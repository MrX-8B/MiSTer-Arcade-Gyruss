// Copyright (c) 2020 MiSTer-X

module GYRUSS_MAIN
(
	input					MCLK,
	input					RESET,

	input	  [8:0]		PH,
	input   [8:0]		PV,

	input	  [7:0]		INP0,
	input	  [7:0]		INP1,
	input	  [7:0]		INP2,

	input	  [7:0]		DSW0,
	input	  [7:0]		DSW1,
	input	  [7:0]		DSW2,

	input					BGCL,
	input   [9:0]		BGVA,
	output [15:0]		BGVD,

	input					SHCL,
	input  [10:0]		SHMA,
	output  [7:0]		SHMD,
	input					SHMW,
	input   [7:0]		SHWD,

	output 				FLPV,

	output 				SNDRQ,
	output reg  [7:0]	SNDNO = 0,
	
	input					ROMCL,
	input  [16:0]		ROMAD,
	input	 [7:0]		ROMID,
	input	 				ROMEN
);

reg [3:0] clkdiv;
always @(posedge MCLK) clkdiv <= clkdiv+1;


// CPU signals
wire [15:0] CPUAD;
wire  [7:0] CPUID,CPUOD;
wire			CPUMR,CPUMW;
wire			CPUCL = clkdiv[3];	// 3.0MHz


// Address decoders
wire CSROM = CPUAD[15   ] ==  1'b0;
wire CSCRM = CPUAD[15:10] ==  6'b1000_00;
wire CSVRM = CPUAD[15:10] ==  6'b1000_01;
wire CSWRM = CPUAD[15:12] ==  4'b1001;
wire CSSRM = CPUAD[15:11] ==  5'b1010_0;
wire CSDS1 = CPUAD[15: 0] == 16'hC000;
wire CSIN0 = CPUAD[15: 0] == 16'hC080;
wire CSIN1 = CPUAD[15: 0] == 16'hC0A0;
wire CSIN2 = CPUAD[15: 0] == 16'hC0C0;
wire CSDS0 = CPUAD[15: 0] == 16'hC0E0;
wire CSDS2 = CPUAD[15: 0] == 16'hC100;
wire CSLAT = CPUAD[15: 3] =={12'hC18,1'b0};

wire WRWDT = CSDS1 & CPUMW;
wire WRSRQ = CSIN0 & CPUMW;
wire WRSNO = CSDS2 & CPUMW;
wire WRLAT = CSLAT & CPUMW;


// ROM & RAMs
wire [7:0] ROMDT,CRMDT,VRMDT,WRMDT,SRMDT;
MAINROM         irom(CPUCL,CPUAD,ROMDT,ROMCL,ROMAD,ROMID,ROMEN);
RAM_B   #(12)   wram(CPUCL,CPUAD,CPUOD,CSWRM & CPUMW,WRMDT);
DPRAM   #(11,8) sram(SHCL,SHMA,SHWD,SHMW,SHMD, CPUCL,CPUAD,CPUOD,CSSRM & CPUMW,SRMDT);
DPRAMrw #(10,8) cram(BGCL,BGVA,BGVD[15:8]    , CPUCL,CPUAD,CPUOD,CSCRM & CPUMW,CRMDT);
DPRAMrw #(10,8) vram(BGCL,BGVA,BGVD[ 7:0]    , CPUCL,CPUAD,CPUOD,CSVRM & CPUMW,VRMDT);


// Watch-Dog timer & Latches
reg [31:0] WDTCN;
reg  [7:0] LATCH;
reg  [1:0] SNDRC;
always @(posedge CPUCL or posedge RESET) begin
	if (RESET) begin
		WDTCN <= 0;
		LATCH <= 0;
		SNDNO <= 0;
		SNDRC <= 0;
	end
	else begin
		if (WRWDT) WDTCN <= 0; else WDTCN <= WDTCN+1;
		if (WRSRQ) SNDRC <= 2'h2; else SNDRC <= SNDRQ ? (SNDRC-1) : SNDRC;
		if (WRSNO) SNDNO <= CPUOD;
		if (WRLAT) LATCH[CPUAD[2:0]] <= CPUOD[0];
	end
end
wire   NMIMASK = LATCH[0];
wire   COINCN0 = LATCH[2];
wire   COINCN1 = LATCH[3];
assign FLPV    = LATCH[5];

assign SNDRQ   = (SNDRC!=0);

// TODO: WDT-RESET
	

// CPU data selector
DSEL12_8 dsel(
	CPUID,
  ~CPUMR,8'h00,
	CSROM,ROMDT,
	CSCRM,CRMDT,
	CSVRM,VRMDT,
	CSWRM,WRMDT,
	CSSRM,SRMDT,
	CSIN0,INP0,
	CSIN1,INP1,
	CSIN2,INP2,
	CSDS0,DSW0,
	CSDS1,DSW1,
	CSDS2,DSW2
);


// V-BLANK NMI Generator
reg NMI,pNMIMASK;
always @(posedge CPUCL or posedge RESET) begin
	if (RESET) begin
		NMI <= 0;
		pNMIMASK <= 0;
	end
	else begin
		if ((pNMIMASK^NMIMASK)&~NMIMASK) NMI <= 0;
		else if (PH<8 && PV==225) NMI <= 1'b1;
		pNMIMASK <= NMIMASK;
	end
end
wire CPUNMI = NMI & NMIMASK;


// CPU
Z80IP maincpu(
	.reset(RESET),.clk(CPUCL),
	.adr(CPUAD),.din(CPUID),.dout(CPUOD),
	.mr(CPUMR),.mw(CPUMW),
	.nmireq(CPUNMI)
);

endmodule


module MAINROM
(
	input				CL,
	input [14:0]	AD,
	output [7:0]	DT,

	input				ROMCL,
	input [16:0]	ROMAD,
	input	 [7:0]	ROMDT,
	input	 			ROMEN
);


reg [1:0] ads;
always @(posedge CL) ads <= AD[14:13];

wire [7:0] DT0,DT1,DT2;
assign DT = (ads==2'b00) ? DT0 :
				(ads==2'b01) ? DT1 :
				(ads==2'b10) ? DT2 : 8'h0;

DLROM #(13,8) r0(CL,AD,DT0, ROMCL,ROMAD,ROMDT,ROMEN && ROMAD[16:13]==4'h0);
DLROM #(13,8) r1(CL,AD,DT1, ROMCL,ROMAD,ROMDT,ROMEN && ROMAD[16:13]==4'h1);
DLROM #(13,8) r2(CL,AD,DT2, ROMCL,ROMAD,ROMDT,ROMEN && ROMAD[16:13]==4'h2);

endmodule


module DSEL12_8
(
	output [7:0] O,

	input E0, input [7:0] D0, 
	input E1, input [7:0] D1, 
	input E2, input [7:0] D2, 
	input E3, input [7:0] D3, 
	input E4, input [7:0] D4, 
	input E5, input [7:0] D5, 
	input E6, input [7:0] D6, 
	input E7, input [7:0] D7, 
	input E8, input [7:0] D8, 
	input E9, input [7:0] D9, 
	input EA, input [7:0] DA, 
	input EB, input [7:0] DB
);	
assign O =	E0 ? D0 :
				E1 ? D1 :
				E2 ? D2 :
				E3 ? D3 :
				E4 ? D4 :
				E5 ? D5 :
				E6 ? D6 :
				E7 ? D7 :
				E8 ? D8 :
				E9 ? D9 :
				EA ? DA :
				EB ? DB :
				8'h00;
endmodule


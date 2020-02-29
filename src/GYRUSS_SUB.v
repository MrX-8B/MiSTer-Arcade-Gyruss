// Copyright (c) 2020 MiSTer-X

module GYRUSS_SUB
(
	input				MCLK,
	input				RESET,

	input  [8:0]	PH,
	input	 [8:0]	PV,

	output 			SHCL,
	output [10:0]	SHMA,
	input   [7:0]	SHMD,
	output 			SHMW,
	output  [7:0]	SHWD,

	input				SPCL,
	input  [7:0]	SPAA,
	output [7:0]	SPAD,
	
	input				ROMCL,
	input  [16:0]	ROMAD,
	input	 [7:0]	ROMID,
	input	 			ROMEN
);

reg [4:0] clkdiv;
always @(posedge MCLK) clkdiv <= clkdiv+1;


// CPU signals
wire			CPURW,CPUMX;
wire [15:0]	CPUAD;
wire  [7:0] CPUID,CPUOD;

wire AXSCL = clkdiv[3];
wire CPUCL = clkdiv[4];
wire CPUMW = ~CPURW;
wire CPUMR = CPURW;


// Address decoders
wire CSSCL = CPUMX & (CPUAD[15: 0] == 16'h0000);
wire CSIMS = CPUMX & (CPUAD[15: 0] == 16'h2000);
wire CSWRM = CPUMX & (CPUAD[15:11] == 5'b0100_0);
wire CSSRM = CPUMX & (CPUAD[15:11] == 5'b0110_0);
wire CSROM = CPUMX & (CPUAD[15:13] == 3'b111);


// RAMs
wire [7:0] WRMDT;
DPRAMrw #(11,8) wram(SPCL,SPAA,SPAD, AXSCL,CPUAD,CPUOD,CSWRM & CPUMW,WRMDT);

assign SHCL = AXSCL;
assign SHMA = CPUAD;
assign SHMW = CSSRM & CPUMW;
assign SHWD = CPUOD;


// CPU data selector
wire [7:0] ROMDT;
wire [7:0] VPOS;
DSEL5_8 dsel(
	 CPUID,
	~CPUMR,8'h0,
	 CSROM,ROMDT,
	 CSWRM,WRMDT,
	 CSSRM,SHMD,
	 CSSCL,VPOS
);


// IRQ Generator
reg IRQMASK,IRQ;
reg [8:0] pPV;
always @(posedge AXSCL or posedge RESET) begin
	if (RESET) begin
		IRQMASK <= 0;
		IRQ <= 0;
		pPV <= 0;
	end
	else begin
		if (CSIMS & CPUMW) begin
			IRQMASK <= CPUOD[0];
			if (~CPUOD[0]) IRQ <= 0;
		end
		else if (pPV!=PV) begin
			IRQ <= 1'b1;
			pPV <= PV;
		end
	end
end
wire CPUIRQ = IRQ & IRQMASK;
assign VPOS = PV[7:0];


// CPU (KONAMI-1)
wire [7:0] ROMOP;
SUBROM irom(AXSCL,CPUAD,ROMOP,ROMDT, ROMCL,ROMAD,ROMID,ROMEN);

cpu09 subcpu(
	.clk(CPUCL),
	.rst(RESET),
	.rw(CPURW),
	.vma(CPUMX),
	.address(CPUAD),
	.opc_in(ROMOP),
	.data_in(CPUID),
	.data_out(CPUOD),
	.halt(1'b0),
	.hold(1'b0),
	.irq(CPUIRQ),
	.firq(1'b0),
	.nmi(1'b0)
);

endmodule


module SUBROM
(
	input				CL,
	input [12:0]	AD,
	output [7:0]	OP,
	output [7:0]	DT,
	
	input				ROMCL,
	input  [16:0]	ROMAD,
	input	 [7:0]	ROMID,
	input	 			ROMEN
);

wire [7:0] OD,DC;

assign DT = OD;
assign DC = {AD[1],1'b0,~AD[1],1'b0,AD[3],1'b0,~AD[3],1'b0};
assign OP =(OD^DC);

DLROM #(13,8) r0(CL,AD,OD, ROMCL,ROMAD,ROMID,ROMEN && ROMAD[16:13]==4'h3);

endmodule


module DSEL5_8
(
	output [7:0] O,

	input E0, input [7:0] D0, 
	input E1, input [7:0] D1, 
	input E2, input [7:0] D2, 
	input E3, input [7:0] D3, 
	input E4, input [7:0] D4 
);	
assign O =	E0 ? D0 :
				E1 ? D1 :
				E2 ? D2 :
				E3 ? D3 :
				E4 ? D4 :
				8'h0;
endmodule



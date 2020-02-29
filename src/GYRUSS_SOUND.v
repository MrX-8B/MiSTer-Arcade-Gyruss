// Copyright (c) 2020 MiSTer-X

module GYRUSS_SOUND
(
	input				MCLK,
	input 			RESET,

	input				SNDRQ,
	input   [7:0]	SNDNO,

	output [15:0]	SND_L,
	output [15:0]	SND_R,

	input				ROMCL,
	input  [16:0]	ROMAD,
	input	 [7:0]	ROMID,
	input	 			ROMEN
);

wire [15:0] CPUAD;
wire  [7:0] CPUOD;
wire CPUCL,CPUMR,CPUMW,CPUIR,CPUIW;
wire CPUIRS;

SNDCGEN2 cgen2(MCLK,CPUCL);


wire		  romcs;
wire [7:0] romdt;
SNDIROM irom(CPUCL,CPUAD,romcs,romdt,ROMCL,ROMAD,ROMID,ROMEN);


wire       ramcs =(CPUAD[15:12]==4'b0110);
wire [7:0] ramdt;
RAM_B #(10) wram(CPUCL,CPUAD[9:0],CPUOD,ramcs & CPUMW,ramdt);


reg [7:0] sndrno = 0;
reg       sndreq = 0;
wire      sndreqrst = RESET|CPUIRS;
reg		 pSNDRQ = 0;
always @(posedge CPUCL) begin
	if (RESET) sndrno <= 0;
	if (sndreqrst) sndreq <= 1'b0;
	else begin
		if ((SNDRQ^pSNDRQ)&SNDRQ) begin
			sndrno <= SNDNO;
			sndreq <= 1'b1;
		end
		pSNDRQ <= SNDRQ;
	end
end
wire snocs = CPUAD[15];
wire CPUIRQ = sndreq;


wire [7:0] DACO;
reg  [7:0] DACNO;
reg		  DACRQ;
always @(posedge CPUCL or posedge RESET) begin
	if (RESET) begin
		DACNO <= 0;
		DACRQ <= 0;
	end
	else begin
		if ((CPUAD[7:0]==8'h18)& CPUIW) DACNO <= CPUOD;
		DACRQ <= (CPUAD[7:0]==8'h14) & CPUIW;
	end
end
GYRUSS_SNDMCU smcu(RESET,MCLK,DACRQ,DACNO,DACO, ROMCL,ROMAD,ROMID,ROMEN);


wire       sgncs;
wire [7:0] sgndt;
GYRUSS_SNDGEN sgen(
	RESET,MCLK,
	CPUCL,CPUIW,CPUIR,CPUAD,CPUOD,
	sgncs,sgndt,
	DACO,
	SND_L,SND_R
);


wire [7:0] CPUID;
DSEL4 dsel(
	CPUID,
	sgncs & CPUIR,sgndt,
	snocs & CPUMR,sndrno,
	ramcs & CPUMR,ramdt,
	romcs & CPUMR,romdt
);

Z80IP sndcpu(
	.reset(RESET),.clk(CPUCL),
	.adr(CPUAD),.din(CPUID),.dout(CPUOD),
	.mr(CPUMR),.mw(CPUMW),.ir(CPUIR),.iw(CPUIW),
	.intreq(CPUIRQ),.intrst(CPUIRS),
	.nmireq(1'b0),.nmirst()
);

endmodule


module SNDCGEN( input in, output reg out );
// in: 48.0MHz -> out: 14.31818MHz
reg [6:0] count;
always @( posedge in ) begin
	if (count > 7'd48) begin
		count <= count - 7'd48;
		out <= ~out;
	end
   else count <= count + 7'd71;
end
endmodule


module SNDCGEN2
(
	input  MCLK,
	output CPUCL
);

wire CLK14M;
SNDCGEN cgen(MCLK,CLK14M);
reg [1:0] clkdiv;
always @(posedge CLK14M) clkdiv <= clkdiv+1;
assign CPUCL = clkdiv[1];

endmodule


module SNDIROM
(
	input				CPUCL,
	input [15:0]	CPUAD,
	output			romcs,
	output [7:0]	romdt,

	input				ROMCL,
	input [16:0]	ROMAD,
	input	 [7:0]	ROMID,
	input	 			ROMEN
);

wire [7:0] rom1d,rom2d;
DLROM #(13,8) r1(CPUCL,CPUAD[12:0],rom1d, ROMCL,ROMAD,ROMID,ROMEN && ROMAD[16:13]==4'h9);
DLROM #(13,8) r2(CPUCL,CPUAD[12:0],rom2d, ROMCL,ROMAD,ROMID,ROMEN && ROMAD[16:13]==4'hA);

reg ad13;
always @(posedge CPUCL) ad13 <= CPUAD[13];

assign romdt = ad13 ? rom2d : rom1d;
assign romcs =(CPUAD[15:14]==2'b00);

endmodule


module DSEL4
(
	output [7:0] O,
	input E0, input [7:0] I0,
	input E1, input [7:0] I1,
	input E2, input [7:0] I2,
	input E3, input [7:0] I3
);

assign O =	E0 ? I0 :
				E1 ? I1 :				
				E2 ? I2 :				
				E3 ? I3 :
				8'hFF;

endmodule

	
module GYRUSS_SNDGEN
(
	input				RESET,
	input				MCLK,

	input				CPUCL,
	input				CPUIW,
	input				CPUIR,
	input	 [7:0]	CPUAD,
	input  [7:0]	CPUOD,

	output			RDV,
	output [7:0]	RDT,

	input  [7:0]	DACO,

	output reg [15:0]	SND_L,
	output reg [15:0]	SND_R,
	
	output reg [7:0]	TIMER
);

function [3:0] timerd(input [3:0] no);
begin
	case(no)
	0: timerd = 4'h0;
	1: timerd = 4'h1;
	2: timerd = 4'h2;
	3: timerd = 4'h3;
	4: timerd = 4'h4;
	5: timerd = 4'h9;
	6: timerd = 4'hA;
	7: timerd = 4'hB;
	8: timerd = 4'hA;
	9: timerd = 4'hD;
	default: timerd = 0;
	endcase
end
endfunction

reg [9:0] clkdiv;
always @(posedge CPUCL) clkdiv <= clkdiv+1;
wire PSGCL = clkdiv[0];
wire TIMCL = clkdiv[9]; 

reg  [3:0] timno = 0;
always @(posedge TIMCL) begin
	TIMER <= {4'h0,timerd(timno)};
	timno <= (timno==4'd9) ? 0 : (timno+4'd1);
end


wire [7:0] p0A,p0B,p0C,p0dt;
wire [7:0] p1A,p1B,p1C,p1dt;
wire [7:0] p2A,p2B,p2C,p2dt;
wire [7:0] p3A,p3B,p3C,p3dt;
wire [7:0] p4A,p4B,p4C,p4dt;

wire CPUIO = (CPUIW|CPUIR);
wire p0cs = (CPUAD[4:2]==3'h0) & CPUIO;
wire p1cs = (CPUAD[4:2]==3'h1) & CPUIO;
wire p2cs = (CPUAD[4:2]==3'h2) & CPUIO;
wire p3cs = (CPUAD[4:2]==3'h3) & CPUIO;
wire p4cs = (CPUAD[4:2]==3'h4) & CPUIO;

wire	bdir0 = p0cs & ~CPUAD[0];
wire	bc0   = p0cs & ~CPUAD[1];

wire	bdir1 = p1cs & ~CPUAD[0];
wire	bc1   = p1cs & ~CPUAD[1];

wire	bdir2 = p2cs & ~CPUAD[0];
wire	bc2   = p2cs & ~CPUAD[1];

wire	bdir3 = p3cs & ~CPUAD[0];
wire	bc3   = p3cs & ~CPUAD[1];

wire	bdir4 = p4cs & ~CPUAD[0];
wire	bc4   = p4cs & ~CPUAD[1];

wire [5:0] FC0,FC1;
wire [7:0] dum0,dum1,dum2,dum3;

pAY8910 p0(RESET,CPUCL,bdir0,bc0,CPUOD,p0dt,p0A,p0B,p0C,dum0,dum1,FC0);
pAY8910 p1(RESET,CPUCL,bdir1,bc1,CPUOD,p1dt,p1A,p1B,p1C,dum2,dum3,FC1);
pAY8910 p2(RESET,CPUCL,bdir2,bc2,CPUOD,p2dt,p2A,p2B,p2C,TIMER);
pAY8910 p3(RESET,CPUCL,bdir3,bc3,CPUOD,p3dt,p3A,p3B,p3C);
pAY8910 p4(RESET,CPUCL,bdir4,bc4,CPUOD,p4dt,p4A,p4B,p4C);

assign RDV =(p0cs|p1cs|p2cs|p3cs|p4cs);
assign RDT = p0cs ? p0dt :
				 p1cs ? p1dt :
				 p2cs ? p2dt :
				 p3cs ? p3dt :
				 p4cs ? p4dt :
				 8'h0;


wire [15:0] SE_L,SE_R;
wire			SMPCL;
FilterCTR ft(
	MCLK,
	FC0,p0A,p0B,p0C,
	FC1,p1A,p1B,p1C,
	SMPCL,SE_L,SE_R
);

wire [16:0] DAC  = (DACO*64*204)/256;		// x0.8

wire [16:0] BG_L = (p4A*64+p4B*64+p4C*64+DAC);
wire [16:0] BG_R = (p2A*64+p2B*64+p2C*64+p3A*64+p3B*64+p3C*64);

wire [19:0] MixL = SE_L+BG_L;
wire [19:0] MixR = SE_R+BG_R;

always @(posedge MCLK) begin
	if (SMPCL) begin
		SND_L <= {16{MixL[19:16]!=0}}|(MixL[15:0]);
		SND_R <= {16{MixR[19:16]!=0}}|(MixR[15:0]);
	end
end

endmodule


module pAY8910
(
	input					RESET,
	input					CLK,

	input					BDIR,
	input					BC1,

	input  [7:0]		ID,
	output [7:0]		OD,

	output reg [7:0]	A,
	output reg [7:0]	B,
	output reg [7:0]	C,

	input  [7:0]		IN_A,
	input  [7:0]		IN_B,
	
	output [7:0]		OUT_A,
	output [7:0]		OUT_B
);

wire [1:0] ACH;
wire [7:0] AOUT;

YM2149 psg(
	.ENA(1'b1),
	.I_SEL_L(1'b0),

	.RESET_L(~RESET),
	.CLK(CLK),
	.I_DA(ID),
	.O_DA(OD),
	
	.I_A9_L(1'b0),
	.I_A8(1'b1),
	.I_BDIR(BDIR),
	.I_BC2(1'b1),
	.I_BC1(BC1),
	
	.I_IOA(IN_A),
	.O_IOA(OUT_A),
	
	.I_IOB(IN_B),
	.O_IOB(OUT_B),

	.O_AUDIO(AOUT),
   .O_CHAN(ACH)
);

always @(posedge CLK or posedge RESET) begin
	if (RESET) begin
		A <= 0;
		B <= 0;
		C <= 0;
	end
	else case (ACH)
	2'd0: A <= AOUT;
	2'd1: B <= AOUT;
	2'd2: C <= AOUT;
	default:;
	endcase
end

endmodule


module FilterCTR
(
	input					MCLK,

	input	 [5:0]	 	F0,
	input  [7:0]		A0,
	input  [7:0]		B0,
	input  [7:0]		C0,

	input	 [5:0] 		F1,
	input  [7:0]		A1,
	input  [7:0]		B1,
	input  [7:0]		C1,

	output				SCLK,
	output reg [15:0] OUT0,
	output reg [15:0] OUT1
);

reg [9:0] cnt;
always @(negedge MCLK) begin
	cnt <= (cnt==999) ? 0 : (cnt+1);
end
wire EN  = (cnt==0);
wire EN2 = (cnt==1);
assign SCLK = (cnt==2);

wire [15:0] o00,o01,o02,o10,o11,o12;
LPF f10(MCLK,EN,A1,F1[1:0],o10);
LPF f11(MCLK,EN,B1,F1[3:2],o11);
LPF f12(MCLK,EN,C1,F1[5:4],o12);
LPF f00(MCLK,EN,A0,F0[1:0],o00);
LPF f01(MCLK,EN,B0,F0[3:2],o01);
LPF f02(MCLK,EN,C0,F0[5:4],o02);

wire [16:0] WO0 = o00+o01+o02;
wire [16:0] WO1 = o10+o11+o12;

always @(posedge MCLK) begin
	if (EN2) begin
		OUT0 <= ({16{WO0[16]}}|WO0[15:0]);
		OUT1 <= ({16{WO1[16]}}|WO1[15:0]);
	end
end

endmodule


module LPF
(
	input				CLK,
	input				EN,
	input  [7:0]	INu8,
	input  [1:0]	FP,

	output reg [15:0] O
);
wire [16:0] K = (FP==2'b01) ? 17'd49391 :	// 2497.2Hz
					 (FP==2'b10) ? 17'd61258 :	//  533.5Hz
					 (FP==2'b11) ? 17'd61971 :	//	 439.5Hz
										17'd0;

wire [15:0] I = {3'h0,INu8,5'h0};
reg  [15:0]	M;
always @(posedge CLK) begin
	if (EN) begin
		M <=(FP==2'b00) ? I : (M+(((I-M)*K)/65536));
		O <= M;
	end
end

endmodule


module GYRUSS_SNDMCU
(
	input 			RESET,
	input				MCLK,
	input				SNDRQ,
	input   [7:0]	SNDNO,

	output  [7:0]	SNDO,

	input				ROMCL,
	input  [16:0]	ROMAD,
	input	  [7:0]	ROMID,
	input	 			ROMEN
);

reg [2:0] clkcnt;
always @(posedge MCLK) clkcnt <= (clkcnt==5) ? 0 : (clkcnt+1);
wire mcuclken = (clkcnt==0);

wire	ale,rd,psen;
wire  [7:0] mcuOB;
wire  [7:0] mcuP2;

reg [7:0] romad;
always @(negedge ale) romad <= mcuOB;
wire [11:0] mcurad = {mcuP2[3:0],romad};
wire  [7:0] mcurom;
DLROM #(12,8) irom(~MCLK,mcurad,mcurom, ROMCL,ROMAD,ROMID,ROMEN && ROMAD[16:12]=={4'hB,1'b0});

wire  [7:0] mcuIB = (~psen) ? mcurom : (~rd) ? SNDNO : 8'hFF;

reg  irq = 1'b0;
wire irqrst = (~mcuP2[7])|RESET;
always @(posedge SNDRQ or posedge irqrst) begin
	if (irqrst) irq <= 1'b0;
	else irq <= 1'b1;
end

t8039_notri mcu
(
	.xtal_i(MCLK),
   .xtal_en_i(mcuclken),
   .reset_n_i(~RESET),
   .int_n_i(~irq),
   .ea_i(1'b1),
	.rd_n_o(rd),
   .psen_n_o(psen),
   .ale_o(ale),
   .db_i(mcuIB),
   .db_o(mcuOB),
   .p2_o(mcuP2),
   .p1_o(SNDO)
);

endmodule


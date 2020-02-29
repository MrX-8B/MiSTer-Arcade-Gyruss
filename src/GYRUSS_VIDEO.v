// Copyright (c) 2020 MiSTer-X

module GYRUSS_VIDEO
(
	input				MCLK,

	input	  [8:0]	PH,
	input	  [8:0]	PV,
	input				VFLP,

	output			BGCL,
	output  [9:0]	BGVA,
	input  [15:0]	BGVD,

	output			SPCL,
	output  [7:0]	SPAA,
	input   [7:0]	SPAD,

	output 			PCLK,
	output  [7:0]	POUT,	

	input				ROMCL,
	input  [16:0]	ROMAD,
	input	  [7:0]	ROMID,
	input	 			ROMEN
);
	
// Clocks
reg [2:0] clkdiv;
always @(posedge MCLK) clkdiv <= clkdiv+1;
wire VCLKx8 = MCLK;
wire VCLKx4 = clkdiv[0];
wire VCLKx2 = clkdiv[1];
wire VCLK   = clkdiv[2];

// BG Scanline Generator
assign		BGCL = VCLKx4;
wire		   BGPR;
wire  [4:0] BGPN;
GYRUSS_BG bg(VCLKx2,PH,PV,VFLP,BGVA,BGVD,BGPR,BGPN, ROMCL,ROMAD,ROMID,ROMEN);

// Sprite Scanline Generator
wire 		  SPOQ;
wire [4:0] SPPN;
GYRUSS_SPRITE spr(VCLKx8,VCLK,PH,PV,SPCL,SPAA,SPAD,SPOQ,SPPN, ROMCL,ROMAD,ROMID,ROMEN);

// Color Mixer & Palette
wire [4:0] PALN = BGPR ? BGPN :
						SPOQ ? SPPN :
								 BGPN ;

DLROM #(8,8) pal(VCLK,PALN,POUT, ROMCL,ROMAD,ROMID,ROMEN && ROMAD[16:8]=={4'hB,5'h12});
assign PCLK = ~VCLK;

endmodule


module GYRUSS_BG
(
	input				VCLKx2,
	
	input  [8:0]	PH,
	input	 [8:0]	PV,
	input				VFLP,

	output [9:0]	BGVA,
	input  [15:0]	BGVD,
	
	output reg		BGPR,
	output [4:0]	BGPN,

	input				ROMCL,
	input  [16:0]	ROMAD,
	input	 [7:0]	ROMID,
	input	 			ROMEN
);

wire  [8:0] BGHP = PH;
wire  [8:0] BGVP = PV+16;

assign 		BGVA = {BGVP[7:3]^{5{VFLP}},BGHP[7:3]^{5{VFLP}}};

wire  [8:0] BGNO = {BGVD[13],BGVD[7:0]};
wire  [3:0] BGPT = BGVD[11:8];
wire        BGFH = BGVD[14]^VFLP;
wire        BGFV = BGVD[15]^VFLP;
wire [12:0] BGCA = {BGNO,(BGHP[2]^BGFH),(BGVP[2:0]^{3{BGFV}})};
wire  [7:0] BGCD;

wire  [7:0] BGPS = BGCD << (BGHP[1:0]^{2{BGFH}});
wire  [1:0] BGPX = {BGPS[3],BGPS[7]};
wire  [5:0] BGCN = {BGPT,BGPX};
wire  [3:0] BGCT;

always @(negedge VCLKx2) BGPR <= BGVD[12];
assign BGPN = {1'b1,BGCT};

DLROM #(13,8) bgch( VCLKx2,BGCA,BGCD, ROMCL,ROMAD,ROMID,ROMEN && ROMAD[16:13]=={4'h4});
DLROM #( 8,4) cltb(~VCLKx2,BGCN,BGCT, ROMCL,ROMAD,ROMID,ROMEN && ROMAD[16: 8]=={4'hB,5'h11});

endmodule

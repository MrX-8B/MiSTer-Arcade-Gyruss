// Copyright (c) 2020 MiSTer-X

module GYRUSS_SPRITE
(
	input					VCLKx8,
	input					VCLK,
	
	input  [8:0]		SPHP,
	input	 [8:0]		SPVP,

	output				SPCL,
	output [7:0]		SPAA,
	input	 [7:0]		SPAD,

	output reg			SPOQ,
	output [4:0]		SPPN,
	
	input					ROMCL,
	input  [16:0]		ROMAD,
	input	 [7:0]		ROMID,
	input	 				ROMEN
);

reg  [5:0] SPNO;
reg  [1:0] SPOF;
assign	  SPAA = {SPNO,SPOF};
assign     SPCL = ~VCLKx8;

reg  [7:0] SPA0,SPA1,SPA2,SPA3;

wire [7:0] POSX = SPA0;
wire [7:0] POSY = SPA3;
wire [8:0] CODE ={SPA1[0],SPA2[5],SPA1[7:1]}; 
wire [3:0] COLR = SPA2[3:0];
wire       FLPH = SPA2[6];
wire		  FLPV = SPA2[7];


wire [8:0] SPHY = {1'b0,POSY}+SPVP;
wire		  SPHT = &SPHY[7:4];

reg  [3:0] SPLX;
wire [3:0] SPLY = SPHY[3:0];
wire		  SPWE = ~SPLX[3];

`define LOOP (ph)
`define PREV (ph-1)
`define NEXT (ph+1)
`define NLIN (0)
`define NSPR (1)
`define RPIX (6)
`define WPIX (7)

`define PBEG (SPHP==0)
`define PEND (SPNO!=6'd15)

reg [2:0] ph = 0;
always @(posedge VCLKx8) begin
	case(ph)
		0: begin SPNO  = 6'd0;   SPLX <= 4'd8;  ph <= `PBEG ? `NEXT:`LOOP; end
		1: begin SPNO  = SPNO-1; SPOF <= 2'd3;  ph <= `PEND ? `NEXT:`NLIN; end
		2: begin SPA3 <= SPAD;   SPOF <= 2'd2;  ph <=         `NEXT;		 end
		3: begin SPA2 <= SPAD;   SPOF <= 2'd1;  ph <=  SPHT ? `NEXT:`NSPR; end
		4: begin SPA1 <= SPAD;   SPOF <= 2'd0;  ph <=         `NEXT;		 end
		5: begin SPA0 <= SPAD;   SPLX <= 4'd0;  ph <=         `NEXT;		 end
		6: begin   /*    PIXEL READ      */     ph <=         `NEXT;		 end
		7: begin SPLX <= SPWE ? (SPLX+1) : 0;	 ph <=  SPWE ? `PREV:`NSPR; end
	default: ph <= 0;
	endcase
end

wire [3:0] PIXD;
GYRUSS_SPPIX sppx(VCLKx8,(ph==`RPIX),CODE,SPLX,SPLY,FLPH,FLPV,PIXD, ROMCL,ROMAD,ROMID,ROMEN);

wire [8:0] SPWP = POSX+SPLX+9'd1;
wire [7:0] SPWD = {COLR,PIXD};
wire [7:0] SPCN;

wire		  LBWE = SPWE & (SPWD[3:0]!=0) & (ph==`WPIX);

reg  [9:0] SPR0=0;
wire [9:0] SPRP = {~SPVP[0],SPHP};
LBUF1024_8 lbuf(
	VCLKx8,{SPVP[0],SPWP},LBWE,SPWD,
  ~VCLKx8,SPRP,(SPR0!=SPRP),(SPR0==SPRP),8'd0,SPCN
);
always @(posedge VCLK) SPR0 <= SPRP;

wire [3:0] SPCT;
DLROM #(8,4) clts(VCLKx8,SPCN,SPCT, ROMCL,ROMAD,ROMID,ROMEN && ROMAD[16:8]=={4'hB,5'h10});
always @(posedge VCLKx8) SPOQ <= (SPCN[3:0]!=0);

assign SPPN = {1'b0,SPCT};

endmodule 


module GYRUSS_SPPIX
(
	input				CLK,
	input				EN,

	input [8:0]		CODE,
	input [2:0] 	LX,
	input [3:0] 	LY,
	input				FH,
	input				FV,
	
	output reg [3:0] PIX,
	
	input				ROMCL,
	input  [16:0]	ROMAD,
	input	  [7:0]	ROMID,
	input	 			ROMEN
);

wire [12:0] ADR = {CODE[6:0],LY[3]^FV,CODE[8],~(LX[2]^FH),LY[2:0]^{3{FV}}};

reg  [16:0] ST;
wire [16:0] STi = {LX[1:0],FH,CODE[7],ADR};
wire [16:0] STe = EN ? STi : ST;
always @(posedge CLK) if (EN) ST <= STi;

wire [15:0] DT0,DT1; 
DLROM #(13,8) r10(CLK,STe[12:0],DT1[ 7:0], ROMCL,ROMAD,ROMID,ROMEN && ROMAD[16:13]==4'h5);
DLROM #(13,8) r00(CLK,STe[12:0],DT0[ 7:0], ROMCL,ROMAD,ROMID,ROMEN && ROMAD[16:13]==4'h6);
DLROM #(13,8) r11(CLK,STe[12:0],DT1[15:8], ROMCL,ROMAD,ROMID,ROMEN && ROMAD[16:13]==4'h7);
DLROM #(13,8) r01(CLK,STe[12:0],DT0[15:8], ROMCL,ROMAD,ROMID,ROMEN && ROMAD[16:13]==4'h8);

wire [15:0] CDT = STe[13] ? DT1 : DT0;
wire [15:0] SFT = CDT >> (STe[16:15]^{2{STe[14]}});

always @(negedge CLK) PIX <= {SFT[8],SFT[12],SFT[0],SFT[4]};

endmodule


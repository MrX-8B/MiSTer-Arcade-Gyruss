// FPGA Gyruss
// Copyright (c) 2020 MiSTer-X

module FPGA_GYRUSS
(
	input				MCLK,
	input				RESET,

	input  [7:0]	INP0,
	input	 [7:0]	INP1,
	input	 [7:0]	INP2,

	input	 [7:0]	DSW0,
	input	 [7:0]	DSW1,
	input	 [7:0]	DSW2,

	input  [8:0]	PH,
	input	 [8:0]	PV,
	output			PCLK,
	output [7:0]	POUT,
	
	output [15:0]	SND_L,
	output [15:0]	SND_R,

	input				ROMCL,
	input  [16:0]	ROMAD,
	input	 [7:0]	ROMDT,
	input	 			ROMEN
);

wire			SPCL;
wire  [7:0]	SPAA;
wire  [7:0]	SPAD;

wire			BGCL;
wire  [9:0] BGVA;
wire [15:0] BGVD;

wire			SHCL,SHMW;
wire [10:0]	SHMA;
wire  [7:0]	SHMD,SHWD;

wire		   FLPV;

wire        SNDRQ;
wire  [7:0] SNDNO;


GYRUSS_MAIN main(
	MCLK,RESET,
	PH,PV,
	INP0,INP1,INP2,DSW0,DSW1,DSW2,
	BGCL,BGVA,BGVD,
	SHCL,SHMA,SHMD,SHMW,SHWD,
	FLPV,
	SNDRQ,SNDNO,

	ROMCL,ROMAD,ROMDT,ROMEN
);


GYRUSS_SUB sub(
	MCLK,RESET,PH,PV,
	SHCL,SHMA,SHMD,SHMW,SHWD,
	SPCL,SPAA,SPAD,
	
	ROMCL,ROMAD,ROMDT,ROMEN
);


GYRUSS_VIDEO video(
	MCLK,
	PH,PV,FLPV,
	BGCL,BGVA,BGVD,
	SPCL,SPAA,SPAD,
	PCLK,POUT,

	ROMCL,ROMAD,ROMDT,ROMEN
);


GYRUSS_SOUND sound(
	MCLK,RESET,SNDRQ,SNDNO,
	SND_L,SND_R,

	ROMCL,ROMAD,ROMDT,ROMEN
);

endmodule



module DLROM #(parameter AW,parameter DW)
(
	input							CL0,
	input [(AW-1):0]			AD0,
	output reg [(DW-1):0]	DO0,

	input							CL1,
	input [(AW-1):0]			AD1,
	input	[(DW-1):0]			DI1,
	input							WE1
);

reg [(DW-1):0] core[0:((2**AW)-1)] /* synthesis ramstyle = "no_rw_check, M10K" */;

always @(posedge CL0) DO0 <= core[AD0];
always @(posedge CL1) if (WE1) core[AD1] <= DI1;

endmodule


module LBUF1024_8
(
	input				CL0,
	input  [9:0]	AD0,
	input				WE0,
	input	 [7:0]	WD0,

	input				CL1,
	input  [9:0]	AD1,
	input				RE1,
	input				WE1,
	input	 [7:0]	WD1,
	output [7:0]	DT1
);

wire       re0 = 1'b0;
wire [7:0] dt0;

DPRAM1024 core
(
	AD0,AD1,
	CL0,CL1,
	WD0,WD1,
	re0,RE1,
	WE0,WE1,
	dt0,DT1
);

endmodule


module DPRAM #(AW=8,DW=8)
(
	input 					CL0,
	input [AW-1:0]			AD0,
	input [DW-1:0]			WD0,
	input						WE0,
	output reg [DW-1:0]	RD0,

	input 					CL1,
	input [AW-1:0]			AD1,
	input [DW-1:0]			WD1,
	input						WE1,
	output reg [DW-1:0]	RD1
);

reg [7:0] core[0:((2**AW)-1)];

always @(posedge CL0) begin
	if (WE0) core[AD0] <= WD0;
	else RD0 <= core[AD0];
end

always @(posedge CL1) begin
	if (WE1) core[AD1] <= WD1;
	else RD1 <= core[AD1];
end

endmodule


module DPRAMrw #(AW=8,DW=8)
(
	input 					CL0,
	input [AW-1:0]			AD0,
	output reg [DW-1:0]	RD0,

	input 					CL1,
	input [AW-1:0]			AD1,
	input [DW-1:0]			WD1,
	input						WE1,
	output reg [DW-1:0] 	RD1
);

reg [7:0] core[0:((2**AW)-1)];

always @(posedge CL0) RD0 <= core[AD0];
always @(posedge CL1) if (WE1) core[AD1] <= WD1; else RD1 <= core[AD1];

endmodule


module RAM_B #(AW=8)
(
	input					cl,
	input	 [(AW-1):0]	ad,
	input   [7:0]		id,
	input					wr,
	output reg [7:0]	od
);

reg [7:0] core [0:((2**AW)-1)];

always @( posedge cl ) begin
	if (wr) core[ad] <= id;
	else od <= core[ad];
end

endmodule

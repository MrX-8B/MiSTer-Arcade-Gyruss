// Copyright (c) 2020 MiSTer-X

module Z80IP
(
	input				reset,
	input				clk,
	output [15:0]	adr,
	input   [7:0]	din,
	output  [7:0]	dout,
	output			m1,
	output			mr,
	output			mw,
	output			ir,
	output			iw,

	input				intreq,
	output reg		intrst,

	input				nmireq,
	output reg		nmirst
);

wire i_mreq, i_iorq, i_rd, i_wr, i_rfsh, i_m1; 

T80s cpu (
	.CLK_n(clk),
	.RESET_n(~reset),
	.INT_n(~intreq),
	.NMI_n(~nmireq),
	.MREQ_n(i_mreq),
	.IORQ_n(i_iorq),
	.RFSH_n(i_rfsh),
	.RD_n(i_rd),
	.WR_n(i_wr),
	.A(adr),
	.DI(din),
	.DO(dout),
	.WAIT_n(1'b1),
	.BUSRQ_n(1'b1),
	.BUSAK_n(),
	.HALT_n(),
	.M1_n(i_m1)
);

assign m1 = (~i_m1);
wire mreq = (~i_mreq) & i_rfsh;
wire iorq = (~i_iorq) & i_m1;
wire rdr  = (~i_rd);
wire wrr  = (~i_wr);

assign mr = mreq & rdr;
assign mw = mreq & wrr;

assign ir = iorq & rdr;
assign iw = iorq & wrr;

always @(posedge clk) begin
	if (reset) begin
		intrst <= 0;
		nmirst <= 0;
	end
	else begin
		intrst <= (adr==16'h38) & m1 & mr;
		nmirst <= (adr==16'h66) & m1 & mr;
	end
end

endmodule


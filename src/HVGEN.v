// Copyright (c) 2020 MiSTer-X

module HVGEN
(
	output	[8:0]		HPOS,
	output	[8:0]		VPOS,
	input 				PCLK,
	input		[7:0]		iRGB,

	output reg [7:0]	oRGB,
	output reg			HBLK = 1,
	output reg			VBLK = 1,
	output reg			HSYN = 1,
	output reg			VSYN = 1,

	input		[8:0]		HOFFS,
	input		[8:0]		VOFFS
);

reg [8:0] hcnt = 0;
reg [8:0] vcnt = 0;

assign HPOS = hcnt;
assign VPOS = vcnt;

wire [8:0] HS_B = 288+(HOFFS*2);
wire [8:0] HS_E =  32+(HS_B);

wire [8:0] VS_B = 240+(VOFFS*4);
wire [8:0] VS_E =   4+(VS_B);

always @(posedge PCLK) begin
	case (hcnt)
	     0: begin HBLK <= 0; hcnt <= hcnt+9'd1; end
		257: begin HBLK <= 1; hcnt <= hcnt+9'd1; end
		395: begin hcnt <= 0;
			case (vcnt)
				 15: begin VBLK <= 0; vcnt <= vcnt+9'd1; end
				239: begin VBLK <= 1; vcnt <= vcnt+9'd1; end
				255: begin vcnt <= 0; end
				default: vcnt <= vcnt+9'd1;
			endcase
		end
		default: hcnt <= hcnt+9'd1;
	endcase

	if (hcnt==HS_B) begin HSYN <= 0; end
	if (hcnt==HS_E) begin HSYN <= 1; end

	if (vcnt[7:0]==VS_B[7:0]) begin VSYN <= 0; end
	if (vcnt[7:0]==VS_E[7:0]) begin VSYN <= 1; end
	
	oRGB <= (HBLK|VBLK) ? 0 : iRGB;
end

endmodule


// New Modules
`timescale 1ns/1ps

//Multiplier Module
module mult( input [31:0] RD1, input [31:0] RD2, output [63:0] res);
		assign res = RD1*RD2;
endmodule


//Module for regHi and regLo
module multReg(input [31:0] in, input WE, output [31:0] out, input clk);
	reg [31:0] x;
	assign out = x;
	
	initial
		x = 32'b0;
	always @ (posedge clk)
		if(WE)
			x = in;
		else
			x = x;
endmodule


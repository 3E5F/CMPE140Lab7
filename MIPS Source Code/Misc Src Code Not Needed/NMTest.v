//TestBench for new modules

module NewTB();
	//for multiplier
	reg[31:0] in1, in2;
	wire [63:0] out;
	wire [31:0] derpOut;
	reg we, clk;
	
	mult HEYO(.RD1(in1), .RD2(in2), .res(out));
	multReg HIYO(.in(in1), .WE(we), .out(derpOut), .clk(clk));
	
	always #20 clk<=~clk;
	
	initial
		begin
			clk = 0;
			in1 = 32'h00000003;
			in2 = 32'h00000002;
			we = 0;
			#30
			we = 0;
			
			#70;
			we = 1;
			#20;
			we = 0;
			
			in2 = 32'h00000005;
			#50;
			$stop;
		end
endmodule
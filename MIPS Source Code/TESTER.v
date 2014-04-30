`timescale 1ns/ 1ps

module tester();

	reg clk, reset;
	reg [7:0] switches;

	wire memwrite;
	wire [3:0] top_an;
	wire [7:0] top_sseg;
	wire sinkBit;
	
	mips Proto1(.clksec(clk), .reset(reset), .pc(), .instr(), .memwrite(memwrite), .dataadr(), .writedata(), .readdata(), .switches(), .dispDat());

	always
		begin
			clk <= 1; 
			#5; 
			clk <= 0; 
			#5;
		end

	initial
		begin
			reset <= 1; # 22; reset <= 0;
		end

	 always@(negedge clk)
		begin
		  if(memwrite) begin
			if(dataadr === 84 & writedata === 7) begin
			  $display("Simulation succeeded");
			  $stop;
			end else if (dataadr !== 80) begin
			  $display("Simulation failed");
			  $stop;
			end
		  end
		end	
endmodule
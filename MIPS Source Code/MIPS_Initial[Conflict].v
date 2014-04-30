//-----------------------------------------------------------------
// Module Name   : clk_gen
// Description   : Generate 4 second and 5KHz clock cycle from
//                 the 50MHz clock on the Nexsys2 board
//------------------------------------------------------------------
module clk_gen(
	input			clk50MHz, reset, 
	output reg		clksec );

	reg 			clk_5KHz;
	integer 		count, count1;
	
	always@(posedge clk50MHz) begin
		if(reset) begin
			count = 0;
			count1 = 0;
			clksec = 0;
			clk_5KHz =0;
		end else begin
			if (count == 50000000) begin
				// Just toggle after certain number of seconds
				clksec = ~clksec;
				count = 0;
			end
			if (count1 == 20000) begin
				clk_5KHz = ~clk_5KHz;
				count1 = 0;
			end
			count = count + 1;
			count1 = count1 + 1;
		end
	end
endmodule

//------------------------------------------------
// Source Code for a Single-cycle MIPS Processor (supports partial instruction)
// Developed by D. Hung, D. Herda and G. Gerken,
// based on the following source code provided by
// David_Harris@hmc.edu (9 November 2005):
//    mipstop.v
//    mipsmem.v
//    mips.v
//    mipsparts.v
//------------------------------------------------

// Main Decoder
module maindec(
	input	[ 5:0]	op,
	output			memtoreg, memwrite, branch, alusrc, regdst, regwrite, jump,
	output	[ 1:0]	aluop );

	reg 	[ 8:0]	controls;

	assign {regwrite, regdst, alusrc, branch, memwrite, memtoreg, jump, aluop} = controls;

	always @(*)
		case(op)
			6'b000000: controls <= 9'b110000010; //Rtype
			6'b100011: controls <= 9'b101001000; //LW
			6'b101011: controls <= 9'b001010000; //SW
			6'b000100: controls <= 9'b000100001; //BEQ
			6'b001000: controls <= 9'b101000000; //ADDI
			6'b000010: controls <= 9'b000000100; //J
			
			default:   controls <= 9'bxxxxxxxxx; //???
		endcase
endmodule

// ALU Decoder
module auxdec(
	input		[5:0]	funct,
	input		[1:0]	aluop,
	output reg	[2:0]	alucontrol,
	output reg WEHi, WELo, HiLo, multHiLo, JAL, JR); //JAL is J type, so it should be in the main dec/CU?

	always @(*)
		case(aluop)
			2'b00: alucontrol <= 3'b010;  // add
			2'b01: alucontrol <= 3'b110;  // sub
			default: case(funct)          // RTYPE
				6'b100000: alucontrol <= 3'b010; // ADD
				6'b100010: alucontrol <= 3'b110; // SUB
				6'b100100: alucontrol <= 3'b000; // AND
				6'b100101: 	begin
										
										
										alucontrol <= 3'b001; // OR
				6'b101010: alucontrol <= 3'b111; // SLT
				6'b001000: begin						//	JR
								WEHi <= 0;	
								WELo <= 0;
								HiLo <= 0;
								multHiLo <= 0;
								JR <= 1;
							  end
				6'b010010: begin						//	MFLO
								WEHi <= 0;	
								WELo <= 1;
								HiLo <= 0;
								multHiLo <= 1;
							  end
				6'b010000: begin						//	MFHI
								WEHi <= 1;	
								WELo <= 0;
								HiLo <= 1;
								multHiLo <= 1;
							  end
				default:   alucontrol <= 3'bxxx; // ???
			endcase
		endcase
endmodule
// ALU
module alu(
	input		[31:0]	a, b, 
	input		[ 2:0]	alucont, 
	output reg	[31:0]	result,
	output			zero );

	wire	[31:0]	b2, sum, slt;

	assign b2 = alucont[2] ? ~b:b; 
	assign sum = a + b2 + alucont[2];
	assign slt = sum[31];

	always@(*)
		case(alucont[1:0])
			2'b00: result <= a & b;
			2'b01: result <= a | b;
			2'b10: result <= sum;
			2'b11: result <= slt;
		endcase

	assign zero = (result == 32'b0);
endmodule

// Adder
module adder(
	input	[31:0]	a, b,
	output	[31:0]	y );

	assign y = a + b;
endmodule

// Two-bit left shifter
module sl2(
	input	[31:0]	a,
	output	[31:0]	y );

	// shift left by 2
	assign y = {a[29:0], 2'b00};
endmodule

// Sign Extension Unit
module signext(
	input	[15:0]	a,
	output	[31:0]	y );

	assign y = {{16{a[15]}}, a};
endmodule

// Parameterized Register
module flopr #(parameter WIDTH = 8) (
	input					clk, reset,
	input		[WIDTH-1:0]	d, 
	output reg	[WIDTH-1:0]	q);

	always @(posedge clk, posedge reset)
		if (reset) q <= 0;
		else       q <= d;
endmodule

// commented out since flopenr is not used
//module flopenr #(parameter WIDTH = 8) (
//	input					clk, reset,
//	input					en,
//	input		[WIDTH-1:0]	d, 
//	output reg	[WIDTH-1:0]	q);
//
//	always @(posedge clk, posedge reset)
//		if      (reset) q <= 0;
//		else if (en)    q <= d;
//endmodule

// Parameterized 2-to-1 MUX
module mux2 #(parameter WIDTH = 8) (
	input	[WIDTH-1:0]	d0, d1, 
	input				s, 
	output	[WIDTH-1:0]	y );

	assign y = s ? d1 : d0; 
endmodule

// register file with one write port and three read ports
// the 3rd read port is for prototyping dianosis
module regfile(	
	input			clk, 
	input			we3, 
	input 	[ 4:0]	ra1, ra2, wa3, 
	input	[31:0] 	wd3, 
	output 	[31:0] 	rd1, rd2,
	input	[ 4:0] 	ra4,
	output 	[31:0] 	rd4);

	reg		[31:0]	rf[31:0];
	integer			n;
	
	//initialize registers to all 0s
	initial 
		for (n=0; n<32; n=n+1) 
			rf[n] = 32'h00;
			
	//write first order, include logic to handle special case of $0
    always @(posedge clk)
        if (we3)
			if (~ wa3[4])
				rf[{0,wa3[3:0]}] <= wd3;
			else
				rf[{1,wa3[3:0]}] <= wd3;
		
			// this leads to 72 warnings
			//rf[wa3] <= wd3;
			
			// this leads to 8 warnings
			//if (~ wa3[4])
			//	rf[{0,wa3[3:0]}] <= wd3;
			//else
			//	rf[{1,wa3[3:0]}] <= wd3;
		
	assign rd1 = (ra1 != 0) ? rf[ra1[4:0]] : 0;
	assign rd2 = (ra2 != 0) ? rf[ra2[4:0]] : 0;
	assign rd4 = (ra4 != 0) ? rf[ra4[4:0]] : 0;
endmodule

// Control Unit
module controller(
	input	[5:0]	op, funct,
	input			zero,
	output			memtoreg, memwrite, pcsrc, alusrc, regdst, regwrite, jump,
	output	[2:0]	alucontrol,
	output WEHi, WELo, HiLo, multHiLo, JAL, JR);

	wire	[1:0]	aluop;
	wire			branch;

	maindec	md(op, memtoreg, memwrite, branch, alusrc, regdst, regwrite, jump, aluop);
	auxdec	ad(funct, aluop, alucontrol, WEHi, WELo, HiLo, multHiLo, JAL, JR);

	assign pcsrc = branch & zero;
endmodule

// Data Path (excluding the instruction and data memories)
module datapath(
	input			clk, reset, memtoreg, pcsrc, alusrc, regdst, regwrite, jump,
	input	[2:0]	alucontrol,
	output			zero,
	output	[31:0]	pc,
	input	[31:0]	instr,
	output	[31:0]	aluout, writedata,
	input	[31:0]	readdata,
	input	[ 4:0]	dispSel,
	output	[31:0]	dispDat,
	input WEHi, WELo, HiLo, multHiLo, JAL, JR);

	wire [4:0]  writereg;
	wire [31:0] pcnext, pcnextbr, pcplus4, pcbranch, signimm, signimmsh, srca, srcb, result;
	
	wire [63:0] multOut;
	//input WEHi, WELo, HiLo, multHiLo;
	wire[31:0] regHiOut, regLoOut, HiLoOut, multHiLoOut;
	
	wire [31:0] JALMux1Out, JRMuxOut;
	wire [4:0] JALMux2Out;
	wire [31:0] JROut;

	// next PC logic
	flopr #(32) pcreg(clk, reset, pcnext, pc);
	adder       pcadd1(pc, 32'b100, pcplus4);
	sl2         immsh(signimm, signimmsh);
	adder       pcadd2(pcplus4, signimmsh, pcbranch);
	mux2 #(32)  pcbrmux(pcplus4, pcbranch, pcsrc, pcnextbr);
	mux2 #(32)  pcmux(pcnextbr, JROut, jump, pcnext);

	// register file logic
	regfile		rf(clk, regwrite, instr[25:21], instr[20:16], writereg, JALMux1Out, srca, writedata, dispSel, dispDat);
	mux2 #(5)	wrmux(instr[20:16], instr[15:11], regdst, writereg);
	mux2 #(32)	resmux(aluout, readdata, memtoreg, result);
	signext		se(instr[15:0], signimm);

	// ALU logic
	mux2 #(32)	srcbmux(writedata, signimm, alusrc, srcb);
	alu			alu(srca, srcb, alucontrol, aluout, zero);
	
	//Addition of the modules ====================================================

	mult multi(.RD1(srca), .RD2(writedata), .res(multOut));
	multReg regHi(.in(multOut[63:32]),.WE(WEHi),.out(regHiOut),.clk(clk));
	multReg regLo(.in(multOut[31:0]),.WE(WELo),.out(regLoOut),.clk(clk));
	mux2 #(32) HiLoMux(regLoOut, regHiOut, HiLo, HiLoOut); 
	mux2 #(32) multHiLoMux(result, HiLoOut, multHiLo, multHiLoOut);
	
	//Intertwined Additions
	
	//input JAL;
	
	mux2 #(32) JALMux1(multHiLoOut, pcplus4, JAL, JALMux1Out);
	mux2 #(5) JALMux2(writereg, 5'b11111, JAL, JALMux2Out);
	

	//input JR;
	mux2 #(32) JRMux({pcplus4[31:28], instr[25:0], 2'b00}, srca, JR, JROut);
	
endmodule

// The MIPS (excluding the instruction and data memories)
module mips(
	input        	clk, reset,
	output	[31:0]	pc,
	input 	[31:0]	instr,
	output			memwrite,
	output	[31:0]	aluout, writedata,
	input 	[31:0]	readdata,
	input	[ 4:0]	dispSel,
	output	[31:0]	dispDat );

	// deleted wire "branch" - not used
	wire 			memtoreg, pcsrc, zero, alusrc, regdst, regwrite, jump;
	wire	[2:0] 	alucontrol;

	controller c(instr[31:26], instr[5:0], zero,
				memtoreg, memwrite, pcsrc,
				alusrc, regdst, regwrite, jump,
				alucontrol);
	datapath dp(clk, reset, memtoreg, pcsrc,
				alusrc, regdst, regwrite, jump,
				alucontrol, zero, pc, instr, aluout, 
				writedata, readdata, dispSel, dispDat);
endmodule

// Instruction Memory
module imem (
	input	[ 5:0]	a,
	output 	[31:0]	dOut );
	
	reg		[31:0]	rom[0:63];
	
	//initialize rom from memfile_s.dat
	initial 
		$readmemh("memfile_s.dat", rom);
	
	//simple rom
    assign dOut = rom[a];
endmodule

// Data Memory
module dmem (
	input			clk,
	input			we,
	input	[31:0]	addr,
	input	[31:0]	dIn,
	output 	[31:0]	dOut );
	
	reg		[31:0]	ram[63:0];
	integer			n;
	
	//initialize ram to all FFs
	initial 
		for (n=0; n<64; n=n+1)
			ram[n] = 8'hFF;
		
	assign dOut = ram[addr[31:2]];
				
	always @(posedge clk)
		if (we) 
			ram[addr[31:2]] = dIn; 
endmodule

//--------------------------------------------------------------
// mips.v
// David_Harris@hmc.edu and Sarah_Harris@hmc.edu 23 October 2005
// Single-cycle MIPS processor
//--------------------------------------------------------------

// files needed for simulation:
//  mipsttest.v
//  mipstop.v
//  mipsmem.v
//  mips.v
//  mipsparts.v

// single-cycle MIPS processor
module mips(input         clk, reset,
            output [31:0] pc,
            input  [31:0] instr,
            output        memwrite,
            output [31:0] aluout, writedata,
            input  [31:0] readdata);

  wire        memtoreg, branch,
              pcsrc, zero,
              alusrc, regdst, regwrite, jump;
  wire [2:0]  alucontrol;
  wire WEHi, WELo, HiLo, multHiLo, JAL, JR;

  controller c(instr[31:26], instr[5:0], zero,
               memtoreg, memwrite, pcsrc,
               alusrc, regdst, regwrite, jump,
               alucontrol, WEHi, WELo, HiLo, multHiLo, JAL, JR);
  datapath dp(clk, reset, memtoreg, pcsrc,
              alusrc, regdst, regwrite, jump,
              alucontrol,
              zero, pc, instr,
              aluout, writedata, readdata, WEHi, WELo, HiLo, multHiLo, JAL, JR);
endmodule


module controller(input  [5:0] op, funct,
                  input        zero,
                  output       memtoreg, memwrite,
                  output       pcsrc, alusrc,
                  output       regdst, regwrite,
                  output       jump,
                  output [2:0] alucontrol,
				  output WEHi, WELo, HiLo, multHiLo, JAL, JR);

  wire [1:0] aluop;
  wire       branch;
  wire Jum1, Jum2;

  
  
  maindec md(op, memtoreg, memwrite, branch,
             alusrc, regdst, regwrite, Jum1,
             aluop, JAL);
  auxdec  ad(funct, aluop, alucontrol, WEHi, WELo, HiLo, multHiLo, JR, Jum2);

  assign jump = Jum1 | Jum2;
  assign pcsrc = branch & zero;
endmodule

module maindec(input  [5:0] op,
               output       memtoreg, memwrite,
               output       branch, alusrc,
               output       regdst, regwrite,
               output       jump,
               output [1:0] aluop,	//aluup and JAL were switched which caused a line issue
			   output JAL);

  reg [9:0] controls;

  assign {regwrite, regdst, alusrc,
          branch, memwrite,
          memtoreg, jump, aluop, JAL} = controls;

  always @(*)
    case(op)
		6'b000000: controls <= 10'b1100000100; //Rtype
		6'b100011: controls <= 10'b1010010000; //LW
		6'b101011: controls <= 10'b0010100000; //SW
		6'b000100: controls <= 10'b0001000010; //BEQ
		6'b001000: controls <= 10'b1010000000; //ADDI
		6'b000010: controls <= 10'b0000001000; //J
		6'b000011: controls <= 10'b1000001001; //JAL
      default:   controls <= 10'bxxxxxxxxxx; //???
    endcase
endmodule

module auxdec(input      [5:0] funct,
              input      [1:0] aluop,
              output reg [2:0] alucontrol,
			  output reg WEHi, WELo, HiLo, multHiLo, JR, Jum);

  always @(*)
    case(aluop)
      2'b00: alucontrol <= 3'b010;  // add
      2'b01: alucontrol <= 3'b110;  // sub 
		2'b10: 
		case(funct)          // RTYPE								Added this because we dont want it to default to Rtype
			6'b100000: begin
								alucontrol <= 3'b010; // ADD
								WEHi <= 0;	
								WELo <= 0;
								HiLo <= 0;
								multHiLo <= 0;
								JR <= 0;
								Jum <=0;
							end
          6'b100010: begin
								alucontrol <= 3'b110; // SUB
								WEHi <= 0;	
								WELo <= 0;
								HiLo <= 0;
								multHiLo <= 0;
								JR <= 0;
								Jum <=0;
							end
          6'b100100: begin 
								alucontrol <= 3'b000; // AND
								WEHi <= 0;	
								WELo <= 0;
								HiLo <= 0;
								multHiLo <= 0;
								JR <= 0;
								Jum <=0;
							end
          6'b100101: begin 
								alucontrol <= 3'b001; // OR
								WEHi <= 0;	
								WELo <= 0;
								HiLo <= 0;
								multHiLo <= 0;
								JR <= 0;
								Jum <=0;
							end
          6'b101010: begin
								alucontrol <= 3'b111; // SLT
								WEHi <= 0;	
								WELo <= 0;
								HiLo <= 0;
								multHiLo <= 0;
								JR <= 0;
								Jum <=0;
							end
		  6'b001000: begin						//	JR
								alucontrol <= 3'b000;
								WEHi <= 0;	
								WELo <= 0;
								HiLo <= 0;
								multHiLo <= 0;
								JR <= 1;
								Jum <=1;
							end
			
		//need case for multiplier
		  6'b011001: begin
								alucontrol<= 3'b000;
								WEHi <= 1;	
								WELo <= 1;
								HiLo <= 0;
								multHiLo <= 0;
								Jum <=0;
						 end
		
		  6'b010010: begin						//	MFLO
								alucontrol<= 3'b000;
								WEHi <= 0;	
								WELo <= 0;
								HiLo <= 0;
								multHiLo <= 1;
								Jum <=0;
							 end
		  6'b010000: begin						//	MFHI
								alucontrol<=3'b000;
								WEHi <= 0;	
								WELo <= 0;
								HiLo <= 1;
								multHiLo <= 1;
								Jum <=0;
							 end
          default:   begin
							alucontrol <= 3'bxxx; // ???
							WEHi <= 0;	
							WELo <= 0;
							HiLo <= 0;
							multHiLo <= 0;
							JR <= 0;
							Jum <=0;
						  end
        endcase
		 default: 
				begin
					alucontrol <= 3'b000; // Default
					WEHi <= 0;	
					WELo <= 0;
					HiLo <= 0;
					multHiLo <= 0;
					JR <= 0;
					Jum <=0;
				end
    endcase
endmodule




module datapath(input         clk, reset,
                input         memtoreg, pcsrc,
                input         alusrc, regdst,
                input         regwrite, jump,
                input  [2:0]  alucontrol,
                output        zero,
                output [31:0] pc,
                input  [31:0] instr,
                output [31:0] aluout, writedata,
                input  [31:0] readdata,
				input WEHi, WELo, HiLo, multHiLo, JAL, JR);

  wire [4:0]  writereg;
  wire [31:0] pcnext, pcnextbr, pcplus4, pcbranch;
  wire [31:0] signimm, signimmsh;
  wire [31:0] srca, srcb;
  wire [31:0] result;
  
  //NEW WIRES ==================================
    wire [63:0] multOut;
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
	regfile		rf(clk, regwrite, instr[25:21], instr[20:16], JALMux2Out, JALMux1Out, srca, writedata);
	mux2 #(5)	wrmux(instr[20:16], instr[15:11], regdst, writereg);
	mux2 #(32)	resmux(aluout, readdata, memtoreg, result);
	signext		se(instr[15:0], signimm);

	// ALU logic
	mux2 #(32)	srcbmux(writedata, signimm, alusrc, srcb);
	alu			alu(srca, srcb, alucontrol, aluout, zero);
				  
//========ADDITION OF NEW MODULES==========

	
	
	mult multi(.RD1(srca), .RD2(writedata), .res(multOut));
	multReg regHi(.in(multOut[63:32]),.WE(WEHi),.out(regHiOut),.clk(clk));
	multReg regLo(.in(multOut[31:0]),.WE(WELo),.out(regLoOut),.clk(clk));
	mux2 #(32) HiLoMux(regLoOut, regHiOut, HiLo, HiLoOut); 
	mux2 #(32) multHiLoMux(result, HiLoOut, multHiLo, multHiLoOut);				  
	
	mux2 #(32) JALMux1(multHiLoOut, pcplus4, JAL, JALMux1Out);
	mux2 #(5) JALMux2(writereg, 5'b11111, JAL, JALMux2Out);
	

	//input JR;
	mux2 #(32) JRMux({pcplus4[31:28], instr[25:0], 2'b00}, srca, JR, JROut);
				  
endmodule
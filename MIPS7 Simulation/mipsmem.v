//------------------------------------------------
// mipsmemsingle.v
// David_Harris@hmc.edu 23 October 2005
// External memories used by MIPS single-cycle
// processor
//------------------------------------------------

module dmem(input         clk, we,
            input  [31:0] a, wd,
            output [31:0] rd);

  reg  [31:0] RAM[63:0];

  assign rd = RAM[a[31:2]]; // word aligned

  always @(posedge clk)
    if (we)
      RAM[a[31:2]] <= wd;
endmodule

module imem(input  [5:0] a,
            output [31:0] rd);

  reg  [31:0] RAM[63:0];

  initial
    begin
      $readmemh("memfile.dat",RAM);
    end

  assign rd = RAM[a]; // word aligned
endmodule

// imem must currently be created with CoreGen for Xilinx synthesis
// or loaded from imem.v for simulation
`timescale 1ns/1ps
module adder_testbench;
   reg reset_; initial begin reset_=0; #22 reset_=1; #600; $stop; end
   reg clock;  initial clock<=0;   always #5 clock<=(!clock);
   reg [31:0] IR;
   wire [31:0] immOut = IMMGEN.immOut;
   initial begin
      wait(reset_==1);
      @(posedge clock); IR = 32'hFFD08013;  // addi x0, x1, -3
      @(posedge clock); IR = 32'h00012423;  // SW   x0, 8(x2)
      @(posedge clock); IR = 32'h00028017;  // auipc x0, 40
      @(posedge clock); IR = 32'h01022003;  // lw x0, 16(x4)
      @(posedge clock); IR = 32'h004000EF;  // jal
      @(posedge clock); IR = 32'h00100863;  // beq
      @(posedge clock); IR = 32'h00104263;  // blt
      #20
      $finish;
   end
   immGenerator IMMGEN(IR, immOut);
endmodule

module immGenerator(instruction, immOut);
   input [31:0] instruction;
   output[31:0] immOut;
   reg[31:0] IMM_OUT;
   wire[6:0] opcode;
   wire[2:0] funct3;

   assign immOut = IMM_OUT;
   assign opcode = instruction[6:0];
   assign funct3 = instruction[14:12];
   always @(instruction) #0.1
   casex(opcode)
        7'b0010011: IMM_OUT <= { {21{instruction[31]}}, instruction[30:25], instruction[24:21], instruction[20]};   // ADDI     -> I-Type
        7'b0100011: IMM_OUT <= { {21{instruction[31]}}, instruction[30:25], instruction[11:8], instruction[7]};     // SW       -> S-Type
        7'b0010111: IMM_OUT <= { instruction[31], instruction[30:20], instruction[19:12], {12{1'b0}} };             // AUIPC    -> U-Type
        7'b0000011: IMM_OUT <= { {21{instruction[31]}}, instruction[30:25], instruction[24:21], instruction[20]};   // LW       -> I-Type
        7'b1101111: IMM_OUT <= { {12{instruction[31]}}, instruction[19:12], instruction[20], instruction[30:25], instruction[24:21], {1{1'b0}}};  // JAL -> J-Type
        7'b1100011: IMM_OUT <= { {20{instruction[31]}}, instruction[7], instruction[30:25], instruction[11:8], {1{1'b0}}};  // BRANCH -> B-Type
        default: IMM_OUT <= 32'bx;
    endcase
endmodule

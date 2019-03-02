`timescale 1ns/1ps
module datapath_testbench;
   reg reset_; initial begin reset_=0; #22 reset_=1; #600; $stop; end
   reg clock;  initial clock<=0;   always #5 clock<=(!clock);
   reg memread, memtoreg, memwrite, selBranch, jump, alusrcA, alusrcB, regwrite;
   reg[3:0] alucontrol;
   reg [31:0] instr, readDataDMem;
   wire[11:0] control;
   assign control = {regwrite, alusrcA, alusrcB, jump, memwrite, memread, memtoreg, alucontrol, selBranch};
   wire zero, LSb_aluresult;
   wire[31:0] readData2, pc, aluout;
   wire[31:0] A, B, RESULT, NPC, PC4, PCD, PCQ, PCB, PC, PCJ,IMM_OUT;
   wire[4:0] A3;
   wire RESET;
   //debug:
   assign A = DP.aluinA, B = DP.aluinB, A3=DP.writereg, RESULT=DP.writeDataRegFile;
   assign  PC4=DP.pcplus4, PCD=DP.pcreg.d, PCQ=DP.pcreg.q, NPC=DP.pcnext, PCB=DP.pcbranch, PCJ=DP.pcMux, PC=DP.pc, RESET=DP.reset_, IMM_OUT = DP.immg.immOut;
   initial begin
      wait(reset_==1);
      @(posedge clock); #1 {regwrite, alusrcA, alusrcB, jump, memwrite, memread, memtoreg, alucontrol, selBranch} <= 12'b111000000100; instr<=32'h00500113; //addi $2, $0, 5
      @(posedge clock); #1 {regwrite, alusrcA, alusrcB, jump, memwrite, memread, memtoreg, alucontrol, selBranch} <= 12'b111000000100; instr<=32'h00C00193; //addi $3, $0, 12
      @(posedge clock); #1 {regwrite, alusrcA, alusrcB, jump, memwrite, memread, memtoreg, alucontrol, selBranch} <= 12'b111000000100; instr<=32'hFF718393; //addi $7, $3, -9
      @(posedge clock); #1 {regwrite, alusrcA, alusrcB, jump, memwrite, memread, memtoreg, alucontrol, selBranch} <= 12'b111000000100; instr<=32'h00300213; //addi $4, $0, 3
      @(posedge clock); #1 {regwrite, alusrcA, alusrcB, jump, memwrite, memread, memtoreg, alucontrol, selBranch} <= 12'b010000010101; instr<=32'h00720463; //beq  $4, $7, 8
      @(posedge clock); #1 {regwrite, alusrcA, alusrcB, jump, memwrite, memread, memtoreg, alucontrol, selBranch} <= 12'b010000010111; instr<=32'h00314263; //blt  $2, $3, 4
      @(posedge clock); #1 {regwrite, alusrcA, alusrcB, jump, memwrite, memread, memtoreg, alucontrol, selBranch} <= 12'b110000010110; instr<=32'h00312433; //slt  $8, $2, $3
      @(posedge clock); #1 {regwrite, alusrcA, alusrcB, jump, memwrite, memread, memtoreg, alucontrol, selBranch} <= 12'b110000000100; instr<=32'h007202B3; //add  $5, $4, $7
      @(posedge clock); #1 {regwrite, alusrcA, alusrcB, jump, memwrite, memread, memtoreg, alucontrol, selBranch} <= 12'b001100000100; instr<=32'hFFDFF06F; //jal  -4
      @(posedge clock); #1 {regwrite, alusrcA, alusrcB, jump, memwrite, memread, memtoreg, alucontrol, selBranch} <= 12'b001100000100; instr<=32'h0040006F; //jal  +4
      @(posedge clock); #1 {regwrite, alusrcA, alusrcB, jump, memwrite, memread, memtoreg, alucontrol, selBranch} <= 12'b110000010100; instr<=32'h40428333; //sub  $6, $5, $4
      @(posedge clock); #1 {regwrite, alusrcA, alusrcB, jump, memwrite, memread, memtoreg, alucontrol, selBranch} <= 12'b111001100100; instr<=32'h00402483; readDataDMem <= 10;  //lw   $9, 4($0)
      @(posedge clock); #1 {regwrite, alusrcA, alusrcB, jump, memwrite, memread, memtoreg, alucontrol, selBranch} <= 12'b011010000100; instr<=32'h00202223; //sw $x2, 4($x0)
      #5
      $display("DATAPATH TESTBENCH");
      $display("REG\t\tRESULT\tEXPECTED");
      $display("R2\t\t%h\t5", DP.rf.regFile[2]);
      $display("R3\t\t%h\tC", DP.rf.regFile[3]);
      $display("R7\t\t%h\t3", DP.rf.regFile[7]);
      $display("ReadData2\t%h\t5\n", DP.rf.readData2);
      $finish;
      #10
      $finish;
   end
   datapath DP(clock, reset_, memtoreg, regwrite, alucontrol, instr, readDataDMem, zero, pc, aluout, readData2, selBranch, alusrcA, alusrcB, jump, LSb_aluresult);
endmodule

module datapath(clock, reset_, memtoreg, regwrite, aluControl, instr, readDataDMem, zero, pc, aluOut, readData2, selBranch, alusrcA, alusrcB, jump, LSb_aluresult);
   input clock, reset_, memtoreg, selBranch, alusrcA, alusrcB, regwrite, jump;
   input[3:0] aluControl;
   input[31:0] instr, readDataDMem;
   output zero, LSb_aluresult;
   output[31:0] pc, aluOut, readData2;
   wire[4:0] writereg;  // is always instr[11:7] in this architecture
   wire[31:0] pcnext, pcplus4, pcbranch, pcMux;
   wire[31:0] immOut, aluinA, aluinB, writeDataRegFile, readData1;
   assign writereg = instr[11:7];

   // next PC logic
   FFD_resettable #(32) pcreg(clock, reset_, pcnext, pc);
   adder                pcaddStart(pc, 32'b100, pcplus4);
   adder       pcaddBranch(pc, immOut, pcbranch);
   mux #(32)   pcBranchMux(pcplus4, pcbranch, selBranch, pcMux);     // selBranch == 0 -> pc | selBranch == 1 -> pcbranch
   mux #(32)   pcJumpMux(pcMux, aluOut, jump, pcnext);               // jump == 0 -> pcMux | jump == 1 -> aluOut

   // register file logic
   regfile     rf(clock, regwrite, instr[19:15], instr[24:20], instr[11:7], writeDataRegFile, readData1, readData2);
   mux #(32)   muxToWrite(aluOut, readDataDMem, memtoreg, writeDataRegFile);
   immGenerator immg(instr, immOut);

   // ALU logic
   mux #(32)  muxsrcB(readData2, immOut, alusrcB, aluinB);
   mux #(32)  muxsrcA(pc, readData1, alusrcA, aluinA);
   alu        alu(aluinA, aluinB, aluControl, aluOut, zero, LSb_aluresult);
endmodule

module regfile(clock, regWrite, readReg1, readReg2, regDest, writeData, readData1, readData2);
   input clock, regWrite;
   input[4:0] readReg1, readReg2, regDest;
   input[31:0] writeData;
   output[31:0] readData1, readData2;
   reg[31:0] readData1, readData2;
   reg[31:0] regFile[0:31];

   always @(negedge clock) if (regWrite == 1) regFile[regDest] <= writeData;
   always @(readReg1) readData1 <= (readReg1 != 0) ? regFile[readReg1] : 0;
   always @(readReg2) readData2 <= (readReg2 != 0) ? regFile[readReg2] : 0;
endmodule

module adder(a, b,  out);
   input[31:0] a, b;
   output[31:0] out;
   assign out = OUT(a, b);

   function [31:0] OUT;
       input [31:0] a, b;
       begin
       casex(b[31])
           1'b1:   begin
                   b = ~b;
                   b = b + 1'b1;
                   OUT = a - b;
                   end
           default: OUT = a + b;
       endcase
     end
   endfunction
endmodule

module alu(a, b, aluctrl,  aluOut, zero, LSb_aluresult);
   input  [31:0] a, b;
   input  [3:0] aluctrl;
   output[31:0] aluOut;
   output zero, LSb_aluresult;
   reg[31:0] aluOut;
   assign zero = (aluOut==0) ? 1 : 0;
   assign LSb_aluresult = aluOut[0];
   always @(aluctrl or a or b)
      casex (aluctrl)
         0: aluOut <= a & b;
         1: aluOut <= a | b;
         2: aluOut <= OUT(a, b);
         4: aluOut <= a * b;
         5: aluOut <= a / b;
         10: aluOut <= a - b;
         11: aluOut <= (a < b) ? 1:0;
         default: aluOut<=0;
      endcase

      /* Function to signed operation*/
      function [31:0] OUT;
          input [31:0] a, b;
          begin
          casex(b[31])
              1'b1:   begin
                      b = ~b;
                      b = b + 1'b1;
                      OUT = a - b;
                      end
              default: OUT = a + b;
          endcase
          end
      endfunction
endmodule

module FFD_resettable(clock, reset_, d, q);
   parameter WIDTH = 32;
   input  [WIDTH-1:0] d;
   input clock, reset_;
   output [WIDTH-1:0] q;
   reg [WIDTH-1:0] q;
   always @(posedge clock)
      #1.2 if (!reset_) q <= 0;
      else q <= d;
endmodule

module mux (data0, data1, sel, out);
  parameter WIDTH = 32;
  input [WIDTH-1:0] data0, data1;
  input sel;
  output [WIDTH-1:0] out;

  assign out = (sel == 1) ? data1 : data0;
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

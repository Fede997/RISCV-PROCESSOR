`timescale 1ns/1ps
module core_testbench;
 reg reset_; initial begin reset_=0; #22 reset_=1; #300; $stop; end
 reg clock;  initial clock=0; always #5 clock<=(!clock);
 reg[31:0] IR;
 reg[31:0] READDATADMEM;

 wire[31:0] PC=mc.pc;
 wire WE=mc.memwrite;
 wire RE=mc.memread;
 wire[31:0] RD2=mc.readData2;
 wire[31:0] ALUOUT=mc.aluOut;
 initial begin
 wait(reset_==1);
 @(posedge clock); IR<=32'h00500113; READDATADMEM<=32'h00000001;
 @(posedge clock); IR<=32'h00C00193; READDATADMEM<=32'h00000002;
 @(posedge clock); IR<=32'hFF718393; READDATADMEM<=32'h00000003;
 @(posedge clock); IR<=32'h00300213; READDATADMEM<=32'h00000004;
 @(posedge clock); IR<=32'h00720463; READDATADMEM<=32'h00000005;
 @(posedge clock); IR<=32'h00314263; READDATADMEM<=32'h00000006;
 @(posedge clock); IR<=32'h00312433; READDATADMEM<=32'h00000007;
 @(posedge clock); IR<=32'h007202B3; READDATADMEM<=32'h00000008;
 @(posedge clock); IR<=32'hFFDFF06F; READDATADMEM<=32'h00000009;
 #15 $finish;
 end
 core mc(clock,reset,READDATADMEM, IR, PC,WE,RD,ALUOUT,RD2);
endmodule

module core(clock, reset_, readDataDMem, instr, pc, memwrite,memread, aluOut, readData2);
   input clock, reset_;
   input[31:0] readDataDMem,instr;
   output[31:0] pc, aluOut, readData2;
   output memwrite, memread;
   wire memtoreg,alusrcA,alusrcB,regwrite,selBranch,jump,zero,LSb_aluresult;
   wire[3:0] alucontrol;

   controller C(instr[6:0], instr[31:25], instr[14:12], zero, LSb_aluresult, memtoreg, memwrite, memread, selBranch, alusrcA, alusrcB, regwrite, alucontrol, jump);
   datapath DP(clock, reset_, memtoreg, regwrite, alucontrol, instr, readDataDMem, zero, pc, aluOut, readData2, selBranch, alusrcA, alusrcB, jump, LSb_aluresult);
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

   reg [31:0] MemAddressRef;
   reg ZERO;
   reg [31:0] InstrPC;
   reg [31:0] RD2;

   assign aluOut = MemAddressRef, readData2 = RD2, zero = ZERO, pc = InstrPC;
   always@(instr)
    begin
    $display("memtoreg = %b, selBranch = %b, alusrcA = %b, alusrcB = %b, regwrite = %b, jump = %b, aluControl = %b, istr = %b, readDataDMem = %b",
             memtoreg, selBranch, alusrcA, alusrcB, regwrite, jump, aluControl, instr, readDataDMem);
    MemAddressRef<=32'h0000001B; RD2<=32'h10FEDE01; ZERO<=1; InstrPC<=32'h00000010;
    end

endmodule

module controller(opcode, funct7, funct3, zero, LSb_aluresult, memtoreg, memwrite, memread, selBranch, alusrcA, alusrcB, regwrite, alucontrol, jump);
   input[6:0] opcode;
   input[6:0] funct7;
   input[2:0] funct3;
   input zero;
   input LSb_aluresult; // Less significant bit of alu result
   output memtoreg, memwrite, memread, alusrcA, alusrcB ,regwrite, selBranch, jump;
   output [3:0] alucontrol;
   wire [1:0] aluop;
   wire branch;
   reg [11:0] control;
   assign {regwrite, alusrcA, alusrcB, jump, memwrite, memread, memtoreg, alucontrol, selBranch} = control;
   always@(opcode)
    begin
      $display("regwrite = %b, alusrcA = %b, alusrcB = %b, jump = %b, memwrite = %b, memread = %b, memtoreg = %b, alucontrol = %b, selBranch = %b",
               regwrite, alusrcA, alusrcB,jump, memwrite, memread, memtoreg, alucontrol, selBranch);
      control <= 010101010101;
    end
endmodule

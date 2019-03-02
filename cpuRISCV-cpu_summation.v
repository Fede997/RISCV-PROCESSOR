`timescale 1ns/1ps
module Cpu_testbench;
   reg reset_; initial begin reset_=0; #22 reset_=1; #450 $stop; end
   reg clock;  initial clock=0; always #5 clock<=(!clock);
   wire[31:0] PC,IR,D,Q,A,B,RESULT, SELBRANCH, ZERO, LSB, PCBRANCH, PCNEXT, PCMUX, R6;
   wire RESET;

   assign PC=Cpu.mycore.DP.pc, IR=Cpu.mycore.DP.instr;
   assign SELBRANCH = Cpu.mycore.C.selBranch;
   assign ZERO = Cpu.mycore.C.zero;
   assign LSB = Cpu.mycore.C.LSb_aluresult;
   assign PCMUX = Cpu.mycore.DP.pcMux;
   assign PCBRANCH = Cpu.mycore.DP.pcbranch;
   assign PCNEXT = Cpu.mycore.DP.pcnext;
   assign RESET=Cpu.mycore.DP.pcreg.reset_;
   assign Q=Cpu.mycore.DP.pcreg.q;
   assign D=Cpu.mycore.DP.pcreg.d;
   assign A=Cpu.mycore.DP.aluinA;
   assign B=Cpu.mycore.DP.aluinB;
   assign RESULT=Cpu.mycore.DP.writeDataRegFile;
   assign R6 = Cpu.mycore.DP.rf.regFile[6];
   
   initial begin wait(reset_); #400
      $display("REG\tRESULT\tEXPECTED");
      $display("R6\t%h\tF",Cpu.mycore.DP.rf.regFile[6]);
      $finish;
   end
   risc_v Cpu(clock,reset_);
endmodule

module risc_v(clock,reset_);
   input clock, reset_;
   wire memwrite;
   wire [31:0] readDataDMem, instr, pc, aluOut, readData2;

   core mycore(clock, reset_, readDataDMem, instr, pc, memwrite, memread, aluOut, readData2);
   instructionMemory imem(pc[7:2], instr);
   dataMemory dmem(clock, memwrite, aluOut[5:0], readData2,  readDataDMem);
endmodule

module core(clock, reset_, readDataDMem, instr, pc, memwrite, memread, aluOut, readData2);
   input clock, reset_;
   input[31:0] readDataDMem,instr;
   output[31:0] pc, aluOut, readData2;
   output memwrite, memread;
   wire memtoreg,alusrcA,alusrcB,regwrite,selBranch,jump,zero,LSb_aluresult;
   wire[3:0] alucontrol;

   controller C(instr[6:0], instr[31:25], instr[14:12], zero, LSb_aluresult, memtoreg, memwrite, memread, selBranch, alusrcA, alusrcB, regwrite, alucontrol, jump);
   datapath DP(clock, reset_, memtoreg, regwrite, alucontrol, instr, readDataDMem, zero, pc, aluOut, readData2, selBranch, alusrcA, alusrcB, jump, LSb_aluresult);
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

   maindec MainDec(opcode, memtoreg, memwrite, memread, jump, branch, alusrcA, alusrcB, regwrite, aluop, funct3);
   aludec  AluDec(funct7, funct3, aluop, alucontrol);

   // Branch selection
   wire beq_enable;
   wire blt_enable;
   assign beq_enable = branch & zero;
   assign blt_enable = branch & LSb_aluresult;
   // To avoid delay of the  2-input AND gate (propagation time = 60ps)
   assign selBranch = (opcode==7'b1100011) ? ( (funct3==3'b000) ? beq_enable : blt_enable ) :
                      opcode==7'b0110011 ? 1'b0 :
                      opcode==7'b0000011 ? 1'b0 :
                      opcode==7'b0100011 ? 1'b0 :
                      opcode==7'b0010011 ? 1'b0 :
                      opcode==7'b0010111 ? 1'b0 :
                      opcode==7'b1101111 ? 1'b0 : 1'bx;
endmodule

module maindec(opcode, memtoreg, memwrite, memread, jump, branch, alusrcA, alusrcB, regwrite, aluop, funct3);
   input [6:0] opcode;
   input [2:0] funct3;
   output memtoreg, memwrite, memread, jump, branch, alusrcA, alusrcB, regwrite;
   output [1:0] aluop;
   reg [9:0] controls;
   assign {regwrite, alusrcA, alusrcB, jump, branch, memwrite, memread, memtoreg, aluop} = controls;
   always @(opcode or funct3)
   casex(opcode)
     7'b0110011: controls <= 10'b1100000011;  // R-Type
     7'b0000011: controls <= 10'b1110001100;  // LW
     7'b0100011: controls <= 10'b0110010000;  // SW
     7'b0010011: controls <= 10'b1110000000;  // ADDI
     7'b0010111: controls <= 10'b1010000000;  // AUIPC
     7'b1101111: controls <= 10'b0011000000;  // JAL
     7'b1100011: casex(funct3)
                   3'b000: controls <= 10'b0100100001;  // BEQ
                   3'b100: controls <= 10'b0100100010;  // BLT
                   default: controls <= 10'bxxxxxxxxxx; // illegal op
                 endcase
     default: controls <= 10'bxxxxxxxxxx; // illegal op
   endcase
endmodule

module aludec(funct7, funct3, aluop, alucontrol);
    input [6:0] funct7;
    input [2:0] funct3;
    input [1:0] aluop;
    output [3:0] alucontrol;
    reg [3:0] alucontrol;
    always @(aluop or funct7 or funct3)
    case(aluop)
      2'b00: alucontrol <= 4'b0010; //add (for lw/sw/addi/auipc/jal)
      2'b01: alucontrol <= 4'b1010; //sub (for beq)
      2'b10: alucontrol <= 4'b1011; //slt (for blt)
      2'bxx: alucontrol <= 4'bxxxx;
      // R-type instructions
      default: casex(funct7)
        7'b0000000: casex(funct3)
		        3'b000: alucontrol <= 4'b0010; //add
		        3'b111: alucontrol <= 4'b0000; //and
		        3'b110: alucontrol <= 4'b0001; //or
		        3'b010: alucontrol <= 4'b1011; //slt
                      default: alucontrol <= 4'bxxxx;
			endcase
	 7'b0000001: casex(funct3)
                      3'b000: alucontrol <= 4'b0100; //mul
                      3'b100: alucontrol <= 4'b0101; //div
                      default: alucontrol <= 4'bxxxx;
		      endcase
	 7'b0100000: alucontrol <= 4'b1010; //sub
	 default: alucontrol <= 4'bxxxx;	//illegal operation
       endcase
    endcase
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
   always @(readReg1) readData1 <= (readReg1 != 0) ? regFile[readReg1] : 0;     // hard-written zero
   always @(readReg2) readData2 <= (readReg2 != 0) ? regFile[readReg2] : 0;     // hard-written zero
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

module dataMemory(clock, writeEnable, address, writeData, readData);
   input clock, writeEnable;
   input[5:0] address;
   input[31:0] writeData;
   output[31:0] readData;
   reg [31:0] RAM2[0:63];
   assign readData = RAM2[address[5:2]];
   always @(posedge clock)
   if (writeEnable) RAM2[address[5:2]] <= writeData;
endmodule

module instructionMemory(address, readData);
   input [5:0] address;
   output [31:0] readData;
   reg [31:0] RAM[0:63];
   initial $readmemh("summation.dat", RAM);
   assign readData = RAM[address];
endmodule

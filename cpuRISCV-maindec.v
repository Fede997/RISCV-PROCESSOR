`timescale 1ns / 1ps
module maindec_testbench;
   reg reset_; initial begin reset_=0; #22 reset_=1; #600; $stop; end
   reg clock;  initial clock<=0;   always #5 clock<=(!clock);
   reg[31:0] IR;
   wire[6:0] opcode;
   wire memtoreg, memwrite, memread, jump, branch, alusrcA, alusrcB ,regwrite;
   wire [2:0] funct3;
   wire[1:0] aluop;
   wire[9:0] control;
   assign control = {regwrite, alusrcA, alusrcB, jump, branch, memwrite, memread, memtoreg, aluop};
   initial begin
         $display("MAINDEC TESTBENCH");
         $display("Instruction\tControl");
         @(posedge clock); IR<=32'h0000A017; $strobe("AUIPC\t\t%b", control);
         @(posedge clock); IR<=32'h004000EF; $strobe("JAL\t\t%b", control);
         @(posedge clock); IR<=32'h00512003; $strobe("LW\t\t%b", control);
         @(posedge clock); IR<=32'h000122A3; $strobe("SW\t\t%b", control);
         @(posedge clock); IR<=32'h00104263; $strobe("BLT\t\t%b", control);
         @(posedge clock); IR<=32'h00408013; $strobe("ADDI\t\t%b", control);
         @(posedge clock); IR<=32'h00208033; $strobe("ADD\t\t%b", control);
         @(posedge clock); IR<=32'h00100263; $strobe("BEQ\t\t%b", control);
         @(posedge clock); IR<=32'hFFFFFFFF; $strobe("ILLEGAL OP\t%b\n", control);
      #30
      $finish;
   end
   assign opcode = IR[6:0];
   assign funct3 = IR[14:12];
   maindec MD(opcode, memtoreg, memwrite, memread, jump, branch, alusrcA, alusrcB, regwrite, aluop, funct3);
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
     7'b0010111: controls <= 10'b1110000000;  // AUIPC
     7'b1101111: controls <= 10'b0011000000;  // JAL
     7'b1100011: casex(funct3)
                   3'b000: controls <= 10'b0100100001;  // BEQ
                   3'b100: controls <= 10'b0100100010;  // BLT
                   default: controls <= 10'bxxxxxxxxxx; // illegal op
                 endcase
     default: controls <= 10'bxxxxxxxxxx; // illegal op
   endcase
endmodule

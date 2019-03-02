`timescale 1ns / 1ps
module controller_testbench;
   reg reset_; initial begin reset_=0; #22 reset_=1; #600; $stop; end
   reg clock;  initial clock<=0;   always #5 clock<=(!clock);
   reg[31:0] IR;
   reg ZERO;
   reg LSB_ALURESULT;
   reg BRANCH;
   wire[6:0] opcode;
   wire[6:0] funct7;
   wire[2:0] funct3;
   wire memtoreg, memread, memwrite, branch, alusrcA, alusrcB , regwrite, jump, selBranch, LSb_aluresult, zero;
   wire[3:0] alucontrol;
   wire[11:0] control;
   assign control = {regwrite, alusrcA, alusrcB, jump, memwrite, memread, memtoreg, alucontrol, selBranch};
   initial begin
      $display("CONTROLLER TESTBENCH");
      $display("Instruction\t Control \t   Aluop");

      @(posedge clock); IR<=32'h0000A017; ZERO<=1'b0; LSB_ALURESULT<=1'b0; $strobe("AUIPC\t\t %b\t   %b", control,CTRL.aluop);
      @(posedge clock); IR<=32'h004000EF; ZERO<=1'b0; LSB_ALURESULT<=1'b0; $strobe("JAL\t\t %b\t   %b", control,CTRL.aluop);
      @(posedge clock); IR<=32'h00512003; ZERO<=1'b0; LSB_ALURESULT<=1'b0; $strobe("LW \t\t %b\t   %b", control,CTRL.aluop);
      @(posedge clock); IR<=32'h000122A3; ZERO<=1'b0; LSB_ALURESULT<=1'b0; $strobe("SW \t\t %b\t   %b", control,CTRL.aluop);
      @(posedge clock); IR<=32'h00104263; ZERO<=1'b0; LSB_ALURESULT<=1'b1; $strobe("BLT \t\t %b\t   %b", control,CTRL.aluop);
      @(posedge clock); IR<=32'h00600293; ZERO<=1'b0; LSB_ALURESULT<=1'b0; $strobe("ADDI \t\t %b\t   %b", control,CTRL.aluop);
      @(posedge clock); IR<=32'h00208033; ZERO<=1'b0; LSB_ALURESULT<=1'b0; $strobe("ADD \t\t %b\t   %b", control,CTRL.aluop);
      @(posedge clock); IR<=32'h00312433; ZERO<=1'b0; LSB_ALURESULT<=1'b0; $strobe("SLT \t\t %b\t   %b", control,CTRL.aluop);
      @(posedge clock); IR<=32'h00100263; ZERO<=1'b1; LSB_ALURESULT<=1'b0; $strobe("BEQ \t\t %b\t   %b", control,CTRL.aluop);
      @(posedge clock); IR<=32'h00100263; ZERO<=1'b1; LSB_ALURESULT<=1'b0; $strobe("BEQ \t\t %b\t   %b", control,CTRL.aluop);
      @(posedge clock); IR<=32'hFFFFFFFF; ZERO<=1'bx; LSB_ALURESULT<=1'bx; $strobe("ILLEGAL OP\t %b\t   %b\n", control, CTRL.aluop);
      #15
      $finish;
   end
   //
   assign opcode = IR[6:0];
   assign funct7 = IR[31:25];
   assign funct3 = IR[14:12];
   assign zero   = ZERO;
   assign LSb_aluresult = LSB_ALURESULT;
   assign CTRL.branch = BRANCH;
   //
   controller CTRL(opcode, funct7, funct3, zero, LSb_aluresult, memtoreg, memwrite, memread, selBranch, alusrcA, alusrcB, regwrite, alucontrol, jump);
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
   //
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

`timescale 1ns/1ps
module aludec_testbench;
   reg reset_; initial begin reset_=0; #18 reset_=1; #300; $stop; end
   reg clock;  initial clock=0; always #5 clock<=(!clock);
   //
   wire [6:0] funct7;
   wire [2:0] funct3;
   reg [1:0] aluop;
   wire [3:0] alucontrol;
   reg [31:0] IR;
   //
   assign funct7 = IR[31:25];
   assign funct3 = IR[14:12];
   aludec ALUdec(funct7,funct3,aluop,alucontrol);
   //

   initial begin
      $display("ALUDEC TESTBENCH");
      $display("Instruction\tAluop\tFunct7\t   Funct3\tAlucontrol\t");
      wait(reset_==1);
      @(posedge clock); IR<=32'h007302B3; aluop=2'b11; $strobe("ADD:\t\t%b\t%b   %b\t\t%b",aluop,funct7,funct3,alucontrol); //addprova
      @(posedge clock); IR<=32'h407302B3; aluop=2'b11; $strobe("SUB:\t\t%b\t%b   %b\t\t%b",aluop,funct7,funct3,alucontrol); //sub
      @(posedge clock); IR<=32'h00432283; aluop=2'b00; $strobe("LW:\t\t%b\t%b   %b\t\t%b",aluop,funct7,funct3,alucontrol); //lw
      @(posedge clock); IR<=32'h00532223; aluop=2'b00; $strobe("SW:\t\t%b\t%b   %b\t\t%b",aluop,funct7,funct3,alucontrol); //sw
      @(posedge clock); IR<=32'h007372B3; aluop=2'b11; $strobe("AND:\t\t%b\t%b   %b\t\t%b",aluop,funct7,funct3,alucontrol); //and
      @(posedge clock); IR<=32'h007362B3; aluop=2'b11; $strobe("OR:\t\t%b\t%b   %b\t\t%b",aluop,funct7,funct3,alucontrol); //or
      @(posedge clock); IR<=32'h007322B3; aluop=2'b11; $strobe("SLT:\t\t%b\t%b   %b\t\t%b",aluop,funct7,funct3,alucontrol); //slt
      @(posedge clock); IR<=32'h027302B3; aluop=2'b11; $strobe("MUL:\t\t%b\t%b   %b\t\t%b",aluop,funct7,funct3,alucontrol); //mul
      @(posedge clock); IR<=32'h027342B3; aluop=2'b11; $strobe("DIV:\t\t%b\t%b   %b\t\t%b",aluop,funct7,funct3,alucontrol); //div
      @(posedge clock); IR<=32'hFC628EE3; aluop=2'b01; $strobe("BEQ:\t\t%b\t%b   %b\t\t%b",aluop,funct7,funct3,alucontrol); //beq
      @(posedge clock); IR<=32'hFC62CCE3; aluop=2'b10; $strobe("BLT:\t\t%b\t%b   %b\t\t%b",aluop,funct7,funct3,alucontrol); //blt
      @(posedge clock); IR<=32'h00A30293; aluop=2'b00; $strobe("ADDI:\t\t%b\t%b   %b\t\t%b",aluop,funct7,funct3,alucontrol); //addi
      @(posedge clock); IR<=32'h0000A097; aluop=2'b00; $strobe("AUIPC:\t\t%b\t%b   %b\t\t%b",aluop,funct7,funct3,alucontrol); //auipc
      @(posedge clock); IR<=32'hFFFFFFFF; aluop=2'b11; $strobe("ILL. OP: \t%b\t%b   %b\t\t%b\n",aluop,funct7,funct3,alucontrol); //illegal operation
      #10 $finish;
   end
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

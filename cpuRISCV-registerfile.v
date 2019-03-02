`timescale 1ns/1ps
module regfile_testbench;
   reg reset_; initial begin reset_=0; #22 reset_=1; #600; $stop; end
   reg clock;  initial clock<=0;   always #5 clock<=(!clock);
   reg [4:0] RS, RT, RD;
   reg REG_WRITE;
   reg [31:0] WRITE_DATA_REG;
   wire [31:0] readData1, readData2;
   initial begin
      wait(reset_==1); RS<=32'hXXXXXXXX; RT<=32'hXXXXXXXX; REG_WRITE<=0;
      @(posedge clock); RS<=0;  RT<=1;   @(posedge clock); RS<=1;  RT<=2;   @(posedge clock); RS<=2;  RT<=3;   @(posedge clock); RS<=3;  RT<=4;
      @(posedge clock); RS<=4;  RT<=5;   @(posedge clock); RS<=5;  RT<=6;   @(posedge clock); RS<=6;  RT<=7;   @(posedge clock); RS<=7;  RT<=8;
      @(posedge clock); RS<=8;  RT<=9;   @(posedge clock); RS<=9;  RT<=10;  @(posedge clock); RS<=10; RT<=11;  @(posedge clock); RS<=11; RT<=12;
      @(posedge clock); RS<=12; RT<=13;  @(posedge clock); RS<=13; RT<=14;  @(posedge clock); RS<=14; RT<=15;  @(posedge clock); RS<=15; RT<=16;
      #10 REG_WRITE<=1; WRITE_DATA_REG=32'h12345678;
      @(posedge clock); RD<=0;  WRITE_DATA_REG<=1;  @(posedge clock); RD<=1;  WRITE_DATA_REG<=2;  @(posedge clock); RD<=2;  WRITE_DATA_REG<=3;  @(posedge clock); RD<=3;  WRITE_DATA_REG<=4;
      @(posedge clock); RD<=4;  WRITE_DATA_REG<=5;  @(posedge clock); RD<=5;  WRITE_DATA_REG<=6;  @(posedge clock); RD<=6;  WRITE_DATA_REG<=7;  @(posedge clock); RD<=7;  WRITE_DATA_REG<=8;
      @(posedge clock); RD<=8;  WRITE_DATA_REG<=9;  @(posedge clock); RD<=9;  WRITE_DATA_REG<=10; @(posedge clock); RD<=10; WRITE_DATA_REG<=11; @(posedge clock); RD<=11; WRITE_DATA_REG<=12;
      @(posedge clock); RD<=12; WRITE_DATA_REG<=13; @(posedge clock); RD<=13; WRITE_DATA_REG<=14; @(posedge clock); RD<=14; WRITE_DATA_REG<=15; @(posedge clock); RD<=15; WRITE_DATA_REG<=16;
      #10 RS<=32'hXXXXXXXX; RT<=32'hXXXXXXXX; REG_WRITE<=0; #10
      @(posedge clock); RS<=0;  RT<=1;   @(posedge clock); RS<=1;  RT<=2;   @(posedge clock); RS<=2;  RT<=3;   @(posedge clock); RS<=3;  RT<=4;
      @(posedge clock); RS<=4;  RT<=5;   @(posedge clock); RS<=5;  RT<=6;   @(posedge clock); RS<=6;  RT<=7;   @(posedge clock); RS<=7;  RT<=8;
      @(posedge clock); RS<=8;  RT<=9;   @(posedge clock); RS<=9;  RT<=10;  @(posedge clock); RS<=10; RT<=11;  @(posedge clock); RS<=11; RT<=12;
      @(posedge clock); RS<=12; RT<=13;  @(posedge clock); RS<=13; RT<=14;  @(posedge clock); RS<=14; RT<=15;  @(posedge clock); RS<=15; RT<=16;
      #180 $finish;
   end
   regfile REGF(clock, REG_WRITE, RS, RT, RD, WRITE_DATA_REG, readData1, readData2);
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

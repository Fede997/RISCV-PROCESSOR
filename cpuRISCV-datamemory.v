`timescale 1ns/1ps
module dmem_testbench;
   reg reset_; initial begin reset_=0; #22 reset_=1; #600; $stop; end
   reg clock;  initial clock<=0;   always #5 clock<=(!clock);
   reg [5:0] memAddressRef;
   reg writeEnable;
   reg [31:0] writeDataReg;
   wire [31:0] readDataReg;
   initial begin
      wait(reset_==1); memAddressRef<=32'hXXXXXXXX; writeEnable<=0;
      @(posedge clock); memAddressRef<=0;  @(posedge clock); memAddressRef<=4;  @(posedge clock); memAddressRef<=8;  @(posedge clock); memAddressRef<=12;
      @(posedge clock); memAddressRef<=16; @(posedge clock); memAddressRef<=20; @(posedge clock); memAddressRef<=24; @(posedge clock); memAddressRef<=28;
      @(posedge clock); memAddressRef<=32; @(posedge clock); memAddressRef<=36; @(posedge clock); memAddressRef<=40; @(posedge clock); memAddressRef<=44;
      @(posedge clock); memAddressRef<=48; @(posedge clock); memAddressRef<=52; @(posedge clock); memAddressRef<=56; @(posedge clock); memAddressRef<=60;
      #10 writeEnable <=1; writeDataReg=32'h12345678;
      @(posedge clock); memAddressRef<=0;  writeDataReg<=1;  @(posedge clock); memAddressRef<=4;  writeDataReg<=2;  @(posedge clock); memAddressRef<=8;  writeDataReg<=3;  @(posedge clock); memAddressRef<=12; writeDataReg<=4;
      @(posedge clock); memAddressRef<=16; writeDataReg<=5;  @(posedge clock); memAddressRef<=20; writeDataReg<=6;  @(posedge clock); memAddressRef<=24; writeDataReg<=7;  @(posedge clock); memAddressRef<=28; writeDataReg<=8;
      @(posedge clock); memAddressRef<=32; writeDataReg<=9;  @(posedge clock); memAddressRef<=36; writeDataReg<=10; @(posedge clock); memAddressRef<=40; writeDataReg<=11; @(posedge clock); memAddressRef<=44; writeDataReg<=12;
      @(posedge clock); memAddressRef<=48; writeDataReg<=13; @(posedge clock); memAddressRef<=52; writeDataReg<=14; @(posedge clock); memAddressRef<=56; writeDataReg<=15; @(posedge clock); memAddressRef<=60; writeDataReg<=16;
      #10 memAddressRef<=32'hXXXXXXXX; writeEnable<=0; #10
      @(posedge clock); memAddressRef<=0;  @(posedge clock); memAddressRef<=4;  @(posedge clock); memAddressRef<=8;  @(posedge clock); memAddressRef<=12;
      @(posedge clock); memAddressRef<=16; @(posedge clock); memAddressRef<=20; @(posedge clock); memAddressRef<=24; @(posedge clock); memAddressRef<=28;
      @(posedge clock); memAddressRef<=32; @(posedge clock); memAddressRef<=36; @(posedge clock); memAddressRef<=40; @(posedge clock); memAddressRef<=44;
      @(posedge clock); memAddressRef<=48; @(posedge clock); memAddressRef<=52; @(posedge clock); memAddressRef<=56; @(posedge clock); memAddressRef<=60;
      #10 $finish;
   end
   dataMemory DMEM(clock,writeEnable,memAddressRef,writeDataReg,readDataReg);
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

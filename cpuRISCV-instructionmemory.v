`timescale 1ns/1ps
module imem_testbench;
   reg reset_; initial begin reset_=0; #22 reset_=1; #300; $stop; end
   reg clock;  initial clock=0; always #5 clock<=(!clock);
   reg [5:0] address;
   wire [31:0] IR;
   initial begin
      wait(reset_==1); address<=32'hXXXXXXXX;
      @(posedge clock); address<=0;
      @(posedge clock); address<=1;
      @(posedge clock); address<=2;
      @(posedge clock); address<=3;
      @(posedge clock); address<=4;
      @(posedge clock); address<=5;
      @(posedge clock); address<=6;
      @(posedge clock); address<=7;
      @(posedge clock); address<=8;
      @(posedge clock); address<=9;
      @(posedge clock); address<=10;
      @(posedge clock); address<=11;
      @(posedge clock); address<=12;
      @(posedge clock); address<=13;
      @(posedge clock); address<=14;
      @(posedge clock); address<=15;
      #10 $finish;
   end
   instructionMemory IMEM(address,IR);
endmodule

module instructionMemory(address, readData);
   input [5:0] address;
   output [31:0] readData;
   reg [31:0] RAM[0:63];
   initial $readmemh("instruction_memory_testbench.dat", RAM);
   assign readData = RAM[address];
endmodule

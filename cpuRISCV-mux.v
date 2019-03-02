`timescale 1ns/1ps
module mux_testbench;
 reg reset_; initial begin reset_=0; #22 reset_=1; #300; $stop; end
 reg clock;  initial clock=0; always #5 clock<=(!clock);
 reg[5:0] X0, X1;
 reg[31:0] A, B;
 wire[31:0] OUT= MUX_32.out;
 reg SEL;
 wire[5:0] Z = MUX_6.out;
 initial begin
 wait(reset_==1);  X0=0; X1=0;
 @(posedge clock); X0<=7;  X1=8;    A=0; B=32'hABCDEF01; SEL<=0; @(posedge clock); SEL<=1;
 @(posedge clock); X0<=99; X1=110;  A=0; B=32'h10FEDCBA; SEL<=0; @(posedge clock); SEL<=1;
 @(posedge clock); X0<=1;  X1=2;    A=32'h10FEDE01; B=0; SEL<=0; @(posedge clock); SEL<=1;
 #20 $finish;
 end
 mux #(6) MUX_6(X0, X1, SEL, Z);    // 6  bit multiplexer
 mux      MUX_32(A, B, SEL, OUT);   // 32 bit multiplexer
endmodule

module mux (data0, data1, sel, out);
  parameter WIDTH = 32;
  input [WIDTH-1:0] data0, data1;
  input sel;
  output [WIDTH-1:0] out;

  assign out = (sel == 1) ? data1 : data0;
endmodule

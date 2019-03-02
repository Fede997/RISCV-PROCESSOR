`timescale 1ns/1ps
module flopr_testbench;
 reg reset_; initial begin reset_=0; #22 reset_=1; #300; $stop; end
 reg clock;  initial clock=0; always #5 clock<=(!clock);
 reg[5:0] X;
 reg[31:0] D;
 wire[5:0] Z  = FFD6.q;
 wire[31:0] Q=FFD32.q;

 initial begin
 wait(reset_==1); X<=0; D<=0;
     @(posedge clock); X<=6'h05; D<=8'hA;
     @(posedge clock); X<=6'h2A; D<=0;
     @(posedge clock); X<=6'hFE; D<=8'h11;
     @(posedge clock); X<=6'h10; D<=8'h5E;
     #20
     $finish;
 end

 FFD_resettable #(6) FFD6(clock, reset_, X, Z);     // 6  bit FFD
 FFD_resettable      FFD32(clock, reset_, D, Q);    // 32 bit FFD
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

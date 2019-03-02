`timescale 1ns/1ps
module adder_testbench;
   reg reset_; initial begin reset_=0; #22 reset_=1; #600; $stop; end
   reg clock;  initial clock<=0;   always #5 clock<=(!clock);
   reg [31:0] A, B;
   wire [31:0] Result;
   initial begin
      $display("ADDER TESTBENCH");
      $display("A\t\tB\t\tA+B");
      wait(reset_==1);
      @(posedge clock); A=32'h10FEDE01; B=32'h00000001; $strobe("%h\t%h\t%h", A, B, ADD.Result); // Should output 0000000F
      @(posedge clock); A=32'b00000000; B=32'b100; $strobe("%h\t%h\t%h", A, B, ADD.Result); // Should output 0000c639
      @(posedge clock); A=32'h000049DF; B=32'h0000029A; $strobe("%H\t%h\t%h\n", A, B, ADD.Result); // Should output 00004c79
      #20
      $finish;
   end
   adder ADD(A, B, Result);
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

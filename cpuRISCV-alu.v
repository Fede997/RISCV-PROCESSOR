`timescale 1ns/1ps
module alu_testbench;
   reg reset_; initial begin reset_=0; #22 reset_=1; #600; $stop; end
   reg clock;  initial clock<=0;   always #5 clock<=(!clock);
   reg [31:0] A, B; reg [3:0] ALUControl;
   wire [31:0] Result;
   wire Zero, LSb_aluresult;
   initial begin
      wait(reset_==1);

      // Addition unit testing
      ALUControl<=4'b0010;
      @(posedge clock); A=32'h0000000F; B=32'hFFFFFFF0; // Should output FFFFFFFF, signed test
      @(posedge clock); A=32'h00001234; B=32'h00000105; // Should output 00001339
      #10
      // AND unit testing
      ALUControl<=4'b0000;
      @(posedge clock); A=32'h00000DEF; B=32'h00000ABC; // Should output 000008AC
      @(posedge clock); A=32'h00001234; B=32'h00000105; // Should output 00000004
      #10
      // OR unit testing
      ALUControl<=4'b0001;
      @(posedge clock); A=32'h00000DEF; B=32'h00000ABC; // Should output 00000FFF
      @(posedge clock); A=32'h00001234; B=32'h00000105; // Should output 00001335
      #10
      // Subtraction unit testing
      ALUControl<=4'b1010;
      @(posedge clock); A=32'h00000DEF; B=32'h00000ABC; // Should output 00000333
      @(posedge clock); A=32'h00001234; B=32'h00000105; // Should output 0000112F
      #10
      // Set Less Than unit testing
      ALUControl<=4'b1011;
      @(posedge clock); A=32'h00000000; B=32'h00000DEF; // Should output 00000001
      @(posedge clock); A=32'h00001234; B=32'h00000105; // Should output 00000000
      #10
      // Multiplication unit testing
      ALUControl<=4'b0100;
      @(posedge clock); A=32'h00000004; B=32'h00000005; // Should output 00000014
      @(posedge clock); A=32'h00001234; B=32'h00000105; // Should output 00128F04
      #10
      // Division unit test
      ALUControl<=4'b0101;
      @(posedge clock); A=32'h00000DEF; B=32'h00000ABC; // Should output 00000001
      @(posedge clock); A=32'h00001234; B=32'h00000105; // Should output 00000011 
      #20
      $finish;
   end
   alu ALU(A,B,ALUControl,  Result, Zero, LSb_aluresult);
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

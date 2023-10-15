module network #(
    parameter W = 16
)(
    input rst,
    input clk,
    input sample_clk,
    input signed [W-1:0] sample_in0,
    input signed [W-1:0] sample_in1,
    input signed [W-1:0] sample_in2,
    input signed [W-1:0] sample_in3,
    output signed [W-1:0] sample_out0,
    output signed [W-1:0] sample_out1,
    output signed [W-1:0] sample_out2,
    output signed [W-1:0] sample_out3,
    input [7:0] jack
);

assign sample_out0 = sample_in0;
assign sample_out1 = sample_in0;
//assign sample_out2 = 16'sb00000001100100_00;  // fp 14.2  +100
//assign sample_out3 = 16'sb11111110011100_00;  // fp 14.2  -100
// assign sample_out2 = 16'sb0000111110100000;  // +1000
// assign sample_out3 = 16'sb1111000001100000;  // -1000
// assign sample_out2 =  16'sb0000011111010000;   // fp16.0 +2000
// assign sample_out3 =  16'sb1111100000110000;   // fp16.0 -2000
assign sample_out2 = 16'sb0000111110100000;   // fp16.0 +4000
assign sample_out3 = 16'sb1111000001100000;   // fp16.0 -4000


endmodule

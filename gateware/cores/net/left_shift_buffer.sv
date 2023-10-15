`default_nettype none

module left_shift_buffer #(
    parameter W = 16  // width for each element
)(
    input                     clk,
    input                     rst,
    input signed [W-1:0]      inp,
    output reg signed [W-1:0] out_d0,
    output reg signed [W-1:0] out_d1,
    output reg signed [W-1:0] out_d2,
    output reg signed [W-1:0] out_d3
);

    reg [W-1:0] buffer [0:3];
    integer i;

    assign out_d0 = buffer[0];
    assign out_d1 = buffer[1];
    assign out_d2 = buffer[2];
    assign out_d3 = buffer[3];

    initial begin
        for(i=0; i<4; i=i+1)
            buffer[i] <= 0;
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for(i=0; i<4; i=i+1)
                buffer[i] <= 0;
        end else begin
            buffer[0] <= buffer[1];
            buffer[1] <= buffer[2];
            buffer[2] <= buffer[3];
            buffer[3] <= inp;
        end
    end

endmodule
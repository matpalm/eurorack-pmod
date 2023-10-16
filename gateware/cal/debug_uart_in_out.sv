// Helper module to emit debug information out a UART for calibration purposes.
//
// This is not part of 'normal' projects, it's only used for board bringup.
//
// The calibration memory is created by following the calibration process
// documented in `cal.py`, which depends on this module.

`default_nettype none

module debug_uart_in_out #(
    parameter W = 16, // sample width
    parameter DIV = 12 // baud rate == CLK / DIV
)(
    input clk,
    input rst,
    output tx_o,
    input signed [W-1:0] in0,
    input signed [W-1:0] in1,
    input signed [W-1:0] in2,
    input signed [W-1:0] in3,
    input signed [W-1:0] out0,
    input signed [W-1:0] out1,
    input signed [W-1:0] out2,
    input signed [W-1:0] out3
);

localparam MAGIC1 = 8'hBE,
           MAGIC2 = 8'hEF;

logic tx1_valid;
logic [7:0] dout;
logic tx1_ack;
logic [7:0] state;

uart_tx utx (
    .tx(tx_o),
    .data(dout),
    .valid(tx1_valid),
    .ack(tx1_ack),
    .div(DIV-2),
	.clk(clk),
    .rst(rst)
);

always_ff @(posedge clk) begin
    if (rst) begin
        state <= 0;
        tx1_valid <= 1;
        dout <= 0;
    end else if(tx1_ack) begin
        tx1_valid <= 1'b1;
        case (state)
            // Note: we're currently only sending 2 bytes per
            // sample for calibration purposes. This should
            // eventually be derived from the sample width.
            0: dout <= MAGIC1;
            1: dout <= MAGIC2;
            2: dout <= 8'((in0 & 16'hFF00) >> 8);
            3: dout <= 8'((in0 & 16'h00FF));
            4: dout <= 8'((in1 & 16'hFF00) >> 8);
            5: dout <= 8'((in1 & 16'h00FF));
            6: dout <= 8'((in2 & 16'hFF00) >> 8);
            7: dout <= 8'((in2 & 16'h00FF));
            8: dout <= 8'((in3 & 16'hFF00) >> 8);
            9: dout <= 8'((in3 & 16'h00FF));
            10: dout <= 8'((out0 & 16'hFF00) >> 8);
            11: dout <= 8'((out0 & 16'h00FF));
            12: dout <= 8'((out1 & 16'hFF00) >> 8);
            13: dout <= 8'((out1 & 16'h00FF));
            14: dout <= 8'((out2 & 16'hFF00) >> 8);
            15: dout <= 8'((out2 & 16'h00FF));
            16: dout <= 8'((out3 & 16'hFF00) >> 8);
            17: dout <= 8'((out3 & 16'h00FF));
            default: begin
                // Should never get here
            end
        endcase
        if (state != 24) state <= state + 1;
        else state <= 0;
    end
end


endmodule

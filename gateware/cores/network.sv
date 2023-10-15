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

    localparam
        CLK_LSB    = 4'b0000,
        OUTPUT     = 4'b0001;
    reg [3:0] state;

    //-------------------------------------
    // left shift buffer

    reg lsb_clk =0;
    reg signed [W-1:0] lsb_out_d0;
    reg signed [W-1:0] lsb_out_d1;
    reg signed [W-1:0] lsb_out_d2;
    reg signed [W-1:0] lsb_out_d3;

    left_shift_buffer lsb (
        .clk(lsb_clk), .rst(rst),
        .inp(sample_in0),
        .out_d0(lsb_out_d0), .out_d1(lsb_out_d1), .out_d2(lsb_out_d2), .out_d3(lsb_out_d3)
    );


    logic prev_sample_clk;
    logic signed [W-1:0] in0_copy;

    always_ff @(posedge clk) begin
        prev_sample_clk <= sample_clk;
        if (rst) begin
            state <= CLK_LSB;
            prev_sample_clk <= 0;
        end else begin
            if (sample_clk != prev_sample_clk) begin
                state <= CLK_LSB;
            end else begin
                case (state)
                    CLK_LSB: begin
                        lsb_clk <= 1;
                        state <= OUTPUT;
                    end
                    OUTPUT: begin
                        lsb_clk <= 0;
                        sample_out0 <= lsb_out_d0;
                        sample_out1 <= lsb_out_d1;
                        sample_out2 <= lsb_out_d2;
                        sample_out3 <= -lsb_out_d3;
                    end
                endcase
            end
        end
    end

    // always_ff @(posedge sample_clk) begin
    //     network_state <= EMIT_SQUARE;
    // end

endmodule


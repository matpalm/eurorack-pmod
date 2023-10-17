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
        WAITING         = 4'b0000,
        CLK_LSB         = 4'b0001,
        RST_CONV_0      = 4'b0010,
        CONV_0_RUNNING  = 4'b0011,
        OUTPUT          = 4'b1111;
    reg [3:0] state;

    //-------------------------------------
    // left shift buffer

    reg lsb_clk =0;
    reg signed [W-1:0] lsb_out_d0;
    reg signed [W-1:0] lsb_out_d1;
    reg signed [W-1:0] lsb_out_d2;
    reg signed [W-1:0] lsb_out_d3;
    reg signed [W-1:0] lsb_input;

    left_shift_buffer lsb (
        .clk(lsb_clk), .rst(rst),
        .inp(sample_in0),
        .out_d0(lsb_out_d0), .out_d1(lsb_out_d1), .out_d2(lsb_out_d2), .out_d3(lsb_out_d3)
    );

    reg signed [W-1:0] n_sample_clk_ticks;
    reg signed [2*W-1:0] n_clk_ticks;

    logic prev_sample_clk;

    always_ff @(posedge clk) begin
        prev_sample_clk <= sample_clk;
        if (rst) begin
            prev_sample_clk <= 0;
            n_sample_clk_ticks <= 0;
            n_clk_ticks <= 0;
            state <= WAITING;
        end else begin
            if (sample_clk == 1 && sample_clk != prev_sample_clk) begin
                lsb_clk <= 1;
                state <= CLK_LSB;
                n_sample_clk_ticks <= n_sample_clk_ticks + 1;
            end else begin
                case (state)
                    WAITING: begin
                        // nothing
                    end
                    CLK_LSB: begin
                        lsb_clk <= 0;
                        state <= OUTPUT;
                    end
                    OUTPUT: begin
                        // nothing yet
                    end
                endcase
                n_clk_ticks <= n_clk_ticks + 1;
            end

            sample_out0 <= lsb_out_d0;
            sample_out1 <= lsb_out_d1;
            sample_out2 <= lsb_out_d2;
            sample_out3 <= lsb_out_d3;

        end
    end



    // always_ff @(posedge sample_clk) begin
    //     network_state <= EMIT_SQUARE;
    // end

endmodule


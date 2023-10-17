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
        COUNT_DP        = 4'b0100,
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

    assign lsb_input = sample_in0; // >>> 2;

    left_shift_buffer lsb (
        .clk(lsb_clk), .rst(rst),
        .inp(lsb_input),
        .out_d0(lsb_out_d0), .out_d1(lsb_out_d1), .out_d2(lsb_out_d2), .out_d3(lsb_out_d3)
    );

    //-------------------------------------
    // test dp
    reg tdp_rst;
    reg signed [W-1:0] tdp_a_d0;
    reg signed [W-1:0] tdp_a_d1;
    reg signed [W-1:0] tdp_a_d2;
    reg signed [W-1:0] tdp_a_d3;
    reg signed [W-1:0] tdp_a_d4;
    reg signed [W-1:0] tdp_a_d5;
    reg signed [W-1:0] tdp_a_d6;
    reg signed [W-1:0] tdp_a_d7;
    reg signed [W-1:0] tdp_out;
    reg tdp_out_v;

    dot_product #(.B_VALUES("/tmp/weights/qconv0/k0/c0.hex")) test_dp (
        .clk(clk), .rst(tdp_rst),
        .a_d0(tdp_a_d0), .a_d1(tdp_a_d1), .a_d2(tdp_a_d2), .a_d3(tdp_a_d3),
        .a_d4(tdp_a_d4), .a_d5(tdp_a_d5), .a_d6(tdp_a_d6), .a_d7(tdp_a_d7),
        .out(tdp_out), .out_v(tdp_out_v)
    );

    //-------------------------------------
    // clock handling

    reg signed [2*W-1:0] n_clk_ticks;
    reg signed [W-1:0] n_sample_clk_ticks;
    reg signed [2*W-1:0] n_dps;

    logic prev_sample_clk;

    always_ff @(posedge clk) begin
        prev_sample_clk <= sample_clk;
        if (rst) begin
            prev_sample_clk <= 0;
            n_sample_clk_ticks <= 0;
            n_clk_ticks <= 0;
            n_dps <= 0;
            state <= WAITING;
        end else begin
            if (sample_clk == 1 && sample_clk != prev_sample_clk) begin
                state <= CLK_LSB;
                n_sample_clk_ticks <= n_sample_clk_ticks + 1;
            end else begin
                case (state)
                    WAITING: begin
                        // nothing
                    end
                    CLK_LSB: begin
                        lsb_clk <= 1;
                        state <= RST_CONV_0;
                    end
                    RST_CONV_0: begin
                        lsb_clk <= 0;
                        tdp_a_d0 <= 0;
                        tdp_a_d1 <= 1;
                        tdp_a_d2 <= 0;
                        tdp_a_d3 <= 0;
                        tdp_a_d4 <= 1;
                        tdp_a_d5 <= 0;
                        tdp_a_d6 <= 0;
                        tdp_a_d7 <= 0;
                        tdp_rst <= 1;
                        state <= CONV_0_RUNNING;
                    end
                    CONV_0_RUNNING: begin
                        tdp_rst <= 0;
                        n_dps <= n_dps + 1;
                        state <= tdp_out_v ? COUNT_DP : CONV_0_RUNNING;;
                    end
                    COUNT_DP: begin
                        state <= WAITING;
                    end
                    OUTPUT: begin
                        // nothing
                    end

                endcase
                n_clk_ticks <= n_clk_ticks + 1;
            end

            sample_out0 <= lsb_out_d3;
            sample_out1 <= n_clk_ticks >> W;
            sample_out2 <= n_sample_clk_ticks;
            sample_out3 <= tdp_out;

        end
    end



endmodule



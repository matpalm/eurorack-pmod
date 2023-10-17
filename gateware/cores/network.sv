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

    // we always right shift input from 5V = 20_000 to be 5V = 5_000
    assign lsb_input = sample_in0 >>> 2;

    left_shift_buffer lsb (
        .clk(lsb_clk), .rst(rst),
        .inp(lsb_input),
        .out_d0(lsb_out_d0), .out_d1(lsb_out_d1), .out_d2(lsb_out_d2), .out_d3(lsb_out_d3)
    );

    //--------------------------------
    // conv 0 block
    // always connected to left shift buffer for input

    reg c0_rst;

    reg signed [W-1:0] c0a0_d0;
    reg signed [W-1:0] c0a0_d1;
    reg signed [W-1:0] c0a0_d2;
    reg signed [W-1:0] c0a0_d3;
    reg signed [W-1:0] c0a0_d4;
    reg signed [W-1:0] c0a0_d5;
    reg signed [W-1:0] c0a0_d6;
    reg signed [W-1:0] c0a0_d7;

    reg signed [W-1:0] c0a1_d0;
    reg signed [W-1:0] c0a1_d1;
    reg signed [W-1:0] c0a1_d2;
    reg signed [W-1:0] c0a1_d3;
    reg signed [W-1:0] c0a1_d4;
    reg signed [W-1:0] c0a1_d5;
    reg signed [W-1:0] c0a1_d6;
    reg signed [W-1:0] c0a1_d7;

    reg signed [W-1:0] c0a2_d0;
    reg signed [W-1:0] c0a2_d1;
    reg signed [W-1:0] c0a2_d2;
    reg signed [W-1:0] c0a2_d3;
    reg signed [W-1:0] c0a2_d4;
    reg signed [W-1:0] c0a2_d5;
    reg signed [W-1:0] c0a2_d6;
    reg signed [W-1:0] c0a2_d7;

    reg signed [W-1:0] c0a3_d0;
    reg signed [W-1:0] c0a3_d1;
    reg signed [W-1:0] c0a3_d2;
    reg signed [W-1:0] c0a3_d3;
    reg signed [W-1:0] c0a3_d4;
    reg signed [W-1:0] c0a3_d5;
    reg signed [W-1:0] c0a3_d6;
    reg signed [W-1:0] c0a3_d7;

    reg signed [W-1:0] c0_out_d0;
    reg signed [W-1:0] c0_out_d1;
    reg signed [W-1:0] c0_out_d2;
    reg signed [W-1:0] c0_out_d3;
    reg signed [W-1:0] c0_out_d4;
    reg signed [W-1:0] c0_out_d5;
    reg signed [W-1:0] c0_out_d6;
    reg signed [W-1:0] c0_out_d7;

    reg c0_out_v;

    assign c0a0_d0 = lsb_out_d0;
    assign c0a0_d1 = 0;
    assign c0a0_d2 = 0;
    assign c0a0_d3 = 0;
    assign c0a0_d4 = 0;
    assign c0a0_d5 = 0;
    assign c0a0_d6 = 0;
    assign c0a0_d7 = 0;
    assign c0a1_d0 = lsb_out_d1;
    assign c0a1_d1 = 0;
    assign c0a1_d2 = 0;
    assign c0a1_d3 = 0;
    assign c0a1_d4 = 0;
    assign c0a1_d5 = 0;
    assign c0a1_d6 = 0;
    assign c0a1_d7 = 0;
    assign c0a2_d0 = lsb_out_d2;
    assign c0a2_d1 = 0;
    assign c0a2_d2 = 0;
    assign c0a2_d3 = 0;
    assign c0a2_d4 = 0;
    assign c0a2_d5 = 0;
    assign c0a2_d6 = 0;
    assign c0a2_d7 = 0;
    assign c0a3_d0 = lsb_out_d3;
    assign c0a3_d1 = 0;
    assign c0a3_d2 = 0;
    assign c0a3_d3 = 0;
    assign c0a3_d4 = 0;
    assign c0a3_d5 = 0;
    assign c0a3_d6 = 0;
    assign c0a3_d7 = 0;

    conv1d #(.B_VALUES("weights/qconv0")) conv0 (
        // TODO: REMEMBER RELU HAS BEEN TURNED OFF HERE!!!
        .clk(clk), .rst(c0_rst), .apply_relu(1'b0),
        .a0_d0(c0a0_d0), .a0_d1(c0a0_d1), .a0_d2(c0a0_d2), .a0_d3(c0a0_d3), .a0_d4(c0a0_d4), .a0_d5(c0a0_d5), .a0_d6(c0a0_d6), .a0_d7(c0a0_d7),
        .a1_d0(c0a1_d0), .a1_d1(c0a1_d1), .a1_d2(c0a1_d2), .a1_d3(c0a1_d3), .a1_d4(c0a1_d4), .a1_d5(c0a1_d5), .a1_d6(c0a1_d6), .a1_d7(c0a1_d7),
        .a2_d0(c0a2_d0), .a2_d1(c0a2_d1), .a2_d2(c0a2_d2), .a2_d3(c0a2_d3), .a2_d4(c0a2_d4), .a2_d5(c0a2_d5), .a2_d6(c0a2_d6), .a2_d7(c0a2_d7),
        .a3_d0(c0a3_d0), .a3_d1(c0a3_d1), .a3_d2(c0a3_d2), .a3_d3(c0a3_d3), .a3_d4(c0a3_d4), .a3_d5(c0a3_d5), .a3_d6(c0a3_d6), .a3_d7(c0a3_d7),
        .out_d0(c0_out_d0), .out_d1(c0_out_d1), .out_d2(c0_out_d2), .out_d3(c0_out_d3),
        .out_d4(c0_out_d4), .out_d5(c0_out_d5), .out_d6(c0_out_d6), .out_d7(c0_out_d7),
        .out_v(c0_out_v));

    //-------------------------------------
    // clock handling

    // reg signed [2*W-1:0] n_clk_ticks;
    // reg signed [W-1:0] n_sample_clk_ticks;
    // reg signed [2*W-1:0] n_dps;

    logic prev_sample_clk;

    always_ff @(posedge clk) begin
        prev_sample_clk <= sample_clk;
        if (rst) begin
            prev_sample_clk <= 0;
            //n_sample_clk_ticks <= 0;
            //n_clk_ticks <= 0;
            //n_dps <= 0;
            state <= WAITING;
        end else begin
            if (sample_clk == 1 && sample_clk != prev_sample_clk) begin
                state <= CLK_LSB;
                //n_sample_clk_ticks <= n_sample_clk_ticks + 1;
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
                        c0_rst <= 1;
                        state <= CONV_0_RUNNING;
                    end
                    CONV_0_RUNNING: begin
                        c0_rst <= 0;
                        state <= c0_out_v ? WAITING : CONV_0_RUNNING;
                    end
                    // OUTPUT: begin
                    //     // nothing
                    // end

                endcase
                //n_clk_ticks <= n_clk_ticks + 1;
            end

            sample_out0 <= c0_out_d0 << 2;
            sample_out1 <= c0_out_d1 << 2;
            sample_out2 <= c0_out_d2 << 2;
            sample_out3 <= lsb_out_d0;

        end
    end



endmodule



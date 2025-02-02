`default_nettype none

module network #(
    parameter W=16,            // width for each element
    parameter FILTER_D=8,      // size of packed conv0 and conv2 filters
    parameter FILTER_PO2_D=16  // size of packed conv1 po2 filters
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

    // everything works now with in and out being 4D for eurorack pmod ins/out
    localparam IN_OUT_D = 4;

    localparam
        CLK_LSB         = 0,
        RST_CONV_0      = 1,
        CONV_0_RUNNING  = 2,
        CLK_ACT_CACHE_0 = 3,
        RST_CONV_1      = 4,
        CONV_1_RUNNING  = 5,
        CLK_ACT_CACHE_1 = 6,
        RST_CONV_2      = 7,
        CONV_2_RUNNING  = 8,
        CLK_ACT_CACHE_2 = 9,
        RST_CONV_3      = 10,
        CONV_3_RUNNING  = 11,
        OUTPUT          = 12,
        RST_CONV_1_1A     = 13,
        CONV_1_1A_RUNNING = 14,
        RST_CONV_1_1B     = 15,
        CONV_1_1B_RUNNING = 16,
        RST_CONV_1_2A     = 17,
        CONV_1_2A_RUNNING = 18,
        RST_CONV_1_2B     = 19,
        CONV_1_2B_RUNNING = 20;

    reg [4:0] state;

    //--------------------------------
    // left shift buffers
    // TOOD: pack these too

    reg signed [W-1:0] shifted_sample_in0;
    reg signed [W-1:0] shifted_sample_in1;
    reg signed [W-1:0] shifted_sample_in2;
    reg signed [W-1:0] shifted_sample_in3;

    // NOTE: not shifted for cocotb version, but >>>2 shifted for eurorack pmod
    // check jack and if not plugged emit 0x8300 -32000, => -1 in embed space
    assign shifted_sample_in0 = sample_in0 >>> 2;
    assign shifted_sample_in1 = sample_in1 >>> 2;  // 8V shifts to 0x1F40
    assign shifted_sample_in2 = sample_in2 >>> 2;  // 8V shifts to 0x1F40
    assign shifted_sample_in3 = 0; //sample_in3 >>> 2;

    reg lsb_clk =0;

    reg signed [W-1:0] lsb_out_in0_0;
    reg signed [W-1:0] lsb_out_in0_1;
    reg signed [W-1:0] lsb_out_in0_2;
    reg signed [W-1:0] lsb_out_in0_3;

    left_shift_buffer #(.W(W)) lsb_in0 (
        .clk(lsb_clk), .rst(rst),
        .inp(shifted_sample_in0),
        .out_0(lsb_out_in0_0), .out_1(lsb_out_in0_1), .out_2(lsb_out_in0_2), .out_3(lsb_out_in0_3)
    );
    reg signed [W-1:0] lsb_out_in1_0;
    reg signed [W-1:0] lsb_out_in1_1;
    reg signed [W-1:0] lsb_out_in1_2;
    reg signed [W-1:0] lsb_out_in1_3;

    left_shift_buffer #(.W(W)) lsb_in1 (
        .clk(lsb_clk), .rst(rst),
        .inp(shifted_sample_in1),
        .out_0(lsb_out_in1_0), .out_1(lsb_out_in1_1), .out_2(lsb_out_in1_2), .out_3(lsb_out_in1_3)
    );

    reg signed [W-1:0] lsb_out_in2_0;
    reg signed [W-1:0] lsb_out_in2_1;
    reg signed [W-1:0] lsb_out_in2_2;
    reg signed [W-1:0] lsb_out_in2_3;

    left_shift_buffer #(.W(W)) lsb_in2 (
        .clk(lsb_clk), .rst(rst),
        .inp(shifted_sample_in2),
        .out_0(lsb_out_in2_0), .out_1(lsb_out_in2_1), .out_2(lsb_out_in2_2), .out_3(lsb_out_in2_3)
    );

    reg signed [W-1:0] lsb_out_in3_0;
    reg signed [W-1:0] lsb_out_in3_1;
    reg signed [W-1:0] lsb_out_in3_2;
    reg signed [W-1:0] lsb_out_in3_3;

    left_shift_buffer #(.W(W)) lsb_in3 (
        .clk(lsb_clk), .rst(rst),
        .inp(shifted_sample_in3),
        .out_0(lsb_out_in3_0), .out_1(lsb_out_in3_1), .out_2(lsb_out_in3_2), .out_3(lsb_out_in3_3)
    );

    //--------------------------------
    // conv 0 block
    // always connected to left shift buffer for input

    reg c0_rst;
    reg signed [IN_OUT_D*W-1:0] c0a0;
    reg signed [IN_OUT_D*W-1:0] c0a1;
    reg signed [IN_OUT_D*W-1:0] c0a2;
    reg signed [IN_OUT_D*W-1:0] c0a3;
    reg signed [FILTER_D*W-1:0] c0_out;
    reg c0_out_v;

    // concat LSB elements into 4 packed values.
    assign c0a0 = {lsb_out_in0_0, lsb_out_in1_0, lsb_out_in2_0, lsb_out_in3_0};
    assign c0a1 = {lsb_out_in0_1, lsb_out_in1_1, lsb_out_in2_1, lsb_out_in3_1};
    assign c0a2 = {lsb_out_in0_2, lsb_out_in1_2, lsb_out_in2_2, lsb_out_in3_2};
    assign c0a3 = {lsb_out_in0_3, lsb_out_in1_3, lsb_out_in2_3, lsb_out_in3_3};

    conv1d #(.W(W), .IN_D(IN_OUT_D), .OUT_D(FILTER_D), .WEIGHTS("weights/qconv_0_qb")) conv0 (
        .clk(clk), .rst(c0_rst), .apply_relu(1'b1),
        .packed_a0(c0a0), .packed_a1(c0a1), .packed_a2(c0a2), .packed_a3(c0a3),
        .packed_out(c0_out),
        .out_v(c0_out_v));

    //--------------------------------
    // conv 0 activation cache

    reg ac_c0_clk = 0;
    reg signed [FILTER_D*W-1:0] ac_c0_out_l0;
    reg signed [FILTER_D*W-1:0] ac_c0_out_l1;
    reg signed [FILTER_D*W-1:0] ac_c0_out_l2;
    reg signed [FILTER_D*W-1:0] ac_c0_out_l3;
    localparam C0_DILATION = 4;

    activation_cache #(.W(W), .D(FILTER_D), .DILATION(C0_DILATION)) activation_cache_c0 (
        .clk(ac_c0_clk), .rst(rst), .inp(c0_out),
        .out_l0(ac_c0_out_l0),
        .out_l1(ac_c0_out_l1),
        .out_l2(ac_c0_out_l2),
        .out_l3(ac_c0_out_l3)
    );

    //--------------------------------
    // conv 1 block

    // the set of cN_rst and cN_out_v values here could be in an array
    // since we just intend to rst, then wait, for each in sequence.

    reg c1_rst = 0;
    reg signed [FILTER_D*W-1:0] c1_out;
    reg c1_out_v;

    conv1d #(.W(W), .IN_D(FILTER_D), .OUT_D(FILTER_D), .WEIGHTS("weights/qconv_1_qb")) conv1 (
        .clk(clk), .rst(c1_rst), .apply_relu(1'b1),
        .packed_a0(ac_c0_out_l0), .packed_a1(ac_c0_out_l1),
        .packed_a2(ac_c0_out_l2), .packed_a3(ac_c0_out_l3),
        .packed_out(c1_out),
        .out_v(c1_out_v));

    reg c1_1a_rst = 0;
    reg signed [FILTER_PO2_D*W-1:0] c1_1a_out;
    reg c1_1a_out_v;

    po2_conv1d #(.W(W), .IN_D(FILTER_D), .OUT_D(FILTER_PO2_D), .WEIGHTS("weights/qconv_1_1a_po2")) conv1_1a (
        .clk(clk), .rst(c1_1a_rst), .apply_relu(1'b0),
        .packed_a(c1_out),
        .packed_out(c1_1a_out),
        .out_v(c1_1a_out_v));

    reg c1_1b_rst = 0;
    reg signed [FILTER_D*W-1:0] c1_1b_out;
    reg c1_1b_out_v;

    po2_conv1d #(.W(W), .IN_D(FILTER_PO2_D), .OUT_D(FILTER_D), .WEIGHTS("weights/qconv_1_1b_po2")) conv1_1b (
        .clk(clk), .rst(c1_1b_rst), .apply_relu(1'b1),
        .packed_a(c1_1a_out),
        .packed_out(c1_1b_out),
        .out_v(c1_1b_out_v));

    reg c1_2a_rst = 0;
    reg signed [FILTER_PO2_D*W-1:0] c1_2a_out;
    reg c1_2a_out_v;

    po2_conv1d #(.W(W), .IN_D(FILTER_D), .OUT_D(FILTER_PO2_D), .WEIGHTS("weights/qconv_1_2a_po2")) conv1_2a (
        .clk(clk), .rst(c1_2a_rst), .apply_relu(1'b0),
        .packed_a(c1_1b_out),
        .packed_out(c1_2a_out),
        .out_v(c1_2a_out_v));

    reg c1_2b_rst = 0;
    reg signed [FILTER_D*W-1:0] c1_2b_out;
    reg c1_2b_out_v;

    po2_conv1d #(.W(W), .IN_D(FILTER_PO2_D), .OUT_D(FILTER_D), .WEIGHTS("weights/qconv_1_2b_po2")) conv1_2b (
        .clk(clk), .rst(c1_2b_rst), .apply_relu(1'b1),
        .packed_a(c1_2a_out),
        .packed_out(c1_2b_out),
        .out_v(c1_2b_out_v));

    // --------------------------------
    // conv 1 activation cache

    reg ac_c1_clk = 0;
    reg signed [FILTER_D*W-1:0] ac_c1_out_l0;
    reg signed [FILTER_D*W-1:0] ac_c1_out_l1;
    reg signed [FILTER_D*W-1:0] ac_c1_out_l2;
    reg signed [FILTER_D*W-1:0] ac_c1_out_l3;
    localparam C1_DILATION = 4*4;

    activation_cache #(.W(W), .D(FILTER_D), .DILATION(C1_DILATION)) activation_cache_c1 (
        .clk(ac_c1_clk), .rst(rst), .inp(c1_2b_out),
        .out_l0(ac_c1_out_l0),
        .out_l1(ac_c1_out_l1),
        .out_l2(ac_c1_out_l2),
        .out_l3(ac_c1_out_l3)
    );

    //--------------------------------
    // conv 2 block

    reg c2_rst = 0;
    reg signed [IN_OUT_D*W-1:0] c2_out;
    reg c2_out_v;

    conv1d #(.W(W), .IN_D(FILTER_D), .OUT_D(IN_OUT_D), .WEIGHTS("weights/qconv_2_qb")) conv2 (
        .clk(clk), .rst(c2_rst), .apply_relu(1'b0),
        .packed_a0(ac_c1_out_l0), .packed_a1(ac_c1_out_l1),
        .packed_a2(ac_c1_out_l2), .packed_a3(ac_c1_out_l3),
        .packed_out(c2_out),
        .out_v(c2_out_v));

    //---------------------------------
    // main network state machine

    logic signed [W-1:0] out0;
    logic signed [W-1:0] out1;
    logic signed [W-1:0] out2;
    logic signed [W-1:0] out3;

    // keep timing of clk ticks vs num ticks in output
    // ( since output is the last state and implies head room )
    logic signed [2*W-1:0] n_clk_ticks;
    logic signed [2*W-1:0] n_output_ticks;

    logic prev_sample_clk;

    always_ff @(posedge clk) begin
        prev_sample_clk <= sample_clk;
        if (rst) begin
            prev_sample_clk <= 0;
            //n_sample_clk_ticks <= 0;
            //n_clk_ticks <= 0;
            //n_dps <= 0;
            state <= CLK_LSB;
        end else begin
            if (sample_clk == 1 && sample_clk != prev_sample_clk) begin
                state <= CLK_LSB;
                //n_sample_clk_ticks <= n_sample_clk_ticks + 1;
            end else begin
                case (state)

                    CLK_LSB: begin
                        // signal left shift buffer to run once
                        lsb_clk <= 1;
                        state <= RST_CONV_0;
                    end

                    RST_CONV_0: begin
                        // signal conv0 to reset and run
                        lsb_clk <= 0;
                        c0_rst <= 1;
                        state <= CONV_0_RUNNING;
                    end

                    CONV_0_RUNNING: begin
                        // wait until conv0 has run
                        c0_rst <= 0;
                        if (c0_out_v) state <= CLK_ACT_CACHE_0;
                    end

                    CLK_ACT_CACHE_0: begin
                        // signal activation_cache 0 to collect a value
                        ac_c0_clk <= 1;
                        state = RST_CONV_1;
                    end

                    RST_CONV_1: begin
                        // signal conv1 to reset and run
                        ac_c0_clk <= 0;
                        c1_rst <= 1;
                        state <= CONV_1_RUNNING;
                    end

                    CONV_1_RUNNING: begin
                        // wait until conv1 has run
                        c1_rst <= 0;
                        if (c1_out_v) state <= RST_CONV_1_1A;
                    end

                    RST_CONV_1_1A: begin
                        // signal conv to reset and run
                        c1_1a_rst <= 1;
                        state <= CONV_1_1A_RUNNING;
                    end

                    CONV_1_1A_RUNNING: begin
                        // wait until conv has run
                        c1_1a_rst <= 0;
                        if (c1_1a_out_v) state <= RST_CONV_1_1B;
                    end

                    RST_CONV_1_1B: begin
                        // signal conv to reset and run
                        c1_1b_rst <= 1;
                        state <= CONV_1_1B_RUNNING;
                    end

                    CONV_1_1B_RUNNING: begin
                        // wait until conv has run
                        c1_1b_rst <= 0;
                        if (c1_1b_out_v) state <= RST_CONV_1_2A;
                    end

                    RST_CONV_1_2A: begin
                        // signal conv to reset and run
                        c1_2a_rst <= 1;
                        state <= CONV_1_2A_RUNNING;
                    end

                    CONV_1_2A_RUNNING: begin
                        // wait until conv has run
                        c1_2a_rst <= 0;
                        if (c1_2a_out_v) state <= RST_CONV_1_2B;
                    end

                    RST_CONV_1_2B: begin
                        // signal conv to reset and run
                        c1_2b_rst <= 1;
                        state <= CONV_1_2B_RUNNING;
                    end

                    CONV_1_2B_RUNNING: begin
                        // wait until conv1_1a has run
                        c1_2b_rst <= 0;
                        if (c1_2b_out_v) state <= CLK_ACT_CACHE_1;
                    end

                    CLK_ACT_CACHE_1: begin
                        // signal activation_cache 1 to collect a value
                        ac_c1_clk <= 1;
                        state = RST_CONV_2;
                    end

                    RST_CONV_2: begin
                        // signal conv2 to reset and run
                        ac_c1_clk <= 0;
                        c2_rst <= 1;
                        state <= CONV_2_RUNNING;
                    end

                    CONV_2_RUNNING: begin
                        // wait until conv2 has run
                        c2_rst <= 0;
                        if (c2_out_v) state <= OUTPUT;
                    end

                    OUTPUT: begin
                        // NOTE: not shifted for cocotb version, but <<2 shifted for eurorack pmod
                        // final net output is last conv output
                        out0 <= c2_out[IN_OUT_D*W-1:(IN_OUT_D-1)*W] << 2;
                        out1 <= n_clk_ticks >> W;
                        out2 <= n_output_ticks >> W;
                        out3 <= 0;
                        n_output_ticks <= n_output_ticks + 1;
                    end

                endcase
                n_clk_ticks <= n_clk_ticks + 1;
            end
        end
    end

    assign sample_out0 = out0;
    assign sample_out1 = out1;
    assign sample_out2 = out2;
    assign sample_out3 = out3;

endmodule



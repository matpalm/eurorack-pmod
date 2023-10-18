module network #(
    parameter W = 16,
    parameter D = 8
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
        CLK_LSB         = 4'b0000,
        RST_CONV_0      = 4'b0001,
        CONV_0_RUNNING  = 4'b0010,
        CLK_ACT_CACHE_0 = 4'b0011,
        RST_CONV_1      = 4'b0100,
        CONV_1_RUNNING  = 4'b0101,

        WAITING         = 4'b1110,
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
    reg signed [D*W-1:0] c0a0;
    reg signed [D*W-1:0] c0a1;
    reg signed [D*W-1:0] c0a2;
    reg signed [D*W-1:0] c0a3;
    reg signed [D*W-1:0] c0_out;
    reg c0_out_v;

    // output from left shift buffer sits in c0a0[0] with all other c0a0 value 0
    assign c0a0 = lsb_out_d0 << (D-1)*W;
    assign c0a1 = lsb_out_d1 << (D-1)*W;
    assign c0a2 = lsb_out_d2 << (D-1)*W;
    assign c0a3 = lsb_out_d3 << (D-1)*W;

    conv1d #(.B_VALUES("weights/qconv0")) conv0 (
        .clk(clk), .rst(c0_rst), .apply_relu(1'b1),
        .packed_a0(c0a0), .packed_a1(c0a1), .packed_a2(c0a2), .packed_a3(c0a3),
        .packed_out(c0_out),
        .out_v(c0_out_v));

    //--------------------------------
    // conv 0 activation cache

    reg ac_c0_clk = 0;
    reg signed [D*W-1:0] ac_c0_out_l0;
    reg signed [D*W-1:0] ac_c0_out_l1;
    reg signed [D*W-1:0] ac_c0_out_l2;
    reg signed [D*W-1:0] ac_c0_out_l3;
    localparam C0_DILATION = 4;

    activation_cache #(.W(W), .D(D), .DILATION(C0_DILATION)) activation_cache_c0 (
        .clk(ac_c0_clk), .rst(rst), .inp(c0_out),
        .out_l0(ac_c0_out_l0),
        .out_l1(ac_c0_out_l1),
        .out_l2(ac_c0_out_l2),
        .out_l3(ac_c0_out_l3)
    );

    //--------------------------------
    // conv 1 block

    reg c1_rst = 0;
    reg signed [D*W-1:0] c1a0;
    reg signed [D*W-1:0] c1a1;
    reg signed [D*W-1:0] c1a2;
    reg signed [D*W-1:0] c1a3;
    reg signed [D*W-1:0] c1_out;
    reg c1_out_v;

    assign c1a0 = ac_c0_out_l0;
    assign c1a1 = ac_c0_out_l1;
    assign c1a2 = ac_c0_out_l2;
    assign c1a3 = ac_c0_out_l3;

    conv1d #(.W(W), .D(D), .B_VALUES("weights/qconv1")) conv1 (
        .clk(clk), .rst(c1_rst), .apply_relu(1'b0),
        .packed_a0(c1a0), .packed_a1(c1a1), .packed_a2(c1a2), .packed_a3(c1a3),
        .packed_out(c1_out),
        .out_v(c1_out_v));

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
                        state <= c0_out_v ? CLK_ACT_CACHE_0 : CONV_0_RUNNING;
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
                        state <= c1_out_v ? WAITING : CONV_1_RUNNING;
                    end

                    // OUTPUT: begin
                    //     // nothing
                    // end

                endcase
                //n_clk_ticks <= n_clk_ticks + 1;
            end

            sample_out0 <= c1_out[8*W-1:7*W] << 2;
            sample_out1 <= c1_out[7*W-1:6*W] << 2;
            sample_out2 <= c1_out[6*W-1:5*W] << 2;
            sample_out3 <= c1_out[5*W-1:4*W] << 2;

        end
    end



endmodule



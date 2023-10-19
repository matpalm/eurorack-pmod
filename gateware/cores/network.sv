module network #(
    parameter W = 16,  // width for each element
    parameter D = 8    // size of packed port arrays
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
        CLK_ACT_CACHE_1 = 4'b0110,
        RST_CONV_2      = 4'b0111,
        CONV_2_RUNNING  = 4'b1000,
        CLK_ACT_CACHE_2 = 4'b1001,
        RST_CONV_3      = 4'b1010,
        CONV_3_RUNNING  = 4'b1011,
        OUTPUT          = 4'b1100;

    reg [3:0] state;

    //--------------------------------
    // left shift buffers
    // TOOD: pack these too

    reg signed [W-1:0] shifted_sample_in0;
    reg signed [W-1:0] shifted_sample_in1;
    reg signed [W-1:0] shifted_sample_in2;
    reg signed [W-1:0] shifted_sample_in3;

    // TODO: for now just fixed to e1 = e2 = 0 => square
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
    reg signed [D*W-1:0] c0a0;
    reg signed [D*W-1:0] c0a1;
    reg signed [D*W-1:0] c0a2;
    reg signed [D*W-1:0] c0a3;
    reg signed [D*W-1:0] c0_out;
    reg c0_out_v;

    // concat W elements, and then left shift them another 4, to make them
    // effectively the first 4 elements in an 8D array
    assign c0a0 = {lsb_out_in0_0, lsb_out_in1_0, lsb_out_in2_0, lsb_out_in3_0} << 4*W;
    assign c0a1 = {lsb_out_in0_1, lsb_out_in1_1, lsb_out_in2_1, lsb_out_in3_1} << 4*W;
    assign c0a2 = {lsb_out_in0_2, lsb_out_in1_2, lsb_out_in2_2, lsb_out_in3_2} << 4*W;
    assign c0a3 = {lsb_out_in0_3, lsb_out_in1_3, lsb_out_in2_3, lsb_out_in3_3} << 4*W;

    // TODO put relu back!
    conv1d #(.W(W), .D(D), .B_VALUES("weights/qconv0")) conv0 (
        .clk(clk), .rst(c0_rst), .apply_relu(1'b0),
        .packed_a0(c0a0), .packed_a1(c0a1), .packed_a2(c0a2), .packed_a3(c0a3),
        .packed_out(c0_out),
        .out_v(c0_out_v));

    // //--------------------------------
    // // conv 0 activation cache

    // reg ac_c0_clk = 0;
    // reg signed [D*W-1:0] ac_c0_out_l0;
    // reg signed [D*W-1:0] ac_c0_out_l1;
    // reg signed [D*W-1:0] ac_c0_out_l2;
    // reg signed [D*W-1:0] ac_c0_out_l3;
    // localparam C0_DILATION = 4;

    // activation_cache #(.W(W), .D(D), .DILATION(C0_DILATION)) activation_cache_c0 (
    //     .clk(ac_c0_clk), .rst(rst), .inp(c0_out),
    //     .out_l0(ac_c0_out_l0),
    //     .out_l1(ac_c0_out_l1),
    //     .out_l2(ac_c0_out_l2),
    //     .out_l3(ac_c0_out_l3)
    // );

    // //--------------------------------
    // // conv 1 block

    // reg c1_rst = 0;
    // reg signed [D*W-1:0] c1a0;
    // reg signed [D*W-1:0] c1a1;
    // reg signed [D*W-1:0] c1a2;
    // reg signed [D*W-1:0] c1a3;
    // reg signed [D*W-1:0] c1_out;
    // reg c1_out_v;

    // assign c1a0 = ac_c0_out_l0;
    // assign c1a1 = ac_c0_out_l1;
    // assign c1a2 = ac_c0_out_l2;
    // assign c1a3 = ac_c0_out_l3;

    // conv1d #(.W(W), .D(D), .B_VALUES("weights/qconv1")) conv1 (
    //     .clk(clk), .rst(c1_rst), .apply_relu(1'b0),
    //     .packed_a0(c1a0), .packed_a1(c1a1), .packed_a2(c1a2), .packed_a3(c1a3),
    //     .packed_out(c1_out),
    //     .out_v(c1_out_v));

    //---------------------------------
    // main network state machine

    logic signed [W-1:0] out0;
    logic signed [W-1:0] out1;
    logic signed [W-1:0] out2;
    logic signed [W-1:0] out3;

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
                        // state <= c0_out_v ? CLK_ACT_CACHE_0 : CONV_0_RUNNING;
                        state <= c0_out_v ? OUTPUT : CONV_0_RUNNING;
                    end

                    // CLK_ACT_CACHE_0: begin
                    //     // signal activation_cache 0 to collect a value
                    //     ac_c0_clk <= 1;
                    //     state = RST_CONV_1;
                    // end

                    // RST_CONV_1: begin
                    //     // signal conv1 to reset and run
                    //     ac_c0_clk <= 0;
                    //     c1_rst <= 1;
                    //     state <= CONV_1_RUNNING;
                    // end

                    // CONV_1_RUNNING: begin
                    //     // wait until conv1 has run
                    //     c1_rst <= 0;
                    //     state <= c1_out_v ? OUTPUT : CONV_1_RUNNING;
                    // end

                    OUTPUT: begin
                        // final net output is conv2 output
                        out0 <= c0_out[8*W-1:7*W] << 2;
                        out1 <= 0;
                        out2 <= 0;
                        out3 <= 0;
                    end

                endcase
                //n_clk_ticks <= n_clk_ticks + 1;
            end

        end
    end

    assign sample_out0 = out0;
    assign sample_out1 = out1;
    assign sample_out2 = out2;
    assign sample_out3 = out3;

endmodule



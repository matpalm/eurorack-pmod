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
        .clk(clk), .rst(c0_rst), .apply_relu(1'b0),
        .packed_a0(c0a0), .packed_a1(c0a1), .packed_a2(c0a2), .packed_a3(c0a3),
        .packed_out(c0_out),
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

            sample_out0 <= c0_out[8*W-1:7*W] << 2;
            sample_out1 <= c0_out[7*W-1:6*W] << 2;
            sample_out2 <= c0_out[6*W-1:5*W] << 2;
            sample_out3 <= c0_out[5*W-1:4*W] << 2;

        end
    end



endmodule



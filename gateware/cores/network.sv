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
        CLK_LSB         = 4'b0000,
        RST_CONV_0      = 4'b0001,
        CONV_0_RUNNING  = 4'b0010,
        OUTPUT          = 4'b1111;
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
        .clk(clk), .rst(c0_rst), .apply_relu(1'b1),
        .a0_d0(c0a0_d0), .a0_d1(c0a0_d1), .a0_d2(c0a0_d2), .a0_d3(c0a0_d3), .a0_d4(c0a0_d4), .a0_d5(c0a0_d5), .a0_d6(c0a0_d6), .a0_d7(c0a0_d7),
        .a1_d0(c0a1_d0), .a1_d1(c0a1_d1), .a1_d2(c0a1_d2), .a1_d3(c0a1_d3), .a1_d4(c0a1_d4), .a1_d5(c0a1_d5), .a1_d6(c0a1_d6), .a1_d7(c0a1_d7),
        .a2_d0(c0a2_d0), .a2_d1(c0a2_d1), .a2_d2(c0a2_d2), .a2_d3(c0a2_d3), .a2_d4(c0a2_d4), .a2_d5(c0a2_d5), .a2_d6(c0a2_d6), .a2_d7(c0a2_d7),
        .a3_d0(c0a3_d0), .a3_d1(c0a3_d1), .a3_d2(c0a3_d2), .a3_d3(c0a3_d3), .a3_d4(c0a3_d4), .a3_d5(c0a3_d5), .a3_d6(c0a3_d6), .a3_d7(c0a3_d7),
        .out_d0(c0_out_d0), .out_d1(c0_out_d1), .out_d2(c0_out_d2), .out_d3(c0_out_d3),
        .out_d4(c0_out_d4), .out_d5(c0_out_d5), .out_d6(c0_out_d6), .out_d7(c0_out_d7),
        .out_v(c0_out_v));

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
                        state <= RST_CONV_0;
                    end
                    RST_CONV_0: begin
                        lsb_clk <= 0;
                        c0_rst <= 1;
                        state <= CONV_0_RUNNING;
                    end
                    CONV_0_RUNNING: begin
                        c0_rst <= 0;
                        net_state <= c0_out_v ? OUTPUT : CONV_0_RUNNING;
                    end
                    OUTPUT: begin
                        sample_out0 <= c0_out_d0;
                        sample_out1 <= c0_out_d1;
                        sample_out2 <= c0_out_d2;
                        sample_out3 <= c0_out_d3;
                    end
                endcase
            end
        end
    end

    // always_ff @(posedge sample_clk) begin
    //     network_state <= EMIT_SQUARE;
    // end

endmodule


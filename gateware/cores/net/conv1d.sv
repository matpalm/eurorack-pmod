`default_nettype none

module conv1d #(
    parameter W=16,
    parameter B_VALUES
)(
  input                        clk,
  input                        rst,
  input                        apply_relu,

  input signed [W-1:0]         a0_d0,
  input signed [W-1:0]         a0_d1,
  input signed [W-1:0]         a0_d2,
  input signed [W-1:0]         a0_d3,
  input signed [W-1:0]         a0_d4,
  input signed [W-1:0]         a0_d5,
  input signed [W-1:0]         a0_d6,
  input signed [W-1:0]         a0_d7,

  input signed [W-1:0]         a1_d0,
  input signed [W-1:0]         a1_d1,
  input signed [W-1:0]         a1_d2,
  input signed [W-1:0]         a1_d3,
  input signed [W-1:0]         a1_d4,
  input signed [W-1:0]         a1_d5,
  input signed [W-1:0]         a1_d6,
  input signed [W-1:0]         a1_d7,

  input signed [W-1:0]         a2_d0,
  input signed [W-1:0]         a2_d1,
  input signed [W-1:0]         a2_d2,
  input signed [W-1:0]         a2_d3,
  input signed [W-1:0]         a2_d4,
  input signed [W-1:0]         a2_d5,
  input signed [W-1:0]         a2_d6,
  input signed [W-1:0]         a2_d7,

  input signed [W-1:0]         a3_d0,
  input signed [W-1:0]         a3_d1,
  input signed [W-1:0]         a3_d2,
  input signed [W-1:0]         a3_d3,
  input signed [W-1:0]         a3_d4,
  input signed [W-1:0]         a3_d5,
  input signed [W-1:0]         a3_d6,
  input signed [W-1:0]         a3_d7,

  output reg signed [W-1:0]    out_d0,
  output reg signed [W-1:0]    out_d1,
  output reg signed [W-1:0]    out_d2,
  output reg signed [W-1:0]    out_d3,
  output reg signed [W-1:0]    out_d4,
  output reg signed [W-1:0]    out_d5,
  output reg signed [W-1:0]    out_d6,
  output reg signed [W-1:0]    out_d7,

  output reg                   out_v
);

    localparam
        MAT_MUL_RUNNING  = 3'b000,
        ACCUMULATE       = 3'b001,
        BIAS_ADD         = 3'b010,
        SINGLE_W         = 3'b011,
        OUTPUT           = 3'b100;
    reg [2:0] c1d_state = MAT_MUL_RUNNING;

    reg kernel0_v;
    reg kernel1_v;
    reg kernel2_v;
    reg kernel3_v;

    // for whatever reason these don't have a valid value (just xxx ) during accumulation
    // but _can_ access kernel0.out (?)
    reg signed [2*W-1:0]  kernel0_out [0:7];
    reg signed [2*W-1:0]  kernel1_out [0:7];
    reg signed [2*W-1:0]  kernel2_out [0:7];
    reg signed [2*W-1:0]  kernel3_out [0:7];

    // double width accumulator
    reg signed [2*W-1:0]  accum [0:7];

    // single width final result
    reg signed [W-1:0]  result [0:7];

    // bias values
    initial begin
        $readmemh({B_VALUES,"/bias.hex"}, bias_values);
    end
    reg signed [2*W-1:0] bias_values [0:7];

    // 4 kernel mat muls

    row_by_matrix_multiply #(.B_VALUES({B_VALUES,"/k0"})) kernel0 (
        .clk(clk), .rst(rst),
        .a_d0(a0_d0), .a_d1(a0_d1), .a_d2(a0_d2), .a_d3(a0_d3),
        .a_d4(a0_d4), .a_d5(a0_d5), .a_d6(a0_d6), .a_d7(a0_d7),
        .out_d0(kernel0_out[0]), .out_d1(kernel0_out[1]), .out_d2(kernel0_out[2]), .out_d3(kernel0_out[3]),
        .out_d4(kernel0_out[4]), .out_d5(kernel0_out[5]), .out_d6(kernel0_out[6]), .out_d7(kernel0_out[7]),
        .out_v(kernel0_v)
    );

    row_by_matrix_multiply #(.B_VALUES({B_VALUES,"/k1"})) kernel1 (
        .clk(clk), .rst(rst),
        .a_d0(a1_d0), .a_d1(a1_d1), .a_d2(a1_d2), .a_d3(a1_d3),
        .a_d4(a1_d4), .a_d5(a1_d5), .a_d6(a1_d6), .a_d7(a1_d7),
        .out_d0(kernel1_out[0]), .out_d1(kernel1_out[1]), .out_d2(kernel1_out[2]), .out_d3(kernel1_out[3]),
        .out_d4(kernel1_out[4]), .out_d5(kernel1_out[5]), .out_d6(kernel1_out[6]), .out_d7(kernel1_out[7]),
        .out_v(kernel1_v)
    );

    row_by_matrix_multiply #(.B_VALUES({B_VALUES,"/k2"})) kernel2 (
        .clk(clk), .rst(rst),
        .a_d0(a2_d0), .a_d1(a2_d1), .a_d2(a2_d2), .a_d3(a2_d3),
        .a_d4(a2_d4), .a_d5(a2_d5), .a_d6(a2_d6), .a_d7(a2_d7),
        .out_d0(kernel2_out[0]), .out_d1(kernel2_out[1]), .out_d2(kernel2_out[2]), .out_d3(kernel2_out[3]),
        .out_d4(kernel2_out[4]), .out_d5(kernel2_out[5]), .out_d6(kernel2_out[6]), .out_d7(kernel2_out[7]),
        .out_v(kernel2_v)
    );

    row_by_matrix_multiply #(.B_VALUES({B_VALUES,"/k3"})) kernel3 (
        .clk(clk), .rst(rst),
        .a_d0(a3_d0), .a_d1(a3_d1), .a_d2(a3_d2), .a_d3(a3_d3),
        .a_d4(a3_d4), .a_d5(a3_d5), .a_d6(a3_d6), .a_d7(a3_d7),
        .out_d0(kernel3_out[0]), .out_d1(kernel3_out[1]), .out_d2(kernel3_out[2]), .out_d3(kernel3_out[3]),
        .out_d4(kernel3_out[4]), .out_d5(kernel3_out[5]), .out_d6(kernel3_out[6]), .out_d7(kernel3_out[7]),
        .out_v(kernel3_v)
    );

    `define relu(a) (a[W-1] == 1 ) ? 0 : a

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            c1d_state <= MAT_MUL_RUNNING;
            out_v <= 0;
        end else
            case(c1d_state)
                MAT_MUL_RUNNING: begin
                    if (kernel0_v && kernel1_v && kernel2_v && kernel3_v) c1d_state = ACCUMULATE;
                end
                ACCUMULATE: begin
                    accum[0] <= kernel0_out[0] + kernel1_out[0] + kernel2_out[0] + kernel3_out[0];
                    accum[1] <= kernel0_out[1] + kernel1_out[1] + kernel2_out[1] + kernel3_out[1];
                    accum[2] <= kernel0_out[2] + kernel1_out[2] + kernel2_out[2] + kernel3_out[2];
                    accum[3] <= kernel0_out[3] + kernel1_out[3] + kernel2_out[3] + kernel3_out[3];
                    accum[4] <= kernel0_out[4] + kernel1_out[4] + kernel2_out[4] + kernel3_out[4];
                    accum[5] <= kernel0_out[5] + kernel1_out[5] + kernel2_out[5] + kernel3_out[5];
                    accum[6] <= kernel0_out[6] + kernel1_out[6] + kernel2_out[6] + kernel3_out[6];
                    accum[7] <= kernel0_out[7] + kernel1_out[7] + kernel2_out[7] + kernel3_out[7];
                    c1d_state <= BIAS_ADD;
                end
                BIAS_ADD: begin
                    accum[0] <= accum[0] + bias_values[0];
                    accum[1] <= accum[1] + bias_values[1];
                    accum[2] <= accum[2] + bias_values[2];
                    accum[3] <= accum[3] + bias_values[3];
                    accum[4] <= accum[4] + bias_values[4];
                    accum[5] <= accum[5] + bias_values[5];
                    accum[6] <= accum[6] + bias_values[6];
                    accum[7] <= accum[7] + bias_values[7];
                    c1d_state <= SINGLE_W;
                end
                SINGLE_W: begin
                    result[0] <= accum[0][27:12];
                    result[1] <= accum[1][27:12];
                    result[2] <= accum[2][27:12];
                    result[3] <= accum[3][27:12];
                    result[4] <= accum[4][27:12];
                    result[5] <= accum[5][27:12];
                    result[6] <= accum[6][27:12];
                    result[7] <= accum[7][27:12];
                    c1d_state = OUTPUT;
                end
                OUTPUT: begin
                    out_d0 <= apply_relu ? `relu(result[0]) : result[0];
                    out_d1 <= apply_relu ? `relu(result[1]) : result[1];
                    out_d2 <= apply_relu ? `relu(result[2]) : result[2];
                    out_d3 <= apply_relu ? `relu(result[3]) : result[3];
                    out_d4 <= apply_relu ? `relu(result[4]) : result[4];
                    out_d5 <= apply_relu ? `relu(result[5]) : result[5];
                    out_d6 <= apply_relu ? `relu(result[6]) : result[6];
                    out_d7 <= apply_relu ? `relu(result[7]) : result[7];
                    out_v <= 1;
                end
            endcase
    end

endmodule


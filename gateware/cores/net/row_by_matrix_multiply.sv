`default_nettype none

// a . b_values -> out
// (1, 8) . (8, 8) -> (1, 8)

// TODO: could pack out as well?

module row_by_matrix_multiply #(
    parameter W=16,  // width for each element
    parameter D=8,   // size of packed port arrays
    parameter B_VALUES
)(
  input                        clk,
  input                        rst,
  input signed [D*W-1:0]       packed_a,
  output reg signed [2*W-1:0]  out_d0,
  output reg signed [2*W-1:0]  out_d1,
  output reg signed [2*W-1:0]  out_d2,
  output reg signed [2*W-1:0]  out_d3,
  output reg signed [2*W-1:0]  out_d4,
  output reg signed [2*W-1:0]  out_d5,
  output reg signed [2*W-1:0]  out_d6,
  output reg signed [2*W-1:0]  out_d7,
  output reg                   out_v
);

    reg col0_v;
    reg col1_v;
    reg col2_v;
    reg col3_v;
    reg col4_v;
    reg col5_v;
    reg col6_v;
    reg col7_v;

    dot_product #(.B_VALUES({B_VALUES,"/c0.hex"})) col0 (
        .clk(clk), .rst(rst),
        .packed_a(packed_a),
        .out(out_d0), .out_v(col0_v)
    );

    dot_product #(.B_VALUES({B_VALUES,"/c1.hex"})) col1 (
        .clk(clk), .rst(rst),
        .packed_a(packed_a),
        .out(out_d1), .out_v(col1_v)
    );

    dot_product #(.B_VALUES({B_VALUES,"/c2.hex"})) col2 (
        .clk(clk), .rst(rst),
        .packed_a(packed_a),
        .out(out_d2), .out_v(col2_v)
    );

    dot_product #(.B_VALUES({B_VALUES,"/c3.hex"})) col3 (
        .clk(clk), .rst(rst),
        .packed_a(packed_a),
        .out(out_d3), .out_v(col3_v)
    );

    dot_product #(.B_VALUES({B_VALUES,"/c4.hex"})) col4 (
        .clk(clk), .rst(rst),
        .packed_a(packed_a),
        .out(out_d4), .out_v(col4_v)
    );

    dot_product #(.B_VALUES({B_VALUES,"/c5.hex"})) col5 (
        .clk(clk), .rst(rst),
        .packed_a(packed_a),
        .out(out_d5), .out_v(col5_v)
    );

    dot_product #(.B_VALUES({B_VALUES,"/c6.hex"})) col6 (
        .clk(clk), .rst(rst),
        .packed_a(packed_a),
        .out(out_d6), .out_v(col6_v)
    );

    dot_product #(.B_VALUES({B_VALUES,"/c7.hex"})) col7 (
        .clk(clk), .rst(rst),
        .packed_a(packed_a),
        .out(out_d7), .out_v(col7_v)
    );

    assign out_v = col0_v && col1_v && col2_v && col3_v && col4_v && col5_v && col6_v && col7_v;


endmodule

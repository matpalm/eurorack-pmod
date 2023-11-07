`default_nettype none

module po2_row_by_matrix_multiply #(
    parameter W=16,       // width for each element
    parameter IN_D,       // size of packed port arrays for a input
    parameter OUT_D,      // size of packed port arrays for output
    parameter WEIGHTS     // root dir for weight hex files
)(
  input                              clk,
  input                              rst,
  input signed [IN_D*W-1:0]          packed_a,
  output reg signed [2*OUT_D*W-1:0]  packed_out,
  output reg                         out_v
);

    reg [0:OUT_D-1] col_v;

    // dot product output unpacked. this variable only introduced to
    // allow a generate block for assign since it uses j in the slicing
    logic signed [2*W-1:0]  dp_N_out [0:OUT_D-1];
    genvar j;
    generate
        for (j=0; j<OUT_D; j++) begin
            localparam a = (OUT_D-j)*2*W-1;
            localparam b = (OUT_D-j-1)*2*W;
            assign packed_out[a:b] = dp_N_out[j];
        end
    endgenerate

    // auto generated! see sverilog_version/generate.py

    po2_dot_product #(.W(W), .D(IN_D), .WEIGHTS({WEIGHTS, "/c00"})) col0 (
        .clk(clk), .rst(rst), .packed_a(packed_a), .out(dp_N_out[0]), .out_v(col_v[0])
    );
    po2_dot_product #(.W(W), .D(IN_D), .WEIGHTS({WEIGHTS, "/c01"})) col1 (
        .clk(clk), .rst(rst), .packed_a(packed_a), .out(dp_N_out[1]), .out_v(col_v[1])
    );
    po2_dot_product #(.W(W), .D(IN_D), .WEIGHTS({WEIGHTS, "/c02"})) col2 (
        .clk(clk), .rst(rst), .packed_a(packed_a), .out(dp_N_out[2]), .out_v(col_v[2])
    );
    po2_dot_product #(.W(W), .D(IN_D), .WEIGHTS({WEIGHTS, "/c03"})) col3 (
        .clk(clk), .rst(rst), .packed_a(packed_a), .out(dp_N_out[3]), .out_v(col_v[3])
    );

    generate
        if (OUT_D > 4) begin
            po2_dot_product #(.W(W), .D(IN_D), .WEIGHTS({WEIGHTS, "/c04"})) col4 (
                .clk(clk), .rst(rst), .packed_a(packed_a), .out(dp_N_out[4]), .out_v(col_v[4])
            );
            po2_dot_product #(.W(W), .D(IN_D), .WEIGHTS({WEIGHTS, "/c05"})) col5 (
                .clk(clk), .rst(rst), .packed_a(packed_a), .out(dp_N_out[5]), .out_v(col_v[5])
            );
            po2_dot_product #(.W(W), .D(IN_D), .WEIGHTS({WEIGHTS, "/c06"})) col6 (
                .clk(clk), .rst(rst), .packed_a(packed_a), .out(dp_N_out[6]), .out_v(col_v[6])
            );
            po2_dot_product #(.W(W), .D(IN_D), .WEIGHTS({WEIGHTS, "/c07"})) col7 (
                .clk(clk), .rst(rst), .packed_a(packed_a), .out(dp_N_out[7]), .out_v(col_v[7])
            );
        end
    endgenerate

    generate
        if (OUT_D > 8) begin
            po2_dot_product #(.W(W), .D(IN_D), .WEIGHTS({WEIGHTS, "/c08"})) col8 (
                .clk(clk), .rst(rst), .packed_a(packed_a), .out(dp_N_out[8]), .out_v(col_v[8])
            );
            po2_dot_product #(.W(W), .D(IN_D), .WEIGHTS({WEIGHTS, "/c09"})) col9 (
                .clk(clk), .rst(rst), .packed_a(packed_a), .out(dp_N_out[9]), .out_v(col_v[9])
            );
            po2_dot_product #(.W(W), .D(IN_D), .WEIGHTS({WEIGHTS, "/c10"})) col10 (
                .clk(clk), .rst(rst), .packed_a(packed_a), .out(dp_N_out[10]), .out_v(col_v[10])
            );
            po2_dot_product #(.W(W), .D(IN_D), .WEIGHTS({WEIGHTS, "/c11"})) col11 (
                .clk(clk), .rst(rst), .packed_a(packed_a), .out(dp_N_out[11]), .out_v(col_v[11])
            );
            po2_dot_product #(.W(W), .D(IN_D), .WEIGHTS({WEIGHTS, "/c12"})) col12 (
                .clk(clk), .rst(rst), .packed_a(packed_a), .out(dp_N_out[12]), .out_v(col_v[12])
            );
            po2_dot_product #(.W(W), .D(IN_D), .WEIGHTS({WEIGHTS, "/c13"})) col13 (
                .clk(clk), .rst(rst), .packed_a(packed_a), .out(dp_N_out[13]), .out_v(col_v[13])
            );
            po2_dot_product #(.W(W), .D(IN_D), .WEIGHTS({WEIGHTS, "/c14"})) col14 (
                .clk(clk), .rst(rst), .packed_a(packed_a), .out(dp_N_out[14]), .out_v(col_v[14])
            );
            po2_dot_product #(.W(W), .D(IN_D), .WEIGHTS({WEIGHTS, "/c15"})) col15 (
                .clk(clk), .rst(rst), .packed_a(packed_a), .out(dp_N_out[15]), .out_v(col_v[15])
            );
        end
    endgenerate

    assign out_v = (col_v == '1);


endmodule

`default_nettype none

module row_by_matrix_multiply #(
    parameter W,        // width for each element
    parameter IN_D,     // size of packed port arrays for a input
    parameter OUT_D,    // size of packed port arrays for output
    parameter B_VALUES
)(
  input                              clk,
  input                              rst,
  input signed [IN_D*W-1:0]          packed_a,
  output reg signed [2*OUT_D*W-1:0]  packed_out,
  output reg                         out_v
);

    reg col_v [0:OUT_D-1];

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

    // TODO: how to do create these dynamically in a generate block?
    //       can't use arrays of instances ( because of B_VALUES )

    // as is we now have a clumsy example where we support either 4, 8 or 16 :/

    dot_product #(.W(W), .D(IN_D), .B_VALUES({B_VALUES,"/c0.hex"})) col0 (
        .clk(clk), .rst(rst), .packed_a(packed_a), .out(dp_N_out[0]), .out_v(col_v[0])
    );
    dot_product #(.W(W), .D(IN_D), .B_VALUES({B_VALUES,"/c1.hex"})) col1 (
        .clk(clk), .rst(rst), .packed_a(packed_a), .out(dp_N_out[1]), .out_v(col_v[1])
    );
    dot_product #(.W(W), .D(IN_D), .B_VALUES({B_VALUES,"/c2.hex"})) col2 (
        .clk(clk), .rst(rst), .packed_a(packed_a), .out(dp_N_out[2]), .out_v(col_v[2])
    );
    dot_product #(.W(W), .D(IN_D), .B_VALUES({B_VALUES,"/c3.hex"})) col3 (
        .clk(clk), .rst(rst), .packed_a(packed_a), .out(dp_N_out[3]), .out_v(col_v[3])
    );

    generate
        if (OUT_D >=8 ) begin
            dot_product #(.W(W), .D(IN_D), .B_VALUES({B_VALUES,"/c4.hex"})) col4 (
                .clk(clk), .rst(rst), .packed_a(packed_a), .out(dp_N_out[4]), .out_v(col_v[4])
            );
            dot_product #(.W(W), .D(IN_D), .B_VALUES({B_VALUES,"/c5.hex"})) col5 (
                .clk(clk), .rst(rst), .packed_a(packed_a), .out(dp_N_out[5]), .out_v(col_v[5])
            );
            dot_product #(.W(W), .D(IN_D), .B_VALUES({B_VALUES,"/c6.hex"})) col6 (
                .clk(clk), .rst(rst), .packed_a(packed_a), .out(dp_N_out[6]), .out_v(col_v[6])
            );
            dot_product #(.W(W), .D(IN_D), .B_VALUES({B_VALUES,"/c7.hex"})) col7 (
                .clk(clk), .rst(rst), .packed_a(packed_a), .out(dp_N_out[7]), .out_v(col_v[7])
            );
        end
    endgenerate

    generate
        if (OUT_D == 16) begin
            dot_product #(.W(W), .D(IN_D), .B_VALUES({B_VALUES,"/c8.hex"})) col8 (
                .clk(clk), .rst(rst), .packed_a(packed_a), .out(dp_N_out[8]), .out_v(col_v[8])
            );
            dot_product #(.W(W), .D(IN_D), .B_VALUES({B_VALUES,"/c9.hex"})) col9 (
                .clk(clk), .rst(rst), .packed_a(packed_a), .out(dp_N_out[9]), .out_v(col_v[9])
            );
            dot_product #(.W(W), .D(IN_D), .B_VALUES({B_VALUES,"/c10.hex"})) col10 (
                .clk(clk), .rst(rst), .packed_a(packed_a), .out(dp_N_out[10]), .out_v(col_v[10])
            );
            dot_product #(.W(W), .D(IN_D), .B_VALUES({B_VALUES,"/c11.hex"})) col11 (
                .clk(clk), .rst(rst), .packed_a(packed_a), .out(dp_N_out[11]), .out_v(col_v[11])
            );
            dot_product #(.W(W), .D(IN_D), .B_VALUES({B_VALUES,"/c12.hex"})) col12 (
                .clk(clk), .rst(rst), .packed_a(packed_a), .out(dp_N_out[12]), .out_v(col_v[12])
            );
            dot_product #(.W(W), .D(IN_D), .B_VALUES({B_VALUES,"/c13.hex"})) col13 (
                .clk(clk), .rst(rst), .packed_a(packed_a), .out(dp_N_out[13]), .out_v(col_v[13])
            );
            dot_product #(.W(W), .D(IN_D), .B_VALUES({B_VALUES,"/c14.hex"})) col14 (
                .clk(clk), .rst(rst), .packed_a(packed_a), .out(dp_N_out[14]), .out_v(col_v[14])
            );
            dot_product #(.W(W), .D(IN_D), .B_VALUES({B_VALUES,"/c15.hex"})) col15 (
                .clk(clk), .rst(rst), .packed_a(packed_a), .out(dp_N_out[15]), .out_v(col_v[15])
            );
        end
    endgenerate

    // TODO: is it enough to just check one?
    assign out_v = col_v[0];


endmodule

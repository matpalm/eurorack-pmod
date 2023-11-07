`default_nettype none

module po2_conv1d #(
    parameter W=16,     // width for each element
    parameter IN_D,     // size of packed port arrays
    parameter OUT_D,    // size of packed port arrays
    parameter WEIGHTS   // root dir for weight hex files
)(
  input                            clk,
  input                            rst,
  input                            apply_relu,
  input signed [IN_D*W-1:0]        packed_a,
  output reg signed [OUT_D*W-1:0]  packed_out,
  output reg                       out_v
);

    localparam
        MAT_MUL_RUNNING  = 0,
        ACCUMULATE       = 1,   // TODO: not used for po2_ version, but makes tests more consistent
        BIAS_ADD         = 2,
        CLIP_LOWER       = 3,
        CLIP_UPPER       = 4,
        SINGLE_W         = 5,
        APPLY_RELU       = 6,
        OUTPUT           = 7;
    reg [2:0] state;

    wire kernel_v;

    // for whatever reason these don't have a valid value (just xxx ) during accumulation
    // but _can_ access kernel0.out (?). also we don't put these into a single 4 element
    // port array because of how they are later accessed
    reg signed [2*OUT_D*W-1:0]  kernel_out;

    // double width accumulator
    reg signed [2*W-1:0]  accum [0:OUT_D-1];

    // single width final result
    reg signed [W-1:0]  result [0:OUT_D-1];

    // bias values
    reg signed [2*W-1:0] bias_values [0:OUT_D-1];
    initial begin
        $readmemh({WEIGHTS, "/bias.hex"}, bias_values);
    end

    // only a single kernel mat mul for po2 module

    po2_row_by_matrix_multiply #(.W(W), .IN_D(IN_D), .OUT_D(OUT_D), .WEIGHTS({WEIGHTS,"/k0"})) kernel0 (
        .clk(clk), .rst(rst), .packed_a(packed_a), .packed_out(kernel_out), .out_v(kernel_v)
    );

    `define relu(a) (a[W-1] == 1 ) ? 0 : a

    integer i;
    genvar j;

    // the max value for single precision is 7.999755859375 whereas the min value is -8
    // so to avoid overflow we clip the double width precision
    // value between these bounds _before_ the single precision conversion
    localparam int signed lower_bound = 32'b11111000000000000000000000000000;  // -8
    localparam int signed upper_bound = 32'b00000111111111111111000000000000;  // 7.999755859375

    // kernel output unpacked. this variable only introduced to
    // allow a generate block for assign since it uses j in the slicing
    logic signed [2*W-1:0]  kernel_out_unpacked [0:OUT_D-1];
    generate
        for (j=0; j<OUT_D; j++) begin
            localparam a = (OUT_D-j)*2*W-1;
            localparam b = (OUT_D-j-1)*2*W;
            assign kernel_out_unpacked[j] = kernel_out[a:b];
        end
    endgenerate

    // similarily, since packedout has variable in slicing, we need to
    // explicitly assign it.
    generate
        for (j=0; j<OUT_D; j++) begin
            assign packed_out[(OUT_D-j)*W-1:(OUT_D-j-1)*W] = result[j];
        end
    endgenerate

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= MAT_MUL_RUNNING;
            out_v <= 0;
        end else
            case(state)
                MAT_MUL_RUNNING: begin
                    if (kernel_v == '1) state = BIAS_ADD;
                end
                // note: po2 version has no ACCUMULATE
                BIAS_ADD: begin
                    for (i=0; i<OUT_D; i=i+1) begin
                        accum[i] <= kernel_out_unpacked[i] + bias_values[i];
                    end
                    state <= CLIP_LOWER;
                end
                CLIP_LOWER: begin
                    for (i=0; i<OUT_D; i=i+1) begin
                        accum[i] <= accum[i] < lower_bound ? lower_bound : accum[i];
                    end
                    state <= CLIP_UPPER;
                end
                CLIP_UPPER: begin
                    for (i=0; i<OUT_D; i=i+1) begin
                        accum[i] <= accum[i] > upper_bound ? upper_bound : accum[i];
                    end
                    state <= SINGLE_W;
                end
                SINGLE_W: begin
                    // TODO: constants 12 and 27 won't work for other W :/
                    for (i=0; i<OUT_D; i=i+1) begin
                        result[i] <= accum[i][27:12];
                    end
                    state = APPLY_RELU;
                end
                APPLY_RELU: begin
                    for (i=0; i<OUT_D; i=i+1) begin
                        result[i] <= apply_relu ? `relu(result[i]) : result[i];
                    end
                    state = OUTPUT;
                end
                OUTPUT: begin
                    // NOTE: packed_out assigned in generate block from result
                    out_v <= 1;
                end
            endcase
    end

endmodule



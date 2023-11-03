`default_nettype none

// a . b_values -> out

module dot_product #(
    parameter W,       // width for each element
    parameter D,       // size of packed port arrays
    parameter B_VALUES
)(
  input                        clk,
  input                        rst,
  input signed [D*W-1:0]       packed_a,
  output reg signed [2*W-1:0]  out,
  output reg                   out_v
);

    // unpack a
    logic signed [W-1:0] a[D];
    genvar j;
    generate
        for (j=0; j<D; j++) begin
            assign a[j] = packed_a[W*(D-j-1) +: W];
        end
    endgenerate

    localparam
        MULTIPLY_ELEMENT     = 0,
        FINAL_ADD            = 1,
        DONE                 = 2;
    reg [2:0] state = MULTIPLY_ELEMENT;

    // see https://projectf.io/posts/fixed-point-numbers-in-verilog/
    reg signed [2*W-1:0] acc0;
    reg signed [2*W-1:0] product0;
    //reg signed [2*W-1:0] acc1;
    //reg signed [2*W-1:0] product1;

    // b values for dot product are network weights and are
    // provided by B_VALUES module level param
    initial begin
        $readmemh(B_VALUES, b_values);
        out_v <= 0;
    end
    reg signed [W-1:0] b_values [0:D-1];

    integer i;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            acc0 <= 0;
            product0 <= 0;
            i <= 0;
            state <= MULTIPLY_ELEMENT;
            out_v <= 0;
        end else
            case(state)
                MULTIPLY_ELEMENT: begin
                    acc0 <= acc0 + product0;
                    product0 <= a[i] * b_values[i];
                    i <= i + 1;
                    state <= (i == D-1) ? FINAL_ADD : MULTIPLY_ELEMENT;
                end
                FINAL_ADD: begin
                    acc0 <= acc0 + product0;
                    state <= DONE;
                end
                DONE: begin
                    out <= acc0;
                    out_v <= 1;
                end
            endcase

    end

endmodule

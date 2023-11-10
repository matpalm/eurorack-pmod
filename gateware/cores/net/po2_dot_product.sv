`default_nettype none

// a . b_values -> out

module po2_dot_product #(
    parameter W=16,     // width for each element
    parameter D,        // size of dot product
    parameter WEIGHTS   // root dir for weight hex files
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
        START_NEXT_MULT  = 0,
        WAIT_FOR_MULT    = 1,
        ACCUMULATE       = 2,
        FINAL_ACCUMULATE = 3,
        DONE             = 4;
    reg [3:0] state;

    // D bits representing whether the Dth weight is zero or negative
    reg zero_weights [0:D-1];
    reg negative_weights [0:D-1];

    // D weights representing the log values of the weights
    reg [W-1:0] log_2_weights [0:D-1];

    // b values for dot product are network weights and are
    // provided by WEIGHTS module level param
    initial begin
        $readmemh({WEIGHTS, "/zero_weights.hex"}, zero_weights);
        $readmemh({WEIGHTS, "/negative_weights.hex"}, negative_weights);
        $readmemh({WEIGHTS, "/log_2_weights.hex"}, log_2_weights);
        out_v <= 0;
    end

    localparam N_MULTS = 2;

    // accumulator for all po2_multiply results
    reg signed [2*W-1:0] accumulator [0:N_MULTS-1];

    // registers to handle in/out of po2 mult
    reg                  po2_rst;
    reg signed [W-1:0]   po2_inp [0:N_MULTS-1];
    reg                  po2_zero_weight [0:N_MULTS-1];
    reg                  po2_negative_weight [0:N_MULTS-1];
    reg [W-1:0]          po2_log_2_weight [0:N_MULTS-1];
    reg signed [2*W-1:0] po2_result [0:N_MULTS-1];
    reg [N_MULTS-1:0]    po2_result_v;

    po2_multiply #(.W(W), .I(4)) po2_mult_0 (
        .clk(clk), .rst(po2_rst), .inp(po2_inp[0]),
        .zero_weight(po2_zero_weight[0]), .negative_weight(po2_negative_weight[0]),
        .log_2_weight(po2_log_2_weight[0]),
        .result(po2_result[0]), .result_v(po2_result_v[0])
    );

    po2_multiply #(.W(W), .I(4)) po2_mult_1 (
        .clk(clk), .rst(po2_rst), .inp(po2_inp[1]),
        .zero_weight(po2_zero_weight[1]), .negative_weight(po2_negative_weight[1]),
        .log_2_weight(po2_log_2_weight[1]),
        .result(po2_result[1]), .result_v(po2_result_v[1])
    );

    // po2_multiply #(.W(W), .I(4)) po2_mult_2 (
    //     .clk(clk), .rst(po2_rst), .inp(po2_inp[2]),
    //     .zero_weight(po2_zero_weight[2]), .negative_weight(po2_negative_weight[2]),
    //     .log_2_weight(po2_log_2_weight[2]),
    //     .result(po2_result[2]), .result_v(po2_result_v[2])
    // );

    // po2_multiply #(.W(W), .I(4)) po2_mult_3 (
    //     .clk(clk), .rst(po2_rst), .inp(po2_inp[3]),
    //     .zero_weight(po2_zero_weight[3]), .negative_weight(po2_negative_weight[3]),
    //     .log_2_weight(po2_log_2_weight[3]),
    //     .result(po2_result[3]), .result_v(po2_result_v[3])
    // );

    integer i;
    integer k;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (k=0; k<N_MULTS; k=k+1) begin
                accumulator[k] <= 0;
            end
            i <= 0;
            state <= START_NEXT_MULT;
            out_v <= 0;
        end else
            case(state)
                START_NEXT_MULT: begin
                    po2_rst <= 1;
                    for (k=0; k<N_MULTS; k=k+1) begin
                        po2_inp[k] <= a[i+k];
                        po2_zero_weight[k] <= zero_weights[i+k];
                        po2_negative_weight[k] <= negative_weights[i+k];
                        po2_log_2_weight[k] <= log_2_weights[i+k];
                    end
                    state <= WAIT_FOR_MULT;
                end
                WAIT_FOR_MULT: begin
                    po2_rst <= 0;
                    if (po2_result_v == '1) state <= ACCUMULATE;
                end
                ACCUMULATE: begin
                    for (k=0; k<N_MULTS; k=k+1) begin
                        accumulator[k] <= accumulator[k] + po2_result[k];
                    end
                    i <= i + N_MULTS;
                    state <= (i == D-N_MULTS) ? FINAL_ACCUMULATE : START_NEXT_MULT;  // -N_MULTS for N_MULTS dot products
                end
                FINAL_ACCUMULATE: begin
                    accumulator[0] <= accumulator[0] + accumulator[1];
                    //accumulator[0] <= accumulator[0] + accumulator[1] + accumulator[2] + accumulator[3];
                    state <= DONE;
                end
                DONE: begin
                    out <= accumulator[0];
                    out_v <= 1;
                end
            endcase
    end

endmodule

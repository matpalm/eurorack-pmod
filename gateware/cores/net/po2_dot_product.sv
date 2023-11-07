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
        MULTIPLYING_ELEMENTS  = 0,
        ADD_16                = 1,
        ADD_8                 = 2,
        ADD_4                 = 3,
        ADD_2                 = 4,
        DONE                  = 5;
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

    // D double width values to hold the po2 multiplications
    wire signed [2*W-1:0] result [0:D-1];

    // accumulator for all po2_multiply results
    reg signed [2*W-1:0] accumulator [0:(D/2)-1];

    // D bit values for whether the Dth multiplcation is finished
    reg [D-1:0] result_v;

    // as is we now have a clumsy example where we support either D = 4, 8 or 16 :/
    // auto generated! see sverilog_version.generate.py

    po2_multiply #(.W(W), .I(4)) m0 (
        .clk(clk), .rst(rst), .inp(a[0]),
        .zero_weight(zero_weights[0]), .negative_weight(negative_weights[0]), .log_2_weight(log_2_weights[0]),
        .result(result[0]), .result_v(result_v[0])
    );
    po2_multiply #(.W(W), .I(4)) m1 (
        .clk(clk), .rst(rst), .inp(a[1]),
        .zero_weight(zero_weights[1]), .negative_weight(negative_weights[1]), .log_2_weight(log_2_weights[1]),
        .result(result[1]), .result_v(result_v[1])
    );
    po2_multiply #(.W(W), .I(4)) m2 (
        .clk(clk), .rst(rst), .inp(a[2]),
        .zero_weight(zero_weights[2]), .negative_weight(negative_weights[2]), .log_2_weight(log_2_weights[2]),
        .result(result[2]), .result_v(result_v[2])
    );
    po2_multiply #(.W(W), .I(4)) m3 (
        .clk(clk), .rst(rst), .inp(a[3]),
        .zero_weight(zero_weights[3]), .negative_weight(negative_weights[3]), .log_2_weight(log_2_weights[3]),
        .result(result[3]), .result_v(result_v[3])
    );

    generate
        if (D > 4) begin
            po2_multiply #(.W(W), .I(4)) m4 (
                .clk(clk), .rst(rst), .inp(a[4]),
                .zero_weight(zero_weights[4]), .negative_weight(negative_weights[4]), .log_2_weight(log_2_weights[4]),
                .result(result[4]), .result_v(result_v[4])
            );
            po2_multiply #(.W(W), .I(4)) m5 (
                .clk(clk), .rst(rst), .inp(a[5]),
                .zero_weight(zero_weights[5]), .negative_weight(negative_weights[5]), .log_2_weight(log_2_weights[5]),
                .result(result[5]), .result_v(result_v[5])
            );
            po2_multiply #(.W(W), .I(4)) m6 (
                .clk(clk), .rst(rst), .inp(a[6]),
                .zero_weight(zero_weights[6]), .negative_weight(negative_weights[6]), .log_2_weight(log_2_weights[6]),
                .result(result[6]), .result_v(result_v[6])
            );
            po2_multiply #(.W(W), .I(4)) m7 (
                .clk(clk), .rst(rst), .inp(a[7]),
                .zero_weight(zero_weights[7]), .negative_weight(negative_weights[7]), .log_2_weight(log_2_weights[7]),
                .result(result[7]), .result_v(result_v[7])
            );
        end
    endgenerate

    generate
        if (D > 8) begin
            po2_multiply #(.W(W), .I(4)) m8 (
                .clk(clk), .rst(rst), .inp(a[8]),
                .zero_weight(zero_weights[8]), .negative_weight(negative_weights[8]), .log_2_weight(log_2_weights[8]),
                .result(result[8]), .result_v(result_v[8])
            );
            po2_multiply #(.W(W), .I(4)) m9 (
                .clk(clk), .rst(rst), .inp(a[9]),
                .zero_weight(zero_weights[9]), .negative_weight(negative_weights[9]), .log_2_weight(log_2_weights[9]),
                .result(result[9]), .result_v(result_v[9])
            );
            po2_multiply #(.W(W), .I(4)) m10 (
                .clk(clk), .rst(rst), .inp(a[10]),
                .zero_weight(zero_weights[10]), .negative_weight(negative_weights[10]), .log_2_weight(log_2_weights[10]),
                .result(result[10]), .result_v(result_v[10])
            );
            po2_multiply #(.W(W), .I(4)) m11 (
                .clk(clk), .rst(rst), .inp(a[11]),
                .zero_weight(zero_weights[11]), .negative_weight(negative_weights[11]), .log_2_weight(log_2_weights[11]),
                .result(result[11]), .result_v(result_v[11])
            );
            po2_multiply #(.W(W), .I(4)) m12 (
                .clk(clk), .rst(rst), .inp(a[12]),
                .zero_weight(zero_weights[12]), .negative_weight(negative_weights[12]), .log_2_weight(log_2_weights[12]),
                .result(result[12]), .result_v(result_v[12])
            );
            po2_multiply #(.W(W), .I(4)) m13 (
                .clk(clk), .rst(rst), .inp(a[13]),
                .zero_weight(zero_weights[13]), .negative_weight(negative_weights[13]), .log_2_weight(log_2_weights[13]),
                .result(result[13]), .result_v(result_v[13])
            );
            po2_multiply #(.W(W), .I(4)) m14 (
                .clk(clk), .rst(rst), .inp(a[14]),
                .zero_weight(zero_weights[14]), .negative_weight(negative_weights[14]), .log_2_weight(log_2_weights[14]),
                .result(result[14]), .result_v(result_v[14])
            );
            po2_multiply #(.W(W), .I(4)) m15 (
                .clk(clk), .rst(rst), .inp(a[15]),
                .zero_weight(zero_weights[15]), .negative_weight(negative_weights[15]), .log_2_weight(log_2_weights[15]),
                .result(result[15]), .result_v(result_v[15])
            );
        end
    endgenerate

    integer i;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= MULTIPLYING_ELEMENTS;
            out_v <= 0;
        end else
            case(state)
                MULTIPLYING_ELEMENTS: begin
                    if (result_v == '1) begin
                        if (D==16) begin
                            for(i=0; i<8; i=i+1)
                                accumulator[i] <= result[i] + result[i+8];
                            state <= ADD_8;
                        end
                        else if (D==8) begin
                            for(i=0; i<4; i=i+1)
                                accumulator[i] <= result[i] + result[i+4];
                            state <= ADD_4;
                        end
                        else if (D==4) begin
                            accumulator[0] <= result[0] + result[2];
                            accumulator[1] <= result[1] + result[3];
                            state <= ADD_2;
                        end
                    end
                end
                ADD_8: begin
                    for(i=0; i<4; i=i+1)
                        accumulator[i] <= accumulator[i] + accumulator[i+4];
                    state <= ADD_4;
                end
                ADD_4: begin
                    accumulator[0] <= accumulator[0] + accumulator[2];
                    accumulator[1] <= accumulator[1] + accumulator[3];
                    state <= ADD_2;
                end
                ADD_2: begin
                    accumulator[0] <= accumulator[0] + accumulator[1];
                    state <= DONE;
                end
                DONE: begin
                    out <= accumulator[0];
                    out_v <= 1;
                end
            endcase

    end

endmodule

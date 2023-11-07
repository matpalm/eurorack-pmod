`default_nettype none

module activation_cache #(
    parameter W = 16,        // width for each element
    parameter D,             // size of packed port arrays
    parameter DILATION = 4   // dilation
    // assume kernel size = 4
)(
    input                     clk,
    input                     rst,
    input             [D*W-1:0] inp,
    output reg signed [D*W-1:0] out_l0,
    output reg signed [D*W-1:0] out_l1,
    output reg signed [D*W-1:0] out_l2,
    output reg signed [D*W-1:0] out_l3
);

localparam KERNEL_SIZE = 4;
localparam NUM_ENTRIES = DILATION * KERNEL_SIZE;
localparam ADDR_W = $clog2(NUM_ENTRIES)-1;

reg [ADDR_W:0] write_head = 0;
reg signed [D*W-1:0] buffer [NUM_ENTRIES];

integer i;
initial begin
    for(i=0; i<NUM_ENTRIES; i=i+1)
        buffer[i] <= 0;
end

wire [ADDR_W:0] out1_addr;
assign out1_addr = write_head - DILATION;

wire [ADDR_W:0] out2_addr;
assign out2_addr = write_head - (2*DILATION);

wire [ADDR_W:0] out3_addr;
assign out3_addr = write_head - (3*DILATION);

`define wrapped(a) (a < 0) ? (NUM_ENTRIES-a) : a

always @(posedge clk) begin
    write_head <= write_head + 1;
    buffer[write_head] <= inp;
    out_l0 <= buffer[`wrapped(out3_addr)];
    out_l1 <= buffer[`wrapped(out2_addr)];
    out_l2 <= buffer[`wrapped(out1_addr)];
    out_l3 <= inp;
end

endmodule
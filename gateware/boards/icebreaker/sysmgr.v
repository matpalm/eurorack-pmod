`default_nettype none

module sysmgr (
    // Assumed 12Mhz CLK input on iCEbreaker
	input  wire clk_in,
	input  wire rst_in,
    // Actually the output here is the same frequency as the input
    // but we leave all this PLL logic here as you might need to scale
    // the clock down to 12m on different boards.
	output wire clk_256fs,
	output wire clk_fs,
	output wire rst_out
);

	// Signals
	wire pll_lock;
	wire pll_reset_n;

    // This 2x output is not actually used for now.
	wire clk_2x_i;
	wire clk_1x_i;
	wire rst_i;

	reg [7:0] rst_cnt;
	reg [7:0] clkdiv;

	assign clk_256fs = clk_1x_i;
	assign pll_reset_n = ~rst_in;
	assign rst_i = rst_cnt[7];
	assign clk_fs = clkdiv[7];

	// PLL instance
`ifndef VERILATOR_LINT_ONLY
	SB_PLL40_2F_PAD #(
		.DIVR(4'b0000),
		.DIVF(7'b0111111),
		.DIVQ(3'b101),
		.FILTER_RANGE(3'b001),
		.FEEDBACK_PATH("SIMPLE"),
		.DELAY_ADJUSTMENT_MODE_FEEDBACK("FIXED"),
		.FDA_FEEDBACK(4'b0000),
		.SHIFTREG_DIV_MODE(2'b00),
		.PLLOUT_SELECT_PORTA("GENCLK"),
		.PLLOUT_SELECT_PORTB("GENCLK_HALF"),
	) pll_I (
		.PACKAGEPIN(clk_in),
		.PLLOUTGLOBALA(clk_2x_i),
		.PLLOUTGLOBALB(clk_1x_i),
		.EXTFEEDBACK(1'b0),
		.DYNAMICDELAY(8'h00),
		.RESETB(pll_reset_n),
		.BYPASS(1'b0),
		.LATCHINPUTVALUE(1'b0),
		.LOCK(pll_lock),
		.SDI(1'b0),
		.SDO(),
		.SCLK(1'b0)
	);
`endif

	// Logic reset generation
	always @(posedge clk_1x_i or negedge pll_lock)
		if (!pll_lock)
			rst_cnt <= 8'h80;
		else if (rst_cnt[7])
			rst_cnt <= rst_cnt + 1;

    always @(posedge clk_256fs)
        if (rst_i)
            clkdiv <= 8'h00;
        else
            clkdiv <= clkdiv + 1;


`ifndef VERILATOR_LINT_ONLY
	SB_GB rst_gbuf_I (
		.USER_SIGNAL_TO_GLOBAL_BUFFER(rst_i),
		.GLOBAL_BUFFER_OUTPUT(rst_out)
	);
`endif

endmodule // sysmgr

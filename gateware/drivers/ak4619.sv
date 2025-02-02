// Driver for AK4619 CODEC.
//
// Usage:
// - `clk_256fs` and `clk_fs` determine the hardware sample rate.
// - Once CODEC is initialized over I2C, samples can be streamed.
// - `sample_in` is latched on falling `clk_fs`.
// - `sample_out` transitions on falling `clk_fs`.
// - As a result, users of this core should latch sample_out (and transition
// sample_in) on rising `clk_fs`.
//
// This core assumes the device is configured in the audio
// interface mode specified in ak4619-cfg.hex. This happens
// over I2C inside the state machine `pmod_i2c_master.sv`.
//
// The following registers specify the interface format:
//  - FS == 0b000, which means:
//      - MCLK = 256*Fs,
//      - BICK = 128*Fs,
//      - Fs must fall within 8kHz <= Fs <= 48Khz.
// - TDM == 0b1 and DCF == 0b010, which means:
//      - TDM128 mode I2S compatible.
//

`default_nettype none

module ak4619 #(
    parameter W = 16 // sample width, bits
)(
    input  rst,
    input  clk_256fs,
    input  clk_fs,

    // Route these straight out to the CODEC pins.
    output pdn,
    output mclk,
    output bick,
    output lrck,
    output reg sdin1,
    input  sdout1,

    // Transitions on falling `clk_fs`.
    output reg signed [W-1:0] sample_out0,
    output reg signed [W-1:0] sample_out1,
    output reg signed [W-1:0] sample_out2,
    output reg signed [W-1:0] sample_out3,

    // Latches on falling `clk_fs`.
    input signed [W-1:0] sample_in0,
    input signed [W-1:0] sample_in1,
    input signed [W-1:0] sample_in2,
    input signed [W-1:0] sample_in3
);

localparam int N_CHANNELS = 4;

logic signed [(W*N_CHANNELS)-1:0] dac_words;
logic signed [W-1:0] adc_words [N_CHANNELS];

logic last_fs;
logic [7:0] clkdiv;

logic [1:0] channel;
logic [4:0] bit_counter;

assign pdn         = ~rst;
assign bick        = clkdiv[0];
assign mclk        = clk_256fs;
assign lrck        = clkdiv[7];

// 0, 1, 2, 3 == L, R, L, R
assign channel     = clkdiv[7:6];
// 0..31 for each channel, regardless of W.
assign bit_counter = clkdiv[5:1];

always_ff @(posedge clk_256fs) begin
    if (rst) begin
        last_fs <= 0;
        clkdiv <= 0;
        dac_words = 0;
        sample_out0 <= 0;
        sample_out1 <= 0;
        sample_out2 <= 0;
        sample_out3 <= 0;
    end else if (last_fs && ~clk_fs) begin
        // Synchronize clkdiv to the incoming sample clock, latching
        // our inputs and outputs at the falling edge of clk_fs.
        clkdiv <= 8'h0;
        dac_words = {sample_in3, sample_in2,
                     sample_in1, sample_in0};
        sample_out0  <= adc_words[0];
        sample_out1  <= adc_words[1];
        sample_out2  <= adc_words[2];
        sample_out3  <= adc_words[3];
        last_fs <= clk_fs;
    end else if (bick) begin
        // BICK transition HI -> LO: Clock in W bits
        // On HI -> LO both SDIN and SDOUT do not transition.
        // (determined by AK4619 transition polarity register BCKP)
        if (bit_counter == 0) begin
            adc_words[channel] <= 0;
        end
        if (bit_counter < W) begin
            adc_words[channel][W - bit_counter - 1] <= sdout1;
        end
        clkdiv <= clkdiv + 1;
        last_fs <= clk_fs;
    end else begin // BICK: LO -> HI
        // BICK transition LO -> HI: Clock out W bits
        // On LO -> HI both SDIN and SDOUT transition.
        if (bit_counter <= (W-1)) begin
            case (channel)
                0: sdin1 <= dac_words[(1*W)-1-bit_counter];
                1: sdin1 <= dac_words[(2*W)-1-bit_counter];
                2: sdin1 <= dac_words[(3*W)-1-bit_counter];
                3: sdin1 <= dac_words[(4*W)-1-bit_counter];
            endcase
        end else begin
            sdin1 <= 0;
        end
        clkdiv <= clkdiv + 1;
        last_fs <= clk_fs;
    end
end

`ifdef COCOTB_SIM
initial begin
  $dumpfile ("ak4619.vcd");
  $dumpvars;
  #1;
end
`endif

endmodule

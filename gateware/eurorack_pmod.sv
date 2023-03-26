// Module to drive a single `eurorack-pmod`. This can be instantiated
// multiple times for multiple PMODs if desired.
//
// Contains an instantiation of the I2C driver, calibration module
// and user-defined DSP core which may be swapped out.

`default_nettype none

module eurorack_pmod #(
    parameter W = 16, // sample width, bits
    parameter CAL_MEM_FILE = "cal_mem.hex"
)(
    input clk_12mhz,   // Assumed 12MHz
    input rst,

    // Signals to/from eurorack-pmod hardware.
    //
    // Pin # referenced to iCEbreaker PMOD connector if NO ribbon
    // cable is used (i.e pins are not flipped).
    output i2c_scl, // Pin 1
    inout  i2c_sda, // Pin 2
    output pdn,     // Pin 3
    output mclk,    // Pin 4
    output sdin1,   // Pin 7
    input  sdout1,  // Pin 8
    output lrck,    // Pin 9
    output bick,    // Pin 10

    // Signals to exchange information to/from user-defined DSP core.
    //
    // Driven by ak4619_instance, 93.75Khz.
    output sample_clk,
    // Calibrated samples to/from CODEC at sample_clk.
    output signed [W-1:0] cal_in0,
    output signed [W-1:0] cal_in1,
    output signed [W-1:0] cal_in2,
    output signed [W-1:0] cal_in3,
    input signed [W-1:0] cal_out0,
    input signed [W-1:0] cal_out1,
    input signed [W-1:0] cal_out2,
    input signed [W-1:0] cal_out3,
    // EEPROM data read over I2C during startup.
    output [7:0] eeprom_mfg,
    output [7:0] eeprom_dev,
    output [31:0] eeprom_serial,
    // Jack detection inputs read constantly over I2C.
    // Logic '1' == jack is inserted. Bit 0 is input 0.
    output [7:0] jack,

    // Signals used for bringup / debug / calibration.
    //
    // Raw samples from the CODEC ADCs
    output signed [W-1:0] sample_adc0,
    output signed [W-1:0] sample_adc1,
    output signed [W-1:0] sample_adc2,
    output signed [W-1:0] sample_adc3,
    // Used for output calibration. If nonzero, all DAC outputs
    // are directly set to this value.
    input signed [W-1:0] force_dac_output
);

// Raw samples to/from CODEC
logic signed [W-1:0] sample_dac0;
logic signed [W-1:0] sample_dac1;
logic signed [W-1:0] sample_dac2;
logic signed [W-1:0] sample_dac3;

// I2C output assignment / tristating.
// TODO: switch to explicit tristating IO blocks for this so
// Yosys throws blocking errors if the flow doesn't support it.
logic i2c_scl_oe;
logic i2c_sda_oe;
assign i2c_scl = i2c_scl_oe ? 1'b0 : 1'bz;
assign i2c_sda = i2c_sda_oe ? 1'b0 : 1'bz;

// Raw sample calibrator, both for input and output channels.
// Compensates for DC bias in CODEC, gain differences, resistor
// tolerances and so on.
cal #(
    .W(W),
    .CAL_MEM_FILE(CAL_MEM_FILE)
)cal_instance (
    .clk (clk_12mhz),
    .sample_clk (sample_clk),
    // Calibrated inputs are zeroed if jack is unplugged.
    .jack (jack),
    // Note: inputs samples are inverted by analog frontend
    // Should add +1 for precise 2s complement sign change
    .in0 (~sample_adc0),
    .in1 (~sample_adc1),
    .in2 (~sample_adc2),
    .in3 (~sample_adc3),
    .in4 (cal_out0),
    .in5 (cal_out1),
    .in6 (cal_out2),
    .in7 (cal_out3),
    .out0 (cal_in0),
    .out1 (cal_in1),
    .out2 (cal_in2),
    .out3 (cal_in3),
    .out4 (sample_dac0),
    .out5 (sample_dac1),
    .out6 (sample_dac2),
    .out7 (sample_dac3)
);

// CODEC ser-/deserialiser. Also derives sample clock.
ak4619 ak4619_instance (
    .clk     (clk_12mhz),
    .rst     (rst),
    .pdn     (pdn),
    .mclk    (mclk),
    .bick    (bick),
    .lrck    (lrck),
    .sdin1   (sdin1),
    .sdout1  (sdout1),
    .sample_clk  (sample_clk),
    .sample_out0 (sample_adc0),
    .sample_out1 (sample_adc1),
    .sample_out2 (sample_adc2),
    .sample_out3 (sample_adc3),
    .sample_in0 (force_dac_output == 0 ? sample_dac0 : force_dac_output),
    .sample_in1 (force_dac_output == 0 ? sample_dac1 : force_dac_output),
    .sample_in2 (force_dac_output == 0 ? sample_dac2 : force_dac_output),
    .sample_in3 (force_dac_output == 0 ? sample_dac3 : force_dac_output)
);

// I2C transceiver and driver for all connected slaves.
pmod_i2c_master pmod_i2c_master_instance (
    .clk(clk_12mhz),
    .rst(rst),

    .scl_oe(i2c_scl_oe),
    .scl_i(i2c_scl),
    .sda_oe(i2c_sda_oe),
    .sda_i(i2c_sda),

    // LEDs directly linked to input/output sample values
    // for now, although they could do whatever we want.
    .led0( cal_in0[W-1:W-8]),
    .led1( cal_in1[W-1:W-8]),
    .led2( cal_in2[W-1:W-8]),
    .led3( cal_in3[W-1:W-8]),
    .led4(force_dac_output == 0 ? cal_out0[W-1:W-8] : force_dac_output[W-1:W-8]),
    .led5(force_dac_output == 0 ? cal_out1[W-1:W-8] : force_dac_output[W-1:W-8]),
    .led6(force_dac_output == 0 ? cal_out2[W-1:W-8] : force_dac_output[W-1:W-8]),
    .led7(force_dac_output == 0 ? cal_out3[W-1:W-8] : force_dac_output[W-1:W-8]),

    .jack(jack),

    .eeprom_mfg_code(eeprom_mfg),
    .eeprom_dev_code(eeprom_dev),
    .eeprom_serial(eeprom_serial)
);

endmodule
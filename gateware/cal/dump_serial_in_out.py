#!/bin/python3

# dump to stdout the uart debug containing in and out values

import serial
import sys

if len(sys.argv) != 2:
    print("Usage: ./cal.py /dev/ttyX (serial port of FPGA board)")
    sys.exit(-1)

SERIAL_PORT = sys.argv[1]

def twos_comp(val, bits):
    """compute the 2's complement of int value val"""
    if (val & (1 << (bits - 1))) != 0: # if sign bit is set e.g., 8bit: 128-255
        val = val - (1 << bits)        # compute negative value
    return val                         # return positive value as is

ser = serial.Serial(SERIAL_PORT, 1000000)

ports = 'I0 I1 I2 I3 O0 O1 O2 O3'.split(" ")

def decode_raw_samples(n, raw):
    for ix in range(n):
        msb = raw[ix*2]
        lsb = raw[ix*2+1]
        value = (msb << 8) | lsb
        value_tc = twos_comp(value, 16)
        output = f"{ports[ix]} {hex(value)} ({value_tc})"
        sys.stdout.write(str.ljust(output, 20))

while True:
    # TODO: switch from sampling to full processing
    ser.flushInput()
    raw = ser.read(100)
    magix_idx = raw.find(b'\xbe\xef')
    raw = raw[(magix_idx+2):]
    decode_raw_samples(8, raw)  # 4 input, 4 output => 8
    sys.stdout.write("\n")

#!/bin/bash
set -x

##build packages 
ghdl -a packages/instructions.vhd &&
ghdl -a packages/helpers.vhd &&
ghdl -a packages/tb_heplers.vhd &&
ghdl -a packages/assembler.vhd &&
ghdl -a packages/csr_info.vhd &&
ghdl -a packages/assemble_file.vhd &&

##build all the hardware
ghdl -a hw/*.vhd

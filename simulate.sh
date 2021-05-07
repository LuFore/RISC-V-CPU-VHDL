#!/bin/bash
set -x
unitname=$1

ghdl -a  hw/${unitname}.vhd && ghdl -a tb/${unitname}_tb.vhd && ghdl -e tb_${unitname} && ghdl -r tb_${unitname} --wave=tb_${unitname}.ghw && gtkwave tb_${unitname}.ghw 


##### Dump to VCD (old), does not support enums like ghw
#####ghdl -a  hw/${unitname}.vhd && ghdl -a tb/${unitname}_tb.vhd && ghdl -e tb_${unitname} && ghdl -r tb_${unitname} --vcd=tb_${unitname}.vcd && gtkwave tb_${unitname}.vcd 


#####"ghdl -a packages/helpers.vhd && ghdl -a packages/tb_heplers.vhd && ghdl -a packages/assembler.vhd && ghdl -a hw/Integer_32_ALU.vhd"

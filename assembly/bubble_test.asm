bubble test, should return 24 (decimal)

addi 0 0 0 NOP, but this is being used as a data value  of 19
lw 1 0 8  Load the value 20 into register 1 (this might not work if the assembler gets changed)
addi 2 1 5 add the loaded value before it has time to go into a register, testing the bubble
sw 0 2 0 save the value to the cache


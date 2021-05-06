Test load, result should be 19. (Data is not directly written to cache, instead the NOP instruction is loaded, the decimal value of which is 19)

 
addi 0 0 0 NOP, but this is being used as a data value  of 19
lw 1 0 8  Load the value 19 into register 1 
addi 0 0 0 
addi 0 0 0 
addi 0 0 0 
addi 0 0 0    More than enough NOP instructions for pipeline reasons
sw 0 1 0
addi 0 0 0 
addi 0 0 0 
addi 0 0 0 

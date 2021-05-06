Test csr module and traps 

addi 1 0 80 save 80 to register 1 
csrrw 1 1 773 save to register 1 to  mtval, the instruction will trap to instruction 20
ecall throw an exception 
addi 0 0 0
addi 0 0 0
addi 0 0 0
addi 0 0 0 Nops so no accidentl other traps and the file will be padded out so 
addi 0 0 0
addi 0 0 0
addi 0 0 0
addi 0 0 0
addi 0 0 0
addi 0 0 0
addi 0 0 0
addi 0 0 0
addi 0 0 0
addi 0 0 0
addi 0 0 0
addi 0 0 0
addi 0 0 0
addi 0 0 0 

addi 2 2 1 add 1 to register 2, this is the trap handler
beq 0 0 -4 go back 1 instruction

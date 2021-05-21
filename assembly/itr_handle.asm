A simple interrupt/exeption handler and a trigger for the interupt
What does it do?
take a register and add 1 -> "Do something" -> enable all interrupts -> jump back to mepc?

addi 2 0 60 write the address of the itr handle to memory
csrrw 0 2 773 set itr handle
addi 0 0 0 Bunch of NOPs so an interrupt can be detected
addi 0 0 0 
addi 2 0 1 save 1 to 2
addi 1 0 252 save location of memory 
sb 1 2 0 save the number 1 to the interrupt bit and trigger itr
addi 0 0 0
addi 0 0 0
addi 0 0 0
addi 0 0 0
addi 0 0 0
addi 0 0 0
addi 0 0 0
addi 10 0 1 just a random number to see if test works


interrupt handler 
Do something to do with interrupt
addi 29 0 252 location of software interrupt
sb 29 0 0 turn off software interrupt

addi 31 0 8 create value to write that re-enables interupts (1000)
csrrs 0 31 768 save previous value to mie in mstatus enabling interrupts.

csrrc 30 0 833 read value of mepc
addi 30 30 4 increment to go to next instruction
jalr 0 30 0 Jump back to program, don't store value of jump 




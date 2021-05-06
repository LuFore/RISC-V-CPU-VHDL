move data from one address to another
	
addi 1 0 0 location to move data from/current ptr
addi 2 0 400 location to move data to			
addi 3 0 464 end of data to be moved
addi 4 0 4 iterator
	
lw 5 1 0 load data to register 
sw 2 5 0 save the loaded word
add 4 4 1 iterate
blt 1 3 -12 jump back to lw if current ptr < end of data to be moved 

	addi 0 0 0 A bunch of NOPs so the program runs long eenough
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

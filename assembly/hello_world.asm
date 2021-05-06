Save "hello world" in ascii to the memory address 200 + 

addi 1 0 104 h Load values into registers
addi 2 0 101 e Last value is the ascii for the letter
addi 3 0 108 l 
addi 4 0 111 o
addi 5 0 32  space
addi 6 0 119 w
addi 7 0 114 r
addi 8 0 100 d
addi 9 0 200 base address

sb 9 1 0
sb 9 2 4
sb 9 3 8
sb 9 3 12
sb 9 4 16
sb 9 5 20
sb 9 6 24
sb 9 4 28
sb 9 7 32	
sb 9 3 36	
sb 9 8 40 

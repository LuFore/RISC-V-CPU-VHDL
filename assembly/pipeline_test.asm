Test the pipeline with by adding 1 to the return of the previous instruction. Each instruction is seperated by a number of NOPs to search for bugs. Pass is memory address 0 counting up to 7 before displaying the value for addi 1 1 1 and addi1111 + 1
addi 1 1 1  Works (of course)
addi 2 1 1  Works 
addi 0 0 0 
addi 3 2 1  Does not work -- now works!
addi 0 0 0 
addi 0 0 0
addi 4 3 1  Does not work -- now works!
addi 0 0 0 
addi 0 0 0 
addi 0 0 0 
addi 5 4 1  Works from here on
addi 0 0 0 
addi 0 0 0 
addi 0 0 0 
addi 0 0 0
addi 6 5 1 
addi 0 0 0 
addi 0 0 0 
addi 0 0 0 
addi 0 0 0
addi 7 6 1 
sw 0 1 0 
sw 0 2 0 
sw 0 3 0 
sw 0 4 0 
sw 0 5 0 
sw 0 6 0 
sw 0 7 0 
lw 8 0 8  Load to register 8 Test bubbles?
addi 0 0 0 NOP
addi 9 8 1 Does not work --works now
lw 10 0 8  Load to register 10
addi 0 0 0 NOP
addi 0 0 0 NOP
addi 11 10 1  Does not work -- works now
lw 12 0 8  Load to register 12
addi 0 0 0 NOP
addi 0 0 0 NOP
addi 0 0 0 NOP
addi 13 12 1  Works
sw 0 8 0 
sw 0 9 0 
sw 0 11 0 
sw 0 13 0 



It now works!



Extra spaces are for so the sim has enough time. Simulation time to run is
(currently) calculated based on length of file












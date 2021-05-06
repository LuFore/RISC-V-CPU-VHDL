# RISC-V-CPU-VHDL


File structure:
	Hardware VHDL is in the directory hw 
	Test benches should have the same name as hardware, only with _tb at the end. All testbenches are found in the directory tb. Please note not all of these will work because of minor changes in the interface list 
	Packages used in both hardware and testbenches are found in packages
	Wave files of various simulations can be found in sim. They normally have the same name as the testbench, or if it is running assembly, the name of the assembly file
	
How to run a testbench:
	Use ./simulate.sh followd by the entity name. so to run the testbench for cpu_32i.vhd, use it's entity name, cpu_32i.  
	Although this project is all built, if you wish to do it yourself run build_all.sh
	
	in order to run an assembly file, edit cpi_32i testbench's variable assembly_file on line 64 to the assembly file you wish to simulate.	

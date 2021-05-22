
package memory_defs is

	constant cache_size : positive := 1024;
	
	constant software_itr_address: natural  := 252;
    	constant mtime_lower         : positive := 100; --arbitrary numbers for memory
    	constant mtime_upper         : positive := mtime_lower + 4; --mapped timer interupt regs
    	constant mtimecmp_lower      : positive := mtime_lower + 8;
    	constant mtimecmp_upper      : positive := mtime_lower + 12;

end memory_defs;


library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-- Little endian, stores all bits in the (top downto bottom) format
entity cache_pc is -- a register
  generic(
    address_width 	: positive := 8;        --size of each address in bits
    cache_size		: positive := 256;      --numbers of addresses in cache
    bus_width 		: positive := (32-1);   --size of access bus
    software_itr_address: positive := 100       
    );
  port(
    clk,rst, rw		: in std_ulogic;	-- low is write, high is read	

    dat_out		:out std_ulogic_vector(bus_width downto 0);
    dat_in		:in std_ulogic_vector(bus_width downto 0);
    -- base address of hardware
    add_in,add_pc	:in std_ulogic_vector(bus_width downto 0);
    --data for the program counter
    dat_pc		:out std_ulogic_vector(bus_width downto 0);
    --number of addresses to be read, 0 is 1 address, 1 is 2, 3 is 4 and so on
    mem_len 		:in std_ulogic_vector(1 downto 0);
    --find the maximum amount of bits to be read through the bus using
    software_itr        :out std_ulogic
    );
end cache_pc;


architecture cache_arch of cache_pc is
  subtype atomic_address is std_ulogic_vector(address_width - 1 downto 0);
  type memory_type is array (0 to cache_size-1) of atomic_address ;

  signal memory : memory_type;
  --signal mem	: std_ulogic_vector(address_width*cache_size downto 0); 
  
begin

  process(clk)
    --variables are for ease of reading
    subtype address is integer range 0 to cache_size-1; 
    
    variable mem_add : address := 0;
    variable pc_address  : address := 0; 
    
    variable dma_write_address :address :=0;
    variable dma_read_address  :address :=0;
    variable mem_length        :unsigned(1 downto 0);
    
    variable hold_value : atomic_address;
  begin
    
    if rst = '0' then --reset on low
      for i in 0 to cache_size-1 loop
        memory(i) <= (others =>'0');
      end loop;
      
      dat_pc <= (others => '0');
      dat_out <= (others => '0');
      
    elsif rising_edge(clk) then
      --set interrupt
      software_itr <= memory(software_itr_address)(0);
      
      --deal with PC
      pc_address := to_integer(unsigned(add_PC)); 
      --PC will always be 32 bit without the C extension
      dat_PC(7 downto 0)  <= memory(PC_address + 0);
      dat_PC(15 downto 8) <= memory(PC_address + 1);
      dat_PC(23 downto 16)<= memory(PC_address + 2);
      dat_PC(31 downto 24)<= memory(PC_address + 3);


      mem_add    := to_integer(unsigned(add_in));
      mem_length := (unsigned(mem_len));
      if rw = '1' then --write data
        
        memory(mem_add + 0) <= dat_in(address_width -1 downto 0);
        if mem_length >= 1 then --deal with different lengths of data
          memory(mem_add + 1) <= dat_in(address_width*2 -1 downto address_width);          
          if mem_length >= 3 then
            memory(mem_add + 2) <= dat_in(address_width*3-1 downto address_width*2);
            memory(mem_add + 3) <= dat_in(address_width*4-1 downto address_width*3);
          end if;
        end if;        

      elsif rw = '0' then -- read       

        --avoid for loop
        dat_out(address_width -1 downto 0) <= memory(mem_add);

        if mem_length >= 1 then --deal with reads of different length 
          dat_out(address_width*2 -1 downto address_width) <= memory(mem_add + 1);
          
          if mem_length >= 3 then
            dat_out(address_width*3 -1 downto address_width*2) <= memory(mem_add + 2);
            dat_out(address_width*4 -1 downto address_width*3) <= memory(mem_add + 3);
          else
            --signing
            hold_value := memory(address_width*2);
            dat_out(address_width*4-1 downto address_width*2) <= (others=> hold_value(address_width-1));
          end if;
        else
          hold_value := memory(address_width);
          dat_out(address_width*4-1 downto address_width)<=(others => hold_value(address_width -1));
        end if;
      end if;
    end if;
  end process;
end cache_arch;

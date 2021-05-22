library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.memory_defs.all;

-- Little endian, stores all bits in the (top downto bottom) format
entity cache_dma is -- a register
  generic(
    address_width : positive := 8;       --size of each address in bits
    bus_width 	  : positive := (32-1)); --size of access bus
   
  port(
    clk,rst, rw		: in std_ulogic;	-- low is write, high is read	

    dma_data_in, dma_address_out,dma_address_in : in std_ulogic_vector(bus_width downto 0);
    dma_data_out                                :out std_ulogic_vector(bus_width downto 0);
    
    dat_out		:out std_ulogic_vector(bus_width downto 0);
    dat_in		: in std_ulogic_vector(bus_width downto 0);
    -- base address of hardware
    add_in,add_pc	: in std_ulogic_vector(bus_width downto 0);
    --data for the program counter
    dat_pc		:out std_ulogic_vector(bus_width downto 0);
    --number of addresses to be read, 0 is 1 address, 1 is 2, 3 is 4 and so on
    mem_len 		: in std_ulogic_vector(1 downto 0);
    software_itr        :out std_ulogic;
    timer_itr           :out std_ulogic
    );
end cache_dma;


architecture cache_arch of cache_dma is

  subtype atomic_address is std_ulogic_vector(address_width - 1 downto 0);
  type memory_type is array (0 to cache_size-1) of atomic_address ;

  signal memory : memory_type;
  
begin

  process(clk)
    --variables are for ease of reading
    subtype address is integer range 0 to cache_size-1; 
    
    variable mem_add     : address := 0;
    variable pc_address  : address := 0; 
    
    variable dma_write_address :address :=0;
    variable dma_read_address  :address :=0;
    variable mem_length        :unsigned(1 downto 0);
    
    variable hold_value : atomic_address;
    
    procedure combine_registers(add1: in address; add2: in address; two_words :out unsigned) is
    begin

      two_words(7  downto  0):= unsigned(memory(add1 + 0));
      two_words(15 downto  8):= unsigned(memory(add1 + 1));
      two_words(23 downto 16):= unsigned(memory(add1 + 2));
      two_words(31 downto 24):= unsigned(memory(add1 + 3));

      two_words(39 downto 32):= unsigned(memory(add2 + 0));
      two_words(47 downto 40):= unsigned(memory(add2 + 1));
      two_words(55 downto 48):= unsigned(memory(add2 + 2));
      two_words(63 downto 56):= unsigned(memory(add2 + 3));      
    end combine_registers;

    
    procedure manage_timer_itr is
      --mtime will always be 64 bit, 3.2.1 of priv spec
      variable mtime_var    : unsigned(64 downto 0) := (others => '0');
      --64 downto 0 allows for overflow
      variable mtimecmp_var : unsigned(63 downto 0);
    begin

      combine_registers(mtime_lower, mtime_upper, mtime_var);
      combine_registers(mtimecmp_lower, mtimecmp_upper, mtimecmp_var);
      
      mtime_var := mtime_var+1;
      --set the incremented timer
      memory(mtime_upper+3) <= std_ulogic_vector(mtime_var(63 downto 56));
      memory(mtime_upper+2) <= std_ulogic_vector(mtime_var(55 downto 48));
      memory(mtime_upper+1) <= std_ulogic_vector(mtime_var(47 downto 40));
      memory(mtime_upper  ) <= std_ulogic_vector(mtime_var(39 downto 32));
      
      memory(mtime_lower+3) <= std_ulogic_vector(mtime_var(31 downto 24));
      memory(mtime_lower+2) <= std_ulogic_vector(mtime_var(23 downto 16));
      memory(mtime_lower+1) <= std_ulogic_vector(mtime_var(15 downto  8));
      memory(mtime_lower  ) <= std_ulogic_vector(mtime_var(7  downto  0));

      --timer interupt
      --A machine timer interrupt becomes pending whenever mtime contains
      --a value greater than or equal to mtimecmp, treating the values as
      --unsigned integers.
      if mtime_var >= mtimecmp_var then
        timer_itr <= '1';
      else
        timer_itr <= '0';
      end if;
      
    end manage_timer_itr;

  begin
    
    if rst = '0' then --reset on low
      for i in 0 to cache_size-1 loop
        memory(i) <= (others =>'0');
      end loop;
      
      --Do not timer interrupt unless set, within spec
      --As memory on reset is arbitrary
      memory(mtimecmp_upper + 3) <= (others => '1');
      
      dat_pc <= (others => '0');
      dat_out <= (others => '0');
      dma_data_out <= (others => '0');
      
      software_itr <= '0';
      timer_itr    <= '0';

      
    elsif rising_edge(clk) then
      --set interrupt
      software_itr <= memory(software_itr_address)(0);

      --manage timer interrupts, come first so later
      --writes have priority
      manage_timer_itr;

      
      --deal with PC
      pc_address := to_integer(unsigned(add_PC)); 
      --PC will always be 32 bit without the C extension
      dat_PC(7 downto 0)  <= memory(PC_address + 0);
      dat_PC(15 downto 8) <= memory(PC_address + 1);
      dat_PC(23 downto 16)<= memory(PC_address + 2);
      dat_PC(31 downto 24)<= memory(PC_address + 3);


      mem_add    := to_integer(unsigned(add_in));
      mem_length := (unsigned(mem_len));
      if rw = '1' then --write
        --much of this code would be cleaner with a for loop
        memory(mem_add + 0) <= dat_in(address_width -1 downto 0);
        if mem_length >= 1 then --deal with writes of different length
          memory(mem_add + 1) <= dat_in(address_width*2 -1 downto address_width);          
          if mem_length >= 3 then
            memory(mem_add + 2) <= dat_in(address_width*3-1 downto address_width*2);
            memory(mem_add + 3) <= dat_in(address_width*4-1 downto address_width*3);
          end if;
        end if;        

      elsif rw = '0' then -- read       

        --avoid for loop
        dat_out(address_width -1 downto 0) <= memory(mem_add);

        if mem_length >= 1 then--deal with reads of different lengths 
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


      -- DMA
      dma_write_address := to_integer(unsigned(dma_address_in));--*address_width;
      memory(dma_write_address + 0) <= dma_data_in(7 downto 0);
      memory(dma_write_address + 1) <= dma_data_in(15 downto 8);
      memory(dma_write_address + 2) <= dma_data_in(23 downto 16);
      memory(dma_write_address + 3) <= dma_data_in(31 downto 24);

      dma_read_address := to_integer(unsigned(dma_address_out));
      dma_data_out(7 downto 0)  <= memory(dma_read_address + 0);
      dma_data_out(15 downto 8) <= memory(dma_read_address + 1);
      dma_data_out(23 downto 16)<= memory(dma_read_address + 2);
      dma_data_out(31 downto 24)<= memory(dma_read_address + 3);

    end if;
  end process;  
end cache_arch;


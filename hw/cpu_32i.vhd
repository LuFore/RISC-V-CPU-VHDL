library IEEE;
use ieee.std_logic_1164.all;

entity CPU_32I is
  generic(cache_size : natural := 1024;
          bit_width  : natural := 32-1); --1kb of cache
  port(
    clk, rst_hart, rst_mem, interrupt       : in std_ulogic;
    read_address, write_address, write_data : in std_ulogic_vector(bit_width downto 0);
    read_data                               :out std_ulogic_vector(bit_width downto 0));
end CPU_32I;

architecture arch of CPU_32I is

  component hart32i is
    generic(
      bit_width           : integer := 32 -1;
      Cache_addres_width  : integer := 8;
      Cache_bus_width     : integer := 32 - 1
      );
    port(
      clk, rst       : in std_ulogic;
      PC_out         :out std_ulogic_vector(bit_width downto 0);
      PC_in          : in std_ulogic_vector(Cache_bus_width downto 0);

      memory_width   :out std_ulogic_vector(1 downto 0);
      memory_write   :out std_ulogic;
      memory_address :out std_ulogic_vector(bit_width       downto 0);
      memory_store   :out std_ulogic_vector(Cache_bus_width downto 0);
      memory_load    : in std_ulogic_vector(Cache_bus_width downto 0);
      external_itr, memory_mapped_itr, timer_itr : in std_ulogic
      );
  end component;


  component cache_dma is -- a register
    generic(
      address_width 	        : integer := 8; --size of each address in bits
      cache_size		: integer := 256;	--numbers of addresses in cache
      bus_width 		: integer := (32-1) 		--size of access bus
      );
    port(
      clk,rst, rw	: in std_ulogic;	

      dma_data_in, dma_address_out,dma_address_in   : in std_ulogic_vector(bus_width downto 0);
      dma_data_out      :out std_ulogic_vector(bus_width downto 0);
      
      dat_out		:out std_ulogic_vector(bus_width downto 0);
      dat_in		: in std_ulogic_vector(bus_width downto 0);
      add_in,add_pc	: in std_ulogic_vector(bus_width downto 0);
      dat_pc		:out std_ulogic_vector(bus_width downto 0);
      mem_len 		: in std_ulogic_vector(1 downto 0);
      software_itr      :out std_ulogic;
      timer_itr         :out std_ulogic
      );
  end component;
  
  signal rw, memory_itr, signal_timer_itr : std_ulogic;
  signal mem_length     : std_ulogic_vector(1 downto 0);
  
  signal PC_data, PC_address, write_data_int, mem_address, read_data_int
    : std_ulogic_vector(32-1 downto 0);
  

begin

  core : hart32i
    port map(clk => clk, rst => rst_hart, PC_out => PC_address, PC_in => PC_data,
             memory_width=>mem_length, memory_write => rw, memory_address => mem_address,
             memory_store => write_data_int, memory_load => read_data_int,
             external_itr => interrupt, memory_mapped_itr => memory_itr,
             timer_itr => signal_timer_itr );

  memory : cache_dma
    generic map(cache_size => cache_size)
    port map(clk => clk, rst => rst_mem, add_pc => PC_address, dat_pc => PC_data, rw => rw,
             dat_out => read_data_int, dat_in => write_data_int,  add_in => mem_address, mem_len =>
             mem_length, dma_data_in => write_data, dma_data_out => read_data,
             dma_address_in => write_address, dma_address_out => read_address,
             software_itr => memory_itr, timer_itr => signal_timer_itr);

end arch;    


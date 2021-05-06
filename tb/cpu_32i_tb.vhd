library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.all;
use work.instructions.all;
use work.helpers.all;
use work.tb_helpers.all;
use work.assemble_file.all;

use work.assembler.all;

entity tb_CPU_32I is
  generic(cache_size : natural := 1024;
          bit_width  : natural := 32-1); --1kb of cache

end tb_CPU_32I;

architecture tb of tb_CPU_32I is

  component CPU_32I
    port (clk           : in std_ulogic;
          rst_hart, rst_mem           : in std_ulogic;
          read_address  : in std_ulogic_vector (bit_width downto 0);
          write_address : in std_ulogic_vector (bit_width downto 0);
          write_data    : in std_ulogic_vector (bit_width downto 0);
          read_data     : out std_ulogic_vector(bit_width downto 0);
          interrupt     : in std_ulogic
          );
  end component;

  signal clk           : std_ulogic;
  signal rst_hart, rst_mem           : std_ulogic;
  signal read_address  : std_ulogic_vector (bit_width downto 0);
  signal write_address : std_ulogic_vector (bit_width downto 0);
  signal write_data    : std_ulogic_vector (bit_width downto 0);
  signal read_data     : std_ulogic_vector (bit_width downto 0);
  signal interrupt     : std_ulogic;
  
  constant TbPeriod : time := 1000 ns; -- 50 Mhz is 20 ns
  signal TbClock : std_logic := '0';
  signal TbSimEnded : std_logic := '0';
  signal programming: boolean := true;
  
begin

  dut : CPU_32I
    port map (clk           => clk,
              rst_hart      => rst_hart,
              rst_mem       => rst_mem,
              read_address  => read_address,
              write_address => write_address,
              write_data    => write_data,
              read_data     => read_data,
              interrupt     => interrupt);

  -- Clock generation
  TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';
  clk <= TbClock;

  stimuli : process
    variable len : natural;
    variable assembly_file : string(1 to 23) := "assembly/itr_handle.asm";
    --count the assembly file name to find it's length
    --use unix command expr length "string" to find the length
    variable times_to_run : positive := 1;
    -- number of times program should be ran (based off file length so will
    --not be accurate, should only be larger than 1 when a loop in the is present
    
    variable good : boolean := true;
    variable inst_from_file : instruction;
    variable count : natural := 0;
    
  begin
    --prepare for file reading.
    lines_in_file(assembly_file, len);

    --init
    read_address <= (others => '0');
    write_address <= (others => '0');
    write_data <= (others => '0');
    interrupt <= '0';
    -- Reset 
    rst_mem  <= '0';
    rst_hart <= '0';

    wait for 100 ns;
    wait for TbPeriod; -- make sure rst is clocked in (it is synchrnous)


    for i in 1 to len + 2 loop
      --instruction address
      write_address <= std_ulogic_vector(to_unsigned(count*4,32));
      --report integer'image(count);

      if i = 1 then
        rst_mem <= '1'; -- start
        good := false;
        
      elsif (i >= 2) and (i <= len+1) then

        get_inst_from_asm(assembly_file, i-1, inst_from_file, good);
        write_data <= inst_from_file; 

      elsif i = len + 2 then
        --replace the jump forever loop with an NOP instruction so program
        --may run
        rst_hart <= '1';
        programming <= false;

        report assembly_file & " written to memory using the new method" severity note;
       end if;


      if good = true then
        wait for TbPeriod; -- make sure bad instructions are not clocked in
        count := count+1;  --used to find current address in memory
      end if;
      
    end loop;

    for i in 1 to len * times_to_run loop
      -- let program run
      wait for TbPeriod; -- make sure bad instructions are not clocked in
    end loop;

    
    TbSimEnded <= '1';
    wait;
  end process;
end tb;

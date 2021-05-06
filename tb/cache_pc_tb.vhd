library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_cache_pc is
  generic(
    address_width 	: integer := 8; --size of each address in bits
    cache_size		: integer := 256;	--numbers of addresses in cache
    bus_width 		: integer := (32-1) 		--size of access bus
    );
end tb_cache_pc;

architecture tb of tb_cache_pc is

  component cache_pc
    port (clk     : in std_ulogic;
          rst     : in std_ulogic;
          rw      : in std_ulogic;
          dat_in  : in std_ulogic_vector (bus_width downto 0);
          dat_out : out std_ulogic_vector (bus_width downto 0);
          add_in  : in std_ulogic_vector (bus_width downto 0);
          add_pc  : in std_ulogic_vector (bus_width downto 0);
          dat_pc  : out std_ulogic_vector (bus_width downto 0);
          mem_len : in std_ulogic_vector (2-1 downto 0));
  end component;

  signal clk     : std_ulogic;
  signal rst     : std_ulogic;
  signal rw      : std_ulogic;
  signal dat_out : std_ulogic_vector (bus_width downto 0);
  signal dat_in  : std_ulogic_vector (bus_width downto 0);
  signal add_in  : std_ulogic_vector (bus_width downto 0);
  signal add_pc  : std_ulogic_vector (bus_width downto 0);
  signal dat_pc  : std_ulogic_vector (bus_width downto 0);
  signal mem_len : std_ulogic_vector (2-1 downto 0);

  constant TbPeriod : time := 1000 ns; -- EDIT Put right period here
  signal TbClock : std_logic := '0';
  signal TbSimEnded : std_logic := '0';
  
begin

  dut : cache_pc
    port map (clk     => clk,
              rst     => rst,
              rw      => rw,
              dat_in  => dat_in,
              dat_out => dat_out,
              add_in  => add_in,
              add_pc  => add_pc,
              dat_pc  => dat_pc,
              mem_len => mem_len);

  -- Clock generation
  TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';

  -- EDIT: Check that clk is really your main clock signal
  clk <= TbClock;
  
  stimuli : process
    
    variable clk_count 	: integer := 0;     
    variable clk_max 	: integer := 5;
    variable score		: integer := 0;
    variable temp_add	: integer := 0;
    variable temp_dat	: integer := 0;
    variable temp_pca	: integer := 0;
    
  begin
    -- EDIT Adapt initialization as needed
    rw <= '0';
    add_in <= (others => '0');
    add_pc <= (others => '0');
    mem_len <= (others => '0');
    dat_in <= (others => '0');
    -- Reset generation
    -- EDIT: Check that rst is really your reset signal
    rst <= '0';
    wait for 100 ns;
    rst <= '1';
    wait for 100 ns;

---------------------------------------------------------------- test 32 bit r/w
    --clock in values to fill memory
    rw <= '1';
    mem_len <= "11";
    for i in 0 to (cache_size/4 - 1) loop
      add_in <= std_ulogic_vector(to_unsigned((i*4), 32));
      dat_in <= std_ulogic_vector(to_unsigned(i,32));-- std_ulogic_vector(to_unsigned(i));
      wait for TbPeriod;
    end loop;
    
    rw <= '0'; --read all values
    for i in 0 to ((cache_size/4) - 1) loop
      add_in <= std_ulogic_vector(to_unsigned((i*4) , 32));
      if i > 0 then
        if dat_out = std_ulogic_vector(to_unsigned((i - 1),32)) then
          score := score + 1;
        end if;
      end if;
      wait for TbPeriod;
    end loop;		

    if score = ((cache_size/4) - 1) then
      report "32 bit r/w pass";
    else
      report "32 bit r/w fail";
    end if;
    score := 0;			
---------------------------------------------------------------- Test program counter
    for i in 0 to ((cache_size/4) - 1) loop
      add_PC <= std_ulogic_vector(to_unsigned((i*4) , 32));
      
      score := i - to_integer(unsigned(dat_PC)) + score; 
      
      wait for TbPeriod;
    end loop;				
    
    if score = ((cache_size/4) - 1) then
      report "PC cache pass";
    else
      report "PC cache fail";
    end if;
    score := 0;			
    
    
    
    
    for clk_count in 0 to clk_max loop
      case clk_count is 
        when 0 =>
          rw <= '0';
          temp_add := 6;
          temp_dat := 150;
          mem_len <= "00";
          
        when 1 =>
          rw <='1';
          temp_pca := 6;
        when 2 =>	
          rw <= '0';
          mem_len <= "00";
          temp_add := 9;
          temp_dat := 3000;
          
          if dat_pc(7 downto 0) = dat_out(7 downto 0) then
            report "PC data equality passed";
          else
            report "PC data equality failed";
          end if;
          if to_integer(unsigned(dat_pc(7 downto 0))) = 150 then
            report "8 bit read passed";
          else
            report "8 bit read failed";
          end if;
        when 3 =>
          rw <= '1';
        when 4 =>
          if dat_out = std_ulogic_vector(to_unsigned(3000 , 32)) then
            report "mismatched rw pass";
          else
            report "mismatched rw fail";
          end if;
          
        when others => 
          rst <= '0';
      end case;
      
      add_in <= std_ulogic_vector(to_unsigned(temp_add , 32));
      add_PC <= std_ulogic_vector(to_unsigned(temp_pca , 32));
      dat_in <= std_ulogic_vector(to_unsigned(temp_dat , 32));
      
      wait for TbPeriod;	
    end loop;
    -- Stop the clock and hence terminate the simulation
    TbSimEnded <= '1';
    wait;
  end process;

end tb;

-- Configuration block below is required by some simulators. Usually no need to edit.

configuration cfg_tb_cache_pc of tb_cache_pc is
  for tb
  end for;
end cfg_tb_cache_pc;        -- EDIT Add stimuli her

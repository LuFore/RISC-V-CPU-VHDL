library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.instructions.all;
use work.assembler.all;
use work.tb_helpers.all;



entity tb_reg_32 is
  generic(
    XLEN   : integer := (32 - 1);	  -- width of adresses and length of register = 2**bitadd
    bitadd : integer := (5 - 1) -- length of address
    );
end tb_reg_32;

architecture tb of tb_reg_32 is

  component reg_32
    port (clk    : in std_ulogic;
          rst    : in std_ulogic;
          d_in   : in std_ulogic_vector (xlen downto 0);
          d_out0 : out std_ulogic_vector (xlen downto 0);
          d_out1 : out std_ulogic_vector (xlen downto 0);
          adre0  : in std_ulogic_vector (bitadd downto 0);
          adre1  : in std_ulogic_vector (bitadd downto 0);
          adwr0  : in std_ulogic_vector (bitadd downto 0));
  end component;

  signal clk    : std_ulogic;
  signal rst    : std_ulogic;
  signal d_in   : std_ulogic_vector (xlen downto 0);
  signal d_out0 : std_ulogic_vector (xlen downto 0);
  signal d_out1 : std_ulogic_vector (xlen downto 0);
  signal adre0  : std_ulogic_vector (bitadd downto 0);
  signal adre1  : std_ulogic_vector (bitadd downto 0);
  signal adwr0  : std_ulogic_vector (bitadd downto 0);

  constant TbPeriod : time := 1000 ns; -- EDIT Put right period here
  signal TbClock : std_logic := '0';
  signal TbSimEnded : std_logic := '0';

begin

  dut : reg_32
    port map (clk    => clk,
              rst    => rst,
              d_in   => d_in,
              d_out0 => d_out0,
              d_out1 => d_out1,
              adre0  => adre0,
              adre1  => adre1,
              adwr0  => adwr0);

  -- Clock generation
  TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';

  clk <= TbClock;

  stimuli : process
    --declare variables
    variable clk_count 	: integer := 0;     
    variable clk_max 	: integer :=66;

  begin
    -- EDIT Adapt initialization as needed
    d_in <= (others => '0');
    adre0 <= (others => '0');
    adre1 <= (others => '0');
    adwr0 <= (others => '0');

    rst <= '0';
    wait for 100 ns;
    rst <= '1';
    wait for 100 ns;
    
    for clk_count in 0 to clk_max loop
      case clk_count is
        when 0 =>
          d_in <= sint2ulog32(24214); -- try and put arbitrary number into address 0
        --test_against_sint(d_out0, 0, "Overwrite position 0");
        when 1 to 32 =>
          if clk_count < 31 then -- make sure no data is written in a
                                 -- non-existant register
            adwr0<= std_ulogic_vector(to_unsigned(clk_count, 5));
            d_in <= std_ulogic_vector(to_unsigned(clk_count, 32));
          end if;

          if clk_count < 32 then --make sure all registers to be read from are
                                 --not out of bounds
            adre0 <= std_ulogic_vector(to_unsigned(clk_count-1, 5));
            adre1 <= std_ulogic_vector(to_unsigned(clk_count-1, 5));
          end if;

          if clk_count > 2 then 
            test_against_uint(d_out0, clk_count-2, "save and read output 0,register:" & integer'image(clk_count-1) );
            test_against_uint(d_out1, clk_count-2, "save and read output 1,register:" & integer'image(clk_count-1) );
          end if;

        when 33 =>
          adwr0 <= "00000"; -- make sure data is not written again
          rst <= '0'; --test the reset
        when 34 =>
          rst <= '1';
        when 35 to (35+31)=> -- this is a bit exessive, only really need to
                             -- test one or two, but it does the job.
          adre0 <= std_ulogic_vector(to_unsigned(clk_count-35, 5));
          test_against_sint(d_out0, 0 , "reset " & integer'image(clk_count-35) );
      end case;
      
      wait for TbPeriod;
    end loop;
    -- Stop the clock and hence terminate the simulation
    TbSimEnded <= '1';
    wait;
  end process;

end tb;

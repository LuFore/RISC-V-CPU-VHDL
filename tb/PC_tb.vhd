
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.helpers.all;

use work.tb_helpers.all;



entity tb_PC is
  generic(
    bitwidth : integer := (32 - 1));
end tb_PC;

architecture tb of tb_PC is

  component PC
    port (clk    : in std_ulogic;
          rst    : in std_ulogic;
          branch : in std_ulogic;
          PC_in  : in std_ulogic_vector (bitwidth downto 0);
          PC_out : out std_ulogic_vector (bitwidth downto 0));
  end component;

  signal clk    : std_ulogic;
  signal rst    : std_ulogic;
  signal branch : std_ulogic;
  signal PC_in  : std_ulogic_vector (bitwidth downto 0);
  signal PC_out : std_ulogic_vector (bitwidth downto 0);

  constant TbPeriod : time := 1000 ns; -- EDIT Put right period here
  signal TbClock : std_logic := '0';
  signal TbSimEnded : std_logic := '0';

begin

  dut : PC
    port map (clk    => clk,
              rst    => rst,
              branch => branch,
              PC_in  => PC_in,
              PC_out => PC_out);

  -- Clock generation
  TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';

  -- EDIT: Check that clk is really your main clock signal
  clk <= TbClock;

  stimuli : process
---------------------------------------------------------------------------------------------
-- DECLARE VARIABLES
    variable clk_count 	: integer := 0;     
    variable clk_max 	: integer := 100 ;
    variable temp_cnt	: integer := 0;
---------------------------------------------------------------------------------------------
  begin
    --initialization
    branch <= '0';
    PC_in <= (others => '0');

    -- Reset generation
    rst <= '0';
    wait for 100 ns;
    rst <= '1';
    wait for 100 ns;


    for clk_count in 0 to clk_max loop
      -- main loop
      case clk_count is

        when 0 to 50 => -- Count up the PC
          null;
        when 51 =>
          test_against_uint(PC_out, clk_count*4, "increment");
          --
        when 52 =>
          branch <= '1';
          PC_in <= sint2ulog32(53126);--set PC to arbitrary number
        when 53 =>
          branch <= '0';
          test_against_uint(PC_out, 53126, "Branch");
        when 54 =>
          test_against_uint(PC_out, 53126+4, "increment after branch");
        when 55 =>
          rst <= '0';
        when 56 =>
          rst <= '1';
          test_against_uint(PC_out, 0, "reset register");      
        when others =>
          null;    
      end case;

      wait for TbPeriod;
    end loop;

    -- Stop the clock and hence terminate the simulation
    TbSimEnded <= '1';
    wait;
  end process;

end tb;


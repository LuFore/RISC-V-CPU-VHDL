library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.tb_helpers.all;
use work.assembler.RISCV32I;
use work.instructions.all;


entity tb_decoder is
  generic(bus_width : integer := (32 - 1));
end tb_decoder;

architecture tb of tb_decoder is

  component decoder
    port(clk, rst               :in std_ulogic;
         inst_in                :in std_ulogic_vector (bus_width downto 0);
         rs1_add, rs2_add       :out std_ulogic_vector (5-1 downto 0);
         inst_out		:out std_ulogic_vector (bus_width downto 0));
  end component;
  
  signal clk    : std_ulogic;
  signal rst    : std_ulogic;
  signal inst_in: std_ulogic_vector (bus_width downto 0);
  signal rs1_add: std_ulogic_vector (5-1 downto 0);
  signal rs2_add: std_ulogic_vector (5-1 downto 0);
  signal inst_out:std_ulogic_vector (bus_width downto 0);

  
  constant TbPeriod : time := 1000 ns; -- EDIT Put right period here
  signal TbClock : std_logic := '0';
  signal TbSimEnded : std_logic := '0';

begin

  dut : decoder
    port map (clk     => clk,
              rst     => rst,
              rs1_add => rs1_add,
              rs2_add => rs2_add,
              inst_in => inst_in,
              inst_out=> inst_out
              );

  -- Clock generation
  TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';

  -- EDIT: Check that clk is really your main clock signal
  clk <= TbClock;

  stimuli : process
-------------------------------------------------------------------------------
-- DECLARE VARIABLES
    variable clk_count 	: integer := 0;     
    variable clk_max 	: integer := 4;
    variable temp_cnt	: integer := 0;
-------------------------------------------------------------------------------
  begin
    --rst <= '1';
    inst_in <= (others => '0');
    
    -- Reset generation
    rst <= '0';
    wait for 100 ns;
    rst <= '1';
    wait for 100 ns;

    for clk_count in 0 to clk_max loop
      case clk_count is
        when 0 =>
          --inst_in <= "00000000000100001101000001100011";
          test_against_sint(rs1_add, 0, "reset");
          inst_in <= RISCV32I(iADD, 4, 6, 2,0);--rs1=4,rs2=6,rd=2
        when 1 =>
          --test change
          inst_in <= RISCV32I(iSUB, 30, 31, 1,0);

          --tests
          test_against_uint(rs1_add, 4, "rs1 address");
          test_against_uint(rs2_add, 6, "rs2 address");

        when 2 =>
          inst_in <= RISCV32I(iJAL, 0, 0, 0,0);

          --tets
          test_against_uint(rs1_add, 30, "rs1 change");
          test_against_uint(rs2_add, 31, "rs2 change");
          test(inst_out, RISCV32I(iADD, 4, 6, 2,0), "inst buffer");
        when 3 =>
          test(inst_out, RISCV32I(iSUB, 30, 31, 1,0), "change inst buffer");          
        when others =>
          null;
      end case;

      wait for tbperiod;
    end loop;

    --terminate the simulation
    TbSimEnded <= '1';
    wait;
  end process;

end tb;


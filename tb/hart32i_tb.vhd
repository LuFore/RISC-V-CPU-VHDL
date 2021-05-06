library ieee;
use ieee.std_logic_1164.all;

library work;
use work.all;

use work.instructions.all;
use work.assembler.all;
use work.tb_helpers.all;

entity tb_hart32i is
  generic(
    bit_width           : integer := 32 -1;
    Cache_addres_width  : integer := 8;
    Cache_bus_width     : integer := 32 - 1
    );
end tb_hart32i;

architecture tb of tb_hart32i is

    component hart32i
        port (clk            : in std_ulogic;
              rst            : in std_ulogic;
              PC_out         : out std_ulogic_vector (bit_width downto 0);
              PC_in          : in std_ulogic_vector (cache_bus_width downto 0);
              memory_width   : out std_ulogic_vector (1 downto 0);
              memory_write   : out std_ulogic;
              memory_address : out std_ulogic_vector (bit_width       downto 0);
              memory_store   : out std_ulogic_vector (cache_bus_width downto 0);
              memory_load    : in std_ulogic_vector (cache_bus_width downto 0));
    end component;

    signal clk            : std_ulogic;
    signal rst            : std_ulogic;
    signal PC_out         : std_ulogic_vector (bit_width downto 0);
    signal PC_in          : std_ulogic_vector (cache_bus_width downto 0);
    signal memory_width   : std_ulogic_vector (1 downto 0);
    signal memory_write   : std_ulogic;
    signal memory_address : std_ulogic_vector (bit_width       downto 0);
    signal memory_store   : std_ulogic_vector (cache_bus_width downto 0);
    signal memory_load    : std_ulogic_vector (cache_bus_width downto 0);

    constant TbPeriod : time := 1000 ns; -- EDIT Put right period here
    signal TbClock : std_logic := '0';
    signal TbSimEnded : std_logic := '0';

begin

    dut : hart32i
    port map (clk            => clk,
              rst            => rst,
              PC_out         => PC_out,
              PC_in          => PC_in,
              memory_width   => memory_width,
              memory_write   => memory_write,
              memory_address => memory_address,
              memory_store   => memory_store,
              memory_load    => memory_load);

    -- Clock generation
    TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';

    -- EDIT: Check that clk is really your main clock signal
    clk <= TbClock;

    stimuli : process
    begin
        -- EDIT Adapt initialization as needed
        PC_in <= (others => '0');
        memory_load <= (others => '0');

        -- Reset generation
        rst <= '0';
        wait for 1100 ns;
        rst <= '1';
        wait for 100 ns;

        for i in 1 to 12 loop
          case i is
            when 1  =>
              PC_in <= assembler.RISCV32I(iADDI,0,0,1,5);
            when 2 =>
              --save position
              PC_in <= assembler.RISCV32I(iADDI,0,0,2,1);
            when 5 =>
              PC_in <= assembler.RISCV32I(iSH,0,1,0,0);
              --return the value to memory
--            when 6 =>
--              PC_in <= assembler.RISCV32I(iADD, 1,5,0,3);
--            when 7 =>
--              PC_in <= assembler.RISCV32I(iADD, 3,0,0,4);
            when 8 =>
              PC_in <= assembler.RISCV32I(IADDI,0,0,0,0); --NOP instruction

              --PC_in <= (others => '0');
              test_against_uint(memory_store, 5, "save 5");
            when others =>
              PC_in <= assembler.RISCV32I(IADDI,0,0,0,0); --NOP instruction
          end case;
          
          wait for  TbPeriod;
        end loop;

        TbSimEnded <= '1';
        wait;
    end process;

end tb;

library ieee;
use ieee.std_logic_1164.all;

library work;
use work.all;
use work.instructions.all;
use work.assembler.all;
use work.tb_helpers.all;

entity tb_mem_access_rx is
    generic(
    address_width : integer := 8; --size of each address in bits
    bit_width : integer := (32 - 1);
    bus_width: integer := (32 -1) 
    );
end tb_mem_access_rx;

architecture tb of tb_mem_access_rx is

    component mem_access_rx
        port (clk      : in std_ulogic;
              rst      : in std_ulogic;
              acc_me   : out std_ulogic;
              inst_in  : in instruction;
              inst_out : out instruction;
              data_in  : in std_ulogic_vector (bus_width downto 0);
              data_out : out std_ulogic_vector (bit_width downto 0));
    end component;

    signal clk      : std_ulogic;
    signal rst      : std_ulogic;
    signal acc_me   : std_ulogic;
    signal inst_in  : instruction;
    signal inst_out : instruction;
    signal data_in  : std_ulogic_vector (bus_width downto 0);
    signal data_out : std_ulogic_vector (bit_width downto 0);

    constant TbPeriod : time := 1000 ns; -- EDIT Put right period here
    signal TbClock : std_logic := '0';
    signal TbSimEnded : std_logic := '0';

begin

    dut : mem_access_rx
    port map (clk      => clk,
              rst      => rst,
              acc_me   => acc_me,
              inst_in  => inst_in,
              inst_out => inst_out,
              data_in  => data_in,
              data_out => data_out);

    -- Clock generation
    TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';
    clk <= TbClock;

    stimuli : process
    begin
        -- EDIT Adapt initialization as needed
        inst_in <= (others => '0');
        data_in <= (others => '0');

        -- Reset generation
        rst <= '0';
        wait for 100 ns;
        rst <= '1';
        wait for 100 ns;

        for i in 0 to 6 loop
          case i is
            when 0 =>
              data_in <= X"000000FF"; -- -1
              inst_in <= RISCV32I(iLB, 0,0,0,0); -- imm does not matter as it recieve
            when 1 =>
              test_against_sint(data_out, -1, "iLB negative sign extend");
              test(inst_out, RISCV32I(iLB,0,0,0,0), "inst pass through");

              data_in <= sint2ulog32(4200);
              inst_in <= RISCV32I(iLH, 4, 5,29, 30);
            when 2 =>
              test_against_sint(data_out, 4200, "iLH positive sign extend");
              test_1(acc_me, '1', "Acc select");
              
              data_in <= X"FFFFFFFF";
              inst_in <= RISCV32I(iLW, 0,0,0,0);
            when 3=>
              test(data_out, X"FFFFFFFF", "iLW max");

              inst_in <= RISCV32I(iLBU, 0,0,0,0);
            when 4 =>
              test(data_out, X"000000FF", "iLBU ignore sign");

              inst_in <= RISCV32I(iLHU, 0,0,0,0);
              data_in <= X"00003FFF";
            when 5 =>
              test(data_out, X"00003FFF", "iLHU keep sign");
              test(inst_out, RISCV32I(iLHU, 0,0,0,0), "inst pass through 2");
              
              inst_in <= RISCV32I(iSB, 0,0,0,0);
              data_in <= sint2ulog32(2421); -- just a random number
            when 6 =>
              test(inst_out, RISCV32I(iSB, 0,0,0,0), "inst pass non-store");
              test_1(acc_me, '0', "acc unselect");
          end case;
          wait for TbPeriod;

        end loop;
        --  terminate the simulation
        TbSimEnded <= '1';
        wait;
    end process;

end tb;

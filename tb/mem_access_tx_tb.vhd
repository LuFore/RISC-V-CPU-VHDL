library ieee;
use ieee.std_logic_1164.all;
use work.instructions.all;
use work.helpers.all;
use work.tb_helpers.all;
use work.assembler.all;


entity tb_mem_access_tx is
    generic(
    address_width : integer := 8; --size of each address in bits
    bit_width : integer := (32 - 1);
    bus_width: integer := 32 - 1
    );
end tb_mem_access_tx;


architecture tb of tb_mem_access_tx is

    component mem_access_tx
        port (clk         : in std_ulogic;
              rst         : in std_ulogic;
              inst_in     : in instruction;
              inst_out    : out instruction;
              rs1_in      : in std_ulogic_vector (bit_width downto 0);
              rs2_in      : in std_ulogic_vector (bit_width downto 0);
              rw          : out std_ulogic;
              data_store  : out std_ulogic_vector (bus_width downto 0);
              address_out : out std_ulogic_vector (bit_width downto 0);
              mem_len     : out std_ulogic_vector (1  downto 0));
    end component;

    signal clk         : std_ulogic;
    signal rst         : std_ulogic;
    signal inst_in     : instruction;
    signal inst_out    : instruction;
    signal rs1_in      : std_ulogic_vector (bit_width downto 0);
    signal rs2_in      : std_ulogic_vector (bit_width downto 0);
    signal rw          : std_ulogic;
    signal data_store  : std_ulogic_vector (bus_width downto 0);
    signal address_out : std_ulogic_vector (bit_width downto 0);
    signal mem_len     : std_ulogic_vector (1 downto 0);

    constant TbPeriod : time := 1000 ns; -- EDIT Put right period here
    signal TbClock : std_logic := '0';
    signal TbSimEnded : std_logic := '0';

begin

    dut : mem_access_tx
    port map (clk         => clk,
              rst         => rst,
              inst_in     => inst_in,
              inst_out    => inst_out,
              rs1_in      => rs1_in,
              rs2_in      => rs2_in,
              rw          => rw,
              data_store  => data_store,
              address_out => address_out,
              mem_len     => mem_len);

    -- Clock generation
    TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';
    clk <= TbClock;

    stimuli : process
    begin
        --initialization 
        inst_in <= (others => '0');
        rs1_in <= (others => '0');
        rs2_in <= (others => '0');

        -- Reset generation
        rst <= '0';
        wait for 100 ns;
        rst <= '1';
        wait for 100 ns;

        for i in 0 to 8 loop
          case i is
            when 0 =>
              inst_in <= RISCV32I(iLB,0,0,0,43);
              
            when 1 =>
              test(inst_out, RISCV32I(iLB,0,0,0,43), "inst passthrough");
              test_against_uint(address_out, 43, "Address add naturals, load");
              test_against_uint(mem_len, 0, "LB memory length test");
              test_1(rw, '0', "set read");
              
              inst_in <= RISCV32I(iLH, 0 ,0, 0, 1); 
              rs1_in <= X"80000000";
            when 2 =>
              test(address_out, X"80000001" , "Add two positives, load");
              test_against_uint(mem_len, 1, "LH memory length test");

              inst_in <= RISCV32I(iLW, 0 ,0, 0, -2);
              rs1_in <= sint2ulog32(100);
            when 3 =>
              test_against_uint(address_out, 98, "Positive and negative, load");
              test_against_uint(mem_len, 3, "LW memory length test");

              inst_in <= RISCV32I(iSB,0 ,0, 0,4);
              rs2_in <= sint2ulog32(78693); -- random number
            when 4 =>
              test_against_uint(address_out, 104 , "Add two positives, store");
              test_against_uint(data_store, 78693 , "store data");
              test_against_uint(mem_len, 0, "SB memory length test");
              test_1(rw, '1', "set write");
              
              inst_in <= RISCV32I(iSH, 0 ,0, 0, -2);
            when 5 =>
              test_against_uint(address_out, 98, "Positive and negative, store");
              test_against_uint(mem_len, 1, "SH memory length test");

              inst_in <= RISCV32I(iSW, 0,0,0,0);
            when 6 =>
              test_against_uint(address_out, 100, "add two naturals, store");
              test_against_uint(mem_len, 3, "SW memory length test");

              inst_in <= RISCV32I(iJAL, 5,5 ,5 ,5);
            when 7 =>
              test(inst_out, RISCV32I(iJAL, 5,5 ,5 ,5), "pass unused instruction");
              test_1(rw, '0', "set read for unrelated op");
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

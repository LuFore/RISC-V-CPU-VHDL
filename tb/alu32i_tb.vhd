library ieee;
use ieee.std_logic_1164.all;
use work.tb_helpers.all;
use work.instructions.all;

entity tb_alu32i is
    generic(
    bit_width           : integer := 32 -1;
    Cache_addres_width  : integer := 8;
    Cache_bus_width     : integer := 32 - 1
    );

end tb_alu32i;

architecture tb of tb_alu32i is

    component alu32i
        port (clk            : in std_ulogic;
              rst            : in std_ulogic;
              inst_enum_in   : in instruction32i;
              inst_in        : in instruction;
              inst_out       : out instruction;
              rs1            : in std_ulogic_vector (bit_width downto 0);
              rs2            : in std_ulogic_vector (bit_width downto 0);
              data_out       : out std_ulogic_vector (bit_width downto 0);
              data_select    : out std_ulogic;
              jump           : out std_ulogic;
              PC_out         : out std_ulogic_vector (bit_width downto 0);
              PC_in          : in std_ulogic_vector (bit_width downto 0);
              rw_memory      : out std_ulogic;
              memory_size    : out std_ulogic_vector (1 downto 0);
              data_memory    : out std_ulogic_vector (cache_bus_width downto 0);
              address_memory : out std_ulogic_vector (bit_width downto 0));
    end component;

    signal clk            : std_ulogic;
    signal rst            : std_ulogic;
    signal inst_enum_in   : instruction32i;
    signal inst_in        : instruction;
    signal inst_out       : instruction;
    signal rs1            : std_ulogic_vector (bit_width downto 0);
    signal rs2            : std_ulogic_vector (bit_width downto 0);
    signal data_out       : std_ulogic_vector (bit_width downto 0);
    signal data_select    : std_ulogic;
    signal jump           : std_ulogic;
    signal PC_out         : std_ulogic_vector (bit_width downto 0);
    signal PC_in          : std_ulogic_vector (bit_width downto 0);
    signal rw_memory      : std_ulogic;
    signal memory_size    : std_ulogic_vector (1 downto 0);
    signal data_memory    : std_ulogic_vector (cache_bus_width downto 0);
    signal address_memory : std_ulogic_vector (bit_width downto 0);

    constant TbPeriod : time := 1000 ns; -- EDIT Put right period here
    signal TbClock : std_logic := '0';
    signal TbSimEnded : std_logic := '0';

begin

    dut : alu32i
    port map (clk            => clk,
              rst            => rst,
              inst_enum_in   => inst_enum_in,
              inst_in        => inst_in,
              inst_out       => inst_out,
              rs1            => rs1,
              rs2            => rs2,
              data_out       => data_out,
              data_select    => data_select,
              jump           => jump,
              PC_out         => PC_out,
              PC_in          => PC_in,
              rw_memory      => rw_memory,
              memory_size    => memory_size,
              data_memory    => data_memory,
              address_memory => address_memory);

    -- Clock generation
    TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';

    -- EDIT: Check that clk is really your main clock signal
    clk <= TbClock;

    stimuli : process
    begin
        -- EDIT Adapt initialization as needed
        inst_enum_in <= i_not_found;
        inst_in <=(others => '0');
        rs1 <= (others => '0');
        rs2 <= (others => '0');
        PC_in <= (others => '0');

        -- Reset generation
        -- EDIT: Check that rst is really your reset signal
        rst <= '0';
        wait for 100 ns;
        rst <= '1';
        wait for 100 ns;
        for i in 0 to 10 loop
          wait for  TbPeriod;
        end loop;
        -- Stop the clock and hence terminate the simulation
        TbSimEnded <= '1';
        wait;
    end process;

end tb;

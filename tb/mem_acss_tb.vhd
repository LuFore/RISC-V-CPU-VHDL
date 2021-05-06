-- Testbench automatically generated online
-- at https://vhdl.lapinoo.net
-- Generation date : 18.8.2020 14:53:46 UTC

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work; 
use work.tb_helpers.all;

entity tb_mem_acss is
  generic(
    address_width 	: integer := 8; --size of each address in bits
    bitwidth 		: integer := (32-1) 		--size of access bus
    );
end tb_mem_acss;

architecture tb of tb_mem_acss is

  component mem_acss
    port (clk        : in std_ulogic;
          rst        : in std_ulogic;
          rw         : out std_ulogic;
          acc_toggle : out std_ulogic;
          inst_in    : in std_ulogic_vector (bitwidth downto 0);
          rs1_in     : in std_ulogic_vector (bitwidth downto 0);
          rs2_in    : in std_ulogic_vector (bitwidth downto 0);
          mem_len    : out std_ulogic_vector (2-1 downto 0);
          cache_rx   : in std_ulogic_vector (bitwidth downto 0);
          cache_tx   : out std_ulogic_vector (bitwidth downto 0);
          cache_ad   : out std_ulogic_vector (bitwidth downto 0);
          reg_out    : out std_ulogic_vector (bitwidth downto 0));
  end component;

  signal clk        : std_ulogic;
  signal rst        : std_ulogic;
  signal rw         : std_ulogic;
  signal acc_toggle : std_ulogic;
  signal inst_in    : std_ulogic_vector (bitwidth downto 0);
  signal rs1_in     : std_ulogic_vector (bitwidth downto 0);
  signal rs2_in    : std_ulogic_vector (bitwidth downto 0);
  signal mem_len    : std_ulogic_vector (2-1 downto 0);
  signal cache_rx   : std_ulogic_vector (bitwidth downto 0);
  signal cache_tx   : std_ulogic_vector (bitwidth downto 0);
  signal cache_ad   : std_ulogic_vector (bitwidth downto 0);
  signal reg_out    : std_ulogic_vector (bitwidth downto 0);

  constant TbPeriod : time := 1000 ns; -- EDIT Put right period here
  signal TbClock : std_logic := '0';
  signal TbSimEnded : std_logic := '0';

begin

  dut : mem_acss
    port map (clk        => clk,
              rst        => rst,
              rw         => rw,
              acc_toggle => acc_toggle,
              inst_in    => inst_in,
              rs1_in     => rs1_in,
              rs2_in    => rs2_in,
              mem_len    => mem_len,
              cache_rx   => cache_rx,
              cache_tx   => cache_tx,
              cache_ad   => cache_ad,
              reg_out    => reg_out);

  -- Clock generation
  TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';

  -- EDIT: Check that clk is really your main clock signal
  clk <= TbClock;

  stimuli : process
    variable clk_count 	: integer := 0;     
    variable clk_max 	: integer := 7;
    variable zeros		: std_ulogic_vector(bitwidth downto 0) := (others => '0'); --used for padding
  begin
    -- EDIT Adapt initialization as needed
    inst_in <= (others => '0');
    rs1_in <= (others => '0');
    rs2_in <= (others => '0');
    cache_rx <= (others => '0');

    -- Reset 
    rst <= '0';
    wait for 100 ns;
    rst <= '1';
    wait for 100 ns;

    for clk_count in 0 to clk_max loop
      case clk_count is 
        when 0 =>
					--load opcode iLW with rs1 = 14, rd = 20, imm = 42
          inst_in <= "00000010101001110010101000000011"; -- test the load opcode
        when 1 =>
					--store opcide iSB with all values set to 0 but imm set to maximum
          inst_in <= "11111110000000000000111110100011";
          
          cache_rx <= int2ulogic32(500);
          rs2_in <= int2ulogic32(324);
          
          test_32(cache_ad, int2ulogic32(42), "LOAD address");
        when 2 =>
					--iLBU rs1 = 2, rd = 2, imm = -1
          inst_in <= "11111111111100010100000100000011";
          rs1_in <= int2ulogic32(2);
          test_1(acc_toggle, '1', "Load acc toggle");
          test_32(reg_out, cache_rx, "Load unsigned word");
          
          test_32( zeros(bitwidth downto 2) & mem_len, zeros(bitwidth downto 2) & "00", "Store byte");
          test_32(cache_tx, int2ulogic32(324), "cache memory store");
        when 3 =>
					--iLH load 
          inst_in <="00000000000000000001000000000011";
          cache_rx <= X"FF28F3FF";  -- fill the top 3 bytes with nonsense to check signed function  
          test_32(cache_ad, int2ulogic32(1), "LOAD address subtract");					
        when 4 =>
          cache_rx <= X"F3FFFFFF";
					--iSH
          inst_in <= "00000000000100001001000010100011";
          
          test_32(reg_out, X"000000FF", "Load unsigned byte");
        when 5 =>
					--iSW
          inst_in <="00000000000000000010000000100011";
          
          test_32( zeros(bitwidth downto 2) & mem_len, zeros(bitwidth downto 2) & "01", "Store half word");
          test_32(reg_out, X"FFFFFFFF", "Load signed half word");	
        when 6 =>
          test_32( zeros(bitwidth downto 2) & mem_len, zeros(bitwidth downto 2) & "11", "Store word");
        when others =>
          null;--?
      end case;
      wait for TbPeriod;
    end loop;
    
    -- Stop the clock and hence terminate the simulation
    TbSimEnded <= '1';
    wait;
  end process;

end tb;


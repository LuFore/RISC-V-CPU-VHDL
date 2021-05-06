library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work; 
use work.tb_helpers.all;
use work.assembler.all;

-- This whole testbench is a bit of a mess, written before I used the newer
-- test functions & VHDL assembler, but it still works :) although hard to read 
-- indentation is OK but a little messed up with the comments, this was first
-- written in gedit

entity tb_Branch_control is
  generic(bitwidth : integer := (32-1) 		--size of access bus
          );
end tb_Branch_control;

architecture tb of tb_Branch_control is

  component Branch_control
    port (clk        : in std_ulogic;
          rst        : in std_ulogic;
          branch     : out std_ulogic;
          misaligned : out std_ulogic;
          inst_in    : in std_ulogic_vector (bitwidth downto 0);
          rs1_in     : in std_ulogic_vector (bitwidth downto 0);
          rs2_in     : in std_ulogic_vector (bitwidth downto 0);
          acc_out    : out std_ulogic_vector (bitwidth downto 0);
          PC_in      : in std_ulogic_vector (bitwidth downto 0);
          PC_out     : out std_ulogic_vector (bitwidth downto 0);
          acc_me     : out std_ulogic);
  end component;

  signal clk        : std_ulogic;
  signal rst        : std_ulogic;
  signal branch     : std_ulogic;
  signal misaligned : std_ulogic;
  signal inst_in    : std_ulogic_vector (bitwidth downto 0);
  signal rs1_in     : std_ulogic_vector (bitwidth downto 0);
  signal rs2_in     : std_ulogic_vector (bitwidth downto 0);
  signal acc_out    : std_ulogic_vector (bitwidth downto 0);
  signal PC_in      : std_ulogic_vector (bitwidth downto 0);
  signal PC_out     : std_ulogic_vector (bitwidth downto 0);
  signal acc_me     : std_ulogic;

  constant TbPeriod : time := 1000 ns; -- EDIT Put right period here
  signal TbClock : std_logic := '0';
  signal TbSimEnded : std_logic := '0';

begin

  dut : Branch_control
    port map (clk        => clk,
              rst        => rst,
              branch     => branch,
              misaligned => misaligned,
              inst_in    => inst_in,
              rs1_in     => rs1_in,
              rs2_in     => rs2_in,
              acc_out    => acc_out,
              PC_in      => PC_in,
              PC_out     => PC_out,
              acc_me     => acc_me);

  -- Clock generation
  TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';

  -- EDIT: Check that clk is really your main clock signal
  clk <= TbClock;

  stimuli : process
    variable clk_count 	: integer := 0;     
    variable clk_max 	: integer := 16;
    variable zeros		: std_ulogic_vector(bitwidth downto 0) := (others => '0'); --used for padding
  begin
    -- EDIT Adapt initialization as needed
    inst_in <= (others => '0');
    rs1_in <= (others => '0');
    rs2_in <= (others => '0');
    PC_in <= (others => '0');

    -- Reset generation
    -- EDIT: Check that rst is really your reset signal
    rst <= '0';
    wait for 100 ns;
    rst <= '1';
    wait for 100 ns;
    
    for clk_count in 0 to clk_max loop
      case clk_count is 
        when 0 =>
					-- JAL test
          inst_in <= "00000001011000000000001001101111"; --rs1: 2 , rs2: 3, rd 4 , 22 imm
                                                         --no command test
          test_1( branch, '0', "Branch flag off");
        when 1 =>
					--JAL negtaive test
          inst_in <= "11111111111111111111000001101111"; -- rs1: 0 , rs2: 0, rd 0 , (- 2) imm
          pc_in <= int2ulogic32(20);
          
					--JAL test
          test_32(pc_out, int2ulogic32(22), "JAL unsigned");
          test_1(branch, '1', "Branch flag on");		
        when 2 =>
					--JALR
          inst_in <= "00000001011100011000001011100111";-- rs1: 3 , rs2: 4, rd 5 , 23 imm
          rs1_in <= int2ulogic32(4);
					-- JAL signed test
          test_32(pc_out, int2ulogic32(18), "JAL signed");
        when 3 =>
					--BEQ fail
          inst_in <= "00000001100000000000001101100011";-- rs1: 4 , rs2: 5, rd 6 , 24 imm
          rs1_in <= int2ulogic32(5);
          rs2_in <= int2ulogic32(525);
					--JALR test
          test_32(pc_out ,int2ulogic32(27), "JALR RS1");
          test_1(acc_me, '1', "JALR write flag");
          test_32(acc_out, int2ulogic32(24), "JALR write val");
        when 4 =>
					--BEQ PASS
          rs1_in <= int2ulogic32(14);
          rs2_in <= int2ulogic32(14);
					--BEQ fail
          test_1(branch, '0', "BEQ fail");
					-- add a test on PC_out
        when 5 =>
					--BNE
          inst_in <="00000000000000000001000001100011";-- rs1: 5 , rs2: 6, rd 7 , 25 imm
                                                       --BEQ pass
          test_1(branch, '1', "BEQ branch");
					-- add a test on PC_out

        when 6 =>
					--BNE pass test 
          rs1_in <= int2ulogic32(1004);
          
					--BNE fail test
          test_1(branch, '0', "BNE nothing");
          

        when 7 =>
					--BLT fail
          inst_in <="00000000000000000100000001100011";-- rs1: 6 , rs2: 7, rd 8 , 26 imm
          rs2_in <= sint2ulog32(-44);
          
					-- BNE pass
          test_1(branch, '1', "BNE branch");
        when 8 =>
					--BLT pass
          rs1_in<= sint2ulog32(-50);
					--BLT fail
          test_1(branch, '0', "BLT fail");
          
        when 9 =>
					--BGE fail
          inst_in <="00000000000000000101000001100011";-- rs1: 7 , rs2: 8, rd 9 , 27 imm
          
					-- BLT pass
          test_1(branch, '1', "BLT branch");
        when 10 =>
					--BGE pass
          rs1_in<= sint2ulog32(55);
					--BGE fail
          test_1(branch, '0', "BGE nothing");	
          
        when 11 =>
					--BLTU fail
          inst_in <="00000000000000000110000001100011";
          rs1_in<= int2ulogic32(50);
          rs2_in <= int2ulogic32(50);
          
					-- BGE pass
          test_1(branch, '1', "BGE branch");
        when 12 =>
					--BLTU pass
          rs1_in<= int2ulogic32(2);
          rs2_in <= int2ulogic32(40000);
					--BLTU fail
          test_1(branch, '0', "BLTU nothing");
        when 13 =>
					--BGEU fail
          inst_in <="00000000000000000111000001100011";		
					--BLTU pass
          test_1(branch, '1', "BLTU branch");					
        when 14 =>
					--BGEU pass
          rs1_in<= sint2ulog32(1000);
          rs2_in <= sint2ulog32(10);
					--BGEU fail
          test_1(branch, '0', "BGEU nothing");
        when 15 =>
          test_1(branch, '1', "BGEU branch");
          
          rs1_in <= sint2ulog32(200);
          RISCV32I(iJALR, 0, 0, 0,-35);
        when 16 =>
          test_against_uint(PC_out, 165, "JALR return minus");
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

-- Configuration block below is required by some simulators. Usually no need to edit.

configuration cfg_tb_Branch_control of tb_Branch_control is
  for tb
  end for;
end cfg_tb_Branch_control;


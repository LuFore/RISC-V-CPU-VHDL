library ieee;
use ieee.std_logic_1164.all;

use work.all;

use work.instructions.all;
use work.assembler.all;
use work.tb_helpers.all;

entity tb_pipeline_control is
  generic(XLEN : integer := 32-1);
end tb_pipeline_control;

architecture tb of tb_pipeline_control is

  component pipeline_control
    port (clk            : in std_ulogic;
          rst            : in std_ulogic;
          bubble         : out std_ulogic;
          rs1_in         : in std_ulogic_vector (xlen downto 0);
          rs2_in         : in std_ulogic_vector (xlen downto 0);
          result_in      : in std_ulogic_vector (xlen downto 0);
          load_in        : in std_ulogic_vector (xlen downto 0);
          rs1_out        : out std_ulogic_vector (xlen downto 0);
          rs2_out        : out std_ulogic_vector (xlen downto 0);
          inst_in        : in instruction;
          inst_enum_in   : in instruction32i;
          next_inst      : in instruction;
          next_inst_enum : in instruction32i);
  end component;

  signal clk            : std_ulogic;
  signal rst            : std_ulogic;
  signal bubble         : std_ulogic;
  signal rs1_in         : std_ulogic_vector (xlen downto 0);
  signal rs2_in         : std_ulogic_vector (xlen downto 0);
  signal result_in      : std_ulogic_vector (xlen downto 0);
  signal load_in        : std_ulogic_vector (xlen downto 0);
  signal rs1_out        : std_ulogic_vector (xlen downto 0);
  signal rs2_out        : std_ulogic_vector (xlen downto 0);
  signal inst_in        : instruction;
  signal inst_enum_in   : instruction32i;
  signal next_inst      : instruction;
  signal next_inst_enum : instruction32i;

  constant TbPeriod : time := 1000 ns; -- EDIT Put right period here
  signal TbClock : std_logic := '0';
  signal TbSimEnded : std_logic := '0';

begin

  dut : pipeline_control
    port map (clk            => clk,
              rst            => rst,
              bubble         => bubble,
              rs1_in         => rs1_in,
              rs2_in         => rs2_in,
              result_in      => result_in,
              load_in        => load_in,
              rs1_out        => rs1_out,
              rs2_out        => rs2_out,
              inst_in        => inst_in,
              inst_enum_in   => inst_enum_in,
              next_inst      => next_inst,
              next_inst_enum => next_inst_enum);

  -- Clock generation
  TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';
  clk <= TbClock;

  stimuli : process
  begin
    rs1_in <= (others => '0');
    rs2_in <= (others => '0');
    result_in <= (others => '0');
    load_in <= (others => '0');
    inst_in <= (others => '0');
    inst_enum_in <= i_not_found;
    next_inst <= (others => '0');
    next_inst_enum <= i_not_found;

    -- Reset generation
    rst <= '0';
    wait for 100 ns;
    rst <= '1';
    wait for 100 ns;
    --init other values with arbitrary value to distinguish from eachother
    rs2_in    <= sint2ulog32(1);
    result_in <= sint2ulog32(10);
    load_in <= sint2ulog32(100);
    
    
    for i in 0 to 13 loop
      case i is
        when 0 =>
          inst_enum_in   <= iLB;
          inst_in        <= assembler.RISCV32I(iLB, 0,0,20,0);
          next_inst_enum <= iADD;
          next_inst      <= assembler.RISCV32I(iADD, 20,0,1,0);
        when 1 =>
          test_1(bubble, '1', "bubble LB");
          test_against_sint(rs1_out,100,"bubble divert RS1");
          test_against_sint(rs2_out,1,"bubble no divert RS2");

          
          inst_enum_in   <= iLH;
          inst_in        <= assembler.RISCV32I(iLH, 0,0,19,0);
          next_inst_enum <= iBGEU;
          next_inst      <= assembler.RISCV32I(iBGEU, 0,19,1,0);
        when 2=>
          test_1(bubble, '1', "bubble LH");
          test_against_sint(rs2_out,100,"bubble divert RS2");

          
          inst_enum_in   <= iADD;
          inst_in        <= assembler.RISCV32I(iADD, 1,2,3,0);
          next_inst_enum <= iJALR;
          next_inst      <= assembler.RISCV32I(iJALR, 3,1,1,0);
        when 3 =>
          test_against_sint(rs1_out,10,"bypass RS1");


          inst_enum_in   <= iLUI;
          inst_in        <= assembler.RISCV32I(iLUI, 0,0,22,0);
          next_inst_enum <= iSH;
          next_inst      <= assembler.RISCV32I(iSH, 0,22,0,0);
        when 4 =>
          test_against_sint(rs2_out,10,"bypass RS2");

          inst_enum_in   <= iLH;
          inst_in        <= assembler.RISCV32I(iLH, 0,0,19,0);
          next_inst_enum <= iBGEU;
          next_inst      <= assembler.RISCV32I(iBGEU, 3,13,1,0);
        when 5=>
          test_1(bubble, '0', "do not bubble on rd /= rs1/2");
          test_against_sint(rs1_out,0,"no divert RS1, bubble");
          test_against_sint(rs2_out,1,"no divert RS2, bubble");


          inst_enum_in   <= iLW;
          inst_in        <= assembler.RISCV32I(iLW, 0,0,19,0);
          next_inst_enum <= iAND;
          next_inst      <= assembler.RISCV32I(iAND, 19,19,19,0);
        when 6=>
          test_1(bubble, '1', "bubble on both");
          test_against_sint(rs1_out,100,"bubble divert rs1 & rs2");
          test_against_sint(rs2_out,100,"bubble divert rs2 & rs1");


          inst_enum_in   <= iADD;
          inst_in        <= assembler.RISCV32I(iADD, 1,2,3,0);
          next_inst_enum <= iJALR;
          next_inst      <= assembler.RISCV32I(iJALR, 1,1,1,0);
        when 7 =>
          test_against_sint(rs1_out,0,"no bypass, rs1 /= rd ");
          test_against_sint(rs2_out,1,"no bypass, rs2 /= rd ");

          
          inst_enum_in   <= iAUIPC;
          inst_in        <= assembler.RISCV32I(iAUIPC, 0,0,15,0);
          next_inst_enum <= iLB;
          next_inst      <= assembler.RISCV32I(iJALR, 0,0,0,15);
        when 8 =>
          test_against_sint(rs2_out,1,"no bypass on imm ");

          inst_enum_in   <= iSLTIU;
          inst_in        <= assembler.RISCV32I(iSLTIU, 0,0,15,0);
          next_inst_enum <= iLB;
          next_inst      <= assembler.RISCV32I(iLB, 0,0,0,15);
        when 9 =>
          test_against_sint(rs2_out,1,"no bypass on imm");
          
          inst_enum_in   <= iLBU;
          inst_in        <= assembler.RISCV32I(ILBU, 0,0,5,0);
          next_inst_enum <= iADDI;
          next_inst      <= assembler.RISCV32I(iADDI, 0,0,0,5);
        when 10 =>
          test_1(bubble, '0', "No bubble on imm");
          test_against_sint(rs2_out,1,"no bubble on imm rs2");

          
          inst_enum_in   <= iSLLI;
          inst_in        <= assembler.RISCV32I(iSLLI, 0,0,5,0);
          next_inst_enum <= iSLT;
          next_inst      <= assembler.RISCV32I(iSLT, 5,5,0,0);
        when 11 =>
          test_against_sint(rs1_out,10,"bypass rs1 & rs2");
          test_against_sint(rs2_out,10,"bypass rs2 &rs1");


          inst_enum_in   <= iSB;
          inst_in        <= assembler.RISCV32I(iBEQ, 0,0,5,0);
          next_inst_enum <= iSLT;
          next_inst      <= assembler.RISCV32I(iSLT, 5,5,0,0);
        when 12 => 
          test_against_sint(rs1_out,0,"no rd instruction RS1");
          test_against_sint(rs2_out,1,"no rd instruction RS1");



          inst_enum_in   <= iADDI;
          inst_in        <= assembler.RISCV32I(iADDI, 1,1,1,1);
          next_inst_enum <= iADDI;
          next_inst      <= assembler.RISCV32I(iADDI, 1,1,1,1);
          
        when others =>
        null;
      end case;            

      wait for TbPeriod;

    end loop;
    -- Stop the clock
    TbSimEnded <= '1';
    wait;
  end process;
end tb;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
--use work.tb_helpers.all;
use work.all;

use work.instructions.all;
use work.assembler.all;
use work.tb_helpers.all;

entity tb_Integer_32_ALU is
  generic( bitwidth : integer :=(32 -1));
end tb_Integer_32_ALU;

architecture tb of tb_Integer_32_ALU is
  component Integer_32_ALU
    port (clk     : in std_ulogic;
          rst     : in std_ulogic;
          inst_in : in std_ulogic_vector (bitwidth downto 0);
          inst_enum_in : in instruction_all;
          rs1_in  : in std_ulogic_vector (bitwidth downto 0);
          rs2_in  : in std_ulogic_vector (bitwidth downto 0);
          acc_out : out std_ulogic_vector (bitwidth downto 0);
          acc_me  : out std_ulogic);
  end component;

  signal clk     : std_ulogic;
  signal rst     : std_ulogic;
  signal inst_in : std_ulogic_vector (bitwidth downto 0);
  signal inst_enum_in :instruction_all;
  signal rs1_in  : std_ulogic_vector (bitwidth downto 0);
  signal rs2_in  : std_ulogic_vector (bitwidth downto 0);
  signal acc_out : std_ulogic_vector (bitwidth downto 0);
  signal acc_me  : std_ulogic;

  constant TbPeriod : time := 1000 ns; 
  signal TbClock : std_logic := '0';
  signal TbSimEnded : std_logic := '0';

begin

  dut : Integer_32_ALU
    port map (clk     => clk,
              rst     => rst,
              inst_in => inst_in,
              inst_enum_in => inst_enum_in,
              rs1_in  => rs1_in,
              rs2_in  => rs2_in,
              acc_out => acc_out,
              acc_me  => acc_me);

  -- Clock generation
  TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';

  clk <= TbClock;
  stimuli : process
--declare variables
    variable clk_count 	: integer := 0;     
    variable clk_max 	: integer := 35;

  begin
    -- initialization 
    inst_in <= (others => '0');
    rs1_in <= (others => '0');
    rs2_in <= (others => '0');

    -- Reset generation
    rst <= '0';
    wait for 100 ns;
    rst <= '1';
    wait for 100 ns;

    for clk_count in 0 to 36 loop
      case clk_count is
        when 0=>
          inst_in <= assembler.RISCV32I(iADDI, 0, 0, 0, 100);
          --report "Test ulogic_vector_image function :" & ulogic_vector_image(assembler.RISCV32I(iADDI, 0, 0, 0, 100)) & " Passed :)";
          inst_enum_in <= iADDI;
        when 1 =>
          test_against_sint(acc_out, 100, "Add positive immedate");
          rs1_in <= sint2ulog32(1);
          inst_in <= assembler.RISCV32I(iADDI, 0, 0, 0, -325);
          inst_enum_in <= iADDI;
        when 2 =>
          test_against_sint(acc_out, -324, "Add negative immedate");
          inst_in <= assembler.RISCV32I(iSLTI, 0, 0, 0, 1);
          inst_enum_in <= iSLTI;
        when 3=>
          test_against_sint(acc_out, 0,"SLTI block select");
          
          inst_in <= assembler.RISCV32I(iSLTI, 0, 0, 0, -34);
          inst_enum_in <= ISLTI;
          rs1_in <= sint2ulog32(-4000);
        when 4 =>
          test_against_uint(acc_out, 1, "SLTI pass data");
          test_1(acc_me, '1', "SLTI pass select");

          inst_in <= assembler.RISCV32I(iSLTIU, 0, 0, 0, 34);
          inst_enum_in <= ISLTIU;
        when 5 =>
          test_1(acc_me, '1', "SLTIU block select");

          inst_in <= assembler.RISCV32I(iSLTIU, 0, 0, 0, 255);
          inst_enum_in <= ISLTIU;
          rs1_in <= sint2ulog32(2);

        when 6 =>
          test_against_uint(acc_out, 1, "SLTIU pass data");
          test_1(acc_me, '1', "SLTIU pass select");

          inst_in <= assembler.RISCV32I(iXORI, 0, 0, 0, -1);
          rs1_in <= sint2ulog32(200);
          inst_enum_in <= iXORI;
        when 7 =>
          test_against_sint(acc_out, -201, "iXORI 1");
          
          inst_in <= assembler.RISCV32I(iXORI, 0, 0, 0, 0);
          inst_enum_in <= iXORI;
          rs1_in <= (others => '0');
        when 8 =>
          test_against_uint(acc_out, 0, "XORI 2");
          test_1(acc_me, '1', "XORI select");

          inst_in <= assembler.RISCV32I(iORI,0,0,0,0);
          inst_enum_in <= iORI;
          rs1_in <= sint2ulog32(42534);
        when 9 =>
          test_against_sint(acc_out, 42534, "ORI 1");
          
          inst_in <= assembler.RISCV32I(iORI,0,0,0,-1); --should make
                                                           --the imm all 1s
          inst_enum_in <= iORI;
          rs1_in <= X"FFFFFFFF";
        when 10 =>
          test_against_sint(acc_out, -1 , "ORI 2"); -- should be all 1s
          
          inst_in <= assembler.RISCV32I(iANDI,0,0,0,0);
          inst_enum_in <= iANDI;
          rs1_in <= sint2ulog32(42534);
        when 11 =>
          test_against_sint(acc_out, 0, "ANDI 0");
          
          inst_in <= assembler.RISCV32I(iANDI,0,0,0,-1); --should make
                                                            --the imm all 1s
          rs1_in <= sint2ulog32(15000);
          inst_enum_in <= iANDI;
        when 12 =>
          test_against_sint(acc_out, 15000, "ANDI 1");
          
          inst_in <= assembler.RISCV32I(iSLLI,0,0,0,1);
          inst_enum_in <= iSLLI;
          rs1_in <= sint2ulog32(2);
        when 13 =>
          test_against_sint(acc_out, 4, "SSLI");

          inst_enum_in <= iSRLI;
          inst_in <= assembler.RISCV32I(iSRLI, 0,0,0,1);
        when 14 =>
          test_against_sint(acc_out, 1, "SRLI");

          inst_enum_in <= iSRAI;
          inst_in <= assembler.RISCV32I(iSRAI, 0,0,0,1);
          rs1_in <= sint2ulog32(-2);
        when 15 =>
          test_against_sint(acc_out, -1, "SRAI");

          inst_enum_in <= iADD;
          inst_in <= assembler.RISCV32I(iADD,0,0,0,0);
          rs1_in <= sint2ulog32(2);
        when 16 =>
          test_against_sint(acc_out,2, "Add zero and positive");

          rs2_in <= sint2ulog32(-4);
        when 17 =>
          test_against_sint(acc_out, -2, "Add postive and negative");
          --this is a pass despite it saying fail maybe?
          inst_in <= assembler.RISCV32I(iSUB, 0, 0, 0, 0);
          inst_enum_in <= iSUB;
          
        when 18 =>
          test_against_sint(acc_out, 6, "Subtract negative from positive");
          
          rs2_in <= sint2ulog32(4);
        when 19 =>
          test_against_sint(acc_out, -2, "Subtract two positives");

          inst_enum_in <= ISLL;
          inst_in <= assembler.RISCV32I(iSLL, 0, 0, 0, 0);
          rs1_in <= sint2ulog32(1);
          rs2_in <= X"FFF00001";
        when 20 =>
          test_against_sint(acc_out, 2, "Ignore top bits in left shift");

          rs1_in <= X"00000100";
          rs2_in <= sint2ulog32(3);
        when 21 =>
          test_against_sint(acc_out, 2048, "SLL left shift 3");

          inst_enum_in <= iSLT;
          inst_in <= assembler.RISCV32I(iSLT, 0, 0, 0, 0);
          rs2_in <= sint2ulog32(0);
        when 22 =>
          test_against_sint(acc_out, 0, "SLT 0");
          
          inst_in <= assembler.RISCV32I(iSLT, 0, 0, 0, 0);
          inst_enum_in <= iSLT;
          rs1_in <= sint2ulog32(-4000);
          rs2_in <= sint2ulog32(-34);
        when 23 =>
          test_against_uint(acc_out, 1, "SLT pass data");
          test_1(acc_me, '1', "SLTI pass select");

          inst_enum_in <= iSLTU;
          inst_in <= assembler.RISCV32I(iSLTU, 0, 0, 0, 0);
          rs2_in <= sint2ulog32(34);
        when 24 =>
          test_1(acc_me, '1', "SLT block select");

          inst_in <= assembler.RISCV32I(iSLTU, 0, 0, 0, 0);
          inst_enum_in <= iSLTU;

          rs1_in <= sint2ulog32(2); --largest unsigned
          rs2_in <= sint2ulog32(255);--random unsigned
        when 25 =>
          test_against_uint(acc_out, 1, "SLTU pass data");
          test_1(acc_me, '1', "SLTU pass select");

          inst_enum_in <= iXOR;
          inst_in <= assembler.RISCV32I(iXOR, 0, 0, 0, 0);
          rs1_in <= sint2ulog32(-1);
          rs2_in <= sint2ulog32(-1);
        when 26 =>
          test(acc_out, X"00000000", "iXOR 1");

          inst_enum_in <= iXOR;
          inst_in <= assembler.RISCV32I(iXOR, 0, 0, 0, 0);
          rs1_in <= sint2ulog32(20);
          rs2_in <= sint2ulog32(4);
        when 27 =>
          test_against_uint(acc_out, 16, "XOR 2");

          inst_enum_in <= iSLL;
          inst_in <= assembler.RISCV32I(iSLL,0,0,0,0);
          rs1_in <= sint2ulog32(2);
          rs2_in <= sint2ulog32(1);

        when 28 =>
          test_against_sint(acc_out, 4, "SLL");
          inst_in <= assembler.RISCV32I(iSRL, 0,0,0,0);
          inst_enum_in <= iSRL;
        when 29 =>
          test_against_sint(acc_out, 1, "SRL");

          inst_enum_in <= iSRA;
          inst_in <= assembler.RISCV32I(iSRA, 0,0,0,0);
          rs1_in <= sint2ulog32(-2);
          rs2_in <= sint2ulog32(1);

        when 30 =>
          test_against_sint(acc_out, -1, "SRA");

          inst_enum_in <= iORI;
          inst_in <= assembler.RISCV32I(iORI,0,0,0,0);
          rs2_in <= sint2ulog32(0);
          rs1_in <= sint2ulog32(42534);
        when 31 =>
          test_against_sint(acc_out, 42534, "OR 1");

          inst_enum_in <= iOR;
          inst_in <= assembler.RISCV32I(iOR,0,0,0,0); --should make
          rs2_in <= X"0000FFFF";
          rs1_in <= X"FFFF0000";
        when 32 =>
          test_against_sint(acc_out, -1 , "ORI 2"); -- should be all 1s

          inst_enum_in <= iAND;
          inst_in <= assembler.RISCV32I(iAND,0,0,0,0);
          rs2_in <= sint2ulog32(0);
          rs1_in <= sint2ulog32(42534);
        when 33 =>
          test_against_sint(acc_out, 0, "AND 0");
          
          inst_in <= assembler.RISCV32I(iAND,0,0,0,0); --should make
                                                      --the imm all 1s
          inst_enum_in <= iAND;
          rs2_in <= X"FFFFFFFF";
          rs1_in <= sint2ulog32(1500000);

        when 34 =>
          test_against_sint(acc_out, 1500000 , "AND 1");

          inst_in <= assembler.RISCV32I(iBEQ, 0,23,22,2000);
          inst_enum_in <= iBEQ;
        when 35 =>
          test_1(acc_me, '0' , "test non-ALU instruction");
          
					inst_enum_in <= iADD;
					rs1_in 			 <= (others => '1');
					rs2_in 			 <= (others => '1');
				when 36 =>
					test(acc_out, "11111111111111111111111111111110","Overflow");
          
        when others => null;
      end case;
      

      wait for TbPeriod;

    end loop;
    -- Stop the clock and terminate the simulation
    TbSimEnded <= '1';
    wait;
  end process;

end tb;

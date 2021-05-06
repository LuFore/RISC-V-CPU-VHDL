library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.instructions.all;
use work.helpers.all;

entity Integer_32_ALU is
  generic( bitwidth : integer :=(32 -1));
  port(clk, rst 	: in std_ulogic;
       	        
       inst_in	        : in instruction; 
       inst_enum_in     : in instruction_all; 

       rs1_in, rs2_in	: in std_ulogic_vector(bitwidth downto 0);
       acc_out          :out std_ulogic_vector(bitwidth downto 0);
       acc_me           :out std_ulogic
   );
end Integer_32_ALU;

architecture ALU_arch of Integer_32_ALU is
  alias imm     : std_ulogic_vector(11 downto 0) is inst_in(bitwidth downto 20);
  alias shamt   : std_ulogic_vector(4 downto 0) is inst_in(24 downto 20);
  
begin
  process(clk)
  begin
    if rst = '0' then
      acc_out <= (others => '0');
      acc_me  <= '0';

    elsif rising_edge(clk) then       
      
      acc_me <= '1';
      
      case inst_enum_in  is
        when iADDI =>
          acc_out <= std_ulogic_vector(signed(rs1_in) + signed_extend(imm, rs1_in'length));
        when iSlTI =>
          --should set rd to 0, but this is handled by acc_me and the accumulator
          if not signed(rs1_in) < signed_extend(imm,rs1_in'length ) then
            acc_me <= '0';
          end if;
          acc_out <= X"00000001";
        when iSlTIU=>
          if not unsigned(rs1_in) < unsigned(X"00000" & imm) then  
            acc_me <= '0';
          end if;
          acc_out <= X"00000001";
        when iXORI =>
          acc_out <= rs1_in xor std_ulogic_vector(signed_extend(imm, bitwidth + 1));
        when iORI  =>
          acc_out <= rs1_in or std_ulogic_vector(signed_extend(imm, bitwidth + 1));  
        when iANDI =>
          acc_out <= rs1_in and std_ulogic_vector(signed_extend(imm,bitwidth + 1));
        when iSLLI =>
          acc_out <= lleft_shift(rs1_in,to_integer(unsigned(shamt)));
        when iSRLI =>
          acc_out <= lright_shift(rs1_in,to_integer(unsigned(shamt)));
        when iSRAI =>
          acc_out <= aright_shift(rs1_in,to_integer(unsigned(shamt)));
-- instructions do not make use of imm
        when iADD =>         
          acc_out <= std_ulogic_vector(signed(rs1_in) + signed(rs2_in));
        when iSUB =>
          acc_out <= std_ulogic_vector(signed(rs1_in) - signed(rs2_in));
        when iSLL =>
          acc_out <= lleft_shift(rs1_in,to_integer(unsigned(rs2_in(4 downto 0))));
        when iSLT =>
          if not  signed(rs1_in) < signed(rs2_in) then
            acc_me <= '0';
          end if;
          acc_out <= X"00000001";
        when iSLTU=>
          if not unsigned(rs1_in) < unsigned(rs2_in) then
            acc_me <= '0';
          end if;     
          acc_out <= X"00000001";
        when iXOR =>
          acc_out <= rs1_in xor rs2_in;
        when iSRL =>
          acc_out <= lright_shift(rs1_in,to_integer(unsigned(rs2_in(4 downto 0))));
        when iSRA =>
          acc_out <= aright_shift(rs1_in,to_integer(unsigned(rs2_in(4 downto 0))));
        when iOR  =>
          acc_out <= rs1_in or rs2_in;
        when iAND =>
          acc_out <= rs1_in and rs2_in;
        
        when others =>
          acc_me <= '0';
      end case;
    end if;
  end process;  
end ALU_arch;

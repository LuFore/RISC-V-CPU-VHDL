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
 	signal output : std_ulogic_vector(bitwidth+1 downto 0);

begin
  process(clk)
  begin
    if rst = '0' then
      output(acc_out'range) <= (others => '0');
      acc_me  <= '0';
			output  <= (others => '0'); --not needed but good for debugging 
    elsif rising_edge(clk) then       
      
      acc_me <= '1';
      
      case inst_enum_in  is
        when iADDI =>
          output <= std_ulogic_vector(signed_extend(rs1_in,rs1_in'length + 1) + signed_extend(imm, rs1_in'length+1));
        when iSlTI =>
         	output  <= (others => '0');
					if signed(rs1_in) < signed_extend(imm,rs1_in'length ) then
          	output(0)  <= '1';
          end if;
        when iSlTIU=>
					output <= (others => '0');
          if unsigned(rs1_in) < unsigned(X"00000" & imm) then
            output(0) <= '1';
          end if;  
        when iXORI =>
        	output(acc_out'range) <= rs1_in xor std_ulogic_vector(signed_extend(imm, bitwidth + 1));
        when iORI  =>
          output(acc_out'range) <= rs1_in or std_ulogic_vector(signed_extend(imm, bitwidth + 1));  
        when iANDI =>
          output(acc_out'range) <= rs1_in and std_ulogic_vector(signed_extend(imm,bitwidth + 1));
        when iSLLI =>
          output(acc_out'range) <= lleft_shift(rs1_in,to_integer(unsigned(shamt)));
        when iSRLI =>
          output(acc_out'range) <= lright_shift(rs1_in,to_integer(unsigned(shamt)));
        when iSRAI =>
          output(acc_out'range) <= aright_shift(rs1_in,to_integer(unsigned(shamt)));
-- instructions that do not make use of imm
        when iADD =>         
          output <= std_ulogic_vector(signed('1' & rs1_in) + signed('1' & rs2_in));
        when iSUB =>
          output <= std_ulogic_vector(signed('0' & rs1_in) - signed('0' & rs2_in));
        when iSLL =>
          output(acc_out'range) <= lleft_shift(rs1_in,to_integer(unsigned(rs2_in(4 downto 0))));
        when iSLT =>
          output <= (others => '0');
					if signed(rs1_in) < signed(rs2_in) then
            output(0) <= '1';
          end if;
        when iSLTU=>
					output <= (others => '0');
          if unsigned(rs1_in) < unsigned(rs2_in) then
            output(0) <= '1';
          end if;
        when iXOR =>
          output(acc_out'range) <= rs1_in xor rs2_in;
        when iSRL =>
          output(acc_out'range) <= lright_shift(rs1_in,to_integer(unsigned(rs2_in(4 downto 0))));
        when iSRA =>
          output(acc_out'range) <= aright_shift(rs1_in,to_integer(unsigned(rs2_in(4 downto 0))));
        when iOR  =>
          output(acc_out'range) <= rs1_in or rs2_in;
        when iAND =>
          output(acc_out'range) <= rs1_in and rs2_in;
        
        when others =>
          acc_me <= '0';
      end case;
    end if;
		acc_out <= output(acc_out'range);
  end process;  
end ALU_arch;

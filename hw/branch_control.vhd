library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.instructions.all;

entity Branch_control is -- a Control unit :)
  generic(
    bitwidth : integer := (32 - 1));
  port(
    clk 	: in std_ulogic;
    rst		: in std_ulogic;
    branch 	:out std_ulogic; -- when this is set it will change the PC to in 
    misaligned  :out std_ulogic; -- error bit

    inst_enum_in: in instruction_all;
    inst_in	: in std_ulogic_vector(bitwidth downto 0); 
    rs1_in	: in std_ulogic_vector(bitwidth downto 0);
    rs2_in	: in std_ulogic_vector(bitwidth downto 0);

    acc_out     :out std_ulogic_vector(bitwidth downto 0); 
    
    PC_in	: in std_ulogic_vector(bitwidth downto 0); 			
    PC_out	:out std_ulogic_vector(bitwidth downto 0);
    acc_me 	:out std_ulogic
    );
end Branch_control;


architecture Control_arch of Branch_control is
  
begin
  process(clk)
    variable imm	 	: std_ulogic_vector(bitwidth + 1 downto 0);
    variable temp		: signed(bitwidth + 1 downto 0);
    variable branched 	: std_ulogic := '0'; --unconditional jumps
    variable branch_c	: std_ulogic := '0'; --conditional jumps
    --When branched or branch_c is set high 
  begin
    
    if rst = '0' then --reset on low
      acc_me <= '0';
      misaligned <= '0';
      branched := '0';
      branch_c := '0';
      imm := (others => '0');
      PC_out <= (others => '0'); --default 0, only used in
      acc_out <= (others => '0'); --default 0, only used in JALR
      branch <= '0';
      
    elsif rising_edge(clk) then

      misaligned <= '0';
      branched := '0';
      branch_c := '0';

      imm := (others => '0');

      PC_out <= (others => '0'); --deafault to 0s

      acc_out <= (others => '0'); --deafault low, only used in JALR
      acc_me <= '0';

------------------------conditional jumps------------------------
      case inst_enum_in is
        when iBEQ =>
          if rs1_in = rs2_in then
            branch_c := '1';
          end if;
        when iBNE =>
          if rs1_in /= rs2_in then
            branch_c := '1';
          end if;	
        when iBLT =>
          if signed(rs1_in) < signed(rs2_in) then
            branch_c := '1';
          end if;
        when iBGE =>
          if signed(rs1_in) >= signed(rs2_in) then
            branch_c := '1';
          end if;
        when iBGEU =>
          if unsigned(rs1_in) >= unsigned(rs2_in) then
            branch_c := '1';
          end if;
        when iBLTU =>
          if unsigned(rs1_in) < unsigned(rs2_in) then
            branch_c := '1';
          end if;
-----------------------unconditional jumps-----------------------
        when iJAL =>
          branched := '1';
          imm(20 downto 0) := (inst_in(31) & inst_in(19 downto 12) & inst_in(20) & inst_in(30 downto 21) &'0');--set imm for	--(others => '0') or
          imm(bitwidth downto 21) := (others => inst_in(31));
          
        when iJALR => -- this does not calculate PC the same and is not complete without code after
          branched := '1';
          acc_out <= std_ulogic_vector(unsigned(PC_in) + 4);
          acc_me <= '1';
          imm(11 downto 0) := inst_in(bitwidth downto 20);			
          imm(bitwidth downto 12) := (others => inst_in(bitwidth));
------------------------ LUI AND AUIPC ------------------------
        when iLUI =>
          acc_out(31 downto 12) <= inst_in(31 downto 12);
          acc_out(11 downto 0 ) <= (others => '0');
          acc_me <= '1';
        when iAUIPC =>
          imm(31 downto 12) :=  inst_in(31 downto 12);
          imm(11 downto 0 ) := (others => '0');
          temp := signed('0' & PC_in) + signed(imm);
          acc_out(31 downto 0) <= std_ulogic_vector(temp(31 downto 0));
          
        when others =>
          branched := '0';
      end case;

----------------------- manage branches ------------------------
      if (branch_c or branched) = '1' then 
        if branch_c = '1' then -- set branched and imm for conditional branches
          branched := '1';
          imm(12 downto 0) := (inst_in(31) & inst_in(7) & inst_in(30 downto 25) & inst_in(11 downto 8) & '0');
          imm(bitwidth downto 13) := (others => inst_in(31));
        end if;

-------------------------JALR exception-------------------------
        if inst_enum_in = iJALR then
          temp := signed('0' & rs1_in)+ signed(imm);
--------------------add imm and set PC_out----------------------	
        else
          temp := signed('0' & PC_in) + signed(imm);
        end if;
        PC_out(bitwidth downto 0) <= std_ulogic_vector(temp(bitwidth downto 0));
        
        misaligned <= (temp(0) or temp(1)); --find if bytes aligne with 32 bit register space
        
      end if;
      branch <= branched;
    end if;
    
  end process;

end Control_arch;


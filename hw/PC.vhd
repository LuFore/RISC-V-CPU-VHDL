library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity PC is -- a program counter :)
--Can only be set to a 32 bit value, all logic involving relative jumps are
--handled in the branch_control module
  generic(
    bitwidth : integer := (32 - 1));
  port(
    clk 	: in std_ulogic;
    rst		: in std_ulogic;
    branch 	: in std_ulogic; -- when this is set it will change the PC to in 
    pause       : in std_ulogic; -- stop incrementing PC when high
    
    PC_in	: in std_ulogic_vector(bitwidth downto 0);
    PC_out	:out std_ulogic_vector(bitwidth downto 0)
    );
end PC;


architecture PC_arch of PC is
  signal reg : std_ulogic_vector(bitwidth downto 0);
  --register to save value of the program counter
begin
  process(clk)
  begin
    
    if rst = '0' then --reset on low
      reg <= (others => '0');
      
    elsif rising_edge(clk) then
      if branch = '1' then --when branch command is issued set the PC to the input PC_out
        reg <= PC_in;

      elsif pause = '0' then --increment PC
        reg <= std_ulogic_vector(unsigned(reg)+4);
      end if;
    end if;
    
  end process;

  PC_out <= reg; --hard wire PC_out to reg

end PC_arch;




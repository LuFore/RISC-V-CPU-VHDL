library IEEE;
use ieee.std_logic_1164.all;

entity delay_std_ulogic is
  port(clk, rst : in std_ulogic;
       input : in std_ulogic;
       output:out std_ulogic);
end delay_std_ulogic;

architecture arch of delay_std_ulogic is
begin
  process(clk)
  begin
    if rst = '0' then
      output <= '0';
    elsif rising_edge(clk) then
      output <= input;
    end if;
  end process;
end arch;     

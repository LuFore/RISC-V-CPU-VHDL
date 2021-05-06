library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;

entity delay is
  generic(vector_size : integer := 32-1);
  port(clk, rst : in std_ulogic;
    input : in std_ulogic_vector (vector_size downto 0);
    output:out std_ulogic_vector (vector_size downto 0));
end delay;

architecture delay_arch of delay is
begin
  process(clk)
  begin
    if rst = '0' then
      output <= (others => '0');
    elsif rising_edge(clk) then
      output <= input;
    end if;
  end process;
end delay_arch;
  

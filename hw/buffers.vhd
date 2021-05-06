library IEEE;
use ieee.std_logic_1164.all;

entity buffers is
  --delays rst_in and PC_in, d1 is delayed by 1 clock, d2 by 2 and so on. 
  generic( bit_width : integer := 32-1);
  port(
    clk, rst : in std_ulogic;
    PC_in : in std_ulogic_vector(bit_width downto 0);
    rst_in: in std_ulogic;

    rst_d1, rst_d2, rst_d3 : out std_ulogic;
    PC_delay : out std_ulogic_vector(bit_width downto 0)
    );
end buffers;
                                 
architecture arch of buffers is
  signal rst_d1s, rst_d2s, rst_d3s : std_ulogic;
  signal PC_d1s, PC_d2s, PC_d3s : std_ulogic_vector(bit_width downto 0);
  
begin
  process(clk)
  begin
    if rst = '0' then
      PC_d3s <= (others => '0');
      PC_d2s <= (others => '0');
      PC_d1s <= (others => '0');

      rst_d3s <= '0';
      rst_d2s <= '0';
      rst_d1s <= '0';

    elsif rising_edge(clk) then
      PC_d3s <= PC_d2s;
      PC_d2s <= PC_d1s;
      PC_d1s <= PC_in;

      rst_d3s <= rst_d2s;
      rst_d2s <= rst_d1s;
      rst_d1s <= rst_in;
      
    end if;
  end process;
  --hard wire registers to output
  PC_delay <= PC_d3s;

  rst_d1 <= rst_d1s;-- rst_d2s;
  rst_d2 <= rst_d2s;
  rst_d3 <= rst_d3s;
end arch;
        
          
    

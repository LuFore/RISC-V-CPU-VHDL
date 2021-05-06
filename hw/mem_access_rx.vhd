library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.instructions.all;
use work.helpers.all;

entity mem_access_rx is
--Recives data from the cache and ALU, also acts as an accumulator
  generic(
    address_width : integer := 8; --size of each address in bits
    bit_width : integer := (32 - 1);
    bus_width : integer := (32 -1) 
    );

  port(
    clk, rst : in std_ulogic;

    inst_enum_in : in instruction_all;
    inst_in      : in instruction;

    data_in      :in std_ulogic_vector(bus_width downto 0); --data to be loaded
    data_out     :out std_ulogic_vector(bit_width downto 0);-- data to write to registers
    address_out  :out std_ulogic_vector(5-1 downto 0); --address to register

    result_in    : in std_ulogic_vector(bit_width downto 0);
    acc_select   : in std_ulogic
    );
end mem_access_rx;

architecture arch of mem_access_rx is

  alias rd      :std_ulogic_vector(5-1 downto 0) is inst_in(11 downto 7);
  alias op_code :std_ulogic_vector(6 downto 0) is inst_in(6 downto 0);
  --immediate for load instructions (I type)
  alias  I_imm       :std_ulogic_vector(11 downto 0) is inst_in(31 downto 20);
  --bitmask for the output, this is the safest way
  signal mask        : std_ulogic_vector(bit_width downto 0);
  --regsiter signals to make them sync
  signal result_sync : std_ulogic_vector(bit_width downto 0); --register
  signal acc_sync    : std_ulogic; 
  signal sign        : std_logic;

begin
  process(clk)
    variable not_select : std_logic; -- used as a bool 
  begin
    
    if rst = '0' then
      mask        <= (others => '0');
      result_sync <= (others => '0');
      address_out <= (others => '0');
      sign <= '0';
      acc_sync <= '0';
      
    elsif rising_edge(clk) then
      not_select := '0';
      result_sync <= result_in;
      acc_sync <= acc_select;
      
      case inst_enum_in is --very similar to tx, but with only loads
        when iLB =>
          --load byte signed
          sign <= '1';
        when iLH =>
          sign <= '1';
        when iLW =>
          sign <= '1';
        when iLBU =>
          sign <= '0';
          mask <= X"000000FF";
        when iLHU  =>
          sign <= '0';
          mask <= X"0000FFFF";
        when others =>
          --output result from ALU
          not_select := '1';
      end case;	

      if (not_select = '0')  or (acc_select = '1')then        
        --handle the accumulator part
        address_out <= rd;
      else
        address_out <= (others => '0');
      end if;      

    end if;
  end process;  
  data_out <= result_sync when    acc_sync = '1' else
              (mask and data_in) when sign = '0' else              
              data_in            when sign = '1' else --data comes in signed
              (others => '0'); -- not needed but useful for debugging              
end arch;


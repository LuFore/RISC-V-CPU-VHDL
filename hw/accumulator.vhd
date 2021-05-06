library IEEE;
use ieee.std_logic_1164.all;

library work;
use work.instructions.all;

entity accumulator is
  --no clock or reset block as there is no process block
  generic(bit_width : integer := 32-1);
  port(
    inst_in               : in instruction;

    mem_select, ALU_select: in std_ulogic;
    mem_data, ALU_data    : in std_ulogic_vector(bit_width downto 0);

    write_data            :out std_ulogic_vector(bit_width downto 0);
    write_address         :out std_ulogic_vector(5-1 downto 0)
    );
end accumulator;

architecture arch of accumulator is
begin
  --Rd of instruction when data is sent
  write_address<= inst_in(11 downto 7) when '1' = (mem_select or ALU_select) else
                  (others => '0');--address 0 is hardwired to 0 so no value
                                  --will be saved
  write_data   <= mem_data when mem_select = '1' else
                  ALU_data when ALU_select = '1' else
                  (others => '0'); -- not needed but avoids undefined behaviour
end arch;


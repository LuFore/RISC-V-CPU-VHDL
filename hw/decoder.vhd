library IEEE;
use ieee.std_logic_1164.all;
library work;
use work.instructions.all;

entity decoder is -- finds rs1 rs2 and saves the instruction so they may be
  -- output at the same clock
  --rs1 and rs2 will always be taken from the register, even if not used
  generic(bus_width : integer := (32-1));
  port(
    clk, rst            : in std_ulogic;
    inst_in             : in instruction;
    rs1_add, rs2_add    :out std_ulogic_vector (5-1 downto 0);
    inst_out0,inst_out1 :out instruction;
    inst_enum_out0,inst_enum_out1 :out instruction_all;    
    pause               : in std_ulogic
    );
end decoder;


architecture decoder_arch of decoder is
  signal enum_save : instruction_all;
  signal inst_save : instruction;
begin
  process(clk) 
    variable enum_var : instruction_all;
  begin
    if rst = '0' then
      inst_save <= X"00000013";--NOP
      rs1_add 	<= (others => '0');
      rs2_add 	<= (others => '0');
      inst_out0 	<= X"00000013";--NOP
      inst_enum_out0    <= iADDI;

      enum_save         <= iADDI;
      inst_out1 	<= X"00000013";--NOP
      inst_enum_out1    <= iADDI;

    elsif rising_edge(clk) then
      if pause /= '1' then
        rs1_add <= inst_in(19 downto 15);
        rs2_add <= inst_in(24 downto 20);
      
        inst_out0 <= inst_in;
        inst_save <= inst_in;
        inst_out1 <= inst_save;
        enum_var := get_instruction_all(inst_in);
        inst_enum_out0 <= enum_var;
        inst_enum_out1 <= enum_save;
        enum_save <= enum_var;
        
      end if;
    end if;
  end process;
end decoder_arch;

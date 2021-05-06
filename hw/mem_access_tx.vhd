library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.instructions.all;
use work.helpers.all;
--use work.tb_helpers.int2ulogic32;

entity mem_access_tx is
-- Sends load/store instructions and data to a memory cache
  generic(
    address_width : integer := 8; --size of each address in bits
    bit_width : integer := (32 - 1);
    bus_width: integer := 32 - 1
    );
  port(
    clk, rst : in std_ulogic;

    
    inst_enum_in  : in instruction_all;

    inst_in  : in instruction;
    inst_out : out instruction;
    
    rs1_in, rs2_in : in std_ulogic_vector(bit_width downto 0);

    rw : out std_ulogic; --Tell the cache if reading or writing, 0 for read 1
    --for write so on reset it will not 
    data_store  :out std_ulogic_vector(bus_width downto 0); --data to be stored
    address_out : out std_ulogic_vector(bit_width downto 0); --address to
                                                            --read/write to
    mem_len : out std_ulogic_vector(1 downto 0)
    );
end mem_access_tx;

architecture arch of mem_access_tx is
  alias op_code :std_ulogic_vector(6 downto 0) is inst_in(6 downto 0);
  --immediate for load instructions (I type)
  alias I_imm   :std_ulogic_vector(11 downto 0) is inst_in(31 downto 20);
  
    
begin
  process(clk)
    variable not_select : std_logic; -- used as a bool 
    variable imm : std_ulogic_vector(bit_width downto 0);
    variable overflow : signed(bit_width + 1 downto 0); -- deal with overflow
  begin
    
    if rst = '0' then
      inst_out <= (others => '0');
      data_store <= (others => '0');
      rw <= '0';
      mem_len <= (others => '0');
      address_out <= (others => '0');
      
    elsif rising_edge(clk) then
      inst_out <= inst_in; -- feed inst through in line with clock cycle to rx
      
      not_select := '0';

      case inst_enum_in is
        when iLW | iSW =>
          mem_len <= "11";
        when iLB | iLBU | iSB=>
          mem_len <= "00";
        when iLH| iLHU | iSH =>
          mem_len <= "01";			
        when others =>
          -- output nothing
          not_select := '1';
      end case;	

      if not_select = '1' then
        rw <= '0'; --set read so no wrong data is accidently saved
        --rest of data doesn't matter so will be ignored.
        address_out <= (others => '0'); -- set address to 0 when nothing happening
      else
        --find imm
          if op_code = "0000011" then --load opcode
            rw <= '0';
            imm(31 downto 12) := (others => i_imm(11)); 
            imm(11 downto 0)  := i_imm; --simple sign extend
                                                             --using numeric_std
          else -- if neither of the first two, result will be a store
            imm(11 downto 5) := inst_in(31 downto 25);
            imm(4 downto 0) := inst_in(11 downto 7);
            imm(bit_width downto 12) := (others => imm(11)); --sign extend
            data_store <= rs2_in; --set data to be saved
            rw <= '1';
          end if;
          --set address of read or write
          overflow := signed(imm) + signed('0' & rs1_in);
          address_out <= std_ulogic_vector(overflow(bit_width downto 0));
      end if;
    end if;
  end process;
end arch;

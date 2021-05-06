library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-- A register of length XLEN, with each adress being XLEN long. 
entity reg_32 is
  generic(
    XLEN : integer := (32 - 1);	  -- width of adresses and length of register = 2**bitadd
    bitadd	 : integer := (5 - 1) -- length of address
    );
  port(
    clk	: in std_ulogic;
    rst	: in std_ulogic;-- 0 will reset
    pause : in std_ulogic;
    
    d_in: in std_ulogic_vector (XLEN downto 0);	--data to be put into register as specifed by adwr

    d_out0, d_out1: out std_ulogic_vector (XLEN downto 0);--data lines output
                                                          --from adress adre1&0
    adre0, adre1, adwr0	: in std_ulogic_vector (bitadd downto 0) --addresses 
    );
end reg_32;

architecture reg_32_arch of reg_32 is

  type t_reg is array(XLEN downto 0) of std_ulogic_vector (XLEN downto 0);	
  signal reg : t_reg;

begin 
  process(clk)
  begin

    if rst = '0' then 	-- reset
      --reset code here
      for i in 0 to XLEN loop
        reg(i) <= (others =>'0'); --reset register with empty values
      end loop;
      d_out0 <= (others =>'0');
      d_out1 <= (others =>'0');

    elsif rising_edge(clk) then

      if pause = '0' then -- make sure pause is not on
      --get data requested from adre0 and adre1
        d_out0 <= reg(to_integer(unsigned(adre0)));
        d_out1 <= reg(to_integer(unsigned(adre1)));
      end if;
      --set data in adwr0, but make sure not to overwirte the zeros in reg(0);
      if adwr0 = "00000" then
        null;
      else
        reg(to_integer(unsigned(adwr0))) <= d_in;
      end if;
      
    end if;
  end process;

  --reg(0) <= (others => '0');	--address 0 hardwired to 0

end reg_32_arch;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.instructions.all;
use work.helpers.all;

package  csr_info is
  constant XLEN : natural := 32-1;
  subtype ulogic_XLEN is std_ulogic_vector(XLEN downto 0);
  
  --ZCSR address constants
  
  -- read only registers
  constant VENDOR_ID_ADDRESS        : natural := 16#F11#;
  constant ARCHITECTURE_ID_ADDRESS  : natural := 16#F12#;
  constant IMPLEMENTATION_ID_ADDRESS: natural := 16#F13#;
  constant THREAD_ID_ADDRESS        : natural := 16#F14#;
  
  constant VENDOR_ID         : ulogic_XLEN := (others => '0');
  --Arch ID is given out by the RISCV foundation
  constant ARCHITECTURE_ID   : ulogic_XLEN := (others => '0');
  constant IMPLEMENTATION_ID : ulogic_XLEN := (others => '0');

  --read write IDs

  constant mstatus    : natural := 16#300#;
  constant misa       : natural := 16#301#;
  constant medeleg    : natural := 16#302#; --NOT USED WITHOUT U or S LEVEL
  constant mideleg    : natural := 16#303#; --NOT USED WITHOUT U or S LEVEL
  constant mie        : natural := 16#304#;
  constant mtvec      : natural := 16#305#;
  constant mcounteren : natural := 16#306#; -- U mode ONLY

  constant mscratch     : natural := 16#340#;
  constant mepc         : natural := 16#341#;
  constant mcause       : natural := 16#342#;
  constant mtval        : natural := 16#343#;
  constant mip          : natural := 16#344#;
  
  constant pmpcfg_bottom : natural := 16#3A0#; -- U/S ONLY
  constant pmpcfg_top    : natural := 16#3A3#; -- U/S ONLY
  constant pmpaddr_bottom: natural := 16#3B0#; -- U/S ONLY
  constant pmpaddr_top   : natural := 16#3BF#; -- U/S ONLY

  constant mcycle             : natural := 16#B00#;
  constant minstret           : natural := 16#B02#;
  constant mhpmcounter_bottom : natural := 16#B03#;
  constant mhpmcounter_top    : natural := 16#B1F#;
  constant mcycleh            : natural := 16#B80#;
  constant minstreth          : natural := 16#B82#;
  constant mhpmcounterh_bottom: natural := 16#B83#;
  constant mhpmcounterh_top   : natural := 16#B9F#;

  constant mcountinhibit      : natural := 16#320#;
  constant mhmevent_bottom    : natural := 16#323#;
  constant mhmevent_top       : natural := 16#33F#;


  --rst is the default value of register, mask returns a bitmask of XLEN length
  --with 0 being values that is legal to write to and 1's being illegal writes
  --for WARL registers that always block off certian bits
  --
  --if a register rst is not provided here, it is assumed to be all 0
  
  function misa_rst return ulogic_XLEN; -- provide data for the misa register   
  function misa_mask return ulogic_XLEN; --provide mask for WARL registers

  function mstatus_rst return ulogic_XLEN;--provide data for the mstatus register
  function mstatus_mask return ulogic_XLEN; --provide mask for WARL registers
  function mip_mask return ulogic_XLEN;
  
  function mie_rst return ulogic_XLEN;
  function mie_mask return ulogic_XLEN;
  
end package csr_info;


package body csr_info is

  function misa_rst return ulogic_XLEN is
    variable r : ulogic_XLEN;
  begin
    r := (others => '0');
    --32 bit
    r(ulogic_XLEN'length-1 downto ulogic_XLEN'length-2) := "01";    
    r(8) := '1'; -- 32I base ISA
    return r;
  end misa_rst;

  function misa_mask return ulogic_XLEN is
    variable r : ulogic_XLEN := (others => '0');
  begin
    r(25 downto 0) := (others =>'1');
    r(XLEN downto XLEN-1) := (others => '1');
    --might need to be XLEN -1 and XLEN-2
    return r;
  end misa_mask;

  
  function mstatus_rst return ulogic_XLEN is
    variable r: ulogic_XLEN := (others => '0');
  --most registers hard wired to 0 as only M level is supported
  --mstatush register is not required as it would all be 0 (3.1.6 in priv spec
  --1.12 draft april 2021)
  begin
    --set MPP as always 11 as only machine level is supported - this cannot change
    r(12 downto 11) := "11";
    r(3) := '1'; -- set MIE to 1, allowing interrupts
    --r(7) (mpie) does not need to be set as there was no previous itr enable state
    return r;    
  end mstatus_rst;
  
  function mstatus_mask return ulogic_XLEN is
    variable r : ulogic_XLEN := (others => '0');--many registers are WPRI   
  begin
    --RV 64 is very different to RV32 so XLEN is not used
    r(31) := '1'; --SD is read only
    --30 downto 23 are WPRI
    r(22 downto 11):= (others => '0');
    --22 downto 11 are only used with U or S modes, not in an M only system
    r(10 downto 9) := (others => '0');--10 downto 9 is WPRI
    --SPP is S only
    r(7) := '0'; -- MPIE stores the previous MIE before an interrupt/trap is entered
    r(6 downto 5) := (others => '1'); --4 is WPRI, rest is S or U only
    r(4 downto 2) := (others => '0');
    --MIE(3) is 1 when interrupts are enabled and 0 when disabled, rest are 0
    r(2 downto 0) := "010"; --2 and 0 are WPRI, 1 is supervisor only
    return r;
  end mstatus_mask;

  function mip_mask return ulogic_XLEN is
    variable r : ulogic_XLEN := (others => '0'); 
  begin
    r(15 downto 0) := (others => '1');
    --bottom 16 bits are all hardwired to 0 or read only
    return r;
  end mip_mask;

  function mie_rst return ulogic_XLEN is
    --3.1.9 of the priv spec (1.12 draft)
    variable r : ulogic_XLEN := (others => '0');
  begin
    r(11 downto 0) := "100010001000";
    --MEIE MTIE and MSIE can be set, rest are hardwired to 0
    return r;    
  end mie_rst;
  

  function mie_mask return ulogic_XLEN is
    --lower 16 bits are opposite as on the reset 
    variable r : ulogic_XLEN := (not mie_rst);
  begin
    --registers 32 downto 16 can be written in this implimentation
    r(XLEN downto 16) := (others => '0');
    return r;
  end mie_mask;  

end package body csr_info;

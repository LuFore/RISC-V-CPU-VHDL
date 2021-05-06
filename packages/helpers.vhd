library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- :) 
package helpers is
--a few useful functions
  function pad_bits( in1: std_ulogic_vector ; in2 : std_ulogic_vector) return std_ulogic_vector;
-- pad rs2 to be as long as rs1 with 0s
  function signed_extend( small : std_ulogic_vector; exten_size :integer ) return signed;
--shifts are not provided by all versions of VHDL, so I did them myself
  function lleft_shift (value: std_ulogic_vector; shift : integer) return std_ulogic_vector;
  --l is logic, a is arthmitic, keeping the sign
  function lright_shift (value: std_ulogic_vector; shift : integer) return std_ulogic_vector;
  function aright_shift (value: std_ulogic_vector; shift : integer) return std_ulogic_vector;

  function reverse_ulogic( logic :in std_ulogic_vector) return std_ulogic_vector;
  function or_all( vect : in std_ulogic_vector) return std_ulogic;
  
end package helpers;

package body helpers is
  --improvment to this is replace all 'length-1 with 'high and 0 with 'low
  
  function signed_extend( small : std_ulogic_vector ; exten_size : integer ) return signed is
    variable r : signed(exten_size-1 downto 0);
  begin
    r := (others => small(small'left));
    r(small'length-1 downto 0) := signed(small);
    return r;
  end signed_extend;

  function pad_bits( in1: std_ulogic_vector ; in2 : std_ulogic_vector) return std_ulogic_vector is
    variable r : std_ulogic_vector(in1'length-1 downto 0) := (others => '0');
  begin
    r(in2'length-1 downto 0) := in2; 
    return r;
  end pad_bits;
  
  function lleft_shift (value: std_ulogic_vector;  shift : integer) return std_ulogic_vector is
    variable r    : std_ulogic_vector(value'length-1 downto 0) := (others => '0');
  begin
    if not(value'length < shift) then
      r(r'length -1 downto shift ) := value(value'length -1 - shift downto 0);
    end if;
    return r;
  end lleft_shift;    

  function lright_shift (value: std_ulogic_vector;  shift : integer) return std_ulogic_vector is
    variable r : std_ulogic_vector(value'length-1 downto 0) := (others => '0');
  begin
    if not(value'length < shift) then
      r(r'length - 1 - shift downto 0) := value(value'length-1  downto shift);
    end if;
    return r;
  end lright_shift;

  function aright_shift (value: std_ulogic_vector;  shift : integer) return std_ulogic_vector is
    variable r : std_ulogic_vector(value'length-1 downto 0) := (others => value(value'left));
  begin
    if not(value'length < shift) then
      r(r'length - 1 - shift downto 0) := value(value'length-1 downto shift);
    end if;
    return r;
  end aright_shift;

  function reverse_ulogic( logic : in std_ulogic_vector) return std_ulogic_vector is
    variable r : std_ulogic_vector(logic'high downto logic'low);
  begin
    for i in logic'low to logic'high loop
      r(i) := logic(logic'high - i); 
    end loop;
    return r;
  end reverse_ulogic;

  function or_all( vect : in std_ulogic_vector) return std_ulogic is
    variable ret : std_ulogic := '0';
  begin
    for i in vect'high downto vect'low loop
      ret := vect(i) or ret;
    end loop;
    return ret;
  end or_all; 

  
end package body helpers;

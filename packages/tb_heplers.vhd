library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.instructions.all;
use work.helpers.all;

-- :) 
package tb_helpers is
  
  subtype word32 is std_ulogic_vector(31 downto 0);

--test_32 is a not ideal way of doing things, would remove but it is
--used in many of test benches. now  are now replaced 
--and test_signed that are not limited to only 32 bits
  procedure test_32( in1 : word32 ; in2 : word32 ; test_name : string);

  procedure test_1( in1 : std_ulogic ; in2 : std_ulogic ; test_name : string);
--new versions of test that are not a fixed legnth
  procedure test(in1 : std_ulogic_vector ; in2 : std_ulogic_vector ; test_name : string);
  procedure test_pad(in1 : std_ulogic_vector ; in2 : std_ulogic_vector ; test_name : string);
  procedure test_signed(in1 : std_ulogic_vector ; in2 : std_ulogic_vector ; test_name : string);

--Test a logical value against unsigned and signed integers
  procedure test_against_uint(logic_in : std_ulogic_vector; int_in : integer; test_name : string);
  procedure test_Against_sint(logic_in : std_ulogic_vector; int_in : integer; test_name : string);
  
 -- convert integers to 32 bit numbers
  function int2ulogic32( int : integer) return word32; --ungsigned integer
  function sint2ulog32( int : integer) return word32; --signed integer
  function int2ulog32pad(int : integer; pad_int : integer ) return word32; --adds padint number of 0s after number int 

  function ulogic_vector_image( img : std_ulogic_vector) return string;
end package tb_helpers;

package body tb_helpers is
  
  procedure test_32( in1 : word32 ; in2 : word32; test_name : string)  is
  begin
    if in1 = in2 then
      report "passed test " & test_name;
    else 
      report "failed test " & test_name;
    end if;
  end test_32;

  procedure test_1( in1 : std_ulogic ; in2 : std_ulogic ; test_name : string) is
  begin
    if in1 = in2 then
      report "passed test " & test_name;
    else 
      report "failed test " & test_name;
    end if;
  end test_1;

  procedure test( in1 : std_ulogic_vector ; in2 : std_ulogic_vector; test_name : string)  is
  begin
    if in1 = in2 then
      report "passed test " & test_name;
    else 
      report "failed test " & test_name & " on value:"& ulogic_vector_image(in1);
      
    end if;
  end test;

  procedure test_pad( in1 : std_ulogic_vector ; in2 : std_ulogic_vector; test_name : string)  is
  begin
    test(in1, pad_bits(in1,in2), test_name);
  end test_pad;
  
  procedure test_signed( in1 : std_ulogic_vector ; in2 : std_ulogic_vector; test_name : string)  is
  begin
    test(in1, std_ulogic_vector(signed_extend(in2,in1'length)), test_name);
  end test_signed;


  procedure test_against_uint(logic_in : std_ulogic_vector; int_in : integer; test_name : string) is
  begin
    test(logic_in, std_ulogic_vector(to_unsigned(int_in, logic_in'length)), test_name);
  end test_against_uint;

  procedure test_against_sint(logic_in : std_ulogic_vector; int_in : integer; test_name : string) is
  begin
    test(logic_in, std_ulogic_vector(to_signed(int_in, logic_in'length)), test_name);
  end test_Against_sint;



  function int2ulogic32( int : integer) return word32 is 
    variable r : word32;
  begin 
    r := std_ulogic_vector(to_unsigned(int, 32));
    return r;
  end int2ulogic32; 
  
  function sint2ulog32( int : integer) return word32 is
    variable r : word32;
  begin
    r := std_ulogic_vector(to_signed(int, 32));
    return r;
  end sint2ulog32;	  
  
  function int2ulog32pad( int : integer ; pad_int :integer) return word32 is 
    variable t : std_ulogic_vector(31 + pad_int downto 0);
    variable pad : std_ulogic_vector(pad_int-1 downto 0);
    variable r : word32;
  begin 
    pad := (others => '0');
    r := int2ulogic32(int);
    t := r & pad;
    r := t(32-1 downto 0);
    
    return r;
  end int2ulog32pad;

  
  function ulogic_vector_image( img : std_ulogic_vector) return string is
    variable temp : string (1 to 3);
    variable r : string(1 to img'length);
  begin
    for i in img'low to img'high loop
      temp := std_ulogic'image(img(i));
      r(img'high - i + 1) :=  temp(2);
    end loop;
    return r;
  end ulogic_vector_image;

end package body tb_helpers;

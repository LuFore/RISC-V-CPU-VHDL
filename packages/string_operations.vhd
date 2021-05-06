package string_operations is

  procedure split_string(str_in  : in string;
                         split_by: in character;
                         pos     : in natural;
                         str_out :out string);

  function find_in_string(str_in : in string;
                          find   : in character) return natural;

  function shrink_string (str_in : in string) return string;
  
end string_operations;

package body string_operations is


  procedure split_string(str_in : in string; split_by : in character; pos : in natural; str_out : out string) is
    variable pos_count    : natural := 0;
    variable lower_bound  : natural := 1;
  begin
    -- init the output
    str_out(1 to str_out'length) := (others => ' ');
    
    for i in 1 to str_in'length loop

      if str_in(i) = split_by then
        if pos_count = pos then
          str_out(1 to i-lower_bound) :=  str_in(lower_bound to i-1 );
          exit;
        else
          pos_count := pos_count + 1;
          lower_bound := i + 1;
        end if;
      end if;
      
    end loop;

    --report "Cannot split string" severity error;
    
  end split_string;

  

  function find_in_string(str_in : in string; find : in character) return natural is
    variable retval : natural := 0;
  begin
    for i in 1 to str_in'length loop
      if str_in(i) = find then
        retval := retval + 1;
      end if;
    end loop;
    return retval;

  end find_in_string;


  function shrink_string( str_in : in string) return string is
    --removes anything after the first space in a string
  begin
    for i in 1 to str_in'length loop
      if str_in(i) = ' ' then
        return str_in(1 to i-1);
      end if;
    end loop;
    
    --return split_string(str_in, ' ', 0);    
  end shrink_string;
  
  
    

  
  --function str2ulogic(str_in : in string) return std_ulogic_vector
  -- variable ret : std_ulogic_vector 
  
end string_operations;

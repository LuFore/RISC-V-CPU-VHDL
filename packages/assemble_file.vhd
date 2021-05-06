library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

library std;
use std.textio.all;

library work;
--use work.RISCV_32I.all;
use work.instructions.all;
use work.assembler.all;
use work.string_operations.all;

package assemble_file is

  -- for making binary files, can't yet be read
  procedure assemble32I (file_in : string; file_out : string);
  --produce binary file from assembly code
  procedure file_length (file_in : in string; length :out natural);
  --finds number of instructions in a file


  --assemble from a string eg "addi 1 1 1", must be lower case
  procedure assemble_string(current_str : in string;
                            good : out boolean;
                            inst : out instruction);


  --for use with JIT assembly 
  procedure lines_in_file (file_in : in string; length :out natural);
  --length returns the number of lines in a given file
  procedure get_inst_from_asm(file_in  : in string;
                              line_no : in positive;
                              inst :out instruction;
                              good :out boolean);
  --assembles a line from an assembly file, returns if the line was an
  --instruction with good and the std_ulogic instruction in inst 

end assemble_file;



package body assemble_file is
  
  --converts a string to an instruction enum
  function str_inst_value(str: in string) return instruction_all is
    --much like 'value, only returns i_not_found when not a valid instruction
    variable retval : instruction_all := i_not_found; 
  begin
    for i in iLUI to i_not_found loop
      if instruction_all'image(i) = ('i' & shrink_string(str)) then
        retval := i;
        exit;
      end if;
    end loop;
    --used for testing
    -- if retval = i_not_found then
    --   null;
    -- end if;
    return retval;
  end str_inst_value;

  
  procedure assemble_string(current_str : in string;
                            good : out boolean;
                            inst : out instruction) is

    -- new format: rd, rs1, rs2, imm (Same as greencard)
    -- old format: rs1, rs2, rd, imm
    
    variable substring   : string(1 to 32);
    variable current_inst : instruction_all;
    variable current_type : format;
    variable current_bin  : instruction; -- find the value of 

    variable number_of_words : natural;

    subtype uint5_t is natural range 0 to 31; -- c style name 
    variable rd  : uint5_t := 0;
    variable rs1 : uint5_t := 0;
    variable rs2 : uint5_t := 0;
    variable imm : integer := 0;

  begin
    --check that the length of the string being checked is sensible (>= 3)
    number_of_words := find_in_string(current_str, ' ');
    if number_of_words >= 3 then
      number_of_words := 3;
    end if;
    
    
    for count in 0 to number_of_words loop -- go through all words on the line      
      --assignment of a dynamicly sized string here might not be allowed
      split_string(current_str, ' ', count, substring); --find current word

      case count is
        when 0 => --first word will be an opcode
          --shrink string may not work as it might not be padded with spaces 
          current_inst := str_inst_value(substring);
          current_type := get_type(current_inst);

          rd := 0; --reset variables
          rs1:= 0;
          rs2:= 0;
          imm:= 0;
        when 1 => --find what the second word, an integer corresponds to
          case current_type is
            when R | I | U | J  =>
              rd := natural'value(substring);
            when S | B =>
              rs1  := integer'value(substring);
            when others =>
              null;
          end case;

        when 2 =>
          case current_type is
            when R | I  =>
              rs1 := integer'value(substring);
            when S | B  =>
              rs2  := integer'value(substring);
            when U | J =>
              imm := integer'value(substring);
            when others =>
              null;
          end case;
          
        when 3 =>
          case current_type is
            when R =>
              rs2  := integer'value(substring);
            when I | S | B =>
              imm := integer'value(substring); 
            when others =>
              null;
          end case;
          
        when others => -- do nothing if extra values detected
          null;
      end case;     
    end loop;

    if current_inst = i_not_found then
      good := false;
      inst := assemble(iADDI, 0, 0, 0, 0); --nop
    else
      good := true; 
      inst := assemble(current_inst, rs1, rs2, rd, imm);
    end if;    
  end assemble_string;


  

  procedure assemble32I (file_in : string; file_out : string) is
    file fileptr_in  : text open read_mode  is file_in;
    file fileptr_out : text open write_mode is file_out;
    variable line_access : line;
    variable line_save   : line;
    
    variable current_str : string(1 to 32); --large for the sake of it
    variable inst        : instruction;
    variable good        : boolean;
  begin

    loop
      exit when endfile(fileptr_in); -- exit when no data found
      readline(fileptr_in, line_access);

      current_str := (others => ' ');


      if line_access'length <= 32 then 
        read(line_access, current_str(1 to line_access'length));
      elsif line_access'length /= 0 then 
        read(line_access, current_str);
      end if;
      assemble_string(current_str, good, inst);

      --convert to std_ulogic then write to file line as integer (not a string of integer)
      if good = true then
        write(line_save, to_bitvector(inst)) ;
      end if;
      
    end loop;
    if line_save /= null then
      report file_in & " compiled to " & file_out severity note;
      writeline(fileptr_out, line_save);
    end if;
  end assemble32I;

  -- function get_inst_from_file( file_in : in string; inst_no : in natural) return instruction is
  --   file fileptr_in  : text open read_mode  is file_in;
  --   variable line_access : line;
  -- begin
  --   readline(fileptr_in, line_access);
  
  
  -- end get_inst_from_file;
    
  procedure file_length (file_in : in string; length :out natural) is
    --finds number of instructions in a file
    file fileptr_in  : text open read_mode  is file_in;
    variable line_access : line;
  begin
    readline(fileptr_in, line_access);
    length :=  (line_access'length /32);
  end file_length;

  procedure lines_in_file (file_in : in string; length :out natural) is
    --finds number of instructions in a file
    file fileptr_in  : text open read_mode  is file_in;
    variable line_access : line;
    variable i           : positive := 1;
  begin
    
    loop
      readline(fileptr_in, line_access);
      exit when endfile(fileptr_in); -- exit when no data found
      i := i + 1;
    end loop;
    length := i;
  end lines_in_file;

  
  procedure get_inst_from_asm(file_in  : in string;
                              line_no : in positive;
                              inst :out instruction;
                              good :out boolean) is
    file fileptr_in  : text open read_mode  is file_in;
    variable line_access : line;
    variable current_str : string(1 to 32); --large for the sake of it
    variable inst0       : instruction; -- done for clearer API
  begin -- I don't know why but it returns the instruction the wrong way around

    for i in 1 to line_no loop
      readline(fileptr_in, line_access);
    end loop;

    current_str := (others => ' ');

    if line_access'length <= 32 then 
      read(line_access, current_str(1 to line_access'length));
    elsif line_access'length /= 0 then 
      read(line_access, current_str);
    end if;
    assemble_string(current_str, good, inst);
    
    --inst := reverse_ulogic(inst0);--ulogic_vector_image(inst0);
    
  end get_inst_from_asm;
 
end assemble_file;  

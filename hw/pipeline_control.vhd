library ieee;
use ieee.std_logic_1164.all;

library work;
use work.instructions.all;
use work.assembler.get_type;

-- This will fail the testbench, but that is ok as the testbench is wrong and
-- it works as a part of the hart

entity pipeline_control is
  generic(XLEN : integer := 32-1);
  port(
    clk, rst : in std_ulogic;

    bubble   :out std_ulogic;
    
    rs1_in,rs2_in         : in std_ulogic_vector(XLEN downto 0);
    result_in, load_in    : in std_ulogic_vector(XLEN downto 0);
    

    rs1_out, rs2_out      :out std_ulogic_vector(XLEN downto 0);
    
    inst_in               : in instruction;
    inst_enum_in          : in instruction_all;

    next_inst             : in instruction;
    next_inst_enum        : in instruction_all
    );
end pipeline_control;

architecture arch of pipeline_control is
  alias rd        : std_ulogic_vector(4 downto 0) is inst_in(11 downto 7);

  signal bubble_rs1, bubble_rs2 : std_ulogic;
  signal bubble_rs1_save, bubble_rs2_save : std_ulogic := '0';-- bubbles should always last 2
 --                                                             -- clock cycles, this saves that
  signal bypass1_rs1, bypass1_rs2, bypass2_rs1, bypass2_rs2, bypass3_rs1, bypass3_rs2 : std_ulogic;

--yet to be rst
  signal rd_save1  , rd_save2   : std_ulogic_vector(5-1 downto 0)    := (others => '0');
  signal enum_save1, enum_save2 : instruction_all := i_not_found;
  signal type_save1, type_save2 : format         := S; --type with no rd
  signal val_save : std_ulogic_vector(XLEN downto 0); 
  
  procedure bypass_needed(signal rs1_pass, rs2_pass   :out std_ulogic;
                          prior_type, post_type : in format;
                          prior_enum, post_enum : in instruction_all;
                          prior_inst            : in instruction;
                          post_rd : in std_ulogic_vector(4 downto 0)) is


    variable bypass_now : boolean := false;
  begin
    if post_rd /= "00000" then --/= to avoid triggering on unkown states
      --check if type has rd by elementing types without
      bypass_now := true;
    end if;

    if (post_type = S) or (post_type = B) or --types with no rd
      (prior_type = U) or (prior_type = J) or--types with no rs1 or rs2
      (prior_type = other) or (post_type = other)--types that are not valid
    then
      bypass_now := false;
    end if;

    if bypass_now = true then
      if prior_inst(19 downto 15) = post_rd then --check rs1
        rs1_pass <= '1';
      else
        rs1_pass <= '0';
      end if;
      
      if (prior_inst(24 downto 20) = post_rd) and (prior_type /= I) then --check for rs2
        rs2_pass <= '1';
        bypass_now := true;
      else
        rs2_pass <= '0';
      end if;
    else  
      --reset bubble status 
      rs1_pass <= '0';
      rs2_pass <= '0';
    end if;    
  end bypass_needed;
  
begin
  process(clk) is
    variable bubble_now : boolean := false;

    --init values are picked so it will by default not trigger
    variable current_type: format := S; --type with no rd
    variable future_type : format := U; --type with no rs
  begin
    
    if rst = '0' then
      bypass1_rs1 <= '0';
      bypass1_rs2 <= '0';
      bypass2_rs1 <= '0';
      bypass2_rs2 <= '0';
      bypass3_rs1 <= '0';
      bypass3_rs2 <= '0';
      
      bubble_rs1<= '0';
      bubble_rs2<= '0';
      bubble <= '0';

      rd_save1 <= (others => '0');
      rd_save2 <= (others => '0');
      enum_save1 <= i_not_found;
      enum_save2 <= i_not_found;
      type_save1 <= S;
      type_save2 <= S;
      val_save <= (others => '0');
      
    elsif rising_edge(clk) then
      
      --finding if bubble could be needed for future instructions
      --using bubble_now is easier to read than a mega if statement
      future_type := get_type(next_inst_enum);

      if (inst_enum_in >= iLB) and (inst_enum_in <= ILHU) and (rd /= "00000") then
        bubble_now := true;
      else
        bubble_now := false;
      end if;
      
      if (future_type = U) or (future_type = J)then --ignore types without
                                                    --rs1 or 2
        bubble_now := false;
      end if;

      if bubble_now = true then 
        if next_inst(19 downto 15) = rd then --check rs1
          bubble_rs1 <= '1';
          -- save for next clk 
          bubble_rs1_save <= '1';

        else
          bubble_rs1 <= '0';
          bubble_now := false;
        end if;
        
        if (next_inst(24 downto 20) = rd) and (future_type /= I) then --check for
                                                                      --rs2 and rs2
          bubble_rs2 <= '1';
          bubble_rs2_save <= '1'; -- save for next clk

          bubble_now := true;
        else
          bubble_rs2 <= '0';
        end if;
      end if;

      if bubble_now = false then 
        --reset bubble status
        bubble <= '0';
        bubble_rs1 <= '0';
        bubble_rs2 <= '0';
      else
        bubble <= '1';
      end if;
      --memory state for bubble, I want to get rid of it
       if (Bubble_rs2_save or bubble_rs1_save) = '1' then
         Bubble_rs1_save  <= '0'; -- clear bubble save
         Bubble_rs2_save  <= '0'; -- clear bubble save

         bubble_rs2 <= bubble_rs2_save;
         bubble_rs1 <= bubble_rs1_save;
       end if;
      
      --FIND IF BYPASS IS REQUIRED
      current_type := get_type(inst_enum_in);
      if bubble_now = false then
        --sort out if bypass is needed for first second or last values
        bypass_needed(bypass1_rs1, bypass1_rs2,
                      future_type, current_type,
                      next_inst_enum, inst_enum_in,
                      next_inst, rd);

        bypass_needed(bypass2_rs1, bypass2_rs2,
                      future_type, type_save1,
                      next_inst_enum, enum_save1,
                      next_inst, rd_save1);

        bypass_needed(bypass3_rs1, bypass3_rs2,
                      future_type, type_save2,
                      next_inst_enum, enum_save2,
                      next_inst, rd_save2);
      end if;
      -- save state for last 
      rd_save1 <= rd;
      rd_save2 <= rd_save1;
      val_save <= load_in;
      enum_save1 <= inst_enum_in;
      enum_save2 <= enum_save1;
      
      type_save1 <= current_type;
      type_save2 <= type_save1;

      
    end if;
    
  end process;  
  
  rs1_out <=  load_in   when bubble_rs1  = '1' else
              result_in when bypass1_rs1 = '1' else
              load_in   when bypass2_rs1 = '1' else
              val_save  when bypass3_rs1 = '1' else
              rs1_in;
  
  rs2_out <=  load_in   when bubble_rs2  = '1' else
              result_in when bypass1_rs2 = '1' else
              load_in   when bypass2_rs2 = '1' else
              val_save  when bypass3_rs2 = '1' else
              rs2_in;

end arch;

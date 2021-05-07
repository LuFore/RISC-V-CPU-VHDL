library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.instructions.all;

package assembler is


  --"bad" types from RISCV_32I
  subtype reg_address is integer range 0 to 31;
  subtype immediate is integer range 0 to (2**20);

  subtype opcode7 is std_ulogic_vector(6 downto 0); 
  
  function assemble(inst : instruction_all;
                    rs1 : reg_address;
                    rs2 : reg_adDress;
                    rd : reg_address;
                    imm : integer)
    return instruction;
  function get_type(inst : instruction_all) return format;

  function return_OP(newop :opcode) return opcode7; 
  
  function find_inst_OP(inst :instruction_all) return opcode;

end package assembler;



package body assembler is
  function assemble(inst : instruction_all;
                    rs1 : reg_address;
                    rs2 : reg_address;
                    rd : reg_address;
                    imm : integer)
    return instruction is
    variable inst_out : instruction;
    variable inst_format : format;
    variable temp_vector : std_ulogic_vector(31 downto 0);
    
    alias inst_rd  : std_ulogic_vector(4 downto 0) is inst_out(11 downto 7);
    alias inst_rs1 : std_ulogic_vector(4  downto 0) is inst_out(19 downto 15);
    alias inst_rs2 : std_ulogic_vector(4  downto 0) is inst_out(24 downto 20);
    alias inst_op  : std_ulogic_vector(6  downto 0) is inst_out(6 downto 0);
    alias funct3   : std_ulogic_vector(2  downto 0) is inst_out(14 downto 12);
    alias funct7   : std_ulogic_vector(6  downto 0) is inst_out(31 downto 25);
    alias funct12  : std_ulogic_vector(11 downto 0)is inst_out(31 downto 20);
    
  begin

    inst_rd := std_ulogic_vector(to_unsigned(rd, 5));
    inst_rs1 := std_ulogic_vector(to_unsigned(rs1, 5));
    inst_rs2 := std_ulogic_vector(to_unsigned(rs2, 5));
    inst_op :=  return_OP(find_inst_OP(inst));
    inst_format := get_type(inst); -- find the type

    if (inst <= iCSRRCI) and (inst >= iCSRRWI ) then --special case for when rs1 is uimm
      inst_format := I;
    end if;
    
    --All this information is from page 130 of the RISC-V spec
    
    case inst_format is
      when R =>
        funct7 := (others => '0');
        funct3 := (others => '0');
        case inst is
          when iADD =>
            funct7 := (others => '0');
            funct3 := "000";
          when iSUB =>
            funct7 := "0100000";
          when iSLL =>
            funct3 := "001";
          when iSLT =>
            funct3 := "010";
          when iSLTU =>
            funct3 := "011";
          when iXOR =>
            funct3 := "100";
          when iSRL =>
            funct3 := "101";
          when iSRA =>
            funct3 := "101";
            funct7 := "0100000";
          when iOR =>
            funct3 := "110";
          when iAND =>
            funct3 := "111";
          when others =>
            report "not R type" severity error; -- these errors should never
                                                -- trigger, only for debugging
        end case;
      when I =>
        --set imm
        temp_vector := std_ulogic_vector(to_signed(imm, 32));
        inst_out(31 downto 20) :=  temp_vector(11 downto 0);
        funct3 := (others => '0');
        
        case inst is
          when iJALR=> null;
          when iLB  => null;
          when iLH  => funct3 := "001";
          when iLW  => funct3 := "010";
          when iLBU => funct3 := "100";
          when iLHU => funct3 := "101";
          when iADDI=> null;
          when iSLTI=> funct3 := "010";
          when iSLTIU=>funct3 := "011";
          when iXORI=> funct3 := "100";
          when iORI => funct3 :="110";
          when iANDI=> funct3 := "111";
          -- shamt commands, these overwrite the top 7 bits of imm
          when iSLLI =>
            funct7 := (others => '0');
            funct3 := "001";
          when iSRLI =>
            funct7 := (others => '0');
            funct3 := "101";
          when iSRAI =>
            funct7 := "0100000";
            funct3 := "101";
          --CSR commands
          when iCSRRW  => funct3 := "001";
          when iCSRRS  => funct3 := "010";
          when iCSRRC  => funct3 := "011";
          when iCSRRWI => funct3 := "101";
          when iCSRRSI => funct3 := "110";
          when iCSRRCI => funct3 := "111";
          -- Privledged commands
          when iMRET =>
            inst_out(19 downto 7) := (others => '0');  
            funct12 := "001100000010";
          when iWFI =>
            inst_out(19 downto 7) := (others => '0');  
            funct12 := "000100000101";
                             
          when others =>
            report "not I type" severity error;
        end case;
        
      when S =>
        temp_vector(11 downto 0) := std_ulogic_vector(to_signed(imm, 12));
        inst_rd := temp_vector(4 downto 0);
        funct7  := temp_vector(11 downto 5);

        case inst is
          when iSB => funct3 := "000";
          when iSH => funct3 := "001";
          when iSW => funct3 := "010";
          when others => report "not S type" severity error;
        end case;
        
      when B => 
        temp_vector(12 downto 0) := std_ulogic_vector(to_signed(imm, 13));
--does not use bottom bit
        inst_out(7) := temp_vector(12);
        inst_out(11 downto 8) := temp_vector(4 downto 1);
        inst_out(30 downto 25) := temp_vector(10 downto 5);
        inst_out(31) := temp_vector(12);
        
        case inst is
          when iBEQ => funct3 := "000";
          when iBNE => funct3 := "001";
          when iBLT => funct3 := "100";
          when iBGE => funct3 := "101";
          when iBLTU=> funct3 := "110";
          when iBGEU=> funct3 := "111";
          when others => report "not B type" severity error;
        end case;
        
      when U =>
            temp_vector(31 downto 0) := std_ulogic_vector(to_unsigned(imm, 32));
            inst_out(31 downto 12) := temp_vector(31 downto 12);
            --no case statement needed, the two U types differ only in
            --Opcode
      when J =>
            temp_vector(20 downto 0) := std_ulogic_vector(to_unsigned(imm, 21));
            inst_out(19 downto 12) := temp_vector(19 downto 12);
            inst_out(20) := temp_vector(11);
            inst_out(30 downto 21) := temp_vector(10 downto 1);
            inst_out(31) := temp_vector(20);
            --no case statement needed, only one J type
          when other =>
            case inst is
              when iFENCE =>
                report "ifence not yet implimented in assembler" severity error;
              when iECALL =>
                inst_out(31 downto 7) := (others => '0');
              when iEBREAK =>
                inst_out(31 downto 7) := (others => '0');
                inst_out(20) := '1';
              when others =>
                report "not an OPCODE yet implimented in assembler" severity error;
            end case;
            
        end case;
            inst_op := return_OP(find_inst_OP(inst));
            return inst_out;
  end assemble;

  function get_type(inst : instruction_all) return format is
    variable r : format;
  begin
    case inst is
      when iLUI to iJAL =>
        r := U;
      when iJALR =>
        r := I;
      when iBEQ to iBGEU =>
        r := B;
      when iLB to iLHU =>
        r := I;
      when iSB to iSW =>
        r := S;
      when iADDI to iANDI =>
        r := I;
      when iSLLI to iSRAI =>
        r := I;
      when iADD to iAND =>
        r := R;
      when iFENCE to iEBREAK =>
        r := other;
      when iCSRRW to iCSRRC =>
        r := I;
      when iCSRRWI to iCSRRCI =>--technically I type with no rs
        r := U; --U type so do not trigger a bypass or bubble as RS1 not used
      when iMRET to iWFI =>
        r := I; --technically type i, rs1 and rd are always 0 so doesn't
                --matter for pipelining        
      when others => -- are I types but with no rs1
        r := other; 
        --report "invalid opcode" severity error; --mostly used for debugging
    end case;

    return r;
  end get_type;

  function return_OP(newop : opcode) return opcode7 is
    variable r : opcode7;
    variable count : integer := 0;
  begin
    for i in opcode range LOAD to op80b loop
      if newop = i then
        r(6 downto 2) := std_ulogic_vector(to_unsigned(count, 5));
        r(1 downto 0) := "11";
        return r;
      end if;
      count := count + 1;
    end loop;

    r(1 downto 0) := "00";
    report "OPcode not valid" severity warning;
    return r;
  end return_OP;

  function find_inst_OP(inst :instruction_all) return opcode is
    variable r : opcode;
  begin
    case inst is
      when iLUI  => r := LUI;
      when iAUIPC=> r := AUIPC;
      when iJAL  => r := JAL;
      when iJALR => r := JALR;
      when iBEQ to iBGEU =>
        r := BRANCH;
      when iLB to iLHU =>
        r := LOAD;
      when iSB to iSW =>
        r := STORE;
      when iADDI to iSRAI =>
        r := OP_IMM;
      when iADD to iAND =>
        r := OP;
      when iFENCE => r := MISC_MEM;
      when iECALL to iEBREAK => r := SYSTEM;
      when iCSRRW to iCSRRCI => r := SYSTEM;
      when iMRET to iWFI => r := system;

      when others => --i_not_found =>
        null;--mostly used for debugging
        --report "not a valid instruction" severity error;
    end case;
    return r;
  end find_inst_OP;
  
end package body assembler;             

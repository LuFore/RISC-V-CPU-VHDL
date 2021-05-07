library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


package instructions is

  subtype instruction is std_ulogic_vector(32-1 downto 0);
  
  type instruction_all is (
    --32I
    iLUI, iAUIPC, iJAL, iJALR, iBEQ, iBNE, iBLT, iBGE, iBLTU, iBGEU, iLB, iLH,
    iLW, iLBU, iLHU, iSB, iSH, iSW, iADDI, iSLTI, iSLTIU, iXORI, iORI, iANDI,
    iSLLI, iSRLI, iSRAI, iADD, iSUB, iSLL, iSLT, iSLTU, iXOR, iSRL, iSRA, iOR,
    iAND, iFENCE, iECALL, iEBREAK, 
    --ziCSR
    iCSRRW, iCSRRS, iCSRRC, iCSRRWI, iCSRRSI, iCSRRCI,
    --Machine-Mode Privileged Instructions 3.3 of priv spec
    iMRET, iWFI,
    --Blank instruction
    i_not_found
    );

  type format is (R, S, I, B, U, J, other); -- type of instruction

  type opcode is
    (LOAD, LOAD_FP, custom_0, MISC_MEM, OP_IMM, AUIPC, OP_IMM_32, op48b, STORE, STORE_FP,
     custom_1, AMO, OP, LUI, OP_32, op64b, MADD, MSUB, NMSUB, NMADD, OP_FP, reserved0,
     custom_2_rv128, op48b0, BRANCH, JALR, reserved1, JAL, SYSTEM, reserved2,
     custom_3_rv128, op80b, op_not_found
     );

  function get_instruction( inst: instruction) return instruction_all;

  function get_opcode(code : std_ulogic_vector(7-1 downto 0)) return opcode;

  function get_instruction_all( inst : instruction) return instruction_all;

  function get_instruciton_zcsr( inst : instruction) return instruction_all;

end instructions;


package body instructions is
  subtype opcode7 is std_ulogic_vector(7-1 downto 0); --private

  function get_instruction( inst: instruction) return instruction_all is
    variable inst_enum : instruction_all := i_not_found;
  begin
    inst_enum := get_instruction_all(inst);
    if inst_enum = i_not_found then
      inst_enum := get_instruciton_zcsr(inst);
    end if;
  end get_instruction;

  function get_opcode(code : opcode7) return opcode is
    --returns an opcode enum type from a 7 bit vector
    variable count : unsigned(4 downto 0) := (others => '0'); -- only 5 bits of opcode are used
    variable r : opcode := op_not_found; --deafults to an error state    
  begin
    if code(1 downto 0) /= "11" then
      r := op_not_found;	--check that it is a valid opcode
    else 
      for i in opcode range LOAD to op80b loop -- go through all opcodes
        if code(6 downto 2) = std_ulogic_vector(count) then 
          r := i 	;
        end if;
        count := count +1;--increment count, this is the value of the type opcode
      end loop;
    end if;
    return r;
  end get_opcode;

  function get_instruction_all( inst : instruction) return instruction_all is    
    variable inst7: opcode ;
    alias funct3  : std_ulogic_vector(2 downto 0) is inst(14 downto 12);
    alias funct7  : std_ulogic_vector(6 downto 0) is inst(31 downto 25);

  begin
    
    inst7 := get_opcode(inst(7-1 downto 0)); -- find the opcode

    case inst7 is
      --find commands that are defined soley by their opcode
      when LUI =>		return iLUI;
      when AUIPC => 	        return iAUIPC;
      when JAL =>		return iJAL;

      -- find commands that require funct3
      when JALR =>
        if funct3 = "000" then
          return iJALR;
        end if;

      when BRANCH =>
        case funct3 is 
          when "000" => return iBEQ;
          when "001" => return iBNE;
          when "100" => return iBLT;
          when "101" => return iBGE;
          when "110" => return iBLTU;
          when "111" => return iBGEU;
          when others => report "Opcode: BRANCH invalid funct3" severity warning;

        end case;
      when LOAD =>
        case funct3 is 
          when "000" => return iLB;
          when "001" => return iLH;
          when "010" => return iLW;
          when "100" => return iLBU; 
          when "101" => return iLHU;
          when others => report "Opcode: LOAD invalid funct3" severity warning;
        end case;
      when STORE =>
        case funct3 is
          when "000" => return iSB;
          when "001" => return iSH;
          when "010" => return iSW;
          when others => report "Opcode: STORE invalid funct3" severity warning;
        end case;
      when OP_IMM =>
        case funct3 is 
          when "000" => return iADDI;
          when "010" => return iSLTI;
          when "011" => return iSLTIU;
          when "100" => return iXORI;
          when "110" => return iORI;
          when "111" => return iANDI;
          -- following require func7
          when "001" => 
            if funct7 = "0000000" then	 --might want to put an error on all non valid calls				
              return iSLLI;
            end if;

          when "101" =>
            if funct7 = "0000000" then
              return iSRLI;
            elsif funct7 = "0100000" then
              return iSRAI;
            end if;
          when others => report "Opcode: OP_IMM invalid funct3" severity warning;

        end case;

      when OP =>
        case funct3 is
          when "000" =>
            if funct7 = "0100000" then
              return iSUB;
            elsif funct7 = "0000000" then
              return iADD;
            end if;
          when "001" =>
            if funct7 = "0000000" then
              return iSLL;
            end if;						
          when "010" =>
            if funct7 = "0000000" then
              return iSLT;
            end if;					
          when "011" =>
            if funct7 = "0000000" then
              return iSLTU;
            end if;				
          when "100" =>
            if funct7 = "0000000" then
              return iXOR;
            end if;				
          when "101" =>
            if funct7 = "0000000" then
              return iSRL;
            elsif funct7 = "0100000" then
              return iSRA;
            end if;		
          when "110" =>
            if funct7 = "0000000" then
              return iOR;
            end if;				
          when "111" =>
            if funct7 = "0000000" then
              return iAND;
            end if;			
            
          when others => report "Opcode: OP invalid funct3" severity warning;
        end case;
        
      when MISC_MEM =>
        if funct3 = "000" then
--All fences are the same - just causes a jump to next instruction, clearing the 
--Pipeline and making double sure memory ordering is assured
          return iFENCE; 
        end if;

      when SYSTEM =>
        case funct3 is
          when "000" => --PRIV system instsructions
            if unsigned(inst(19 downto 7)) = to_unsigned(0,1)  then
              case inst(31 downto 20) is
                when "000000000000" =>
                  return iECALL;
                when "000000000001" =>
                  return iEBREAK;
                --ITR instructions
                when "001100000010" =>
                  return iMRET;
                when "000100000101" =>
                  return iWFI;
                when others =>
                  null;
              end case;
            end if;

          --csr instructions
          when "001" =>
            return iCSRRW;
          when "010" =>
            return iCSRRS;
          when "011" =>
            return iCSRRC;
          when "101" =>
            return iCSRRWI;
          when "110" =>
            return iCSRRSI;
          when "111" =>
            return iCSRRCI;
          when others =>
            null;
        end case;
      when others => 
        report "Invalid instruction" severity error;
        return i_not_found;
    end case; 
    return i_not_found;
  end get_instruction_all;


  function get_instruciton_zcsr( inst : instruction) return instruction_all is

    alias opcode_al  : std_ulogic_vector(6 downto 0) is inst(7-1 downto 0);
    alias funct3  : std_ulogic_vector(2 downto 0) is inst(14 downto 12);
    
  begin  
    if opcode_al = "1110011" then --check opcode is SYSTEM 
      case funct3 is
        when "001" =>
          return iCSRRW;
        when "010" =>
          return iCSRRS;
        when "011" =>
          return iCSRRC;
        when "101" =>
          return iCSRRWI;
        when "110" =>
          return iCSRRSI;
        when "111" =>
          return iCSRRCI;
        when others =>
          null;
      end case;
    end if;
    return i_not_found;
    
  end get_instruciton_zcsr;
  

end package body instructions;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-- NO LONGER USED


-- :) 
package riscv_32i is
--notes
--move all general utility functions to their own package
  constant opcode_len : integer := (7-1); --size of opcodes
  constant inst_width : integer := (32-1);	--size of instruction
  
  
 --opcode	
--  type instruction32I is (iLUI, iAUIPC, iJAL, iJALR, iBEQ, iBNE, iBLT, iBGE, iBLTU, iBGEU, iLB, iLH, iLW, iLBU, iLHU, iSB, iSH, iSW, iADDI, iSLTI, iSLTIU, iXORI, iORI, iANDI, iSLLI, iSRLI, iSRAI, iADD, iSUB, iSLL, iSLT, iSLTU, iXOR, iSRL, iSRA, iOR, iAND, iFENCE, iECALL, iEBREAK, i_not_found); -- all 32I instructions, i to avoid key words :)
  -- could add extra "wrong" instruction to aviod returning nothing

  subtype reg_address is integer range 0 to inst_width;
  subtype immediate is integer range 0 to (2**20);
  
  --types to make returning logic vectors cleaner
  subtype opcode7 is std_ulogic_vector(opcode_len downto 0);
  subtype instruction is std_ulogic_vector(inst_width downto 0);


--	function use_opcode(code : opcode) return opcode7;

end package riscv_32i;

package body riscv_32i is
  
    
      
end package body riscv_32i;


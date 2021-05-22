library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.instructions.all;
use work.csr_info.all;
use work.helpers.all; 
use work.memory_defs.all;

entity zcsr is
--absolutely massive, stores the control status registers, detects and performs
--traps
  generic(
    XLEN : positive    := 32-1;
    Hardware_thread_ID : natural := 0);

  port(
    clk, rst : in std_ulogic;

    inst_in	     : in instruction; 
    inst_enum_in     : in instruction_all; 

    rs1_in           : in std_ulogic_vector(XLEN downto 0); 
    result_out       :out std_ulogic_vector(XLEN downto 0);
    
    acc_me           :out std_ulogic;
    branch_in        : in std_ulogic;

    PC_in            : in std_ulogic_vector(XLEN downto 0);
    PC_out           :out std_ulogic_vector(XLEN downto 0);
    trap_PC          :out std_ulogic; -- high when PC jump as a ressult of trap
    external_itr_hw  : in std_ulogic; --exposed signals for triggering interrupts 
    external_itr_sw  : in std_ulogic; --to be memory mapped to cache
    external_itr_tm  : in std_ulogic  --memory mapped timer
    );  
end zcsr;

architecture arch of zcsr is
  
  alias rs1_add : std_ulogic_vector(5-1 downto 0) is inst_in(19 downto 15);

  alias address : std_ulogic_vector(11 downto 0) is inst_in(31 downto 20);
  alias uimm    : std_ulogic_vector(5-1 downto 0)  is inst_in(20-1 downto 15);
  alias rd      : std_ulogic_vector(5-1 downto 0)  is inst_in(11 downto 7);
  
  subtype ulogic_XLEN is std_ulogic_vector(XLEN downto 0);
  subtype ulogic_address is std_ulogic_vector(12-1 downto 0);  
  --found in page 8 of the priviliedged spec
  type XLEN_array is array(natural range <>) of ulogic_XLEN;

  --Break up CSR so not all 4096 registers need to be implimented
  -- page 11 of the priv spec in table 2
  signal read_only_csrs : XLEN_array (VENDOR_ID_ADDRESS to THREAD_ID_ADDRESS);
  signal trap_setup1    : XLEN_array (mstatus to misa); --medeleg and mideleg removed 
  signal trap_setup2    : XLEN_array (mie to mcounteren); --as they are only
                                                          --for S + U modes
  signal trap_handle    : XLEN_array (mscratch to mip);

  signal pmpcfg         : XLEN_array (pmpcfg_bottom to pmpcfg_top);
  signal pmpaddr        : XLEN_array (pmpaddr_bottom to pmpaddr_top);

  signal mcycle_reg     : XLEN_array (mcycle  to mcycle); -- 1 long array
  signal timers1        : XLEN_array (minstret to mhpmcounter_top);
  signal mcycleh_reg    : XLEN_array (mcycleh to mcycleh);
  signal timers2        : XLEN_array (minstreth to mhpmcounterh_top);

  signal mcountinhibit_reg : XLEN_array (mcountinhibit to mcountinhibit);
  signal mhmevent        : XLEN_array (mhmevent_bottom to mhmevent_top);

  --used to save rst and branch for instructions retired counter
  type post_branch_states is --reset is not always on rising edge so
                             --post_rst_imm is included so it does not skip 5
    (post_rst5, post_rst4, post_branch,
     post_rst3, post_rst2, post_rst1, normal_operation);
  signal branch_rst_save: post_branch_states;--used to save values 

  --Will stall CPU when high
  signal waiting_for_itr : boolean; 
  
--useful aliases for ease of use
  alias mtvec_reg   : ulogic_XLEN is trap_setup2(mtvec);
  alias mip_reg     : ulogic_XLEN is trap_handle(mip);
  alias mie_reg     : ulogic_XLEN is trap_setup2(mie);
  alias mstatus_reg : ulogic_XLEN is trap_setup1(mstatus);
  alias inhibit_reg : ulogic_XLEN is mcountinhibit_reg(mcountinhibit);
  
begin
  process(clk)
    
    subtype address_type is natural range 0 to (2**12);
    variable address_int : address_type;
    variable write_csr   : boolean := false;
    variable temp_read   : ulogic_XLEN := (others => '0');

    variable result         : ulogic_XLEN;
    variable algiment_check : unsigned(1 downto 0);
    variable trap           : boolean := false;
    variable itr            : boolean := false;
    variable csr_read       : std_ulogic := '0'; 
    
    variable mcause_set     : unsigned(XLEN downto 0); 

    --correct formatting for saving to register mcause
    function trap_mcause(cause :in natural) return unsigned is
    begin
      return '0' & to_unsigned(cause, XLEN);
    end trap_mcause;

    function itr_mcause(cause : in natural) return unsigned is
    begin
      return '1' & to_unsigned(cause, XLEN);
    end itr_mcause;

    -- function to select correct csr from the split up list, changes numbers
    -- of regs from 4096 to < 100 
    procedure csr_nochecks( csr_add_int   : in address_type;
                            write_val     : in ulogic_XLEN;
                            out_val       :out ulogic_XLEN;
                            write_select  : in boolean) is
    begin
      case csr_add_int is
        when VENDOR_ID_ADDRESS to THREAD_ID_ADDRESS =>          
          --read only
          if write_select = true then
            trap := true;
            mcause_set := trap_mcause(7);
          end if;
          out_val := read_only_csrs(csr_add_int);

        when mstatus to misa =>
          if write_select = true then
            trap_setup1(csr_add_int) <= write_val;
          end if;
          out_val := trap_setup1(csr_add_int);

        when mie to mcounteren =>
          if write_select = true then
            trap_setup2(csr_add_int) <= write_val;
          end if;
          out_val := trap_setup2(csr_add_int);
          
        when mscratch to mtval =>
          if write_select = true then
            trap_handle(csr_add_int) <= write_val;
            null;
          end if;
          out_val := trap_handle(csr_add_int);

        when mip => --handle special case for mip as many of these registers
          --are hardwired externally, this will not write to them
          if write_select = true then --3.1.14 of v1.10 spec
            mip_reg(2 downto 0) <= write_val(2 downto 0);
            mip_reg(6 downto 4) <= write_val(6 downto 4);
            mip_reg(10 downto 8) <= write_val(10 downto 8);
            mip_reg(XLEN downto 11) <= write_val(XLEN downto 11);
          end if;
          out_val := trap_handle(csr_add_int);
          
        when pmpcfg_bottom to pmpcfg_top =>
          if write_select = true then
            pmpcfg(csr_add_int) <= write_val;
          end if;
          out_val := pmpcfg(csr_add_int);

        when pmpaddr_bottom to pmpaddr_top =>
          if write_select = true then
            pmpaddr(csr_add_int) <= write_val;
          end if;
          out_val := pmpaddr(csr_add_int);

        when mcycle =>
          if write_select = true then
            mcycle_reg(csr_add_int) <= write_val;
          end if;
          out_val := mcycle_reg(csr_add_int);

        when minstret to mhpmcounter_top =>
          if write_select = true then
            timers1(csr_add_int) <= write_val;
          end if;
          out_val := timers1(csr_add_int);

        when mcycleh to mcycleh =>
          if write_select = true then
            mcycleh_reg(csr_add_int) <= write_val;
          end if;
          out_val := mcycleh_reg(csr_add_int);

        when minstreth to mhpmcounterh_top =>
          if write_select = true then
            timers2(csr_add_int) <= write_val;
          end if;
          out_val := timers2(csr_add_int);

        when mcountinhibit to mcountinhibit =>
          if write_select = true then
            mcountinhibit_reg(csr_add_int) <= write_val;
          end if;
          out_val := mcountinhibit_reg(csr_add_int);

        when mhmevent_bottom to mhmevent_top =>
          if write_select = true then
            mhmevent(csr_add_int) <= write_val;
          end if;
          out_val := mhmevent(csr_add_int);

        when others =>
          if write_select = true then
            trap := true;
            mcause_set := trap_mcause(7);
          end if;
          
          out_val := (others => '0');
      end case;
    end csr_nochecks;
    
    function WARL_legal(data : in ulogic_XLEN; address : in address_type) return boolean is
      --check to see if WARL write is legal
      variable r : boolean;
    begin
      case address is
        when misa =>
          if (data and misa_mask) /= (misa_rst and misa_mask) then
            trap := true;
            mcause_set := trap_mcause(6);
            return false;
          end if;

        when mstatus =>
          if (data and mstatus_mask) /= (mstatus_rst and mstatus_mask) then
            trap := true;
            mcause_set := trap_mcause(6);
            return false;
          end if;

        when mie =>
          if (data and mie_mask) /= (mie_rst and mie_mask) then
            trap := true;
            mcause_set := trap_mcause(6);
            return false;
          end if;

        when mip =>
          --read only bits can be changed outside of zcsr
          --so the register is used opposed to the default rst value
          if (data and mip_mask) /= (trap_handle(mip) and mie_mask) then
            trap := true;
            mcause_set := trap_mcause(6);
            return false;
          end if;
          
        when others =>
          return true;
      end case;       
      return true;
    end WARL_legal;
    
    procedure csr_nochecks(csr_add_int : in address_type;
                           out_val     :out ulogic_XLEN)is
      variable nothing : ulogic_XLEN;
    begin
      csr_nochecks(csr_add_int, nothing, out_val, false);
    end csr_nochecks;

    
    procedure csr( csr_add_int   : in address_type; --csr with WARL check
                   write_val     : in ulogic_XLEN;
                   out_val       :out ulogic_XLEN;
                   write_select  : in boolean) is
      variable to_write : ulogic_XLEN;
      variable mask     : ulogic_XLEN;
    begin
      csr_nochecks(csr_add_int,write_val, out_val, write_select and WARL_legal(write_val, csr_add_int));
    end;
    
    procedure csr(csr_add_int : in address_type; --this procudre can be improved  
                  out_val    :out ulogic_XLEN)is
      variable nothing : ulogic_XLEN; --non-pedantic version of csr_nochecks(csr_add_int; out_val);
    begin
      csr_nochecks(csr_add_int, nothing, out_val, false);
    end csr;

    procedure take_itr(mcause_reason: in natural) is -- take an interupt
    begin
      waiting_for_itr <= false; --reset WFI

      mcause_set := itr_mcause(mcause_reason);          
      mstatus_reg(7) <= mstatus_reg(3); --mpie <= mie
      mstatus_reg(3) <= '0'; --disabled interrupts
      itr := true;
    end take_itr;  
    
    procedure manage_itr is
    begin
      --check mstatus mie (itr enable) is on and that an itr is enabled and pending
      --priv spec 3.1.6.1 and 3.1.9 
      if (mstatus_reg(3) = '1') then --and (unsigned(mie_reg and mip_reg) > 0) then
        --check interrupts enabled with mstatus and if any enable and pending
        --bits are on        
        if (external_itr_sw and mie_reg(3)) = '1' then --software itr
          take_itr(3);
        elsif (external_itr_tm and mie_reg(7)) = '1'  then--Timer itr
          take_itr(7);
        elsif (external_itr_hw and mie_reg(11)) = '1' then--external itr
          take_itr(11);
        elsif or_all(mie_reg(31 downto 16) and mip_reg(31 downto 16)) = '1' then --find any other itr in
                                                     --WIRI space
          --catch all for all mip/mie after 16, not defined in spec so should
          --be legal, would be better to do with for loop or more of the above
          take_itr(16);
        end if;
      end if;
    end manage_itr;
    
    procedure rst_csr is --resets the csr
      variable var : natural;
      variable ignore : ulogic_XLEN;
      
    begin
      for i in 0 to 16#C00# -1 loop --write zereos to all
      -- may not be hardware efficent and CSRs not needed be reset to 0
      -- by spec so may be pointless, good for debugging though
        var := i;
        csr_nochecks(var,X"00000000", ignore, true);
      end loop;
      --write WARL registers to correct values
      csr_nochecks(misa, misa_rst ,ignore, true);
      mie_reg     <= mie_rst; --enable all interupts
      mstatus_reg <= mstatus_rst; --enable interupts and other mstatus effects
    end rst_csr;

    
    function ulog_2_signed (vec : in std_ulogic_vector) return signed is
    -- signed('0' & mtvec_reg(XLEN downto 2) & "00") did not compile due to overloading
    -- so I made it a function instead
    begin
      return signed(vec);
    end ulog_2_signed;
    
--Timers
    procedure increment_timer(XLEN_low  : in address_type;
                              XLEN_high : in address_type) is
      --65 bit to allow safe overflow for 64 bit (2 words)
      variable bit64 : unsigned(64 downto 0) := (others => '0');
    begin
      --no overflow protection needed
      --according to unprivliedged spec
      --"underlying 64-bit counter should never overflow in practice."
      bit64(63 downto 32):= unsigned(timers2(XLEN_high));
      bit64(31 downto 0 ):= unsigned(timers1(XLEN_low ));
      bit64 := bit64 + to_unsigned(1,1);
      
      timers2(XLEN_high) <= std_ulogic_vector(bit64(63 downto 32));
      timers1(XLEN_low ) <= std_ulogic_vector(bit64(31 downto 0 ));
    end increment_timer;

    procedure increment_mcycle is
      --Needs a seperate procedure as mcycle is not in timers1 or timers2
      --unlike rest of timers
      --65 bit to allow safe overflow for 64 bit (2 words)
      variable bit64 : unsigned(64 downto 0) := (others => '0');
    begin
      --no overflow protection needed
      --according to unprivliedged spec
      --"underlying 64-bit counter should never overflow in practice."
      bit64(63 downto 32) := unsigned(mcycleh_reg(mcycleh));
      bit64(31 downto 0 ) := unsigned(mcycle_reg (mcycle ));
      bit64 := bit64 + to_unsigned(1,64);

      mcycleh_reg(mcycleh)<= std_ulogic_vector(bit64(63 downto 32));
      mcycle_reg (mcycle )<= std_ulogic_vector(bit64(31 downto 0 ));
    end increment_mcycle;
    
    
    procedure manage_timers is --most of this is 3.1.10 of spec
    begin
      --checks on inhibit_reg are defiend by 3.1.12 of spec
      --(machine counter-inhibit csr)
      
      --manage instructions-retired counter 3.1.10 of spec
      --save instructions as instructions will not be 'retired'(fully complete)
      --until 5 clocks after it is first read, this is why resets will set to post_rst5
      --after a branch it will be set to branch2 as the the first two parts WILL be
      --retired normally and then it will take 3 instructions till next normal
      --one
      if branch_in = '1' then
        branch_rst_save <= post_branch;
        increment_timer(minstret, minstreth);
      else
        case branch_rst_save is --statemachine for reset 
          when post_rst4 =>
            branch_rst_save <= post_rst3; 
          when post_branch  =>
            increment_timer(minstret, minstreth);
            branch_rst_save <= post_branch_states'succ(branch_rst_save);
            
          when normal_operation =>
            increment_timer(minstret, minstreth);
            
          when others =>
            branch_rst_save <= post_branch_states'succ(branch_rst_save);

        end case;
      end if;    

      --hardware performance monitor extra parts
      for i in mhmevent_bottom to mhmevent_top loop
        if mhmevent(i) /= X"00000000"then --if event is present, increment
          increment_timer(i+2015,i+2144);--convert i to lower and upper address
        end if;      
      end loop;

      increment_mcycle;      
    end manage_timers;

    procedure manage_wait_itr(waiting : in boolean) is      
    begin
      if waiting = true then
        trap_PC <= '1';        
      else
        trap_PC <= '0';
      end if;      
    end manage_wait_itr;

    
    
  begin
    -- Spec states CSRRW should not be read when rd = x0, this isn't managed
    -- here and will still be read, just not saved to a register (page 56 unprivileged)
    
    if rst = '0' then --reset
      waiting_for_itr <= false;
      acc_me     <= '0';
      PC_out <= (others => '0');
      trap_PC<= '0';
      rst_csr;
      result_out <= (others => '0');
      branch_rst_save <= post_rst5; --save when rst
      --happens
            --hardware interrupts, manage on rst--
      mip_reg(3) <= external_itr_sw;--software - tied to memory location in cache
      mip_reg(7) <= external_itr_tm;--timer 
      mip_reg(11)<= external_itr_hw;--external - normally hardware
      
    elsif rising_edge(clk) then
      --hardware interrupts--
      mip_reg(3) <= external_itr_sw;--software - tied to memory location in cache
      mip_reg(7) <= external_itr_tm;--timer 
      mip_reg(11)<= external_itr_hw;--external - normally hardware



      address_int := to_integer(unsigned(address));
      
      --calculate if load/store address is algined with 32 bits
      algiment_check:= unsigned(rs1_in(1 downto 0)) + unsigned(inst_in(8 downto 7));
      
      if uimm /= "00000" then
        write_csr := true;
      else
        --will write on U/X/Z, may be an issue
        write_csr := false;
      end if;
      
      itr := false; --default values
      csr_read := '1';
      trap   := false;
      manage_wait_itr(waiting_for_itr);--this also sets PC_trap

      
      case inst_enum_in is --manage different instructions
                           -- CSR instructions are in unprivileged spec
                           -- As are Ebreak and iFence
                           -- Rest are trap causing side effects defined
                           -- in the priv spec
        when iCSRRW => --write RS1
          temp_read := rs1_in;

        when iCSRRS =>--set bits where rs1 = '1'
          if rs1_in = X"00000000" then
            write_csr := false;
          else
            csr(address_int, temp_read);
            temp_Read := (rs1_in or temp_read);
          end if;
          
        when iCSRRC => --clear bits where rs1 = '1'
          if rs1_in = X"00000000" then
            write_csr := false;
          else
            csr(address_int, temp_read);
            temp_read :=(not rs1_in) and temp_read;
          end if;
          
        when iCSRRWI =>
          temp_read := X"000000" & "000" & uimm;--use UIMM and 0 extend

        when iCSRRSI =>
          csr(address_int, temp_read);
          temp_read := (X"000000" & "000" & uimm) or temp_read;
          --use UIMM and 0 extend         
          
        when iCSRRCI =>
          csr(address_int, temp_read);
          temp_read := (not (X"000000" & "000" & uimm)) and temp_read;
          --use UIMM and 0 extend

        -- check instructions that can trap issues
        when iEBREAK =>
          mcause_set := trap_mcause(3);
          trap := true;
          csr_read := '0';

        when iECALL =>
          mcause_set := trap_mcause(11);
          trap := true;  
          csr_read := '0';
          
        when iWFI =>
          --wait for interrupt
          waiting_for_itr <= true;
          trap_handle(mepc)
            <= std_ulogic_vector(unsigned(PC_in) + to_unsigned(4,3));
          PC_out <= PC_in;
          manage_wait_itr(true);
          csr_read := '0';

        when iMRET =>
          --return from interrupt
          PC_out <= trap_handle(mepc);
          trap_PC<= '1';
          csr_read := '0';

        when iLB to iLHU =>
          --this could be repalaced by reading the input to the cache
          --would lag traps behind by a clock cycle though 
          algiment_check := unsigned(rs1_in(1 downto 0)) + unsigned(inst_in(8 downto 7)); 

          if algiment_check(1 downto 0) /= "00" then
            -- check for misaligned loads
            mcause_set := trap_mcause(4);
            trap := true;            
          end if;
          csr_read := '0';

        when iSB to iSW =>

          if algiment_check(1 downto 0) /= "00" then
            -- check for misaligned stores
            mcause_set := trap_mcause(6);
            trap := true;            
          end if;
          csr_read := '0';
          
        when iFENCE => 
          trap_PC <= '1'; --jump to next instruction, clearing the pipeline
        									--making sure all instructions in the pipeline are executed before the next
          PC_out <= std_ulogic_vector(unsigned(PC_in) + 4);
        
          csr_read := '0';
        when i_not_found => --trap on malformed/unsupported instructions
          mcause_set := trap_mcause(1); 
          trap := true;          
          
        when others =>
          csr_read := '0';
      end case;

      manage_timers;
      manage_itr; --manage interrupts

			--trap when attemping to access memory that doesn't exist			
			if unsigned(PC_in) > to_unsigned(cache_size,PC_in'length) then
				trap := true;
				mcause_set := trap_mcause(1);
			end if;

      --trap on misaligned instruction
      if PC_in(1 downto 0) /= "00" then
        trap := true;
        mcause_set := trap_mcause(0); 
      end if;
      
      --checks if trap and instruction  written to register at same time  
      if ((trap or itr) = true) and ((address_int = mepc) or (address_int = mcause))then
        write_csr := false;
      --make sure CSR is not dirven high by 2 signals at once
      end if;

      if csr_read = '1' then
        csr(address_int, temp_read ,result ,write_csr);
      else
        result := (others => '0');
      end if;
      
      acc_me <= csr_read;

      --deal with traps
      if (trap or itr) = true then
        if (PC_in(1 downto 0) = "00") then
          --save trap address, if aligned
          if waiting_for_itr = true then --find if triggering after a WFI
            trap_handle(mepc) <=  std_ulogic_vector(
              unsigned(PC_in) + to_unsigned(4,3)); --3.3 of priv spec
          else
            trap_handle(mepc) <=  PC_in;
          end if;          
        end if;
        
        trap_handle(mcause) <= std_ulogic_vector(mcause_set);
        trap_PC <= '1';
        
        --set PC, mtvec, 3.1.7 of priv spec (pg 27)
        if (mtvec_reg(1 downto 0) = "01") and (trap /= true) then
          --vector mode, only on interupts, hence trap /= true
          --function used here as it got confused with function overloading
          -- even putting std_ulogic_vector around everything didn't work
          PC_out <= std_ulogic_vector(
            ulog_2_signed('0' & mtvec_reg(XLEN downto 2) & "00") +
            signed(mcause_set*4));                                      
        else
          --direct mode
          PC_out <= mtvec_reg(XLEN downto 2) & "00";
        --Block of bottom 2 bits so always aligned
        end if;
      end if;
      
      --print result
      result_out <= result;      
    end if;
  end process;

--read only register set
  read_only_csrs(VENDOR_ID_ADDRESS)        <= VENDOR_ID;
  read_only_csrs(ARCHITECTURE_ID_ADDRESS)  <= ARCHITECTURE_ID;
  read_only_csrs(IMPLEMENTATION_ID_ADDRESS)<= IMPLEMENTATION_ID;
  read_only_csrs(THREAD_ID_ADDRESS)        <= std_ulogic_vector(
    to_unsigned(Hardware_thread_ID,32));
  
end arch;

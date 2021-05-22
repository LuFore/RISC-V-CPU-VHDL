library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.all;
use work.instructions.all;
use work.assembler.all;
use work.tb_helpers.all;
use work.csr_info.all;

entity tb_zcsr is
  generic(
    XLEN : natural := 32-1;
    Hardware_thread_ID : integer := 0
    );
end tb_zcsr;

architecture tb of tb_zcsr is

  component zcsr
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
    trap_PC          :out std_ulogic;

    external_itr_hw  : in std_ulogic; --exposed signals for triggering interrupts 
    external_itr_sw  : in std_ulogic;  --to be memory mapped to cache
    external_itr_tm  : in std_ulogic
    );
  end component;        
    
  signal clk          : std_ulogic;
  signal rst          : std_ulogic;
  signal inst_in      : instruction;
  signal inst_enum_in : instruction_all;
  signal rs1_in       : std_ulogic_vector (xlen downto 0);
  signal result_out   : std_ulogic_vector (xlen downto 0);
  signal acc_me       : std_ulogic;
  signal PC_in        : std_ulogic_vector(XLEN downto 0);
  signal PC_out       : std_ulogic_vector(XLEN downto 0);
  signal trap_PC      : std_ulogic;
  signal external_itr_hw  : std_ulogic; --exposed signals for triggering interrupts 
  signal external_itr_sw  : std_ulogic;  --to be memory mapped to cache
  signal external_itr_tm  : std_ulogic;  --to be memory mapped to cache
  signal branch_in    : std_ulogic;
  
  constant TbPeriod : time := 1000 ns; -- EDIT Put right period here
  signal TbClock : std_logic := '0';
  signal TbSimEnded : std_logic := '0';

begin

  dut : zcsr
    port map (clk          => clk,
              rst          => rst,
              inst_in      => inst_in,
              inst_enum_in => inst_enum_in,
              rs1_in       => rs1_in,
              result_out   => result_out,
              acc_me       => acc_me,
              PC_in => PC_in,
              PC_out => PC_out,
              trap_PC => trap_PC,
              external_itr_sw => external_itr_sw,
              external_itr_hw => external_itr_hw,
              external_itr_tm => external_itr_tm,
              branch_in => branch_in);

  -- Clock generation
  TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';

  -- EDIT: Check that clk is really your main clock signal
  clk <= TbClock;

  stimuli : process    

    variable test_var : std_ulogic_vector(XLEN downto 0);
    subtype uint12 is natural range 0 to (2**12 -1);
    subtype uint5  is natural range 0 to  (2**5 -1);    

    variable test_register : natural := 810;--used to use mcycle,
                                            --now mhmevent8
    variable test_reg_read : natural := 3857;
    
    procedure set_command (inst : in instruction_all;
                           rs1 : in uint5;
                           imm : in uint12;
                           rs1_data : in std_ulogic_vector) is
    begin
      rs1_in       <= rs1_data;
      inst_enum_in <= inst; 
      inst_in      <= assemble(inst, rs1, 0, 1,imm);--rs2 doesn't matter and rd
                                                    --doesn't either 
    end set_command;
    
  begin
    report "Starting simulation" severity note;
    rs1_in  <= (others => '0');
    inst_in <= (others => '0');
    inst_enum_in <= i_not_found;
    PC_in <= (others => '0');
    external_itr_hw <= '0';
    external_itr_sw <= '0';

    external_itr_tm <= '0';
    branch_in <= '0';

-- Reset generation
    rst <= '0';
    wait for 100 ns;
    rst <= '1';
    wait for 100 ns;
    report ulogic_vector_image(assemble(iJALR,30,0,0,50)) severity error;
    
    for i in 0 to 60 loop
      case i is
        when 0 =>
          test_var := sint2ulog32(2**30);              
          set_command(iCSRRW, 1,test_register,test_var);
        when 1 =>
          test_against_sint(result_out,0, "read CSRRW");
          test_1(acc_me, '1', "acc_me on");
          
          test_var := sint2ulog32(1);
          set_command(iCSRRS,1,test_register,test_var);
        when 2 =>
          test(result_out, sint2ulog32(2**30), "write CSRRW and read CSRRS");

          set_command(iCSRRC,1,test_register,test_var);
        when 3 =>
          test(result_out, sint2ulog32(2**30 + 1), "write CSRRS and read CSSRC");
          
          -- set this bit later
          set_command(iCSRRSI,1,test_register,test_var);
        when 4 =>
          test(result_out, sint2ulog32(2**30), "write CSSRC and read CSRRSI");
          
          set_command(iCSRRCI,3,test_register,test_var);
        when 5 => -- test start here
          --last one
          test(result_out, sint2ulog32(2**30 + 1), "write CSRRSI and read CSRRCI");
          
          set_command(iCSRRWI,3,test_register,test_var);
        when 6 =>
          test(result_out, sint2ulog32(2**30), "write CSRRCI and read CSRRWI");
          
          inst_enum_in <= iaddi; 
          inst_in      <= (others => '0');
        when 7 =>
          test_1(acc_me, '0', "acc_me off");

          set_command(iCSRRWI,3,test_register,test_var); -- just read
        when 8 =>
          test(result_out, sint2ulog32(3), "write CSRRWI ");

          test_var := sint2ulog32(10001);
          set_command(iCSRRW, 1,test_reg_read,test_var);
        when 9 =>
          null;
        when 10 =>          
          test_against_sint(result_out, 0, "read and write read only");

          test_var := sint2ulog32(300);
          set_command(iCSRRW, 0, test_register, test_var); 
        when 11 =>
          null;
        when 12 =>
          test_against_sint(result_out, 3, "No write on rs1 =0");          

          --test write 0
          set_command(iCSRRW, 1, test_register, sint2ulog32(0));
        when 13 =>
          null;

        when 14 =>
          test_against_sint(result_out, 0, "Clear register with a 0 write");

          
          set_command(iCSRRW, 1, mtvec, X"000000F0");--set mtvec (location to
                                                     --trap to)
        when 15 =>
          inst_enum_in <= i_not_found; 
          inst_in      <= sint2ulog32(19); --nop instruction, but should be
          PC_in        <= sint2ulog32(200);

        when 16 =>
          test_against_sint(PC_out, 16#F0#,"PC direct trap");
          test_1(trap_PC, '1', "PC trapped");


          set_command(iCSRRC, 1, mepc, sint2ulog32(0));
        when 17 =>
          test_against_sint(result_out, 200, "mepc after trap");
          test_1(trap_PC, '0', "reset trap");

          set_command(iCSRRC,1,mcause,sint2ulog32(0));
        when 18 =>
          test_against_sint(result_out, 1, "1 for wrong instruction");

        when 19 => --test interrupt
          external_itr_hw <= '1';
          null;
        when 20 =>
          test_1(trap_PC, '1', "Trap on interrupt");

        when 21 =>
          test_1(trap_PC, '0', "Interrupt off");

          set_command(iCSRRC,1,mcycle,X"00000000" );
          external_itr_hw <= '0';
        when 22 =>
          test_against_sint(result_out, 21, "cycle timer read");
          test_against_sint(result_out, 21, "no set on rs1_in = 0");
          
          --this command is impossible but it's ok to test with!
          set_command(iCSRRC,0,minstret,int2ulogic32(4));

        when 23 => --test overflow
          set_command(iCSRRw,1,mcycleh,X"FFFFFFFF");
        when 24 =>
          set_command(iCSRRW,1,mcycle,X"FFFFFFFF" );
        when 25 =>
          null;
          set_command(iCSRRC,1,mcycle,X"00000000" );
        when 26 =>
          set_command(iCSRRC,1,mcycle,X"00000000" );
        when 27 =>
          test_against_sint(result_out, 0, "counter overflow");
          set_command(iCSRRW, 1,minstret,X"00000000"); --rst inst counter

        when 28 =>
          
          inst_enum_in <= iAddi; 
          inst_in      <= assemble(iAddi, 3, 0, 1,0); 

        when 29 to 30 =>
          null;

        when 31 =>
          set_command(iCSRRC, 1,minstret,X"00000000"); --read inst counter

          --inst_enum_in <= iAddi;  --more legit instructions with no side effects
          --inst_in      <= assemble(iAddi, 3, 0, 1,0); 
        when 32 =>
          test_against_sint(result_out, 3, "instruction retired counter"); 

          branch_in <= '1';
        when 33 to 35 =>
          branch_in <= '0';

        when 36 =>
          set_command(iCSRRC, 1,minstret,X"00000000"); --read inst counter

        when 37 =>
          test_against_sint(result_out, 6, "instructions retired after branch");
          
          --6 = 2 + 4 as 4 is the number in the register prior to branch
          --it should carry out 2 reads before stopping the read
        when 38 =>
          rst <= '0';
        when 39 to 44 =>
          rst <= '1'; --test rst
        when 45 =>
          test_against_sint(result_out, 0, "reset retired counter");
        when 46 =>
          test_against_sint(result_out, 1, "increment retired counter after reset");
          inst_enum_in <= iFence;
        when 47 =>
          test_1(trap_PC, '1', "fence");
          inst_enum_in <= iADDI;
        when 48 =>
          test_1(trap_PC, '0', "fence off");
          inst_enum_in <= iWFI;
          PC_in <= X"00000004";
        when 49 =>
          inst_enum_in <= iADDI;
          test_1(trap_PC, '1', "WFI turn on");
          test_against_sint(PC_out, 4, "WFI jump pos");
        when 50 to 53 =>
          null;
        when 54 =>
          test_1(trap_PC, '1' , "Stall CPU for WFI");
          test_against_sint(PC_out, 4,"Stall address");
          
          external_itr_hw <= '1';
        when 55 =>
          null;
        when 56 =>
          test_1(trap_PC, '0' , "Stall done");

          inst_enum_in <= iMRET;

        when 57 =>
          test_1(trap_PC, '1', "trap return from instruction");
          test_against_sint(PC_out, 8, "Set PC after MRET and set mePC after WFI");
          
					inst_enum_in <= iaddi; --random instruction
			
				when 58 =>
					test_1(trap_PC, '0', "trap off");				
          PC_in <= std_ulogic_vector(
										to_unsigned(positive'high ,PC_in'length)); --set PC to too high :)
				when 59 =>
					test_1(trap_PC, '1', "error on impossible instruction access");
					PC_in <= std_ulogic_vector(to_unsigned(4,32));
				when 60 =>
					test_1(trap_PC, '0',"trap off after impossible access");

        when others =>
          null;
      end case;


      wait for TbPeriod;
    end loop;
    TbSimEnded <= '1';
    wait;
  end process;
end tb;


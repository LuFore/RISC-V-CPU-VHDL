library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.instructions.all;

entity alu32i is
  generic(
    bit_width           : positive := 32 -1;
    Cache_addres_width  : positive := 8;
    thread_ID           : natural := 0;
    Cache_bus_width     : positive := 32 - 1
    );
  port(
    clk, rst : in std_ulogic;

    inst_enum_in : in instruction_all;
    inst_enum_out:out instruction_all;
    
    inst_in     : in  instruction;
    inst_out    : out instruction;

    rs1, rs2    : in std_ulogic_vector(bit_width downto 0);
    data_out    :out std_ulogic_vector(bit_width downto 0);
    data_select :out std_ulogic; --high when there is a useful output
  
    jump        :out std_ulogic;
    PC_out      :out std_ulogic_vector(bit_width downto 0);
    PC_in       : in std_ulogic_vector(bit_width downto 0);

    rw_memory   : out std_ulogic;
    memory_size : out std_ulogic_vector(1 downto 0);
    data_memory : out std_ulogic_vector(Cache_bus_width downto 0);
    address_memory : out std_ulogic_vector(bit_width downto 0);
    external_itr, memory_mapped_itr, external_itr_tm : in std_ulogic
    );
 
end alu32i;

architecture alu32i_arch of alu32i is
  
component Integer_32_ALU is
  generic(bitwidth : integer :=(32 -1));
  port(clk, rst	                : in std_ulogic;
       inst_enum_in: in instruction_all; 

       inst_in, rs1_in, rs2_in	: in std_ulogic_vector(bitwidth downto 0); 
       acc_out                  : out std_ulogic_vector(bitwidth downto 0);
       acc_me                   : out std_ulogic);
end component;

component mem_access_tx is
-- Sends load/store instructions and data to a memory cache
  generic(
    address_width : integer := 8; --size of each address in bits
    bit_width : integer := (32 - 1);
    bus_width: integer := 32 - 1
    );
  port(
    clk, rst : in std_ulogic;
    inst_enum_in: in instruction_all; 

    inst_in  : in instruction;
    inst_out : out instruction;
    rs1_in, rs2_in      : in std_ulogic_vector(bit_width downto 0);
    rw                  : out std_ulogic;
    data_store          : out std_ulogic_vector(Cache_bus_width downto 0); 
    address_out         : out std_ulogic_vector(bit_width downto 0);
    mem_len             : out std_ulogic_vector(1 downto 0));
end component;

component Branch_control is -- a Control unit :)
  generic(
    bitwidth : integer := (32 - 1));
  port(
    clk,rst 	: in std_ulogic;
    branch 	: out std_ulogic; -- when this is set it will change the PC to in 
    misaligned  : out std_ulogic; -- error bit

    inst_enum_in: in instruction_all; 

    inst_in	: in std_ulogic_vector(bit_width downto 0); 
    rs1_in	: in std_ulogic_vector(bit_width downto 0);
    rs2_in	: in std_ulogic_vector(bit_width downto 0);

    acc_out     :out std_ulogic_vector(bit_width downto 0); 
    
    PC_in	: in std_ulogic_vector(bit_width downto 0); 			
    PC_out	:out std_ulogic_vector(bit_width downto 0);
    acc_me      :out std_ulogic

    );
end component;


component zcsr is
  generic(
    XLEN : natural := 32-1;
    Hardware_thread_ID : natural := 0
    );

  port(
    clk, rst : in std_ulogic;
    
    inst_in	     : in instruction; 
    inst_enum_in     : in instruction_all; --will have to change this one! 

    rs1_in           : in std_ulogic_vector(XLEN downto 0); 
    result_out       :out std_ulogic_vector(XLEN downto 0);
    
    acc_me           :out std_ulogic;

    PC_in            : in std_ulogic_vector(XLEN downto 0);
    PC_out           :out std_ulogic_vector(XLEN downto 0);
    trap_PC          :out std_ulogic;
    external_itr_hw  : in std_ulogic; --exposed signals for triggering interrupts
    external_itr_sw  : in std_ulogic; --to be memory mapped to cache
    external_itr_tm  : in std_ulogic;
    branch_in        : in std_ulogic);
end component;




--signal rs1_in, rs2_in : std_ulogic_vector(bit_width downto 0);
signal branch_select, integer_select, data_select_sig, csr_select : std_ulogic; 
signal branch_data, integer_data, csr_select_data : std_ulogic_vector(bit_width downto 0);
signal data : std_ulogic_vector(bit_width downto 0);
signal inst_save : instruction;
signal PC_out1, PC_out2 : std_ulogic_vector(bit_width downto 0);
signal jump0, jump1, jump2 : std_ulogic;

begin

  int_ALU : integer_32_ALU
    --generic map(bit_width => bitwidth) do the generic map later
    port map(clk => clk, rst => rst, inst_in => inst_in, inst_enum_in => inst_enum_in,
             rs1_in => rs1, rs2_in => rs2, acc_me => integer_select,
             acc_out => integer_data);
  
  branch_ALU : branch_control 
    port map(clk => clk, rst => rst, inst_in => inst_in, inst_enum_in => inst_enum_in,
             rs1_in => rs1, rs2_in => rs2, acc_me => branch_select,
             acc_out => branch_data,
             pc_in => PC_in, PC_out => pc_out1, branch => jump1
             );
  
  mem_ALU : mem_access_tx
    port map(clk => clk, rst => rst, inst_in => inst_in, inst_enum_in => inst_enum_in,
             rs1_in => rs1, rs2_in => rs2, mem_len => memory_size,
             rw => rw_memory, data_store => data_memory,
             address_out => address_memory, inst_out => inst_save
             );
  

  CSR : zcsr
    generic map(hardware_thread_ID => Thread_Id)
    port map (clk => clk, rst => rst, inst_in => inst_in, inst_enum_in => inst_enum_in,
              rs1_in => rs1, PC_in => PC_in, result_out => csr_select_data,acc_me => csr_select,
              PC_out => PC_out2, trap_PC => jump2, branch_in => jump0,
              external_itr_hw => external_itr,external_itr_sw => memory_mapped_itr,
              external_itr_tm => external_itr_tm);


  --ideally this would be handled by syncrnous block, it is not a problem for
  --now so is not the focus of improvements. This logic *should* be added to mem_acccess_rx
  --however it does make dataflow diagram and "api" of this entity easier/better
  data_select_sig <=  branch_select or integer_select or csr_select;
  data_select <= data_select_sig;

  data       <= integer_data when integer_select = '1' else
                branch_data  when branch_select  = '1' else
                csr_select_data when csr_select     = '1' else
                (others => '0');

  --mangage PC out, all but jump could be handled by PC
  PC_out    <= PC_out2 when jump2 = '1' else --trap prefered over jump
               PC_out1 when jump1 = '1' else 
               (others => '0'); --not needed, but good for debugging

  jump0 <= jump1 or jump2;
  jump <= jump0;

  data_out <= data;
  inst_out <= inst_save;

  
--implicit latch of inst_enum in to preserve the clock 
  process(clk)
  begin
    if rst = '0' then
      inst_enum_out <= i_not_found;
    elsif rising_edge(clk) then
      inst_enum_out <= inst_enum_in;
    end if;
  end process;
  
end alu32i_arch;


library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.instructions.all;

entity hart32i is
  generic(
    bit_width           : integer := 32 -1;
    Cache_addres_width  : integer := 8;
    Cache_bus_width     : integer := 32 - 1
    );
  port(
    clk, rst       : in std_ulogic;
    PC_out         :out std_ulogic_vector(bit_width downto 0);
    PC_in          : in std_ulogic_vector(Cache_bus_width downto 0);

    memory_width   :out std_ulogic_vector(1 downto 0);
    memory_write   :out std_ulogic;
    memory_address :out std_ulogic_vector(bit_width       downto 0);
    memory_store   :out std_ulogic_vector(Cache_bus_width downto 0);
    memory_load    : in std_ulogic_vector(Cache_bus_width downto 0);
    external_itr, memory_mapped_itr, timer_itr : in std_ulogic
    );
end hart32i;

architecture hart32i_arch of hart32i is

component alu32i is
  port(
    clk, rst : in std_ulogic;

    inst_enum_in : in instruction_all; -- not used but might be in future
    inst_enum_out:out instruction_all; -- not used but might be in future
    
    inst_in     : in  instruction;
    inst_out    : out instruction;

    rs1, rs2    : in  std_ulogic_vector(bit_width downto 0);
    data_out    : out std_ulogic_vector(bit_width downto 0);
    data_select : out std_ulogic; --high when there is a useful output

    jump        : out std_ulogic;
    PC_out      : out std_ulogic_vector(bit_width downto 0);
    PC_in       : in  std_ulogic_vector(bit_width downto 0);

    rw_memory   : out std_ulogic;
    memory_size : out std_ulogic_vector(1 downto 0);
    data_memory : out std_ulogic_vector(Cache_bus_width downto 0);
    address_memory : out std_ulogic_vector(bit_width downto 0);

    external_itr, memory_mapped_itr, external_itr_tm :in std_ulogic);
end component;

component buffers is
  --delays rst_in and PC_in, d1 is delayed by 1 clock, d2 by 2 and so on. 
  generic( bit_width : integer := 32-1);
  port(
    clk, rst : in std_ulogic;
    PC_in : in std_ulogic_vector(bit_width downto 0);
    rst_in: in std_ulogic;

    rst_d1, rst_d2, rst_d3 : out std_ulogic;
    PC_delay : out std_ulogic_vector(bit_width downto 0)
    );
end component;

component decoder is 
  generic(bus_width : integer := (32-1));
  port(
    clk, rst            :in std_ulogic;
    inst_in             :in std_ulogic_vector (bus_width downto 0);
    rs1_add, rs2_add    :out std_ulogic_vector (5-1 downto 0);
    inst_out0,inst_out1 :out instruction;
    inst_enum_out0,inst_enum_out1 :out instruction_all;    
    pause               : in std_ulogic
    );
end component;

component mem_access_rx is
  generic(
    address_width : integer := 8; --size of each address in bits
    bit_width : integer := (32 - 1);
    bus_width: integer := (32 -1) 
    );
  port(
    clk, rst : in std_ulogic;

    inst_enum_in : in instruction_all;
    inst_in      : in instruction;

    data_in      :in std_ulogic_vector(bus_width downto 0); --data to be loaded
    data_out     :out std_ulogic_vector(bit_width downto 0);-- data to write to registers
    address_out  :out std_ulogic_vector(5-1 downto 0); --address to register

    result_in    : in std_ulogic_vector(bit_width downto 0);
    acc_select   : in std_ulogic
    );
end component;

component reg_32 is
  generic(
    XLEN   : integer := (32 - 1);
    bitadd : integer := (5 - 1)
    );
  port(
    clk	: in std_ulogic;
    rst	: in std_ulogic;-- 0 will reset
    d_in: in std_ulogic_vector (XLEN downto 0);
    pause : in std_ulogic;
    
    d_out0, d_out1: out std_ulogic_vector (XLEN downto 0);
    adre0, adre1, adwr0	: in std_ulogic_vector (bitadd downto 0) 
    );
end component;

component PC is
  generic(
    bitwidth : integer := (32 - 1));
  port(
    clk 	: in std_ulogic;
    rst		: in std_ulogic;
    branch 	: in std_ulogic; -- when this is set it will change the PC to in 
    pause       : in std_ulogic; -- stop incrementing PC when high
    
    PC_in	: in std_ulogic_vector(bitwidth downto 0);
    PC_out	: out std_ulogic_vector(bitwidth downto 0)
    );
end component;

component accumulator is
  --no clock or reset block as there is no process block
  generic(bit_width : integer := 32-1);
  port(
    inst_in               : in instruction;

    mem_select, ALU_select: in std_ulogic;
    mem_data, ALU_data    : in std_ulogic_vector(bit_width downto 0);

    write_data            :out std_ulogic_vector(bit_width downto 0);
    write_address         :out std_ulogic_vector(5-1 downto 0)
    );
end component;

component delay is
  generic(vector_size : integer := 32-1);
  port(clk, rst : in std_ulogic;
    input : in std_ulogic_vector (bit_width downto 0);
    output:out std_ulogic_vector (bit_width downto 0));
end component;

component delay_std_ulogic is
  port(clk, rst : in std_ulogic;
       input : in std_ulogic;
       output:out std_ulogic);
end component;

component pipeline_control is
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
end component;

signal jump, jump1, jump2 : std_ulogic;

signal rst_0, rst_1, rst_2 : std_ulogic;

signal rs1_0, rs2_0,rs1_1, rs2_1 : std_ulogic_vector(bit_width downto 0);
signal inst_0, inst_1, inst_2 : instruction; --, inst_3

signal rs1_add, rs2_add : std_ulogic_vector(5-1 downto 0);
signal reg_address: std_ulogic_vector(5-1 downto 0);
signal reg_data   : std_ulogic_vector(bit_width downto 0);

signal alu_data0  : std_ulogic_vector(bit_width downto 0); --, alu_data1
signal alu_select0: std_ulogic; --, alu_select1

--signal mem_data   : std_ulogic_vector(bit_width downto 0);
--signal mem_select : std_ulogic;

signal PC_ALU_read, PC_ALU_write : std_ulogic_vector(bit_width downto 0);

signal inst_enum0, inst_enum1, inst_enum2 : instruction_all;

signal bubble_pause : std_ulogic;
signal bubble_reset : std_ulogic;

signal PC_address : std_ulogic_vector(bit_width downto 0);

begin
  --resets controlled by both branching and normal reset
  -- not is for the polarity of the reset
  
  rst_0 <= (rst and not (jump1  or jump)); 
  rst_1 <= (rst and not jump1);
  bubble_reset <= (rst_2 and not bubble_pause); 
  rst_2 <= (rst and not jump2);
  PC_out <= PC_address;


  decode : decoder
    port map(clk => clk, rst => rst_0, inst_in => PC_in,
             rs1_add => rs1_add, rs2_add => rs2_add, pause => bubble_pause,
             inst_out0 => inst_0, inst_enum_out0 => inst_enum0,
             inst_out1 => inst_1, inst_enum_out1 => inst_enum1);
  --Inst out happens after 2 clock cycles, only thing that does this
  --(improvment might be to move this into register or use a delay unit)
  
  int_register : reg_32
    port map(clk => clk, rst => rst,
             adre0 => rs1_add, adre1 => rs2_add, d_out0 => rs1_0, d_out1 => rs2_0, 
             d_in => reg_data,  adwr0 => reg_address, pause => bubble_pause);
             
  ALU : alu32i
    port map(clk => clk, rst => rst, inst_in => inst_1, rs1 => rs1_1, rs2 => rs2_1,
             inst_out => inst_2, data_out => alu_data0, data_select => alu_select0,
             jump => jump, PC_out => PC_ALU_write, PC_in => PC_ALU_read,
             rw_memory => memory_write, memory_size => memory_width,
             data_memory => memory_store, address_memory => memory_address,
             inst_enum_in => inst_enum1, inst_enum_out =>inst_enum2,
             external_itr => external_itr, memory_mapped_itr => memory_mapped_itr,
             external_itr_tm => timer_itr);

  -- alu_data_delay : delay
  --   port map(clk => clk, rst => bubble_reset, input => alu_data0, output => alu_data1);
  
  -- alu_select_delay : delay_std_ulogic
  --   port map(clk => clk, rst => bubble_reset, input => alu_select0, output => alu_select1);

  -- memory_rx : mem_access_rx --old
  --   port map( clk => clk, rst => rst_2, acc_me => mem_select, inst_in => inst_2,
  --             inst_out => inst_3,data_in => memory_load, inst_enum_in => inst_enum2);

  acc : mem_access_rx
    port map (clk => clk, rst => rst_2, inst_enum_in => inst_enum2, inst_in => inst_2 ,
              data_in => memory_load, data_out=> reg_data, address_out => reg_address,
              result_in => alu_data0, acc_select => alu_select0 );

  
  --mem_data <= memory_load;
    
  -- acc :  accumulator --no longer used maybe?
  --   port map(inst_in => inst_3, mem_select => mem_select, mem_data => mem_data,
  --            ALU_select => alu_select1, alu_data => alu_data1, write_data => reg_data,
  --            write_address => reg_address);
  
  jump_buffer : buffers
    port map(clk => clk, rst => rst, PC_in => PC_address, PC_delay => PC_ALU_read, rst_in => jump,
             rst_d1 => jump1, rst_d2 => jump2);
  -- JALR needs to be tested for this to see if it writes the correct PC to regeister
  -- The change will be simple in buffers

  program_counter :PC
    port map( clk => clk, rst => rst, branch => jump, PC_in => PC_ALU_write, PC_out => PC_address,
              pause => bubble_pause);

  pipeline_controller : pipeline_control
    port map( clk => clk, rst => rst_0, rs1_in => rs1_0, rs2_in => rs2_0, result_in => alu_data0,
              load_in => reg_data, rs1_out => rs1_1, rs2_out => rs2_1, inst_in => inst_1,
              inst_enum_in => inst_enum1, next_inst => inst_0, next_inst_enum => inst_enum0,
              bubble => bubble_pause);
  
end hart32i_arch;

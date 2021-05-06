library ieee;
use ieee.std_logic_1164.all;
-- casual test bench, no formal tests or reports should be returned.


library work;
use work.all;
use work.instructions.all;
use work.tb_helpers.all;

entity tb_cache_dma is
  generic(
      address_width 	: integer := 8;                 --size of each address in bits
    cache_size		: integer := 256;              	--numbers of addresses in cache
    bus_width 		: integer := (32-1) 		--size of access bus
    );
end tb_cache_dma;

architecture tb of tb_cache_dma is

    component cache_dma
        port (clk             : in std_ulogic;
              rst             : in std_ulogic;
              rw              : in std_ulogic;
              dma_data_in     : in std_ulogic_vector (bus_width downto 0);
              dma_address_out : in std_ulogic_vector (bus_width downto 0);
              dma_address_in  : in std_ulogic_vector (bus_width downto 0);
              dma_data_out    : out std_ulogic_vector (bus_width downto 0);
              dat_out         : out std_ulogic_vector (bus_width downto 0);
              dat_in          : in std_ulogic_vector (bus_width downto 0);
              add_in          : in std_ulogic_vector (bus_width downto 0);
              add_pc          : in std_ulogic_vector (bus_width downto 0);
              dat_pc          : out std_ulogic_vector (bus_width downto 0);
              mem_len         : in std_ulogic_vector (1 downto 0);
              software_itr    :out std_ulogic;
              timer_itr       :out std_ulogic
              );
    end component;

    
    signal clk             : std_ulogic;
    signal rst             : std_ulogic;
    signal rw              : std_ulogic;
    signal dma_data_in     : std_ulogic_vector (bus_width downto 0);
    signal dma_address_out : std_ulogic_vector (bus_width downto 0);
    signal dma_address_in  : std_ulogic_vector (bus_width downto 0);
    signal dma_data_out    : std_ulogic_vector (bus_width downto 0);
    signal dat_out         : std_ulogic_vector (bus_width downto 0);
    signal dat_in          : std_ulogic_vector (bus_width downto 0);
    signal add_in          : std_ulogic_vector (bus_width downto 0);
    signal add_pc          : std_ulogic_vector (bus_width downto 0);
    signal dat_pc          : std_ulogic_vector (bus_width downto 0);
    signal mem_len         : std_ulogic_vector (1 downto 0);
    signal software_itr    : std_ulogic;
    signal timer_itr       : std_ulogic;

    constant TbPeriod : time := 1000 ns; 
    signal TbClock : std_logic := '0';
    signal TbSimEnded : std_logic := '0';

begin

    dut : cache_dma
    port map (clk             => clk,
              rst             => rst,
              rw              => rw,
              dma_data_in     => dma_data_in,
              dma_address_out => dma_address_out,
              dma_address_in  => dma_address_in,
              dma_data_out    => dma_data_out,
              dat_out         => dat_out,
              dat_in          => dat_in,
              add_in          => add_in,
              add_pc          => add_pc,
              dat_pc          => dat_pc,
              mem_len         => mem_len,
              software_itr    =>software_itr,
              timer_itr       => timer_itr);

    -- Clock generation
    TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';
    clk <= TbClock;

    stimuli : process
    begin
        rw <= '0';
        dma_data_in <= (others => '0');
        dma_address_out <= (others => '0');
        dma_address_in <= (others => '0');
        dat_in <= (others => '0');
        add_in <= (others => '0');
        add_pc <= (others => '0');
        mem_len <= (others => '0');

        -- Reset generation
        rst <= '0';
        wait for 100 ns;
        rst <= '1';
        wait for 100 ns;

        for i in 0 to 25 loop
          case i is 
            when 0 =>
              dma_address_out <= int2ulogic32(16); -- read random block of memory
              rw <= '0';
              add_in <= int2ulogic32(11);
              add_pc <= int2ulogic32(12);
            when 1 =>
              dma_address_in <= int2ulogic32(112+3);
              dma_data_in    <= int2ulogic32(0);
              
              add_in         <= int2ulogic32(12);
              dat_in         <= int2ulogic32(120);
              rw <= '1';
            when 2 =>
              rw <= '0';
              dma_address_out <= int2ulogic32(20);
            when 3 =>
              add_in <= int2ulogic32(100);
            when 4 =>
              test_against_sint(dat_out, 3, "increment accuratly");
              rw <= '1';
              dat_in <= int2ulogic32(29);
              add_in <= int2ulogic32(100);
            when 5 =>
              null;
            when 6 =>
              rw <= '0';
            when 7 =>
              test_against_sint(dat_out, 29, "no increment on write");
            when 8 =>
              test_against_sint(dat_out, 30, "increment after write");
            when 9 =>
              dat_in <= int2ulogic32(1  );
              add_in <= int2ulogic32(104);
              rw <= '1';
            when 10 =>
              dat_in <= int2ulogic32(2  );
              add_in <= int2ulogic32(112);
              
            when 11 =>
              rw <= '0';
            when 12 =>
              test_1(timer_itr, '0', "no trigger timer interupt on upper");

              rw <= '1';
              dat_in <= (others => '1'); --set mtime to 1FFFFFFFF, 1 below timecmp
              add_in <= int2ulogic32(100);
              mem_len<= "11"; -- write 32 bits;
            when 13 =>
              rw <= '0';
            when 14 to 15 => --wait for count to count above timecmp
              null;
            when 16 =>
              test_1(timer_itr, '1', "incrment to upper 32 bits");

              rw <= '1';
              dat_in <= (others => '1'); --set mtime to 1FFFFFFFF, 1 below timecmp
              add_in <= int2ulogic32(97);

            when 17 =>
              rw <= '0';
              add_in <= int2ulogic32(100);

            when 18 =>
              null;
                       
            when 19 =>
              test(dat_out,X"00000100","write 4 length to address below"); --could be 1 higher

              rw <= '1';
              add_in <= int2ulogic32(103);--test write to upper bit and no break
              mem_len <= "11";
            when 20 =>
              mem_len <= "11";
              add_in <= int2ulogic32(104);

            when 21 =>
              add_in <= int2ulogic32(100); --test overflow

            when 22 =>
              rw <= '0';

            when 23 =>
              null;
            when 24 =>
              test_against_sint(dat_out, 0, "overflow lower");
              
              add_in <= int2ulogic32(104);
            when 25 =>
              test_against_sint(dat_out, 0,"test overflow upper");
              test_1(timer_itr, '0', "interrupt on overflow");          
              
            when others =>
              null;             
          end case;
          
          wait for TbPeriod;
        end loop;
        -- Stop the clock and hence terminate the simulation
        TbSimEnded <= '1';
        wait;
    end process;

end tb;

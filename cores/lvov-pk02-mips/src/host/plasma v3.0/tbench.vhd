---------------------------------------------------------------------
-- TITLE: Test Bench
-- AUTHOR: Steve Rhoads (rhoadss@yahoo.com)
-- DATE CREATED: 4/21/01
-- FILENAME: tbench.vhd
-- PROJECT: Plasma CPU core
-- COPYRIGHT: Software placed into the public domain by the author.
--    Software 'as is' without warranty.  Author liable for nothing.
-- DESCRIPTION:
--    This entity provides a test bench for testing the Plasma CPU core.
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.mlite_pack.all;

entity tbench is
end; --entity tbench

architecture logic of tbench is
   constant memory_type : string := 
   "TRI_PORT_X";   
--   "DUAL_PORT_";
--   "ALTERA_LPM";
--   "XILINX_16X";

   constant log_file  : string := 
--   "UNUSED";
   "output.txt";

   signal clk         : std_logic := '1';
   signal reset       : std_logic := '1';
   signal interrupt   : std_logic := '0';
   signal mem_write   : std_logic;
   signal mem_address : std_logic_vector(31 downto 2);
   signal mem_data    : std_logic_vector(31 downto 0);
   signal mem_pause   : std_logic := '0';
   signal mem_byte_sel: std_logic_vector(3 downto 0);
   --signal uart_read   : std_logic;
   signal uart_write  : std_logic;
   signal data_read   : std_logic_vector(31 downto 0);
begin  --architecture
   --Uncomment the line below to test interrupts
   interrupt <= '1' after 20 us when interrupt = '0' else '0' after 445 ns;

   clk   <= not clk after 50 ns;
   reset <= '0' after 500 ns;
   --mem_pause <= not mem_pause after 100 ns;
   --uart_read <= '0';
   data_read <= interrupt & ZERO(30 downto 0);

   u1_plasma: plasma
      generic map (memory_type => memory_type,
                   log_file    => log_file)
      PORT MAP (
         clk               => clk,
         reset             => reset,
         uart_read         => uart_write,
         uart_write        => uart_write,
 
         address           => mem_address,
         data_write        => mem_data,
         data_read         => data_read,
         write_byte_enable => mem_byte_sel,
         mem_pause_in      => mem_pause,
         
         gpio0_out         => open,
         gpioA_in          => data_read);

end; --architecture logic

---------------------------------------------------------------------
-- TITLE: Plasma (CPU core with memory)
-- AUTHOR: Steve Rhoads (rhoadss@yahoo.com)
-- DATE CREATED: 6/4/02
-- FILENAME: plasma.vhd
-- PROJECT: Plasma CPU core
-- COPYRIGHT: Software placed into the public domain by the author.
--    Software 'as is' without warranty.  Author liable for nothing.
-- DESCRIPTION:
--    This entity combines the CPU core with memory and a UART.
--
-- Memory Map:
--   0x00000000 - 0x0000ffff   Internal RAM (16KB)
--   0x10000000 - 0x000fffff   External RAM (1MB)
--   Access all Misc registers with 32-bit accesses
--   0x20000000  Uart Write (will pause CPU if busy)
--   0x20000000  Uart Read
--   0x20000010  IRQ Mask
--   0x20000020  IRQ Status
--   0x20000030  GPIO0 Out
--   0x20000050  GPIOA In
--   0x20000060  Counter
--   IRQ bits:
--      7   GPIO31
--      6   GPIO30
--      5  ^GPIO31
--      4  ^GPIO30
--      3   Counter(18)
--      2  ^Counter(18)
--      1  ^UartWriteBusy
--      0   UartDataAvailable
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.mlite_pack.all;

entity plasma is
   generic(memory_type : string := "XILINX_X16"; --"DUAL_PORT_" "ALTERA_LPM";
           log_file    : string := "UNUSED");
   port(clk               : in std_logic;
        reset             : in std_logic;

        uart_write        : out std_logic;
        uart_read         : in std_logic;

        address           : out std_logic_vector(31 downto 2);
        data_write        : out std_logic_vector(31 downto 0);
        data_read         : in std_logic_vector(31 downto 0);
        write_byte_enable : out std_logic_vector(3 downto 0); 
        mem_pause_in      : in std_logic;
        
        gpio0_out         : out std_logic_vector(31 downto 0);
        gpioA_in          : in std_logic_vector(31 downto 0));
end; --entity plasma

architecture logic of plasma is
   signal address_reg         : std_logic_vector(31 downto 2);
   signal data_write_reg      : std_logic_vector(31 downto 0);
   signal write_byte_enable_reg : std_logic_vector(3 downto 0);

   signal mem_address         : std_logic_vector(31 downto 0);
   signal mem_data_read       : std_logic_vector(31 downto 0);
   signal mem_data_write      : std_logic_vector(31 downto 0);
   signal mem_write_byte_enable : std_logic_vector(3 downto 0);
   signal data_read_ram       : std_logic_vector(31 downto 0);
   signal data_read_uart      : std_logic_vector(7 downto 0);
   signal write_enable        : std_logic;
   signal mem_pause           : std_logic;

   signal enable_internal_ram : std_logic;
   signal enable_misc         : std_logic;
   signal enable_uart         : std_logic;
   signal enable_uart_read    : std_logic;
   signal enable_uart_write   : std_logic;

   signal gpio0_reg           : std_logic_vector(31 downto 0);

   signal uart_write_busy     : std_logic;
   signal uart_data_avail     : std_logic;
   signal irq_mask_reg        : std_logic_vector(7 downto 0);
   signal irq_status          : std_logic_vector(7 downto 0);
   signal irq                 : std_logic;
   signal counter_reg         : std_logic_vector(31 downto 0);

begin  --architecture
   write_byte_enable <= write_byte_enable_reg;
   data_write <= data_write_reg;
   address  <= address_reg;

   write_enable <= '1' when write_byte_enable_reg /= "0000" else '0';
   mem_pause <= mem_pause_in or (uart_write_busy and enable_uart and write_enable);
   irq_status <= gpioA_in(31 downto 30) & (gpioA_in(31 downto 30) xor "11") &
                 counter_reg(18) & not counter_reg(18) &
                 not uart_write_busy & uart_data_avail;
   irq <= '1' when (irq_status and irq_mask_reg) /= ZERO(7 downto 0) else '0';
   gpio0_out <= gpio0_reg;

   enable_internal_ram <= '1' when mem_address(30 downto 28) = "000" else '0';
   enable_misc <= '1' when address_reg(30 downto 28) = "010" else '0';
   enable_uart <= '1' when enable_misc = '1' and address_reg(7 downto 4) = "0000" else '0';
   enable_uart_read <= enable_uart and not write_enable;
   enable_uart_write <= enable_uart and write_enable;

   u1_cpu: mlite_cpu 
      generic map (memory_type => memory_type)
      PORT MAP (
         clk          => clk,
         reset_in     => reset,
         intr_in      => irq,
 
         mem_address  => mem_address,
         mem_data_w   => mem_data_write,
         mem_data_r   => mem_data_read,
         mem_byte_we  => mem_write_byte_enable,
         mem_pause    => mem_pause);

   misc_proc: process(clk, reset, mem_address, address_reg, enable_misc,
      data_read_ram, data_read, data_read_uart, mem_pause,
      irq_mask_reg, irq_status, gpio0_reg, write_enable,
      gpioA_in, counter_reg, mem_data_write, data_write_reg)
   begin
      case address_reg(30 downto 28) is
      when "000" =>      --internal RAM
         mem_data_read <= data_read_ram;
      when "001" =>      --external RAM
         mem_data_read <= data_read;
      when "010" =>      --misc
         case address_reg(6 downto 4) is
         when "000" =>      --uart
            mem_data_read <= ZERO(31 downto 8) & data_read_uart;
         when "001" =>      --irq_mask
            mem_data_read <= ZERO(31 downto 8) & irq_mask_reg;
         when "010" =>      --irq_status
            mem_data_read <= ZERO(31 downto 8) & irq_status;
         when "011" =>      --gpio0
            mem_data_read <= gpio0_reg;
         when "101" =>      --gpioA
            mem_data_read <= gpioA_in;
         when "110" =>      --counter
            mem_data_read <= counter_reg;        
         when others =>
            mem_data_read <= gpioA_in;
         end case;
      when others =>
         mem_data_read <= ZERO;
      end case;

      if reset = '1' then
         address_reg <= ZERO(31 downto 2);
         data_write_reg <= ZERO;
         write_byte_enable_reg <= ZERO(3 downto 0);
         irq_mask_reg <= ZERO(7 downto 0);
         gpio0_reg <= ZERO;
         counter_reg <= ZERO;
      elsif rising_edge(clk) then
         if mem_pause = '0' then
            address_reg <= mem_address(31 downto 2);
            data_write_reg <= mem_data_write;
            write_byte_enable_reg <= mem_write_byte_enable;
            if enable_misc = '1' and write_enable = '1' then
               if address_reg(6 downto 4) = "001" then
                  irq_mask_reg <= data_write_reg(7 downto 0);
               elsif address_reg(6 downto 4) = "011" then
                  gpio0_reg <= data_write_reg;
               end if;
            end if;
         end if;
         counter_reg <= bv_inc(counter_reg);
      end if;
   end process;

   u2_ram: ram 
      generic map (memory_type => memory_type)
      port map (
         clk               => clk,
         enable            => enable_internal_ram,
         write_byte_enable => mem_write_byte_enable,
         address           => mem_address(31 downto 2),
         data_write        => mem_data_write,
         data_read         => data_read_ram);

   u3_uart: uart
      generic map (log_file => log_file)
      port map(
         clk          => clk,
         reset        => reset,
         enable_read  => enable_uart_read,
         enable_write => enable_uart_write,
         data_in      => data_write_reg(7 downto 0),
         data_out     => data_read_uart,
         uart_read    => uart_read,
         uart_write   => uart_write,
         busy_write   => uart_write_busy,
         data_avail   => uart_data_avail);

end; --architecture logic

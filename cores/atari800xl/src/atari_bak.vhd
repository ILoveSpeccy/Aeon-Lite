library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ATARI is
port(
   CLK_50         : in    std_logic;

   KB_CLK         : in    std_logic;
   KB_DAT         : in    std_logic;

   JOY_CLK        : out   std_logic;
   JOY_LOAD       : out   std_logic;
   JOY_DATA0      : in    std_logic;
   JOY_DATA1      : in    std_logic;
   
   SD_MOSI        : out   std_logic;
   SD_MISO        : in    std_logic;
   SD_SCK         : out   std_logic;
   SD_CS          : out   std_logic; 

   SOUND_L        : out    std_logic;
   SOUND_R        : out    std_logic;

   VGA_R          : out   std_logic_vector(3 downto 0);
   VGA_G          : out   std_logic_vector(3 downto 0);
   VGA_B          : out   std_logic_vector(3 downto 0);
   VGA_HSYNC      : out   std_logic;
   VGA_VSYNC      : out   std_logic );
end ATARI;

architecture RTL of ATARI is

   -- System
   signal CLK                 : std_logic;
   signal PLL_LOCKED          : std_logic;
   signal RESET_N             : std_logic;

   -- Video
   signal HSYNC               : std_logic;
   signal VSYNC               : std_logic;
   
   -- Audio
   signal AUDIO_L_PCM         : std_logic_vector(15 downto 0);
   signal AUDIO_R_PCM         : std_logic_vector(15 downto 0); 

   -- Gamepads
   signal GAMEPAD0            : std_logic_vector(7 downto 0);
   signal GAMEPAD1            : std_logic_vector(7 downto 0);
   signal JOY1_n              : std_logic_vector(7 downto 0);
   signal JOY2_n              : std_logic_vector(7 downto 0);
   
   -- Keyboard
   signal KEYBOARD_SCAN       : std_logic_vector(5 downto 0);
   signal KEYBOARD_RESPONSE   : std_logic_vector(1 downto 0);
   signal CONSOL_START        : std_logic;
   signal CONSOL_SELECT       : std_logic;
   signal CONSOL_OPTION       : std_logic;
   signal FKEYS               : std_logic_vector(11 downto 0);

   -- PIA
   signal CA2_OUT             : std_logic;
   signal CA2_DIR_OUT         : std_logic;
   signal CB2_OUT             : std_logic;
   signal CB2_DIR_OUT         : std_logic;
   signal CA2_IN              : std_logic;
   signal CB2_IN              : std_logic;
   signal PORTA_IN            : std_logic_vector(7 downto 0);
   signal PORTA_OUT           : std_logic_vector(7 downto 0);
   signal PORTA_DIR_OUT       : std_logic_vector(7 downto 0);
   signal PORTB_IN            : std_logic_vector(7 downto 0);
   signal PORTB_OUT           : std_logic_vector(7 downto 0);

   -- PBI
   signal PBI_WRITE_DATA      : std_logic_vector(31 downto 0);
   signal PBI_WIDTH_32BIT_ACCESS : std_logic;
   signal PBI_WIDTH_16BIT_ACCESS : std_logic;
   signal PBI_WIDTH_8BIT_ACCESS : std_logic;

   signal GTIA_TRIG           : std_logic_vector(3 downto 0);
   signal ANTIC_LIGHTPEN      : std_logic; 
      
   -- INTERNAL ROM/RAM
   signal RAM_ADDR            : std_logic_vector(18 downto 0);
   signal RAM_DO              : std_logic_vector(15 downto 0);
   signal RAM_REQUEST         : std_logic;
   signal RAM_REQUEST_COMPLETE : std_logic;
   signal RAM_WRITE_ENABLE    : std_logic;

   signal ROM_ADDR            : std_logic_vector(21 downto 0);
   signal ROM_DO              : std_logic_vector(7 downto 0);
   signal ROM_REQUEST         : std_logic;
   signal ROM_REQUEST_COMPLETE : std_logic;
   
	-- DMA/Virtual drive
	signal DMA_ADDR_FETCH : std_logic_vector(23 downto 0);
	signal DMA_WRITE_DATA : std_logic_vector(31 downto 0);
	signal DMA_FETCH : std_logic;
	signal DMA_32BIT_WRITE_ENABLE : std_logic;
	signal DMA_16BIT_WRITE_ENABLE : std_logic;
	signal DMA_8BIT_WRITE_ENABLE : std_logic;
	signal DMA_READ_ENABLE : std_logic;
	signal DMA_MEMORY_READY : std_logic;
	signal DMA_MEMORY_DATA : std_logic_vector(31 downto 0);

	signal ZPU_ADDR_ROM : std_logic_vector(15 downto 0);
	signal ZPU_ROM_DATA :  std_logic_vector(31 downto 0);

	signal ZPU_OUT1 : std_logic_vector(31 downto 0);
	signal ZPU_OUT2 : std_logic_vector(31 downto 0);
	signal ZPU_OUT3 : std_logic_vector(31 downto 0);
	signal ZPU_OUT4 : std_logic_vector(31 downto 0);

	signal ZPU_POKEY_ENABLE    : std_logic;
	signal ZPU_SIO_TXD         : std_logic;
	signal ZPU_SIO_RXD         : std_logic;
	signal ZPU_SIO_COMMAND     : std_logic;

	-- System control from ZPU
	signal RAM_SELECT          : std_logic_vector(2 downto 0);
	signal ROM_SELECT          : std_logic_vector(5 downto 0);
	signal RESET_ATARI         : std_logic;
	signal PAUSE_ATARI         : std_logic;
	signal SPEED_6502          : std_logic_vector(5 downto 0); 
   
begin

u_PLL : entity work.PLL
port map (
   CLKIN          => CLK_50,
   CLKOUT         => CLK,
   LOCKED         => PLL_LOCKED );
   
u_DAC_L : entity work.dac
port map (
   clk_i          => CLK,
   res_n_i        => RESET_N,
   dac_i          => AUDIO_L_PCM,
   dac_o          => SOUND_L );

u_DAC_R : entity work.dac
port map (
   clk_i          => CLK,
   res_n_i        => RESET_N,
   dac_i          => AUDIO_R_PCM,
   dac_o          => SOUND_R );

u_KEYBOARD : entity work.ps2_to_atari800
port map (
   CLK            => CLK,
   RESET_N        => RESET_N,
   PS2_CLK        => KB_CLK,
   PS2_DAT        => KB_DAT,
		
   KEYBOARD_SCAN  => KEYBOARD_SCAN,
   KEYBOARD_RESPONSE => KEYBOARD_RESPONSE,

   CONSOL_START   => CONSOL_START,
   CONSOL_SELECT  => CONSOL_SELECT,
   CONSOL_OPTION  => CONSOL_OPTION,
		
   FKEYS          => FKEYS );

u_JOYSTICKS : entity work.nes_gamepad
port map( 
   CLK            => CLK,
   RESET          => not RESET_N,
   JOY_CLK         => JOY_CLK,
   JOY_LOAD        => JOY_LOAD,
   JOY_DATA0       => JOY_DATA0,
   JOY_DATA1       => JOY_DATA1,
   JOY0_BUTTONS    => GAMEPAD0,
   JOY1_BUTTONS    => GAMEPAD1,
   JOY0_CONNECTED  => OPEN,
   JOY1_CONNECTED  => OPEN );
    
u_INTROMRAM : entity work.internalromram
generic map (
   internal_rom => 1,
   internal_ram => 16384 )
port map (
   clock   => CLK,
   reset_n => RESET_N,

   ROM_ADDR => ROM_ADDR,
   ROM_REQUEST_COMPLETE => ROM_REQUEST_COMPLETE,
   ROM_REQUEST => ROM_REQUEST,
   ROM_DATA => ROM_DO,
		
   RAM_ADDR => RAM_ADDR,
   RAM_WR_ENABLE => RAM_WRITE_ENABLE,
   RAM_DATA_IN => PBI_WRITE_DATA(7 downto 0),
   RAM_REQUEST_COMPLETE => RAM_REQUEST_COMPLETE,
   RAM_REQUEST => RAM_REQUEST,
   RAM_DATA => RAM_DO(7 downto 0) );

u_ATARI800 : entity work.atari800core
generic map (
   cycle_length   => 16,
   video_bits     => 4 )
port map (
   CLK            => CLK,
   RESET_N        => RESET_N,

   VIDEO_VS       => VSYNC,
   VIDEO_HS       => HSYNC,
   VIDEO_B        => VGA_B,
   VIDEO_G        => VGA_G,
   VIDEO_R        => VGA_R,

   AUDIO_L        => AUDIO_L_PCM,
   AUDIO_R        => AUDIO_R_PCM,

   CA1_IN         => '1',
   CB1_IN         => '1',
   CA2_IN         => CA2_IN,
   CA2_OUT        => CA2_OUT,
   CA2_DIR_OUT    => CA2_DIR_OUT,
   CB2_IN         => CB2_IN,
   CB2_OUT        => CB2_OUT,
   CB2_DIR_OUT    => CB2_DIR_OUT,
   PORTA_IN       => PORTA_IN,
   PORTA_DIR_OUT  => PORTA_DIR_OUT,
   PORTA_OUT      => PORTA_OUT,
   PORTB_IN       => PORTB_IN,
   PORTB_DIR_OUT  => OPEN,
   PORTB_OUT      => PORTB_OUT,

   KEYBOARD_RESPONSE => KEYBOARD_RESPONSE,
   KEYBOARD_SCAN  => KEYBOARD_SCAN,

   POT_IN         => "00000000",
   POT_RESET      => OPEN,
		
   PBI_ADDR       => OPEN,
   PBI_WRITE_ENABLE => OPEN,
   PBI_SNOOP_DATA => OPEN,
   PBI_WRITE_DATA => PBI_WRITE_DATA,
   PBI_WIDTH_8bit_ACCESS => PBI_WIDTH_8bit_ACCESS,
   PBI_WIDTH_16bit_ACCESS => PBI_WIDTH_16bit_ACCESS,
   PBI_WIDTH_32bit_ACCESS => PBI_WIDTH_32bit_ACCESS,

   PBI_ROM_DO     => "11111111",
   PBI_REQUEST    => OPEN,
   PBI_REQUEST_COMPLETE => '1',

   CART_RD4       => '0',
   CART_RD5       => '0',
   CART_S4_n      => OPEN,
   CART_S5_N      => OPEN,
   CART_CCTL_N    => OPEN,

   SIO_RXD        => '0',
   SIO_TXD        => OPEN,

   CONSOL_OPTION  => CONSOL_OPTION,
   CONSOL_SELECT  => CONSOL_SELECT,
   CONSOL_START   => CONSOL_START,
   GTIA_TRIG      => GTIA_TRIG,
		
   ANTIC_LIGHTPEN => ANTIC_LIGHTPEN,

   SDRAM_REQUEST  => OPEN,
   SDRAM_REQUEST_COMPLETE => '1',
   SDRAM_READ_ENABLE => OPEN,
   SDRAM_WRITE_ENABLE => OPEN,
   SDRAM_ADDR     => OPEN,
   SDRAM_DO       => (others=>'1'),

   ANTIC_REFRESH  => OPEN,

   RAM_ADDR       => RAM_ADDR,
   RAM_DO         => RAM_DO,
   RAM_REQUEST    => RAM_REQUEST,
   RAM_REQUEST_COMPLETE => RAM_REQUEST_COMPLETE,
   RAM_WRITE_ENABLE => RAM_WRITE_ENABLE,
		
   ROM_ADDR       => ROM_ADDR,
   ROM_DO         => ROM_DO,
   ROM_REQUEST    => ROM_REQUEST,
   ROM_REQUEST_COMPLETE => ROM_REQUEST_COMPLETE,

   DMA_FETCH      => '0',
   DMA_READ_ENABLE => '0',
   DMA_32BIT_WRITE_ENABLE => '0',
   DMA_16BIT_WRITE_ENABLE => '0',
   DMA_8BIT_WRITE_ENABLE => '0',
   DMA_ADDR       => (others=>'1'),
   DMA_WRITE_DATA => (others=>'1'),
   MEMORY_READY_DMA => OPEN,
   PBI_SNOOP_DATA => OPEN,

   RAM_SELECT     => "000",
   ROM_SELECT     => "000001",
   CART_EMULATION_SELECT => "0000000",
   CART_EMULATION_ACTIVATE => '0',
   PAL            => '1',
   USE_SDRAM      => '0',
   ROM_IN_RAM     => '0',
   THROTTLE_COUNT_6502 => "000001",
   HALT           => '0' );

u_ZPU : entity work.zpucore
generic map (
   platform       => 1,
   spi_clock_div  => 1 ) -- 28MHz/2. Max for SD cards is 25MHz...
port map (
   CLK            => CLK,
   RESET_N        => RESET_N,

   ZPU_ADDR_FETCH => dma_addr_fetch,
   ZPU_DATA_OUT   => dma_write_data,
   ZPU_FETCH      => dma_fetch,
   ZPU_32BIT_WRITE_ENABLE => dma_32bit_write_enable,
   ZPU_16BIT_WRITE_ENABLE => dma_16bit_write_enable,
   ZPU_8BIT_WRITE_ENABLE => dma_8bit_write_enable,
   ZPU_READ_ENABLE => dma_read_enable,
   ZPU_MEMORY_READY => dma_memory_ready,
   ZPU_MEMORY_DATA => dma_memory_data, 

   ZPU_ADDR_ROM   => zpu_addr_rom,
   ZPU_ROM_DATA   => zpu_rom_data,

   ZPU_SD_DAT0    => SD_MISO,
   ZPU_SD_CLK     => SD_SCK,
   ZPU_SD_CMD     => SD_MOSI,
   ZPU_SD_DAT3    => SD_CS,

   ZPU_POKEY_ENABLE => zpu_pokey_enable,
   ZPU_SIO_TXD    => zpu_sio_txd,
   ZPU_SIO_RXD    => zpu_sio_rxd,
   ZPU_SIO_COMMAND => zpu_sio_command,

   ZPU_IN1        => X"00000"& FKEYS,
   ZPU_IN2        => X"00000000",
   ZPU_IN3        => X"00000000",
   ZPU_IN4        => X"00000000",

   ZPU_OUT1       => ZPU_OUT1,
   ZPU_OUT2       => ZPU_OUT2,
   ZPU_OUT3       => ZPU_OUT3,
   ZPU_OUT4       => ZPU_OUT4 );

u_ZPUROM : entity work.zpu_rom
port map (
   clock          => clk,
   address        => zpu_addr_rom(13 downto 2),
   q              => zpu_rom_data ); 

u_ZPU_POKEY : entity work.enable_divider
generic map (
   COUNT => 16)
port map(
   clk            => clk,
   reset_n        => reset_n,
   enable_in      => '1',
   enable_out     => zpu_pokey_enable );

RESET_N <= PLL_LOCKED;

VGA_HSYNC <= not(HSYNC or VSYNC);
VGA_VSYNC <= not(HSYNC or VSYNC);

CA2_IN <= CA2_OUT when CA2_DIR_OUT='1' else '1';
CB2_IN <= CB2_OUT when CB2_DIR_OUT='1' else '1';
PORTB_IN <= PORTB_OUT;
PORTA_IN <= ((JOY2_n(0)&JOY2_n(1)&JOY2_n(2)&JOY2_n(3)&JOY1_n(0)&JOY1_n(1)&JOY1_n(2)&JOY1_n(3)) and not (porta_dir_out)) or (porta_dir_out and porta_out);
ANTIC_LIGHTPEN <= JOY2_n(7) and JOY1_n(7);
GTIA_TRIG <= "01"&JOY2_n(7)&JOY1_n(7);
JOY1_n <= not GAMEPAD0; -- FRLDU
JOY2_n <= not GAMEPAD1; -- FRLDU

PAUSE_ATARI <= ZPU_OUT1(0);
RESET_ATARI <= ZPU_OUT1(1);
SPEED_6502 <= ZPU_OUT1(7 downto 2);
RAM_SELECT <= ZPU_OUT1(10 downto 8);
ROM_SELECT <= ZPU_OUT1(16 downto 11);

end RTL;

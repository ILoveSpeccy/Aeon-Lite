---------------------------------------------------------------------------
-- Atari800-Core wrapper
---------------------------------------------------------------------------
-- This file is a part of "Aeon Lite" project
-- Dmitriy Schapotschkin aka ILoveSpeccy '2014
-- ilovespeccy@speccyland.net
-- Project homepage: www.speccyland.net
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- (c) 2013 mark watson
-- I am happy for anyone to use this for non-commercial use.
-- If my vhdl files are used commercially or otherwise sold,
-- please contact me for explicit permission at scrameta (gmail).
-- This applies for source and binary form and derived works.
---------------------------------------------------------------------------

-- New Files:
-- DAC.VHD                 - Delta-Sigma-DAC from Xilinx Appnotes
-- NES-GAMEPAD.VHD         - NES-Gamepad controller
-- SRAM-STATEMACHINE.VHD   - SRAM (2 x 256KB x 16bit) Controller

-- Changed Files:
-- PS2_TO_ATARI800.VHD     - Added PS2_KEYS Output

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ATARI is
port (
   CLK_50         : in    std_logic;
   MCU_READY      : in    std_logic;

   SRAM_A         : out   std_logic_vector(17 downto 0);
   SRAM_D         : inout std_logic_vector(15 downto 0);
   SRAM_WE        : out   std_logic;
   SRAM_OE        : out   std_logic;
   SRAM_UB        : out   std_logic;
   SRAM_LB        : out   std_logic;
   SRAM_CE0       : out   std_logic; 
   SRAM_CE1       : out   std_logic; 

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

   SOUND_L        : out   std_logic;
   SOUND_R        : out   std_logic;

   VGA_R          : out   std_logic_vector(3 downto 0);
   VGA_G          : out   std_logic_vector(3 downto 0);
   VGA_B          : out   std_logic_vector(3 downto 0);
   VGA_HSYNC      : out   std_logic;
   VGA_VSYNC      : out   std_logic );
end ATARI;

architecture rtl of ATARI is

   signal CLK                 : std_logic;
   signal LOCKED              : std_logic;
   signal RESET_N             : std_logic;
   
   -- Pokey Keyboard
   signal KEYBOARD_SCAN       : std_logic_vector(5 downto 0);
   signal KEYBOARD_RESPONSE   : std_logic_vector(1 downto 0);

   -- GTIA Consol Keys
   signal CONSOL_START        : std_logic;
   signal CONSOL_SELECT       : std_logic;
   signal CONSOL_OPTION       : std_logic;
   signal FKEYS               : std_logic_vector(11 downto 0); 
   signal PS2_KEYS            : std_logic_vector(511 downto 0);
   
   -- Gamepads
   signal GAMEPAD0            : std_logic_vector(7 downto 0);
   signal GAMEPAD1            : std_logic_vector(7 downto 0);
   signal JOY1_n              : std_logic_vector(4 downto 0);
   signal JOY2_n              : std_logic_vector(4 downto 0);

   -- Video
   signal VIDEO_R             : std_logic_vector(7 downto 0);
   signal VIDEO_G             : std_logic_vector(7 downto 0);
   signal VIDEO_B             : std_logic_vector(7 downto 0);
   signal VIDEO_VS            : std_logic;
   signal VIDEO_HS            : std_logic;

   signal PAL                 : std_logic := '0';
   signal VGA                 : std_logic := '1';
   signal SCANLINES           : std_logic := '0';

   -- Scandoubler
   signal SCANDOUBLE_CLK      : std_logic;
   signal HALF_SCANDOUBLE_ENABLE_REG : std_logic;
	signal HALF_SCANDOUBLE_ENABLE_NEXT : std_logic;

   -- Audio
   signal AUDIO_L_PCM         : std_logic_vector(15 downto 0);
   signal AUDIO_R_PCM         : std_logic_vector(15 downto 0); 

   -- SDRAM (SRAM)
   signal SDRAM_REQUEST       : std_logic;
   signal SDRAM_REQUEST_COMPLETE : std_logic;
   signal SDRAM_WRITE_ENABLE  : std_logic;
   signal SDRAM_ADDR          : std_logic_vector(22 DOWNTO 0);
   signal SDRAM_DO            : std_logic_vector(31 DOWNTO 0);
   signal SDRAM_DI            : std_logic_vector(31 DOWNTO 0);
   signal SDRAM_WIDTH_8BIT_ACCESS : std_logic;
   signal SDRAM_WIDTH_16BIT_ACCESS : std_logic;
   signal SDRAM_WIDTH_32BIT_ACCESS : std_logic; 
   
   -- DMA/Virtual Drive
   signal DMA_ADDR_FETCH      : std_logic_vector(23 downto 0);
   signal DMA_WRITE_DATA      : std_logic_vector(31 downto 0);
   signal DMA_FETCH           : std_logic;
   signal DMA_32BIT_WRITE_ENABLE : std_logic;
   signal DMA_16BIT_WRITE_ENABLE : std_logic;
   signal DMA_8BIT_WRITE_ENABLE : std_logic;
   signal DMA_READ_ENABLE     : std_logic;
   signal DMA_MEMORY_READY    : std_logic;
   signal DMA_MEMORY_DATA     : std_logic_vector(31 downto 0);

   signal ZPU_ADDR_ROM        : std_logic_vector(15 downto 0);
   signal ZPU_ROM_DATA        : std_logic_vector(31 downto 0);
   signal ZPU_OUT1            : std_logic_vector(31 downto 0);

   -- System Control from ZPU
   signal ZPU_POKEY_ENABLE    : std_logic;

   signal ZPU_SIO_TXD         : std_logic;
   signal ZPU_SIO_RXD         : std_logic;
   signal ZPU_SIO_COMMAND     : std_logic;

   alias  PAUSE_ATARI         : std_logic                    is ZPU_OUT1(0);
   alias  RESET_ATARI         : std_logic                    is ZPU_OUT1(1);
   alias  SPEED_6502          : std_logic_vector(5 downto 0) is ZPU_OUT1(7 downto 2);
   alias  RAM_SELECT          : std_logic_vector(2 downto 0) is ZPU_OUT1(10 downto 8);
   alias  ROM_SELECT          : std_logic_vector(5 downto 0) is ZPU_OUT1(16 downto 11);

begin 

u_PLL : entity work.PLL
port map (
   CLKIN                      => CLK_50,
   CLKOUT                     => CLK,
   CLKOUT2                    => SCANDOUBLE_CLK,
   LOCKED                     => LOCKED );
   
u_DAC_L : entity work.dac
port map (
   CLK_I                      => CLK,
   RES_N_I                    => RESET_N,
   DAC_I                      => AUDIO_L_PCM,
   DAC_O                      => SOUND_L );

u_DAC_R : entity work.dac
port map (
   CLK_I                      => CLK,
   RES_N_I                    => RESET_N,
   DAC_I                      => AUDIO_R_PCM,
   DAC_O                      => SOUND_R );

u_KEYBOARD : entity work.ps2_to_atari800
port map(
   CLK                        => CLK,
   RESET_N                    => RESET_N,
   PS2_CLK                    => KB_CLK,
   PS2_DAT                    => KB_DAT,
   KEYBOARD_SCAN              => KEYBOARD_SCAN,
   KEYBOARD_RESPONSE          => KEYBOARD_RESPONSE,
   CONSOL_START               => CONSOL_START,
   CONSOL_SELECT              => CONSOL_SELECT,
   CONSOL_OPTION              => CONSOL_OPTION,
   FKEYS                      => FKEYS,
   PS2_KEYS                   => PS2_KEYS );

u_JOYSTICKS : entity work.nes_gamepad
port map( 
   CLK                        => CLK,
   RESET                      => not RESET_N,
   JOY_CLK                    => JOY_CLK,
   JOY_LOAD                   => JOY_LOAD,
   JOY_DATA0                  => JOY_DATA0,
   JOY_DATA1                  => JOY_DATA1,
   JOY0_BUTTONS               => GAMEPAD0,
   JOY1_BUTTONS               => GAMEPAD1,
   JOY0_CONNECTED             => OPEN,
   JOY1_CONNECTED             => OPEN );

u_ATARI800_CORE : entity work.atari800core_simple_sdram
generic map(
   CYCLE_LENGTH               => 16,
   INTERNAL_ROM               => 0,
   INTERNAL_RAM               => 0,
   PALETTE                    => 0,
   VIDEO_BITS                 => 8 )
port map(
   CLK                        => CLK,
   RESET_N                    => RESET_N and not (RESET_ATARI),

   VIDEO_VS                   => VIDEO_VS,
   VIDEO_HS                   => VIDEO_HS,
   VIDEO_B                    => VIDEO_B,
   VIDEO_G                    => VIDEO_G,
   VIDEO_R                    => VIDEO_R,
   VIDEO_BLANK                => OPEN,
   VIDEO_BURST                => OPEN,
   VIDEO_START_OF_FIELD       => OPEN,
   VIDEO_ODD_LINE             => OPEN,

   AUDIO_L                    => AUDIO_L_PCM,
   AUDIO_R                    => AUDIO_R_PCM,
   
   JOY1_n                     => JOY1_n, 
   JOY2_n                     => JOY2_n, 

   KEYBOARD_RESPONSE          => KEYBOARD_RESPONSE,
   KEYBOARD_SCAN              => KEYBOARD_SCAN,

   SIO_COMMAND                => ZPU_SIO_COMMAND,
   SIO_RXD                    => ZPU_SIO_TXD,
   SIO_TXD                    => ZPU_SIO_RXD,

   CONSOL_OPTION              => CONSOL_OPTION,
   CONSOL_SELECT              => CONSOL_SELECT,
   CONSOL_START               => CONSOL_START,

   SDRAM_REQUEST              => SDRAM_REQUEST,
   SDRAM_REQUEST_COMPLETE     => SDRAM_REQUEST_COMPLETE,
   SDRAM_READ_ENABLE          => OPEN,
   SDRAM_WRITE_ENABLE         => SDRAM_WRITE_ENABLE,
   SDRAM_ADDR                 => SDRAM_ADDR,
   SDRAM_DO                   => SDRAM_DO,
   SDRAM_DI                   => SDRAM_DI,
   SDRAM_32BIT_WRITE_ENABLE   => SDRAM_WIDTH_32BIT_ACCESS,
   SDRAM_16BIT_WRITE_ENABLE   => SDRAM_WIDTH_16BIT_ACCESS,
   SDRAM_8BIT_WRITE_ENABLE    => SDRAM_WIDTH_8BIT_ACCESS,
   SDRAM_REFRESH              => OPEN,

   DMA_FETCH                  => DMA_FETCH,
   DMA_READ_ENABLE            => DMA_READ_ENABLE,
   DMA_32BIT_WRITE_ENABLE     => DMA_32BIT_WRITE_ENABLE,
   DMA_16BIT_WRITE_ENABLE     => DMA_16BIT_WRITE_ENABLE,
   DMA_8BIT_WRITE_ENABLE      => DMA_8BIT_WRITE_ENABLE,
   DMA_ADDR                   => DMA_ADDR_FETCH,
   DMA_WRITE_DATA             => DMA_WRITE_DATA,
   MEMORY_READY_DMA           => DMA_MEMORY_READY,
   DMA_MEMORY_DATA            => DMA_MEMORY_DATA, 

   RAM_SELECT                 => RAM_SELECT,
   ROM_SELECT                 => ROM_SELECT,
   PAL                        => PAL,
   HALT                       => PAUSE_ATARI,
   THROTTLE_COUNT_6502        => SPEED_6502 );

u_SRAM : entity work.sram_statemachine

port map (
   CLK                        => CLK,
   RESET_N                    => RESET_N and not (RESET_ATARI),

   ADDRESS_IN                 => SDRAM_ADDR,
   DATA_IN                    => SDRAM_DI,
   DATA_OUT                   => SDRAM_DO,
   WRITE_EN                   => SDRAM_WRITE_ENABLE,
   REQUEST                    => SDRAM_REQUEST,
   BYTE_ACCESS                => SDRAM_WIDTH_8BIT_ACCESS,
   WORD_ACCESS                => SDRAM_WIDTH_16BIT_ACCESS,
   LONGWORD_ACCESS            => SDRAM_WIDTH_32BIT_ACCESS,
   COMPLETE                   => SDRAM_REQUEST_COMPLETE,

   SRAM_ADDR                  => SRAM_A,
   SRAM_DQ                    => SRAM_D,
   SRAM_CE0_N                 => SRAM_CE0,
   SRAM_CE1_N                 => SRAM_CE1,
   SRAM_OE_N                  => SRAM_OE,
   SRAM_WE_N                  => SRAM_WE,
   SRAM_UB_N                  => SRAM_UB,
   SRAM_LB_N                  => SRAM_LB );

u_ZPU : entity work.zpucore
generic map (
   PLATFORM                   => 1,
   SPI_CLOCK_DIV              => 1 )
port map (
   CLK                        => CLK,
   RESET_N                    => RESET_N,

   ZPU_ADDR_FETCH             => DMA_ADDR_FETCH,
   ZPU_DATA_OUT               => DMA_WRITE_DATA,
   ZPU_FETCH                  => DMA_FETCH,
   ZPU_32BIT_WRITE_ENABLE     => DMA_32BIT_WRITE_ENABLE,
   ZPU_16BIT_WRITE_ENABLE     => DMA_16BIT_WRITE_ENABLE,
   ZPU_8BIT_WRITE_ENABLE      => DMA_8BIT_WRITE_ENABLE,
   ZPU_READ_ENABLE            => DMA_READ_ENABLE,
   ZPU_MEMORY_READY           => DMA_MEMORY_READY,
   ZPU_MEMORY_DATA            => DMA_MEMORY_DATA, 

   ZPU_ADDR_ROM               => ZPU_ADDR_ROM,
   ZPU_ROM_DATA               => ZPU_ROM_DATA,

   ZPU_SD_DAT0                => SD_MISO,
   ZPU_SD_CLK                 => SD_SCK,
   ZPU_SD_CMD                 => SD_MOSI,
   ZPU_SD_DAT3                => SD_CS,

   ZPU_POKEY_ENABLE           => ZPU_POKEY_ENABLE,
   ZPU_SIO_TXD                => ZPU_SIO_TXD,
   ZPU_SIO_RXD                => ZPU_SIO_RXD,
   ZPU_SIO_COMMAND            => ZPU_SIO_COMMAND,

   ZPU_IN1                    => X"00000" & FKEYS,
   ZPU_IN2                    => X"00000000",
   ZPU_IN3                    => X"00000000",
   ZPU_IN4                    => X"00000000",

   ZPU_OUT1                   => ZPU_OUT1,
   ZPU_OUT2                   => OPEN,
   ZPU_OUT3                   => OPEN,
   ZPU_OUT4                   => OPEN );

u_ZPUROM : entity work.zpu_rom
port map (
   CLOCK                      => CLK,
   ADDRESS                    => ZPU_ADDR_ROM(13 downto 2),
   Q                          => ZPU_ROM_DATA );

u_ZPUPOKEY : entity work.enable_divider
generic map (
   COUNT                      => 16 )
port map (
   CLK                        => CLK,
   RESET_N                    => RESET_N,
   ENABLE_IN                  => '1',
   ENABLE_OUT                 => ZPU_POKEY_ENABLE);

-- Scandoubler
process(SCANDOUBLE_CLK, RESET_N, RESET_ATARI)
begin
   if ((RESET_N and not (RESET_ATARI)) = '0') then
      HALF_SCANDOUBLE_ENABLE_REG <= '0';
   elsif (SCANDOUBLE_CLK'event and SCANDOUBLE_CLK = '1') then
      HALF_SCANDOUBLE_ENABLE_REG <= HALF_SCANDOUBLE_ENABLE_NEXT;
   end if;
end process;

HALF_SCANDOUBLE_ENABLE_NEXT <= not(HALF_SCANDOUBLE_ENABLE_REG);

u_SCANDOUBLER : entity work.scandoubler
port map (
   CLK                        => SCANDOUBLE_CLK,
   RESET_N                    => RESET_N and not (RESET_ATARI),
   VGA                        => VGA,
   COMPOSITE_ON_HSYNC         => not VGA,

   COLOUR_ENABLE              => HALF_SCANDOUBLE_ENABLE_REG,
   DOUBLED_ENABLE             => VGA,
   
   SCANLINES_ON               => SCANLINES,
			
   COLOUR_IN                  => VIDEO_B,
   VSYNC_IN                   => VIDEO_VS,
   HSYNC_IN                   => VIDEO_HS,
			
   R                          => VGA_R,
   G                          => VGA_G,
   B                          => VGA_B,
			
   VSYNC                      => VGA_VSYNC,
   HSYNC                      => VGA_HSYNC );

RESET_N <= LOCKED and MCU_READY;

-- NES Gamepad 1 & Cursor keys on keyboard
JOY1_n <= (not GAMEPAD0(7) and not GAMEPAD0(6) and not PS2_KEYS(16#014#)) & 
                              (not GAMEPAD0(0) and not PS2_KEYS(16#174#)) & 
                              (not GAMEPAD0(1) and not PS2_KEYS(16#16B#)) & 
                              (not GAMEPAD0(2) and not PS2_KEYS(16#172#)) & 
                              (not GAMEPAD0(3) and not PS2_KEYS(16#175#)) ;

-- NES Gamepad 2
JOY2_n <= (not GAMEPAD1(7) and not GAMEPAD1(6)) & not GAMEPAD1(0) & not GAMEPAD1(1) & not GAMEPAD1(2) & not GAMEPAD1(3);

-- Switch video mode
-- VGA/TV (Ins)
process(PS2_KEYS)
begin
   if rising_edge(PS2_KEYS(16#170#)) then
      VGA <= not VGA;
   end if;
end process;

-- PAL/NTSC (Home)
process(PS2_KEYS)
begin
   if rising_edge(PS2_KEYS(16#16C#)) then
      PAL <= not PAL;
   end if;
end process;

-- Scanlines on/off (Page Up)
process(PS2_KEYS)
begin
   if rising_edge(PS2_KEYS(16#17D#)) then
      SCANLINES <= not SCANLINES;
   end if;
end process;

end rtl;

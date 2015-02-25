library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity korvet is
Port ( 
   CLK50          : in     std_logic;

   PS2_CLK        : in     std_logic;
   PS2_DATA       : in     std_logic; 

   SOUND_L        : out    std_logic;
   SOUND_R        : out    std_logic;

   SRAM_A         : out    std_logic_vector(17 downto 0);
   SRAM_D         : inout  std_logic_vector(15 downto 0);
   SRAM_WE        : out    std_logic;
   SRAM_OE        : out    std_logic;
   SRAM_CS        : out    std_logic;
   SRAM_LB        : out    std_logic;
   SRAM_UB        : out    std_logic;

   COMM_CSA       : in     std_logic;
   COMM_CSD       : in     std_logic;
   COMM_SCK       : in     std_logic;
   COMM_MOSI      : in     std_logic;
   COMM_MISO      : out    std_logic;
   COMM_REQ       : out    std_logic;
   
   VGA_R          : out    std_logic_vector(3 downto 0);
   VGA_G          : out    std_logic_vector(3 downto 0);
   VGA_B          : out    std_logic_vector(3 downto 0);
   VGA_HSYNC      : out    std_logic;
   VGA_VSYNC      : out    std_logic );
end korvet;

architecture RTL of korvet is

   -- Verilog Modules
   ----------------------------------------------------------
   component k580wm80a is
   port(
      clk      : in  std_logic;
      ce       : in  std_logic;
      reset    : in  std_logic;
      intr     : in  std_logic;
      idata    : in  std_logic_vector(7 downto 0);
      addr     : out std_logic_vector(15 downto 0);
      sync     : out std_logic;
      rd       : out std_logic;
      wr       : out std_logic;
      inta     : out std_logic;
      odata    : out std_logic_vector(7 downto 0) );
   end component;
   
--   component cpu8080 is
--  port(
--      addr     : out std_logic_vector(15 downto 0);
--      data     : in  std_logic_vector(7 downto 0);
--      datao    : out std_logic_vector(7 downto 0);
--      readmem  : out std_logic;
--      writemem : out std_logic;
--      readio   : out std_logic;
--      writeio  : out std_logic;
--      intr     : in  std_logic;
--      inta     : out std_logic;
--      waitr    : in  std_logic;
--      reset    : in  std_logic;
--      cke      : in  std_logic;
--      clock    : in  std_logic );
--   end component; 
   
   component k580wi53 is
   port(
      clk      : in  std_logic;
      c0       : in  std_logic;
      c1       : in  std_logic;
      c2       : in  std_logic;
      g0       : in  std_logic;
      g1       : in  std_logic;
      g2       : in  std_logic;
      out0     : out std_logic;
      out1     : out std_logic;
      out2     : out std_logic;
      addr     : in  std_logic_vector(1 downto 0);
      rd       : in  std_logic;
      we_n     : in  std_logic;
      idata    : in  std_logic_vector(7 downto 0);
      odata    : out std_logic_vector(7 downto 0) );
   end component;

   -- Memory Mapper Values -------------------------------------
   constant M_RAM       : std_logic_vector(2 downto 0) := "000";
   constant M_ROM       : std_logic_vector(2 downto 0) := "001";
   constant M_KEYBOARD  : std_logic_vector(2 downto 0) := "010";
   constant M_PORTBASE  : std_logic_vector(2 downto 0) := "011";
   constant M_REGBASE   : std_logic_vector(2 downto 0) := "100";
   constant M_CGRAM     : std_logic_vector(2 downto 0) := "101";
   constant M_VRAM      : std_logic_vector(2 downto 0) := "110";
   -------------------------------------------------------------    

   signal CLK           : std_logic;
   signal RESET         : std_logic := '1';
   signal TICK          : unsigned(3 downto 0);
   signal TICK2_0       : unsigned(1 downto 0);
   signal TICK2_1       : unsigned(4 downto 0);
   
   signal CPU_PAUSE     : std_logic;
   signal CPU_RESET     : std_logic;
   signal CPU_CLK       : std_logic;
   signal CPU_INTA      : std_logic;
   signal CPU_INTR      : std_logic;
   signal CPU_RD        : std_logic;
   signal CPU_SYNC      : std_logic;
   signal CPU_WR        : std_logic;
   signal CPU_A         : std_logic_vector(15 downto 0);
   signal CPU_DI        : std_logic_vector(7 downto 0);
   signal CPU_DO        : std_logic_vector(7 downto 0);   

   signal MAPPER_DO     : std_logic_vector(2 downto 0);
   signal KEYBOARD_DO   : std_logic_vector(7 downto 0);
   signal SYSREG        : std_logic_vector(4 downto 0); 
   signal COLORREG      : std_logic_vector(7 downto 0);

   signal KB_SG_RESET   : std_logic;
   
   signal CHRAM_WR      : std_logic;
   signal CHRAM_DO      : std_logic_vector(8 downto 0);
   signal CHRAM_VA      : std_logic_vector(9 downto 0);
   signal CHRAM_VD      : std_logic_vector(8 downto 0);
   
   signal PPI1_WR       : std_logic;
   signal PPI1_DO       : std_logic_vector(7 downto 0);
   signal PPI1_PAI      : std_logic_vector(7 downto 0);
   signal PPI1_PAO      : std_logic_vector(7 downto 0);
   signal PPI1_PBI      : std_logic_vector(7 downto 0);
   signal PPI1_PBO      : std_logic_vector(7 downto 0);
   signal PPI1_PCI      : std_logic_vector(7 downto 0);
   signal PPI1_PCO      : std_logic_vector(7 downto 0);

   signal PPI2_WR       : std_logic;
   signal PPI2_DO       : std_logic_vector(7 downto 0);
   signal PPI2_PAI      : std_logic_vector(7 downto 0);
   signal PPI2_PAO      : std_logic_vector(7 downto 0);
   signal PPI2_PBI      : std_logic_vector(7 downto 0);
   signal PPI2_PBO      : std_logic_vector(7 downto 0);
   signal PPI2_PCI      : std_logic_vector(7 downto 0);
   signal PPI2_PCO      : std_logic_vector(7 downto 0);

   signal PPI3_WR       : std_logic;
   signal PPI3_DO       : std_logic_vector(7 downto 0);
   signal PPI3_PAI      : std_logic_vector(7 downto 0);
   signal PPI3_PAO      : std_logic_vector(7 downto 0);
   signal PPI3_PBI      : std_logic_vector(7 downto 0);
   signal PPI3_PBO      : std_logic_vector(7 downto 0);
   signal PPI3_PCI      : std_logic_vector(7 downto 0);
   signal PPI3_PCO      : std_logic_vector(7 downto 0);
   
   signal PIC_WR        : std_logic;
   signal PIC_DO        : std_logic_vector(7 downto 0);

   signal TIMER_RD      : std_logic;
   signal TIMER_WR      : std_logic;
   signal TIMER_DO      : std_logic_vector(7 downto 0);
   signal TIMER_C0      : std_logic;
   signal TIMER_OUT0    : std_logic;

   signal CDI           : std_logic;
   signal CDO           : std_logic;
   signal VBLANK        : std_logic;
   signal VBLANK_2      : std_logic;
   signal VBLANK_TICK   : unsigned(3 downto 0);
   
   signal DRIVE         : std_logic_vector(1 downto 0);
   
   alias  FLOPPY_SIDE   : std_logic                    is PPI1_PBO(4);
   alias  DRV_SEL       : std_logic_vector(3 downto 0) is PPI1_PBO(3 downto 0);

   alias  VRAM_PAGE     : std_logic_vector(1 downto 0) is PPI1_PCO(7 downto 6);
   alias  INVON         : std_logic                    is PPI1_PCO(5);
   alias  INVOFF        : std_logic                    is PPI1_PCO(4);
   alias  WIDEFONT      : std_logic                    is PPI1_PCO(3);
   alias  ALTFONT       : std_logic                    is PPI1_PCO(2);
   alias  VIEW_PAGE     : std_logic_vector(1 downto 0) is PPI1_PCO(1 downto 0);
   
   alias  TAPE_OUT0     : std_logic                    is PPI2_PCO(0);
   alias  TAPE_OUT1     : std_logic                    is PPI2_PCO(1);
   alias  SOUND_EN      : std_logic                    is PPI2_PCO(3);
   
   signal RAM_DO        : std_logic_vector(7 downto 0);
   signal ROM_DO        : std_logic_vector(7 downto 0);
   signal VRAM_DO       : std_logic_vector(7 downto 0);

   signal SRAM_DI       : std_logic_vector(15 downto 0);
   signal SRAM_DO       : std_logic_vector(15 downto 0);
   
   signal LUT_A         : std_logic_vector(3 downto 0);
   signal LUT_D         : std_logic_vector(3 downto 0);

   signal FONTROM_A     : std_logic_vector(11 downto 0);
   signal FONTROM_DO    : std_logic_vector(7 downto 0);
   
   signal CACHE_AI      : std_logic_vector(5 downto 0);
   signal CACHE_DI      : std_logic_vector(31 downto 0);
   signal CACHE_WE      : std_logic;
   signal CACHE_AO      : std_logic_vector(5 downto 0);
   signal CACHE_DO      : std_logic_vector(31 downto 0);
   signal CACHE_SWAP    : std_logic;
   signal CACHE_CNT     : unsigned(5 downto 0);
   signal CACHE_RD      : std_logic;
   
   signal PLANE0        : std_logic_vector(7 downto 0);  -- PLANEs - temporary data from VRAM for write to cache and read/write VRAM
   signal PLANE1        : std_logic_vector(7 downto 0);
   signal PLANE2        : std_logic_vector(7 downto 0);

   signal SCANLINE      : std_logic_vector(7 downto 0); 
   
   signal SOUND         : std_logic;
--   signal SOUND_L       : std_logic_vector(15 downto 0);
--   signal SOUND_R       : std_logic_vector(15 downto 0);
   signal TAPE_IN       : std_logic;
   
   signal FLOPPY_DO     : std_logic_vector(7 downto 0); 
   signal PAUSE_ONESHOT  : std_logic;

   signal COMM_ADDR_O   : std_logic_vector(7 downto 0);
   signal COMM_ADDR_I   : std_logic_vector(7 downto 0);
   signal COMM_ADDR_REQ : std_logic;
   signal COMM_ADDR_ACK : std_logic;
   signal COMM_DATA_O   : std_logic_vector(7 downto 0);
   signal COMM_DATA_I   : std_logic_vector(7 downto 0);
   signal COMM_DATA_REQ : std_logic;
   signal COMM_DATA_ACK : std_logic;

   type LUT_T is array (0 to 15) of std_logic_vector(3 downto 0);
   signal LUT : LUT_T;
   
   -- Memory Controller Statemachine
   type STATE_TYPE is (ST_IDLE, ST_RAMREAD, ST_RAMWRITE1, ST_RAMWRITE2, ST_CACHEREAD1, ST_CACHEREAD2, ST_CACHEREAD3, ST_CACHEREAD4,
                       ST_VRAMREAD1, ST_VRAMREAD2, ST_VRAMREAD3, ST_VRAMREAD4, ST_VRAMREAD5,
                       ST_VRAMWRITE1, ST_VRAMWRITE2, ST_VRAMWRITE3, ST_VRAMWRITE4, ST_VRAMWRITE5, ST_VRAMWRITE6, ST_VRAMWRITE7, ST_VRAMWRITE8,
                       ST_FLOPPY1, ST_FLOPPY2, ST_FLOPPY3 );
   signal STATE : STATE_TYPE := ST_IDLE; 
   signal NSTATE : STATE_TYPE := ST_IDLE; 
   
begin

   -- PLL Make 32.5MHz Design Clock from 50MHz Oscillator
   ----------------------------------------------------------
   u_CLOCK : entity work.clock
   port map(
      CLK50          => CLK50,
      CLK            => CLK );

   -- Memory Mapper
   ----------------------------------------------------------
   u_MAPPER : entity work.mapper
   port map(
      CLKA           => CLK,
      ADDRA          => SYSREG & CPU_A(15 downto 8),
      DOUTA          => MAPPER_DO );  

   -- Memory Mapper
   ----------------------------------------------------------
   u_ROM : entity work.rom
   port map(
      CLKA           => CLK,
      ADDRA          => CPU_A(14 downto 0),
      DOUTA          => ROM_DO );  

   -- i8080 CPU
   ----------------------------------------------------------
   u_CPU : k580wm80a
   port map(
      clk            => CLK,
      ce             => CPU_CLK,
      reset          => CPU_RESET,
      intr           => CPU_INTR,
      idata          => CPU_DI,
      addr           => CPU_A,
      sync           => CPU_SYNC,
      rd             => CPU_RD,
      wr             => CPU_WR,
      inta           => CPU_INTA,
      odata          => CPU_DO );

   -- Character RAM
   ----------------------------------------------------------
   u_CHRAM : entity work.chram
   port map (
      CLK            => CLK,
      CHRAM_A        => CPU_A(9 downto 0),
      CHRAM_WR       => CHRAM_WR,
      CHRAM_DI       => CDI & CPU_DO,
      CHRAM_DO       => CHRAM_DO,
      CHRAM_VA       => CHRAM_VA,
      CHRAM_VD       => CHRAM_VD );
      
   -- VGA Video Controller
   ----------------------------------------------------------
   u_VIDEO : entity work.video
   port map( 
      CLK            => CLK,
      RESET          => RESET,
      CACHE_SWAP     => CACHE_SWAP,
      CACHE_A        => CACHE_AO,
      CACHE_D        => CACHE_DO,
      CURRENT_LINE   => SCANLINE,
      LUT_A          => LUT_A,
      LUT_D          => LUT_D,
      VBLANK         => VBLANK,
      R              => VGA_R,
      G              => VGA_G,
      B              => VGA_B,
      HSYNC          => VGA_HSYNC,
      VSYNC          => VGA_VSYNC ); 

   -- Keyboard Controller
   ----------------------------------------------------------
   u_KEYBOARD : entity work.keyboard
   port map(
      clk            => CLK,
      reset          => RESET,
      o_reset        => KB_SG_RESET,
      PS2_Clk        => PS2_CLK,
      PS2_Data       => PS2_DATA,
      Key_Addr       => CPU_A(8 downto 0),
      Key_Data       => KEYBOARD_DO );
      
   -- Font ROM
   ----------------------------------------------------------
   u_FONTROM : ENTITY work.fontrom
	PORT MAP(
		ADDRA 	      => FONTROM_A,
		CLKA		      => CLK,
		DOUTA	         => FONTROM_DO);
      
   -- Video Scanline Cache
   ----------------------------------------------------------
   u_CACHE : entity work.cache
   port map (	
      CLK            => CLK,
      AI             => CACHE_AI,
      DI             => CACHE_DI,
      WE             => CACHE_WE,
      AO             => CACHE_AO,
      DO             => CACHE_DO,
      CACHE          => CACHE_SWAP ); 
      
   -- i8255 - PPI1 Controller
   ----------------------------------------------------------
   u_PPI1 : entity work.i8255
   port map(
      CLK         => CLK,
      RESET       => CPU_RESET,
      A           => CPU_A(1 downto 0),
      DI          => CPU_DO,
      DO          => PPI1_DO,
      WR          => PPI1_WR,
      PAI         => PPI1_PAI,
      PAO         => PPI1_PAO,
      PBI         => PPI1_PBI,
      PBO         => PPI1_PBO,
      PCI         => PPI1_PCI,
      PCO         => PPI1_PCO );
      
   PPI1_PAI <= "1111" & CDI & '0' & VBLANK & not TAPE_IN;
   PPI1_PBI <= "00000000";
   PPI1_PCI <= "00000000";

   -- i8255 - PPI2 Controller
   ----------------------------------------------------------
   u_PPI2 : entity work.i8255
   port map(
      CLK         => CLK,
      RESET       => CPU_RESET,
      A           => CPU_A(1 downto 0),
      DI          => CPU_DO,
      DO          => PPI2_DO,
      WR          => PPI2_WR,
      PAI         => PPI2_PAI,
      PAO         => PPI2_PAO,
      PBI         => PPI2_PBI,
      PBO         => PPI2_PBO,
      PCI         => PPI2_PCI,
      PCO         => PPI2_PCO );
   
   PPI2_PAI <= "00000000";
   PPI2_PBI <= "00000000";
   PPI2_PCI <= "00000000";

   -- i8255 - PPI3 Controller
   ----------------------------------------------------------
   u_PPI3 : entity work.i8255
   port map(
      CLK         => CLK,
      RESET       => CPU_RESET,
      A           => CPU_A(1 downto 0),
      DI          => CPU_DO,
      DO          => PPI3_DO,
      WR          => PPI3_WR,
      PAI         => PPI3_PAI,
      PAO         => PPI3_PAO,
      PBI         => PPI3_PBI,
      PBO         => PPI3_PBO,
      PCI         => PPI3_PCI,
      PCO         => PPI3_PCO );
      
   PPI3_PAI <= "00000000";
   PPI3_PBI <= "00000000";
   PPI3_PCI <= "00000000";

   -- i8259 - Programmable Interrupt Controller
   ----------------------------------------------------------
   u_PIC : entity work.i8259
   port map(
      CLK         => CLK,
      RESET       => CPU_RESET,
      A0          => CPU_A(0),
      WR          => PIC_WR,
      INTA        => CPU_INTA,
      INTR        => CPU_INTR,
      IRQ         => "000" & (VBLANK and not PAUSE_ONESHOT) & "0000",
      DI          => CPU_DO,
      DO          => PIC_DO );
      
   -- i8253 - Timer
   ----------------------------------------------------------
   u_TIMER : k580wi53
   port map (
      clk         => CLK,
      c0          => TIMER_C0, -- 2MHz Clock for Sound Generation
      c1          => '0', -- for RS232
      c2          => '0', -- HBL 65.6 µS Period for Interrupt
      g0          => '1',
      g1          => '1',
      g2          => '1',
      out0        => TIMER_OUT0,
      out1        => OPEN,
      out2        => OPEN,
      addr        => CPU_A(1 downto 0),
      rd          => TIMER_RD,
      we_n        => not TIMER_WR,
      idata       => CPU_DO,
      odata       => TIMER_DO );

   u_SPI : entity work.spi_comm
   port map(   
      CLK            => CLK,
      RESET          => RESET,

      SPI_CS_A       => COMM_CSA,
      SPI_CS_D       => COMM_CSD,
      SPI_SCK        => COMM_SCK,
      SPI_DI         => COMM_MOSI,
      SPI_DO         => COMM_MISO,

      ADDR_O         => COMM_ADDR_O,
      ADDR_I         => COMM_ADDR_I,
      ADDR_REQ       => COMM_ADDR_REQ,
      ADDR_ACK       => COMM_ADDR_ACK,

      DATA_O         => COMM_DATA_O,
      DATA_I         => COMM_DATA_I,
      DATA_REQ       => COMM_DATA_REQ,
      DATA_ACK       => COMM_DATA_ACK ); 

u_ONESHOT_RESET : entity work.oneshot
port map(
    CLK         => CLK,
    RESET       => RESET,
    ONESHOT_IN  => CPU_PAUSE,
    ONESHOT_OUT => PAUSE_ONESHOT );

   -- Select active Floppy Drive
   ----------------------------------------------------------
   floppy_drive : process(DRV_SEL)
   begin
      case DRV_SEL is
         when X"0"   => DRIVE <= "00";
         when X"1"   => DRIVE <= "00";
         when X"2"   => DRIVE <= "01";
         when X"3"   => DRIVE <= "01";
         when X"4"   => DRIVE <= "10";
         when X"5"   => DRIVE <= "01";
         when X"6"   => DRIVE <= "10";
         when X"7"   => DRIVE <= "01";
         when X"8"   => DRIVE <= "11";
         when X"9"   => DRIVE <= "00";
         when X"A"   => DRIVE <= "01";
         when X"B"   => DRIVE <= "00";
         when X"C"   => DRIVE <= "00";
         when X"D"   => DRIVE <= "01";
         when X"E"   => DRIVE <= "00";
         when X"F"   => DRIVE <= "01";
         when others => DRIVE <= "00";      
      end case;
   end process;
      
   -- Generate Global Reset and CPU Reset & Clock
   ----------------------------------------------------------
   design_reset : process(CLK)
   begin
      if rising_edge(CLK) then
         if KB_SG_RESET = '1' then
            TICK <= "0000";
            CPU_RESET <= '1';
            CPU_CLK <= '0';
         else
            CPU_CLK <= '0';
            if CPU_PAUSE = '0' then
               TICK <= TICK + 1;
               if TICK = 12 then
                  TICK <= "0000";
                  CPU_RESET <= '0';
                  RESET <= '0';
                  CPU_CLK <= '1';
               end if;
            end if;
         end if;
      end if;
   end process;

   -- Generate 2MHz Clock for Timer 0
   ----------------------------------------------------------
   process(CLK)
   begin
      if rising_edge(CLK) then
         if RESET = '1' then
            TICK2_0 <= "00";
            TICK2_1 <= "00000";
         else
            if TICK2_1 < 8 then
               TIMER_C0 <= '0';
            else
               TIMER_C0 <= '1';
            end if;
            TICK2_1 <= TICK2_1 + 1;
            if (TICK2_0 = "00" and TICK2_1 = 17) or TICK2_1 = 16 then
               TICK2_0 <= TICK2_0 + 1;
               TICK2_1 <= "00000";
            end if;
         end if;
      end if;
   end process;
   
   -- Character Inversion Logic
   ----------------------------------------------------------
   inversion_logic : process(CLK)
   begin
      if rising_edge(CLK) then 
         if INVON = '0' and INVOFF = '1' then
            CDI <= '1';
         elsif INVON = '1' and INVOFF = '0' then
            CDI <= '0';
         elsif INVON = '1' and INVOFF = '1' then
            CDI <= CDO;
         end if;
                           
         if INVON = '1' and INVOFF = '1' then
            CDO <= CHRAM_DO(8);
         end if;
      end if;
   end process;
   
   -- CPU Write
   ----------------------------------------------------------
   CHRAM_WR <= '1' when CPU_WR = '1' and MAPPER_DO = M_CGRAM else '0';
   PPI1_WR  <= '1' when CPU_WR = '1' and MAPPER_DO = M_PORTBASE and CPU_A(5 downto 3) = "111" else '0';
   PPI2_WR  <= '1' when CPU_WR = '1' and MAPPER_DO = M_PORTBASE and CPU_A(5 downto 3) = "110" else '0';
   PPI3_WR  <= '1' when CPU_WR = '1' and MAPPER_DO = M_PORTBASE and CPU_A(5 downto 3) = "001" else '0';
   PIC_WR   <= '1' when CPU_WR = '1' and MAPPER_DO = M_PORTBASE and CPU_A(5 downto 3) = "101" else '0';   
   TIMER_WR <= '1' when CPU_WR = '1' and MAPPER_DO = M_PORTBASE and CPU_A(5 downto 3) = "000" else '0';   

-- ########################################### TEST #####################################################

--   TIMER_RD <= '1' when CPU_RD = '1' and MAPPER_DO = M_PORTBASE and CPU_A(5 downto 3) = "000" else '0';   

   process(CLK)
   begin
      if rising_edge(CLK) then
         if RESET = '1' then
            TIMER_RD <= '0';
         else
            TIMER_RD <= '0';
            if TICK = 3 and CPU_RD = '1' and MAPPER_DO = M_PORTBASE and CPU_A(5 downto 3) = "000" then
               TIMER_RD <= '1';
            end if;
         end if;
      end if;
   end process;

-- ########################################### END TEST ################################################

   -- CPU Read
   ----------------------------------------------------------
   CPU_DI <=  PIC_DO   when CPU_INTA = '1' or (CPU_RD = '1' and MAPPER_DO = M_PORTBASE and CPU_A(5 downto 3) = "101")
--         else FLASH_D  when CPU_RD = '1' and MAPPER_DO = M_ROM
--         else RAM_DO   when CPU_RD = '1' and (MAPPER_DO = M_RAM or MAPPER_DO = M_REGBASE)
         else ROM_DO   when CPU_RD = '1' and MAPPER_DO = M_ROM
         else RAM_DO   when CPU_RD = '1' and (MAPPER_DO = M_RAM or MAPPER_DO = M_REGBASE)
         else PPI3_DO  when CPU_RD = '1' and MAPPER_DO = M_PORTBASE and CPU_A(5 downto 3) = "001"
         else PPI2_DO  when CPU_RD = '1' and MAPPER_DO = M_PORTBASE and CPU_A(5 downto 3) = "110"
         else PPI1_DO  when CPU_RD = '1' and MAPPER_DO = M_PORTBASE and CPU_A(5 downto 3) = "111"
         else TIMER_DO when CPU_RD = '1' and MAPPER_DO = M_PORTBASE and CPU_A(5 downto 3) = "000"
         else FLOPPY_DO when CPU_RD = '1' and MAPPER_DO = M_PORTBASE and CPU_A(5 downto 3) = "011"
         else CHRAM_DO(7 downto 0) when CPU_RD = '1' and MAPPER_DO = M_CGRAM
         else VRAM_DO  when CPU_RD = '1' and MAPPER_DO = M_VRAM
         else KEYBOARD_DO when CPU_RD = '1' and MAPPER_DO = M_KEYBOARD
         else "11111111";   
         
   -- SRAM Arbiter / Controller
   ----------------------------------------------------------
   SRAM_DO <= SRAM_D;
   SRAM_D <= SRAM_DI;
   
   process(CLK)
   begin
      if rising_edge(CLK) then
         if CPU_RESET = '1' then
            STATE <= ST_IDLE;
            SRAM_A <= (others => '0');
            SRAM_DI <= (others => 'Z');
            SRAM_CS <= '1';
            SRAM_OE <= '1';
            SRAM_WE <= '1';
            SRAM_LB <= '1';
            SRAM_UB <= '1';
            CACHE_WE <= '0';
            CACHE_CNT <= "111111";    
            SYSREG <= "00000";
            COLORREG <= "00000000";
            CACHE_RD <= '0';
            CPU_PAUSE <= '0';
            COMM_REQ <= '0';
            FLOPPY_DO <= "00000000";
            COMM_ADDR_ACK <= '0';
            COMM_DATA_ACK <= '0';
         else
            COMM_ADDR_ACK <= '0';
            COMM_DATA_ACK <= '0';
            CACHE_WE <= '0';
            if CACHE_SWAP = '1' then
               CACHE_RD <= '1';
               CACHE_CNT <= "000000";    
            end if;
            
            case STATE is
               when ST_IDLE =>
                  if TICK = 3 then
                     if CPU_RD = '1' then
                        case MAPPER_DO is
                           when M_RAM | M_REGBASE =>
                              SRAM_A <= "00" & CPU_A;
                              SRAM_OE <= '0';
                              SRAM_WE <= '1';
                              SRAM_CS <= '0';
                              SRAM_LB <= '0';
                              SRAM_UB <= '1';
                              STATE <= ST_RAMREAD;
                           when M_VRAM =>
                              SRAM_A <= "00" & VRAM_PAGE & CPU_A(13 downto 0);
                              SRAM_LB <= '1';
                              SRAM_UB <= '0';
                              SRAM_OE <= '0';
                              SRAM_CS <= '0';
                              STATE <= ST_VRAMREAD1;
                           when M_PORTBASE =>   
                              if CPU_A(5 downto 3) = "011" then -- Read from Floppy
                                 COMM_REQ <= '1';
                                 COMM_ADDR_I <= '0' & FLOPPY_SIDE & DRIVE & "00" & CPU_A(1 downto 0);
                                 COMM_DATA_I <= X"FF";
                                 CPU_PAUSE <= '1';
                                 STATE <= ST_FLOPPY1;
                              end if;
                           when others =>
                              STATE <= ST_IDLE;
                        end case;
                     elsif CPU_WR = '1' then
                        case MAPPER_DO is
                           when M_RAM | M_ROM | M_KEYBOARD =>
                              SRAM_A <= "00" & CPU_A;
                              SRAM_WE <= '0';
                              SRAM_OE <= '1';
                              SRAM_CS <= '0';
                              SRAM_LB <= '0';
                              SRAM_UB <= '1';
                              SRAM_DI <= "ZZZZZZZZ" & CPU_DO;
                              STATE <= ST_RAMWRITE1;
                           when M_VRAM =>
                              SRAM_A <= "00" & VRAM_PAGE & CPU_A(13 downto 0);
                              SRAM_LB <= '1';
                              SRAM_UB <= '0';
                              SRAM_OE <= '0';
                              SRAM_CS <= '0';
                              STATE <= ST_VRAMWRITE1;
                           when M_REGBASE =>
                              if CPU_A(7) = '0' then
                                 SYSREG <= CPU_DO(6 downto 2);
                              elsif CPU_A(6) = '0' then
                                 COLORREG <= CPU_DO;
                              elsif CPU_A(2) = '0' then
                                 LUT(to_integer(unsigned(CPU_DO(3 downto 0)))) <= CPU_DO(7 downto 4);
                              end if;
                           when M_PORTBASE =>   
                              if CPU_A(5 downto 3) = "011" then -- Write to Floppy
                                 COMM_REQ <= '1';
                                 COMM_ADDR_I <= '1' & FLOPPY_SIDE & DRIVE & "00" & CPU_A(1 downto 0);
                                 COMM_DATA_I <= CPU_DO;
                                 CPU_PAUSE <= '1';
                                 STATE <= ST_FLOPPY1;
                              end if;
                           when others =>
                              STATE <= ST_IDLE;
                        end case;
                     else
                        if CACHE_RD = '1' then
                           CHRAM_VA <= SCANLINE(7 downto 4) & std_logic_vector(CACHE_CNT);
                           SRAM_A <= "00" & VIEW_PAGE & SCANLINE & std_logic_vector(CACHE_CNT);
                           SRAM_LB <= '1';
                           SRAM_UB <= '0';
                           SRAM_OE <= '0';
                           SRAM_CS <= '0';
                           STATE <= ST_CACHEREAD1;
                           NSTATE <= ST_IDLE;
                        end if;          
                     end if;
                  end if;
                  
               when ST_FLOPPY1 =>
                  if COMM_ADDR_REQ = '1' then
                     COMM_REQ <= '0';
                     COMM_ADDR_ACK <= '1';
                  elsif COMM_DATA_REQ = '1' then
                     COMM_DATA_ACK <= '1';
                     FLOPPY_DO <= COMM_DATA_O;
                     CPU_PAUSE <= '0';
                     STATE <= ST_FLOPPY3;
                  elsif CACHE_RD = '1' then
                     CHRAM_VA <= SCANLINE(7 downto 4) & std_logic_vector(CACHE_CNT);
                     SRAM_A <= "00" & VIEW_PAGE & SCANLINE & std_logic_vector(CACHE_CNT);
                     SRAM_LB <= '1';
                     SRAM_UB <= '0';
                     SRAM_OE <= '0';
                     SRAM_CS <= '0';
                     STATE <= ST_CACHEREAD1;
                     NSTATE <= ST_FLOPPY1;
                  end if;

               when ST_FLOPPY3 =>
                  if CPU_RD = '0' and CPU_WR = '0' then
                     STATE <= ST_IDLE;
                  end if;

               when ST_RAMREAD =>
                  RAM_DO <= SRAM_DO(7 downto 0);
                  SRAM_OE <= '1';
                  SRAM_CS <= '1';
                  SRAM_LB <= '1';
                  STATE <= ST_IDLE;
               
               when ST_RAMWRITE1 =>
                  SRAM_WE <= '1';
                  STATE <= ST_RAMWRITE2;

               when ST_RAMWRITE2 =>
                  SRAM_DI <= (OTHERS => 'Z');
                  SRAM_CS <= '1';
                  SRAM_LB <= '1';
                  STATE <= ST_IDLE;
                  
               when ST_CACHEREAD1 =>
                  PLANE0 <= SRAM_DO(15 downto 8);
                  SRAM_LB <= '0';
                  SRAM_UB <= '0';
                  SRAM_A <= "01" & VIEW_PAGE & SCANLINE & std_logic_vector(CACHE_CNT);
                  STATE <= ST_CACHEREAD2;
                
               when ST_CACHEREAD2 =>
                  PLANE1 <= SRAM_DO(15 downto 8);
                  PLANE2 <= SRAM_DO(7 downto 0);
                  SRAM_OE <= '1';
                  SRAM_CS <= '1';
                  SRAM_LB <= '1';
                  SRAM_UB <= '1';
                  FONTROM_A <= CHRAM_VD(7 downto 0) & SCANLINE(3 downto 0);
--                  FONTROM_A <= ALTFONT & CHRAM_VD(7 downto 0) & SCANLINE(3 downto 0);
                  STATE <= ST_CACHEREAD3;
                  
               when ST_CACHEREAD3 =>
                  STATE <= ST_CACHEREAD4;

               when ST_CACHEREAD4 =>
                  CACHE_AI <= std_logic_vector(CACHE_CNT(5 downto 0));
                  if CHRAM_VD(8) = '0' then
                     CACHE_DI <= FONTROM_DO & PLANE2 & PLANE1 & PLANE0;
                  else
                     CACHE_DI <= (not FONTROM_DO) & PLANE2 & PLANE1 & PLANE0;
                  end if;
                  CACHE_WE <= '1'; 
                  if CACHE_CNT = "111111" then
                     CACHE_RD <= '0';
                  else
                     CACHE_CNT <= CACHE_CNT + 1;
                  end if;
                  STATE <= NSTATE;

               when ST_VRAMREAD1 =>
                  PLANE0 <= SRAM_DO(15 downto 8);
                  SRAM_LB <= '0';
                  SRAM_UB <= '0';
                  SRAM_A <= "01" & VRAM_PAGE & CPU_A(13 downto 0);
                  STATE <= ST_VRAMREAD2;

               when ST_VRAMREAD2 =>
                  PLANE1 <= SRAM_DO(15 downto 8);
                  PLANE2 <= SRAM_DO(7 downto 0);
                  SRAM_LB <= '1';
                  SRAM_UB <= '1';
                  SRAM_OE <= '1';
                  SRAM_CS <= '1';
                  SRAM_WE <= '1';
                  STATE <= ST_VRAMREAD3;
               
               when ST_VRAMREAD3 =>
                  if COLORREG(7) = '1' then  -- color mode
                     if COLORREG(4) = '0' then 
                        PLANE0 <= PLANE0 xor "11111111";
                     end if;
                     if COLORREG(5) = '0' then 
                        PLANE1 <= PLANE1 xor "11111111";
                     end if;
                     if COLORREG(6) = '0' then 
                        PLANE2 <= PLANE2 xor "11111111";
                     end if;
                  else                       -- plane mode
                     if COLORREG(4) = '1' then
                        VRAM_DO <= PLANE0;
                     else
                        VRAM_DO <= "00000000";
                     end if;
                  end if;
                  STATE <= ST_VRAMREAD4;

               when ST_VRAMREAD4 =>
                  if COLORREG(7) = '1' then
                     VRAM_DO <= (PLANE0 and PLANE1 and PLANE2) xor "11111111";
                  else
                     if COLORREG(5) = '1' then
                        VRAM_DO <= PLANE1;
                     end if;                  
                  end if;
                  STATE <= ST_VRAMREAD5;

               when ST_VRAMREAD5 =>
                  if COLORREG(7) = '0' then
                     if COLORREG(6) = '1' then
                        VRAM_DO <= PLANE2;
                     end if;                  
                  end if;
                  STATE <= ST_IDLE;                  

               when ST_VRAMWRITE1 =>
                  PLANE0 <= SRAM_DO(15 downto 8);
                  SRAM_LB <= '0';
                  SRAM_UB <= '0';
                  SRAM_A <= "01" & VRAM_PAGE & CPU_A(13 downto 0);
                  STATE <= ST_VRAMWRITE2;

               when ST_VRAMWRITE2 =>
                  PLANE1 <= SRAM_DO(15 downto 8);
                  PLANE2 <= SRAM_DO(7 downto 0);
                  SRAM_OE <= '1';
                  SRAM_CS <= '1';
                  SRAM_LB <= '1';
                  SRAM_UB <= '1';
                  SRAM_WE <= '1';
                  STATE <= ST_VRAMWRITE3;
               
               when ST_VRAMWRITE3 =>
                  if COLORREG(7) = '1' then  -- color mode
                     if COLORREG(1) = '1' then
                        PLANE0 <= PLANE0 or CPU_DO;
                     else
                        PLANE0 <= PLANE0 and not CPU_DO;
                     end if;
                     if COLORREG(2) = '1' then
                        PLANE1 <= PLANE1 or CPU_DO;
                     else
                        PLANE1 <= PLANE1 and not CPU_DO;
                     end if;
                     if COLORREG(3) = '1' then
                        PLANE2 <= PLANE2 or CPU_DO;
                     else
                        PLANE2 <= PLANE2 and not CPU_DO;
                     end if;
                  else                       -- plane mode
                     if COLORREG(0) = '1' then     -- write 1
                        if COLORREG(1) = '0' then
                           PLANE0 <= PLANE0 or CPU_DO;
                        end if;
                        if COLORREG(2) = '0' then
                           PLANE1 <= PLANE1 or CPU_DO;
                        end if;
                        if COLORREG(3) = '0' then
                           PLANE2 <= PLANE2 or CPU_DO;
                        end if;
                     else                          -- write 0
                        if COLORREG(1) = '0' then
                           PLANE0 <= PLANE0 and not CPU_DO;
                        end if;
                        if COLORREG(2) = '0' then
                           PLANE1 <= PLANE1 and not CPU_DO;
                        end if;
                        if COLORREG(3) = '0' then
                           PLANE2 <= PLANE2 and not CPU_DO;
                        end if;
                     end if;
                  end if;
                  STATE <= ST_VRAMWRITE4;
               
               when ST_VRAMWRITE4 =>
                  SRAM_LB <= '1';
                  SRAM_UB <= '0';
                  SRAM_A <= "00" & VRAM_PAGE & CPU_A(13 downto 0);
                  SRAM_WE <= '0';
                  SRAM_CS <= '0';
                  SRAM_DI <= PLANE0 & "ZZZZZZZZ";
                  STATE <= ST_VRAMWRITE5;

               when ST_VRAMWRITE5 =>
                  SRAM_WE <= '1';
                  STATE <= ST_VRAMWRITE6;

               when ST_VRAMWRITE6 =>
                  SRAM_LB <= '0';
                  SRAM_UB <= '0';
                  SRAM_A <= "01" & VRAM_PAGE & CPU_A(13 downto 0);
                  SRAM_WE <= '0';
                  SRAM_DI <= PLANE1 & PLANE2;
                  STATE <= ST_VRAMWRITE7;

               when ST_VRAMWRITE7 =>
                  SRAM_WE <= '1';
                  STATE <= ST_VRAMWRITE8;

               when ST_VRAMWRITE8 =>
                  SRAM_LB <= '1';
                  SRAM_UB <= '1';
                  SRAM_CS <= '1';
                  SRAM_OE <= '1';
                  SRAM_DI <= "ZZZZZZZZZZZZZZZZ";
                  STATE <= ST_IDLE;

               when OTHERS =>
                  STATE <= ST_IDLE;
                  
            end case;         
         end if;
      end if;
   end process;
         
   LUT_D <= LUT(to_integer(unsigned(LUT_A)));
   
   SOUND <= TIMER_OUT0 and SOUND_EN;

   SOUND_L <= SOUND;
   SOUND_R <= SOUND;
   
--   SOUND_L <= "000" & SOUND & "00" & TAPE_OUT0 & TAPE_IN & "00000000" when SWITCH(8) = '1' else "00" & TAPE_OUT0 & "0000000000000";
--   SOUND_R <= "000" & SOUND & "00" & TAPE_OUT0 & TAPE_IN & "00000000" when SWITCH(8) = '1' else "00" & TAPE_OUT0 & "0000000000000";
   
end RTL;

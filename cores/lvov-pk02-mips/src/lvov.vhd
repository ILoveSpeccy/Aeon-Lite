library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- SRAM is used for Lvov Main 64Kb RAM
-- FPGA is used for all ROM's (16Kb Standard, 16Kb Chameleon )
-- FPGA is used for 16Kb Dual Port VRAM

entity lvov is
Port (
   CLK50       : IN  STD_LOGIC;
   
   PS2_CLK     : in  STD_LOGIC;
   PS2_DATA    : in  STD_LOGIC;
   
   SRAM_A      : out    std_logic_vector(17 downto 0);
   SRAM_D      : inout  std_logic_vector(15 downto 0);
   SRAM_WE     : buffer    std_logic;
   SRAM_OE     : buffer    std_logic;
   SRAM_CE0    : buffer    std_logic;
   SRAM_CE1    : buffer    std_logic;	
   SRAM_LB     : buffer    std_logic;
   SRAM_UB     : buffer    std_logic;

   SOUND_L     : out    std_logic;
   SOUND_R     : out    std_logic;

   IO		      : out  std_logic_vector(15 downto 0);

   SD_MOSI     : out   std_logic;
   SD_MISO     : in    std_logic;
   SD_SCK      : out   std_logic;
   SD_CS       : out   std_logic; 
		
   VGA_R       : OUT STD_LOGIC_VECTOR(3 downto 0);
   VGA_G       : OUT STD_LOGIC_VECTOR(3 downto 0);
   VGA_B       : OUT STD_LOGIC_VECTOR(3 downto 0);
   VGA_HSYNC   : OUT STD_LOGIC;
   VGA_VSYNC   : OUT STD_LOGIC );
end lvov;

architecture Behavioral of lvov is

component T80se is
	generic (
		Mode 				: integer := 0;		-- 0 => Z80, 1 => Fast Z80, 2 => 8080, 3 => GB
		T2Write 			: integer := 1;		-- 0 => WR_n active in T3, /=0 => WR_n active in T2
		IOWait 			: integer := 1 );		-- 0 => Single cycle I/O, 1 => Std I/O cycle
	port (
		RESET_n			: in std_logic;
		CLK_n				: in std_logic;
		CLKEN				: in std_logic;
		WAIT_n			: in std_logic;
		INT_n				: in std_logic;
		NMI_n				: in std_logic;
		BUSRQ_n			: in std_logic;
		M1_n				: out std_logic;
		MREQ_n			: out std_logic;
		IORQ_n			: out std_logic;
		RD_n				: out std_logic;
		WR_n				: out std_logic;
		RFSH_n			: out std_logic;
		HALT_n			: out std_logic;
		BUSAK_n			: out std_logic;
		A					: out std_logic_vector(15 downto 0);
		DI					: in std_logic_vector(7 downto 0);
		DO					: out std_logic_vector(7 downto 0)
 );
end component;

  component mips_soc
	port (
		-- CLOCK
		CPU_CLK			: in std_logic;
		VGA_CLK			: in std_logic;
		CPU_RESET		: in std_logic;
		
		-- VGA
		VGA_R				: OUT STD_LOGIC_VECTOR(3 downto 0);	
		VGA_G				: OUT STD_LOGIC_VECTOR(3 downto 0);
		VGA_B				: OUT STD_LOGIC_VECTOR(3 downto 0);
		VGA_VSYNC		: out std_logic;
		VGA_HSYNC		: out std_logic;
		
		-- SRAM
		MEM_A       	: out std_logic_vector(31 downto 2);
		MEM_DI      	: out std_logic_vector(31 downto 0);
		MEM_DO      	: in  std_logic_vector(31 downto 0);
		MEM_MASK    	: out std_logic_vector(3  downto 0);
		MEM_WR      	: out std_logic;
		MEM_REQ     	: out std_logic;
		MEM_BUSY    	: in  std_logic;
		
		-- Keyboard
		KEYB_DATA   	: in  std_logic_vector(7 downto 0);

		-- Sound
		MIPS_BEEPER		: out std_logic;
		
		-- SD Card
		SD_MOSI     : out   std_logic;
		SD_MISO     : in    std_logic;
		SD_SCK      : out   std_logic;
		SD_CS       : out   std_logic;

		-- FDC Ports
		VG93_CLK					: in	std_logic;
		VG93_nCLR				: in	std_logic;
				
		VG93_IRQ					: out	std_logic;
		VG93_DRQ					: out	std_logic;
		
		VG93_A					: in	std_logic_vector(1 downto 0);
		VG93_D_IN				: in	std_logic_vector(7 downto 0);
		VG93_D_OUT				: out std_logic_vector(7 downto 0);	
		VG93_nCS					: in	std_logic;		
		VG93_nRD					: in	std_logic;
		VG93_nWR					: in	std_logic;
		
		VG93_nDDEN				: in	std_logic;
		VG93_HRDY				: in	std_logic;
		
		FDC_DRIVE				: in	std_logic_vector(1 downto 0);
		FDC_nSIDE				: in	std_logic;

		TST						: out std_logic
	);	
  end component;	

COMPONENT a8255 IS
   PORT(
      RESET : IN std_logic;
      CLK   : IN std_logic;
      nCS   : IN std_logic;
      nRD   : IN std_logic;
      nWR   : IN std_logic;
      A     : IN std_logic_vector (1 DOWNTO 0);
      DIN   : IN std_logic_vector (7 DOWNTO 0);
      PAIN  : IN std_logic_vector (7 DOWNTO 0);
      PBIN  : IN std_logic_vector (7 DOWNTO 0);
      PCIN  : IN std_logic_vector (7 DOWNTO 0);

      DOUT  : OUT std_logic_vector (7 DOWNTO 0);
      PAOUT : OUT std_logic_vector (7 DOWNTO 0);
      PAEN  : OUT std_logic;
      PBOUT : OUT std_logic_vector (7 DOWNTO 0);
      PBEN  : OUT std_logic;
      PCOUT : OUT std_logic_vector (7 DOWNTO 0);
      PCEN  : OUT std_logic_vector (7 DOWNTO 0)
   );

END COMPONENT;
	
   -- CLK 32.5 MHz is 1/2 of pixelxlock 1024x768@60Hz (65MHz)
   signal CLK        : std_logic;	
   signal nRESET     : std_logic := '0';
   signal TICK       : std_logic_vector(3 downto 0) := "0000";
	signal LOCKED		: std_logic;
	signal nRESET_MEM	: std_logic := '0';
   
   signal SRAM_DO    : std_logic_vector(7 downto 0);

   signal KEYB_A     : std_logic_vector(7 downto 0);
   signal KEYB_D     : std_logic_vector(7 downto 0);   
   signal KEYB_A2    : std_logic_vector(3 downto 0);
   signal KEYB_D2    : std_logic_vector(3 downto 0);   
   signal KEYB_CTRL  : std_logic_vector(7 downto 0);   
   
   signal COLORS     : std_logic_vector(6 downto 0);
   
	-- ROM_INIT = 1 on reset and maps ROM to address 0000
	-- ROM_INIT = 0 on first I/O write
   signal ROM_INIT   : std_logic := '1';

   -- CPU_CLK is 2.16MHz (32.5MHz/15) CPU Clock (Original 2.22MHz (20MHz/9))
   signal CPU_CLK    : std_logic;
   signal nCPU_RD    : std_logic;
   signal nCPU_WR	   : std_logic;
   signal CPU_A      : std_logic_vector(15 downto 0);
   signal RAM_A      : std_logic_vector(17 downto 0);	
   signal CPU_DI     : std_logic_vector(7 downto 0);
   signal CPU_DO     : std_logic_vector(7 downto 0);
   signal nIO_RQ     : std_logic;
   signal nMEM_RQ    : std_logic;
	signal nCPU_WAIT   : std_logic;
	
	signal LV_SRAM_DO		: std_logic_vector(7 downto 0);
	signal nLV_SRAM_CS	: std_logic;
	
	signal ROM_D      : std_logic_vector(7 downto 0); 

   signal SD_CLK_R   : std_logic;
   signal SD_DATA    : std_logic_vector(6 downto 0);   
   signal SD_O       : std_logic_vector(7 downto 0);   
   
   signal VRAM_DO    : std_logic_vector(7 downto 0);
   signal VRAM_WE    : std_logic_vector(0 downto 0);
   signal VRAM_VA    : std_logic_vector(13 downto 0);   
   signal VRAM_VD    : std_logic_vector(7 downto 0);
   signal nVRAM_CS   : std_logic;
   signal nVRAM_EN   : std_logic;
	
	signal VV55_SYS_DO	: std_logic_vector(7 downto 0);
	signal VV55_KBD_DO	: std_logic_vector(7 downto 0);
	signal nVV55_SYS_CS	: std_logic;
	signal nVV55_KBD_CS	: std_logic;
	
	signal nROM_CS		: std_logic;
	signal nHALT		: std_logic;
	signal nRFSH		: std_logic;
	signal BEEPER     : std_logic;	
	signal BEEPER_EN	: std_logic;

	-- Lvov VGA Signals
	signal   LV_VGA_R       : STD_LOGIC_VECTOR(3 downto 0);
   signal	LV_VGA_G       : STD_LOGIC_VECTOR(3 downto 0);
   signal	LV_VGA_B       : STD_LOGIC_VECTOR(3 downto 0);
   signal	LV_VGA_HSYNC   : STD_LOGIC;
   signal	LV_VGA_VSYNC   : STD_LOGIC;
	
	-- VGA Select Signal
	signal VGA_SEL   : std_logic := '0';

	signal	CLK25				: std_logic;
	signal	MIPS_RESET		: std_logic := '1';
	
	-- Host VGA Signals
	signal   MIPS_VGA_R       : STD_LOGIC_VECTOR(3 downto 0);
   signal	MIPS_VGA_G       : STD_LOGIC_VECTOR(3 downto 0);
   signal	MIPS_VGA_B       : STD_LOGIC_VECTOR(3 downto 0);
   signal	MIPS_VGA_HSYNC   : STD_LOGIC;
   signal	MIPS_VGA_VSYNC   : STD_LOGIC;	
	
	-- Host SRAM Signals
	signal	MIPS_MEM_A       	: std_logic_vector(31 downto 2);
	signal	MIPS_MEM_DI      	: std_logic_vector(31 downto 0);
	signal	MIPS_MEM_DO      	: std_logic_vector(31 downto 0);
	signal	MIPS_MEM_MASK  	: std_logic_vector(3  downto 0);
	signal	MIPS_MEM_WR      	: std_logic;
	signal	MIPS_MEM_REQ     	: std_logic;
	signal	MIPS_MEM_BUSY    	: std_logic;

   signal 	MIPS_KEYB_DATA  	: std_logic_vector(7 downto 0);
	signal	MIPS_BEEPER			: std_logic;

	-- FDC Ports
	signal	VG93_nCLR				: std_logic;
	signal	VG93_CLK					: std_logic;

	signal	VG93_IRQ					: std_logic;
	signal	VG93_DRQ					: std_logic;
	
	signal	VG93_D_OUT				: std_logic_vector(7 downto 0);	
	signal	VG93_nCS					: std_logic;		
		
	signal	VG93_nDDEN				: std_logic;
	signal	VG93_HRDY				: std_logic;

	signal	FDC_DRIVE				: std_logic_vector(1 downto 0);
	signal	FDC_nSIDE				: std_logic;
	signal	nFDC_CS					: std_logic;

	signal	TST					: std_logic;
	
	-- PK-02 Signals
	signal	PORT_F0_CS	: std_logic;
	signal	RAM_PAGE0	: std_logic;
	signal	RAM_PAGE1	: std_logic;
	signal	nROM_EN		: std_logic;
	signal	HI_RES		: std_logic;
	signal	BLANK_SCR	: std_logic;
	signal	INT_EN		: std_logic;
	signal	RAM_BANK0	: std_logic;
	signal	RAM_BANK1	: std_logic;
	signal	int_cnt		: std_logic_vector(19 downto 0);
	signal	nINT			: std_logic := '1';
	signal	nM1			: std_logic;

	-- AY Signals
   signal CLC          : std_logic;
   signal nAY_CS        : std_logic;
   signal AY_DO        : std_logic_vector(7 downto 0);
   signal AY_A         : std_logic_vector(7 downto 0);
   signal AY_B         : std_logic_vector(7 downto 0);
   signal AY_C         : std_logic_vector(7 downto 0); 
   signal AY_BC        : std_logic;
		 
   signal AUDIO_L      : std_logic_vector(9 downto 0);
   signal AUDIO_R      : std_logic_vector(9 downto 0);
	 
	signal clc_cnt		: std_logic_vector(4 downto 0);
	
begin

LV_Z80:T80se
port map (
	RESET_n			=> nRESET,
   CLK_n      		=> CPU_CLK,
	CLKEN				=> '1',
	WAIT_n			=> nCPU_WAIT,
	INT_n				=> nINT,
	NMI_n				=> '1',
	BUSRQ_n			=> '1',
	M1_n				=> nM1,
	MREQ_n			=> nMEM_RQ,
	IORQ_n			=> nIO_RQ,
	RD_n				=> nCPU_RD,
	WR_n				=> nCPU_WR,
	RFSH_n			=> nRFSH,
	HALT_n			=> nHALT,
	BUSAK_n			=> open,
	A					=> CPU_A,
	DI					=> CPU_DI,
	DO					=> CPU_DO
);

   u_Host : mips_soc
	PORT MAP (
			-- CLOCK
		CPU_CLK			=> CLK,
		VGA_CLK			=> CLK25,
		CPU_RESET		=> MIPS_RESET,
		
		-- VGA
		VGA_R				=> MIPS_VGA_R,
		VGA_G				=> MIPS_VGA_G,
		VGA_B				=> MIPS_VGA_B,
		VGA_VSYNC		=>	MIPS_VGA_VSYNC,
		VGA_HSYNC		=> MIPS_VGA_HSYNC,

		-- SRAM
		MEM_A       	=> MIPS_MEM_A,
		MEM_DI      	=> MIPS_MEM_DI,
		MEM_DO      	=> MIPS_MEM_DO,
		MEM_MASK    	=> MIPS_MEM_MASK,
		MEM_WR      	=> MIPS_MEM_WR,
		MEM_REQ     	=> MIPS_MEM_REQ,
		MEM_BUSY    	=> MIPS_MEM_BUSY,

		-- Keyboard
		KEYB_DATA   => MIPS_KEYB_DATA,
		
		-- Sound
		MIPS_BEEPER	=> MIPS_BEEPER,
		
		-- SD Card
		SD_MOSI     => SD_MOSI,
		SD_MISO     => SD_MISO,
		SD_SCK      => SD_SCK,
		SD_CS       => SD_CS,

		-- FDC Ports
		VG93_CLK					=> VG93_CLK,
		VG93_nCLR				=> VG93_nCLR,
		
		VG93_IRQ					=> VG93_IRQ,
		VG93_DRQ					=> VG93_DRQ,
		
		VG93_A					=> CPU_A (1 downto 0),
		VG93_D_IN				=> CPU_DO,
		VG93_D_OUT				=> VG93_D_OUT,	
		VG93_nCS					=> VG93_nCS,		
		VG93_nRD					=> nCPU_RD,
		VG93_nWR					=> nCPU_WR,
		
		VG93_nDDEN				=> VG93_nDDEN,
		VG93_HRDY				=> VG93_HRDY,
		
		FDC_DRIVE				=> FDC_DRIVE,
		FDC_nSIDE				=> FDC_nSIDE,
		TST						=> TST
   );

   u_dp_ram : entity work.dp_sram
	PORT MAP (
		-- CLOCK
		CLK			=> CLK,		
		nRESET		=> nRESET_MEM,		

		-- PORT A
		DI_A			=> CPU_DO,		
		DO_A			=> LV_SRAM_DO,
		ADDR_A		=> RAM_A,
		nWE_A			=> nCPU_WR,
		nCS_A			=> nLV_SRAM_CS,
		nOE_A			=> nCPU_RD,
		nWAIT_A		=> nCPU_WAIT,	
	
		-- PORT B - MIPS must be on chanel B
		DI_B			=> MIPS_MEM_DI,
		DO_B			=> MIPS_MEM_DO,	
		ADDR_B		=> MIPS_MEM_A,
		nWE_B			=> not MIPS_MEM_WR,
		nCS_B			=> not MIPS_MEM_REQ,			
		nOE_B			=> '0',	
		WAIT_B		=> MIPS_MEM_BUSY,
		MEM_MASK_B  => MIPS_MEM_MASK,
	
		-- SRAM
		SRAM_A		=> SRAM_A,
		SRAM_D		=> SRAM_D,
		SRAM_WE		=> SRAM_WE,
		SRAM_OE		=> SRAM_OE,
		SRAM_CE0		=> SRAM_CE0,
		SRAM_CE1		=> SRAM_CE1,		
		SRAM_LB		=> SRAM_LB,		
		SRAM_UB		=> SRAM_UB	
		);

-- Silicone device resets port registers on reset signal
-- VHDL device - not
-- Important for nVRAM_EN

SYS_VV55: a8255
port map(
      RESET		=> not nRESET,
      CLK   	=> CLK,
      nCS   	=> nVV55_SYS_CS,
      nRD   	=> nCPU_RD,
      nWR   	=>	nCPU_WR,
      A     	=> CPU_A(1 downto 0),
      DIN   	=> CPU_DO,
		
      PAIN  					=> (others => '1'),
      PBIN  					=> (others => '1'),
      PCIN(7 downto 5)		=> (others => '1'),
		PCIN(4)					=> '1',					-- TAPE IN
		
		PCIN(3)					=> '1',					-- PCIN 3 to 0 must be connected like this
		PCIN(2)					=> '1',					-- in order to play Hawk Storm game to work
		PCIN(1)					=> nVRAM_EN,			-- and do not corrupt memory in Hawk Storm  
		PCIN(0)					=> BEEPER,				-- and other PK-02 games

      DOUT  	=> VV55_SYS_DO,
		
      PAOUT 					=> open,
      PAEN  					=> open,
		
      PBOUT(6 downto 0) 	=> COLORS,
		PBOUT(7) 				=> BEEPER_EN,
      PBEN  					=> open,
		
		PCOUT(0)					=> BEEPER,
		PCOUT(1)					=> nVRAM_EN,
		PCOUT(7 downto 2) 	=> open,
      PCEN  					=> open
		);

KBD_VV55: a8255
port map(
      RESET		=> not nRESET,
      CLK   	=> CLK,
      nCS   	=> nVV55_KBD_CS,
      nRD   	=> nCPU_RD,
      nWR   	=>	nCPU_WR,
      A     	=> CPU_A(1 downto 0),
      DIN   	=> CPU_DO,
		
      PAIN  					=> (others => '1'),
      PBIN  					=>	KEYB_D,

		PCIN(3 downto 0)		=> KEYB_A2,			-- PCIN 3 to 0 must be connected like this,
      PCIN(7 downto 4)		=> KEYB_D2,			-- otherwize BASICZ80 will run in step execution (F5) mode always

      DOUT  	=> VV55_KBD_DO,
		
      PAOUT 					=> KEYB_A,
      PAEN  					=> open,
		
      PBOUT 					=> open,
      PBEN  					=> open,
		
      PCOUT(3 downto 0) 	=> KEYB_A2,
      PCOUT(7 downto 4) 	=> open,		
      PCEN  					=> open
		);
		
u_AY8910 : entity work.ay8910
port map(
   CLK            => CLK,
   CLC            => CLC,
   RESET          => nRESET,
   BDIR           => not nCPU_WR,
   CS             => nAY_CS,
   BC             => CPU_A(14),
   DI             => CPU_DO,
   DO             => AY_DO,
   OUT_A          => AY_A,
   OUT_B          => AY_B,
   OUT_C          => AY_C ); 
    
u_DAC_L : entity work.dac
port map(
    clk_i       => CLK,
    res_n_i     => nRESET,
    dac_i       => AUDIO_L,
    dac_o       => SOUND_L ); 

u_DAC_R : entity work.dac
port map(
    clk_i       => CLK,
    res_n_i     => nRESET,
    dac_i       => AUDIO_R,
    dac_o       => SOUND_R ); 

	
   -- u_CLOCK is PLL 50 to 32.5 MHz created using wizard
	-- CLK 32.5 MHz is 1/2 of pixelxlock 1024x768@60Hz (65MHz)
   u_CLOCK : entity work.clock
   port map(
      CLK_IN      => CLK50,
      CLK_OUT     => CLK,
		CLK_OUT2		=> CLK25,
		LOCKED		=> LOCKED
		);

   -- FPGA Standard Lvov ROM 16Kb first 2K replaced with Chameleon DOS ROM created using wizard.
   u_ROM : entity work.cham_rom
   port map(
      CLKA        => CLK,
      ADDRA       => CPU_A(13 downto 0),
      DOUTA       => ROM_D );

   -- Handcrafted Lvov video section 
   u_VIDEO : entity work.video
   port map(
      CLK         => CLK,
      RESET       => '1',
      VRAM_A      => VRAM_VA,
      VRAM_D      => VRAM_VD,
      COLORS      => COLORS,
      R           => LV_VGA_R,
      G           => LV_VGA_G,
      B           => LV_VGA_B,
      HSYNC       => LV_VGA_HSYNC,
      VSYNC       => LV_VGA_VSYNC,
		HI_RES		=> HI_RES,
		BLANK_SCR	=> BLANK_SCR	); 
      
   -- FPGA Dual Port RAM 16Kb created using wizard.
   u_VRAM : entity work.vram
   port map(
      clka        => CLK,
      wea         => VRAM_WE,
      addra       => CPU_A(13 downto 0),
      dina        => CPU_DO,
      douta       => VRAM_DO,
		
      clkb        => CLK,
      web         => "0",
      addrb       => VRAM_VA,
      dinb        => "11111111",
      doutb       => VRAM_VD );
 
   -- Handcrafted PS2 to Lvov Matrix keyboard adapter 
   u_KEYBOARD : entity work.keyboard
   port map(
      CLK         => CLK,
      RESET       => nRESET,
		
      PS2_CLK     => PS2_CLK,
      PS2_DATA    => PS2_DATA,
		
      CONTROL     => KEYB_CTRL,
      KEYB_A      => KEYB_A,
      KEYB_D      => KEYB_D,
      KEYB_A2     => KEYB_A2,
      KEYB_D2     => KEYB_D2,
		
		VGA_SEL		=> VGA_SEL,
		
      KEYB_DATA   => MIPS_KEYB_DATA
		);

   -- Divider for CPU CLK  
	-- Generate CPU_CLK 2.16MHz (32.5MHz/15) CPU Clock (Original 2.22MHz (20MHz/9))
   -- CLK 32.5 MHz is 1/2 of pixelxlock 1024x768@60Hz (65MHz)
	-- nRESET is active during one period of CPU_CLK
	process (CLK)
	begin
		if rising_edge(CLK) then
         if KEYB_CTRL(0) = '1' then
            TICK <= (others => '0');
            nRESET <= '0';
				CPU_CLK <= '0';
         else		
				if KEYB_CTRL(1) = '1' then
					MIPS_RESET <= '1';
				end if;
				if KEYB_CTRL(2) = '1' then
					VGA_SEL <= '1';
				end if;
				if KEYB_CTRL(3) = '1' then
					VGA_SEL <= '0';
				end if;
			
				if LOCKED = '1' then
					TICK <= TICK + 1;
				end if;
				
            CPU_CLK <= '0';
            if TICK = "1111" then
					CPU_CLK <= '1';
               nRESET <= '1';
					MIPS_RESET <= '0';
					nRESET_MEM <= '1';
            end if;
			
			end if;
		end if;
	end process;

-- Video output selector
VGA_R			<= LV_VGA_R			when VGA_SEL = '0' else MIPS_VGA_R;
VGA_G			<= LV_VGA_G			when VGA_SEL = '0' else MIPS_VGA_G;
VGA_B			<= LV_VGA_B			when VGA_SEL = '0' else MIPS_VGA_B;
VGA_HSYNC	<= LV_VGA_HSYNC	when VGA_SEL = '0' else MIPS_VGA_HSYNC;
VGA_VSYNC	<= LV_VGA_VSYNC	when VGA_SEL = '0' else MIPS_VGA_VSYNC;

-- Debug Stuff
IO(1) <= CLK; -- OSC D8
IO(3) <= MIPS_MEM_REQ;	

IO(5) <= MIPS_MEM_WR;
IO(7) <= MIPS_MEM_BUSY;

IO(9) <=  nLV_SRAM_CS;
IO(11) <= nCPU_WR;

IO(13) <= nCPU_WAIT;
IO(15) <= MIPS_RESET or (not nRESET);	-- OSC D15
		
IO(14) <= '0'; --SRAM_CE0;	-- OSC D0
IO(12) <= '0'; --SRAM_CE1;	
IO(10) <= '0'; --SRAM_OE;	
IO(8)  <= '0'; --SRAM_WE;	
IO(6)	 <= '0'; --SRAM_LB;	
IO(4)  <= '0'; --SRAM_UB;	
IO(2)  <= '0';	
IO(0)  <= TST;	-- OSC D7		
		
--IO(14) <= MIPS_MEM_DO(0);	-- OSC D0
--IO(12) <= MIPS_MEM_DO(1);	
--IO(10) <= MIPS_MEM_DO(2);	
--IO(8)  <= MIPS_MEM_DO(3);	
--IO(6)	<= MIPS_MEM_DO(4);	
--IO(4)  <= MIPS_MEM_DO(5);	
--IO(2)  <= MIPS_MEM_DO(6);	
--IO(0)  <= MIPS_MEM_DO(7);	-- OSC D7	


-- System bus device multiplexor
-- Connecting appropriate memory or I/O to the system bus for reading and writing
-- ROM is in CPU address space 0xC000 - 0xFFFF
-- nLV_SRAM_CS <= '0' when nMEM_RQ = '0' and nRFSH = '1' and nHALT = '1' and nVRAM_CS = '1' and nROM_CS = '1' and TICK = "0100" else '1';

nLV_SRAM_CS <= '0' when nMEM_RQ = '0' and nRFSH = '1' and nHALT = '1' and nVRAM_CS = '1' and nROM_CS = '1' and (nCPU_WR = '0' or nCPU_RD = '0') else '1';

-- Read ROM, VRAM and RAM
CPU_DI 	<= 
				ROM_D			when nROM_CS = '0' else
				VRAM_DO		when nVRAM_CS = '0' else		
				LV_SRAM_DO	when nMEM_RQ = '0' and nRFSH = '1' else

-- Read ports	
				VG93_IRQ & VG93_DRQ & "111111"	when nFDC_CS = '0' 		else
				VG93_D_OUT								when VG93_nCS = '0' 		else
				VV55_SYS_DO								when nVV55_SYS_CS = '0' else
				VV55_KBD_DO								when nVV55_KBD_CS = '0' else
				AY_DO										when nAY_CS = '0' 		else
				(others => '1');

nROM_CS <= '0' when nMEM_RQ = '0' and nRFSH = '1' and nHALT = '1' and ( (CPU_A(15 downto 14) = "11" and nROM_EN = '0') or ROM_INIT = '1' ) else '1';

-- VRAM Control
-- VRAM is in CPU address space 0x4000 - 0x7FFF
nVRAM_CS <= '0' when nMEM_RQ = '0' and nRFSH = '1' and nHALT = '1' and CPU_A(15 downto 14) = "01" and nVRAM_EN = '0' else '1';	
VRAM_WE	<= "1" when nCPU_WR = '0' and nVRAM_CS = '0' else "0";

-- Ports 0xD0-0xDF - PK-02 bits 7-6 (15-14) are ignored
nVV55_KBD_CS <= '0' when nIO_RQ = '0' and CPU_A(5 downto 4) = "01" else '1'; 
nVV55_SYS_CS <= '0' when nIO_RQ = '0' and CPU_A(5 downto 4) = "00" else '1'; 

-- VG93 Ports 0xE0-0xE3
VG93_nCS		<= '0' when nIO_RQ = '0' and CPU_A(7 downto 2) = "111000" else '1';
VG93_CLK		<= '0' when TICK = "0011" else '1';

-- FDC Port 0xE4
nFDC_CS		<= '0' when nIO_RQ = '0' and CPU_A(7 downto 0) = x"E4" else '1';

-- Write to ports
process(CLK)
begin
    if rising_edge(CLK) then
        if nRESET = '0' then
				ROM_INIT		<= '1';
				
				-- Port #F0 PK-02 Reset
				RAM_PAGE0	<= '0';
				RAM_PAGE1	<= '0';
				nROM_EN		<= '0';
				HI_RES		<= '0';
				BLANK_SCR	<= '0';
				INT_EN		<= '0';
				RAM_BANK0	<= '0';
				RAM_BANK1	<= '0';
        elsif TICK = "1011" then
            if nIO_RQ = '0' and nCPU_WR = '0' then
					 ROM_INIT	<= '0';
                if CPU_A(5 downto 4) = "11" then               -- Port #F0 PK-02
							RAM_PAGE0	<= CPU_DO(0);
							RAM_PAGE1	<= CPU_DO(1);
							nROM_EN		<= CPU_DO(2);
							HI_RES		<= CPU_DO(3);
							BLANK_SCR	<= CPU_DO(4);
							INT_EN		<= CPU_DO(5);
							RAM_BANK0	<= CPU_DO(6);
							RAM_BANK1	<= CPU_DO(7);
                elsif nFDC_CS = '0' then            				-- Port #E4 FDC
							VG93_nCLR	<= CPU_DO(2);	
							VG93_nDDEN	<= CPU_DO(6);
							VG93_HRDY	<= CPU_DO(3);
							FDC_DRIVE	<= CPU_DO(1 downto 0);
							FDC_nSIDE	<= CPU_DO(4);
               end if;
				end if;
        end if;
    end if;
end process;

-- PK-02 Interupts and AY CLC
-- Input 38.5 Mhz Output 49 Hz
-- 20 bit counter used, pulse width 10 us
process (CLK)
begin
	if rising_edge(CLK) then
		int_cnt <= int_cnt + 1;
		clc_cnt <= clc_cnt + 1;
		
		-- AY CLC 1.77 MHz (Actial 1.8MHz)
		CLC <= '0';
		if clc_cnt = 17 then
			clc_cnt <= "00000";
			CLC <= '1';
		end if;
		
		if int_cnt = 325 then
			int_cnt <= int_cnt + 1;
			nINT <= '1';
		end if;
		
		if int_cnt = 663260 then
			int_cnt <= (others => '0');
			if INT_EN = '1' then
				nINT <= '0';
			end if;
		end if;
		
	end if;
end process;

-- PK-02 RAM Page Switching
RAM_A <=  RAM_BANK1 & RAM_BANK0 & RAM_PAGE1 & RAM_PAGE0 & CPU_A(13 downto 0) when CPU_A(15 downto 14) = "11" else
			"11" & CPU_A(15 downto 0);
			
-- PK-02 AY8910 Port 
nAY_CS <= '0' when nIO_RQ = '0' and nM1 = '1' and CPU_A(15) = '1' and CPU_A(1) = '0' else '1';

AUDIO_L <= std_logic_vector( unsigned('0' & AY_A & '0') + unsigned('0' & ( (BEEPER and BEEPER_EN) xor MIPS_BEEPER ) & AY_B) );
AUDIO_R <= std_logic_vector( unsigned('0' & AY_C & '0') + unsigned('0' & ( (BEEPER and BEEPER_EN) xor MIPS_BEEPER ) & AY_B) );

end Behavioral;

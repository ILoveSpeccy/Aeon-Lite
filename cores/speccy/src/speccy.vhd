library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;  

entity speccy is
Port ( 
    CLK50               : in    std_logic;

    MCU_READY           : in    std_logic;

    KEYB_CLK            : in    std_logic;
    KEYB_DATA           : in    std_logic;
    
    SD_MOSI             : out   std_logic;
    SD_MISO             : in    std_logic;
    SD_SCK              : out   std_logic;
    SD_CS               : out   std_logic;

    SOUND_L             : out   std_logic;
    SOUND_R             : out   std_logic;

    SRAM_A              : out   std_logic_vector(17 downto 0);
    SRAM_D              : inout std_logic_vector(15 downto 0);
    SRAM_WE             : out   std_logic;
    SRAM_OE             : out   std_logic;
    SRAM_UB             : out   std_logic;
    SRAM_LB             : out   std_logic;
    SRAM_CE0            : out   std_logic;
    SRAM_CE1            : out   std_logic;
   
    VGA_R               : out   std_logic_vector(3 downto 0);
    VGA_G               : out   std_logic_vector(3 downto 0);
    VGA_B               : out   std_logic_vector(3 downto 0);
    VGA_HSYNC           : out   std_logic;
    VGA_VSYNC           : out   std_logic );
end speccy;

architecture rtl of speccy is 

    signal CLK          : std_logic;
    signal VGA_CLK      : std_logic;
    signal LOCKED       : std_logic;
	 
    signal RESET        : std_logic;
    signal TICK         : unsigned(3 downto 0);
    signal CLC_TICK     : std_logic;

    signal CPU_CLK      : std_logic;
    signal CPU_RESET    : std_logic;
    signal CPU_INT      : std_logic;
    signal CPU_NMI      : std_logic;
    signal CPU_MREQ     : std_logic;
    signal CPU_IORQ     : std_logic;
    signal CPU_M1       : std_logic;
    signal CPU_RD       : std_logic;
    signal CPU_WR       : std_logic;
    signal CPU_A        : std_logic_vector(15 downto 0);
    signal CPU_DI       : std_logic_vector(7 downto 0);
    signal CPU_DO       : std_logic_vector(7 downto 0);

    signal ROM_DO       : std_logic_vector(7 downto 0);
    signal DIVROM_DO    : std_logic_vector(7 downto 0);

    signal RAM_A        : std_logic_vector(19 downto 0);
    signal RAM_DO       : std_logic_vector(7 downto 0);
    signal RAM_RW       : std_logic;
    signal RAM_REQ      : std_logic;

    signal VRAM_WR      : std_logic_vector(0 downto 0);
    signal VRAM_A       : std_logic_vector(13 downto 0);
    signal VRAM_VA      : std_logic_vector(12 downto 0);
    signal VRAM_VD      : std_logic_vector(7 downto 0);
    signal BORDERCOLOR  : std_logic_vector(2 downto 0);
    
    signal KEYB_DO      : std_logic_vector(4 downto 0);

    signal RESET_TICK   : std_logic;
    signal RESET_ONESHOT: std_logic;
    signal NMI_TICK     : std_logic;
    signal NMI_ONESHOT  : std_logic;

    signal BEEPER       : std_logic;

    signal CLC          : std_logic;
    signal AY_CS        : std_logic;
    signal AY_DO        : std_logic_vector(7 downto 0);
    signal AY_A         : std_logic_vector(7 downto 0);
    signal AY_B         : std_logic_vector(7 downto 0);
    signal AY_C         : std_logic_vector(7 downto 0); 
   
    signal AUDIO_L      : std_logic_vector(9 downto 0);
    signal AUDIO_R      : std_logic_vector(9 downto 0);
    
    ------------------------- 128K -------------------------
    signal PAGE         : std_logic_vector(2 downto 0) := "000";
    signal SCREEN       : std_logic := '0';
    signal ROMSEL       : std_logic := '0';
    signal DISABLE      : std_logic := '0'; 
    
    ------------------------ DIVMMC ------------------------
    signal BANK         : std_logic_vector(5 downto 0) := "000000";
    signal CONMEM       : std_logic := '0';
    signal MAPRAM       : std_logic := '0';
    signal MAPCOND      : std_logic := '0';
    signal AUTOMAP      : std_logic := '0';

    signal counter		:	unsigned(3 downto 0);
    -- Shift register has an extra bit because we write on the
    -- falling edge and read on the rising edge
    signal shift_reg	:	std_logic_vector(8 downto 0);
    signal in_reg		:	std_logic_vector(7 downto 0);

begin

u_CLOCK : entity work.clock
port map(
    CLK50       => CLK50,
    CLK         => CLK,
    VGA_CLK     => VGA_CLK,
    LOCKED      => LOCKED );

u_VIDEO : entity work.video
port map(
    VGA_CLK     => VGA_CLK,
    RESET       => '0',
    BORDERCOLOR => BORDERCOLOR,
    INT         => CPU_INT,
    VA          => VRAM_VA,
    VD          => VRAM_VD,
    VGA_R       => VGA_R,
    VGA_G       => VGA_G,
    VGA_B       => VGA_B,
    VGA_HSYNC   => VGA_HSYNC,
    VGA_VSYNC   => VGA_VSYNC );

u_ROM : entity work.rom
port map(
    clka        => CLK,
    addra       => ROMSEL & CPU_A(13 downto 0),
    douta       => ROM_DO );

u_DIVROM : entity work.divrom
port map(
    clka        => CLK,
    addra       => CPU_A(12 downto 0),
    douta       => DIVROM_DO );

u_VRAM : entity work.vram
port map(
    clka        => CLK,
    wea         => VRAM_WR,
    addra       => VRAM_A,
    dina        => CPU_DO,
    clkb        => VGA_CLK,
    addrb       => SCREEN & VRAM_VA,
    doutb       => VRAM_VD );

u_CPU : entity work.T80se
port map(
    RESET_n     => CPU_RESET, --not RESET,
    CLK_n       => CLK,
    CLKEN       => CPU_CLK,
    WAIT_n      => '1',
    INT_n       => CPU_INT,
    NMI_n       => CPU_NMI,
    BUSRQ_n     => '1',
    M1_n        => CPU_M1,
    MREQ_n      => CPU_MREQ,   
    IORQ_n      => CPU_IORQ,
    RD_n        => CPU_RD,
    WR_n        => CPU_WR,
    RFSH_n      => OPEN,
    HALT_n      => OPEN,
    BUSAK_n     => OPEN,
    A           => CPU_A,
    DI          => CPU_DI,
    DO          => CPU_DO );

u_RAM : entity work.memctrl
port map(            
    CLK         => CLK,
    RESET       => RESET,
      
    MEM_A       => RAM_A,
    MEM_DI      => CPU_DO,
    MEM_DO      => RAM_DO,
    MEM_RW      => RAM_RW,
    MEM_REQ     => RAM_REQ,
    MEM_ACK     => open,

    SRAM_A      => SRAM_A,
    SRAM_D      => SRAM_D,
    SRAM_CE0    => SRAM_CE0,
    SRAM_CE1    => SRAM_CE1,
    SRAM_OE     => SRAM_OE,
    SRAM_WE     => SRAM_WE,
    SRAM_UB     => SRAM_UB,
    SRAM_LB     => SRAM_LB );

u_KEYBOARD: entity work.keyboard
port map(
    CLK         => CLK,
    RESET       => RESET,
    PS2_CLK     => KEYB_CLK,
    PS2_DATA    => KEYB_DATA,
    KEYB_ADDR   => CPU_A(15 downto 8),
    KEYB_DATA   => KEYB_DO,
    RESET_TICK  => RESET_TICK,
    NMI_TICK    => NMI_TICK );

u_ONESHOT_RESET : entity work.oneshot
port map(
    CLK         => CLK,
    RESET       => RESET,
    ONESHOT_IN  => RESET_TICK,
    ONESHOT_OUT => RESET_ONESHOT );

u_ONESHOT_NMI : entity work.oneshot
port map(
    CLK         => CLK,
    RESET       => RESET,
    ONESHOT_IN  => NMI_TICK,
    ONESHOT_OUT => NMI_ONESHOT );
    
u_AY8910 : entity work.ay8910
port map(
   CLK            => CLK,
   CLC            => CLC,
   RESET          => CPU_RESET,
   BDIR           => not CPU_WR,
   CS             => AY_CS,
   BC             => CPU_A(14),
   DI             => CPU_DO,
   DO             => AY_DO,
   OUT_A          => AY_A,
   OUT_B          => AY_B,
   OUT_C          => AY_C ); 
    
u_DAC_L : entity work.dac
port map(
    clk_i       => CLK,
    res_n_i     => CPU_RESET,
    dac_i       => AUDIO_L,
    dac_o       => SOUND_L ); 

u_DAC_R : entity work.dac
port map(
    clk_i       => CLK,
    res_n_i     => CPU_RESET,
    dac_i       => AUDIO_R,
    dac_o       => SOUND_R ); 

AUDIO_L <= std_logic_vector(unsigned('0' & AY_A & '0') + unsigned('0' & BEEPER & AY_B));
AUDIO_R <= std_logic_vector(unsigned('0' & AY_C & '0') + unsigned('0' & BEEPER & AY_B));

CPU_RESET <= not RESET_ONESHOT;

reset_and_clock : process(CLK)
begin
    if rising_edge(CLK) then
        if LOCKED = '0' or MCU_READY = '0' then
            TICK <= "0000";
            RESET <= '1';
            CPU_CLK <= '0';
            CLC <= '0';
            CLC_TICK <= '0';
        else
            CPU_CLK <= '0';        
            CLC <= '0';
            TICK <= TICK + 1;
            if TICK = "1111" then
                CPU_CLK <= '1';
                RESET <= '0';
                CLC_TICK <= not CLC_TICK;
                if CLC_TICK = '1' then
                    CLC <= '1';
                end if;
            end if;
        end if;
    end if;
end process;

CPU_DI <= ROM_DO            when CPU_A(15 downto 14)  = "00"  and CPU_MREQ = '0' and AUTOMAP = '0' and CONMEM = '0'
     else DIVROM_DO         when CPU_A(15 downto 13)  = "000" and CPU_MREQ = '0' and (AUTOMAP = '1' or CONMEM = '1')
     else RAM_DO            when CPU_A(15 downto 13)  = "001" and CPU_MREQ = '0' and (AUTOMAP = '1' or CONMEM = '1') 
     else RAM_DO            when CPU_A(15 downto 14) /= "00"  and CPU_MREQ = '0'
     else AY_DO             when AY_CS = '0'
     else in_reg            when CPU_A(7 downto 0) = X"EB"    and CPU_IORQ = '0'
     else "111" & KEYB_DO   when CPU_A(0) = '0'               and CPU_IORQ = '0'
     else "11111111"; 
        
VRAM_WR <= "1" when ((CPU_A(15 downto 13) = "010") or (CPU_A(15 downto 13) = "110" and PAGE(2) = '1' and PAGE(0) = '1')) and CPU_MREQ = '0' and CPU_WR = '0' else "0";

VRAM_A <= '0' & CPU_A(12 downto 0) when CPU_A(15 downto 13) = "010" else PAGE(1) & CPU_A(12 downto 0);

RAM_A <= '1' & BANK & CPU_A(12 downto 0) when CPU_A(15 downto 13) = "001" and (AUTOMAP = '1' or CONMEM = '1') 
    else "000" & PAGE & CPU_A(13 downto 0) when CPU_A(15 downto 14) = "11"
    else "000" & CPU_A(14) & CPU_A;

RAM_RW <= '1' when CPU_MREQ = '0' and CPU_WR = '0' and (CPU_A(15 downto 14) /= "00" or (CPU_A(15 downto 13) = "001" and (AUTOMAP = '1' or CONMEM = '1'))) else '0';
RAM_REQ <= '1' when TICK = "0100" else '0';

AY_CS	<= '0' when CPU_A(15) = '1' and CPU_A(13) = '1' and CPU_A(1) = '0' and CPU_M1 = '1' and CPU_IORQ = '0' else '1';

process(CLK)
begin
    if rising_edge(CLK) then
        if CPU_RESET = '0' then
            SD_CS <= '1';
            PAGE <= "000";
            SCREEN <= '0';
            ROMSEL <= '0';
            DISABLE <= '0';
        elsif TICK = "0011" then
            if CPU_MREQ = '0' then
                if CPU_M1 = '0' and CPU_A(15 downto 3) = "0001111111111" then
                    MAPCOND <= '0';
                elsif (CPU_M1 = '0' and (CPU_A = X"0000" or CPU_A = X"0008" or CPU_A = X"0038" or CPU_A = X"0066" or CPU_A = X"04C6" or CPU_A = X"0562")) or (CPU_M1 = '0' and CPU_A(15 downto 8) = X"3D") then
                    MAPCOND <= '1';
                end if;
                if MAPCOND = '1' or (CPU_M1 = '0' and CPU_A(15 downto 8) = X"3D") then
                    AUTOMAP <= '1';
                else
                    AUTOMAP <= '0';
                end if;
            end if;
            if CPU_IORQ = '0' and CPU_WR = '0' then
                if CPU_A(7 downto 0) = X"E7" then               -- Port #E7
                    SD_CS <= CPU_DO(0);
                elsif CPU_A(7 downto 0) = X"E3" then            -- Port #E3
                    BANK <= CPU_DO(5 downto 0);
                    CONMEM <= CPU_DO(7);
                    MAPRAM <= CPU_DO(6) or MAPRAM;
                elsif CPU_A(15) = '0' and CPU_A(1) = '0' then   -- Port #7FFD
                    if DISABLE = '0' then   -- not locked in 48K-mode
                        PAGE <= CPU_DO(2 downto 0);
                        SCREEN <= CPU_DO(3);
                        ROMSEL <= CPU_DO(4);
                        DISABLE <= CPU_DO(5);
                    end if;
                elsif CPU_A(0) = '0' then                       -- Port #FE
                    BORDERCOLOR <= CPU_DO(2 downto 0);
                    BEEPER <= CPU_DO(4);
                end if;
            end if;
        end if;
    end if;
end process;

CPU_NMI <= '0' when NMI_ONESHOT = '1' and MAPCOND = '0' else '1'; 

sd_card : process(CLK)
begin
    if rising_edge(CLK) then
        if CPU_RESET = '0' then
            shift_reg <= (others => '1');
            in_reg <= (others => '1');
            counter <= "1111"; -- Idle
        elsif TICK = "0011" then
            if counter = "1111" then
                in_reg <= shift_reg(7 downto 0);
                if CPU_IORQ = '0' and CPU_A(7 downto 0) = X"EB" then
                    if CPU_WR = '1' then
                        shift_reg <= (others => '1');
                    else
                        shift_reg <= CPU_DO & '1';
                    end if;
                    counter <= "0000";
                end if;
            else
                counter <= counter + 1;
                if counter(0) = '0' then
                    shift_reg(0) <= SD_MISO;
                else
                    shift_reg <= shift_reg(7 downto 0) & '1';
                end if;
            end if;
        end if;
    end if;
end process;

SD_SCK <= counter(0);
SD_MOSI <= shift_reg(8);

end rtl;

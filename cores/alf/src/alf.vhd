library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;  

entity alf is
Port ( 
    CLK50               : in    std_logic;

    PS2_CLK             : in    std_logic;
    PS2_DATA            : in    std_logic;
    
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
end alf;

architecture rtl of alf is 

    signal CLK          : std_logic;
    signal VGA_CLK      : std_logic;
    signal LOCKED       : std_logic;
	 
    signal RESET        : std_logic;
    signal TICK         : unsigned(3 downto 0);

    signal CPU_CLK      : std_logic;
    signal CPU_INT      : std_logic;
    signal CPU_MREQ     : std_logic;
    signal CPU_IORQ     : std_logic;
    signal CPU_RD       : std_logic;
    signal CPU_WR       : std_logic;
    signal CPU_A        : std_logic_vector(15 downto 0);
    signal CPU_DI       : std_logic_vector(7 downto 0);
    signal CPU_DO       : std_logic_vector(7 downto 0);

    signal ROM_A        : std_logic_vector(19 downto 0);
    signal ROM_DO       : std_logic_vector(7 downto 0);

    signal VRAM_VA      : std_logic_vector(12 downto 0);
    signal VRAM_VD      : std_logic_vector(7 downto 0);
    signal BORDERCOLOR  : std_logic_vector(2 downto 0);

    signal RAM1_DO      : std_logic_vector(7 downto 0);
    signal RAM1_WR      : std_logic_vector(0 downto 0);
    signal RAM2_DO      : std_logic_vector(7 downto 0);
    signal RAM2_WR      : std_logic_vector(0 downto 0);
    signal RAM3_DO      : std_logic_vector(7 downto 0);
    signal RAM3_WR      : std_logic_vector(0 downto 0);
    
    signal KEYB_DO      : std_logic_vector(4 downto 0);

    signal ROM_REG      : std_logic_vector(7 downto 0);
    signal KB_RESET     : std_logic;
    
    signal BEEPER       : std_logic;

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

u_CPU : entity work.T80se
port map(
    RESET_n     => not RESET,
    CLK_n       => CLK,
    CLKEN       => CPU_CLK,
    WAIT_n      => '1',
    INT_n       => CPU_INT,
    NMI_n       => '1',
    BUSRQ_n     => '1',
    M1_n        => OPEN,
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

--u_ROM : entity work.rom
--port map(
--   clka        => CLK,
--   addra       => CPU_A(13 downto 0),
--   douta       => ROM_DO );
 
u_RAM1 : entity work.vram
port map(
   clka           => CLK,
   wea            => RAM1_WR,
   addra          => CPU_A(13 downto 0),
   dina           => CPU_DO,
   douta          => RAM1_DO,
   clkb           => VGA_CLK,
   web            => "0",
   addrb          => '0' & VRAM_VA,
   dinb           => "00000000",
   doutb          => VRAM_VD );

u_RAM2 : entity work.ram
port map(
   clka           => CLK,
   wea            => RAM2_WR,
   addra          => CPU_A(13 downto 0),
   dina           => CPU_DO,
   douta          => RAM2_DO );

u_RAM3 : entity work.ram
port map(
   clka           => CLK,
   wea            => RAM3_WR,
   addra          => CPU_A(13 downto 0),
   dina           => CPU_DO,
   douta          => RAM3_DO );

u_KEYBOARD : entity work.keyboard
port map(
    CLK           => CLK,
    RESET         => RESET,
    PS2_CLK       => PS2_CLK,
    PS2_DATA      => PS2_DATA,
    KEYB_DATA     => KEYB_DO,
    RESET_TICK    => KB_RESET );

reset_and_clock : process(CLK)
begin
    if rising_edge(CLK) then
        if LOCKED = '0' or KB_RESET = '1' then
            TICK <= "0000";
            RESET <= '1';
            CPU_CLK <= '0';
        else
            CPU_CLK <= '0';        
            TICK <= TICK + 1;
            if TICK = "1111" then
                CPU_CLK <= '1';
                RESET <= '0';
            end if;
        end if;
    end if;
end process;

SOUND_L <= BEEPER;
SOUND_R <= BEEPER;

CPU_DI <= ROM_DO            when CPU_A(15 downto 14)  = "00" and CPU_MREQ = '0' and ROM_REG(7) = '0'
     else ROM_DO            when CPU_A(15 downto 14)  = "00" and CPU_MREQ = '0' and ROM_REG(6 downto 4) = "000"
     else RAM1_DO           when CPU_A(15 downto 14)  = "01" and CPU_MREQ = '0'
     else RAM2_DO           when CPU_A(15 downto 14)  = "10" and CPU_MREQ = '0'
     else RAM3_DO           when CPU_A(15 downto 14)  = "11" and CPU_MREQ = '0'
     else "000" & KEYB_DO   when CPU_A(5) = '0' and CPU_RD = '0' and CPU_IORQ = '0'
     else "11111111"        when CPU_A(0) = '0' and CPU_RD = '0' and CPU_IORQ = '0'
     else "11111111"; 

RAM1_WR <= "1" when CPU_A(15 downto 14) = "01"  and CPU_MREQ = '0' and CPU_WR = '0' else "0";
RAM2_WR <= "1" when CPU_A(15 downto 14) = "10"  and CPU_MREQ = '0' and CPU_WR = '0' else "0";
RAM3_WR <= "1" when CPU_A(15 downto 14) = "11"  and CPU_MREQ = '0' and CPU_WR = '0' else "0";

ROM_A <= ROM_REG(7) & '0' & ROM_REG(3 downto 0) & CPU_A(13 downto 0);

SRAM_A <= ROM_A(18 downto 1);
SRAM_WE <= '1';
SRAM_OE <= '0';
SRAM_LB <= '0';
SRAM_UB <= '0';
SRAM_CE0 <= ROM_A(19);
SRAM_CE1 <= not ROM_A(19);
SRAM_D <= "ZZZZZZZZZZZZZZZZ";
ROM_DO <= SRAM_D(7 downto 0) when ROM_A(0) = '0' else SRAM_D(15 downto 8);

romreg : process(CLK)
begin
    if rising_edge(CLK) then
        if RESET = '1' then
            ROM_REG <= "00000000";
        else
            if CPU_IORQ = '0' and CPU_WR = '0' and CPU_A(5) = '0' then
               ROM_REG <= CPU_DO;
            end if;
            
            if CPU_IORQ = '0' and CPU_WR = '0' and CPU_A(0) = '0' then
               BEEPER <= CPU_DO(4);
               BORDERCOLOR <= CPU_DO(2 downto 0);
            end if;
        end if;
    end if;
end process;

end rtl;

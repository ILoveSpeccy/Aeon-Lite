library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

entity boot is
port (
    CLK50       : in     std_logic;

    SRAM_A      : out   std_logic_vector(18 downto 0);
    SRAM_D      : inout std_logic_vector(15 downto 0);
    SRAM_WE     : out   std_logic;
    SRAM_OE     : out   std_logic;
    SRAM_UB     : out   std_logic;
    SRAM_LB     : out   std_logic;
    SRAM_CE0    : out   std_logic;
    SRAM_CE1    : out   std_logic;

    KEYB_CLK    : in    std_logic;
    KEYB_DATA   : in    std_logic;
   
    COMM_CSA    : in    std_logic;
    COMM_CSD    : in    std_logic;
    COMM_SCK    : in    std_logic;
    COMM_MOSI   : in    std_logic;
    COMM_MISO   : out   std_logic;
    COMM_RDY    : out   std_logic;

    SD_MOSI     : out   std_logic := '1';
    SD_MISO     : in    std_logic;
    SD_SCK      : out   std_logic := '1';
    SD_CS       : out   std_logic;
    FL_CS       : out   std_logic;

    VGA_R       : out   std_logic_vector(3 downto 0);
    VGA_G       : out   std_logic_vector(3 downto 0);
    VGA_B       : out   std_logic_vector(3 downto 0);
    VGA_VSYNC   : out	std_logic;
    VGA_HSYNC   : out   std_logic
);
end boot;

architecture rtl of boot is

    -- SPI COMMANDS
    constant CMD_VIDEO_MODE     : std_logic_vector(7 downto 0) := X"00"; -- sequental or swapped read/write attr/char 
    constant CMD_VIDEO_X_POS    : std_logic_vector(7 downto 0) := X"01";
    constant CMD_VIDEO_Y_POS    : std_logic_vector(7 downto 0) := X"02";
    constant CMD_VIDEO_ATTR     : std_logic_vector(7 downto 0) := X"03";
    constant CMD_VIDEO_CHAR     : std_logic_vector(7 downto 0) := X"04";
    constant CMD_RAM_MODE       : std_logic_vector(7 downto 0) := X"10"; -- 1/2 bytes address increment
    constant CMD_RAM_H_ADDR     : std_logic_vector(7 downto 0) := X"11";
    constant CMD_RAM_M_ADDR     : std_logic_vector(7 downto 0) := X"12";
    constant CMD_RAM_L_ADDR     : std_logic_vector(7 downto 0) := X"13";
    constant CMD_RAM_DATA       : std_logic_vector(7 downto 0) := X"14"; 
    constant CMD_KEYBOARD       : std_logic_vector(7 downto 0) := X"20"; 
   
    signal CLK                  : std_logic;
    signal VGA_CLK              : std_logic;
    signal LOCKED               : std_logic;

    signal TICK                 : unsigned(3 downto 0) := "0000";
    signal RESET                : std_logic := '1';
   
    signal SRAM_DI              : std_logic_vector(15 downto 0);
    signal SRAM_DO              : std_logic_vector(15 downto 0);

    signal POS_X                : unsigned(6 downto 0);
    signal POS_Y                : unsigned(4 downto 0);
   
    signal VA                   : std_logic_vector(11 downto 0);
    signal VDI                  : std_logic_vector(7 downto 0);
    signal VDO                  : std_logic_vector(15 downto 0);
    signal VWR                  : std_logic;
    signal VATTR                : std_logic_vector(7 downto 0);
    signal VRG                  : std_logic_vector(7 downto 0);
   
    signal RAM_A                : std_logic_vector(19 downto 0);
    signal RAM_DI               : std_logic_vector(7 downto 0);
    signal RAM_DO               : std_logic_vector(7 downto 0);
    signal RAM_RW               : std_logic;
    signal RAM_REQ              : std_logic;
    signal RAM_ACK              : std_logic;
    signal RAM_RG               : std_logic_vector(7 downto 0);

    signal COMM_AO              : std_logic_vector(7 downto 0);
    signal COMM_AI              : std_logic_vector(7 downto 0);
    signal COMM_A_REQ           : std_logic;
    signal COMM_A_ACK           : std_logic;

    signal COMM_DO              : std_logic_vector(7 downto 0);
    signal COMM_DI              : std_logic_vector(7 downto 0);
    signal COMM_D_REQ           : std_logic;
    signal COMM_D_ACK           : std_logic;

    signal COMM_RG              : std_logic_vector(7 downto 0);
    signal COMM_MA              : std_logic_vector(19 downto 0);

    signal KB_DATA              : std_logic_vector(7 downto 0); 

   type STATES is (ST_IDLE, ST_READ_DATA, ST_WRITE_DATA, ST_READ_VRAM_A, ST_READ_VRAM_D, ST_READ, ST_WRITE, ST_INC);
    signal STATE : STATES;

begin

SD_CS <= '1';
FL_CS <= '1';

u_CLOCK : entity work.clock
port map(
    CLK50       => CLK50,
    CLK         => CLK,
    VGA_CLK     => VGA_CLK,
    LOCKED      => LOCKED );

u_VIDEO : entity work.video
port map(
    CLK         => CLK,
    VGA_CLK     => VGA_CLK,
    RESET       => RESET,

    VA          => VA,
    VDI         => VDI,
    VDO         => VDO,
    VWR         => VWR,
    VATTR       => VATTR,

    VGA_R       => VGA_R,
    VGA_G       => VGA_G,
    VGA_B       => VGA_B,
    VGA_HSYNC   => VGA_HSYNC,
    VGA_VSYNC   => VGA_VSYNC );

u_COMM_SPI : entity work.spi_comm
port map(   
    CLK         => CLK,
    RESET       => RESET,

    SPI_CS_A    => COMM_CSA,
    SPI_CS_D    => COMM_CSD,
    SPI_SCK     => COMM_SCK,
    SPI_DI      => COMM_MOSI,
    SPI_DO      => COMM_MISO,

    ADDR_O      => COMM_AO,
    ADDR_I      => COMM_AI,
    ADDR_REQ    => COMM_A_REQ,
    ADDR_ACK    => COMM_A_ACK,

    DATA_O      => COMM_DO,
    DATA_I      => COMM_DI,
    DATA_REQ    => COMM_D_REQ,
    DATA_ACK    => COMM_D_ACK );

u_RAM : entity work.memctrl
port map(            
    CLK         => CLK,
    RESET       => RESET,
      
    MEM_A       => RAM_A,
    MEM_DI      => RAM_DI,
    MEM_DO      => RAM_DO,
    MEM_RW      => RAM_RW,
    MEM_REQ     => RAM_REQ,
    MEM_ACK     => RAM_ACK,

    SRAM_A      => SRAM_A,
    SRAM_D      => SRAM_D,
    SRAM_CE0    => SRAM_CE0,
    SRAM_CE1    => SRAM_CE1,
    SRAM_OE     => SRAM_OE,
    SRAM_WE     => SRAM_WE,
    SRAM_UB     => SRAM_UB,
    SRAM_LB     => SRAM_LB );

u_KEYBOARD : entity work.keyboard
port map(
   clk          => CLK,
   reset        => RESET,
   PS2_Clk      => KEYB_CLK,
   PS2_Data     => KEYB_DATA,
   Key_Data     => KB_DATA ); 

reset_generator : process(CLK)
begin
    if rising_edge(CLK) then
        if LOCKED = '1' then
            if TICK /= "1111" then
                TICK <= TICK + 1;
            else
                RESET <= '0';
            end if;
        end if;
    end if;
end process;

p_state_machine : process(CLK)
begin
    if rising_edge(CLK) then
        if RESET = '1' then

            STATE <= ST_IDLE;

            COMM_A_ACK <= '0';
            COMM_D_ACK <= '0';
            COMM_RDY   <= '0';
            VWR <= '0';
            RAM_REQ <= '0';

        else

            COMM_A_ACK <= '0';
            COMM_D_ACK <= '0';
            VWR <= '0';
            RAM_REQ <= '0';

            case STATE is

                when ST_IDLE =>
           
                    if COMM_A_REQ = '1' then
                        COMM_A_ACK <= '1';
                        COMM_RG <= COMM_AO;
                        
                        if COMM_AO(7) = '0' then
                            STATE <= ST_READ_DATA;
                        end if;
                        
                    elsif COMM_D_REQ = '1' then
                        COMM_D_ACK <= '1';
                    
                        if COMM_RG(7) = '0' then -- ### READ ###
                            STATE <= ST_READ_DATA;
                        else
                            STATE <= ST_WRITE_DATA;
                        end if;
                    end if;
                
                when ST_READ_DATA =>
                    case ('0' & COMM_RG(6 downto 0)) is
                    
                        when CMD_VIDEO_MODE =>
                            COMM_DI <= VRG;
                            STATE <= ST_IDLE;
                    
                        when CMD_VIDEO_ATTR =>
                            VA <= std_logic_vector(POS_Y) & std_logic_vector(POS_X);
                            STATE <= ST_READ_VRAM_A;
                 
                        when CMD_VIDEO_X_POS =>
                            COMM_DI <= '0' & std_logic_vector(POS_X);
                            STATE <= ST_IDLE;

                        when CMD_VIDEO_Y_POS =>
                            COMM_DI <= "000" & std_logic_vector(POS_Y);
                            STATE <= ST_IDLE;

                        when CMD_VIDEO_CHAR =>
                            VA <= std_logic_vector(POS_Y) & std_logic_vector(POS_X);
                            STATE <= ST_READ_VRAM_D;
                        
                        when CMD_RAM_MODE =>
                            COMM_DI <= RAM_RG;
                            STATE <= ST_IDLE;
    
                        when CMD_RAM_DATA =>
                            RAM_A <= COMM_MA;
                            RAM_RW <= '0';
                            RAM_REQ <= '1';
                            if RAM_RG(0) = '0' then
                                COMM_MA <= std_logic_vector(unsigned(COMM_MA) + 1); 
                            else
                                COMM_MA <= std_logic_vector(unsigned(COMM_MA) + 2); 
                            end if;
                            STATE <= ST_READ;
                            
                        when CMD_KEYBOARD =>
                            COMM_DI <= KB_DATA;
                            STATE <= ST_IDLE;

                        when OTHERS =>
                            STATE <= ST_IDLE;

                    end case;
                        
                when ST_WRITE_DATA =>
                        
                    case ('0' & COMM_RG(6 downto 0)) is

                        when CMD_VIDEO_MODE =>
                            VRG <= COMM_DO;
                            STATE <= ST_IDLE;

                        when CMD_VIDEO_ATTR =>
                            VATTR <= COMM_DO;
                            if VRG(2) = '1' then
                                STATE <= ST_INC;
                            else
                                STATE <= ST_IDLE;
                            end if;
                 
                        when CMD_VIDEO_X_POS =>
                            POS_X <= unsigned(COMM_DO(6 downto 0));
                            STATE <= ST_IDLE;

                        when CMD_VIDEO_Y_POS =>
                            POS_Y <= unsigned(COMM_DO(4 downto 0));
                            STATE <= ST_IDLE;

                        when CMD_VIDEO_CHAR =>
                            VDI <= COMM_DO;
                            VWR <= '1';
                            VA <= std_logic_vector(POS_Y) & std_logic_vector(POS_X);
                            if VRG(0) = '1' then
                                STATE <= ST_INC;
                            else
                                STATE <= ST_IDLE;
                            end if;
                    
                        when CMD_RAM_MODE =>
                            RAM_RG <= COMM_DO;
                            STATE <= ST_IDLE;
                        
                        when CMD_RAM_H_ADDR =>
                            COMM_MA(19 downto 16)  <= COMM_DO(3 downto 0);
                            STATE <= ST_IDLE;

                        when CMD_RAM_M_ADDR =>
                            COMM_MA(15 downto 8)  <= COMM_DO;
                            STATE <= ST_IDLE;

                        when CMD_RAM_L_ADDR =>
                            COMM_MA(7  downto 0 )  <= COMM_DO;
                            STATE <= ST_IDLE;

                        when CMD_RAM_DATA =>
                            RAM_A <= COMM_MA;
                            RAM_DI <= COMM_DO;
                            RAM_RW <= '1';
                            RAM_REQ <= '1';
                            if RAM_RG(0) = '0' then
                                COMM_MA <= std_logic_vector(unsigned(COMM_MA) + 1); 
                            else
                                COMM_MA <= std_logic_vector(unsigned(COMM_MA) + 2); 
                            end if;
                            STATE <= ST_WRITE;

                        when OTHERS =>
                            STATE <= ST_IDLE;

                    end case;

                when ST_READ_VRAM_A =>
                    COMM_DI <= VDO(15 downto 8);
                    if VRG(3) = '1' then
                        STATE <= ST_INC;
                    else
                        STATE <= ST_IDLE;
                    end if;

                when ST_READ_VRAM_D =>
                    COMM_DI <= VDO(7 downto 0);
                    if VRG(1) = '1' then
                        STATE <= ST_INC;
                    else
                        STATE <= ST_IDLE;
                    end if;

                when ST_WRITE =>
                    if RAM_ACK = '1' then
                        STATE <= ST_IDLE;
                    end if;

                when ST_READ =>
                    if RAM_ACK = '1' then
                        COMM_DI <= RAM_DO;
                        STATE <= ST_IDLE;
                    end if;
                    
                when ST_INC =>
                    POS_X <= POS_X + 1;
                    if POS_X = 79 then 
                        POS_X <= "0000000";
                        POS_Y <= POS_Y + 1;
                        if POS_Y = 29 then
                            POS_Y <= "00000";
                        end if;
                    end if;
                    STATE <= ST_IDLE;

                when OTHERS =>
                    STATE <= ST_IDLE;
           
            end case;

        end if;
    end if;
end process;

end rtl;

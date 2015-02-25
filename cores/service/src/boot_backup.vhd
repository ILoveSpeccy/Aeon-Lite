library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

entity boot is
port (
   CLK50       : in     std_logic;

   BUTTON1     : in     std_logic;
   BUTTON2     : in     std_logic;

   LED1        : out    std_logic;
   LED2        : out    std_logic;
   
   SRAM_A      : out    std_logic_vector(18 downto 0);
   SRAM_D      : inout  std_logic_vector(15 downto 0);
   SRAM_WE     : out    std_logic;
   SRAM_OE     : out    std_logic;
   SRAM_UB     : out    std_logic;
   SRAM_LB     : out    std_logic;
   SRAM_CE0    : out    std_logic;
   SRAM_CE1    : out    std_logic;
   
   COMM_CSA    : in     std_logic;
   COMM_CSD    : in     std_logic;
   COMM_SCK    : in     std_logic;
   COMM_SDI    : in     std_logic;
   COMM_SDO    : out    std_logic;
   COMM_READY  : out    std_logic;

	VGA_R			: out    std_logic_vector(3 downto 0);
	VGA_G			: out    std_logic_vector(3 downto 0);
	VGA_B			: out    std_logic_vector(3 downto 0);
	VGA_VSYNC	: out		std_logic;
	VGA_HSYNC	: out		std_logic
);
end boot;

architecture rtl of boot is

   -- SPI COMMANDS
   constant CMD_SET_ATTR   : std_logic_vector(6 downto 0) := "0000000";
   constant CMD_SET_X      : std_logic_vector(6 downto 0) := "0000001";
   constant CMD_SET_Y      : std_logic_vector(6 downto 0) := "0000010";
   constant CMD_WRITE_CHAR : std_logic_vector(6 downto 0) := "0000011";
   constant CMD_H_ADDR     : std_logic_vector(6 downto 0) := "0000100";
   constant CMD_M_ADDR     : std_logic_vector(6 downto 0) := "0000101";
   constant CMD_L_ADDR     : std_logic_vector(6 downto 0) := "0000110";
   constant CMD_DATA_WR    : std_logic_vector(6 downto 0) := "0000111"; 
   constant CMD_DATA_RD    : std_logic_vector(6 downto 0) := "0001000"; 
   
   signal CLK              : std_logic;
   signal VGA_CLK          : std_logic;
   signal RESET            : std_logic;
   signal LOCKED           : std_logic;
   
   signal SRAM_DI          : std_logic_vector(15 downto 0);
   signal SRAM_DO          : std_logic_vector(15 downto 0);
   
   signal VA               : std_logic_vector(11 downto 0);
   signal VDI              : std_logic_vector(7 downto 0);
   signal VWR              : std_logic;
   signal VATTR            : std_logic_vector(7 downto 0);
   
   signal COMM_AO          : std_logic_vector(7 downto 0);
   signal COMM_AI          : std_logic_vector(7 downto 0);
   signal COMM_A_REQ       : std_logic;
   signal COMM_A_ACK       : std_logic;

   signal COMM_DO          : std_logic_vector(7 downto 0);
   signal COMM_DI          : std_logic_vector(7 downto 0);
   signal COMM_D_REQ       : std_logic;
   signal COMM_D_ACK       : std_logic;

   signal COMM_RG          : std_logic_vector(7 downto 0);
   signal COMM_MA          : std_logic_vector(19 downto 0);

   type STATES is (ST_IDLE, ST_READ1, ST_READ2, ST_WRITE1);
   signal STATE : STATES;

begin

LED1 <= BUTTON1;
LED2 <= not BUTTON1 and not BUTTON2;

u_CLOCK : entity work.clock
port map(
   CLK50          => CLK50,
   CLK            => CLK,
   VGA_CLK        => VGA_CLK,
   LOCKED         => LOCKED );

-- ###########################
RESET <= not LOCKED;

u_VIDEO : entity work.video
port map(
   CLK         => CLK,
   VGA_CLK     => VGA_CLK,
   RESET       => RESET,

   VA          => VA,
   VDI         => VDI,
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
   SPI_DI      => COMM_SDI,
   SPI_DO      => COMM_SDO,

   ADDR_O      => COMM_AO,
   ADDR_I      => COMM_AI,
   ADDR_REQ    => COMM_A_REQ,
   ADDR_ACK    => COMM_A_ACK,

   DATA_O      => COMM_DO,
   DATA_I      => COMM_DI,
   DATA_REQ    => COMM_D_REQ,
   DATA_ACK    => COMM_D_ACK );

   p_state_machine : process(CLK)
   begin
      if rising_edge(CLK) then
         if RESET = '1' then

            STATE <= ST_IDLE;

            SRAM_DI <= (OTHERS=>'Z');
            SRAM_WE <= '1';
            SRAM_OE <= '1';
            SRAM_CE0 <= '1';
            SRAM_CE1 <= '1';
            SRAM_LB <= '1';
            SRAM_UB <= '1';

            COMM_A_ACK <= '0';
            COMM_D_ACK <= '0';
            COMM_READY <= '0';
            
            VWR <= '0';

         else

            COMM_A_ACK <= '0';
            COMM_D_ACK <= '0';
            VWR <= '0';

            case STATE is

               when ST_IDLE =>
               
                  SRAM_DI <= (OTHERS=>'Z');
                  SRAM_WE <= '1';
                  SRAM_OE <= '1';
                  SRAM_CE0 <= '1';
                  SRAM_CE1 <= '1';
                  SRAM_LB <= '1';
                  SRAM_UB <= '1';

                  if COMM_A_REQ = '1' then
                     COMM_A_ACK <= '1';
                     COMM_RG <= COMM_AO;
                     
                     if COMM_AO(7) = '0' then -- ### READ ###

                        case (COMM_AO(6 downto 0)) is

                           when CMD_DATA_RD =>
                              SRAM_A <= '0' & COMM_MA(17 downto 0);
                              SRAM_OE <= '0';

                              if COMM_MA(18) = '0' then
                                 SRAM_CE0 <= '0';
                              else
                                 SRAM_CE1 <= '0';
                              end if;
                           
                              if COMM_MA(19) = '0' then
                                 SRAM_LB <= '0';
                              else
                                 SRAM_UB <= '0';
                              end if;
                           
                              COMM_MA <= std_logic_vector(unsigned(COMM_MA) + 1);
                              STATE <= ST_READ1;

                           when OTHERS =>
                              NULL;

                        end case;
                     end if;
               
                  elsif COMM_D_REQ = '1' then
                     COMM_D_ACK <= '1';

                     if COMM_RG(7) = '1' then -- ### WRITE ###
                        case (COMM_RG(6 downto 0)) is

                           when CMD_SET_ATTR =>
                              VATTR <= COMM_DO;
                     
                           when CMD_SET_X =>
                              VA <= VA(11 downto 7) & COMM_DO(6 downto 0);

                           when CMD_SET_Y =>
                              VA <= COMM_DO(4 downto 0) & VA(6 downto 0);

                           when CMD_WRITE_CHAR =>
                              VDI <= COMM_DO;
                              VWR <= '1';
                        
                           when CMD_H_ADDR =>
                              COMM_MA(19 downto 16)  <= COMM_DO(3 downto 0);

                           when CMD_M_ADDR =>
                              COMM_MA(15 downto 8)  <= COMM_DO;

                           when CMD_L_ADDR =>
                              COMM_MA(7  downto 0 )  <= COMM_DO;

                           when CMD_DATA_WR =>
                              SRAM_A <= '0' & COMM_MA(17 downto 0);
                              SRAM_DI <= COMM_DO & COMM_DO;
                              SRAM_WE <= '0';

                              if COMM_MA(18) = '0' then
                                 SRAM_CE0 <= '0';
                              else
                                 SRAM_CE1 <= '0';
                              end if;
                           
                              if COMM_MA(19) = '0' then
                                 SRAM_LB <= '0';
                              else
                                 SRAM_UB <= '0';
                              end if;
                           
                              COMM_MA <= std_logic_vector(unsigned(COMM_MA) + 1);
                              STATE <= ST_WRITE1;

                           when OTHERS =>
                              NULL;

                        end case;
                     end if;
                  end if;

               when ST_READ1 =>
                  if COMM_MA(19) = '0' then
                     COMM_DI <= SRAM_DO(7 downto 0);
                  else
                     COMM_DI <= SRAM_DO(15 downto 8);
                  end if;
                  STATE <= ST_READ2;

               when ST_READ2 =>
                  if COMM_D_REQ = '1' then
                     COMM_D_ACK <= '1';
                     STATE <= ST_IDLE;
                  end if;

               when ST_WRITE1 =>
                  SRAM_WE <= '1';
                  STATE <= ST_IDLE;

               when OTHERS =>
                  STATE <= ST_IDLE;
               
            end case;

         end if;
      end if;
   end process;

   SRAM_D <= SRAM_DI;
   SRAM_DO <= SRAM_D;

end rtl;

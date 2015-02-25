library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL; 

entity memctrl is
    Port (            
        CLK         : in    std_logic;
        RESET       : in    std_logic;
      
        MEM_A       : in    std_logic_vector(19 downto 0);
        MEM_DI      : in    std_logic_vector(7 downto 0);
        MEM_DO      : out   std_logic_vector(7 downto 0);
        MEM_RW      : in    std_logic;
        MEM_REQ     : in    std_logic;
        MEM_ACK     : out   std_logic;
      
        SRAM_A      : out   std_logic_vector(17 downto 0); 
        SRAM_D      : inout std_logic_vector(15 downto 0); 
        SRAM_CE0    : out   std_logic;
        SRAM_CE1    : out   std_logic;
        SRAM_OE     : out   std_logic;
        SRAM_WE     : out   std_logic;
        SRAM_UB     : out   std_logic;
        SRAM_LB     : out   std_logic );
end memctrl;

architecture Behavioral of memctrl is

    signal SRAM_DI : std_logic_vector(15 downto 0);
    signal SRAM_DO : std_logic_vector(15 downto 0);

    -- STATEMACHINE   
    type STATE_TYPE is (IDLE, READ1, WRITE1, WRITE2, DONE);
    signal STATE : STATE_TYPE := IDLE;

begin

SRAM_D <= SRAM_DI;
SRAM_DO <= SRAM_D;
   
process (CLK)
begin
    if rising_edge(CLK) then    
        if RESET = '1' then
            SRAM_A <= (others=>'0');
            SRAM_DI <= (others=>'Z');
            SRAM_CE0 <= '1';
            SRAM_CE1 <= '1';
            SRAM_OE <= '1';
            SRAM_WE <= '1';
            SRAM_UB <= '1';
            SRAM_LB <= '1';
            MEM_DO <= "11111111";
            MEM_ACK <= '0';
        else
            MEM_ACK <= '0';
            case STATE is
                when IDLE =>
                    if MEM_REQ = '1' then  
                        SRAM_A <= MEM_A(18 downto 1);
                        
                        if MEM_A(19) = '0' then
                            SRAM_CE0 <= '0';
                        else
                            SRAM_CE1 <= '0';
                        end if;

                        if MEM_A(0) = '0' then
                            SRAM_LB <= '0';
                        else
                            SRAM_UB <= '0';
                        end if;
                        
                        if MEM_RW = '0' then
                            SRAM_OE <= '0';
                            STATE <= READ1;
                        else
                            SRAM_DI <= MEM_DI & MEM_DI;
                            SRAM_WE <= '0';
                            STATE <= WRITE1;
                        end if;
                    end if;
            
                when READ1 =>
                    if MEM_A(0) = '0' then
                        MEM_DO <= SRAM_DO(7 downto 0);
                    else
                        MEM_DO <= SRAM_DO(15 downto 8);
                    end if;
                        
                    SRAM_LB <= '1';
                    SRAM_UB <= '1';
                    SRAM_CE0 <= '1';
                    SRAM_CE1 <= '1';
                    SRAM_OE <= '1';
                    MEM_ACK <= '1';
                    STATE <= DONE;
            
                when WRITE1 =>
                    SRAM_CE0 <= '1';
                    SRAM_CE1 <= '1';
                    SRAM_WE <= '1';
                    STATE <= WRITE2;
            
                when WRITE2 =>
                    SRAM_DI <= (others=>'Z');
                    MEM_ACK <= '1';
                    STATE <= DONE;               
         
                when DONE =>
                    STATE <= IDLE;

                when others =>
                    STATE <= IDLE;
            end case;   
        end if;
    end if;
end process;

end Behavioral;

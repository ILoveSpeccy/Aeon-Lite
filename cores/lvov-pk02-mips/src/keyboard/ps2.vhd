-- #####################################################################################
--
-- #### ####                              #####
--  ##   ##                              ##
--  ##   ##       #####  ##   ##  #####  ##      ######   #####   #####   #####  ##   ##
--  ##   ##      ##   ## ##   ## ##   ## ##      ##   ## ##   ## ##   ## ##   ## ##   ##
--  ##   ##      ##   ## ##   ## ##   ##  #####  ##   ## ##   ## ##      ##      ##   ##
--  ##   ##      ##   ## ##   ## ######       ## ######  ######  ##      ##       ######
--  ##   ##      ##   ##  ## ##  ##           ## ##      ##      ##      ##           ##
--  ##   ##   ## ##   ##   ###   ##   ## ##   ## ##      ##   ## ##   ## ##   ## ##   ##
-- #### ########  #####     #     #####   #####  ##       #####   #####   #####   #####
--
-- #####################################################################################

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity ps2 is
generic (FilterSize : positive := 3);
port(
    CLK         : in    std_logic;
    RESET       : in    std_logic;
    PS2_CLK     : in    std_logic;
    PS2_DATA    : in    std_logic;
    CODE        : out   std_logic_vector(7 downto 0);
    DONE        : out   std_logic;
    ERROR       : out   std_logic );
end ps2;

architecture rtl of ps2 is

    signal Filter       : unsigned(FilterSize-1 downto 0);
    signal Filter_High  : unsigned(FilterSize-1 downto 0);
    signal Filter_Low   : unsigned(FilterSize-1 downto 0);
    signal PS2_CLK_LOCK : std_logic;
    signal PS2_CLK_TICK : std_logic;
    signal shift_state  : unsigned(3 downto 0);
    signal CODE_TEMP    : std_logic_vector(7 downto 0);
    signal parity       : std_logic;

begin

    Filter_High <= (others=>'1');
    Filter_Low <= (others=>'0');
    
clockfilter : process (CLK) -- PS2 Clock Filter
begin
    if rising_edge(CLK) then
        if RESET = '1' then
            Filter <= (others=>'0');
            PS2_CLK_LOCK <= '0';
            PS2_CLK_TICK <= '1';
        else
            PS2_CLK_TICK <= '1';
            if PS2_CLK = '0' then
                if Filter /= Filter_High then
                    Filter <= Filter + 1;
                else
                    PS2_CLK_LOCK <= '1';
                    if PS2_CLK_LOCK = '0' then
                        PS2_CLK_TICK <= '0';
                    end if;
                end if;
            else
                if Filter /= Filter_Low then
                    Filter <= Filter - 1;
                else
                    PS2_CLK_LOCK <= '0';
                end if;
            end if;
        end if;
    end if;
end process;

shiftregister : process (CLK)
begin
    if rising_edge(CLK) then
        if RESET = '1' then
            shift_state <= "0000";
            CODE_TEMP <= "00000000";
            DONE <= '0';
            ERROR <= '0';
        else
            DONE <= '0';
            ERROR <= '0';
            if PS2_CLK_TICK = '0' then -- PS2 Clock Detected
                case to_integer(shift_state) is
                    
                    when 0 => -- start bit
                        if PS2_DATA = '0' then
                            shift_state <= "0001";
                            parity <= '1';
                        else
                            shift_state <= "0000"; -- error
                            ERROR <= '1';
                        end if;
                        
                    when 1 to 8 => -- data bits
                        CODE_TEMP(to_integer(shift_state-1)) <= PS2_DATA;
                        shift_state <= shift_state + 1;
                        parity <= parity xor PS2_DATA;
                        
                    when 9 => -- parity bit
                        if parity = PS2_DATA then
                            shift_state <= shift_state + 1;
                        else
                            shift_state <= "0000"; -- error
                            ERROR <= '1';
                        end if;
                        
                    when 10 => -- stop bit
                        if PS2_DATA = '1' then
                            DONE <= '1';
                            CODE <= CODE_TEMP;
                            shift_state <= "0000";
                        else
                            shift_state <= "0000"; -- error
                            ERROR <= '1';
                        end if;
                        
                    when others => null;
                    
                end case;
            end if;
        end if;
    end if;
end process;

end rtl;

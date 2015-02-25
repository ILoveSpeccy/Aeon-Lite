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

entity oneshot is
generic (SIZE : positive := 22);
port(
    CLK         : in    std_logic;
    RESET       : in    std_logic;
    ONESHOT_IN  : in    std_logic;
    ONESHOT_OUT : out   std_logic );
end oneshot;

architecture rtl of oneshot is

    signal COUNTER      : unsigned(SIZE-1 downto 0);
    signal ONES         : unsigned(SIZE-1 downto 0);
    signal LOCK         : std_logic;

begin

ONES <= (others=>'1');

process(CLK)
begin
    if rising_edge(CLK) then
        if RESET = '1' then
            LOCK <= '0';
            COUNTER <= (others=>'0');
        else
            if ONESHOT_IN = '1' then
                LOCK <= '1';
            end if;
            if LOCK = '1' then
                if COUNTER /= ONES then
                    COUNTER <= COUNTER + 1;
                else
                    LOCK <= '0';
                    COUNTER <= (others=>'0');
                end if;
            end if;
        end if;
    end if;
end process;

ONESHOT_OUT <= LOCK;

end rtl;

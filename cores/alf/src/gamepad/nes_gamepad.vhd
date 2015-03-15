---------------------------------------------------------------------------
-- NES-Controller Module
---------------------------------------------------------------------------
-- This file is a part of "Aeon Lite" project
-- Dmitriy Schapotschkin aka ILoveSpeccy '2014
-- ilovespeccy@speccyland.net
-- Project homepage: www.speccyland.net
---------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

------------------
-- Bit - Button --
-- (1 = pressed)
------------------
--  7     A
--  6     B
--  5     Select
--  4     Start
--  3     Up
--  2     Down
--  1     Left
--  0     Right
------------------

entity nes_gamepad is
generic (
    CLK_FREQ        : integer   := 25000000;
    TICK_FREQ       : integer   := 20000 );
port ( 
    CLK             : in     std_logic;
    RESET           : in     std_logic;
    
    JOY_CLK         : out    std_logic;
    JOY_LOAD        : out    std_logic;
    JOY_DATA0       : in     std_logic;
    JOY_DATA1       : in     std_logic;
   
    JOY0_BUTTONS    : out    std_logic_vector(7 downto 0);
    JOY1_BUTTONS    : out    std_logic_vector(7 downto 0);
    
    JOY0_CONNECTED  : out    std_logic; -- 1 when gamepad connected
    JOY1_CONNECTED  : out    std_logic );
end nes_gamepad;

architecture RTL of nes_gamepad is

    signal TICK     : integer range 0 to (CLK_FREQ / TICK_FREQ);
    signal STATE    : integer range 0 to 17;
    signal DATA0    : std_logic_vector(7 downto 0); 
    signal DATA1    : std_logic_vector(7 downto 0); 
   
begin

process (CLK)
begin
    if rising_edge(CLK) then
        if RESET = '1' then
            STATE <= 0;
            JOY_CLK <= '0';
            JOY_LOAD <= '0';
            TICK <= 0;
            JOY0_BUTTONS <= "00000000";
            JOY0_BUTTONS <= "00000000";
            JOY0_CONNECTED <= '0';
            JOY1_CONNECTED <= '0';
        else
            TICK <= TICK + 1;
            if TICK = (CLK_FREQ / TICK_FREQ) then
                TICK <= 0;
                STATE <= STATE + 1;
            
                case STATE is
               
                    when 0 =>
                        JOY_LOAD <= '1';

                    when 1 => 
                        JOY_LOAD <= '0';
                        DATA0(7) <= JOY_DATA0;
                        DATA1(7) <= JOY_DATA1;

                    when 2 | 4 | 6 | 8 | 10 | 12 | 14 | 16 => 
                        JOY_CLK <= '1';
                  
                    when 3 =>
                        JOY_CLK <= '0';
                        DATA0(6) <= JOY_DATA0;
                        DATA1(6) <= JOY_DATA1;
                              
                    when 5 =>
                        JOY_CLK <= '0';
                        DATA0(5) <= JOY_DATA0;
                        DATA1(5) <= JOY_DATA1;
            
                    when 7 =>
                        JOY_CLK <= '0';
                        DATA0(4) <= JOY_DATA0;
                        DATA1(4) <= JOY_DATA1;

                    when 9 =>
                        JOY_CLK <= '0';
                        DATA0(3) <= JOY_DATA0;
                        DATA1(3) <= JOY_DATA1;
                  
                    when 11 =>
                        JOY_CLK <= '0';
                        DATA0(2) <= JOY_DATA0;
                        DATA1(2) <= JOY_DATA1;
            
                    when 13 =>
                        JOY_CLK <= '0';
                        DATA0(1) <= JOY_DATA0;
                        DATA1(1) <= JOY_DATA1;
                  
                    when 15 =>
                        JOY_CLK <= '0';
                        DATA0(0) <= JOY_DATA0;
                        DATA1(0) <= JOY_DATA1;

                    when 17 =>
                        JOY_CLK <= '0';
                        JOY0_BUTTONS <= "00000000";
                        JOY1_BUTTONS <= "00000000";
                        JOY0_CONNECTED <= '0';
                        JOY1_CONNECTED <= '0';
                        STATE <= 0;

                        if DATA0 /= "00000000" then -- gamepad connected
                            JOY0_BUTTONS <= not DATA0;
                            JOY0_CONNECTED <= '1';
                        end if;

                        if DATA1 /= "00000000" then -- gamepad connected
                            JOY1_BUTTONS <= not DATA1;
                            JOY1_CONNECTED <= '1';
                        end if;

                    when OTHERS =>
                        NULL;
                  
                end case;
            end if;
        end if;
    end if;
end process; 
   
end RTL;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity keyboard is
port(
    CLK         : in    std_logic;
    RESET       : in    std_logic;
    PS2_CLK     : in    std_logic;
    PS2_DATA    : in    std_logic;
    KEYB_DATA   : out   std_logic_vector(4 downto 0);
    RESET_TICK  : out   std_logic);
end keyboard;

architecture rtl of keyboard is
   
    signal CODE         : std_logic_vector(7 downto 0); -- Scancode recieved from keyboard
    signal DONE         : std_logic;                    -- Current scancode valid
    signal ERROR        : std_logic;                    -- Current scancode corrupted
    
    signal RELEASED_KEY : std_logic;
    signal EXTENDED_KEY : std_logic;

    signal KEYB_DATA_TEMP : std_logic_vector(4 downto 0);

begin

keyb_data <= KEYB_DATA_TEMP;

u_PS2 : entity work.ps2
port map(
    CLK         => CLK,
    RESET       => RESET,
    PS2_CLK     => PS2_CLK,
    PS2_DATA    => PS2_DATA,
    CODE        => CODE,
    DONE        => DONE,
    ERROR       => ERROR );

main : process(CLK)
begin
    if rising_edge(CLK) then
        if RESET = '1' then
            RELEASED_KEY <= '0';
            EXTENDED_KEY <= '0';
            RESET_TICK <= '0';
            KEYB_DATA_TEMP <= "00000";
        else
            RESET_TICK <= '0';
            if ERROR = '1' then
                RELEASED_KEY <= '0';
                EXTENDED_KEY <= '0';
            elsif DONE = '1' then
                if CODE = X"F0" then
                    RELEASED_KEY <= '1';
                elsif CODE = X"E0" then
                    EXTENDED_KEY <= '1';
                elsif CODE = X"07" and RELEASED_KEY = '1' then
                    RESET_TICK <= '1';
                else
                    if EXTENDED_KEY = '1' then
                        if CODE = X"75" then
                           KEYB_DATA_TEMP(3) <= not RELEASED_KEY; -- up
                        elsif CODE = X"72" then
                           KEYB_DATA_TEMP(2) <= not RELEASED_KEY; -- down
                        elsif CODE = X"6B" then
                           KEYB_DATA_TEMP(1) <= not RELEASED_KEY; -- left
                        elsif CODE = X"74" then
                           KEYB_DATA_TEMP(0) <= not RELEASED_KEY; -- right
                        end if;
                    else
                        if CODE = X"29" or CODE = X"5A" then
                           KEYB_DATA_TEMP(4) <= not RELEASED_KEY; -- space/enter for fire
                        end if;
                    end if;
                    RELEASED_KEY <= '0';
                    EXTENDED_KEY <= '0';
                end if;
            end if;
        end if;
    end if;
end process;

end; 
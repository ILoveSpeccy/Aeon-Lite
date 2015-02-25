library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity keyboard is
port(
    CLK         : in    std_logic;
    RESET       : in    std_logic;
    PS2_CLK     : in    std_logic;
    PS2_DATA    : in    std_logic;
    KEYB_ADDR   : in    std_logic_vector(7 downto 0);
    KEYB_DATA   : out   std_logic_vector(4 downto 0);
    RESET_TICK  : out   std_logic;
    NMI_TICK    : out   std_logic );
end keyboard;

architecture rtl of keyboard is
   
    signal CODE         : std_logic_vector(7 downto 0); -- Scancode recieved from keyboard
    signal DONE         : std_logic;                    -- Current scancode valid
    signal ERROR        : std_logic;                    -- Current scancode corrupted

    signal LOOKUP       : std_logic_vector(7 downto 0); -- bits 7-5 - A8..A15, bits 4-0 - D4..D0
    
    signal RELEASED_KEY : std_logic;
    signal EXTENDED_KEY : std_logic;

    type MATRIX_IMAGE is array (natural range <>) of std_logic_vector(4 downto 0);
    signal MATRIX : MATRIX_IMAGE(0 to 7); -- Speccy keyboard matrix

begin

u_PS2 : entity work.ps2
port map(
    CLK         => CLK,
    RESET       => RESET,
    PS2_CLK     => PS2_CLK,
    PS2_DATA    => PS2_DATA,
    CODE        => CODE,
    DONE        => DONE,
    ERROR       => ERROR );
    
decoder : process (CODE)
begin
    case CODE is
        when X"12" => LOOKUP <= "00000001"; -- left/caps shift
        when X"1a" => LOOKUP <= "00000010"; -- z
        when X"22" => LOOKUP <= "00000100"; -- x
        when X"21" => LOOKUP <= "00001000"; -- c
        when X"2a" => LOOKUP <= "00010000"; -- v
        when X"1c" => LOOKUP <= "00100001"; -- a
        when X"1b" => LOOKUP <= "00100010"; -- s
        when X"23" => LOOKUP <= "00100100"; -- d
        when X"2b" => LOOKUP <= "00101000"; -- f
        when X"34" => LOOKUP <= "00110000"; -- g
        when X"15" => LOOKUP <= "01000001"; -- q
        when X"1d" => LOOKUP <= "01000010"; -- w
        when X"24" => LOOKUP <= "01000100"; -- e
        when X"2d" => LOOKUP <= "01001000"; -- r
        when X"2c" => LOOKUP <= "01010000"; -- t
        when X"16" => LOOKUP <= "01100001"; -- 1
        when X"69" => LOOKUP <= "01100001"; -- 1
        when X"1e" => LOOKUP <= "01100010"; -- 2
        when X"72" => LOOKUP <= "01100010"; -- 2
        when X"26" => LOOKUP <= "01100100"; -- 3
        when X"7a" => LOOKUP <= "01100100"; -- 3
        when X"25" => LOOKUP <= "01101000"; -- 4
        when X"6b" => LOOKUP <= "01101000"; -- 4
        when X"2e" => LOOKUP <= "01110000"; -- 5
        when X"73" => LOOKUP <= "01110000"; -- 5
        when X"45" => LOOKUP <= "10000001"; -- 0
        when X"70" => LOOKUP <= "10000001"; -- 0
        when X"46" => LOOKUP <= "10000010"; -- 9
        when X"7d" => LOOKUP <= "10000010"; -- 9
        when X"3e" => LOOKUP <= "10000100"; -- 8
        when X"75" => LOOKUP <= "10000100"; -- 8
        when X"3d" => LOOKUP <= "10001000"; -- 7
        when X"6c" => LOOKUP <= "10001000"; -- 7
        when X"36" => LOOKUP <= "10010000"; -- 6
        when X"74" => LOOKUP <= "10010000"; -- 6
        when X"4d" => LOOKUP <= "10100001"; -- p
        when X"44" => LOOKUP <= "10100010"; -- o
        when X"43" => LOOKUP <= "10100100"; -- i
        when X"3c" => LOOKUP <= "10101000"; -- u
        when X"35" => LOOKUP <= "10110000"; -- y
        when X"5a" => LOOKUP <= "11000001"; -- return
        when X"4b" => LOOKUP <= "11000010"; -- l
        when X"42" => LOOKUP <= "11000100"; -- k
        when X"3b" => LOOKUP <= "11001000"; -- j
        when X"33" => LOOKUP <= "11010000"; -- h
        when X"29" => LOOKUP <= "11100001"; -- Space
        when X"59" => LOOKUP <= "11100010"; -- right/symbol shift
        when X"3a" => LOOKUP <= "11100100"; -- m
        when X"31" => LOOKUP <= "11101000"; -- n
        when X"32" => LOOKUP <= "11110000"; -- b
        when others => LOOKUP <= "00000000";
    end case;
end process; 

main : process(CLK)
begin
    if rising_edge(CLK) then
        if RESET = '1' then
            MATRIX <= (others => (others => '0'));
            RELEASED_KEY <= '0';
            EXTENDED_KEY <= '0';
            RESET_TICK <= '0';
            NMI_TICK <= '0';
        else
            RESET_TICK <= '0';
            NMI_TICK <= '0';
            if ERROR = '1' then
                MATRIX <= (others => (others => '0'));
                RELEASED_KEY <= '0';
                EXTENDED_KEY <= '0';
            elsif DONE = '1' then
                if CODE = X"F0" then
                    RELEASED_KEY <= '1';
                elsif CODE = X"E0" then
                    EXTENDED_KEY <= '1';
                elsif CODE = X"07" and RELEASED_KEY = '1' then
                    RESET_TICK <= '1';
                elsif CODE = X"78" and RELEASED_KEY = '1' then
                    NMI_TICK <= '1';
                else
                    RELEASED_KEY <= '0';
                    EXTENDED_KEY <= '0';
--                    if LOOKUP /= "00000000" then
                        if RELEASED_KEY = '0' then
                            MATRIX(to_integer(unsigned(LOOKUP(7 downto 5)))) <= MATRIX(to_integer(unsigned(LOOKUP(7 downto 5)))) or std_logic_vector(unsigned(LOOKUP(4 downto 0))); 
                        else
                            MATRIX(to_integer(unsigned(LOOKUP(7 downto 5)))) <= MATRIX(to_integer(unsigned(LOOKUP(7 downto 5)))) and std_logic_vector(not unsigned(LOOKUP(4 downto 0))); 
                        end if;
--                    end if;
                end if;
            end if;
        end if;
    end if;
end process;

keyboard_output : for i in 0 to 4 generate
    KEYB_DATA(i) <= not ((MATRIX(0)(i) and not KEYB_ADDR(0)) or
                         (MATRIX(1)(i) and not KEYB_ADDR(1)) or
                         (MATRIX(2)(i) and not KEYB_ADDR(2)) or
                         (MATRIX(3)(i) and not KEYB_ADDR(3)) or
                         (MATRIX(4)(i) and not KEYB_ADDR(4)) or
                         (MATRIX(5)(i) and not KEYB_ADDR(5)) or
                         (MATRIX(6)(i) and not KEYB_ADDR(6)) or
                         (MATRIX(7)(i) and not KEYB_ADDR(7)) );
end generate;

end; 
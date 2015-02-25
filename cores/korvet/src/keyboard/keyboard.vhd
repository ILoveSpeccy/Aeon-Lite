-- ###################################################################################
--
-- #### ####                              #####
--  ##   ##       #####  ##   ##  #####  ##      ######   #####   #####  ##### ##   ##
--  ##   ##      ##   ## ##   ## ##   ##  #####  ##   ## ##   ## ##     ##     ##   ##
--  ##   ##      ##   ##  ## ##  ######       ## ######  ######  ##     ##      ######
--  ##   ##      ##   ##   ###   ##           ## ##      ##      ##     ##          ##
-- #### ########  #####     #     #####   #####  ##       #####   #####  #####  #####
--
-- ###################################################################################

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity keyboard is
  generic (FilterSize : positive := 10);
  port(
      clk        : in std_logic;
      reset      : in std_logic;
      o_reset    : out std_logic;
      PS2_Clk    : in std_logic;
      PS2_Data   : in std_logic;
      Key_Addr   : in std_logic_vector(8 downto 0);
      Key_Data   : out std_logic_vector(7 downto 0) );
end keyboard;

architecture Behavioral of keyboard is

  signal PS2_Datr  : std_logic;
  signal DoRead    : std_logic;  -- From outside when reading the scan code
  signal Scan_Err  : std_logic;  -- To outside : Parity or Overflow error
  signal Scan_Code : std_logic_vector(7 downto 0); -- Eight bits Data Out
  signal Filter    : std_logic_vector(FilterSize-1 downto 0);
  signal Filter_t0 : std_logic_vector(FilterSize-1 downto 0);
  signal Filter_t1 : std_logic_vector(FilterSize-1 downto 0);
  signal Fall_Clk  : std_logic;
  signal Bit_Cnt   : unsigned (3 downto 0);
  signal Parity    : std_logic;
  signal S_Reg     : std_logic_vector(8 downto 0);
  signal PS2_Clk_f : std_logic;  signal Code_Readed : std_logic;
  signal Key_Released : std_logic;
  signal Extend_Key   : std_logic;
  
  signal Key_Data_0 : std_logic_vector(7 downto 0);
  signal Key_Data_1 : std_logic_vector(7 downto 0);
  
  type 		Matrix_Image is array (natural range <>) of std_logic_vector(7 downto 0);
  signal	   Matrix_0	: Matrix_Image(0 to 7);
  signal	   Matrix_1	: Matrix_Image(0 to 7);

  Type   State_t is (Idle, Shifting);
  signal State : State_t;

begin

Filter_t0 <= (others=>'0');
Filter_t1 <= (others=>'1');

process (Clk,Reset)
begin
  if Reset='1' then
    PS2_Datr  <= '0';
    PS2_Clk_f <= '0';
    Filter    <= (others=>'0');
    Fall_Clk  <= '0';
  elsif rising_edge (Clk) then
    PS2_Datr <= PS2_Data and PS2_Data; -- also turns 'H' into '1'
    Fall_Clk <= '0';
    Filter   <= (PS2_Clk and PS2_CLK) & Filter(Filter'high downto 1);
    if Filter = Filter_t1 then
      PS2_Clk_f <= '1';
    elsif Filter = Filter_t0 then
      PS2_Clk_f <= '0';
      if PS2_Clk_f = '1' then
        Fall_Clk <= '1';
      end if;
    end if;
  end if;
end process;

process(Clk,Reset)
begin
  if Reset='1' then
    State     <= Idle;
    Bit_Cnt   <= (others => '0');
    S_Reg     <= (others => '0');
    Scan_Code <= (others => '0');
    Parity    <= '0';
    Scan_Err  <= '0';
    Code_Readed <= '0';
  elsif rising_edge (Clk) then
    Code_Readed <= '0';
    case State is
      when Idle =>
        Parity  <= '0';
        Bit_Cnt <= (others => '0');
        -- note that we dont need to clear the Shift Register
        if Fall_Clk='1' and PS2_Datr='0' then -- Start bit
          Scan_Err <= '0';
          State <= Shifting;
        end if;
      when Shifting =>
          if Bit_Cnt >= 9 then
            if Fall_Clk='1' then -- Stop Bit
              -- Error is (wrong Parity) or (Stop='0') or Overflow
              Scan_Err  <= (not Parity) or (not PS2_Datr);
              Scan_Code <= S_Reg(7 downto 0);
              Code_Readed <= '1';
              State <= Idle;
            end if;
          elsif Fall_Clk='1' then
            Bit_Cnt  <= Bit_Cnt + 1;
            S_Reg <= PS2_Datr & S_Reg (S_Reg'high downto 1); -- Shift right
            Parity <= Parity xor PS2_Datr;
          end if;
      when others => -- never reached
        State <= Idle;
    end case;
    --Scan_Err <= '0'; -- to create an on-purpose error on Scan_Err !
  end if;
end process;

process(Clk,Reset)
   variable aaa : std_logic_vector(10 downto 0);
   variable bbb : std_logic_vector(10 downto 0);
begin
  if Reset='1' then
    Matrix_0 <= (others => (others => '0'));
    Matrix_1 <= (others => (others => '0'));
    Key_Released <= '0';
    Extend_Key <= '0';
  elsif rising_edge (Clk) then
  
    o_reset <= '0';
  
    if Code_Readed = '1' then -- ScanCode is Readed
      if Scan_Code = x"F0" then -- Key is Released
         Key_Released <= '1';
      elsif Scan_Code = x"E0" then -- Extended Key Pressed
         Extend_Key <= '1';
      else -- Analyse
         aaa := (others=>'0');
         bbb := (others=>'0');
         case Scan_Code is
            ------------------------------------
            when x"52"  => aaa := "00000000001"; -- @
            when x"1C"  => aaa := "00000000010"; -- A
            when x"32"  => aaa := "00000000100"; -- B
            when x"21"  => aaa := "00000001000"; -- C
            when x"23"  => aaa := "00000010000"; -- D
            when x"24"  => aaa := "00000100000"; -- E
            when x"2B"  => aaa := "00001000000"; -- F
            when x"34"  => aaa := "00010000000"; -- G
            ------------------------------------
            when x"33"  => aaa := "00100000001"; -- H
            when x"43"  => aaa := "00100000010"; -- I
            when x"3B"  => aaa := "00100000100"; -- J
            when x"42"  => aaa := "00100001000"; -- K
            when x"4B"  => aaa := "00100010000"; -- L
            when x"3A"  => aaa := "00100100000"; -- M
            when x"31"  => aaa := "00101000000"; -- N
            when x"44"  => aaa := "00110000000"; -- O
            ------------------------------------
            when x"4D"  => aaa := "01000000001"; -- P
            when x"15"  => aaa := "01000000010"; -- Q
            when x"2D"  => aaa := "01000000100"; -- R
            when x"1B"  => aaa := "01000001000"; -- S
            when x"2C"  => aaa := "01000010000"; -- T
            when x"3C"  => aaa := "01000100000"; -- U
            when x"2A"  => aaa := "01001000000"; -- V
            when x"1D"  => aaa := "01010000000"; -- W
            ------------------------------------
            when x"22"  => aaa := "01100000001"; -- X
            when x"1A"  => aaa := "01100000010"; -- Y
            when x"35"  => aaa := "01100000100"; -- Z
            when x"54"  => aaa := "01100001000"; -- [
            when x"0E"  => aaa := "01100010000"; -- ?
            when x"5B"  => aaa := "01100100000"; -- ]
            when x"61"  => aaa := "01101000000"; -- ?
            when x"4C"  => aaa := "01110000000"; -- ?
            ------------------------------------
            when x"45"  => aaa := "10000000001"; -- 0
            when x"16"  => aaa := "10000000010"; -- 1
            when x"1E"  => aaa := "10000000100"; -- 2
            when x"26"  => aaa := "10000001000"; -- 3
            when x"25"  => aaa := "10000010000"; -- 4
            when x"2E"  => aaa := "10000100000"; -- 5
            when x"36"  => aaa := "10001000000"; -- 6
            when x"3D"  => aaa := "10010000000"; -- 7
            ------------------------------------
            when x"3E"  => aaa := "10100000001"; -- 8
            when x"46"  => aaa := "10100000010"; -- 9
            when x"5D"  => aaa := "10100000100"; -- *
            when x"55"  => aaa := "10100001000"; -- +
            when x"41"  => aaa := "10100010000"; -- <
            when x"4A"  => aaa := "10100100000"; -- =
            when x"49"  => aaa := "10101000000"; -- >
            when x"4E"  => aaa := "10110000000"; -- ?

            ------------------------------------
            when x"5A"  => aaa := "11000000001"; -- ENTER
            when x"7B"  => aaa := "11000000010"; -- ????
            when x"07"  => aaa := "11000000100"; -- ????
            when x"77"  => aaa := "11000001000"; -- ??
            when x"7C"  => aaa := "11000010000"; -- ??
            when x"66"  => aaa := "11000100000"; -- BACKSPACE
            when x"0D"  => aaa := "11001000000"; -- TAB
            when x"29"  => aaa := "11010000000"; -- SPACE
            ------------------------------------
            when x"12"  => aaa := "11100000001"; -- ?? ???.
            when x"11"  => 
            case Extend_Key is
               when '0' => aaa := "11100000010"; -- ???
            when others => aaa := "11100000100"; -- ????
            end case;
            when x"76"  => aaa := "11100001000"; -- ???
            when x"14"  =>
            case Extend_Key is
               when '0' => aaa := "11101000000"; -- o
            when others => aaa := "11100010000"; -- ???
            end case;
            when x"58"  => aaa := "11100100000"; -- ???
            when x"59"  => aaa := "11110000000"; -- ?? ????.
            ------------------------------------
            when x"70"  => bbb := "00000000001"; -- 0
            when x"69"  => bbb := "00000000010"; -- 1
            when x"72"  => bbb := "00000000100"; -- 2
            when x"7A"  => bbb := "00000001000"; -- 3
            when x"6B"  => bbb := "00000010000"; -- 4
            when x"73"  => bbb := "00000100000"; -- 5
            when x"74"  => bbb := "00001000000"; -- 6
            when x"6C"  => bbb := "00010000000"; -- 7
            ------------------------------------
            when x"75"  => bbb := "00100000001"; -- 8
            when x"7D"  => bbb := "00100000010"; -- 9
            when x"71"  => bbb := "00101000000"; -- .
            ------------------------------------
            when x"05"  => bbb := "01000000001"; -- P
            when x"06"  => bbb := "01000000010"; -- Q
            when x"04"  => bbb := "01000000100"; -- R
            when x"0C"  => bbb := "01000001000"; -- S
            when x"03"  => bbb := "01000010000"; -- T
            ------------------------------------
            
            when x"7E"  => o_reset <= '1';

            when others => null;
         end case;
         if Key_Released = '0' then
				Matrix_0(to_integer(unsigned(aaa(10 downto 8)))) <=
					Matrix_0(to_integer(unsigned(aaa(10 downto 8)))) or
					std_logic_vector(unsigned(aaa(7 downto 0)));
				Matrix_1(to_integer(unsigned(bbb(10 downto 8)))) <=
					Matrix_1(to_integer(unsigned(bbb(10 downto 8)))) or
					std_logic_vector(unsigned(bbb(7 downto 0)));
         else
				Matrix_0(to_integer(unsigned(aaa(10 downto 8)))) <=
					Matrix_0(to_integer(unsigned(aaa(10 downto 8)))) and
					std_logic_vector(not unsigned(aaa(7 downto 0)));
				Matrix_1(to_integer(unsigned(bbb(10 downto 8)))) <=
					Matrix_1(to_integer(unsigned(bbb(10 downto 8)))) and
					std_logic_vector(not unsigned(bbb(7 downto 0)));
         end if;
         Key_Released <= '0';
         Extend_Key <= '0';
      end if;
    end if;
  end if;
end process;

--			if RX_ShiftReg = x"aa" and RX_Received = '1' then
--				Matrix <= (others => (others => '0'));
--			end if;

	g_out1 : for i in 0 to 7 generate
		Key_Data_0(i) <= (Matrix_0(0)(i) and Key_Addr(0)) or
                       (Matrix_0(1)(i) and Key_Addr(1)) or
                       (Matrix_0(2)(i) and Key_Addr(2)) or
                       (Matrix_0(3)(i) and Key_Addr(3)) or
                       (Matrix_0(4)(i) and Key_Addr(4)) or
                       (Matrix_0(5)(i) and Key_Addr(5)) or
                       (Matrix_0(6)(i) and Key_Addr(6)) or
                       (Matrix_0(7)(i) and Key_Addr(7));
	end generate;

	g_out2 : for i in 0 to 7 generate
		Key_Data_1(i) <= (Matrix_1(0)(i) and Key_Addr(0)) or
                       (Matrix_1(1)(i) and Key_Addr(1)) or
                       (Matrix_1(2)(i) and Key_Addr(2)) or
                       (Matrix_1(3)(i) and Key_Addr(3)) or
                       (Matrix_1(4)(i) and Key_Addr(4)) or
                       (Matrix_1(5)(i) and Key_Addr(5)) or
                       (Matrix_1(6)(i) and Key_Addr(6)) or
                       (Matrix_1(7)(i) and Key_Addr(7));
	end generate;
   
   Key_Data <= Key_Data_0 when Key_Addr(8) = '0' else Key_Data_1;

end Behavioral;

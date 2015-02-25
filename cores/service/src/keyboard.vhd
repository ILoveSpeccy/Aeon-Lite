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
      PS2_Clk    : in std_logic;
      PS2_Data   : in std_logic;
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
  signal	   Matrix : std_logic_vector(7 downto 0);

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
   variable aaa : std_logic_vector(7 downto 0);
begin
  if Reset='1' then
    Matrix <= (others => '0');
    Key_Released <= '0';
    Extend_Key <= '0';
  elsif rising_edge (Clk) then
    if Code_Readed = '1' then -- ScanCode is Readed
      if Scan_Code = x"F0" then -- Key is Released
         Key_Released <= '1';
      elsif Scan_Code = x"E0" then -- Extended Key Pressed
         Extend_Key <= '1';
      else -- Analyse
         aaa := (others=>'0');
         case Scan_Code is
            when x"76"  => aaa := "00000001"; -- ESC
            when x"5A"  => aaa := "00000010"; -- ENTER
            when x"75"  =>
               if Extend_Key = '1' then
                           aaa := "00000100"; -- UP
               end if;
            when x"6B"  =>
               if Extend_Key = '1' then
                           aaa := "00001000"; -- LEFT
               end if;
            when x"72"  =>
               if Extend_Key = '1' then
                           aaa := "00010000"; -- DOWN
               end if;
            when x"74"  =>
               if Extend_Key = '1' then
                           aaa := "00100000"; -- RIGHT
               end if;
            when others => null;
         end case;
         if Key_Released = '0' then
				Matrix <= Matrix or aaa;
         else
				Matrix <= Matrix and not aaa;
         end if;
         Key_Released <= '0';
         Extend_Key <= '0';
      end if;
    end if;
  end if;
end process;

Key_Data <= Matrix;

end Behavioral;

library IEEE;
use IEEE.numeric_std.all;
use IEEE.std_logic_1164.all;

entity keyboard is
   port(
      CLK         : in  std_logic;
      RESET       : in  std_logic;
      PS2_CLK     : in  std_logic;
      PS2_DATA    : in  std_logic;
      CONTROL     : out std_logic_vector(7 downto 0);
      KEYB_A      : in  std_logic_vector(7 downto 0);
      KEYB_A2     : in  std_logic_vector(3 downto 0);
      KEYB_D      : out std_logic_vector(7 downto 0);
      KEYB_D2     : out std_logic_vector(3 downto 0);
		VGA_SEL		: in  std_logic; -- 0 = Lvov, 1= MIPS
		KEYB_DATA   : out std_logic_vector(7 downto 0) -- MIPS
		);
end keyboard;

architecture Behavioral of keyboard is

   signal CODE    : std_logic_vector(7 downto 0);
   signal DONE    : std_logic;
   signal ERROR   : std_logic;
   signal KEY_REL : std_logic;
   signal KEY_EXT : std_logic;

   type   Matrix_Image is array (natural range <>) of std_logic_vector(7 downto 0);
   signal Matrix  : Matrix_Image(0 to 7);   

   type   Matrix2_Image is array (natural range <>) of std_logic_vector(3 downto 0);
   signal Matrix2  : Matrix2_Image(0 to 3);  
	
  
begin

   u_PS2 : entity work.ps2
   port map(
      CLK         => CLK,
      RESET       => not RESET,
      PS2_CLK     => PS2_CLK,
      PS2_DATA    => PS2_DATA,
      CODE        => CODE,
      DONE        => DONE,
      ERROR       => ERROR );

   DECODER : process(CLK)
      variable KEY : std_logic_vector(10 downto 0);
      variable KEY2 : std_logic_vector(5 downto 0);
   begin
      if rising_edge(CLK) then
         if RESET = '0' then
            Matrix <= (others => (others => '0'));
            KEY_REL <= '0';
            KEY_EXT <= '0';
            CONTROL <= "00000000";
				
         else
            CONTROL <= "00000000";
				
			 if VGA_SEL = '0' then

			   -- Lvov
            if DONE = '1' then                        -- ScanCode Readed
               if CODE = X"F0" then                      -- Key Released
                  KEY_REL <= '1';
               elsif CODE = X"E0" then                   -- Extended Key
                  KEY_EXT <= '1';
               else
                  KEY := (others => '0');
                  KEY2 := (others => '0');
                  case CODE is									-- PS2 Set 2 Scancodes

                     when x"1C"  => KEY := "11000010000"; -- A
                     when x"32"  => KEY := "01100000010"; -- B
                     when x"21"  => KEY := "10110000000"; -- C
                     when x"23"  => KEY := "01010000000"; -- D
                     when x"24"  => KEY := "10100010000"; -- E
                     when x"2B"  => KEY := "11010000000"; -- F
                     when x"34"  => KEY := "00100000001"; -- G
                     when x"33"  => KEY := "00101000000"; -- H
                     when x"43"  => KEY := "11100100000"; -- I
                     when x"3B"  => KEY := "10100000100"; -- J
                     when x"42"  => KEY := "10100100000"; -- K
                     when x"4B"  => KEY := "01000000100"; -- L
                     when x"3A"  => KEY := "11101000000"; -- M
                     when x"31"  => KEY := "10100001000"; -- N
                     when x"44"  => KEY := "01000000010"; -- O
                     when x"4D"  => KEY := "11000001000"; -- P
                     when x"15"  => KEY := "11100000010"; -- Q
                     when x"2D"  => KEY := "01000000001"; -- R
                     when x"1B"  => KEY := "11110000000"; -- S
                     when x"2C"  => KEY := "11100010000"; -- T
                     when x"3C"  => KEY := "10101000000"; -- U
                     when x"2A"  => KEY := "01001000000"; -- V
                     when x"1D"  => KEY := "11000100000"; -- W
                     when x"22"  => KEY := "11100001000"; -- X
                     when x"35"  => KEY := "11001000000"; -- Y
                     when x"1A"  => KEY := "00110000000"; -- Z
                     when x"16"  => KEY := "10010000000"; -- 1
                     when x"1E"  => KEY := "10001000000"; -- 2
                     when x"26"  => KEY := "10000100000"; -- 3
                     when x"25"  => KEY := "10000010000"; -- 4
                     when x"2E"  => KEY := "10000001000"; -- 5
                     when x"36"  => KEY := "00000000001"; -- 6
                     when x"3D"  => KEY := "00000000010"; -- 7
                     when x"3E"  => KEY := "00000000100"; -- 8
                     when x"46"  => KEY := "00010000000"; -- 9
                     when x"45"  => KEY := "00001000000"; -- 0

                     when x"29"  => KEY := "01100000001"; -- SPACE       
                     when x"66"  => KEY := "01000001000"; -- PACKSPACE     | ZB
                     when x"5A"  => KEY := "00100001000"; -- ENTER         | WK
                     when x"58"  => KEY := "11000000100"; -- CAPS LOCK     | SU
                     when x"12"  => 
                                 if KEY_EXT = '1' then    -- Print Screen
                                    if KEY_REL = '0' then -- Lvov Reset
                                       CONTROL(0) <= '1';
                                    end if;											
                                 else
                                    KEY := "11100000001"; -- LEFT SHIFT    | NR
                                 end if;		
				
                     when x"59"  => KEY := "01100001000"; -- RIGHT SHIFT   | WR
                     when x"0D"  => KEY := "00000010000"; -- TAB
                     when x"41"  => KEY := "01110000000"; -- ,
                     when x"49"  => KEY := "01000010000"; -- .
                     when x"4E"  => KEY := "00000100000"; -- -
                     when x"5D"  => KEY := "01000100000"; -- \
                     when x"55"  => KEY := "11100000100"; -- =             | ^
                     when x"0E"  => KEY := "00100100000"; -- '             | :
                     when x"54"  => KEY := "00100000010"; -- [
--                     when x"76"  => KEY := "10000000001"; --               | STR
--                     when x"76"  => KEY := "10000000001"; --               | @]
							when x"5B"  => KEY := "00100000100"; -- ]
                     when x"1f"  => 
                                 if KEY_EXT = '1' then		-- Left Win
                                    if KEY_REL = '0' then	
														CONTROL(2) <= '1'; -- Switch to Host Console
												end if;			                                    
                                 end if;	
                     when x"27"  => 
                                 if KEY_EXT = '1' then		-- Right Win
                                    if KEY_REL = '0' then	
														CONTROL(3) <= '1'; -- Switch to Lvov Screen
												end if;			                                    
                                 end if;												
							
                     when x"4C"  => KEY := "11000000001"; -- ;
                     when x"4A"  => KEY := "01101000000"; -- / 
                     when x"0B"  => KEY := "10000000010"; -- F6            | [G]
                     when x"83"  => KEY := "10000000100"; -- F7            | [B]

                     when x"11"  => 
                                 if KEY_EXT = '1' then
                                    KEY := "00100010000"; -- RIGHT ALT     | PS
                                 else
                                    KEY := "00000001000"; -- LEFT ALT      | GT
                                 end if;

                     when x"14"  => 
                                 if KEY_EXT = '1' then
                                    KEY := "01100100000"; -- RIGHT CTRL    | LAT
                                 else
                                    KEY := "11000000010"; -- LEFT CTRL     | RUS
                                 end if;

                     when x"76"  => KEY2 := "010010"; -- ESC      | F0
                     when x"05"  => KEY2 := "010100"; -- F1
                     when x"06"  => KEY2 := "011000"; -- F2
                     when x"04"  => KEY2 := "101000"; -- F3
                     when x"0C"  => KEY2 := "100100"; -- F4
                     when x"03"  => KEY2 := "100010"; -- F5
                     when x"0A"  => KEY2 := "001000"; -- F8       | [R]
                     when x"01"  => KEY2 := "000100"; -- F9       | DIN
                     when x"09"  => KEY2 := "000010"; -- F10      | CD
                     when x"78"  => KEY2 := "000001"; -- F11      | P4
                     when x"07"  => KEY2 := "010001"; -- F12      | P/D

                     when x"74"  => 
                                 if KEY_EXT = '1' then
                                    KEY2 := "110001"; -- RIGHT
                                 end if;
                     when x"75"  => 
                                 if KEY_EXT = '1' then
                                    KEY2 := "110010"; -- UP
                                 end if;
                     when x"6B"  => 
                                 if KEY_EXT = '1' then
                                    KEY2 := "110100"; -- LEFT
                                 end if;
                     when x"72"  => 
                                 if KEY_EXT = '1' then
                                    KEY2 := "111000"; -- DOWN
                                 end if;
                     when x"71"  => 
                                 if KEY_EXT = '1' then
                                    KEY2 := "100001"; -- DEL      | DIA
                                 end if;
                     when x"7e"  =>                   -- ScrollLock
                                 if KEY_REL = '0' then -- Reset to Standard Lvov ROM
                                    CONTROL(0) <= '1';
                                 end if;
                                 
                     when OTHERS => NULL;
                  end case;

                  if KEY_REL = '0' then
                     Matrix(to_integer(unsigned(KEY(10 downto 8)))) <=
                     Matrix(to_integer(unsigned(KEY(10 downto 8)))) or
                     std_logic_vector(unsigned(KEY(7 downto 0)));

                     Matrix2(to_integer(unsigned(KEY2(5 downto 4)))) <=
                     Matrix2(to_integer(unsigned(KEY2(5 downto 4)))) or
                     std_logic_vector(unsigned(KEY2(3 downto 0)));
                  else
                     Matrix(to_integer(unsigned(KEY(10 downto 8)))) <=
                     Matrix(to_integer(unsigned(KEY(10 downto 8)))) and
                     std_logic_vector(not unsigned(KEY(7 downto 0)));

                     Matrix2(to_integer(unsigned(KEY2(5 downto 4)))) <=
                     Matrix2(to_integer(unsigned(KEY2(5 downto 4)))) and
                     std_logic_vector(not unsigned(KEY2(3 downto 0)));
                  end if;
                  KEY_REL <= '0';
                  KEY_EXT <= '0';
               end if;
            end if;
				
			else
			-- MIPS
 			if DONE = '1' then
				if CODE = X"e0" then
					-- Extended key code follows
					KEY_EXT <= '1';
				elsif CODE = X"f0" then
					-- Release code follows
					KEY_REL <= '1';
				else
					if KEY_EXT = '1' then
						case CODE is					
							when X"00" => 									-- X"12"
												if KEY_REL = '0' then
													CONTROL(1) <= '1';	-- MIPS Reset														
												end if;							
							
							when X"27" =>	-- Escape For auto switch from File Manager to Console
												if KEY_REL = '1' then
													CONTROL(3) <= '1';		-- Switch to Lvov screen in left Win release
												end if;
							
							when others =>	null;
						end case;
					end if;
					
					-- Cancel extended/release flags for next time
					if KEY_REL = '1' then
						KEYB_DATA <= x"00";
						KEY_REL <= '0';
						KEY_EXT <= '0';
					else
							KEYB_DATA <= CODE;
					end if;
					
				end if;
			end if;

			
			end if;	
				
         end if;
      end if;
   end process;

	-- Lvov
   KEYB_D <= "11111111" and
				 ( not Matrix(0) or (7 downto 0 => KEYB_A(0)) ) and
             ( not Matrix(1) or (7 downto 0 => KEYB_A(1)) ) and
             ( not Matrix(2) or (7 downto 0 => KEYB_A(2)) ) and
             ( not Matrix(3) or (7 downto 0 => KEYB_A(3)) ) and
             ( not Matrix(4) or (7 downto 0 => KEYB_A(4)) ) and
             ( not Matrix(5) or (7 downto 0 => KEYB_A(5)) ) and
             ( not Matrix(6) or (7 downto 0 => KEYB_A(6)) ) and
             ( not Matrix(7) or (7 downto 0 => KEYB_A(7)) );

   KEYB_D2<= "1111" and
				 ( not Matrix2(0) or (3 downto 0 => KEYB_A2(0)) ) and
             ( not Matrix2(1) or (3 downto 0 => KEYB_A2(1)) ) and
             ( not Matrix2(2) or (3 downto 0 => KEYB_A2(2)) ) and
             ( not Matrix2(3) or (3 downto 0 => KEYB_A2(3)) );

			 
             
end Behavioral;

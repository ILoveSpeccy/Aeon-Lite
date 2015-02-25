---------------------------------------------------------------------------
-- (c) 2013 mark watson
-- I am happy for anyone to use this for non-commercial use.
-- If my vhdl files are used commercially or otherwise sold,
-- please contact me for explicit permission at scrameta (gmail).
-- This applies for source and binary form and derived works.
---------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;
	
ENTITY pokey_noise_filter IS
PORT 
( 
	NOISE_SELECT : IN STD_LOGIC_VECTOR(2 downto 0);
		
	PULSE_IN : IN STD_LOGIC;

	NOISE_4 : IN STD_LOGIC;
	NOISE_5 : IN STD_LOGIC;
	NOISE_LARGE : IN STD_LOGIC;
	
	PULSE_OUT : OUT STD_LOGIC
);
END pokey_noise_filter;

ARCHITECTURE vhdl OF pokey_noise_filter IS
	signal pulse_noise_a : std_logic;
	signal pulse_noise_b : std_logic;
BEGIN
	process(pulse_in, noise_4, noise_5, noise_large, pulse_noise_a, pulse_noise_b, noise_select)
	begin
		pulse_noise_a <= noise_large;
		pulse_noise_b <= noise_5 and pulse_in;
	
		if (NOISE_SELECT(1) = '1') then
			pulse_noise_a <= noise_4;
		end if;
	
		if (NOISE_SELECT(2) = '1') then
			pulse_noise_b <= pulse_in;
		end if;
		
		PULSE_OUT <= pulse_noise_a and pulse_noise_b;

		if (NOISE_SELECT(0) = '1') then
			PULSE_OUT <= pulse_noise_b;
		end if;		
	end process;
end vhdl;
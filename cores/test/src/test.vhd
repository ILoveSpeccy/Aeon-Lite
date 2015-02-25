library std;
use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity test is
   port (
      CLK: in std_logic;
      LEDG : out std_logic_vector(7 downto 0));
end test;

architecture rtl of test is

    signal TICK : unsigned(25 downto 0);
	 
begin
	  
process(CLK)
begin
   if rising_edge(CLK) then
      TICK <= TICK + 1;
   end if;
end process;

LEDG <= std_logic_vector(TICK(25 downto 18));

end rtl;




library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
 
entity D_Flip_Flop is
   port
   (
      rst : in std_logic;
      pre : in std_logic;
      ce  : in std_logic;
 
      d : in std_logic;
 
      q : out std_logic
   );
end entity D_Flip_Flop;
 
architecture Behavioral of D_Flip_Flop is
begin
   process (ce, rst, pre) is
   begin
      if rising_edge(ce) then  
         q <= d;
      end if;
      if (rst='1') then   
         q <= '0';
      elsif (pre='1') then
         q <= '1';
      end if;
   end process;
end architecture Behavioral;
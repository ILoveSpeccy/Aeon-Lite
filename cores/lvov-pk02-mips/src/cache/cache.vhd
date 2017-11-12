library ieee;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity cache is
   port 
   (	
      CLK   : in std_logic;
      AI    : in std_logic_vector(5 downto 0);
      DI    : in std_logic_vector(7 downto 0);
      WE    : in std_logic := '1';
      AO    : in std_logic_vector(5 downto 0);
      DO    : out std_logic_vector(7 downto 0);
      CACHE : in std_logic
   );
end cache;

architecture rtl of cache is
	
   signal CACHE_ACTIVE : std_logic := '0';
   subtype word_t is std_logic_vector(7 downto 0);
   type memory_t is array(0 to 127) of word_t;
   shared variable ram : memory_t;

begin

   process(CLK)
   begin
      if rising_edge(CLK) then
         if CACHE = '1' then
            CACHE_ACTIVE <= not CACHE_ACTIVE;
         end if;
      end if;
   end process;

   process(CLK)
   begin
      if rising_edge(CLK) then 
         if WE = '0' then
            ram(to_integer(unsigned(CACHE_ACTIVE & AI))) := DI;
         end if;
      end if;
   end process;
	
   process(CLK)
   begin
      if rising_edge(CLK) then
         DO <= ram(to_integer(unsigned(not CACHE_ACTIVE & AO)));
      end if;
   end process;

end rtl;

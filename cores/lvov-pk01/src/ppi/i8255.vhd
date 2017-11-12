library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL; 

entity i8255 is
port (
   CLK         : in  std_logic;
   RESET       : in  std_logic;
   
   A           : in  std_logic_vector(1 downto 0);
   DI          : in  std_logic_vector(7 downto 0);
   DO          : out std_logic_vector(7 downto 0);
   WR          : in  std_logic;

   PAI         : in  std_logic_vector(7 downto 0);
   PAO         : out std_logic_vector(7 downto 0);
   PBI         : in  std_logic_vector(7 downto 0);
   PBO         : out std_logic_vector(7 downto 0);
   PCI         : in  std_logic_vector(7 downto 0);
   PCO         : out std_logic_vector(7 downto 0));
end i8255;

architecture Behavioral of i8255 is

   signal PORTA      : std_logic_vector(7 downto 0);
   signal PORTB      : std_logic_vector(7 downto 0);
   signal PORTC      : std_logic_vector(7 downto 0);
   signal CONTROL    : std_logic_vector(7 downto 0);

begin

   DO <= PAI   when A = "00" and CONTROL(4) = '1' else
         PORTA when A = "00" and CONTROL(4) = '0' else
         PBI   when A = "01" and CONTROL(1) = '1' else
         PORTB when A = "01" and CONTROL(1) = '0' else
         PCI   when A = "10" and CONTROL(0) = '1' and CONTROL(3) = '1' else
         PORTC when A = "10" and CONTROL(0) = '0' and CONTROL(3) = '0' else
         PCI(7 downto 4) & PORTC(3 downto 0) when A = "10" and CONTROL(0) = '1' and CONTROL(3) = '0' else
         PORTC(7 downto 4) & PCI(3 downto 0) when A = "10" and CONTROL(0) = '0' and CONTROL(3) = '1' else
         CONTROL;

   PAO <= PORTA;
   PBO <= PORTB;
   PCO <= PORTC;

   registers_write : process(CLK)
   begin
      if rising_edge(CLK) then
         if RESET = '1' then
            CONTROL <= "10011011";
            PORTA <= "00000000";
            PORTB <= "00000000";
            PORTC <= "00000000";
         else
            if WR = '1' then
               case A is
                  when "00"   => PORTA    <= DI;
                  when "01"   => PORTB    <= DI;
                  when "10"   => PORTC    <= DI;
                  when others => CONTROL  <= DI;
                     if DI(7) = '0' then -- Bit set/reset
                        case DI(3 downto 1) is
                           when "000"  => PORTC(0) <= DI(0);
                           when "001"  => PORTC(1) <= DI(0);
                           when "010"  => PORTC(2) <= DI(0);
                           when "011"  => PORTC(3) <= DI(0);
                           when "100"  => PORTC(4) <= DI(0);
                           when "101"  => PORTC(5) <= DI(0);
                           when "110"  => PORTC(6) <= DI(0);
                           when others => PORTC(7) <= DI(0);
                        end case;
                     end if;
               end case;
            end if;
         end if;
      end if;
   end process;

end Behavioral; 

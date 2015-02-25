library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL; 

entity i8259 is
port (
   CLK      : in  std_logic;
   RESET    : in  std_logic;
   A0       : in  std_logic;
   WR       : in  std_logic;
   INTA     : in  std_logic;
   INTR     : out std_logic;
   IRQ      : in  std_logic_vector(7 downto 0);
   DI       : in  std_logic_vector(7 downto 0);
   DO       : out std_logic_vector(7 downto 0) );
end i8259;

architecture rtl of i8259 is

   signal IRR        : std_logic_vector(7 downto 0);
   signal IRQ_LAST   : std_logic_vector(7 downto 0);
   signal IMR        : std_logic_vector(7 downto 0);
   signal ISR        : std_logic_vector(7 downto 0);
   signal ICW1       : std_logic_vector(7 downto 0);
   signal ICW2       : std_logic_vector(7 downto 0);
   signal STATE      : unsigned(1 downto 0);
   signal IRQ_WORK   : std_logic_vector(2 downto 0);

   signal INIT       : std_logic;
   signal EXINTA     : std_logic;
   signal EXWR       : std_logic;

   alias  INTERVAL   : std_logic is ICW1(2);
   alias  ADDRH      : std_logic_vector(7 downto 0) is ICW2;
   alias  ADDRL      : std_logic_vector(2 downto 0) is ICW1(7 downto 5);

begin

   INTR <= '1' when ISR /= "00000000" or IRR /= "00000000" else '0';

   process(CLK)
   begin
      if rising_edge(CLK) then
         if RESET = '1' then

            IMR <= "11111111";
            ISR <= "00000000";
            IRR <= "00000000";
            IRQ_WORK <= "000";
            IRQ_LAST <= "00000000";
            DO <= "00000000";
            INIT <= '0';
            STATE <= "00";
            EXINTA <= '0';
            EXWR <= '0';

         else
            
            EXINTA <= INTA;
            EXWR <= WR;
            
            -- write to PIC registers
            if WR = '1' and EXWR = '0' then
               if INIT = '1' then -- Write to ICW2
                  ICW2 <= DI;
                  INIT <= '0';
               else
                  if A0 = '1' then -- Write to OCW1
                     IMR <= DI;
                  elsif DI(4) = '1' then -- Write to ICW1 (Reset and Init PIC)
                     IMR <= "11111111";
                     ISR <= "00000000";
                     IRR <= "00000000";
                     ICW1 <= DI;
                     INIT <= '1';
                  end if;
               end if;
            end if;

            -- Write new interrupts to IRR ---------------------
            IRQ_LAST <= IRQ;
            for POS in 0 to 7 loop
--               if IRQ_LAST(POS) = '0' and IRQ(POS) = '1' and IMR(POS) = '0' then  ################# ISR CHECK TOO?????????????
               if IRQ_LAST(POS) = '0' and IRQ(POS) = '1' and IMR(POS) = '0' and ISR(POS) = '0' then
                  IRR(POS) <= '1';
               end if;
            end loop;

            -- Check for interrupts in IRR, clear IRR and set ISR/IRQ_WORK (current interrupt number)
            if ISR = "00000000" then
               if    IRR(0) = '1' then IRQ_WORK <= "000"; IRR(0) <= '0'; ISR(0) <= '1';
               elsif IRR(1) = '1' then IRQ_WORK <= "001"; IRR(1) <= '0'; ISR(1) <= '1';
               elsif IRR(2) = '1' then IRQ_WORK <= "010"; IRR(2) <= '0'; ISR(2) <= '1';
               elsif IRR(3) = '1' then IRQ_WORK <= "011"; IRR(3) <= '0'; ISR(3) <= '1';
               elsif IRR(4) = '1' then IRQ_WORK <= "100"; IRR(4) <= '0'; ISR(4) <= '1';
               elsif IRR(5) = '1' then IRQ_WORK <= "101"; IRR(5) <= '0'; ISR(5) <= '1';
               elsif IRR(6) = '1' then IRQ_WORK <= "110"; IRR(6) <= '0'; ISR(6) <= '1';
               elsif IRR(7) = '1' then IRQ_WORK <= "111"; IRR(7) <= '0'; ISR(7) <= '1';
               end if;
            end if;

            -- State machine for interrupt acknowledge
            if INTA = '1' and EXINTA = '0' then
               case STATE is
                  when "00" =>
                     DO <= "11001101";
                     STATE <= "01";

                  when "01" =>
                     if INTERVAL = '0' then -- 8
                        DO <= ADDRL(2 downto 1) & IRQ_WORK & "000";
                     else  -- 4
                        DO <= ADDRL(2 downto 0) & IRQ_WORK & "00";
                     end if;
                     STATE <= "10";

                  when "10" =>
                     DO <= ADDRH;
                     ISR <= "00000000";
                     STATE <= "00";

                  when others =>
                     null;
               end case;
            end if;

         end if;
      end if;
   end process;

end rtl;

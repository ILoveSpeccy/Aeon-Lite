library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity spi_comm is  
port(   
   CLK      : in  std_logic;
   RESET    : in  std_logic;

   SPI_CS_A : in  std_logic;
   SPI_CS_D : in  std_logic;
   SPI_SCK  : in  std_logic;
   SPI_DI   : in  std_logic;
   SPI_DO   : out std_logic;

   ADDR_O   : out std_logic_vector(7 downto 0);
   ADDR_I   : in  std_logic_vector(7 downto 0);
   ADDR_REQ : out std_logic;
   ADDR_ACK : in  std_logic;

   DATA_O   : out std_logic_vector(7 downto 0);
   DATA_I   : in  std_logic_vector(7 downto 0);
   DATA_REQ : out std_logic;
   DATA_ACK : in  std_logic );
end spi_comm;

architecture RTL of spi_comm is

   signal ADDR_IN    : std_logic_vector (7 downto 0);
   signal DATA_IN    : std_logic_vector (7 downto 0);
   signal ADDR_OUT   : std_logic_vector (7 downto 0);
   signal DATA_OUT   : std_logic_vector (7 downto 0);
   signal CS_A_LAST  : std_logic_vector (1 downto 0);
   signal CS_D_LAST  : std_logic_vector (1 downto 0);

begin
   
   process (SPI_SCK)
   begin              
      if rising_edge(SPI_SCK) then
         if SPI_CS_A = '0' then
            ADDR_IN <= ADDR_IN (6 downto 0) & SPI_DI;
         elsif SPI_CS_D = '0' then  
            DATA_IN <= DATA_IN (6 downto 0) & SPI_DI;
         end if;
      end if;
   end process;
   
   process (CLK) is         
   begin                        
      if rising_edge(CLK) then
         if RESET = '1' then                        
            CS_A_LAST <= "11";
            CS_D_LAST <= "11"; 
            ADDR_REQ <= '0';
            DATA_REQ <= '0';
         else

            if ADDR_ACK = '1' then
               ADDR_REQ <= '0';
            end if;
            
            if DATA_ACK = '1' then
               DATA_REQ <= '0';
            end if;
            
            CS_A_LAST <= CS_A_LAST(0) & SPI_CS_A;
            CS_D_LAST <= CS_D_LAST(0) & SPI_CS_D;

            if CS_D_LAST = "01" then
               DATA_O <= DATA_IN; 
               DATA_REQ <= '1';
            end if;

            if CS_A_LAST = "01" then
               ADDR_O <= ADDR_IN;
               ADDR_REQ <= '1';
            end if;
         end if;
      end if;
   end process;

   process (SPI_SCK, ADDR_I, SPI_CS_A, DATA_I, SPI_CS_D)
   begin
      if SPI_CS_A = '1' then
         ADDR_OUT <= ADDR_I;
      elsif falling_edge(SPI_SCK) then
         ADDR_OUT <= ADDR_OUT(6 downto 0) & '0';
      end if;
      if SPI_CS_D = '1' then
         DATA_OUT <= DATA_I;
      elsif falling_edge(SPI_SCK) then
         DATA_OUT <= DATA_OUT(6 downto 0) & '0';
      end if;
   end process;

   SPI_DO <= ADDR_OUT(7) when SPI_CS_A = '0' else DATA_OUT(7) when SPI_CS_D = '0' else 'Z';

end RTL;

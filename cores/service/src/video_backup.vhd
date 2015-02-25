library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL; 

entity video is
port (
   CLK         : in  std_logic;
   VGA_CLK     : in  std_logic;
   RESET       : in  std_logic;

   VA          : in  std_logic_vector(11 downto 0);
   VDI         : in  std_logic_vector(7 downto 0);
   VWR         : in  std_logic;
   VATTR       : in  std_logic_vector(7 downto 0);
   
   VGA_R       : out std_logic_vector(3 downto 0);
   VGA_G       : out std_logic_vector(3 downto 0);
   VGA_B       : out std_logic_vector(3 downto 0);
   VGA_HSYNC   : out std_logic;
   VGA_VSYNC   : out std_logic
);
end video;

architecture Behavioral of video is

   signal V_COUNTER     : unsigned(9 downto 0);  -- Vertical Counter
   signal H_COUNTER     : unsigned(11 downto 0); -- Horizontal Counter
   signal PAPER         : std_logic;
   signal PAPER_ENA     : std_logic;
   
   signal PIX           : std_logic_vector(7 downto 0);
   signal PIX_LT        : std_logic_vector(7 downto 0);
   signal ATTR          : std_logic_vector(7 downto 0);
   signal ATTR_LT       : std_logic_vector(7 downto 0);

   constant HSIZE       : integer := 640; -- Paper H_size --1024
   constant VSIZE       : integer := 480; -- Paper V_size --768

   constant HFP         : integer := 16; --24;
   constant HS          : integer := 96; --136;
   constant HB          : integer := 48; --160;
   constant VFP         : integer := 19; --3;
   constant VS          : integer := 2;  --6;
   constant VB          : integer := 33; --29;

   signal FONTROM_A     : std_logic_vector(11 downto 0);
   signal FONTROM_DO    : std_logic_vector(7 downto 0);

   signal VRAM_WR       : std_logic_vector(0 downto 0);
   signal VRAM_RA       : std_logic_vector(11 downto 0);
   signal VRAM_RDO      : std_logic_vector(15 downto 0);
   
begin

--##########################
VRAM_WR <= "1" when VWR = '1' else "0";

u_FONTROM : entity work.fontrom
port map(
   clka                 => VGA_CLK,
   addra                => FONTROM_A,
   douta                => FONTROM_DO );

u_VRAM : entity work.vram
port map(
   clka           => CLK,
   wea            => VRAM_WR,
   addra          => VA,
   dina           => VATTR & VDI,
   clkb           => VGA_CLK,
   addrb          => VRAM_RA,
   doutb          => VRAM_RDO );
   
process (VGA_CLK)
begin
   if rising_edge(VGA_CLK) then
      if RESET = '1' then
         H_COUNTER <= (others=>'0');
         V_COUNTER <= (others=>'0');
      else
         H_COUNTER <= H_COUNTER + 1;
         if H_COUNTER = (HSIZE + HFP + HS + HB - 1) then
            H_COUNTER <= (others=>'0');
            V_COUNTER <= V_COUNTER + 1;
            if V_COUNTER = (VSIZE + VFP + VS + VB - 1) then
               V_COUNTER <= (others=>'0');
            end if;
         end if;
      end if;

      VGA_HSYNC <= '1';
      VGA_VSYNC <= '1';
      PAPER <= '0';

      if H_COUNTER >= (HSIZE + HFP) and H_COUNTER < (HSIZE + HFP + HS)then
         VGA_HSYNC <= '0';
      end if;
			
      if V_COUNTER >= (VSIZE + VFP) and V_COUNTER < (VSIZE + VFP + VS)then
         VGA_VSYNC <= '0';
      end if;

      if H_COUNTER < HSIZE and V_COUNTER < VSIZE then
         PAPER <= '1';
      end if;
      
   end if;
end process;
		
process (VGA_CLK)
begin
   if rising_edge(VGA_CLK) then
      case H_COUNTER(2 downto 0) is

         when "000" =>
            VRAM_RA <= std_logic_vector(V_COUNTER(8 downto 4)) & std_logic_vector(H_COUNTER(9 downto 3));

         when "010" => 
            FONTROM_A <= VRAM_RDO(7 downto 0) & std_logic_vector(V_COUNTER(3 downto 0));
            ATTR <= VRAM_RDO(15 downto 8);
                     
         when "100" => 
            PIX <= FONTROM_DO;
      
         when "111" => 
            PAPER_ENA <= PAPER;
            PIX_LT <= PIX;
            ATTR_LT <= ATTR;
                     
         when others => NULL;
      end case;
   end if;
end process;

process (VGA_CLK)
begin
   if rising_edge(VGA_CLK) then
      if PAPER_ENA = '1' then
         if PIX_LT(7 - to_integer(H_COUNTER(2 downto 0))) = '1' then 
            VGA_R(3) <= ATTR_LT(0);
            VGA_R(2) <= ATTR_LT(0) and ATTR_LT(3);
            VGA_R(1) <= ATTR_LT(0) and ATTR_LT(3);
            VGA_R(0) <= ATTR_LT(0);
            VGA_G(3) <= ATTR_LT(1);
            VGA_G(2) <= ATTR_LT(1) and ATTR_LT(3);
            VGA_G(1) <= ATTR_LT(1) and ATTR_LT(3);
            VGA_G(0) <= ATTR_LT(1);
            VGA_B(3) <= ATTR_LT(2);
            VGA_B(2) <= ATTR_LT(2) and ATTR_LT(3);
            VGA_B(1) <= ATTR_LT(2) and ATTR_LT(3);
            VGA_B(0) <= ATTR_LT(2);
         else
            VGA_R(3) <= ATTR_LT(4);
            VGA_R(2) <= ATTR_LT(4) and ATTR_LT(7);
            VGA_R(1) <= ATTR_LT(4) and ATTR_LT(7);
            VGA_R(0) <= ATTR_LT(4);
            VGA_G(3) <= ATTR_LT(5);
            VGA_G(2) <= ATTR_LT(5) and ATTR_LT(7);
            VGA_G(1) <= ATTR_LT(5) and ATTR_LT(7);
            VGA_G(0) <= ATTR_LT(5);
            VGA_B(3) <= ATTR_LT(6);
            VGA_B(2) <= ATTR_LT(6) and ATTR_LT(7);
            VGA_B(1) <= ATTR_LT(6) and ATTR_LT(7);
            VGA_B(0) <= ATTR_LT(6);
         end if;
      else
         VGA_G <= "0000";
         VGA_R <= "0000";
         VGA_B <= "0000";
      end if;
   end if;
end process;

--process (VGA_CLK)
--begin
--   if rising_edge(VGA_CLK) then
--      VGA_R <= "0000";
--      VGA_G <= "0000";
--      VGA_B <= "0000";
--      if PAPER = '1' then
--         VGA_B <= "1111";
--      end if;
--   end if;
--end process;

end Behavioral;

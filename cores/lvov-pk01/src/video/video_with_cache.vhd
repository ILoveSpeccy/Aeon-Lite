library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity video is
Port ( 
   CLK            : in  std_logic;                       -- Pixel clock 32.5MHz
   RESET          : in  std_logic;                       -- Reset (active low)
   CACHE_SWAP     : out std_logic;                       -- Active buffer
   CACHE_A        : out std_logic_vector(5 downto 0);    -- Cache address
   CACHE_D        : in  std_logic_vector(7 downto 0);    -- Cache data
   CURRENT_LINE   : out std_logic_vector(7 downto 0);    -- Current line to read in cache
   COLORS         : in  std_logic_vector(6 downto 0);
   R              : out std_logic_vector(3 downto 0);    -- Red
   G              : out std_logic_vector(3 downto 0);    -- Green
   B              : out std_logic_vector(3 downto 0);    -- Blue
   HSYNC          : out std_logic;                       -- Hor. sync
   VSYNC          : out std_logic                        -- Ver. sync
);
end video;

architecture BEHAVIORAL of video is

   -- VGA timing constants (XGA - 1024x768@60) (512x768@60)
   -- HOR
   constant HSIZE       : INTEGER := 512;                -- Visible area
   constant HFP         : INTEGER := 12;                 -- Front porch
   constant HS          : INTEGER := 68;                 -- HSync pulse
   constant HB          : INTEGER := 80;                 -- Back porch
   constant HOFFSET     : INTEGER := 0;                  -- HSync offset

   -- VER
   constant VSIZE       : INTEGER := 768;                -- Visible area
   constant VFP         : INTEGER := 3;                  -- Front porch
   constant VS          : INTEGER := 6;	               -- VSync pulse
   constant VB          : INTEGER := 29;                 -- Back porch     
   constant VOFFSET     : INTEGER := 0;                  -- VSync offset

   ------------------------------------------------------------

   signal H_COUNTER     : UNSIGNED(9 downto 0);          -- Horizontal Counter    
   signal V_COUNTER     : UNSIGNED(9 downto 0);          -- Vertical Counter
   signal THREE_ROW_CNT : UNSIGNED(1 downto 0);          -- 3 Row Counter
   signal ROW_COUNTER   : UNSIGNED(7 downto 0);          -- Korvet Row Counter  

   signal PAPER         : STD_LOGIC;                     -- Paper zone
   signal PAPER_L       : STD_LOGIC;                     -- Paper zone latched
   signal COLOR_R       : STD_LOGIC;
   signal COLOR_G       : STD_LOGIC;
   signal COLOR_B       : STD_LOGIC;
   
   signal PIX0          : STD_LOGIC_VECTOR(3 downto 0);
   signal PIX1          : STD_LOGIC_VECTOR(3 downto 0);

begin

   u_COLOR_MUX : entity work.clr_mux
   port map(
      color    => PIX1(3 - to_integer(H_COUNTER(2 downto 1))) & PIX0(3 - to_integer(H_COUNTER(2 downto 1))),
      portb    => COLORS,
      out_r    => COLOR_R, 
      out_g    => COLOR_G,
      out_b    => COLOR_B );

   CURRENT_LINE <= std_logic_vector(ROW_COUNTER);
      
   process (CLK)  -- H/V Counters
   begin
      if rising_edge(CLK) then
         if RESET = '0' then
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
      end if;
   end process;

   process (CLK)
   begin
      if rising_edge(CLK) then
         if RESET = '0' then
            THREE_ROW_CNT <= (others=>'0');
            ROW_COUNTER <= (others=>'0');
            CACHE_SWAP <= '0';
         else      
            CACHE_SWAP <= '0';
            if H_COUNTER = 544 then
               if V_COUNTER < 768 then
                  THREE_ROW_CNT <= THREE_ROW_CNT + 1;
                  if THREE_ROW_CNT = 2 then
                     THREE_ROW_CNT <= (others=>'0');
                     ROW_COUNTER <= ROW_COUNTER + 1;
                     CACHE_SWAP <= '1';
                  end if;
               else
                  ROW_COUNTER <= (others=>'0');
                  THREE_ROW_CNT <= (others=>'0');
               end if;
            end if;  
         end if;
      end if;
   end process;

   process (CLK)
   begin
      if rising_edge(CLK) then
         HSYNC <= '1';
         VSYNC <= '1';
         PAPER <= '0';

         if H_COUNTER >= (HSIZE + HOFFSET + HFP) and H_COUNTER < (HSIZE + HOFFSET + HFP + HS) then
            HSYNC <= '0';
         end if;
			
         if V_COUNTER >= (VSIZE + VOFFSET + VFP) and V_COUNTER < (VSIZE + VOFFSET + VFP + VS) then
            VSYNC <= '0';
         end if;
	
         if H_COUNTER < HSIZE and V_COUNTER < VSIZE then
            PAPER <= '1';
         end if;
      end if;
   end process;
   
   process (CLK)
   begin
      if rising_edge(CLK) then
         case H_COUNTER(2 downto 0) is

            when "001" => 
                           CACHE_A <= std_logic_vector(H_COUNTER(8 downto 3));
         
            when "111" => 
                           PIX0 <= CACHE_D(3 downto 0);
                           PIX1 <= CACHE_D(7 downto 4);
                           PAPER_L <= PAPER;

            when OTHERS => 
                           null;

         end case; 
      end if;
   end process;
  
   process (CLK)
   begin
      if rising_edge(CLK) then
         if PAPER_L = '1' then
            if THREE_ROW_CNT = "01" then
               R <= COLOR_R & COLOR_R & COLOR_R & COLOR_R;
               G <= COLOR_G & COLOR_G & COLOR_G & COLOR_G;
               B <= COLOR_B & COLOR_B & COLOR_B & COLOR_B;
            else
               R <= COLOR_R & "000";            
               G <= COLOR_G & "000";            
               B <= COLOR_B & "000";            
            end if;
         else
            R <= (others=>'0');
            G <= (others=>'0');
            B <= (others=>'0');
         end if;
      end if;
   end process;

end BEHAVIORAL;

-- XGA Signal 1024 x 768 @ 60 Hz timing

-- General timing
-- Screen refresh rate	60 Hz
-- Vertical refresh	   48.363095238095 kHz
-- Pixel freq.	         65.0 MHz

-- Horizontal timing (line)
-- Polarity of horizontal sync pulse is negative.
-- Scanline part	Pixels	Time [µs]
-- Visible area	1024	   15.753846153846
-- Front porch	   24	      0.36923076923077
-- Sync pulse	   136	   2.0923076923077
-- Back porch	   160	   2.4615384615385
-- Whole line  	1344	   20.676923076923

-- Vertical timing (frame)
-- Polarity of vertical sync pulse is negative.

-- Frame part	   Lines	   Time [ms]
-- Visible area	768	   15.879876923077
-- Front porch	   3	      0.062030769230769
-- Sync pulse	   6	      0.12406153846154
-- Back porch	   29	      0.59963076923077
-- Whole frame	   806	   16.6656

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity video is
Port ( 
   CLK            : in  std_logic;                       -- Pixel clock 32.5MHz
   RESET          : in  std_logic;                       -- Reset (active low)
   CACHE_SWAP     : out std_logic;                       -- Active buffer
   CACHE_A        : out std_logic_vector(5 downto 0);    -- Cache address
   CACHE_D        : in  std_logic_vector(31 downto 0);   -- Cache data
   CURRENT_LINE   : out std_logic_vector(7 downto 0);    -- Current line to read in cache
   LUT_A          : out std_logic_vector(3 downto 0);    -- LUT address
   LUT_D          : in  std_logic_vector(3 downto 0);    -- LUT data
   VBLANK         : out std_logic;
   R              : out std_logic_vector(3 downto 0);    -- Red
   G              : out std_logic_vector(3 downto 0);    -- Green
   B              : out std_logic_vector(3 downto 0);    -- Blue
   HSYNC          : out std_logic;                       -- Hor. sync
   VSYNC          : out std_logic                        -- Ver. sync
);
end video;

architecture BEHAVIORAL of video is

   constant H_TICKS        : natural := 679;
   constant V_TICKS        : natural := 805;
   constant H_SIZE         : natural := 512;
   constant V_SIZE         : natural := 768;
   constant HSYNC_B        : natural := 531;
   constant HSYNC_E        : natural := 600;
   constant VSYNC_B        : natural := 770;
   constant VSYNC_E        : natural := 800;

   ------------------------------------------------------------

   signal H_COUNTER        : unsigned(9 downto 0);          -- Horizontal Counter    
   signal V_COUNTER        : unsigned(9 downto 0);          -- Vertical Counter
   signal THREE_TICK       : unsigned(1 downto 0);          -- Three Rows Tick
   signal SCANLINE         : unsigned(7 downto 0);          -- Current Scanline for Video Output
   signal FLIP_CACHE       : std_logic;
   signal PAPER            : std_logic;                     -- Paper Area
   signal PAPER_L          : std_logic;                     -- Paper zone
   signal PAPER_LL         : std_logic;                     -- Paper zone
   
   signal VBLANK_TICK      : unsigned(9 downto 0);
   
   signal PIX_R            : std_logic_vector(7 downto 0);  -- Red byte latch
   signal PIX_G            : std_logic_vector(7 downto 0);  -- Green byte latch
   signal PIX_B            : std_logic_vector(7 downto 0);  -- Blue byte latch
   signal PIX_C            : std_logic_vector(7 downto 0);  -- Char byte latch

   type palette_t is array(0 to 15) of std_logic_vector(23 downto 0);
   constant color_palette : palette_t := (   "000000000000000000000000", -- 0
                                             "000000000110000000001010", -- 1 
                                             "000001100000000010100000", -- 2
                                             "000001100110000010101010", -- 3
                                             "011000000000101000000000", -- 4
                                             "011000000110101000001010", -- 5
                                             "011001100000101010100000", -- 6
                                             "011001100110101010101010", -- 7
                                             "001100110011010101010101", -- 8
                                             "001100111001010101011111", -- 9
                                             "001110010011010111110101", -- 10
                                             "001110011001010111111111", -- 11
                                             "100100110011111101010101", -- 12
                                             "100100111001111101011111", -- 13
                                             "100110010011111111110101", -- 14
                                             "100110011001111111111111");-- 15

begin
   
   CURRENT_LINE <= std_logic_vector(SCANLINE);
   CACHE_SWAP <= FLIP_CACHE;
   
   process(CLK)
   begin
      if rising_edge(CLK) then
         if RESET = '1' then

            H_COUNTER <= (others => '0');
            V_COUNTER <= (others => '0');
            THREE_TICK <= "00";
            SCANLINE <= "00000001";
            FLIP_CACHE <= '0';
            PAPER <= '0';
            HSYNC <= '1';
            VSYNC <= '1'; 
            VBLANK <= '0';
            VBLANK_TICK <= (others => '0');

         else

            PAPER <= '0';
            HSYNC <= '1';
            VSYNC <= '1'; 
            VBLANK <= '0';
            FLIP_CACHE <= '0';
            H_COUNTER <= H_COUNTER + 1;

            if H_COUNTER = H_TICKS then
               H_COUNTER <= (others => '0');
               V_COUNTER <= V_COUNTER + 1;
               if V_COUNTER = V_TICKS then
                  V_COUNTER <= (others => '0');
               end if;
               VBLANK_TICK <= VBLANK_TICK + 1;
               if VBLANK_TICK = 994 then
                  VBLANK_TICK <= (others => '0');
               end if;
            end if;

            if H_COUNTER < H_SIZE and V_COUNTER < V_SIZE then
               PAPER <= '1';
            end if;

            if H_COUNTER > HSYNC_B and H_COUNTER < HSYNC_E then
               HSYNC <= '0';
            end if;
            

            if VBLANK_TICK < 6 then
               VBLANK <= '1';
            end if; 

            if V_COUNTER > VSYNC_B and V_COUNTER < VSYNC_E then
               VSYNC <= '0';
            end if; 

            if H_COUNTER = H_TICKS - 16 and V_COUNTER < V_SIZE then
               THREE_TICK <= THREE_TICK + 1;
               if THREE_TICK = 2 then
                  THREE_TICK <= "00";
                  SCANLINE <= SCANLINE + 1;
                  FLIP_CACHE <= '1';
               end if;
            end if;

         end if;
      end if;
   end process;
 
   process (CLK)
   begin
      if rising_edge(CLK) then
         case H_COUNTER(2 downto 0) is
            when "001" => CACHE_A <= std_logic_vector(H_COUNTER(8 downto 3));

            when "111" => 
                          PIX_C <= CACHE_D(31 downto 24);
                          PIX_R <= CACHE_D(23 downto 16);
                          PIX_G <= CACHE_D(15 downto 8);
                          PIX_B <= CACHE_D(7 downto 0);
                          PAPER_L <= PAPER;

            when others => null;
         end case; 
      end if;
   end process;

   process (CLK)
   begin
      if rising_edge(CLK) then
         LUT_A <= PIX_C(7 - to_integer(H_COUNTER(2 downto 0))) &
                  PIX_R(7 - to_integer(H_COUNTER(2 downto 0))) &
                  PIX_G(7 - to_integer(H_COUNTER(2 downto 0))) &
                  PIX_B(7 - to_integer(H_COUNTER(2 downto 0)));
         PAPER_LL <= PAPER_L;
      end if;
   end process;
 
   process (CLK)
   begin
      if rising_edge(CLK) then
         if PAPER_LL = '1' then
            if THREE_TICK = "01" then
               R <= color_palette(to_integer(unsigned(LUT_D)))(11 downto 8);
               G <= color_palette(to_integer(unsigned(LUT_D)))(7  downto 4);
               B <= color_palette(to_integer(unsigned(LUT_D)))(3  downto 0);
            else
               R <= color_palette(to_integer(unsigned(LUT_D)))(23 downto 20);
               G <= color_palette(to_integer(unsigned(LUT_D)))(19 downto 16);
               B <= color_palette(to_integer(unsigned(LUT_D)))(15 downto 12);
            end if;
         else
            R <= (others=>'0');
            G <= (others=>'0');
            B <= (others=>'0');
         end if;
      end if;
   end process;

end BEHAVIORAL;

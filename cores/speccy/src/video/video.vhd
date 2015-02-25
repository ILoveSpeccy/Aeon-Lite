library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity video is
Port ( 
   VGA_CLK     : in  std_logic;
   RESET       : in  std_logic;
   BORDERCOLOR : in  std_logic_vector(2 downto 0);
   INT         : out std_logic;
   VA          : out std_logic_vector(12 downto 0);
   VD          : in  std_logic_vector(7 downto 0);
   VGA_R       : out std_logic_vector(3 downto 0);
   VGA_G       : out std_logic_vector(3 downto 0);
   VGA_B       : out std_logic_vector(3 downto 0);
   VGA_HSYNC   : out std_logic;
   VGA_VSYNC   : out std_logic );
end video;

architecture BEHAVIORAL of video is

   constant HSCREENSIZE       : integer := 640;          -- Hor. visible area (border) size
   constant VSCREENSIZE       : integer := 480;          -- Vert. visible area (border) size

   constant HPAPERSIZE        : integer := 512;          -- Hor. paper area size
   constant VPAPERSIZE        : integer := 384;          -- Vert. paper area size

   constant RIGHTBORDERSIZE   : integer := 64;
   constant BOTTOMBORDERSIZE  : integer := 48;

   constant HBACKPORCH        : integer := 48;
   constant HSYNCLENGTH       : integer := 96;
   constant HFRONTPORCH       : integer := 16;

   constant VBACKPORCH        : integer := 33;
   constant VSYNCLENGTH       : integer := 2;
   constant VFRONTPORCH       : integer := 10;

   constant HPIXELSIZE        : integer := 2;
   constant VPIXELSIZE        : integer := 2;

   signal HCOUNTER            : unsigned(9 downto 0);    -- Main hor. counter
   signal VCOUNTER            : unsigned(9 downto 0);    -- Main vert. counter

   signal HPSCOUNTER          : unsigned(1 downto 0);    -- Hor. pixel size counter
   signal VPSCOUNTER          : unsigned(1 downto 0);    -- Vert. pixel size counter

   signal HPIXELCOUNTER       : unsigned(7 downto 0);
   signal VPIXELCOUNTER       : unsigned(7 downto 0);

   signal PIX                 : std_logic_vector(7 downto 0);  -- Pixel data
   signal ATTR                : std_logic_vector(7 downto 0);  -- Attribute data
   signal PAPER               : std_logic;                     -- Paper area
   signal BORDER              : std_logic;                     -- Visible area (border)

   signal LPIX                : std_logic_vector(7 downto 0);
   signal LATTR               : std_logic_vector(7 downto 0);
   signal LPAPER              : std_logic;
   signal LBORDER             : std_logic;

   signal FLASHCOUNTER        : unsigned(6 downto 0);
   signal FLASH               : std_logic;

   signal INTCOUNTER          : unsigned(9 downto 0);

begin

main_counter : process (VGA_CLK, RESET)
begin
   if RESET = '1' then
      HCOUNTER <= (others => '0');
      VCOUNTER <= (others => '0');
      HPSCOUNTER <= (others => '0');
      VPSCOUNTER <= (others => '0');
      HPIXELCOUNTER <= (others => '0');
      VPIXELCOUNTER <= (others => '0');
      FLASHCOUNTER <= (others => '0');
      INTCOUNTER <= (others => '0');
      INT <= '1';
   elsif rising_edge(VGA_CLK) then
      INT <= '1';
      if INTCOUNTER = 1 and HCOUNTER < 256 then
         INT <= '0';
      end if;
      if HCOUNTER < HSCREENSIZE + HBACKPORCH + HSYNCLENGTH + HFRONTPORCH - 1 then
         HCOUNTER <= HCOUNTER + 1;
         HPSCOUNTER <= HPSCOUNTER + 1;
         if (HPSCOUNTER = HPIXELSIZE - 1) then
            HPSCOUNTER <= (others => '0');
            HPIXELCOUNTER <= HPIXELCOUNTER + 1;
         end if;
      else
         HCOUNTER <= (others => '0');
         HPSCOUNTER <= (others => '0');
         HPIXELCOUNTER <= (others => '0');
         
         INTCOUNTER <= INTCOUNTER + 1;
         if INTCOUNTER = 628 then
            INTCOUNTER <= (others => '0');
         end if;

         if VCOUNTER < VSCREENSIZE + VBACKPORCH + VSYNCLENGTH + VFRONTPORCH - 1 then
            VCOUNTER <= VCOUNTER + 1;
            VPSCOUNTER <= VPSCOUNTER + 1;
            if (VPSCOUNTER = VPIXELSIZE - 1) then
               VPSCOUNTER <= (others => '0');
               VPIXELCOUNTER <= VPIXELCOUNTER + 1;
            end if;
         else
            VCOUNTER <= (others => '0');
            VPSCOUNTER <= (others => '0');
            VPIXELCOUNTER <= (others => '0');
            FLASHCOUNTER <= FLASHCOUNTER + 1;
         end if;
      end if;
   end if;
end process;

FLASH <= std_logic(FLASHCOUNTER(6));

make_sync : process (VGA_CLK)
begin
   if rising_edge(VGA_CLK) then
      VGA_HSYNC <= '1';
      VGA_VSYNC <= '1';
      if HCOUNTER > HPAPERSIZE + RIGHTBORDERSIZE + HBACKPORCH - 1 
      and HCOUNTER < HPAPERSIZE + RIGHTBORDERSIZE + HBACKPORCH + HSYNCLENGTH then
         VGA_HSYNC <= '0';
      end if;
      if VCOUNTER > VPAPERSIZE + BOTTOMBORDERSIZE + VBACKPORCH - 1 
      and VCOUNTER < VPAPERSIZE + BOTTOMBORDERSIZE + VBACKPORCH + VSYNCLENGTH then
         VGA_VSYNC <= '0';
      end if;
   end if;
end process;

make_paper : process (VGA_CLK)
begin
   if rising_edge(VGA_CLK) then
      PAPER <= '0';
      if HCOUNTER < HPAPERSIZE - 1 and VCOUNTER < VPAPERSIZE then
         PAPER <= '1';
      end if;
   end if;
end process;

make_border : process (VGA_CLK)
begin
   if rising_edge(VGA_CLK) then
      BORDER <= '1';
      if (HCOUNTER > HPAPERSIZE + RIGHTBORDERSIZE - 1 
      and HCOUNTER < HPAPERSIZE + RIGHTBORDERSIZE + HBACKPORCH + HSYNCLENGTH + HFRONTPORCH) 
      or (VCOUNTER > VPAPERSIZE + BOTTOMBORDERSIZE - 1 
      and VCOUNTER < VPAPERSIZE + BOTTOMBORDERSIZE + VBACKPORCH + VSYNCLENGTH + VFRONTPORCH) then
         BORDER <= '0';
      end if;
      if HCOUNTER > HPAPERSIZE + RIGHTBORDERSIZE + HBACKPORCH + HSYNCLENGTH + HFRONTPORCH - 1 then
         if VCOUNTER = 431 then
            BORDER <= '0';
         elsif VCOUNTER = 476 then
            BORDER <= '1';
         end if;
      end if;
   end if;
end process;

latch_data : process (VGA_CLK)
begin
   if rising_edge(VGA_CLK) and HPSCOUNTER = HPIXELSIZE - 1 then
      case HPIXELCOUNTER(2 downto 0) is
         when "001" => VA <= std_logic_vector(VPIXELCOUNTER(7 downto 6)) & std_logic_vector(VPIXELCOUNTER(2 downto 0)) & 
                             std_logic_vector(VPIXELCOUNTER(5 downto 3)) & std_logic_vector(HPIXELCOUNTER(7 downto 3));
         when "011" => PIX <= VD;
         when "100" => VA <= "110" & std_logic_vector(VPIXELCOUNTER(7 downto 3)) & std_logic_vector(HPIXELCOUNTER(7 downto 3));
         when "110" => ATTR <= VD;
         when "111" => LPIX <= PIX;
                       LATTR <= ATTR;
                       LPAPER <= PAPER;
                       LBORDER <= BORDER;
         when others => null;
      end case;
   end if;
end process;

process (VGA_CLK)
begin
   if rising_edge(VGA_CLK) then
      if LPAPER = '1' then
         if (LPIX(7 - to_integer(HPIXELCOUNTER(2 downto 0))) xor (FLASH and LATTR(7))) = '1' then
            VGA_G(0) <= LATTR (2);
            VGA_G(1) <= LATTR (2);
            VGA_G(2) <= LATTR (2) and LATTR(6);
            VGA_G(3) <= LATTR (2);
            VGA_R(0) <= LATTR (1);
            VGA_R(1) <= LATTR (1);
            VGA_R(2) <= LATTR (1) and LATTR(6);
            VGA_R(3) <= LATTR (1);
            VGA_B(0) <= LATTR (0);
            VGA_B(1) <= LATTR (0);
            VGA_B(2) <= LATTR (0) and LATTR(6);
            VGA_B(3) <= LATTR (0);
         else
            VGA_G(0) <= LATTR (5);
            VGA_G(1) <= LATTR (5);
            VGA_G(2) <= LATTR (5) and LATTR(6);
            VGA_G(3) <= LATTR (5);
            VGA_R(0) <= LATTR (4);
            VGA_R(1) <= LATTR (4);
            VGA_R(2) <= LATTR (4) and LATTR(6);
            VGA_R(3) <= LATTR (4);
            VGA_B(0) <= LATTR (3);
            VGA_B(1) <= LATTR (3);
            VGA_B(2) <= LATTR (3) and LATTR(6);
            VGA_B(3) <= LATTR (3);
         end if;
      elsif LBORDER = '1' then
         VGA_G(0) <= BORDERCOLOR (2);
         VGA_G(1) <= BORDERCOLOR (2);
         VGA_G(2) <= '0';
         VGA_G(3) <= BORDERCOLOR (2);
         VGA_R(0) <= BORDERCOLOR (1);
         VGA_R(1) <= BORDERCOLOR (1);
         VGA_R(2) <= '0';
         VGA_R(3) <= BORDERCOLOR (1);
         VGA_B(0) <= BORDERCOLOR (0);
         VGA_B(1) <= BORDERCOLOR (0);
         VGA_B(2) <= '0';
         VGA_B(3) <= BORDERCOLOR (0);
      else
         VGA_G <= "0000";
         VGA_R <= "0000";
         VGA_B <= "0000";
      end if;
   end if;
end process;

end BEHAVIORAL;

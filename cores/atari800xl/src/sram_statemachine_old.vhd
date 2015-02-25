---------------------------------------------------------------------------
-- SRAM memory controller
---------------------------------------------------------------------------
-- This file is a part of "Aeon Lite" project
-- Dmitriy Schapotschkin aka ILoveSpeccy '2014
-- ilovespeccy@speccyland.net
-- Project homepage: www.speccyland.net
---------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY sram_statemachine IS
PORT ( 
   CLK               : in     std_logic;
   RESET_N           : in     std_logic;
	
   DATA_IN           : in     std_logic_vector(31 downto 0);
   ADDRESS_IN        : in     std_logic_vector(22 downto 0);
   WRITE_EN          : in     std_logic;
   REQUEST           : in     std_logic;
   BYTE_ACCESS       : in     std_logic; -- ldqm/udqm set based on a(0) - if 0=0111, if 1=1011. Data fields valid:7 downto 0.
   WORD_ACCESS       : in     std_logic; -- ldqm/udqm set based on a(0) - if 0=0011, if 1=1001. Data fields valid:15 downto 0.
   LONGWORD_ACCESS   : in     std_logic; -- a(0) ignored. lqdm/udqm mask is 0000
   COMPLETE          : out    std_logic;
   DATA_OUT          : out    std_logic_vector(31 downto 0);

   SRAM_ADDR         : out    std_logic_vector(17 downto 0);
   SRAM_DQ           : inout  std_logic_vector(15 downto 0);
   SRAM_WE_N         : out    std_logic;
   SRAM_OE_N         : out    std_logic;
   SRAM_UB_N         : out    std_logic;
   SRAM_LB_N         : out    std_logic;
   SRAM_CE0_N        : out    std_logic;
   SRAM_CE1_N        : out    std_logic );
END sram_statemachine;

ARCHITECTURE vhdl OF sram_statemachine IS

	function REPEAT(N: natural; B: std_logic) 
      return std_logic_vector
	is
      variable RESULT: std_logic_vector(1 to N);
	begin
      for i in 1 to N loop
         RESULT(i) := B;
      end loop;
      return RESULT;
	end;
   
   signal SRAM_DI       : std_logic_vector(15 downto 0);
   signal SRAM_DO       : std_logic_vector(15 downto 0);
   signal DATA_OUT_REG  : std_logic_vector(31 downto 0);
   signal MASK          : std_logic_vector(3 downto 0);
   
   type STATES is (ST_IDLE, ST_READ0, ST_READ1, ST_READ2, ST_WRITE0, ST_WRITE1, ST_WRITE2);
   signal STATE : STATES;

BEGIN

   SRAM_DQ <= SRAM_DI;
   SRAM_DO <= SRAM_DQ;

   DATA_OUT <= DATA_OUT_REG;
   
   COMPLETE <= '1' when STATE = ST_IDLE and REQUEST = '0' else '0';

   process(CLK, RESET_N)
   begin
      if RESET_N = '0' then
         SRAM_DI <= (OTHERS=>'Z');
         SRAM_WE_N <= '1';
         SRAM_OE_N <= '1';
         SRAM_CE0_N <= '1';
         SRAM_CE1_N <= '1';
         SRAM_LB_N <= '1';
         SRAM_UB_N <= '1';
         STATE <= ST_IDLE;
      else
         if rising_edge(CLK) then
         
            case STATE is
               when ST_IDLE =>

                  SRAM_DI <= (OTHERS=>'Z');
                  SRAM_WE_N <= '1';
                  SRAM_OE_N <= '1';
                  SRAM_LB_N <= '1';
                  SRAM_UB_N <= '1';

                  if REQUEST = '1' then
                  
                     MASK(0) <= (BYTE_ACCESS or WORD_ACCESS) and ADDRESS_IN(0);      -- masked on misaligned byte or word
                     MASK(1) <= (BYTE_ACCESS) and not(address_in(0));                -- masked on aligned byte only
                     MASK(2) <= BYTE_ACCESS or (WORD_ACCESS and not(ADDRESS_IN(0))); -- masked on aligned word or byte
                     MASK(3) <= not(LONGWORD_ACCESS);                                -- masked for everything except long word access                     

                     SRAM_ADDR <= ADDRESS_IN(18 downto 1);
                     
                     SRAM_CE0_N <= ADDRESS_IN(19);
                     SRAM_CE1_N <= not ADDRESS_IN(19);

                     if WRITE_EN = '1' then
                        STATE <= ST_WRITE0;
                     else
                        STATE <= ST_READ0;
                     end if;
                  end if;  

               when ST_WRITE0 =>
                  SRAM_LB_N <= MASK(0);
                  SRAM_UB_N <= MASK(1);
                  SRAM_DI(7 downto 0) <= DATA_IN(7 downto 0);
                  SRAM_DI(15 downto 8) <= (DATA_IN(15 downto 8) and not(repeat(8,MASK(0)))) or (DATA_IN(7 downto 0) and repeat(8,MASK(0)));
                  SRAM_WE_N <= '0';
                  STATE <= ST_WRITE1;             

               when ST_WRITE1 =>
                  SRAM_WE_N <= '1';
                  STATE <= ST_WRITE2;             

               when ST_WRITE2 =>
                  SRAM_ADDR <= std_logic_vector(unsigned(ADDRESS_IN(18 downto 1)) + 1);
                  SRAM_DI(7 downto 0) <= (DATA_IN(23 downto 16) and not(repeat(8,MASK(0)))) or (DATA_IN(15 downto 8) and repeat(8,MASK(0)));
                  SRAM_DI(15 downto 8) <= DATA_IN(31 downto 24);
                  SRAM_LB_N <= MASK(2);
                  SRAM_UB_N <= MASK(3);
                  SRAM_WE_N <= '0';
                  STATE <= ST_IDLE;
   
               when ST_READ0 =>
                  SRAM_LB_N <= MASK(0);
                  SRAM_UB_N <= MASK(1);
                  SRAM_OE_N <= '0';
                  STATE <= ST_READ1;

               when ST_READ1 =>
                  DATA_OUT_REG(7 downto 0) <= (SRAM_DO(7 downto 0) and not(repeat(8,MASK(0)))) or (SRAM_DO(15 downto 8) and repeat(8,MASK(0)));
                  DATA_OUT_REG(15 downto 8) <= SRAM_DO(15 downto 8); 
                  SRAM_ADDR <= std_logic_vector(unsigned(ADDRESS_IN(18 downto 1)) + 1);
                  SRAM_LB_N <= MASK(2);
                  SRAM_UB_N <= MASK(3);
                  STATE <= ST_READ2;

               when ST_READ2 =>
                  DATA_OUT_REG(15 downto 8 ) <= (SRAM_DO(7 downto 0) and repeat(8,MASK(0))) or (DATA_OUT_REG(15 downto 8) and not(repeat(8,MASK(0))));
                  DATA_OUT_REG(31 downto 16) <= SRAM_DO(15 downto 0);
                  STATE <= ST_IDLE;

               when OTHERS =>
                  STATE <= ST_IDLE;
               
            end case;
         end if;
      end if;
   end process;

END vhdl;

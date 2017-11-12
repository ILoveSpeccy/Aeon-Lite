library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.ALL;  

entity dp_sram is                    
	port (
		-- CLOCK
		CLK				: in std_logic;	-- 32MHz
		nRESET			: in std_logic;
		
		-- PORT A
		DI_A				: in  STD_LOGIC_VECTOR(7 downto 0);
		DO_A				: inout STD_LOGIC_VECTOR(7 downto 0);
		ADDR_A			: in  STD_LOGIC_VECTOR(17 downto 0);
		nWE_A				: in  std_logic;
		nCS_A				: in  std_logic;
		nOE_A				: in  std_logic;
		nWAIT_A			: out std_logic;
		
		-- PORT B
		DI_B				: in  STD_LOGIC_VECTOR(31 downto 0);
		DO_B				: inout STD_LOGIC_VECTOR(31 downto 0);
		ADDR_B			: in  STD_LOGIC_VECTOR(31 downto 2);
		nWE_B				: in  std_logic;
		nCS_B				: in  std_logic;
		nOE_B				: in  std_logic;
		WAIT_B			: out std_logic;
		MEM_MASK_B		: in STD_LOGIC_VECTOR(3 downto 0);
		
		-- SRAM
		SRAM_A			: out    std_logic_vector(17 downto 0);
		SRAM_D			: inout  std_logic_vector(15 downto 0);
		SRAM_WE			: out    std_logic;
		SRAM_OE			: out    std_logic;
		SRAM_CE0			: out    std_logic;
		SRAM_CE1			: out    std_logic;		
		SRAM_LB			: out    std_logic;
		SRAM_UB			: out    std_logic	
);		
				
end dp_sram;

architecture dp_sram_arch of dp_sram is

   --"00" = big_endian; "11" = little_endian
   constant ENDIAN_MODE   : std_logic_vector(1 downto 0) := "11";
	
   -- FSM States
   type STATE_TYPE is ( IDLE,
	
								ST_READ1_A,
								ST_WRITE1_A,
								
								ST_READ1_B, ST_READ2_B,
								ST_WRITE1_B, ST_WRITE2_B, ST_WRITE3_B );
								
   signal STATE : STATE_TYPE := IDLE;

	signal A_LOCK		: std_logic;	
	signal B_LOCK		: std_logic;
	signal nWAIT_B		: std_logic;
	signal nCS_B_L		: std_logic;
	signal nWE_B_L		: std_logic;
	signal MEM_MASK_B_L	: STD_LOGIC_VECTOR(3 downto 0);
	signal DI_B_L				: STD_LOGIC_VECTOR(31 downto 0);
	signal ADDR_B_L			: STD_LOGIC_VECTOR(31 downto 2);
	
begin

nWE_B_L			<= nWE_B			when falling_edge (nCS_B);
MEM_MASK_B_L	<= MEM_MASK_B	when falling_edge (nCS_B);
DI_B_L			<= DI_B			when falling_edge (nCS_B);
ADDR_B_L			<= ADDR_B		when falling_edge (nCS_B);

WAIT_B			<= (not nCS_B) or (not nWAIT_B);

CS_B_LATCH: entity work.D_Flip_Flop
PORT MAP(
		rst => not nCS_B,
		pre => not nRESET,
		ce  => nWAIT_B,
		d   => '1',
		q   => nCS_B_L
);



process (CLK)
begin
      if rising_edge(CLK) then
         if nRESET = '0' then
				STATE 	<= IDLE;
				nWAIT_A	<= '1';
				nWAIT_B	<= '1';
				A_LOCK	<= '0';			
				B_LOCK	<= '0';
				SRAM_WE  <= '1';
            SRAM_OE  <= '1';
				SRAM_CE0 <= '1';								
				SRAM_CE1 <= '1';
				SRAM_LB	<= '1';
				SRAM_UB	<= '1';
				SRAM_D	<= (OTHERS=>'Z');
			else
				if nCS_A = '1' then
					A_LOCK <= '0';
				end if;
				if nCS_B = '1' then
					B_LOCK <= '0';
				end if;

				if A_LOCK = '0' and nCS_A = '0' and STATE /= IDLE then
					nWAIT_A <= '0';
				end if;
				if B_LOCK = '0' and nCS_B_L = '0' and (STATE /= IDLE or (STATE = IDLE and nCS_A = '0') ) then
					nWAIT_B <= '0';
				end if;
				
				case STATE is
				
					when IDLE =>
						
						if A_LOCK = '0' and nCS_A = '0' then
							nWAIT_A	<= '0';
							A_LOCK  	<= '1';
							SRAM_CE0 <= '1';								
							SRAM_CE1 <= '0';
							SRAM_LB	<= '0';
							SRAM_UB	<= '1';
							SRAM_A   <= ADDR_A;
							
							if nWE_A = '1' then
								-- Read
								SRAM_OE  <= '0';
								STATE    <= ST_READ1_A;
							else	
								-- Write
								SRAM_WE  <= '0';
								SRAM_D(7 DOWNTO 0) <= DI_A;
								STATE    <= ST_WRITE1_A;
							end if;
						else

							if nCS_B_L = '0' then
								nWAIT_B	<= '0';
								B_LOCK	<= '1';
								SRAM_CE0	<= '0';								
								SRAM_CE1 <= '1';	
								SRAM_A	<= ADDR_B_L(18 downto 2) & '0';
								
								if nWE_B_L = '1' then
									-- Read
									SRAM_UB	<= '0';
									SRAM_LB	<= '0';
									SRAM_OE	<= '0';
									STATE		<= ST_READ1_B;

								else	
									-- Write
									if (ENDIAN_MODE = "11" and (MEM_MASK_B_L(0) = '1' or MEM_MASK_B_L(1) = '1') )
									or (ENDIAN_MODE = "00" and (MEM_MASK_B_L(2) = '1' or MEM_MASK_B_L(3) = '1') )then
										if ENDIAN_MODE = "11" then
											SRAM_D	<= DI_B_L(15 downto 0);
											SRAM_UB	<= not MEM_MASK_B_L(1);
											SRAM_LB	<= not MEM_MASK_B_L(0);	
										else
											SRAM_D	<= DI_B_L(23 downto 16) & DI_B_L(31 downto 24);
											SRAM_UB	<= not MEM_MASK_B_L(2);
											SRAM_LB	<= not MEM_MASK_B_L(3);
										end if;
										SRAM_WE	<= '0';
										if (ENDIAN_MODE = "11" and (MEM_MASK_B_L(2) = '1' or MEM_MASK_B_L(3) = '1') )
										or (ENDIAN_MODE = "00" and (MEM_MASK_B_L(0) = '1' or MEM_MASK_B_L(1) = '1') ) then
											STATE		<= ST_WRITE1_B;
										else
											STATE		<= ST_WRITE3_B;
										end if;
									else
										SRAM_A	<= ADDR_B_L(18 downto 2) & '1';
										if ENDIAN_MODE = "11" then
											SRAM_D	<= DI_B_L(31 downto 16);
											SRAM_UB	<= not MEM_MASK_B_L(3);
											SRAM_LB	<= not MEM_MASK_B_L(2);	
										else
											SRAM_D	<= DI_B_L(7 downto 0) & DI_B_L(15 downto 8);
											SRAM_UB	<= not MEM_MASK_B_L(0);
											SRAM_LB	<= not MEM_MASK_B_L(1);
										end if;
										SRAM_WE	<= '0';
										SRAM_CE0	<= '0';								
										SRAM_CE1 <= '1';
										STATE		<= ST_WRITE3_B;
									end if;
								end if;
							end if;
							
						end if;
						
			      when ST_READ1_A =>
						DO_A		<= SRAM_D(7 DOWNTO 0);                           
						nWAIT_A	<= '1';
						SRAM_D	<= (OTHERS=>'Z');
						SRAM_WE  <= '1';
                  SRAM_OE  <= '1';
                  SRAM_CE0 <= '1';
						SRAM_CE1 <= '1';
                  SRAM_LB  <= '1';
                  SRAM_UB  <= '1';						
                  STATE    <= IDLE;                  

               when ST_WRITE1_A => 
						nWAIT_A	<= '1';	
						SRAM_D	<= (OTHERS=>'Z');
						SRAM_WE  <= '1';
                  SRAM_OE  <= '1';
                  SRAM_CE0 <= '1';
						SRAM_CE1 <= '1';
                  SRAM_LB  <= '1';
                  SRAM_UB  <= '1';					
                  STATE    <= IDLE;                   

			      when ST_READ1_B =>
						if ENDIAN_MODE = "11" then
							DO_B(15 downto 0) <= SRAM_D;
						else
							DO_B(31 downto 16) <= SRAM_D(7 downto 0) & SRAM_D(15 downto 8);
						end if;
                  SRAM_A	<= ADDR_B(18 downto 2) & '1';
                  STATE		<= ST_READ2_B;                  
						
			      when ST_READ2_B =>
						if ENDIAN_MODE = "11" then
							DO_B(31 downto 16) <= SRAM_D;
						else
							DO_B(15 downto 0) <= SRAM_D(7 downto 0) & SRAM_D(15 downto 8);
						end if;
                  nWAIT_B	<= '1';
						SRAM_WE  <= '1';
                  SRAM_OE  <= '1';
                  SRAM_CE0 <= '1';
						SRAM_CE1 <= '1';
                  SRAM_LB  <= '1';
                  SRAM_UB  <= '1';		
						SRAM_D	<= (OTHERS=>'Z');
                  STATE		<= IDLE;

               when ST_WRITE1_B =>
						SRAM_UB	<= '1';
						SRAM_LB	<= '1';					
                  SRAM_WE  <= '1';
						SRAM_CE0 <= '1';								
						SRAM_CE1 <= '1';       
                  STATE    <= ST_WRITE2_B;                  

					when ST_WRITE2_B =>	
						SRAM_A	<= ADDR_B_L(18 downto 2) & '1';
						if ENDIAN_MODE = "11" then
							SRAM_D	<= DI_B_L(31 downto 16);
							SRAM_UB	<= not MEM_MASK_B_L(3);
							SRAM_LB	<= not MEM_MASK_B_L(2);	
						else
							SRAM_D	<= DI_B_L(7 downto 0) & DI_B_L(15 downto 8);
							SRAM_UB	<= not MEM_MASK_B_L(0);
							SRAM_LB	<= not MEM_MASK_B_L(1);
						end if;
                  SRAM_WE	<= '0';
						SRAM_CE0	<= '0';								
						SRAM_CE1 <= '1';
                  STATE		<= ST_WRITE3_B;

               when ST_WRITE3_B => 
						nWAIT_B	<= '1';	
						SRAM_D	<= (OTHERS=>'Z');
						SRAM_WE  <= '1';
                  SRAM_OE  <= '1';
                  SRAM_CE0 <= '1';
						SRAM_CE1 <= '1';
                  SRAM_LB  <= '1';
                  SRAM_UB  <= '1';					
                  STATE    <= IDLE;
						
					when OTHERS =>
						STATE <= IDLE;  
						
            end case;
				
			end if;
		end if;
end process;

end dp_sram_arch;
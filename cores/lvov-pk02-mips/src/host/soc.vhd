library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity mips_soc is                    
	port (
		-- CLOCK
		CPU_CLK			: in std_logic; -- 32.5 Mhz
		VGA_CLK			: in std_logic; -- VGA_CLK 25Mhz
		CPU_RESET		: in std_logic;
		
		-- VGA
		VGA_R				: OUT STD_LOGIC_VECTOR(3 downto 0);
		VGA_G				: OUT STD_LOGIC_VECTOR(3 downto 0);
		VGA_B				: OUT STD_LOGIC_VECTOR(3 downto 0);
		VGA_VSYNC		: buffer std_logic;
		VGA_HSYNC		: out std_logic;
		
		-- SRAM
		MEM_A       	: out std_logic_vector(31 downto 2);
		MEM_DI      	: out std_logic_vector(31 downto 0);
		MEM_DO      	: in  std_logic_vector(31 downto 0);
		MEM_MASK    	: out std_logic_vector(3  downto 0);
		MEM_WR      	: out std_logic;
		MEM_REQ     	: out std_logic;
		MEM_BUSY    	: in  std_logic;
	
		-- Keyboard
		KEYB_DATA   	: in  std_logic_vector(7 downto 0);
		
		-- Sound
		MIPS_BEEPER		: out std_logic;		

		-- SD Card
		SD_MOSI     : out   std_logic;
		SD_MISO     : in    std_logic;
		SD_SCK      : out   std_logic;
		SD_CS       : out   std_logic;
		
		-- FDC Ports
		VG93_CLK					: in	std_logic;
		VG93_nCLR				: in	std_logic;
				
		VG93_IRQ					: out	std_logic;
		VG93_DRQ					: out	std_logic;
		
		VG93_A					: in	std_logic_vector(1 downto 0);
		VG93_D_IN				: in	std_logic_vector(7 downto 0);
		VG93_D_OUT				: out std_logic_vector(7 downto 0);	
		VG93_nCS					: in	std_logic;		
		VG93_nRD					: in	std_logic;
		VG93_nWR					: in	std_logic;
		
		VG93_nDDEN				: in	std_logic;
		VG93_HRDY				: in	std_logic;

		FDC_DRIVE				: in	std_logic_vector(1 downto 0);
		FDC_nSIDE				: in	std_logic;
		TST						: out	std_logic
);		
				
end mips_soc;

architecture mips_soc_arch of mips_soc is

	signal CPU_A			: std_logic_vector(31 downto 0);
	signal CPU_DI			: std_logic_vector(31 downto 0);
	signal CPU_DO			: std_logic_vector(31 downto 0);
	signal CPU_SEL			: std_logic_vector(3 downto 0); 
	signal CPU_WE			: std_logic;
	signal CPU_INT			: std_logic;

	signal CPU_A_L			: std_logic_vector(31 downto 0);

	-- VGA
	signal POS_X      : unsigned(6 downto 0);
   signal POS_Y      : unsigned(4 downto 0);
   
   signal VA         : std_logic_vector(11 downto 0);
   signal VDI        : std_logic_vector(7 downto 0);
   signal VDO        : std_logic_vector(15 downto 0);
   signal VWR        : std_logic;
   signal VATTR      : std_logic_vector(7 downto 0);
   signal VRG        : std_logic_vector(7 downto 0);
	
	-- HW timer: Frame counter
	signal VGA_FRAMES	: std_logic_vector(31 downto 0);
	signal FR_LOCK		: std_logic;

	-- HW timer: CPU CLK counter
	signal CPU_CLK_COUNTER	: std_logic_vector(31 downto 0);
	
   type STATES is (ST_IDLE, ST_INC, ST_SET_FRAMES, ST_SET_CC_COUNTER);
   signal STATE : STATES;
	
	-- SD Card
	signal counter		:	unsigned(4 downto 0);
	-- Shift register has an extra bit because we write on the
	-- falling edge and read on the rising edge
	signal shift_reg	:	std_logic_vector(8 downto 0);
	signal in_reg		:	std_logic_vector(7 downto 0);
	signal SD_BUSY		:	std_logic;
	
-- VG93 Reg
signal VG93_STATUS	:	std_logic_vector(7 downto 0);
signal VG93_TRACK_R	:	std_logic_vector(7 downto 0);
signal VG93_SECTOR_R	:	std_logic_vector(7 downto 0);
signal VG93_DATA_R	:	std_logic_vector(7 downto 0);

signal VG93_CONTROL	:	std_logic_vector(7 downto 0);
signal VG93_TRACK		:	std_logic_vector(7 downto 0);
signal VG93_SECTOR	:	std_logic_vector(7 downto 0);
signal VG93_DATA		:	std_logic_vector(7 downto 0);

signal VG93_CONTROL_READY_M	: std_logic;	
signal VG93_DATA_READY_M		: std_logic;
signal VG93_CONTROL_READY		: std_logic;	
signal VG93_DATA_READY			: std_logic;

signal VG93_IRQ_B		: std_logic := '0';
signal VG93_DRQ_B		: std_logic := '0';
signal SET_IRQ_DRQ	: std_logic := '0';

signal RES_VG93_IRQ	: std_logic;
signal RES_VG93_DRQ	: std_logic;
signal RES_CR			: std_logic := '0';
signal RES_DR			: std_logic := '0';

signal idx_cnt			:	std_logic_vector(22 downto 0);
signal FDC_IDX			: std_logic;
signal VG93_TYPE_1_CMD_SET : std_logic;
signal VG93_TYPE_1_CMD : std_logic;	

begin

cpu: entity work.mlite_cpu
port map (
	clk         => CPU_CLK,
   reset_in    => CPU_RESET,
   intr_in     => CPU_INT,

   mem_address => CPU_A,
   mem_data_w  => CPU_DO,
   mem_data_r  => CPU_DI,
   mem_byte_we	=> CPU_SEL,
   mem_pause   => MEM_BUSY or SD_BUSY
	);



u_MIPS_VIDEO : entity work.mips_video
port map(
    CLK         => CPU_CLK,
    VGA_CLK     => VGA_CLK,
    RESET       => CPU_RESET,

    VA          => VA,
    VDI         => VDI,
    VDO         => VDO,
    VWR         => VWR,
    VATTR       => VATTR,

    VGA_R       => VGA_R,
    VGA_G       => VGA_G,
    VGA_B       => VGA_B,
    VGA_HSYNC   => VGA_HSYNC,
    VGA_VSYNC   => VGA_VSYNC );

	
CPU_WE <=	CPU_SEL(0) or CPU_SEL(1) or CPU_SEL(2) or CPU_SEL(3);

CPU_DI <=	x"000000" & VRG										when CPU_A_L = x"80000000" else
				x"000000" & VATTR										when CPU_A_L = x"80000010" else
				x"0000" & VDO											when CPU_A_L = x"80000020" or CPU_A_L = x"80000030" else
				x"000000" & '0' & std_logic_vector(POS_X)		when CPU_A_L = x"80000040" else
				x"000000" & "000" & std_logic_vector(POS_Y)	when CPU_A_L = x"80000050" else
				VGA_FRAMES												when CPU_A_L = x"80000060" else
				CPU_CLK_COUNTER										when CPU_A_L = x"80000064" else
				
				x"000000" & in_reg									when CPU_A_L = x"80000070" else
				x"000000" & KEYB_DATA								when CPU_A_L = x"80000090" else
				
				x"000000" & "1" & VG93_nDDEN & "1" & FDC_nSIDE & VG93_HRDY & VG93_nCLR & FDC_DRIVE
																			when CPU_A_L = x"80000E40" else
																			
				x"000000" & VG93_CONTROL							when CPU_A_L = x"80000E00" else
				x"000000" & VG93_TRACK								when CPU_A_L = x"80000E10" else
				x"000000" & VG93_SECTOR								when CPU_A_L = x"80000E20" else
				x"000000" & VG93_DATA								when CPU_A_L = x"80000E30" else
				
				x"0000000" & "00" & VG93_DATA_READY & VG93_CONTROL_READY
																			when CPU_A_L = x"80000E50" else				
				MEM_DO;

VA <= std_logic_vector(POS_Y) & std_logic_vector(POS_X);	

SD_CS			<=	'1'			when CPU_RESET = '1' else
					CPU_DO(0)	when rising_edge(CPU_CLK) and MEM_BUSY = '0' and CPU_RESET = '0' and CPU_WE = '1' and CPU_A = x"80000080";
								
MIPS_BEEPER	<= CPU_DO(0)	when rising_edge(CPU_CLK) and MEM_BUSY = '0' and CPU_RESET = '0' and CPU_WE = '1' and CPU_A = x"80000FE0";
				
-- Main State Machine
process(CPU_CLK)
   begin
	if rising_edge(CPU_CLK) then
		if CPU_RESET = '1' then
			MEM_REQ  <= '0';
			POS_X		<= "0000000";
			POS_Y		<= "00000";
         STATE		<= ST_IDLE;
         VWR		<= '0';
			VRG		<= "00000001";
			FR_LOCK	<= '0';
			CPU_INT	<= '0';
      else
			MEM_REQ  <= '0';
			MEM_WR	<= '0';
         VWR		<= '0';
			
			if VGA_VSYNC = '0' then
				FR_LOCK <= '0';
			end if;
			
			case STATE is
				when ST_INC =>
					POS_X <= POS_X + 1;
					if POS_X = 79 then 
						POS_X <= "0000000";
						POS_Y <= POS_Y + 1;
						if POS_Y = 29 then
							POS_Y <= "00000";
						end if;
					end if;
					STATE <= ST_IDLE;
					
				when ST_SET_FRAMES =>
                     STATE <= ST_IDLE;
							
				when ST_SET_CC_COUNTER =>
							STATE <= ST_IDLE;
			
				when OTHERS =>
                     STATE <= ST_IDLE; 
			end case;
			
			if FR_LOCK = '0' and VGA_VSYNC = '1' and STATE /= ST_SET_FRAMES then
				FR_LOCK		<= '1';
				VGA_FRAMES	<= VGA_FRAMES + 1;
				CPU_INT		<= '1';
				STATE			<= ST_IDLE;
			end if;
			
			if STATE /= ST_SET_CC_COUNTER then
				CPU_CLK_COUNTER <= CPU_CLK_COUNTER +1;
			end if;
			
			if MEM_BUSY = '0' and CPU_RESET = '0' then
				CPU_A_L <= CPU_A;
				if (CPU_A = x"80000020" or CPU_A = x"80000030") and VRG(0) = '1' then
					STATE <= ST_INC;
				end if;
				
				-- Plasma ISR Vector
				if CPU_A = x"0000003C" then
					CPU_INT <= '0';
				end if;
				
				if CPU_A(31) = '1' and CPU_WE = '1' then
			
					case CPU_A is

						when x"80000000" =>					-- Video Mode
							VRG <= CPU_DO(7 downto 0);

                  when x"80000010" =>					-- Video Set Attr
                     VATTR <= CPU_DO(7 downto 0);
                     if VRG(2) = '1' then
								STATE <= ST_INC;
                     end if;

						when x"80000020" =>					-- Video Write Char
							VDI <= CPU_DO(7 downto 0);
                     VWR <= '1';

						when x"80000030" =>					-- Video Write Char & Attr
							VATTR <= CPU_DO(15 downto 8);
                     VDI <= CPU_DO(7 downto 0);
                     VWR <= '1';
                 
                  when x"80000040" =>					-- Video Set X Pos
							POS_X <= unsigned(CPU_DO(6 downto 0));

                  when x"80000050" =>					-- Video Set Y Pos
                     POS_Y <= unsigned(CPU_DO(4 downto 0));
							
						when x"80000060" =>	
							VGA_FRAMES <= CPU_DO;
							STATE <= ST_SET_FRAMES;	
							
						when x"80000064" =>	
							CPU_CLK_COUNTER <= CPU_DO;
							STATE <= ST_SET_CC_COUNTER;	
								
                  when OTHERS =>
                     STATE <= ST_IDLE;

					end case;
					
				-- CPU Mem Access
				elsif CPU_A(31) = '0' then
					MEM_A		<= '0' & CPU_A(30 downto 2);
					MEM_DI	<= CPU_DO;
					MEM_WR	<= CPU_WE;
					MEM_MASK	<= CPU_SEL;
					MEM_REQ	<= '1';
				end if;
				
			end if;
			
		 end if;
	end if;
end process;

-- SD Card Serializer
-- SD CLK = CPU_CLK / 2 
-- MMC/SDC can work at the clock frequency upto 20/25 MHz.

process(CPU_CLK)
begin
		if rising_edge(CPU_CLK) then
        if CPU_RESET = '1' then
            shift_reg 	<= (others => '1');
            in_reg 		<= (others => '1');
            counter 		<= "10000"; -- Idle
        else
				
            case counter is

					when "10000" =>
						if MEM_BUSY = '0' and CPU_A = x"80000070" then
							if CPU_WE = '0' then
								shift_reg <= (others => '1');
							else
								shift_reg <= CPU_DO(7 downto 0) & '1';
							end if;
							counter <= "00000";
						end if;

					when "01111" =>
						in_reg	<= shift_reg(7 downto 0);
						counter	<= "10000";
						
					when OTHERS =>			
	  					counter <= counter + 1;
						if counter(0) = '0' then
							shift_reg(0) <= SD_MISO;
						else
							shift_reg <= shift_reg(7 downto 0) & '1';
						end if;
	
            end case;
			  
        end if;
	  end if;
end process;

SD_BUSY	<= not counter(4);
TST <= counter(0);

SD_SCK	<= counter(0);
SD_MOSI	<= shift_reg(8);

-- VG93 Reg Read
VG93_D_OUT	<= 	VG93_STATUS(7 downto 2) & FDC_IDX & VG93_STATUS(0)
											when VG93_nCS = '0' and VG93_nRD = '0' and VG93_A = "00" and VG93_TYPE_1_CMD = '1' else
						VG93_STATUS		when VG93_nCS = '0' and VG93_nRD = '0' and VG93_A = "00" else
						VG93_TRACK_R	when VG93_nCS = '0' and VG93_nRD = '0' and VG93_A = "01" else
						VG93_SECTOR_R	when VG93_nCS = '0' and VG93_nRD = '0' and VG93_A = "10" else
						VG93_DATA_R		when VG93_nCS = '0' and VG93_nRD = '0' and VG93_A = "11" else
						"11111111";
						
-- VG93 Status set to BUSY when Command received
VG93_STATUS		<= CPU_DO(7 downto 0) when rising_edge(CPU_CLK) and MEM_BUSY = '0' and CPU_RESET = '0' and CPU_WE = '1' and CPU_A = x"80000E00" else
						"00000001" when VG93_CONTROL_READY_M = '1';
						
VG93_TRACK_R	<= CPU_DO(7 downto 0) when rising_edge(CPU_CLK) and MEM_BUSY = '0' and CPU_RESET = '0' and CPU_WE = '1' and CPU_A = x"80000E10";
VG93_SECTOR_R	<=	CPU_DO(7 downto 0) when rising_edge(CPU_CLK) and MEM_BUSY = '0' and CPU_RESET = '0' and CPU_WE = '1' and CPU_A = x"80000E20";
VG93_DATA_R		<= CPU_DO(7 downto 0) when rising_edge(CPU_CLK) and MEM_BUSY = '0' and CPU_RESET = '0' and CPU_WE = '1' and CPU_A = x"80000E30";

-- VG93 Reg Write
VG93_CONTROL	<= VG93_D_IN when VG93_nCS = '0' and VG93_A = "00" and VG93_nWR = '0' and falling_edge(VG93_CLK);
VG93_TRACK		<= VG93_D_IN when VG93_nCS = '0' and VG93_A = "01" and VG93_nWR = '0' and falling_edge(VG93_CLK);
VG93_SECTOR		<= VG93_D_IN when VG93_nCS = '0' and VG93_A = "10" and VG93_nWR = '0' and falling_edge(VG93_CLK);
VG93_DATA		<= VG93_D_IN when VG93_nCS = '0' and VG93_A = "11" and VG93_nWR = '0' and falling_edge(VG93_CLK);

-- Buffers. IRQ and DRQ are send	on VG93 status write
VG93_IRQ_B		<= CPU_DO(1) when rising_edge(CPU_CLK) and MEM_BUSY = '0' and CPU_RESET = '0' and CPU_WE = '1' and CPU_A = x"80000E40";
VG93_DRQ_B		<= CPU_DO(0) when rising_edge(CPU_CLK) and MEM_BUSY = '0' and CPU_RESET = '0' and CPU_WE = '1' and CPU_A = x"80000E40";

-- One shoot
SET_IRQ_DRQ		<= '1' when rising_edge(CPU_CLK) and MEM_BUSY = '0' and CPU_RESET = '0' and CPU_WE = '1' and CPU_A = x"80000E00" else '0';

-- One shoot
RES_VG93_IRQ <= '1' when VG93_nCS = '0' and VG93_A = "00" and rising_edge(CPU_CLK) else '0';
RES_VG93_DRQ <= '1' when VG93_nCS = '0' and VG93_A = "11" and rising_edge(CPU_CLK) else '0';

-- IRQ is cleard if VG93 Status Reg read or VG92 Control Reg written	
IRQ_TR: entity work.D_Flip_Flop PORT MAP(
		rst => RES_VG93_IRQ,
		pre => '0',
		ce  => SET_IRQ_DRQ,
		d   => VG93_IRQ_B,
		q   => VG93_IRQ
);

-- DRQ is cleared if VG93 Data Reg accessed
DRQ_TR: entity work.D_Flip_Flop PORT MAP(
		rst => RES_VG93_DRQ,
		pre => '0',
		ce  => SET_IRQ_DRQ,
		d   => VG93_DRQ_B,
		q   => VG93_DRQ
);


CR_TR: entity work.D_Flip_Flop PORT MAP(
		rst => CPU_RESET,
		pre => VG93_CONTROL_READY_M,
		ce  => RES_CR,
		d   => '0',
		q   => VG93_CONTROL_READY
);

-- One Shoot
VG93_CONTROL_READY_M <= 	'1' when VG93_nCS = '0' and VG93_A = "00" and VG93_nWR = '0' and falling_edge(VG93_CLK) else '0';
RES_CR					<=		'1' when rising_edge(CPU_CLK) and MEM_BUSY = '0' and CPU_RESET = '0' and CPU_WE = '0' and CPU_A = x"80000E00" else '0';

DR_TR: entity work.D_Flip_Flop PORT MAP(
		rst => CPU_RESET,
		pre => VG93_DATA_READY_M,
		ce  => RES_DR,
		d   => '0',
		q   => VG93_DATA_READY
);
								
VG93_DATA_READY_M <=	'1' when VG93_A = "11" and VG93_nCS = '0' and falling_edge(VG93_CLK) else '0';
RES_DR				<=	'1' when rising_edge(CPU_CLK) and MEM_BUSY = '0' and CPU_RESET = '0' and CPU_A = x"80000E30" else '0';

IDX_TR: entity work.D_Flip_Flop PORT MAP(
		rst => CPU_RESET,
		pre => VG93_TYPE_1_CMD_SET,
		ce  => VG93_CONTROL_READY_M,
		d   => '0',
		q   => VG93_TYPE_1_CMD
);

VG93_TYPE_1_CMD_SET <= '1' when rising_edge(CPU_CLK) and MEM_BUSY = '0' and CPU_RESET = '0' and CPU_WE = '1' and CPU_A = x"80000E10" else '0';

-- FDC Index pulse generator
-- 5 Hz for 300 RPM, Pulse width 8ms
process (CPU_CLK)	
begin
	if rising_edge(CPU_CLK) then
		idx_cnt <= idx_cnt + 1;

		if idx_cnt = 260000 then
			FDC_IDX <= '0';
		end if;
		
		if idx_cnt = 6132076 then
			idx_cnt <= (others => '0');
			FDC_IDX <= '1';
		end if;
		
	end if;
end process;

	
end mips_soc_arch;
-- Altera Microperipheral Reference Design Version 0802
--**********************************************************************************************
--
--					System:	A8251
--				Component:	Test Bench Stimulus
--
--					  File:	tb_A8251.vhd
--				 Function:	Sequences character transmission
--
--
--Copyright © 2002 Altera Corporation. All rights reserved.  Altera products are
--protected under numerous U.S. and foreign patents, maskwork rights, copyrights and
--other intellectual property laws.  

--This reference design file, and your use thereof, is subject to and governed by
--the terms and conditions of the applicable Altera Reference Design License Agreement.
--By using this reference design file, you indicate your acceptance of such terms and
--conditions between you and Altera Corporation.  In the event that you do not agree with
--such terms and conditions, you may not use the reference design file. Please promptly
--destroy any copies you have made.

--This reference design file being provided on an "as-is" basis and as an accommodation 
--and therefore all warranties, representations or guarantees of any kind 
--(whether express, implied or statutory) including, without limitation, warranties of 
--merchantability, non-infringement, or fitness for a particular purpose, are 
--specifically disclaimed.  By making this reference design file available, Altera
--expressly does not recommend, suggest or require that this reference design file be
--used in combination with any other product not provided by Altera.
--**********************************************************************************************

LIBRARY ieee;
USE ieee.std_logic_1164.all;

LIBRARY conversions;
USE conversions.conversions.all;


----------------------------
-- Entity Declaration
----------------------------
ENTITY a8251tb IS

	--
	-- 82C51A processor bus timing parameters taken from the Intel data sheet.
	--
	GENERIC 
	(
		Tcy			: TIME :=   320 ns;		-- System clock period 						(min)
		Tar			: TIME :=    20 ns;		-- Address stable before read				(min)
		Tra			: TIME :=    20 ns;		-- Address hold time for read				(min)
		Trr			: TIME :=   130 ns;		-- Read pulse width 							(min)
		Trd			: TIME :=   100 ns; 		-- Data delay from read 					(max)
		Tdf			: TIME :=    75 ns; 		-- Read strobe inactive to data float	(max)
		Trvr			: TIME :=   960 ns;		-- Data read recovery time					(min)
		Taw			: TIME :=    20 ns;		-- Address stable before write			(min)
		Twa			: TIME :=    20 ns;		-- Address hold time for write			(min)
		Tww			: TIME :=   100 ns;		-- Write width parameter					(min)
		Tdw			: TIME :=   100 ns;		-- Data setup time for write				(min)
		Twd			: TIME :=     0 ns		-- Data hold time for write				(min)
	);


	PORT 
	(
		-- Common signals
      clk       			: OUT std_logic;
      reset					: OUT std_logic;
      txd_to_rxd   		: IN  std_logic;
      rxd_to_txd   		: IN  std_logic;
      nDTR_to_nDSR   	: IN  std_logic;
      nDSR_to_nDTR   	: IN  std_logic;

		-- Signals for the Tx USART
      tx_txrdy     		: IN  std_logic;
      tx_txempty     	: IN  std_logic;
      tx_rxrdy     		: IN  std_logic;
      tx_syn_brk     	: IN  std_logic;
      tx_nEN       		: IN  std_logic;
      tx_dout     		: IN  std_logic_vector (7 DOWNTO 0);

      tx_nWR     			: OUT std_logic;
      tx_nRD     			: OUT std_logic;
      tx_nCS     			: OUT std_logic;
      tx_CnD     	   	: OUT std_logic;
      tx_nRTS_to_nCTS   : IN  std_logic;
      tx_ExtSyncD			: OUT std_logic;
      tx_nTxC     		: OUT std_logic;
      tx_nRxC     		: OUT std_logic;
      tx_din     			: OUT std_logic_vector (7 DOWNTO 0);

		-- Signals for the Rx USART
      rx_txrdy     		: IN  std_logic;
      rx_txempty     	: IN  std_logic;
      rx_rxrdy     		: IN  std_logic;
      rx_syn_brk     	: IN  std_logic;
      rx_nEN       		: IN  std_logic;
      rx_dout     		: IN  std_logic_vector (7 DOWNTO 0);

      rx_nWR     			: OUT std_logic;
      rx_nRD     			: OUT std_logic;
      rx_nCS     			: OUT std_logic;
      rx_CnD     			: OUT std_logic;
      rx_nRTS_to_nCTS   : IN  std_logic;
      rx_ExtSyncD			: OUT std_logic;
      rx_nTxC     		: OUT std_logic;
      rx_nRxC     		: OUT std_logic;
      rx_din     			: OUT std_logic_vector (7 DOWNTO 0)
	);

END a8251tb;


-----------------------------
-- Architecture Body
-----------------------------
ARCHITECTURE MainTest OF a8251tb IS

	--
	-- Enumerated test state dumped with vectors to make reading
	-- waveforms easier.
	--
	TYPE test_state IS 
	(    
		initializing,	
      single_sync,	
      dual_sync,
      async_16x,	
      Kofu_mode,
      Fuchu_mode,
      Collins_mode,
      framing_error_mode,
      parity_error_mode,
      overrun_error_mode,	
      break_mode,
      cts_mode	
	);

	TYPE test_mode IS 
	(    
		sync_mode,	
      async_mode
	);

	SIGNAL	clk_Stim 				: std_logic := '0';
	SIGNAL	reset_Stim 				: std_logic := '0';
	SIGNAL	nTxC_Stim 				: std_logic := '0';
	SIGNAL	nRxC_Stim 				: std_logic := '0';

	SIGNAL	tx_nWR_Stim 			: std_logic := '1';
	SIGNAL	tx_nRD_Stim 			: std_logic := '1';
	SIGNAL	tx_nCS_Stim 			: std_logic := '1';
	SIGNAL	tx_CnD_Stim 			: std_logic := '1';
	SIGNAL	tx_ExtSyncD_Stim		: std_logic := '0';
	 
	SIGNAL	rx_nWR_Stim 			: std_logic := '1';
	SIGNAL	rx_nRD_Stim 			: std_logic := '1';
	SIGNAL	rx_nCS_Stim 			: std_logic := '1';
	SIGNAL	rx_CnD_Stim 			: std_logic := '1';
	SIGNAL	rx_ExtSyncD_Stim		: std_logic := '0';

	SIGNAL	rxc_per					: TIME := 30 * tcy;
	SIGNAL	txc_per					: TIME := 30 * tcy;
	
BEGIN

	--
	--	Concurrent signal assignments
	--
	clk       		<= clk_Stim;
	reset    		<= reset_Stim;

	tx_nWR     		<= tx_nWR_Stim;
	tx_nRD     		<= tx_nRD_Stim;
	tx_nCS     		<= tx_nCS_Stim;
	tx_CnD     		<= tx_CnD_Stim;
	tx_ExtSyncD		<= tx_ExtSyncD_Stim;
	tx_nTxC     	<= nTxC_Stim;
	tx_nRxC     	<= nRxC_Stim;

	rx_nWR     		<= rx_nWR_Stim;
	rx_nRD     		<= rx_nRD_Stim;
	rx_nCS     		<= rx_nCS_Stim;
	rx_CnD     		<= rx_CnD_Stim;
	rx_ExtSyncD		<= rx_ExtSyncD_Stim;
	rx_nTxC     	<= nRxC_Stim;
	rx_nRxC     	<= nTxC_Stim;
				  

	--
	-- Bus clock generation
	--
	clk_Stim  		<= '0' WHEN clk_Stim = 'U' ELSE 
						NOT clk_Stim 	AFTER Tcy/2;
	
	--
	-- Rx clock generation
	--
	Rx_clk_gen_proc : PROCESS 
	BEGIN
											
		nRxC_Stim <= '0' AFTER rxc_per/2, '1' AFTER rxc_per;

		WAIT FOR rxc_per;

	END PROCESS;

	--
	-- Tx clock generation
	--
	Tx_clk_gen_proc : PROCESS
	BEGIN
											
		nTxC_Stim <= '0' AFTER txc_per/2, '1' AFTER txc_per;

		WAIT FOR txc_per;

	END PROCESS;


	GeneralStimulus : PROCESS

		VARIABLE current_test_state	: test_state;
		VARIABLE current_test_mode		: test_mode;


		-----------------------------------------------------------------------
		--
		-- Procedure to perform master reset
		--
    	-----------------------------------------------------------------------
    	PROCEDURE MasterReset IS
      BEGIN

			reset_Stim <= '0';

			WAIT FOR 6 * Tcy;
          
			reset_Stim <= '1';
          
		END MasterReset;


		-----------------------------------------------------------------------
		--
		-- Procedure to write the MODE initialization words to the Tx USART
		--
		-----------------------------------------------------------------------
		PROCEDURE  WrTxMode ( mode		: IN std_logic_vector(7 DOWNTO 0);
								    sync1	: IN std_logic_vector(7 DOWNTO 0);
 								    sync2	: IN std_logic_vector(7 DOWNTO 0)
 								  ) IS
   	BEGIN

	      tx_CnD_Stim  	<= '1';
	      tx_nCS_Stim 	<= '0';
   		tx_din			<= mode;
	      WAIT FOR Taw;
   
	      tx_nWR_Stim 	<= '0';
	      WAIT FOR Tww;
	
 	      tx_nWR_Stim 	<= '1';
 	      WAIT FOR Twa;
   
			tx_nCS_Stim 	<= '1';
	      WAIT FOR 6 * Tcy;
	
   		IF (mode(1) = '0') AND (mode(0) = '0') AND (mode(6) = '0') THEN 
			
         	tx_CnD_Stim  	<= '1';
	      	tx_nCS_Stim 	<= '0';
				tx_din			<= sync1;
	      	WAIT FOR Taw;
 	
 	      	tx_nWR_Stim 	<= '0';
         	WAIT FOR Tww;

	      	tx_nWR_Stim 	<= '1';
	      	WAIT FOR Twa;
   
	      	tx_nCS_Stim 	<= '1';
	      	WAIT FOR 6 * Tcy;
	
			END IF;
	
 			IF (mode(1) = '0') AND (mode(0) = '0') AND (mode(7) = '0') AND (mode(6) = '0') THEN 
 			
         	tx_CnD_Stim  	<= '1';
				tx_nCS_Stim 	<= '0';
				tx_din			<= sync2;
	      	WAIT FOR Taw;
   
	      	tx_nWR_Stim 	<= '0';
         	WAIT FOR Tww;
	
	      	tx_nWR_Stim 	<= '1';
	      	WAIT FOR Twa;
 	
 	      	tx_nCS_Stim 	<= '1';

			END IF;
	
			IF ( current_test_mode = async_mode ) THEN

         	WAIT FOR 8 * Tcy;

			ELSE

				WAIT FOR 18 * Tcy;

			END IF;

   	END WrTxMode;

	
		-----------------------------------------------------------------------
		--
		-- Procedure to write the MODE initialization words to the Rx USART
		--
		-----------------------------------------------------------------------
		PROCEDURE  WrRxMode ( mode		: IN std_logic_vector(7 DOWNTO 0);
								    sync1	: IN std_logic_vector(7 DOWNTO 0);
 								    sync2	: IN std_logic_vector(7 DOWNTO 0)
 								  ) IS
   	BEGIN

	      rx_CnD_Stim  	<= '1';
	      rx_nCS_Stim 	<= '0';
   		rx_din			<= mode;
	      WAIT FOR Taw;
   
	      rx_nWR_Stim 	<= '0';
	      WAIT FOR Tww;
	
 	      rx_nWR_Stim 	<= '1';
 	      WAIT FOR Twa;
   
			rx_nCS_Stim 	<= '1';
	      WAIT FOR 6 * Tcy;
	
   		IF (mode(1) = '0') AND (mode(0) = '0') AND (mode(6) = '0') THEN 
			
         	rx_CnD_Stim  	<= '1';
	      	rx_nCS_Stim 	<= '0';
				rx_din			<= sync1;
	      	WAIT FOR Taw;
 	
 	      	rx_nWR_Stim 	<= '0';
         	WAIT FOR Tww;

	      	rx_nWR_Stim 	<= '1';
	      	WAIT FOR Twa;
   
	      	rx_nCS_Stim 	<= '1';
	      	WAIT FOR 6 * Tcy;
	
			END IF;
	
 			IF (mode(1) = '0') AND (mode(0) = '0') AND (mode(7) = '0') AND (mode(6) = '0') THEN 
 			
         	rx_CnD_Stim  	<= '1';
				rx_nCS_Stim 	<= '0';
				rx_din			<= sync2;
	      	WAIT FOR Taw;
   
	      	rx_nWR_Stim 	<= '0';
         	WAIT FOR Tww;
	
	      	rx_nWR_Stim 	<= '1';
	      	WAIT FOR Twa;
 	
 	      	rx_nCS_Stim 	<= '1';

			END IF;
	
			IF ( current_test_mode = async_mode ) THEN

         	WAIT FOR 8 * Tcy;

			ELSE

				WAIT FOR 18 * Tcy;

			END IF;

   	END WrRxMode;

	
   	-----------------------------------------------------------------------
		--
		-- Define procedure to write Command Word	to Tx USART
		--
		-----------------------------------------------------------------------
		PROCEDURE  WrTxCmd ( cmdwrd : IN std_logic_vector(7 DOWNTO 0) ) IS
 		BEGIN
 	
         tx_CnD_Stim  	<= '1';
      	tx_nCS_Stim 	<= '0';
			tx_din			<= cmdwrd;
	      WAIT FOR Taw;
   
	      tx_nWR_Stim 	<= '0';
         WAIT FOR Tww;
	
	      tx_nWR_Stim 	<= '1';
	      WAIT FOR Twa;
 	
 	      tx_nCS_Stim 	<= '1';

			IF ( current_test_mode = async_mode ) THEN

         	WAIT FOR 8 * Tcy;

			ELSE

				WAIT FOR 18 * Tcy;

			END IF;

		END WrTxCmd;

	
   	-----------------------------------------------------------------------
		--
		-- Define procedure to write Command Word	to Rx USART
		--
		-----------------------------------------------------------------------
		PROCEDURE  WrRxCmd ( cmdwrd : IN std_logic_vector(7 DOWNTO 0) ) IS
 		BEGIN
 	
         rx_CnD_Stim  	<= '1';
      	rx_nCS_Stim 	<= '0';
			rx_din			<= cmdwrd;
	      WAIT FOR Taw;
   
	      rx_nWR_Stim 	<= '0';
         WAIT FOR Tww;
	
	      rx_nWR_Stim 	<= '1';
	      WAIT FOR Twa;
 	
 	      rx_nCS_Stim 	<= '1';
         WAIT FOR 6 * Tcy;

			IF ( current_test_mode = async_mode ) THEN

         	WAIT FOR 8 * Tcy;

			ELSE

				WAIT FOR 18 * Tcy;

			END IF;

		END WrRxCmd;

	
   	-----------------------------------------------------------------------
		--
		-- Define procedure to write Transmit Data to the Tx USART
		--
   	-----------------------------------------------------------------------
		PROCEDURE  WrTxTxD ( TxIn : IN std_logic_vector(7 DOWNTO 0) ) IS
		BEGIN
	
 	      tx_CnD_Stim  	<= '0';	
 	      tx_nCS_Stim 	<= '0';
   		tx_din			<= TxIn;
      	WAIT FOR Taw;
	
	      tx_nWR_Stim 	<= '0';
         WAIT FOR Tww;
	
         tx_nWR_Stim 	<= '1';
	      WAIT FOR Twa;
	
	      tx_nCS_Stim 	<= '1';
 	      WAIT FOR 6 * Tcy;
 	
   	END WrTxTxD;


   	-----------------------------------------------------------------------
		--
		-- Define procedure to write Transmit Data to the Rx USART
		--
   	-----------------------------------------------------------------------
		PROCEDURE  WrRxTxD ( TxIn : IN std_logic_vector(7 DOWNTO 0) ) IS
		BEGIN
	
 	      rx_CnD_Stim  	<= '0';	
 	      rx_nCS_Stim 	<= '0';
   		rx_din			<= TxIn;
      	WAIT FOR Taw;
	
	      rx_nWR_Stim 	<= '0';
         WAIT FOR Tww;
	
         rx_nWR_Stim 	<= '1';
	      WAIT FOR Twa;
	
	      rx_nCS_Stim 	<= '1';
 	      WAIT FOR 6 * Tcy;
 	
   	END WrRxTxD;


		-----------------------------------------------------------------------
		--
		-- Procedure to read the Status Register in the Tx USART and 
		-- check the data.
		--
		-----------------------------------------------------------------------
		PROCEDURE  CheckTxStat ( ExpectedData : IN std_logic_vector(7 DOWNTO 0) ) IS

			VARIABLE ExpectDataString	: STRING(1 TO 6);
			VARIABLE GotDataString		: STRING(1 TO 6);
			VARIABLE	TempData				: std_logic_vector(7 DOWNTO 0);

		BEGIN

 	      tx_CnD_Stim  	<= '1';	
 	      tx_nCS_Stim 	<= '0';
      	WAIT FOR Tar;
	
	      tx_nRD_Stim 	<= '0';
         WAIT FOR Trr;

			TempData 		:=	tx_dout;

         tx_nRD_Stim 	<= '1';
	      WAIT FOR Tra;
	
	      tx_nCS_Stim 	<= '1';
	      WAIT FOR Tra;

			ExpectDataString 	:= to_hex_str(ExpectedData,  6);
			GotDataString 		:= to_hex_str(TempData, 6);

			ASSERT ( TempData = ExpectedData ) 
				REPORT "*** Check Status Error on Tx USART *** Expected: " & ExpectDataString & " got: " & GotDataString SEVERITY ERROR;

		END CheckTxStat;


		-----------------------------------------------------------------------
		--
		-- Procedure to read the Status Register in the Rx USART and 
		-- check the data.
		--
		-----------------------------------------------------------------------
		PROCEDURE  CheckRxStat ( ExpectedData : IN std_logic_vector(7 DOWNTO 0) ) IS

			VARIABLE ExpectDataString	: STRING(1 TO 6);
			VARIABLE GotDataString		: STRING(1 TO 6);
			VARIABLE	TempData				: std_logic_vector(7 DOWNTO 0);

		BEGIN

 	      rx_CnD_Stim  	<= '1';	
 	      rx_nCS_Stim 	<= '0';
      	WAIT FOR Tar;
	
	      rx_nRD_Stim 	<= '0';
         WAIT FOR Trr;

			TempData 		:=	rx_dout;

         rx_nRD_Stim 	<= '1';
	      WAIT FOR Tra;
	
	      rx_nCS_Stim 	<= '1';
	      WAIT FOR Tra;

			ExpectDataString 	:= to_hex_str(ExpectedData,  6);
			GotDataString 		:= to_hex_str(TempData, 6);

			ASSERT ( TempData = ExpectedData ) 
				REPORT "*** Check Status Error on Rx USART *** Expected: " & ExpectDataString & " got: " & GotDataString SEVERITY ERROR;

		END CheckRxStat;


		-----------------------------------------------------------------------
		--
		-- Procedure to read the Rx Data Register in the Tx USART and 
		-- check the data.
		--
		-----------------------------------------------------------------------
		PROCEDURE  CheckTxRxd ( ExpectedData : IN std_logic_vector(7 DOWNTO 0) ) IS

			VARIABLE ExpectDataString	: STRING(1 TO 6);
			VARIABLE GotDataString		: STRING(1 TO 6);
			VARIABLE	TempData				: std_logic_vector(7 DOWNTO 0);

		BEGIN

 	      tx_CnD_Stim  	<= '0';	
 	      tx_nCS_Stim 	<= '0';
      	WAIT FOR Tar;
	
	      tx_nRD_Stim 	<= '0';
         WAIT FOR Trr;

			TempData 		:=	tx_dout;

         tx_nRD_Stim 	<= '1';
	      WAIT FOR Tra;
	
	      tx_nCS_Stim 	<= '1';
	      WAIT FOR Tra;

			ExpectDataString 	:= to_hex_str(ExpectedData,  6);
			GotDataString 		:= to_hex_str(TempData, 6);

			ASSERT ( TempData = ExpectedData ) 
				REPORT "*** Check Rx Data Error on Tx USART *** Expected: " & ExpectDataString & " got: " & GotDataString SEVERITY ERROR;

		END CheckTxRxd;


		-----------------------------------------------------------------------
		--
		-- Procedure to read the Rx Data Register in the Rx USART and 
		-- check the data.
		--
		-----------------------------------------------------------------------
		PROCEDURE  CheckRxRxd ( ExpectedData : IN std_logic_vector(7 DOWNTO 0) ) IS

			VARIABLE ExpectDataString	: STRING(1 TO 6);
			VARIABLE GotDataString		: STRING(1 TO 6);
			VARIABLE	TempData				: std_logic_vector(7 DOWNTO 0);

		BEGIN

 	      rx_CnD_Stim  	<= '0';	
 	      rx_nCS_Stim 	<= '0';
      	WAIT FOR Tar;
	
	      rx_nRD_Stim 	<= '0';
         WAIT FOR Trr;

			TempData 		:=	rx_dout;

         rx_nRD_Stim 	<= '1';
	      WAIT FOR Tra;
	
	      rx_nCS_Stim 	<= '1';
	      WAIT FOR Tra;

			ExpectDataString 	:= to_hex_str(ExpectedData, 6);
			GotDataString 		:= to_hex_str(TempData, 6);

			ASSERT ( TempData = ExpectedData ) 
				REPORT "*** Check Rx Data Error on Rx USART *** Expected: " & ExpectDataString & " got: " & GotDataString SEVERITY ERROR;

		END CheckRxRxd;


		-----------------------------------------------------------------------
		--
		-- Procedure to wait for N cycles of the Tx clock 
		--
		-----------------------------------------------------------------------
		PROCEDURE  TxWait ( Cycles : natural ) IS

			VARIABLE Count : natural;

		BEGIN

			WAIT FOR ( txc_per * Cycles );

--			Count := 0;
--
--			WAIT UNTIL ( nTxC_Stim = '1' );	-- The first partial clock				
--
--			WHILE ( Count < Cycles ) LOOP
--
--  				WAIT UNTIL ( nTxC_Stim = '1' );
--				
--				Count := Count + 1;				
--
--			END LOOP;

		END TxWait;


		-----------------------------------------------------------------------
		--
		-- Procedure to set period of the Tx clock 
		--
		-----------------------------------------------------------------------
		PROCEDURE  TxClkSet ( Period : TIME ) IS
		BEGIN

			txc_per <= Period;						-- Set the clock period

			WAIT UNTIL ( nTxC_Stim = '1' );		-- Block till it takes effect

		END TxClkSet;


		-----------------------------------------------------------------------
		--
		-- Procedure to set period of the Rx clock 
		--
		-----------------------------------------------------------------------
		PROCEDURE  RxClkSet ( Period : TIME ) IS
		BEGIN

			rxc_per <= Period;						-- Set the clock period

			WAIT UNTIL ( nRxC_Stim = '1' );		-- Block till it takes effect

		END RxClkSet;


	---------------------------------------------------------------
	-- Main Test Program
	---------------------------------------------------------------
	BEGIN

		ASSERT false REPORT "INITIALIZING" SEVERITY NOTE;

		current_test_state 	:= initializing;
		current_test_mode 	:= sync_mode;

		MasterReset;

		TxClkSet(30 * tcy);
		RxClkSet(30 * tcy);

		--
		-- Perform the Intel recommended	initialization sequence
		-- for both the Tx and Rx USARTs.
		-- 
		WrTxMode ("00000000", "00000000", "00000000");		-- Initialize the mode
		WrTxCmd ("01000000");										-- Write a reset command

		WrRxMode ("00000000", "00000000", "00000000");		-- Initialize the mode
		WrRxCmd ("01000000");										-- Write a reset command


		--
		--	Setup any mode to prepare for the I/O discrete test
		-- that follows.
		-- 
		WrTxMode ("00000000", "00000000", "00000000");		-- Initialize the mode
		WrRxMode ("00000000", "00000000", "00000000");		-- Initialize the mode


		--
		-- Check the abilty to manipulate DTR, DSR, and assert break.
		--
		WrTxCmd ("00000010");
		TxWait(3);
		IF ( nDTR_to_nDSR = '1' ) THEN ASSERT false REPORT "DTR CLEAR FAILED"		SEVERITY NOTE; END IF;

		WrTxCmd ("00000000");
		TxWait(3);
		IF ( nDTR_to_nDSR = '0' ) THEN ASSERT false REPORT "DTR SET FAILED" 			SEVERITY NOTE; END IF;
		 
		WrTxCmd ("00100000");
		TxWait(3);
		IF ( tx_nRTS_to_nCTS = '1' ) THEN ASSERT false REPORT "RTS CLEAR FAILED"	SEVERITY NOTE; END IF;
		 
		WrTxCmd ("00000000");
		TxWait(3);
		IF ( tx_nRTS_to_nCTS = '0' ) THEN ASSERT false REPORT "RTS SET FAILED" 		SEVERITY NOTE; END IF; 


		--
		--	Start synch mode, single sync character test using HDLC format.
		--
		--		Synchronous mode
		--		8 bit characters
		--		No parity
		--		Internal sync detection
		--		Single sync character
		--		Maximum Tx rate (64 Kbps)
		--		Maximum Rx rate (64 Kbps)
		--		
		ASSERT false REPORT "START SYNC MODE TEST - SINGLE SYNC CHARACTER" SEVERITY NOTE;
      
		current_test_state	:= single_sync;
		current_test_mode 	:= sync_mode;

		TxClkSet(15625 ns);
		RxClkSet(15625 ns);

		--
		-- Init the Tx USART
		--
		WrTxCmd ("01000000");									-- Write a reset command
		
		WrTxMode ("10001100", "01111110", "00000000");	-- Initialize the mode use an HDLC flag character for sync 
		
		WrTxCmd ("10100111");									-- Enter hunt mode

		--
		-- Init the Rx USART
		--
		WrRxCmd ("01000000");									-- Write a reset command
		
		WrRxMode ("10001100", "01111110", "00000000");	-- Initialize the mode, use an HDLC flag character for sync 
		
		WrRxCmd ("10100111");									-- Enter hunt mode

		TxWait(24);													-- Wait for three character times, during this time the line
																		-- should be in a marking state.

		IF ( tx_txrdy = '0' ) THEN 							-- Wait for tx_txrdy
			WAIT UNTIL ( tx_txrdy = '1' ); 
		END IF;

		WrTxTxD ("01111110");									-- Send first character, a sync character

		IF ( tx_txrdy = '0' ) THEN 							-- Wait for tx_txrdy
			WAIT UNTIL ( tx_txrdy = '1' ); 
		END IF;

		WrTxTxD ("01010101");									-- Send a single character that requires no bit stuffing

		IF ( rx_rxrdy = '0' ) THEN 							-- Wait for the Rx USART to receive it
			WAIT UNTIL ( rx_rxrdy = '1' );
		ELSE
			WAIT UNTIL ( rx_rxrdy = '0' ); 
			WAIT UNTIL ( rx_rxrdy = '1' ); 
		END IF;

		CheckRxStat ("10000111");								-- Check Status, there should be no errors and a character waiting

		CheckRxRxd("01010101");									-- check the data

		CheckRxStat ("10000101");								-- Check Status, the RXRDY bit should have been cleared

		TxWait(24);													-- Wait for three character times, during this time the 
																		-- transmitter should be transmitting flag characters.


		--
		--	Start synch mode, dual sync character test
		--
		--		Synchronous mode
		--		8 bit characters
		--		No parity
		--		Internal sync detection
		--		Two sync characters
		--		Maximum Tx rate (64 Kbps)
		--		Maximum Rx rate (64 Kbps)
		--		
		ASSERT false REPORT "START SYNC MODE TEST - DUAL SYNC CHARACTER" SEVERITY NOTE;
      
		current_test_state	:= dual_sync;
		current_test_mode 	:= sync_mode;

		TxClkSet(15625 ns);
		RxClkSet(15625 ns);

		--
		-- Init the Tx USART
		--
		WrTxCmd ("01010000");										-- Write a reset command, clear any errors from the last test
		
		WrTxMode ("00001100", "01100110", "10011001");		-- Initialize the mode, use a BISYNC sequence for sync
		
		WrTxCmd ("10100111");										-- Enter hunt mode

		--
		-- Init the Rx USART
		--
		WrRxCmd ("01010000");										-- Write a reset command, clear any errors from the last test
		
		WrRxMode ("00001100", "01100110", "10011001");		-- Initialize the mode use a BISYNC sequence for sync
		
		WrRxCmd ("10100111");										-- Enter hunt mode

		TxWait(24);														-- Wait for three character times, during this time the line
																			-- should be in a marking state.

		IF ( tx_txrdy = '0' ) THEN 								-- Wait for tx_txrdy
			WAIT UNTIL ( tx_txrdy = '1' ); 
		END IF;

		WrTxTxD ("01100110");										-- Send the first sync character 

		IF ( tx_txrdy = '0' ) THEN 								-- Wait for tx_txrdy
			WAIT UNTIL ( tx_txrdy = '1' ); 
		END IF;

		WrTxTxD ("10011001");										-- Send the second sync character 

		IF ( tx_txrdy = '0' ) THEN 								-- Wait for tx_txrdy
			WAIT UNTIL ( tx_txrdy = '1' ); 
		END IF;

		WrTxTxD ("10101010");										-- Send a single character 

		IF ( rx_rxrdy = '0' ) THEN 								-- Wait for the Rx USART to receive it
			WAIT UNTIL ( rx_rxrdy = '1' );
		ELSE
			WAIT UNTIL ( rx_rxrdy = '0' ); 
			WAIT UNTIL ( rx_rxrdy = '1' ); 
		END IF;

		CheckRxStat("10000111");									-- Check Status, there should be no errors and a character waiting

		CheckRxRxd("10101010");										-- Check the data

		CheckRxStat("10000101");									-- Check Status, the RXRDY bit should have been cleared


		TxWait(24);														-- Wait for three character times, during this time the 
																			-- transmitter should be transmitting flag characters.

		--
		--	Start asynch mode, 16x clock test (NEC Kofu test)
		--
		--		Asynchronous mode
		--		8 bit characters
		--		Even parity
		--		1 stop bit
		--		19.2 Kbps Tx rate
		--		19.2 Kbps Rx rate
		--		
		ASSERT false REPORT "START ASYNC MODE TEST - 16X CLOCK, 8 BIT DATA, EVEN PARITY" SEVERITY NOTE;
      
		current_test_state	:= Kofu_mode;
		current_test_mode 	:= async_mode;

		TxClkSet(3255 ns);
		RxClkSet(3255 ns);

		--
		-- Init the Tx USART
		--
		WrTxCmd ("01010000");										-- Write a reset command, clear any errors from the last test
		
		WrTxMode ("01111110", "00000000", "00000000");		-- Initialize the mode
		
		WrTxCmd ("00100111");										-- Write a setup command
		
		--
		-- Init the Rx USART
		--
		WrRxCmd ("01010000");										-- Write a reset command, clear any errors from the last test
		
		WrRxMode ("01111110", "00000000", "00000000");		-- Initialize the mode
		
		WrRxCmd ("00100111");										-- Enter hunt mode

		TxWait(8);														-- Wait for one character time, during this time the line
																			-- should be in a marking state.

		IF ( tx_txrdy = '0' ) THEN 								-- Wait for tx_txrdy
			WAIT UNTIL ( tx_txrdy = '1' ); 
		END IF;

		WrTxTxD ("10101010");										-- Send a single character 

		IF ( rx_rxrdy = '0' ) THEN 								-- Wait for the Rx USART to receive it
			WAIT UNTIL ( rx_rxrdy = '1' );
		ELSE
			WAIT UNTIL ( rx_rxrdy = '0' ); 
			WAIT UNTIL ( rx_rxrdy = '1' ); 
		END IF;

		CheckRxStat ("10000111");									-- Check Status, there should be no errors and a character waiting

		CheckRxRxd("10101010");										-- Check the data

		CheckRxStat ("10000101");									-- Check Status, the RXRDY bit should have been cleared

		TxWait(8);														-- Wait for one character time, during this time the 
																			-- transmitter should be transmitting idle line state.

		--
		--	Start asynch mode, 16x clock test ( NEC Fuchu test )
		--
		--		Asynchronous mode
		--		8 bit characters
		--		Odd parity
		--		1 stop bit
		--		200 bps Tx rate
		--		115 bps Rx rate
		--		
		ASSERT false REPORT "START ASYNC MODE TEST - 16X CLOCK, 8 BIT DATA, ODD PARITY" SEVERITY NOTE;
      
		current_test_state	:= Fuchu_mode;
		current_test_mode 	:= async_mode;

		TxClkSet(8680 ns);
		RxClkSet(8680 ns);

		--
		-- Init the Tx USART
		--
		WrTxCmd ("01010000");										-- Write a reset command, clear any errors from the last test
		
		WrTxMode ("01011110", "00000000", "00000000");		-- Initialize the mode
		
		WrTxCmd ("00100111");										-- Write a setup command
		
		--
		-- Init the Rx USART
		--
		WrRxCmd ("01010000");										-- Write a reset command, clear any errors from the last test
		
		WrRxMode ("01011110", "00000000", "00000000");		-- Initialize the mode
		
		WrRxCmd ("00100111");										-- Enter hunt mode

		TxWait(8);														-- Wait for one character time, during this time the line
																			-- should be in a marking state.

		IF ( tx_txrdy = '0' ) THEN 								-- Wait for tx_txrdy
			WAIT UNTIL ( tx_txrdy = '1' ); 
		END IF;

		WrTxTxD ("01010101");										-- Send a single character 

		IF ( rx_rxrdy = '0' ) THEN 								-- Wait for the Rx USART to receive it
			WAIT UNTIL ( rx_rxrdy = '1' );
		ELSE
			WAIT UNTIL ( rx_rxrdy = '0' ); 
			WAIT UNTIL ( rx_rxrdy = '1' ); 
		END IF;

		CheckRxStat ("10000111");									-- Check Status, there should be no errors and a character waiting

		CheckRxRxd("01010101");										-- Check the data

		CheckRxStat ("10000101");									-- Check Status, the RXRDY bit should have been cleared

		TxWait(8);														-- Wait for one character time, during this time the 
																			-- transmitter should be transmitting idle line state.


		--
		--	Start asynch mode, 1x clock test ( Collins test )
		--
		--		Asynchronous mode
		--		8 bit characters
		--		Even parity
		--		1 stop bit
		--		38.5 kbps Tx rate
		--		38.5 kbps Rx rate
		--		
		ASSERT false REPORT "START ASYNC MODE TEST - 1X CLOCK, 8 BIT DATA, EVEN PARITY" SEVERITY NOTE;
      
		current_test_state	:= Collins_mode;
		current_test_mode 	:= async_mode;

		TxClkSet(26000 ns);
		RxClkSet(26000 ns);

		--
		-- Init the Tx USART
		--
		WrTxCmd ("01010000");										-- Write a reset command, clear any errors from the last test
		
		WrTxMode ("01111101", "00000000", "00000000");		-- Initialize the mode
		
		WrTxCmd ("00100111");										-- Write a setup command
		
		--
		-- Init the Rx USART
		--
		WrRxCmd ("01010000");										-- Write a reset command, clear any errors from the last test
		
		WrRxMode ("01111101", "00000000", "00000000");		-- Initialize the mode
		
		WrRxCmd ("00100111");										-- Write a setup command

		CheckTxStat ("10000101");									-- Check the state of the Status register

		CheckTxRxd ("00000000");									-- Check the data

		TxWait(1);														-- Wait for one Tx clock time for the Rx UART
																			-- to complete configuration 

		IF ( tx_txrdy = '0' ) THEN 								-- Wait for tx_txrdy
			WAIT UNTIL ( tx_txrdy = '1' ); 
		END IF;

		WrTxTxD ("01010101");										-- Send a single character 

		IF ( rx_rxrdy = '0' ) THEN 								-- Wait for the Rx USART to receive it
			WAIT UNTIL ( rx_rxrdy = '1' );
		ELSE
			WAIT UNTIL ( rx_rxrdy = '0' ); 
			WAIT UNTIL ( rx_rxrdy = '1' ); 
		END IF;

		CheckRxStat ("10000111");									-- Check Status, there should be no errors and a character waiting

		CheckRxRxd("01010101");										-- Check the data

		CheckRxStat ("10000101");									-- Check Status, the RXRDY bit should have been cleared

		TxWait(8);														-- Wait for one character time, during this time the 
																			-- transmitter should be transmitting idle line state.

		WrTxCmd ("00100101");										-- Write a command to take DTR high

		TxWait(8);														-- Wait for one character time to make sure that nothing
																			-- else happens.

		--
		--	Start Framing Error test
		--
		-- Tx USART Mode
		--		Asynchronous mode
		--		8 bit characters
		--		Odd parity
		--		1 stop bit
		--		38.5 kbps Tx rate
		--		38.5 kbps Rx rate
		--		
		-- Rx USART Mode
		--		Asynchronous mode
		--		6 bit characters
		--		Odd parity
		--		1 stop bit
		--		38.5 kbps Tx rate
		--		38.5 kbps Rx rate
		--		
		ASSERT false REPORT "START FRAMING ERROR TEST" SEVERITY NOTE;
      
		current_test_state	:= framing_error_mode;
		current_test_mode 	:= async_mode;

		TxClkSet(26000 ns);
		RxClkSet(26000 ns);

		--
		-- Init the Tx USART
		--
		WrTxCmd ("01010000");										-- Write a reset command, clear any errors from the last test
		
		WrTxMode ("01011101", "00000000", "00000000");		-- Initialize the mode
		
		WrTxCmd ("00100111");										-- Write a setup command
		
		--
		-- Init the Rx USART
		--
		WrRxCmd ("01010000");										-- Write a reset command, clear any errors from the last test
		
		WrRxMode ("01010101", "00000000", "00000000");		-- Initialize the mode
		
		WrRxCmd ("00100111");										-- Write a setup command

		CheckRxStat ("10000101");									-- Check Status, there should be no errors

		CheckRxRxd ("00000000");									-- Check for data, it should be zero

		TxWait(1);														-- Wait for one Tx clock time for the Rx UART
																			-- to complete configuration 

		IF ( tx_txrdy = '0' ) THEN 								-- Wait for tx_txrdy
			WAIT UNTIL ( tx_txrdy = '1' ); 
		END IF;

		WrTxTxD ("00000001");										-- Send a single character to generate a framing error 

		IF ( rx_rxrdy = '0' ) THEN 								-- Wait for the Rx USART to receive it
			WAIT UNTIL ( rx_rxrdy = '1' );
		ELSE
			WAIT UNTIL ( rx_rxrdy = '0' ); 
			WAIT UNTIL ( rx_rxrdy = '1' ); 
		END IF;

		CheckRxStat ("10100111");									-- Check Status, there should be a framing error only

		CheckRxRxd ("00000001");									-- Check for data

		WrRxCmd ("00110111");										-- Clear the framing error

		CheckRxStat ("10000101");									-- Check Status, the framing error should have cleared

		TxWait(8);														-- Wait for one character time to let the receiver to
																			-- recover.

		--
		--	Start Parity Error test
		--
		-- Tx USART Mode
		--		Asynchronous mode
		--		8 bit characters
		--		Even parity
		--		1 stop bit
		--		38.5 kbps Tx rate
		--		38.5 kbps Rx rate
		--		
		-- Rx USART Mode
		--		Asynchronous mode
		--		6 bit characters
		--		Odd parity
		--		1 stop bit
		--		38.5 kbps Tx rate
		--		38.5 kbps Rx rate
		--		
		ASSERT false REPORT "START PARITY ERROR TEST" SEVERITY NOTE;
      
		current_test_state	:= parity_error_mode;
		current_test_mode 	:= async_mode;

		TxClkSet(26000 ns);
		RxClkSet(26000 ns);

		--
		-- Init the Tx USART
		--
		WrTxCmd ("01010000");										-- Write a reset command, clear any errors from the last test
		
		WrTxMode ("01111101", "00000000", "00000000");		-- Initialize the mode
		
		WrTxCmd ("00100111");										-- Write a setup command
		
		--
		-- Init the Rx USART
		--
		WrRxCmd ("01010000");										-- Write a reset command, clear any errors from the last test
		
		WrRxMode ("01010101", "00000000", "00000000");		-- Initialize the mode
		
		WrRxCmd ("00100111");										-- Write a setup command

		CheckRxStat ("10000101");									-- Check Status, there should be no errors

		CheckRxRxd ("00000000");									-- Check for data, it should be zero

		TxWait(1);														-- Wait for one Tx clock time for the Rx UART
																			-- to complete configuration 
		IF ( tx_txrdy = '0' ) THEN 								-- Wait for tx_txrdy
			WAIT UNTIL ( tx_txrdy = '1' ); 
		END IF;

		WrTxTxD ("11000001");										-- Send a single character to generate a parity error 

		IF ( rx_rxrdy = '0' ) THEN 								-- Wait for the Rx USART to receive it
			WAIT UNTIL ( rx_rxrdy = '1' );
		ELSE
			WAIT UNTIL ( rx_rxrdy = '0' ); 
			WAIT UNTIL ( rx_rxrdy = '1' ); 
		END IF;

		CheckRxStat ("10001111");									-- Check Status, there should be a parity error only

		CheckRxRxd ("00000001");									-- Check for data

		WrRxCmd ("00110111");										-- Clear the parity error

		CheckRxStat ("10000101");									-- Check Status, the parity error should have cleared

		TxWait(8);														-- Wait for two clock times to let the transmitter finish


		--
		--	Start Overrun Error test
		--
		--		Asynchronous mode
		--		8 bit characters
		--		Even parity
		--		1 stop bit
		--		38.5 kbps Tx rate
		--		38.5 kbps Rx rate
		--		
		ASSERT false REPORT "START OVERRUN ERROR TEST" SEVERITY NOTE;
      
		current_test_state	:= overrun_error_mode;
		current_test_mode 	:= async_mode;

		TxClkSet(26000 ns);
		RxClkSet(26000 ns);

		--
		-- Init the Tx USART
		--
		WrTxCmd ("01010000");										-- Write a reset command, clear any errors from the last test
		
		WrTxMode ("01111101", "00000000", "00000000");		-- Initialize the mode
		
		WrTxCmd ("00100111");										-- Write a setup command
		
		--
		-- Init the Rx USART
		--
		WrRxCmd ("01010000");										-- Write a reset command, clear any errors from the last test
		
		WrRxMode ("01111101", "00000000", "00000000");		-- Initialize the mode
		
		WrRxCmd ("00100111");										-- Write a setup command

		CheckTxStat ("10000101");									-- Check the state of the Status register

		CheckTxRxd ("00000000");									-- Check the data

		TxWait(1);														-- Wait for one Tx clock time for the Rx UART
																			-- to complete configuration 

		IF ( tx_txrdy = '0' ) THEN 								-- Wait for tx_txrdy
			WAIT UNTIL ( tx_txrdy = '1' ); 
		END IF;

		WrTxTxD ("10101010");										-- Send the first character 

		IF ( rx_rxrdy = '0' ) THEN 								-- Wait for the Rx USART to receive it
			WAIT UNTIL ( rx_rxrdy = '1' );
		ELSE
			WAIT UNTIL ( rx_rxrdy = '0' ); 
			WAIT UNTIL ( rx_rxrdy = '1' ); 
		END IF;

		CheckRxStat ("10000111");									-- Check Status, there should be a character ready and no errors

		IF ( tx_txrdy = '0' ) THEN 								-- Wait for tx_txrdy
			WAIT UNTIL ( tx_txrdy = '1' ); 
		END IF;

		WrTxTxD ("01010101");										-- Send the second character 

		TxWait(12);														-- Wait for one start bit time + character time 
																			-- + parity bit time + one stop bit time + one bit time
																			-- since we can't use RXRDY as a reference. 

		CheckRxStat ("10010111");									-- Check Status, there should be a character ready and an
																			-- overrun error

		CheckRxRxd ("01010101");									-- Check for data, it should be the second character

		WrRxCmd ("00110111");										-- Clear the overrun error

		CheckRxStat ("10000101");									-- Check Status, the overrun error should have cleared


		--
		--	Start break test
		--
		--		Asynchronous mode
		--		8 bit characters
		--		Even parity
		--		1 stop bit
		--		38.5 kbps Tx rate
		--		38.5 kbps Rx rate
		--		
		ASSERT false REPORT "START BREAK TEST" SEVERITY NOTE;
      
		current_test_state	:= break_mode;
		current_test_mode 	:= async_mode;

		TxClkSet(26000 ns);
		RxClkSet(26000 ns);

		--
		-- Init the Tx USART
		--
		WrTxCmd ("01010000");										-- Write a reset command, clear any errors from the last test
		
		WrTxMode ("01111101", "00000000", "00000000");		-- Initialize the mode
		
		WrTxCmd ("00100111");										-- Write a setup command
		
		--
		-- Init the Rx USART
		--
		WrRxCmd ("01010000");										-- Write a reset command, clear any errors from the last test
		
		WrRxMode ("01111101", "00000000", "00000000");		-- Initialize the mode
		
		WrRxCmd ("00100111");										-- Write a setup command

		CheckRxStat ("10000101");									-- Check the state of the Status register

		CheckTxRxd ("00000000");									-- Check the data

		TxWait(1);														-- Wait for one Tx clock time for the Rx UART
																			-- to complete configuration 

		WAIT UNTIL ( nTxC_Stim = '1' ); 							-- Wait for the falling edge of Tx clock
		WAIT UNTIL ( nTxC_Stim = '0' ); 

		WrTxCmd ("00101111");										-- Assert a line break

		TxWait(10);														-- Wait for 10 Tx bit times:
																			-- (8 data bit + 1 start bit + 1 parity bit)

		CheckRxStat ("10000101");									-- Check the state of the Status register, the
																			-- overrun error bit should be set

		TxWait(11);														-- Wait for 11 Tx bit times:
																			-- (8 data bit + 1 start bit + 1 parity bit) + 1 stop bit

		IF ( rx_syn_brk = '0' ) THEN 								-- Check to make sure that the break was detected
			ASSERT false REPORT "*** Line break not detected by Rx USART ***" SEVERITY ERROR;
		END IF;

		TxWait(4);														-- Wait for a character time to make sure that everything
																			-- has settled.

		WrTxCmd ("00100111");										-- Clear the line break

		TxWait(1);														-- Wait for a character time to make sure that everything

		IF ( rx_syn_brk = '1' ) THEN 								-- Check to make sure that the break was cleared
			ASSERT false REPORT "*** Line break indication not cleared by Rx USART ***" SEVERITY ERROR;
		END IF;

		TxWait(4);														-- Wait for a character time to make sure that everything

		WrRxCmd ("00110111");										-- Clear the overrun error

		CheckRxStat ("10000101");									-- Check Status, the overrun error should have cleared


		--
		--	Start CTS flow control test
		--
		--		Asynchronous mode
		--		8 bit characters
		--		Even parity
		--		1 stop bit
		--		38.5 kbps Tx rate
		--		38.5 kbps Rx rate
		--		
		ASSERT false REPORT "START CTS FLOW CONTROL TEST" SEVERITY NOTE;
      
		current_test_state	:= cts_mode;
		current_test_mode 	:= async_mode;

		TxClkSet(26000 ns);
		RxClkSet(26000 ns);

		--
		-- Init the Tx USART
		--
		WrTxCmd ("01010000");										-- Write a reset command, clear any errors from the last test
		
		WrTxMode ("01111101", "00000000", "00000000");		-- Initialize the mode
		
		WrTxCmd ("00000111");										-- Write a setup command, turn off CTS by turning
																			-- the looped back RTS
		
		--
		-- Init the Rx USART
		--
		WrRxCmd ("01010000");										-- Write a reset command, clear any errors from the last test
		
		WrRxMode ("01111101", "00000000", "00000000");		-- Initialize the mode
		
		WrRxCmd ("00100111");										-- Write a setup command

		CheckRxStat ("10000101");									-- Check the state of the Status register

		TxWait(1);														-- Wait for one Tx clock time for the Rx UART
																			-- to complete configuration
																			
		WAIT UNTIL ( nTxC_Stim = '1' ); 							-- Wait for the falling edge of Tx clock
		WAIT UNTIL ( nTxC_Stim = '0' ); 

		WrTxTxD ("10101010");										-- Load the first character 

		TxWait(12);														-- Wait for one character time

		CheckRxStat ("10000101");									-- Check Status, there should be nothing in the Rx buffer

		WrTxCmd ("00100111"); 										-- Turn on CTS

		TxWait(2);														-- Wait for two Tx clock times to enable transmission

		WrTxCmd ("00000111"); 										-- Turn off CTS

		TxWait(12);														-- Wait for one character time

		WrTxTxD ("01010101");										-- Load the second character, but CTS is not asserted 
																			-- and transmission should not start.

		IF ( rx_rxrdy = '0' ) THEN 								-- Wait for the Rx USART to receive it
			WAIT UNTIL ( rx_rxrdy = '1' );
		END IF;

		CheckRxStat ("10000111");									-- Check Status, there should be a character ready and no errors

		CheckRxRxd ("10101010");									-- Check for data, it should be the first character

		TxWait(12);														-- Wait for one character time

		CheckRxStat ("10000101");									-- Check Status, there should be nothing in the Rx buffer

		WrTxCmd ("00100111"); 										-- Now turn on CTS to enable transmission of the second character

		IF ( rx_rxrdy = '0' ) THEN 								-- Wait for the Rx USART to receive it
			WAIT UNTIL ( rx_rxrdy = '1' );
		END IF;

		CheckRxStat ("10000111");									-- Check Status, there should be a character ready and no errors

		CheckRxRxd ("01010101");									-- Check for data, it should be the first character

		ASSERT false REPORT "TEST COMPLETE" SEVERITY NOTE;

		WAIT;

 	END PROCESS;

END MainTest;
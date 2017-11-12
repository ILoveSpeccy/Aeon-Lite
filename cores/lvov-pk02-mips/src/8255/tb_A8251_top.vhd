-- Altera Microperipheral Reference Design Version 0802
--**********************************************************************************************
--
--					System:	A8251
--				Component:	Testbench top level
--
--					  File:	tb_a8251_top.vhd

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

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;


ENTITY a8251top IS

END a8251top;


ARCHITECTURE struct OF a8251top IS

	-------------------------------------------------------------------------------
	-- SIGNAL declarations
	-------------------------------------------------------------------------------
	SIGNAL		clk       			: std_logic;
	SIGNAL		reset    			: std_logic;
	SIGNAL		txd_to_rxd       	: std_logic;
	SIGNAL		rxd_to_txd     	: std_logic;
	SIGNAL		nDTR_to_nDSR    	: std_logic;
	SIGNAL		nDSR_to_nDTR     	: std_logic;

	SIGNAL		tx_nRTS_to_nCTS   : std_logic;
	SIGNAL		tx_nWR     			: std_logic;
	SIGNAL		tx_nRD     			: std_logic;
	SIGNAL		tx_nCS     			: std_logic;
	SIGNAL		tx_CnD     			: std_logic;
	SIGNAL		tx_ExtSyncD			: std_logic;
	SIGNAL		tx_nTxC     		: std_logic;
	SIGNAL		tx_nRxC     		: std_logic;
	SIGNAL		tx_din     			: std_logic_vector(7 DOWNTO 0);
	SIGNAL		tx_txrdy     		: std_logic;
	SIGNAL		tx_txempty     	: std_logic;
	SIGNAL		tx_rxrdy     		: std_logic;
	SIGNAL		tx_syn_brk      	: std_logic;
	SIGNAL		tx_nEN       		: std_logic;
	SIGNAL		tx_dout     		: std_logic_vector(7 DOWNTO 0);
	
	SIGNAL		rx_nRTS_to_nCTS   : std_logic;
	SIGNAL		rx_nWR     			: std_logic;
	SIGNAL		rx_nRD     			: std_logic;
	SIGNAL		rx_nCS     			: std_logic;
	SIGNAL		rx_CnD     			: std_logic;
	SIGNAL		rx_ExtSyncD			: std_logic;
	SIGNAL		rx_nTxC     		: std_logic;
	SIGNAL		rx_nRxC     		: std_logic;
	SIGNAL		rx_din     			: std_logic_vector(7 DOWNTO 0);
	SIGNAL		rx_txrdy     		: std_logic;
	SIGNAL		rx_txempty     	: std_logic;
	SIGNAL		rx_rxrdy     		: std_logic;
	SIGNAL		rx_syn_brk      	: std_logic;
	SIGNAL		rx_nEN       		: std_logic;
	SIGNAL		rx_dout     		: std_logic_vector(7 DOWNTO 0);
	
	
	-------------------------------------------------------------------------------
	-- COMPONENT declarations
	-------------------------------------------------------------------------------
	
	COMPONENT a8251tb
	 
		PORT 
		(
			-- Common ports
      	clk       			: OUT std_logic;
      	reset					: OUT std_logic;
     	 	txd_to_rxd   		: IN  std_logic;
      	rxd_to_txd   		: IN  std_logic;
      	nDTR_to_nDSR   	: IN  std_logic;
      	nDSR_to_nDTR   	: IN  std_logic;

			-- Ports for the Tx USART
			tx_txrdy     		: IN  std_logic;
	      tx_txempty     	: IN  std_logic;
	      tx_rxrdy     		: IN  std_logic;
	      tx_syn_brk     	: IN  std_logic;
	      tx_nEN       		: IN  std_logic;
	      tx_dout     		: IN  std_logic_vector (7 DOWNTO 0);
	
	      tx_nWR     			: OUT std_logic;
	      tx_nRD     			: OUT std_logic;
	      tx_nCS     			: OUT std_logic;
	      tx_CnD     			: OUT std_logic;
      	tx_nRTS_to_nCTS   : IN  std_logic;
	      tx_ExtSyncD			: OUT std_logic;
	      tx_nTxC     		: OUT std_logic;
	      tx_nRxC     		: OUT std_logic;
	      tx_din     			: OUT std_logic_vector (7 DOWNTO 0);
	
			-- Ports for the Rx USART
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
		                                              
	END COMPONENT;
	
	
	COMPONENT a8251 
		PORT 
		(
	      clk       		: IN  std_logic;
	      reset    		: IN  std_logic;
	      nWR     			: IN  std_logic;
	      nRD     			: IN  std_logic;
	      nCS     			: IN  std_logic;
	      CnD     			: IN  std_logic;
	      nDSR     		: IN  std_logic;
	      nCTS     		: IN  std_logic;
	      ExtSyncD			: IN  std_logic;
	      nTxC     		: IN  std_logic;
	      nRxC     		: IN  std_logic;
	      rxd     			: IN  std_logic;
	      din				: IN  std_logic_vector(7 DOWNTO 0);
	
	      txd       		: OUT std_logic;
	      txrdy     		: OUT std_logic;
	      txempty     	: OUT std_logic;
	      rxrdy     		: OUT std_logic;
	      nDTR      		: OUT std_logic;
	      nRTS      		: OUT std_logic;
	      syn_brk      	: OUT std_logic;
	      nEN       		: OUT std_logic;
	      dout				: OUT std_logic_vector(7 DOWNTO 0)
		);
	END COMPONENT;
	
BEGIN
	
	-------------------------------------------------------------------------------
	-- COMPONENT instantiations
	-------------------------------------------------------------------------------
          
	i_a8251tb : a8251tb 
	PORT MAP
	(
	   clk       			=> clk,       	
	   reset					=>	reset,			
		txd_to_rxd			=>	txd_to_rxd,
		rxd_to_txd			=>	rxd_to_txd,
	   nDTR_to_nDSR   	=> nDTR_to_nDSR,    
	   nDSR_to_nDTR   	=> nDSR_to_nDTR,    
		tx_txrdy     		=> tx_txrdy,   
	   tx_txempty     	=> tx_txempty, 
	   tx_rxrdy     		=> tx_rxrdy,   
	   tx_syn_brk     	=> tx_syn_brk, 
	   tx_nEN       		=> tx_nEN,     
	   tx_dout     		=> tx_dout,    
	   tx_nWR     			=> tx_nWR,     
	   tx_nRD     			=> tx_nRD,     
	   tx_nCS     			=> tx_nCS,     
	   tx_CnD     			=> tx_CnD,     
	   tx_nRTS_to_nCTS   => tx_nRTS_to_nCTS,    
	   tx_ExtSyncD			=> tx_ExtSyncD,
	   tx_nTxC     		=> tx_nTxC,    
	   tx_nRxC     		=> tx_nRxC,    
	   tx_din     			=> tx_din,     
	   rx_txrdy     		=> rx_txrdy,   
	   rx_txempty     	=> rx_txempty, 
	   rx_rxrdy     		=> rx_rxrdy,   
	   rx_syn_brk     	=> rx_syn_brk, 
	   rx_nEN       		=> rx_nEN,     
	   rx_dout     		=> rx_dout,    
	   rx_nWR     			=> rx_nWR,     
	   rx_nRD     			=> rx_nRD,     
	   rx_nCS     			=> rx_nCS,     
	   rx_CnD     			=> rx_CnD,     
	   rx_nRTS_to_nCTS   => rx_nRTS_to_nCTS,    
	   rx_ExtSyncD			=> rx_ExtSyncD,
	   rx_nTxC     		=> rx_nTxC,    
	   rx_nRxC     		=> rx_nRxC,    
	   rx_din     			=> rx_din     
	);                    
	
	
	i_tx_a8251 : a8251 
	PORT MAP
	(
		clk       		=> clk,     
	   reset    		=> reset,   
	   nWR     			=> tx_nWR,     
	   nRD     			=> tx_nRD,     
	   nCS     			=> tx_nCS,     
	   CnD     			=> tx_CnD,     
	   nDSR     		=> nDSR_to_nDTR,    
	   nCTS     		=> tx_nRTS_to_nCTS,    
	   ExtSyncD			=> tx_ExtSyncD,
	   nTxC     		=> tx_nTxC,    
	   nRxC     		=> tx_nRxC,    
	   rxd     			=> rxd_to_txd,     
	   din				=> tx_din,		
	
	   txd       		=> txd_to_rxd,     
	   txrdy     		=> tx_txrdy,   
	   txempty     	=> tx_txempty, 
	   rxrdy     		=> tx_rxrdy,   
	   nDTR      		=> nDTR_to_nDSR,    
	   nRTS      		=> tx_nRTS_to_nCTS,    
	   syn_brk      	=> tx_syn_brk, 
	   nEN       		=> tx_nEN,     
	   dout				=> tx_dout		
	);
	
	
	i_rx_a8251 : a8251 
	PORT MAP
	(
		clk       		=> clk,     
	   reset    		=> reset,   
	   nWR     			=> rx_nWR,     
	   nRD     			=> rx_nRD,     
	   nCS     			=> rx_nCS,     
	   CnD     			=> rx_CnD,     
	   nDSR     		=> nDTR_to_nDSR,    
	   nCTS     		=> rx_nRTS_to_nCTS,    
	   ExtSyncD			=> rx_ExtSyncD,
	   nTxC     		=> rx_nTxC,    
	   nRxC     		=> rx_nRxC,    
	   rxd     			=> txd_to_rxd,     
	   din				=> rx_din,		
	
	   txd       		=> rxd_to_txd,     
	   txrdy     		=> rx_txrdy,   
	   txempty     	=> rx_txempty, 
	   rxrdy     		=> rx_rxrdy,   
	   nDTR      		=> nDSR_to_nDTR,    
	   nRTS      		=> rx_nRTS_to_nCTS,    
	   syn_brk      	=> rx_syn_brk, 
	   nEN       		=> rx_nEN,     
	   dout				=> rx_dout		
	);
	
END struct;
		
			
			
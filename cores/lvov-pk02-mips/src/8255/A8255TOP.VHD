-- Altera Microperipheral Reference Design Version 0802
--------------------------------------------------------
--
--  FILE NAME   :   a8255top.vhd

--  PROJECT     :   Altera A8255 UART
--  PURPOSE     :   This file contains the entity and architecture 
--                  for the A8255 top level model containing the
--                  A8255 model and its testbench
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
--
--
--------------------------------------------------------
----------------------------
-- Entity Declaration
----------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY a8255top IS
END a8255top;

-----------------------------
-- Architecture Body
-----------------------------
ARCHITECTURE struct OF a8255top IS


   SIGNAL  RESET_Stim : std_logic;
   SIGNAL  CLK_Stim   : std_logic;
   SIGNAL  nCS_Stim   : std_logic;
   SIGNAL  nRD_Stim   : std_logic;
   SIGNAL  nWR_Stim   : std_logic;
   SIGNAL  A_Stim     : std_logic_vector (1 DOWNTO 0);
   SIGNAL  DIN_Stim   : std_logic_vector (7 DOWNTO 0);
   SIGNAL  PAIN_Stim  : std_logic_vector (7 DOWNTO 0);
   SIGNAL  PBIN_Stim  : std_logic_vector (7 DOWNTO 0);
   SIGNAL  PCIN_Stim  : std_logic_vector (7 DOWNTO 0);
   SIGNAL  DOUT_Resp  : std_logic_vector (7 DOWNTO 0);
   SIGNAL  PAOUT_Resp : std_logic_vector (7 DOWNTO 0);
   SIGNAL  PAEN_Resp  : std_logic;
   SIGNAL  PBOUT_Resp : std_logic_vector (7 DOWNTO 0);
   SIGNAL  PBEN_Resp  : std_logic;
   SIGNAL  PCOUT_Resp : std_logic_vector (7 DOWNTO 0);
   SIGNAL  PCEN_Resp  : std_logic_vector (7 DOWNTO 0);

COMPONENT a8255 IS
   PORT(
      RESET : IN std_logic;
      CLK   : IN std_logic;
      nCS   : IN std_logic;
      nRD   : IN std_logic;
      nWR   : IN std_logic;
      A     : IN std_logic_vector (1 DOWNTO 0);
      DIN   : IN std_logic_vector (7 DOWNTO 0);
      PAIN  : IN std_logic_vector (7 DOWNTO 0);
      PBIN  : IN std_logic_vector (7 DOWNTO 0);
      PCIN  : IN std_logic_vector (7 DOWNTO 0);

      DOUT  : OUT std_logic_vector (7 DOWNTO 0);
      PAOUT : OUT std_logic_vector (7 DOWNTO 0);
      PAEN  : OUT std_logic;
      PBOUT : OUT std_logic_vector (7 DOWNTO 0);
      PBEN  : OUT std_logic;
      PCOUT : OUT std_logic_vector (7 DOWNTO 0);
      PCEN  : OUT std_logic_vector (7 DOWNTO 0)
   );

END COMPONENT;

COMPONENT a8255tb IS
  GENERIC (
          CLKOffset  : TIME :=   0 ns;
          CLKPeriod  : TIME := 200 ns;
          LoopDelay  : TIME :=  50 ns
          );
  PORT (
      RESET_Stim : OUT std_logic;
      CLK_Stim   : OUT std_logic;
      nCS_Stim   : OUT std_logic;
      nRD_Stim   : OUT std_logic;
      nWR_Stim   : OUT std_logic;
      A_Stim     : OUT std_logic_vector (1 DOWNTO 0);
      DIN_Stim   : OUT std_logic_vector (7 DOWNTO 0);
      PAIN_Stim  : OUT std_logic_vector (7 DOWNTO 0);
      PBIN_Stim  : OUT std_logic_vector (7 DOWNTO 0);
      PCIN_Stim  : OUT std_logic_vector (7 DOWNTO 0);

      DOUT_Resp  : IN std_logic_vector (7 DOWNTO 0);
      PAOUT_Resp : IN std_logic_vector (7 DOWNTO 0);
      PAEN_Resp  : IN std_logic;
      PBOUT_Resp : IN std_logic_vector (7 DOWNTO 0);
      PBEN_Resp  : IN std_logic;
      PCOUT_Resp : IN std_logic_vector (7 DOWNTO 0);
      PCEN_Resp  : IN std_logic_vector (7 DOWNTO 0)
       );
END COMPONENT;

BEGIN

UUT : a8255
   PORT MAP(
      RESET   => RESET_Stim, 
      CLK     => CLK_Stim  , 
      nCS     => nCS_Stim  , 
      nRD     => nRD_Stim  , 
      nWR     => nWR_Stim  , 
      A       => A_Stim    , 
      DIN     => DIN_Stim  , 
      PAIN    => PAIN_Stim , 
      PBIN    => PBIN_Stim , 
      PCIN    => PCIN_Stim , 

      DOUT    => DOUT_Resp , 
      PAOUT   => PAOUT_Resp, 
      PAEN    => PAEN_Resp , 
      PBOUT   => PBOUT_Resp, 
      PBEN    => PBEN_Resp , 
      PCOUT   => PCOUT_Resp, 
      PCEN    => PCEN_Resp  
   );

TB  : a8255tb
  GENERIC MAP(
          CLKOffset  =>   0 ns,
          CLKPeriod  => 400 ns,
          LoopDelay  => 100 ns
          )
  PORT MAP(
      RESET_Stim    => RESET_Stim,
      CLK_Stim      => CLK_Stim  , 
      nCS_Stim      => nCS_Stim  ,
      nRD_Stim      => nRD_Stim  ,
      nWR_Stim      => nWR_Stim  ,
      A_Stim        => A_Stim    ,
      DIN_Stim      => DIN_Stim  ,
      PAIN_Stim     => PAIN_Stim ,
      PBIN_Stim     => PBIN_Stim ,
      PCIN_Stim     => PCIN_Stim ,

      DOUT_Resp     => DOUT_Resp ,
      PAOUT_Resp    => PAOUT_Resp,
      PAEN_Resp     => PAEN_Resp ,
      PBOUT_Resp    => PBOUT_Resp,
      PBEN_Resp     => PBEN_Resp ,
      PCOUT_Resp    => PCOUT_Resp,
      PCEN_Resp     => PCEN_Resp 
       );

END struct;
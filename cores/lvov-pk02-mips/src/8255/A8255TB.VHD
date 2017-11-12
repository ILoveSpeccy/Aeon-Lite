-- Altera Microperipheral Reference Design Version 0802
--------------------------------------------------------
--
--  FILE NAME   :   a8255tb.vhd
--
--  PROJECT     :   Altera A8255 UART
--  PURPOSE     :   This file contains the entity and architecture 
--                  for the A8255 testbench. All registers and base 
--                  functionality are tested.
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
----------------------------------------------------------
----------------------------
-- Entity Declaration
----------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY a8255tb IS
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
END a8255tb;

-----------------------------
-- Architecture Body
-----------------------------
ARCHITECTURE MainTest OF a8255tb IS

SIGNAL PA : std_logic_vector (7 DOWNTO 0);
SIGNAL PB : std_logic_vector (7 DOWNTO 0);
SIGNAL PC : std_logic_vector (7 DOWNTO 0);

TYPE LoopBackModeType IS (Mode0, Mode1_AToB, Mode1_BToA, Mode2_AToB, Mode2_BToA);
SIGNAL LoopBackMode : LoopBackModeType;

BEGIN


  CLKClockPrc : PROCESS
    BEGIN
    CLK_Stim <= '0';
    WAIT FOR CLKOffset;
    LOOP
      CLK_Stim <= '0';
      WAIT FOR CLKPeriod/2;
      CLK_Stim <= '1';
      WAIT FOR CLKPeriod/2;
    END LOOP;
  END PROCESS CLKClockPrc;

  GeneralStimulus : PROCESS
    CONSTANT  PortA      : std_logic_vector(1 DOWNTO 0) := "00";
    CONSTANT  PortB      : std_logic_vector(1 DOWNTO 0) := "01";
    CONSTANT  PortC      : std_logic_vector(1 DOWNTO 0) := "10";
    CONSTANT  ControlReg : std_logic_vector(1 DOWNTO 0) := "11";
    CONSTANT  ChangeBit  : std_logic_vector(1 DOWNTO 0) := "11";

    -----------------------------------------------------------------------
    -- Define procedure to initialize inputs to default values and reset
    -----------------------------------------------------------------------
    PROCEDURE InitInputsAndReset IS
      BEGIN
        nCS_Stim  <= '1';
        nRD_Stim  <= '1';
        nWR_Stim  <= '1';
        A_Stim    <= "00";
        DIN_Stim  <= "00000000";

        RESET_Stim <= '1';
        WAIT FOR CLKPeriod * 2;
        RESET_Stim <= '0';
        WAIT FOR CLKPeriod * 2;
          
    END InitInputsAndReset;

    -----------------------------------------------------------------------
    -- Define procedure to read any register and compare to an expected value
    -----------------------------------------------------------------------
    PROCEDURE  ReadReg (Address      : IN std_logic_vector(1 DOWNTO 0);
                        ExpectedData : IN bit_vector(7 DOWNTO 0)
                        ) IS
      BEGIN
        A_Stim <= Address;
        WAIT FOR CLKPeriod;

        nCS_Stim <= '0';
        nRD_Stim <= '0';
        WAIT FOR CLKPeriod;

        ASSERT (DOUT_Resp = to_stdlogicvector(ExpectedData)) 
            REPORT "Read Data does not match Expected Data" SEVERITY WARNING;

        nCS_Stim <= '1';
        nRD_Stim <= '1';
        WAIT FOR CLKPeriod;
             
      END ReadReg;

    -----------------------------------------------------------------------
    -- Define procedure to write any register
    -----------------------------------------------------------------------
    PROCEDURE  WriteReg(Address  : IN std_logic_vector(1 DOWNTO 0);
                        Data     : IN bit_vector(7 DOWNTO 0)
                        ) IS
      BEGIN

        A_Stim <= Address;
        nCS_Stim <= '0';
        DIN_Stim <= to_stdlogicvector(Data); 
        WAIT FOR CLKPeriod;


        nWR_Stim <= '0';
        WAIT FOR CLKPeriod;

        nWR_Stim <= '1';
        WAIT FOR CLKPeriod * 2;

        nCS_Stim <= '1';
        WAIT FOR CLKPeriod * 2;
             
      END  WriteReg;


    ---------------------------------------------------------------
    -- Main Test Program
    ---------------------------------------------------------------
    BEGIN

      ASSERT false REPORT "START MODE 0 TEST" SEVERITY NOTE;

      -- Set Loop Back Mode
	  LoopBackMode <= Mode0;

      -- Reset chip and set inputs to default values
      InitInputsAndReset;

      -- Read Control Reg after reset
      ReadReg(ControlReg,   x"9B");    -- Resets to Mode 0, all inputs

      -- Load Port output registers before changing mode and direction
	  WriteReg(PortA, x"AA");
	  WriteReg(PortB, x"55");
	  WriteReg(PortC, x"F0");

	  -- Set Mode 0, Port A out, B in, C upper in, C lower out
	  WriteReg(ControlReg,   x"8A");

      -- Read all ports
      ReadReg(PortA,   x"AA");
      ReadReg(PortB,   x"AA");
      ReadReg(PortC,   x"00");

	  -- Set Mode 0, Port A in, B out, C upper out, C lower in
      WriteReg(ControlReg,   x"98");
      WriteReg(ControlReg,   x"91");

      -- Read all ports
      ReadReg(PortA,   x"55");
      ReadReg(PortB,   x"55");
      ReadReg(PortC,   x"FF");

      -- Load Port output registers with inverse
	  WriteReg(PortA, x"55");
	  WriteReg(PortB, x"AA");
	  WriteReg(PortC, x"0F");

      -- Read all ports
      ReadReg(PortA,   x"AA");
      ReadReg(PortB,   x"AA");
      ReadReg(PortC,   x"00");

	  -- Set Mode 0, Port A out, B in, C upper out, C lower in
      WriteReg(ControlReg,   x"83");

      -- Read all ports
      ReadReg(PortA,   x"55");
      ReadReg(PortB,   x"55");
      ReadReg(PortC,   x"00");

	  -- Test Port C Upper Set/Reset Bit Feature
      WriteReg(ChangeBit,   x"09");	  -- Set Port C (4)
      ReadReg(PortC,   x"11");

      WriteReg(ChangeBit,   x"0B");   -- Set Port C (5)
      ReadReg(PortC,   x"33");

      WriteReg(ChangeBit,   x"0D");   -- Set Port C (6)
      ReadReg(PortC,   x"77");

      WriteReg(ChangeBit,   x"0F");   -- Set Port C (7)
      ReadReg(PortC,   x"FF");

      WriteReg(ChangeBit,   x"08");	  -- Reset Port C (4)
      ReadReg(PortC,   x"EE");

      WriteReg(ChangeBit,   x"0A");   -- Reset Port C (5)
      ReadReg(PortC,   x"CC");

      WriteReg(ChangeBit,   x"0C");   -- Reset Port C (6)
      ReadReg(PortC,   x"88");

      WriteReg(ChangeBit,   x"0E");   -- Reset Port C (7)
      ReadReg(PortC,   x"00");

	  -- Set Mode 0, Port A out, B in, C upper in, C lower out
      WriteReg(ControlReg,   x"8A");
	  WriteReg(PortC, x"00");

	  -- Test Port C Lower Set/Reset Bit Feature
      WriteReg(ChangeBit,   x"01");	  -- Set Port C (0)
      ReadReg(PortC,   x"11");

      WriteReg(ChangeBit,   x"03");   -- Set Port C (1)
      ReadReg(PortC,   x"33");

      WriteReg(ChangeBit,   x"05");   -- Set Port C (2)
      ReadReg(PortC,   x"77");

      WriteReg(ChangeBit,   x"07");   -- Set Port C (3)
      ReadReg(PortC,   x"FF");

      WriteReg(ChangeBit,   x"00");	  -- Reset Port C (0)
      ReadReg(PortC,   x"EE");

      WriteReg(ChangeBit,   x"02");   -- Reset Port C (1)
      ReadReg(PortC,   x"CC");

      WriteReg(ChangeBit,   x"04");   -- Reset Port C (2)
      ReadReg(PortC,   x"88");

      WriteReg(ChangeBit,   x"06");   -- Reset Port C (3)
      ReadReg(PortC,   x"00");

------------------------------------------------------------
------------------------------------------------------------
      ASSERT false REPORT "START MODE 1 TEST" SEVERITY NOTE;

      -- Set Loop Back Mode
	  LoopBackMode <= Mode1_AToB;

      -- Reset chip and set inputs to default values
      InitInputsAndReset;

      -- Read Control Reg after reset
      ReadReg(ControlReg,   x"9B");    -- Resets to Mode 0, all inputs

	  -- Set Mode 1, Port A out, B in and check Port C Status
      WriteReg(ControlReg,   x"A6");
      WriteReg(ChangeBit,   x"0F");   -- Set Port C (7)
      WriteReg(ChangeBit,   x"02");   -- Reset Port C (1)
      WriteReg(ChangeBit,   x"00");	  -- Reset Port C (0)
      ReadReg(PortC,   x"80");		  -- Read Port C Status (only OBFA is set)

      -- Load Port output registers
	  WriteReg(PortA, x"11");

      -- Read all ports
      ReadReg(PortB,   x"11");
      ReadReg(PortC,   x"80");		  -- Read Port C Status (only OBFA is set)

      -- Do same test with interrupt enables on
      WriteReg(ChangeBit,   x"0D");   -- Set Port A Int Enable (Port C (6))
      WriteReg(ChangeBit,   x"05");   -- Set Port B Int Enable (Port C (2))
      ReadReg(PortC,   x"C4");		  -- Read Port C Status (OBFA, INTEA, and INTEB are set)
	  WriteReg(PortA,  x"88");
      ReadReg(PortC,   x"C7");		  -- Read Port C Status (everything but INTA is set)
      ReadReg(PortB,   x"88");
      ReadReg(PortC,   x"CC");		  -- Read Port C Status 

      -- Load Port output registers to bring down INTA
	  WriteReg(PortA, x"00");


-- REVERSE LOOPBACK DIRECTION

      -- Set Loop Back Mode
	  LoopBackMode <= Mode1_BToA;

      -- Reset chip and set inputs to default values
      InitInputsAndReset;

      -- Read Control Reg after reset
      ReadReg(ControlReg,   x"9B");    -- Resets to Mode 0, all inputs

	  -- Set Mode 1, Port A out, B in and check Port C Status
      WriteReg(ControlReg,   x"B4");
      WriteReg(ChangeBit,   x"0E");	  -- Reset Port C (7)
      WriteReg(ChangeBit,   x"0C");	  -- Reset Port C (6)
      WriteReg(ChangeBit,   x"0A");	  -- Reset Port C (5)
      WriteReg(ChangeBit,   x"08");	  -- Reset Port C (4)
      WriteReg(ChangeBit,   x"06");   -- Reset Port C (3)
      WriteReg(ChangeBit,   x"04");   -- Reset Port C (2)
      WriteReg(ChangeBit,   x"03");   -- Set Port C (1)
      WriteReg(ChangeBit,   x"00");	  -- Reset Port C (0)
      ReadReg(PortC,   x"02");		  -- Read Port C Status (only OBFB is set)

      -- Load Port output registers
	  WriteReg(PortB, x"33");

      -- Read all ports
      ReadReg(PortA,   x"33");
      ReadReg(PortC,   x"02");		  -- Read Port C Status (only OBFB is set)

      -- Do same test with interrupt enables on
      WriteReg(ChangeBit,   x"09");   -- Set Port A Int Enable (Port C (4))
      WriteReg(ChangeBit,   x"05");   -- Set Port B Int Enable (Port C (2))
      ReadReg(PortC,   x"16");		  -- Read Port C Status (OBFA, INTEA, and INTEB are set)
	  WriteReg(PortB,  x"44");
      ReadReg(PortC,   x"3E");		  -- Read Port C Status (everything but INTB is set)
      ReadReg(PortA,   x"44");
      ReadReg(PortC,   x"17");		  -- Read Port C Status (INTB and OBFB set)

      -- Load Port output registers	to bring down INTB
	  WriteReg(PortB, x"FF");

------------------------------------------------------------
------------------------------------------------------------
      ASSERT false REPORT "START MODE 2 TEST" SEVERITY NOTE;

      -- Set Loop Back Mode
	  LoopBackMode <= Mode2_AToB;

      -- Reset chip and set inputs to default values
      InitInputsAndReset;

      -- Read Control Reg after reset
      ReadReg(ControlReg,   x"9B");    -- Resets to Mode 0, all inputs

	  -- Set Port A to Mode 2, B in and check Port C Status
      WriteReg(ControlReg,   x"C6");
      WriteReg(ChangeBit,   x"0F");   -- Set Port C (7)	  --OBFA
      WriteReg(ChangeBit,   x"0C");   -- Reset Port C (6) --INTE1
      WriteReg(ChangeBit,   x"0A");   -- Reset Port C (5) --IBFA
      WriteReg(ChangeBit,   x"08");   -- Reset Port C (4) --INTE2
      WriteReg(ChangeBit,   x"06");   -- Reset Port C (3) --INTRA
      WriteReg(ChangeBit,   x"04");   -- Reset Port C (2) --INTEB
      WriteReg(ChangeBit,   x"02");   -- Reset Port C (1) --IBFB
      WriteReg(ChangeBit,   x"00");	  -- Reset Port C (0) --INTRB
      ReadReg(PortC,   x"80");		  -- Read Port C Status (only OBFA is set)

      -- Load Port output registers
	  WriteReg(PortA, x"11");

      -- Read all ports
      ReadReg(PortB,   x"11");
      ReadReg(PortC,   x"80");		  -- Read Port C Status (only OBFA is set)

      -- Do same test with interrupt enables on
      WriteReg(ChangeBit,   x"0D");   -- Set Port A Int Enable (Port C (6))
      WriteReg(ChangeBit,   x"05");   -- Set Port B Int Enable (Port C (2))
      ReadReg(PortC,   x"C4");		  -- Read Port C Status (OBFA, INTEA, and INTEB are set)
	  WriteReg(PortA,  x"88");
      ReadReg(PortC,   x"C7");		  -- Read Port C Status (everything but INTA is set)
      ReadReg(PortB,   x"88");
      ReadReg(PortC,   x"CC");		  -- Read Port C Status 

      -- Load Port output registers to bring down INTA
	  WriteReg(PortA, x"00");




      -- Set Loop Back Mode
	  LoopBackMode <= Mode2_BToA;

      -- Reset chip and set inputs to default values
      InitInputsAndReset;

      -- Read Control Reg after reset
      ReadReg(ControlReg,   x"9B");    -- Resets to Mode 0, all inputs

	  -- Set Port A to Mode 2, B out and check Port C Status
      WriteReg(ControlReg,   x"C4");
      WriteReg(ChangeBit,   x"0F");   -- Set Port C (7)	  --OBFA
      WriteReg(ChangeBit,   x"0C");   -- Reset Port C (6) --INTE1
      WriteReg(ChangeBit,   x"0A");   -- Reset Port C (5) --IBFA
      WriteReg(ChangeBit,   x"08");   -- Reset Port C (4) --INTE2
      WriteReg(ChangeBit,   x"06");   -- Reset Port C (3) --INTRA
      WriteReg(ChangeBit,   x"04");   -- Reset Port C (2) --INTEB
      WriteReg(ChangeBit,   x"03");   -- Set Port C (1)   --OBFB
      WriteReg(ChangeBit,   x"00");	  -- Reset Port C (0) --INTRB
      ReadReg(PortC,   x"82");		  -- Read Port C Status (OBFA, OBFB is set)

      -- Load Port output registers
	  WriteReg(PortB, x"66");

      -- Read all ports
      ReadReg(PortA,   x"66");
      ReadReg(PortC,   x"82");		  -- Read Port C Status (only OBFA is set)

      -- Do same test with interrupt enables on
      WriteReg(ChangeBit,   x"09");   -- Set Port A Int Enable (Port C (4))
      WriteReg(ChangeBit,   x"05");   -- Set Port B Int Enable (Port C (2))
      ReadReg(PortC,   x"96");		  -- Read Port C Status (OBFA, INTEA2, and INTEB are set)
	  WriteReg(PortB,  x"88");
      ReadReg(PortC,   x"BE");		  -- Read Port C Status (everything but INTRB is set)
      ReadReg(PortA,   x"88");
      ReadReg(PortC,   x"97");		  -- Read Port C Status 

      -- Load Port output registers to bring down INTA
	  WriteReg(PortB, x"00");

      ASSERT false REPORT "END OF TEST" SEVERITY NOTE;
      WAIT;
  END PROCESS GeneralStimulus;

  ------------------------------------------------------------
  -- Process to loop PA to PB, and PC upper to PC lower
  ------------------------------------------------------------
  OutputBufferPrc : Process    (PAEN_Resp, PBEN_Resp, PCEN_Resp, PAOUT_Resp, PBOUT_Resp, PCOUT_Resp)
    BEGIN
        IF (PAEN_Resp = '1') THEN
           PA <= PAOUT_Resp AFTER LoopDelay;
        ELSE
           PA <= "ZZZZZZZZ" AFTER LoopDelay;
        END IF;

        IF (PBEN_Resp = '1') THEN
           PB <= PBOUT_Resp AFTER LoopDelay;
        ELSE
           PB <= "ZZZZZZZZ" AFTER LoopDelay;
        END IF;

        FOR I IN 0 TO 7 LOOP
           IF (PCEN_Resp(I) = '1') THEN
             PC(I) <= PCOUT_Resp(I) AFTER LoopDelay;
           ELSE
              PC(I) <= 'Z' AFTER LoopDelay;
           END IF;
		END LOOP;

  END PROCESS OutputBufferPrc;

--  -- Output buffer assignments
  PAIN_Stim <= PA;
  PBIN_Stim <= PB;
  PCIN_Stim <= PC;
  
  -- Loop back assignments
  LoopBackPrc : Process    (LoopBackMode, PA, PB, PC)
    BEGIN
        PAIN_Stim <= PB ;
        PBIN_Stim <= PA ;
        IF (LoopBackMode = Mode0) THEN
           PCIN_Stim (7 DOWNTO 4) <= PC (3 DOWNTO 0) ;
           PCIN_Stim (3 DOWNTO 0) <= PC (7 DOWNTO 4) ;
        ELSIF (LoopBackMode = Mode1_BToA) THEN
		   PCIN_Stim (7) <= PC (7) ;
		   PCIN_Stim (6) <= PC (6) ;
		   PCIN_Stim (5) <= PC (5) ;
           PCIN_Stim (4) <= PC (1) ;      -- OBFB to STBA
		   PCIN_Stim (3) <= PC (3) ;
           PCIN_Stim (2) <= NOT PC (5) ;  -- IBFA to ACKB
		   PCIN_Stim (1) <= PC (1) ;
		   PCIN_Stim (0) <= PC (0) ;
        ELSIF (LoopBackMode = Mode2_BToA) THEN
		   PCIN_Stim (7) <= PC (7) ;
		   PCIN_Stim (6) <= '1';
		   PCIN_Stim (5) <= PC (5) ;
           PCIN_Stim (4) <= PC (1)  ;      -- OBFB to STBA
		   PCIN_Stim (3) <= PC (3) ;
           PCIN_Stim (2) <= NOT PC (5) ;  -- IBFA to ACKB
		   PCIN_Stim (1) <= PC (1) ;
		   PCIN_Stim (0) <= PC (0) ;
        ELSIF (LoopBackMode = Mode1_AToB) THEN
		   PCIN_Stim (0) <= PC (0) ;
		   PCIN_Stim (1) <= PC (1) ;
           PCIN_Stim (2) <= PC (7) ;      -- OBFA to STBB
		   PCIN_Stim (3) <= PC (3) ;				     
		   PCIN_Stim (4) <= PC (4) ;
		   PCIN_Stim (5) <= PC (5) ;
           PCIN_Stim (6) <= NOT PC (1) ;  -- IBFB to ACKA
		   PCIN_Stim (7) <= PC (7) ;
        ELSIF (LoopBackMode = Mode2_AToB) THEN
		   PCIN_Stim (0) <= PC (0) ;
		   PCIN_Stim (1) <= PC (1) ;
           PCIN_Stim (2) <= PC (7) ;      -- OBFA to STBB
		   PCIN_Stim (3) <= PC (3) ;				     
		   PCIN_Stim (4) <= '1';
		   PCIN_Stim (5) <= PC (5) ;
           PCIN_Stim (6) <= NOT PC (1) ;  -- IBFB to ACKA
		   PCIN_Stim (7) <= PC (7) ;
        END IF;


  END PROCESS LoopBackPrc;

END MainTest;

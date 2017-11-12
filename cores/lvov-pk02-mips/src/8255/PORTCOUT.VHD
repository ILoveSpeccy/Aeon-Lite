-- Altera Microperipheral Reference Design Version 0802
-------------------------------------------------------
--
--  FILE NAME   :   portcout.vhd

--
--  PROJECT     :   Altera A8255 Peripheral Interface Adapter
--  PURPOSE     :   This file contains the entity and architecture 
--                  for the Port C Output Register of the A8255 design.
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
--
--------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY portcout IS
   PORT(
      RESET         : IN std_logic;
      CLK           : IN std_logic;
      DIN           : IN std_logic_vector (7 DOWNTO 0);
      PCIN          : IN std_logic_vector (7 DOWNTO 0);
      ControlReg    : IN std_logic_vector (7 DOWNTO 0);
      PortARead     : IN std_logic;
      PortBRead     : IN std_logic;
      PortAWrite    : IN std_logic;
      PortBWrite    : IN std_logic;
      PortCOverride : IN std_logic;
      PortCOutLd    : IN std_logic_vector (7 DOWNTO 0);
      PortCStatus   : OUT std_logic_vector (7 DOWNTO 0);
      PCOUT         : OUT std_logic_vector (7 DOWNTO 0)
   );

END portcout;


ARCHITECTURE rtl OF portcout IS

   SIGNAL    PortCOutRegD    : std_logic_vector(7 DOWNTO 0);
   SIGNAL    PortCOutRegQ    : std_logic_vector(7 DOWNTO 0);
   SIGNAL    ModeA           : std_logic_vector (1 DOWNTO 0);
   SIGNAL    ModeB           : std_logic;
   SIGNAL    PortA_IO        : std_logic;
   SIGNAL    PortB_IO        : std_logic;
   SIGNAL	 RisePortAWriteQ : std_logic;
   SIGNAL	 RisePortBWriteQ : std_logic;
   SIGNAL	 RisePortAReadQ  : std_logic;
   SIGNAL	 RisePortBReadQ  : std_logic;
   SIGNAL	 RisePCIN6Q      : std_logic;
   SIGNAL	 RisePCIN4Q      : std_logic;
   SIGNAL	 RisePCIN2Q      : std_logic;
   SIGNAL	 RisePortAWrite  : std_logic;
   SIGNAL	 RisePortBWrite  : std_logic;
   SIGNAL	 RisePortARead   : std_logic;
   SIGNAL	 RisePortBRead   : std_logic;
   SIGNAL	 RisePCIN6       : std_logic;
   SIGNAL    RisePCIN4       : std_logic;
   SIGNAL    RisePCIN2       : std_logic;


   BEGIN

	  PCOUT       <= PortCOutRegQ;
      ModeA       <= ControlReg (6 DOWNTO 5);
      ModeB       <= ControlReg (2);
      PortA_IO    <= ControlReg (4);
      PortB_IO    <= ControlReg (1);

	  PortCStatusProc: PROCESS ( ModeA, ModeB, PortA_IO, PCIN, PortCOutRegQ )
	     BEGIN
		    PortCStatus(7) <= PCIN(7);

            IF (ModeA = "01" AND PortA_IO = '0') THEN	   -- Mode 1
		       PortCStatus(6) <= PortCoutRegQ(6);
			ELSIF (ModeA(1) = '1') THEN   				   -- Mode 2
		       PortCStatus(6) <= PortCoutRegQ(6);
			ELSE
		       PortCStatus(6) <= PCIN(6);
			END IF;

		    PortCStatus(5) <= PCIN(5);

            IF (ModeA = "01" AND PortA_IO = '1') THEN	   -- Mode 1
		       PortCStatus(4) <= PortCoutRegQ(4);
			ELSIF (ModeA(1) = '1') THEN   				   -- Mode 2
		       PortCStatus(4) <= PortCoutRegQ(4);
			ELSE
		       PortCStatus(4) <= PCIN(4);
			END IF;

		    PortCStatus(3) <= PCIN(3);

            IF (ModeB = '1') THEN	                       -- Mode 1
		       PortCStatus(2) <= PortCoutRegQ(2);
			ELSE
		       PortCStatus(2) <= PCIN(2);
			END IF;

		    PortCStatus(1) <= PCIN(1);
		    PortCStatus(0) <= PCIN(0);
	     END PROCESS;


      PortCDataProc: PROCESS ( ModeA, PortA_IO, PortB_IO, ModeB, PortCOverride,
                               PortAWrite, PortBWrite, PortARead, PortBRead,
                               RisePortAWrite, RisePortBWrite, RisePortARead, RisePortBRead,
                               PortCOutLd, PortCOutRegQ, DIN,
                               PCIN, RisePCIN2, RisePCIN4, RisePCIN6 )

         BEGIN

            IF (ModeB = '0') THEN				                            -- Mode 0
			   IF (PortCOutLd (0) = '0') THEN								-- Load from bus and bit set/reset
                  PortCOutRegD (0)  <= DIN(0);
			   ELSE
                  PortCOutRegD (0)  <= PortCOutRegQ (0);
			   END IF;
			ELSIF (ModeB = '1') THEN								        -- Mode 1
               IF ( PortCOutLd (0) = '0' AND PortCOverride = '1')  THEN     -- Load for the set/reset command
                  PortCOutRegD (0)  <= DIN(0);								-- Mode 1 Output
			   ELSIF (PortB_IO = '0') THEN
			      IF (PortBWrite = '0') THEN								-- Reset INTRB on write strobe
                     PortCOutRegD (0)  <=  '0';
				  ELSIF (PortBWrite = '1' AND RisePCIN2 = '1' 				-- Set INTRB on rising edge of ACKB
				         AND PortCOutRegQ (1) = '1') THEN
                     PortCOutRegD (0)  <= PortCOutRegQ (2);
				  ELSE
                     PortCOutRegD (0)  <= PortCOutRegQ (0);
				  END IF;
			   ELSE															-- Mode 1 Input
			      IF (PortBRead = '0' AND PortCOutRegQ(1) = '1') THEN		-- Reset INTRB on read strobe
                     PortCOutRegD (0)  <=  '0';
				  ELSIF (RisePCIN2 = '1' AND PortCOutRegQ (1) = '1') THEN	-- Set INTRB on rising edge of STBB
                     PortCOutRegD (0)  <= PortCOutRegQ (2);
				  ELSE
                     PortCOutRegD (0)  <= PortCOutRegQ (0);
				  END IF;
               END IF;
			ELSE
                  PortCOutRegD (0)  <= PortCOutRegQ (0);
			END IF;


            IF (ModeB = '0') THEN				                           -- Mode 0
			   IF (PortCOutLd (1) = '0') THEN
                  IF ( PortCOverride = '1')  THEN                     	   
                     PortCOutRegD (1)  <= DIN(0);						   -- Load from bit set/reset
			      ELSE
                     PortCOutRegD (1)  <= DIN(1);						   -- Load from bus
                  END IF;
			   ELSE
                  PortCOutRegD (1)  <= PortCOutRegQ (1);
			   END IF;
			ELSIF (ModeB = '1') THEN								       -- Mode 1
               IF ( PortCOutLd (1) = '0' AND PortCOverride = '1')  THEN    -- Load from bit set/reset
                  PortCOutRegD (1)  <= DIN(0);
			   ELSIF (PortB_IO = '0') THEN								   -- Mode 1 Output
			      IF (RisePortBWrite = '1') THEN						   -- Reset OBFB on rising edge of write strobe
                     PortCOutRegD (1)  <=  '0';
				  ELSIF (PCIN(2) = '0') THEN							   -- Set OBFB when ACKB goes low
                     PortCOutRegD (1)  <= '1';
				  ELSE
                     PortCOutRegD (1)  <= PortCOutRegQ (1);
				  END IF;
			   ELSE														  -- Mode 1 Input
			      IF (RisePortBRead = '1' AND PortCOutRegQ(0) = '0') THEN -- Reset IBFB on rising edge of read strobe
                     PortCOutRegD (1)  <=  '0';
				  ELSIF (PCIN(2) = '0') THEN							  -- Set IBFB when STBB goes low
                     PortCOutRegD (1)  <= '1';
				  ELSE
                     PortCOutRegD (1)  <= PortCOutRegQ (1);
				  END IF;
               END IF;
			ELSE
                  PortCOutRegD (1)  <= PortCOutRegQ (1);
			END IF;


            IF (PortCOutLd (2) = '0') THEN				                  -- All Modes
               IF ( PortCOverride = '1')  THEN                     
                  PortCOutRegD (2)  <= DIN(0);							  -- Load INTEB from bit set/reset
			   ELSE
                  PortCOutRegD (2)  <= DIN(2);							  -- Load INTEB from bus
               END IF;
			ELSE
                  PortCOutRegD (2)  <= PortCOutRegQ (2);
			END IF;



            IF (ModeA = "00") THEN										  -- Mode 0

			   IF (PortCOutLd (3) = '0') THEN
                  IF ( PortCOverride = '1')  THEN
                     PortCOutRegD (3)  <= DIN(0);                         -- Load from bit set/reset
			      ELSE
                     PortCOutRegD (3)  <= DIN(3);						  -- Load from bus
                  END IF;
			   ELSE
                  PortCOutRegD (3)  <= PortCOutRegQ (3);
			   END IF;
			ELSIF (ModeA = "01") THEN								      -- Mode 1
               IF ( PortCOutLd (3) = '0' AND PortCOverride = '1')  THEN
                  PortCOutRegD (3)  <= DIN(0);							  -- Load from bit set/reset
			   ELSIF (PortA_IO = '0') THEN								  -- Mode 1 Output
			      IF (PortAWrite = '0') THEN							  
                     PortCOutRegD (3)  <=  '0';							  -- Reset INTRA on write strobe
				  ELSIF (PortAWrite = '1' AND RisePCIN6 = '1' 			  -- Set INTRA on rising edge of ACKA
				         AND PortCOutRegQ (7) = '1') THEN
                     PortCOutRegD (3)  <= PortCOutRegQ (6);
				  ELSE
                     PortCOutRegD (3)  <= PortCOutRegQ (3);
				  END IF;
			   ELSE														  -- Mode 1 Input
			      IF (PortARead = '0' AND PortCOutRegQ(5) = '1') THEN
                     PortCOutRegD (3)  <=  '0';							  -- Reset INTRA on read strobe
				  ELSIF (RisePCIN4 = '1' AND PortCOutRegQ (5) = '1') THEN
                     PortCOutRegD (3)  <= PortCOutRegQ (4);				  -- Set INTRA on rising edge of STBA
				  ELSE
                     PortCOutRegD (3)  <= PortCOutRegQ (3);
				  END IF;
               END IF;
			ELSIF (ModeA(1) = '1') THEN								      -- Mode 2
               IF ( PortCOutLd (3) = '0' AND PortCOverride = '1')  THEN   
                  PortCOutRegD (3)  <= DIN(0);							  -- Load from bit set/reset
			   ELSE
			      IF (PortAWrite = '0' OR PortARead = '0') THEN			  -- Reset INTRA on either read or write strobes
                     PortCOutRegD (3)  <=  '0';
				  ELSIF (PortAWrite = '1' AND RisePCIN6 = '1' 
				         AND PortCOutRegQ (7) = '1') THEN                 -- Set INTRA on rising edge of ACKA
                     PortCOutRegD (3)  <= PortCOutRegQ (6);
				  ELSIF (PortARead = '1' AND RisePCIN4 = '1' 			  -- OR
				         AND PortCOutRegQ (5) = '1') THEN				  -- Set INTRA on rising edge of STBA
                     PortCOutRegD (3)  <= PortCOutRegQ (4);
				  ELSE
                     PortCOutRegD (3)  <= PortCOutRegQ (3);
				  END IF;
               END IF;
			ELSE
                  PortCOutRegD (3)  <= PortCOutRegQ (3);
			END IF;

            IF (ModeA = "00" OR (ModeA = "01" AND PortA_IO = '0')) THEN	  -- Mode 0 and Mode 1 Output
			   IF (PortCOutLd (4) = '0') THEN
                  IF ( PortCOverride = '1')  THEN
                     PortCOutRegD (4)  <= DIN(0);						  -- Load INTEA from bit set/reset
			      ELSE													  
                     PortCOutRegD (4)  <= DIN(4);						  -- Load INTEA from bus
                  END IF;
			   ELSE
                  PortCOutRegD (4)  <= PortCOutRegQ (4);
			   END IF;													  -- Mode 1 Input and Mode 2
			ELSE
               IF ( PortCOutLd (4) = '0' AND PortCOverride = '1')  THEN
                  PortCOutRegD (4)  <= DIN(0);							  -- Load INTEA(2) from bit set/reset
			   ELSE
                  PortCOutRegD (4)  <= PortCOutRegQ (4);
               END IF;
			END IF;

            IF (ModeA = "00"OR (ModeA = "01" AND PortA_IO = '0')) THEN	  -- Mode 0 and Mode 1 Output
			   IF (PortCOutLd (5) = '0') THEN
                  IF ( PortCOverride = '1')  THEN
                     PortCOutRegD (5)  <= DIN(0);						  -- Load from bit set/reset
			      ELSE
                     PortCOutRegD (5)  <= DIN(5);						  -- Load from bus
                  END IF;
			   ELSE
                  PortCOutRegD (5)  <= PortCOutRegQ (5);
			   END IF;
			ELSIF (ModeA = "01") THEN								      -- Mode 1
               IF ( PortCOutLd (5) = '0' AND PortCOverride = '1')  THEN   
                  PortCOutRegD (5)  <= DIN(0);							  -- Load from bit set/reset
			   ELSIF (PortA_IO = '1') THEN								  -- Mode 1 Input
			      IF (RisePortARead = '1' AND PortCOutRegQ(3) = '0') THEN
                     PortCOutRegD (5)  <=  '0';							  -- Reset IBFA on rising edge of read strobe
				  ELSIF (PCIN(4) = '0') THEN
                     PortCOutRegD (5)  <= '1';							  -- Set IBFA when STBA goes low
				  ELSE
                     PortCOutRegD (5)  <= PortCOutRegQ (5);
				  END IF;
			   ELSE
                  PortCOutRegD (5)  <= PortCOutRegQ (5);
               END IF;
			ELSIF (ModeA(1) = '1') THEN								      -- Mode 2
               IF ( PortCOutLd (5) = '0' AND PortCOverride = '1')  THEN
                  PortCOutRegD (5)  <= DIN(0);							  -- Load from bit set/reset
			   ELSE
			      IF (RisePortARead = '1' AND PortCOutRegQ(3) = '0') THEN
                     PortCOutRegD (5)  <=  '0';							  -- Reset IBFA on rising edge of read strobe
				  ELSIF (PCIN(4) = '0') THEN
                     PortCOutRegD (5)  <= '1';							  -- Set IBFA when STBA goes low
				  ELSE
                     PortCOutRegD (5)  <= PortCOutRegQ (5);
				  END IF;
               END IF;
			ELSE
               PortCOutRegD (5)  <= PortCOutRegQ (5);
			END IF;


            IF (ModeA = "00" OR (ModeA = "01" AND PortA_IO = '1')) THEN	  -- Mode 0 and Mode 1 Input
			   IF (PortCOutLd (6) = '0') THEN
                  IF ( PortCOverride = '1')  THEN
                     PortCOutRegD (6)  <= DIN(0);                         -- Load INTEA from bit set/reset
			      ELSE
                     PortCOutRegD (6)  <= DIN(6);						  -- Load INTEA from bus
                  END IF;
			   ELSE
                  PortCOutRegD (6)  <= PortCOutRegQ (6);
			   END IF;
			ELSE
               IF ( PortCOutLd (6) = '0' AND PortCOverride = '1')  THEN
                  PortCOutRegD (6)  <= DIN(0);                            -- Load INTEA(1) from bit set/reset
			   ELSE
                  PortCOutRegD (6)  <= PortCOutRegQ (6);
               END IF;
			END IF;


            IF (ModeA = "00" OR (ModeA = "01" AND PortA_IO = '1')) THEN	  -- Mode 0 and Mode 1 Input
			   IF (PortCOutLd (7) = '0') THEN
                  IF ( PortCOverride = '1')  THEN
                     PortCOutRegD (7)  <= DIN(0);                         -- Load from bit set/reset
			      ELSE
                     PortCOutRegD (7)  <= DIN(7);                         -- Load from bus
                  END IF;
			   ELSE
                  PortCOutRegD (7)  <= PortCOutRegQ (7);
			   END IF;
			ELSIF (ModeA = "01") THEN								      -- Mode 1
               IF ( PortCOutLd (7) = '0' AND PortCOverride = '1')  THEN
                  PortCOutRegD (7)  <= DIN(0);
			   ELSIF (PortA_IO = '0') THEN                                -- Mode 1 Output
			      IF (RisePortAWrite = '1') THEN
                     PortCOutRegD (7)  <=  '0';							  -- Reset OBFA on rising edge of Write strobe
				  ELSIF (PCIN(6) = '0') THEN
                     PortCOutRegD (7)  <= '1';							  -- Set OBFA when ACKA goes low
				  ELSE
                     PortCOutRegD (7)  <= PortCOutRegQ (7);
				  END IF;
			   ELSE
                  PortCOutRegD (7)  <= PortCOutRegQ (7);
               END IF;
			ELSIF (ModeA(1) = '1') THEN								      -- Mode 2
               IF ( PortCOutLd (7) = '0' AND PortCOverride = '1')  THEN
                  PortCOutRegD (7)  <= DIN(0);                            -- Load from bit set/reset
			   ELSE
			      IF (RisePortAWrite = '1') THEN						  -- Reset OBFA on rising edge of write strobe
                     PortCOutRegD (7)  <=  '0';
				  ELSIF (PCIN(6) = '0') THEN                              -- Set OBFA when ACKA goes low
                     PortCOutRegD (7)  <= '1';
				  ELSE
                     PortCOutRegD (7)  <= PortCOutRegQ (7);
				  END IF;
               END IF;
			ELSE
                  PortCOutRegD (7)  <= PortCOutRegQ (7);
			END IF;

  END PROCESS;

      
-- Process for Port C output register
      PortCOutRegSyncProc: PROCESS ( RESET, CLK )

         BEGIN

			IF ( RESET = '1') THEN
			   PortCoutRegQ <= "00000000";
            ELSIF ( CLK'EVENT and CLK = '1')  THEN
               PortCoutRegQ     <= PortCOutRegD;
            END IF;


         END PROCESS;


-- Process for edge detect registers

      EdgeDetectSyncProc: PROCESS ( RESET, CLK )

         BEGIN

			IF ( RESET = '1') THEN
               RisePortAWriteQ     <= '0';
               RisePortBWriteQ     <= '0';
               RisePortAReadQ      <= '0';
               RisePortBReadQ      <= '0';
               RisePCIN6Q          <= '0';
               RisePCIN4Q          <= '0';
               RisePCIN2Q          <= '0';
            ELSIF ( CLK'EVENT and CLK = '1')  THEN
               RisePortAWriteQ     <= PortAWrite;
               RisePortBWriteQ     <= PortBWrite;
               RisePortAReadQ      <= PortARead;
               RisePortBReadQ      <= PortBRead;
               RisePCIN6Q          <= PCIN(6);
               RisePCIN4Q          <= PCIN(4);
               RisePCIN2Q          <= PCIN(2);
            END IF;


         END PROCESS;


-- Assignments for edge detect signals
     RisePortAWrite     <= PortAWrite AND NOT RisePortAWriteQ;
     RisePortBWrite     <= PortBWrite AND NOT RisePortBWriteQ;
     RisePortARead      <= PortARead  AND NOT RisePortAReadQ;
     RisePortBRead      <= PortBRead  AND NOT RisePortBReadQ;
     RisePCIN6          <= PCIN(6)    AND NOT RisePCIN6Q;
     RisePCIN4          <= PCIN(4)    AND NOT RisePCIN4Q;
     RisePCIN2          <= PCIN(2)    AND NOT RisePCIN2Q;
   END rtl;

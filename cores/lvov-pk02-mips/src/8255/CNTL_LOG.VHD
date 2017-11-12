-- Altera Microperipheral Reference Design Version 0802
--------------------------------------------------------
--
--  FILE NAME   :   cntl_log.vhd
--
--  PROJECT     :   Altera A8255 Peripheral Interface Adapter
--  PURPOSE     :   This file contains the entity and architecture 
--                  for the data output multiplexer of the A8255 design.
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
--------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY cntl_log IS
   PORT(
      RESET         : IN std_logic;
      CLK           : IN std_logic;
      nCS           : IN std_logic;
      nRD           : IN std_logic;
      nWR           : IN std_logic;
      A             : IN std_logic_vector (1 DOWNTO 0);
      DIN           : IN std_logic_vector (7 DOWNTO 0);
      PCIN          : IN std_logic_vector (7 DOWNTO 0);
      PAEN          : OUT std_logic;
      PBEN          : OUT std_logic;
      PCEN          : OUT std_logic_vector (7 DOWNTO 0);
      DOUTSelect    : OUT std_logic_vector (2 DOWNTO 0);
      ControlReg    : OUT std_logic_vector (7 DOWNTO 0);
      PortARead     : OUT std_logic;
      PortBRead     : OUT std_logic;
      PortAWrite    : OUT std_logic;
      PortBWrite    : OUT std_logic;
      PortAOutLd    : OUT std_logic;
      PortBOutLd    : OUT std_logic;
      PortCOverride : OUT std_logic;
      PortCOutLd    : OUT std_logic_vector (7 DOWNTO 0)
   );

END cntl_log;


ARCHITECTURE rtl OF cntl_log IS

   SIGNAL    ControlRegD     : std_logic_vector(6 DOWNTO 0);
   SIGNAL    ControlRegQ     : std_logic_vector(6 DOWNTO 0);
   SIGNAL    ModeA           : std_logic_vector (1 DOWNTO 0);
   SIGNAL    ModeB           : std_logic;
   SIGNAL    PortA_IO        : std_logic;
   SIGNAL    PortB_IO        : std_logic;
   SIGNAL    PortCUp_IO      : std_logic;
   SIGNAL    PortCLow_IO     : std_logic;
   SIGNAL    ControlRegWrite : std_logic;



   BEGIN

      ControlReg       <= '1' & ControlRegQ;
      ModeA            <= ControlRegQ (6 DOWNTO 5);
      ModeB            <= ControlRegQ (2);
      PortA_IO         <= ControlRegQ (4);
      PortB_IO         <= ControlRegQ (1);
      PortCUp_IO       <= ControlRegQ (3);
      PortCLow_IO      <= ControlRegQ (0);

      PortAOutLd       <= '0' WHEN nCS = '0' AND A = "00" AND nWR = '0' ELSE
                          '1';
      PortBOutLd       <= '0' WHEN nCS = '0' AND A = "01" AND nWR = '0' ELSE
                          '1';
	  PortARead        <= nCS  OR nRD OR A(1) OR      A(0);
	  PortBRead        <= nCS  OR nRD OR A(1) OR (NOT A(0));
	  PortAWrite       <= nCS  OR nWR  OR A(1) OR      A(0);
	  PortBWrite       <= nCS  OR nWR  OR A(1) OR (NOT A(0));
	  ControlRegWrite  <= nCS  OR nWR  OR (NOT A(1)) OR (NOT A(0)) OR (NOT DIN(7));


   ControlLogicProc: PROCESS ( nCS , nWR , A, DIN, ModeA, ModeB, 
                               PortA_IO, PortB_IO, PortCLow_IO, PortCUp_IO,
                               PCIN, ControlRegWrite, ControlRegQ )

   BEGIN

         IF (ModeB = '0') THEN
             PBEN        <= NOT PortB_IO;
			 IF (ModeA(1) = '1') THEN
                PCEN (3 DOWNTO 0) <= '1' & 
                                     std_logic'(NOT PortCLow_IO) & 
                                     std_logic'(NOT PortCLow_IO) & 
                                     std_logic'(NOT PortCLow_IO);
			 ELSE
                PCEN (3 DOWNTO 0) <= std_logic'(NOT PortCLow_IO) & 
                                     std_logic'(NOT PortCLow_IO) & 
                                     std_logic'(NOT PortCLow_IO) & 
                                     std_logic'(NOT PortCLow_IO);
			 END IF;
		 ELSE
             PBEN                 <= NOT PortB_IO;
             PCEN (3 DOWNTO 0)    <= "1011";
		 END IF;


		 IF (ModeA = "00") THEN
             PAEN  <= NOT PortA_IO;
             PCEN (7 DOWNTO 4) <= std_logic'(NOT PortCUp_IO) & 
                                  std_logic'(NOT PortCUp_IO) & 
                                  std_logic'(NOT PortCUp_IO) & 
                                  std_logic'(NOT PortCUp_IO);
		 ELSIF (ModeA = "01") THEN
             PAEN                 <= NOT PortA_IO;
			 IF (PortA_IO = '0') THEN                               --Port A Output
			     PCEN(7 DOWNTO 4) <= "10" & 
			                          std_logic'(NOT PortCUp_IO) & 
			                          std_logic'(NOT PortCUp_IO);
			 ELSE					                                --Port A Input
			     PCEN(7 DOWNTO 4) <= std_logic'(NOT PortCUp_IO) & 
			                         std_logic'(NOT PortCUp_IO) & 
			                         "10";
			 END IF;
		 ELSE
		     PAEN                 <= NOT PCIN(6);		            -- ACK signal drives enable in Mode 2
			 PCEN(7 DOWNTO 4)     <= "1010";
		 END IF;


         CASE A IS
		    WHEN "00" =>					 -- Port A Data
			   IF (ModeA = "00") THEN		 -- If Port A is in Mode 0
			      DOUTSelect <= "000";		 -- then select unlatched PAIN data
			   ELSE
			      DOUTSelect <= "001";		 -- else select latched PAIN data
			   END IF;
			WHEN "01" =>					 -- Port B Data
			   IF (ModeB = '0') THEN		 -- If Port B is in Mode 0
			      DOUTSelect <= "010";		 -- then select unlatched PBIN data
			   ELSE
			      DOUTSelect <= "011";		 -- else select latched PBIN data
			   END IF;
			WHEN "10" =>					 -- Port C Data
			   DOUTSelect <= "100";		     -- Select PCIN data
			WHEN "11" =>
			   DOUTSelect <= "110";			 -- Select Control Register Data
			WHEN OTHERS =>
			   NULL;            			 -- Default
		 END CASE;


		 IF (nCS  = '0' AND A = "11" AND DIN(7) = '0') THEN
		    PortCOverride <= '1';
		 ELSE
		    PortCOverride <= '0';
		 END IF;

		 IF (nCS  = '0' AND A =       "10" AND nWR  = '0') THEN
			IF (ModeA = "00" AND ModeB = '0') THEN
               PortCOutLd    <= "00000000";
			ELSIF (ModeA = "00") THEN
               PortCOutLd    <= "00001111";
			ELSIF (ModeB = '0') THEN
               PortCOutLd    <= "11110000";
			ELSE
               PortCOutLd    <= "11111111";
			END IF;  
		 ELSIF (nCS  = '0' AND A = "11" AND nWR  = '0' AND DIN(7) = '0') THEN
			CASE DIN (3 DOWNTO 1) IS
			   WHEN "000" =>
                 PortCOutLd <= "11111110";
			   WHEN "001" =>
                 PortCOutLd <= "11111101";
			   WHEN "010" =>
                 PortCOutLd <= "11111011";
			   WHEN "011" =>
                 PortCOutLd <= "11110111";
			   WHEN "100" =>
                 PortCOutLd <= "11101111";
			   WHEN "101" =>
                 PortCOutLd <= "11011111";
			   WHEN "110" =>
                 PortCOutLd <= "10111111";
			   WHEN "111" =>
                 PortCOutLd <= "01111111";
			   WHEN OTHERS =>
                 PortCOutLd <= "11111111";
			END CASE;
		 ELSE
            PortCOutLd    <= "11111111";
		 END IF;

		 IF (ControlRegWrite = '0') THEN
            ControlRegD     <= DIN (6 DOWNTO 0);
		 ELSE
            ControlRegD     <= ControlRegQ;
		 END IF;

   END PROCESS;


ControlRegProc: PROCESS ( RESET, CLK )

    BEGIN

        IF (RESET = '1') THEN
            ControlRegQ     <= "0011011";
        ELSIF (CLK'EVENT and CLK = '1')  THEN
            ControlRegQ     <= ControlRegD;
        END IF;

    END PROCESS;

   END rtl;

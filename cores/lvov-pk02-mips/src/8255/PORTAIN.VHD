-- Altera Microperipheral Reference Design Version 0802
--------------------------------------------------------
--
--  FILE NAME   :   portain.vhd
--  PROJECT     :   Altera A8255 Peripheral Interface Adapter
--  PURPOSE     :   This file contains the entity and architecture 
--                  for the Port A Input Register of the A8255 design.
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

ENTITY portain IS
   PORT(
      PAIN       : IN std_logic_vector (7 DOWNTO 0);
      RESET      : IN std_logic;
      CLK        : IN std_logic;
      PortAInLd  : IN std_logic;
      PortAInReg : OUT std_logic_vector (7 DOWNTO 0)
   );

END portain;


ARCHITECTURE rtl OF portain IS

   SIGNAL    PortAInRegQ : std_logic_vector(7 DOWNTO 0);
   SIGNAL    PortAInRegD : std_logic_vector(7 DOWNTO 0);


   BEGIN

	  PortAInReg <= PortAInRegQ;

      PortAInRegProc: PROCESS ( PortAInLd, PAIN, PortAInRegQ )

         BEGIN

            IF ( PortAInLd = '0')  THEN
               PortAInRegD     <= PAIN (7 DOWNTO 0);
			ELSE
               PortAInRegD     <= PortAInRegQ;
            END IF;

      END PROCESS;


      PortAInRegSynchProc: PROCESS ( RESET, CLK )

         BEGIN

            IF (RESET = '1') THEN
               PortAInRegQ     <= "00000000";
            ELSIF ( CLK'EVENT and CLK = '1')  THEN
               PortAInRegQ     <= PortAInRegD;
            END IF;

      END PROCESS;

   END rtl;

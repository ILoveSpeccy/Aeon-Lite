-- Altera Microperipheral Reference Design Version 0802
--------------------------------------------------------
--
--  FILE NAME   :   portaout.vhd
--  PROJECT     :   Altera A8255 Peripheral Interface Adapter
--  PURPOSE     :   This file contains the entity and architecture 
--                  for the Port A Output Register of the A8255 design.
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

ENTITY portaout IS
   PORT(
      RESET       : IN std_logic;
      CLK         : IN std_logic;
      DIN         : IN std_logic_vector (7 DOWNTO 0);
      PortAOutLd  : IN std_logic;
      PAOUT       : OUT std_logic_vector (7 DOWNTO 0)
   );

END portaout;


ARCHITECTURE rtl OF portaout IS

   SIGNAL    PortAOutRegD : std_logic_vector(7 DOWNTO 0);
   SIGNAL    PortAOutRegQ : std_logic_vector(7 DOWNTO 0);


   BEGIN

	  PAOUT <= PortAOutRegQ;

      PortAOutRegProc: PROCESS ( PortAOutLd, PortAOutRegQ, DIN )

         BEGIN

            IF ( PortAOutLd = '0')  THEN
               PortAOutRegD     <= DIN;
			ELSE
			   PortAOutRegD     <= PortAOutRegQ;
            END IF;

         END PROCESS;


      PortAOutRegSynchProc: PROCESS ( RESET, CLK )

         BEGIN

            IF (RESET = '1') THEN
               PortAOutRegQ     <= "00000000";
            ELSIF ( CLK'EVENT and CLK = '1')  THEN
               PortAOutRegQ     <= PortAOutRegD;
            END IF;

         END PROCESS;

   END rtl;

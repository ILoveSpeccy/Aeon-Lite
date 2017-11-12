-- Altera Microperipheral Reference Design Version 0802
--------------------------------------------------------
--
--  FILE NAME	:	dout_mux.vhd
--  PROJECT		:	Altera A8255 Peripheral Interface Adapter
--  PURPOSE		:	This file contains the entity and architecture 
--					for the data output multiplexer of the A8255 design.
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

ENTITY dout_mux IS
   PORT(
      DOUTSelect  : IN std_logic_vector (2 DOWNTO 0);
      ControlReg  : IN std_logic_vector (7 DOWNTO 0);
      PortAInReg  : IN std_logic_vector (7 DOWNTO 0);
      PAIN        : IN std_logic_vector (7 DOWNTO 0);
      PortBInReg  : IN std_logic_vector (7 DOWNTO 0);
      PBIN        : IN std_logic_vector (7 DOWNTO 0);
      PortCStatus : IN std_logic_vector (7 DOWNTO 0);
      DOUT        : OUT std_logic_vector(7 DOWNTO 0)
   );

END dout_mux;


ARCHITECTURE rtl OF dout_mux IS

   BEGIN
      mux_proc : PROCESS( DOUTSelect, PAIN, PortAInReg, PBIN, PortBInReg, PortCStatus, ControlReg, DOUTSelect)
         BEGIN

            CASE DOUTSelect IS

               WHEN "000" => 
                   DOUT <= PAIN;

               WHEN "001" =>                
                   DOUT <= PortAInReg;

               WHEN "010" =>                
                   DOUT <= PBIN;

               WHEN "011" =>                
                   DOUT <= PortBInReg;

               WHEN "100" =>                
                   DOUT <= PortCStatus;

               WHEN "110" =>                
                   DOUT <= ControlReg;

               WHEN OTHERS =>
                   DOUT <= "11111111";

             END CASE;

      END PROCESS mux_proc;

   END rtl;

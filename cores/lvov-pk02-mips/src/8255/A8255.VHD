-- Altera Microperipheral Reference Design Version 0802
--------------------------------------------------------
--
--  FILE NAME	:	a8255.vhd
--  PROJECT		:	Altera A8255 Peripheral Interface Adapter
--  PURPOSE		:	This file contains the entity and architecture 
--					for the top level of the A8255 design.
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

ENTITY a8255 IS
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

END a8255;


ARCHITECTURE structure OF a8255 IS
   -- SIGNAL DECLARATIONS
      SIGNAL DOUTSelect           : std_logic_vector(2 DOWNTO 0);
      SIGNAL ControlReg           : std_logic_vector(7 DOWNTO 0);
	  SIGNAL PortAOutLd           : std_logic;
	  SIGNAL PortBOutLd           : std_logic;
	  SIGNAL PortCOverride        : std_logic;
	  SIGNAL PortCOutLd           : std_logic_vector (7 DOWNTO 0);
      SIGNAL PortAInReg           : std_logic_vector (7 DOWNTO 0);
      SIGNAL PortBInReg           : std_logic_vector (7 DOWNTO 0);
	  SIGNAL PortARead            : std_logic;
	  SIGNAL PortBRead            : std_logic;
	  SIGNAL PortAWrite           : std_logic;
	  SIGNAL PortBWrite           : std_logic;
	  SIGNAL PortCStatus          : std_logic_vector (7 DOWNTO 0);
	  SIGNAL CompositePortCStatus : std_logic_vector (7 DOWNTO 0);


   -- COMPONENT_DECLARATIONS
      COMPONENT dout_mux
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
      END COMPONENT;

      COMPONENT cntl_log
         PORT(
            RESET         : IN std_logic;
            CLK           : IN std_logic;
            nCS           : IN std_logic;
            nRD           : IN std_logic;
            nWR           : IN std_logic;
            A             : IN std_logic_vector (1 DOWNTO 0);
            DIN           : IN std_logic_vector(7 DOWNTO 0);
            PCIN          : IN std_logic_vector(7 DOWNTO 0);
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
      END COMPONENT;

      COMPONENT portaout
         PORT(
            DIN        : IN std_logic_vector (7 DOWNTO 0);
            RESET      : IN std_logic;
            CLK        : IN std_logic;
            PortAOutLd : IN std_logic;
            PAOUT      : OUT std_logic_vector (7 DOWNTO 0)
         );
      END COMPONENT;


      COMPONENT portain
         PORT(
            PAIN       : IN std_logic_vector (7 DOWNTO 0);
            RESET      : IN std_logic;
            CLK        : IN std_logic;
            PortAInLd  : IN std_logic;
            PortAInReg : OUT std_logic_vector (7 DOWNTO 0)
         );
      END COMPONENT;

      COMPONENT portbout
         PORT(
            DIN        : IN std_logic_vector (7 DOWNTO 0);
            RESET      : IN std_logic;
            CLK        : IN std_logic;
            PortBOutLd : IN std_logic;
            PBOUT      : OUT std_logic_vector (7 DOWNTO 0)
         );
      END COMPONENT;

      COMPONENT portbin
         PORT(
            PBIN       : IN std_logic_vector (7 DOWNTO 0);
            RESET      : IN std_logic;
            CLK        : IN std_logic;
            PortBInLd  : IN std_logic;
            PortBInReg : OUT std_logic_vector (7 DOWNTO 0)
         );
      END COMPONENT;

      COMPONENT portcout
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
      END COMPONENT;


   BEGIN
      -- CONCURRENT SIGNAL ASSIGNMENTS
	  CompositePortCStatus <= PCIN(7)        &  
	                          PortCStatus(6) & 
	                          PCIN(5)        & 
	                          PortCStatus(4) & 
                              PCIN(3)        & 
                              PortCStatus(2) & 
                              PCIN(1)        & 
                              PCIN(0);

      -- COMPONENT INSTANTIATIONS
      I_dout_mux : dout_mux
         PORT MAP(
            DOUTSelect  => DOUTSelect          , 
            ControlReg  => ControlReg          , 
            PortAInReg  => PortAInReg          , 
            PAIN        => PAIN                , 
            PortBInReg  => PortBInReg          , 
            PBIN        => PBIN                , 
            PortCStatus => CompositePortCStatus, 
            DOUT        => DOUT       
         );

      I_cntl_log : cntl_log
         PORT MAP(
            RESET          => RESET         , 
            CLK            => CLK           , 
            nCS            => nCS           , 
            nRD            => nRD           , 
            nWR            => nWR           , 
            A              => A             , 
            DIN            => DIN           , 
            PCIN           => PCIN          , 
            PAEN           => PAEN          , 
            PBEN           => PBEN          , 
            PCEN           => PCEN          , 
			DOUTSelect     => DOUTSelect    , 
			ControlReg     => ControlReg    , 
            PortARead      => PortARead     ,
            PortBRead      => PortBRead     ,
            PortAWrite     => PortAWrite    ,
            PortBWrite     => PortBWrite    ,
			PortAOutLd     => PortAOutLd    , 
			PortBOutLd     => PortBOutLd    , 
			PortCOverride  => PortCOverride , 
			PortCOutLd     => PortCOutLd
         );

      I_portaout : portaout
         PORT MAP(
            DIN        => DIN       ,
            RESET      => RESET     , 
            CLK        => CLK       , 
            PortAOutLd => PortAOutLd,
            PAOUT      => PAOUT     
         );


      I_portain : portain
         PORT MAP(
            PAIN       => PAIN      ,
            RESET      => RESET     , 
            CLK        => CLK       , 
            PortAInLd  => PCIN (4)  ,
            PortAInReg => PortAInReg
         );

      I_portbout : portbout
         PORT MAP(
            DIN        => DIN       ,
            RESET      => RESET     , 
            CLK        => CLK       , 
            PortBOutLd => PortBOutLd,
            PBOUT      => PBOUT     
         );

      I_portbin : portbin
         PORT MAP(
            PBIN       => PBIN      ,
            RESET      => RESET     , 
            CLK        => CLK       , 
            PortBInLd  => PCIN (2)  ,
            PortBInReg => PortBInReg
         );

      I_portcout : portcout
         PORT MAP(
            RESET         => RESET        ,
            CLK           => CLK          , 
            DIN           => DIN          ,
            PCIN          => PCIN         ,
            ControlReg    => ControlReg   ,
            PortARead     => PortARead    ,
            PortBRead     => PortBRead    ,
            PortAWrite    => PortAWrite   ,
            PortBWrite    => PortBWrite   ,
            PortCOutLd    => PortCOutLd   ,
			PortCOverride => PortCOverride,
            PortCStatus   => PortCStatus  ,     
            PCOUT         => PCOUT     
         );


   END structure;

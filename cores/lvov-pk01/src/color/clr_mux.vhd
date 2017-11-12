LIBRARY ieee;
USE ieee.std_logic_1164.all; 

LIBRARY work;

ENTITY clr_mux IS 
	PORT
	(
		color :  IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
		portb :  IN  STD_LOGIC_VECTOR(6 DOWNTO 0);
		out_r :  OUT  STD_LOGIC;
		out_g :  OUT  STD_LOGIC;
		out_b :  OUT  STD_LOGIC
	);
END clr_mux;

ARCHITECTURE bdf_type OF clr_mux IS 

   signal i0   : std_logic;
   signal i1   : std_logic;
   signal i2   : std_logic;
   signal i3   : std_logic;

   signal D591 : std_logic;
   signal D592 : std_logic;
   signal D593 : std_logic;
   signal D594 : std_logic;
   signal D601 : std_logic;
   signal D602 : std_logic;
   signal D603 : std_logic;
   signal D604 : std_logic;
   signal D611 : std_logic;
   signal D612 : std_logic;
   signal D613 : std_logic;
   
BEGIN 

   i0   <=     color(1) or     color(0);
   i1   <=     color(1) or not color(0);
   i2   <= not color(1) or     color(0);
   i3   <= not color(1) or not color(0);

   D591 <= portb(0) or  i1;
   D592 <= portb(1) or  i3;
   D593 <= portb(2) or  i0;
   D594 <= portb(3) or  i0;
   D601 <= D604     and i3;
   D602 <= D592     and i2;
   D603 <= D593     and i1;
   D604 <= D591     and D594;
   D611 <= portb(4) xor D601;
   D612 <= portb(5) xor D602;
   D613 <= portb(6) xor D603;    
   
   out_r <= not D611;
   out_g <= not D612;
   out_b <= not D613;
   
END bdf_type;
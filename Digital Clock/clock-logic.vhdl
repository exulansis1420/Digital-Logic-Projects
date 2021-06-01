library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
-------------------------------------
ENTITY clk_divider IS
	PORT (  clk : in STD_LOGIC;
		clk_sec : out STD_LOGIC;)
END clk_sec;
--------------------------------------
ARCHITECTURE behaviour OF clk_divider IS
	SIGNAL toggle : std_logic :='0';
	SIGNAL cycles : integer range 0 to 50000000 :=0;
 BEGIN
   PROCESS(clk) BEGIN
	if(rising_edge(clk)) then
		cycles <= cycles+1;
		if(cycles = 50000000) then
			toggle<= not toggle
			cycles<=0;
		end if;
	end if;
	clk_sec <= toggle
   END PROCESS;
 END behaviour;
------------------------------------
ENTITY digital_clk IS
	PORT (	clk_sec: in std_logic;
		btnModeSetTime: in std_logic;
		btnInc: in std_logic;
		btnShiftLeft: in std_logic;	
		dotModeSetTime: out std_logic;
		sec_out0: out std_logic_vector(6 DOWNTO 0); 
		sec_out1: out std_logic_vector(6 DOWNTO 0); 
		min_out0: out std_logic_vector(6 DOWNTO 0); 
		min_out1: out std_logic_vector(6 DOWNTO 0); 
		hr_out0: out std_logic_vector(6 DOWNTO 0); 
		hr_out1: out std_logic_vector(6 DOWNTO 0); 
	     );
 END digital_clk;
------------------------------------------------
ENTITY intToHex IS
	PORT (  Intin: integer range 0 to 9;
		Hexout: out std_logic_vector(6 DOWNTO 0);
	     );
 END intToHex;
------------------------------------------------
ARCHITECTURE behaviour OF intToHex IS
 BEGIN
	PROCESS(Intin)
 	BEGIN
  	       case(Intin) is
   		 when 0 =>  Hexout <= "1000000"; 
   		 when 1 =>  Hexout <= "1111001"; 
   		 when 2 =>  Hexout <= "0100100"; 
   		 when 3 =>  Hexout <= "0110000"; 
   	 	 when 4 =>  Hexout <= "0011001"; 
  		 when 5 =>  Hexout <= "0010010";    
   		 when 6 =>  Hexout <= "0000010"; 
   		 when 7 =>  Hexout <= "1111000";   
   		 when 8 =>  Hexout <= "0000000"; 
   		 when 9 =>  Hexout <= "0010000"; 
   		END case;
 	END process;
 END behaviour;
----------------------------------------------------
ARCHITECTURE behaviour OF digital_clk IS
	COMPONENT intToHex IS
	PORT (  Intin: integer range 0 to 9;
		Hexout: out std_logic_vector(6 DOWNTO 0);
	     );
	END COMPONENT;
	SIGNAL sec: integer range 0 to 60 :=0;
	SIGNAL min: integer range 0 to 60 :=0;
	SIGNAL hr: integer range 0 to 24 :=0;
	SIGNAL btnModeSetTimeCount: std_logic :='0';
	SIGNAL changeField: integer range 0 to 2 :=0;
 BEGIN
	 PROCESS(clk_sec,btnModeSetTime,btnShiftLeft) BEGIN
		if(btnModeSetTime='1') THEN
			btnModeSetTimeCount<= not btnModeSetTimeCount;
		end if;

		if(btnModeSetTimeCount='0') THEN
		   if(rising_edge(clk_sec)) THEN
			sec<=sec+1;
			if(sec=60) then
		      		min<=min+1;
		      		sec<=0;
		      		if(min=60) then
					hr<=hr+1;
					min<=0;
					if(hr=24) then
			  			hr<=0;
		          			min<=0;
			  			sec<=0;
					end if;
				end if;
			end if;
			dotModeSetTime<=btnModeSetTimeCount;
		   end if;

		elsif(btnModeSetTimeCount=1) THEN
		     if(btnShiftLeft=1) THEN
			changeField<=(changeField+1) mod 3;
		     end if;

		     if(changeField=0) THEN
			if(btnInc=1) then
				sec<=sec+1;
				if(sec=60) then
					sec<=0;
				end if;
			end if;
		     end if;

		     if(changeField=1) THEN
			if(btnInc=1) then
				min<=min+1;
				if(min=60) then
					min<=0;
				end if;
			end if;
		     end if;

		     if(changeField=2) THEN
			if(btnInc=1) then
				hr<=hr+1;
				if(hr=24) then
					hr<=0;
				end if;
			end if;
		     end if;

		     dotModeSetTime<=btnModeSetTimeCount;
		end if;

		intToHex port map(sec mod 10, sec_out0); 
		intToHex port map(min mod 10, min_out0); 
		intToHex port map(hr mod 10, hr_out0);
		intToHex port map(sec-(sec mod 10), sec_out1); 
		intToHex port map(min-(min mod 10), min_out1); 
		intToHex port map(hr-(hr mod 10), hr_out1);  
	END PROCESS;
 END behaviour;
-----------------------------------------------------------
ENTITY displayMode IS
	PORT(   sec_in0: in STD_LOGIC_VECTOR(6 DOWNTO 0);
		sec_in1: in STD_LOGIC_VECTOR(6 DOWNTO 0);
		min_in0: in STD_LOGIC_VECTOR(6 DOWNTO 0);
		min_in1: in STD_LOGIC_VECTOR(6 DOWNTO 0);
		hr_in0: in STD_LOGIC_VECTOR(6 DOWNTO 0);
		hr_in1: in STD_LOGIC_VECTOR(6 DOWNTO 0);
		btnViewMode: in STD_LOGIC;
		dotBlink: out STD_LOGIC;
		out0: out STD_LOGIC_VECTOR(6 DOWNTO 0);
		out1: out STD_LOGIC_VECTOR(6 DOWNTO 0);
		out2: out STD_LOGIC_VECTOR(6 DOWNTO 0);
		out3: out STD_LOGIC_VECTOR(6 DOWNTO 0);
	    );
 END displayMode;
-----------------------------------------------------------
ARCHITECTURE behaviour OF displayMode IS
	SIGNAL btnPress: STD_LOGIC:='0';
	SIGNAL dotBlinkCounter integer range 0 to 50000000;
	BEGIN
	   PROCESS(sec_in0, sec_in1, min_in0, min_in1, hr_in0, hr_in1)
		if(btnViewMode=1) then
			btnPress<= not btnPress;
		end if;
		
		if(btnPress='0') then 
			out0<= sec_in0;
			out1<= sec_in1;
			out2<= min_in0;
			out3<= min_in1;
			dotBlink<='0';
			dotBlinkCounter<=0;

		elsif(btnPress='1') then 
			out0<= min_in0;
			out1<= min_in1;
			out2<= hr_in0;
			out3<= hr_in1;
			if(rising_edge(clk)) then
				dotBlinkCounter<=dotBlinkCounter+1;
				if(dotBlinkCounter=50000000)
					dotBlink<=not dotBlink;
					dotBlinkCounter<=0;
				end if;
			end if;	
		end if;
	   END PROCESS;
  END behaviour;
-----------------------------------------------------------
ENTITY segDisplay IS
	PORT(   clk: in STD_LOGIC;
		out0: in STD_LOGIC_VECTOR(6 DOWNTO 0);
		out1: in STD_LOGIC_VECTOR(6 DOWNTO 0);
		out2: in STD_LOGIC_VECTOR(6 DOWNTO 0);
		out3: in STD_LOGIC_VECTOR(6 DOWNTO 0);
		anode: out STD_LOGIC_VECTOR(3 DOWNTO 0);
	     );
 END segDisplay;
-----------------------------------------------------------
ARCHITECTURE behaviour OF segDisplay IS
	SIGNAL counter: integer range 0 to 400000:= 0;
	SIGNAL clk_4ms: STD_LOGIC :='0';
	SIGNAL selector: STD_LOGIC_VECTOR(3 DOWNTO 0);

	BEGIN
	 PROCESS(clk)
	  BEGIN 
    	   if(rising_edge(clk)) then
        	counter <= counter + 1;
		if(counter=200000) then 
			clk_4ms <= not clk_4ms;
			counter<=0;
		end if;
    	   end if;
	END PROCESS;

	PROCESS(clk_4ms, selector)
	  BEGIN
	    if(rising_edge(clk_4ms)) then
		selector<= selector +1;
		if(selector = "11") then
			selector<="00";
		end if;
	    end if;
    	   CASE selector is
    		WHEN "00" =>anode <= "0111"; 
    		WHEN "01" =>anode <= "1011";
    		WHEN "10" =>anode <= "1101";
    		WHEN "11" =>anode <= "1110"; 
    	   END CASE;
	END PROCESS;
 END behaviour;
------------------------------------------



			  
		         
			   


















			
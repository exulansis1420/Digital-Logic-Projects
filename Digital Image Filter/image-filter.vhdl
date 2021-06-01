library IEEE;
use IEEE.std_logic_1164.ALL; 
use IEEE.NUMERIC_STD.ALL;

entity RAM_64Kx8 is 
port (
	clock : in std_logic;
	read_enable, write_enable : in std_logic;	-- signals that enable read/write operation 
	address : in std_logic_vector(15 downto 0);	-- 2^16 = 64K
	data_in : in std_logic_vector(7 downto 0); 
	data_out : out std_logic_vector(7 downto 0); 
);
end RAM_64Kx8; 

entity ROM_32x9 is
port (
	clock : in std_logic;
	read_enable : in std_logic;			-- signal that enables read operation 
	address : in std_logic_vector(4 downto 0); 	-- 2^5 = 32
	data_out : out std_logic_vector(8 downto 0)
);
end ROM_32x9; 

entity MAC is
port (
	clock : in std_logic;
	control : in std_logic;				-- ‘0’ for initializing the sum 
	data_in1, data_in2 : in std_logic_vector(17 downto 0);
	data_out : out std_logic_vector(17 downto 0);
);
end MAC;

architecture Artix of RAM_64Kx8 is
	type Memory_type is array (0 to 65535) of std_logic_vector (7 downto 0); 
	signal Memory_array : Memory_type;
	begin
	    process (clock) begin
		if rising_edge (clock) then
		   if (read_enable = '1') then		 
    			data_out <= Memory_array (to_integer (unsigned (address)));
		   end if;
		   if (write_enable = '1') then			
    			Memory_array (to_integer (unsigned(address))) <= data_in;
	           end if; 
		end if;
	    end process; 
end Artix;

architecture Artix of ROM_32x9 is
	type Memory_t-ype is array (0 to 31) of std_logic_vector (8 downto 0); signal Memory_array : Memory_type;
	begin
	    process (clock) begin
		if rising_edge (clock) then
		      if (read_enable = '1') then	
			data_out <= Memory_array (to_integer (unsigned (address)));
		      end if; 
	        end if;
	    end process; 
end Artix;

architecture Artix of MAC is
	signal sum, product : signed (17 downto 0); 
	begin
	    data_out <= std_logic_vector (sum);
	    product <= signed (data_in1) * signed (data_in2);
  	    process (clock) 
	        begin
		if rising_edge (clock) then			-- sum is available after clock edge
		    if (control = '0') then			-- initialize the sum with the first product
	 		sum <= std_logic_vector (product);
		    else					-- add product to the previous sum
	 		sum <= std_logic_vector (product + signed (sum));
		    end if; 
		end if;
	   end process; 
end Artix;

--------------Filter Component: Logic and Architecture-------------------

ENTITY FILTER IS 
PORT (
	clock: in std_logic;					--clock signal
	btn: in std_logic;					--button to start filtering
	filterType: in std_logic;				--switch to decide smoothen/sharpen
	RAM_data: in std_logic_vector(7 downto 0);		--read data from RAM
	ROM_data: in std_logic_vector(8 downto 0);		--read data from ROM
	MAC_sum: in std_logic_vector(17 downto 0);		--accumulated sum from MAC
	RAM_Ren: out std_logic;					--RAM read enable
	RAM_Wen: out std_logic;					--RAM write enable
	RAM_Radd: out std_logic_vector(15 downto 0);		--RAM read address
	RAM_Wadd: out std_logic_vector(15 downto 0);		--RAM write address
	RAM_Wdata: out in std_logic_vector(7 downto 0);		--RAM write data
	ROM_Ren: out std_logic;					--ROM read enable
	ROM_Radd: out std_logic_vector(4 downto 0);		--ROM read address 
	MAC_ctrl: out std_logic;				--MAC control
	MAC_num1: out std_logic_vector(17 downto 0)		--input for MAC: number1 
	MAC_num2: out std_logic_vector(17 downto 0)		--input for MAC: number2
     );
END FILTER;

ARCHITECTURE ARTIX of FILTER IS							--see psuedo code in design overview 
	SIGNAL j: integer range 0 to 120 :=0;					--counter corresponding to image row		
	SIGNAL i: integer range 0 to 160 :=0;					--counter corresponding to image column
	SIGNAL k: integer range 0 to 3 :=0;					--counter corresponding to window row
	SIGNAL l: integer range 0 to 3 :=0;					--counter corresponding to window colum
	SIGNAL Wadd_counter: integer range 32768 to 64000:= 32768;		--write address counter initialized at 32768
	TYPE State_type IS ( S1, S2, S3, S4 );					--S1,S2,S3,S4 correspond to states of nested loop
	SIGNAL y: State_type :=S4;						--y is current state
										--initial state S4 corresponding to innermost loop
	BEGIN
	   FSMtransitions: PROCESS (clock,j,i,k,l,y)
 	   BEGIN
  	       IF(rising_edge(clock))) THEN
	   	  CASE y IS
		     WHEN S1=>
			IF j>117 THEN y<=S0; ELSE y<=S2 ENDIF;		--sliding window top left edge y-coordinate>117
		     WHEN S2=>
			IF i>157 THEN y<=S1; ELSE y<=S3 ENDIF;		--sliding window top left edge x-coordinate>157
		     WHEN S3=>
			IF l>2 THEN y<=S2; ELSE y<=S4 ENDIF;		--iterator in window y-coordinate>2
		     WHEN S4=>
			IF k>2 THEN y<=S3; ELSE y<=S4 ENDIF;		--iterator in window x-coordinate>2
		  END CASE;
	       END IF;
 	   END process;

	   FSMoutputs: PROCESS (clock,j,i,k,l,y)
 	   BEGIN
  	       IF(rising_edge(clock))) THEN
	   	  CASE y IS
		     WHEN S1=>
			i<=0;
			j<=j+1;	

		     WHEN S2=>
			k<=0;
			i<=i+1;
			MAC_ctrl<='0';							--MAC control is reset to 0 after every 9 calls
			RAM_Wen <='1';							--enable RAM writing
			RAM_Ren <='0';
			RAM_Wadd <=std_logic_vector(to_unsigned(Wadd_counter,16));	--output address for writing, converted to 16 bit
			RAM_Wdata <= MAC_sum(17 downto 10);				--output data for writing data, discarded last bits
			Wadd_counter<= Wadd_counter+1;					--increment counter

		     WHEN S3=>
			l<=0;
			k<=k+1;

		     WHEN S4=>
			IF(filterType='0') THEN							--0 means smoothening
			    RAM_Radd<= std_logic_vector(to_unsigned((160*(j+k)+i+l),16));	--converts int to RAM address i.e 16 bit binary
			    ROM_Radd<= std_logic_vector(to_unsigned((3*k+l),5));		--converts int to ROM address i.e 5 bit binary

			ELSIF(filterType='1') THEN					--1 means sharpening
			    RAM_Radd<= std_logic_vector(to_unsigned((160*j+k+i+l),16));	--converts int to RAM address i.e 16 bit binary
			    ROM_Radd<= std_logic_vector(to_unsigned((16+3*k+l),5));	--converts int to ROM address i.e 5 bit binary
			    
			END IF;
			
			RAM_Wen <='0';				--disable RAM writing
			RAM_Ren <='1';				--enable RAM reading
			ROM_Ren <='1';				--enable ROM reading
		        MAC_num1 <=RAM_data;			
		    	MAC_num2 <=ROM_data;
			MAC_ctrl <='1'; 
			l<=l+1;		
		  END CASE;
	       END IF;
 	   END process;
END ARTIX;
	
		


	

	
	




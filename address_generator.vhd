--address generator 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity address_generator is 
	port(
	
		new_addr: in std_logic; -- set to 1, to enable new address to be written; basically the reset signal; 
		advance_addr: in std_logic; -- only increment the address when this is set high 
		
		clk: in std_logic; -- pclk; 
		addr: out std_logic_vector(19 downto 0); --19 bit address here; 
	);

end address_generator; 


architecture arch of address_generator is
	address: std_logic_vector(19 downto 0) := (others => '0');  
	address_next: std_logic_vector(19 downto 0); 

begin 
	addr <= address; 
	
	process(clk) 
		if rising_edge(clk)
			address <= address_next; -- clock the output; 
		end if; 
	
	end process; 
	
	process(new_addr, advance_addr) -- remember to deassert when done; -- luckily, only
		address_next <= address; 	
		if(new_addr = '1') then
			address_next <= (others => '0');
		
		elsif(advance_addr) then 
			address_next <= address + 1; -- take current value and increment; 
		end if; 
	
	end process 


end arch; 
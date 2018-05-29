library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity rw_mux is 
	port(
		-- 
		select_i: in std_logic; -- selects the data; 
		addr1_i: in std_logic_vector(19 downto 0);
		we1_i: in std_logic; 
		mem1_i: in std_logic; 
		
		addr2_i: in std_logic_vector(19 downto 0);
		we2_i: in std_logic; 
		mem2_i: in std_logic; 
		
		we_o: out std_logic; 
		mem_o: out std_logic; 
		addr_o: out std_logic_vector(19 downto 0); 
		
		
		
	); 
end rw_mux; 



architecture arch of rw_mux is 
--

begin

addr_o <= addr1_i when select_i = '0' else addr2_i;
mem_o <= mem1_i when select_i = '0' else mem2_i;
we_o <= we1_i when select_i = '0' else we2_i;  --naisu; 
	

end arch; 
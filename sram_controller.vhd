library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity sram_controller is
	port(
		--inputs from interface
		addr_i: in std_logic_vector(19 downto 0); --20 bit address; 
		data_i: in std_logic_vector(15 downto 0); 
		we_i: in std_logic; 
		mem_i: in std_logic; 
		
		--outputs from interface
		data_o: out std_logic_vector(15 downto 0);
		ready: out std_logic; 
		
		--inputs to sram
		sram_addr_o: out std_logic_vector(19 downto 0); 
		sram_data_io: inout std_logic_vector(15 downto 0);
		we_o: out std_logic; -- output 
		oe_o: out std_logic; --output enable; assert 0 to read
		
		
		--clk and reset: 
		clk_i, reset_i: in std_logic 
	);
end sram_controller; 



architecture behavioral of sram_controller is

	--define state types: 
	type sram_states is (idle, rd1, rd2, wr1, wr2); 
	signal state_reg, state_next : sram_states;
	signal data_f2s_reg, data_f2s_next: std_logic_vector(15 downto 0); 
	
	--read/write current state - in order to not have it change for the sram; 
	signal data_s2f_reg, data_s2f_next: std_logic_vector(15 downto 0); -- once again, only conect data_s2f_next to the data bus of the sram; 
	
	signal addr_reg, addr_next: std_logic_vector(19 downto 0); -- interface with the addr_i; 
	
	signal we_buf, oe_buf, tri_buf: std_logic; --at each clock cycle, we want to CALCULATE the NEXT value the clock will take! 
	signal we_reg, oe_reg, tri_reg: std_logic; --the current state that system is in. 
	
	-- as far as we know, the SRAM does not CARE about any clock cycle. It will only see what 
begin
	--map signals that can definitely be mapped; 
	
	
	--process to update registers upon clock 
	process(clk_i, reset_i)
	begin
		if reset_i = '1' then
			--set everything to 0; 
			state_reg <= idle; 
			addr_reg <= (others => '0');
			data_f2s_reg <= (others => '0');
			data_s2f_reg <= (others => '0');	
			tri_reg <= '1'; -- tri state buffer asserted to high -> means high impedance state; means to NOT drive the output; leave the thing be. 
			we_reg <= '1';
			oe_reg <= '1';

		elsif rising_edge(clk_i) then
			-- update state; 
			state_reg <= state_next; 
			addr_reg <= adr_next; 
			data_f2s_reg <= data_f2s_next;
			data_s2f_reg <= data_s2f_next;	
			tri_reg <= tri_buf; -- tri state buffer asserted to high -> means high impedance state; means to NOT drive the output; leave the thing be. 
			we_reg <= we_buf;
			oe_reg <= oe_buf;
		end if
	end process; --current state connections; 
	
	
	--next state logic; state logic; 
	process(state_reg, clk_i, mem_i, we_i, addr_i, data_i, sram_data_io, data_f2s_reg, data_s2f_reg) -- need mem_i for 
	begin
		--next state logic; what do we need to read? 
		addr_reg <= adr_next; 
		data_f2s_next <= data_f2s_reg; -- default - keep original value; prevent extra registers from being formed. 
		data_s2f_next <= data_s2f_reg; --default assignment; ok since it's in a process; 
		ready <= '0'; -- only assert 1 if in idle; 
		case state_reg is
			
			when idle =>
				--
				ready <= '1'; 
				--is a memory read currently being requested? 
				if (mem_i = '1') then 
					--read requested; 
					addr_next <= addr_i; -- the next address will be read is the 
					if(we_i = '0') then -- write signal, send to wr1; 
						state_next <= wr1; 
						data_f2s_next <= data_i; --input data from the bus port; 	
					else
						state_next <= rd1; --send to read state; 
					end if; 
				else 
					state_next <= idle; 
				
				end if; 
			when rd1 => 
				-- send to rd2
				state_next <= rd2; 
				
			when rd2 =>
				state_next <= idle; 
				--read the data into our buffer; 
				data_s2f_next <= sram_data_io; -- sram data input; 
			when wr1 => 
				state_next <= wr2; 
			
			when wr2 => 
				state_next <= idle; --send back to idle 
		end case; 
	
	end process;

	
	--output logic;
	process(state_next) -- we are not updating anything new here; we did that in the first process; 
	begin
		tri_buf <= '1'; 
		oe_buf <= '1'; 
		we_buf <= '1'; 
		case state_next is --only care about what the NEXT state is... 
			when idle => -- set as default; no writes, no outputs, input into SRAM is invalid.  
			when wr1 =>
				--turn on we
				we_buf <= '0'; 
				tri_buf <= '0'; -- why is this neccesary? 
			when wr2 => 
				--turn off we_buf; 
				tri_buf <= '0'; 
				
			when rd1 => 
				oe_buf <= '0'; 
				
			when rd2 => 
				oe_buf <= '0'; -- why keep this on??? 
		end case; 
	end process; --determine what the next outputs will be. 
	
	sram_addr_o <= addr_reg; --must be true; 
	
	data_s2f_reg <= data_o;
	we_o <= we_reg; 
	oe_o <= we_reg; 
	
	sram_data_io <= data_f2s_reg when tri_reg = '0' else (others => 'Z');
	
	


end behavioral; 
--Central Controlunit 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity control_unit is
	port(
		--general signals:
		clk: in std_logic; 
		
		--from i2c sender; 
		resend_init: out std_logic; 
		camera_config_finished: in std_logic; 
		
		--camera reader: 
		image_available: in std_logic; -- just a signal that is set high when image has finished transferring. 
		capture_on: out std_logic; 
		
		--address selection
		select_signal: out std_logic;
		
		--demo portion 
		read_on: in std_logic
		--start_read: out std_logic
		--UART control - coming soon! 
		
	
	);
end control_unit 


architecture arch of control_unit is


type control_state_type is (initializing, idle, capturing, reading); 
signal control_state_r: control_state_type := initializing; 
signal control_state_next: control_state_type; 

signal capture_r: std_logic; 
signal capture_next: std_logic; 
signal resend_r: std_logic; 
signal resend_next: std_logic; 

signal select_r: std_logic; -- 0 for write, 1 for read; 
signal select_next: std_logic;



begin
	capture_on <= capture_r; 
	select_signal <= select_r; 
	
	process(clk, control_state_next)
	begin
		control_state_r <= control_state_next; 
		capture_r <= capture_next; 
		resend_r <= resend_next; 
		select_r <= select_next; 
		
	end process; 
	
	
	--next state
	process(control_state_r, camera_config_finished, image_available, read_on)
	begin 
		case control_state_r is
		
			when initializing => 
				control_state_next <= initializing; --keep! 
				if(camera_config_finished = '1') then 
					control_state_next <= capturing; -- start capturing; 
				end if; 
				
			
			when idle => 
				control_state_next <= idle; 
				if (image_available = '0') then
					control_state_next <= capturing; 
				elsif(image_available = '1' and read_on = '1') then
					control_state_next <= reading; 
				end if; 
			
			
			when capturing => 
				control_state_next <= capturing; 
				--only stop when "image available is asserted high; 
				if(image_available = '1') then
					control_state_next <= idle; --finished reading; --quickly! make it idle! 
				end if; 
			
			when reading => 
				control_state_next <= reading; 
				if (read_on = '0') then 
					control_state_next <= capturing; 
				end if; 
	
	end process; 
	
	
	--outputs; 
	process(control_state_next) 
	begin
		case control_state_next is
			when initializing => 
				resend_init <= '1'; 
				
			when idle => 
				--?? what do here? 
				capture_next <= '0'; 
				read_next <= '0'; 
				select_next <= '0'; 
				
			when capturing => 
				capture_next <= '1'; --assert high for capture; 
				select_next <= '0'; --sram interface multiplexor takes in
				resend_init <= '0'; 
			when reading => 
				capture_next <= '0'; --turn this off! EXTREMELY IMPORTANT! 
				select_next <= '1'; 
				resend_init <= '0'; 
		
		end case;
	end process; 




end arch; 
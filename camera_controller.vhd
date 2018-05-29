library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity camera_controller is -- only needed for camera configuration - i.e. register setting; 
	Port ( 
		-- interface with the main system; 
		clk    : in    STD_LOGIC;
		resend : in    STD_LOGIC; -- by default, we begin the resend pin set high; 
		config_finished : out std_logic;
	 
	 -- interface with camera; 
		sioc  : out   STD_LOGIC; -- provided TO the OV2640; 
		siod  : inout STD_LOGIC; -- i2c data wire; 
		
		-- hold these constant; 
		reset : out   STD_LOGIC; -- reset signal to the camera; 
		xclk  : out   STD_LOGIC
	);
end camera_controller; 




architecture arch of camera_controller is

-- have cam registers builder; spit out the commands to send; only spit out the right commands when needed; 
COMPONENT cam_registers
	PORT(
		clk      : in  STD_LOGIC;
		resend   : in  STD_LOGIC;
		advance  : in  STD_LOGIC;
		command  : out  std_logic_vector(15 downto 0);
		finished : out  STD_LOGIC
	); 
end COMPONENT; 


COMPONENT i2c_sender:
	PORT(
		clk   : in  STD_LOGIC;   
		siod  : inout  STD_LOGIC;
		sioc  : out  STD_LOGIC;
		taken_o : out  STD_LOGIC;
		send_i  : in  STD_LOGIC;
		id_i    : in  STD_LOGIC_VECTOR (7 downto 0);
		reg_i   : in  STD_LOGIC_VECTOR (7 downto 0);
		value_i : in  STD_LOGIC_VECTOR (7 downto 0)
	); 
end COMPONENT; 
 


--next states
type init_state is (beginning, in_progress, complete); 
signal init_begin_next: init_state; 
signal init_begin_r: init_state; 

--outputs
signal resend_o_r : std_logic; -- asserts resend_o_r 
signal resend_next : std_logic; 

signal send__r : std_logic; --i2c send signal; assert high to send; 
signal send_next: std_logic; 

signal finished: std_logic; 

signal next_inst: std_logic; 
signal command: std_logic_vector(15 downto 0); 
constant camera_address : std_logic_vector(7 downto 0) := x"30";




begin

config_finished <= finished; 


cam_registers_inst : cam_registers PORT MAP(
	clk => clk, 
	resend => resend_o_r, 
	advance => next_inst, 
	command => command,
	finished => finished
); 

i2c_sender_inst : i2c_sender PORT MAP(
	clk => clk,
	siod => siod,
	sioc => sioc, 
	
	taken_o => next_inst; -- taken_o initiates a "next_inst command; 
	send_i => send_r -- should we send? 
	id_i => camera_address; 
	reg_i => command(15 downto 8);  -- first 8 bits are the address of the registers inside the camera; 
	value_i => command(7 downto 0); -- last 8 bits are the values to be written inside the camera; 
); 




-- clocked output; 
	
process(clk, resend_next, init_begin_next, send_next) 
begin
	if rising_edge(clk) then
		resend_o_r <= resend_next; 
		init_begin_r <= init_begin_next; 
		send_r <= send_next; 
	end if; 

end process; 



-- combinational output 
process(init_begin_r, resend, command, finished, taken_o)
begin
	-- when to assert what signal? 
	
	case init_begin_next is
		when beginning => 
			-- is the i2c bus taken? 
			resend_next <= '1'; --we are resending; begin sending data in the NEXT clock output; 
			send_next <= '0'; --don't send JUNK over to the i2C; 
			
		when in_progress => 
			-- if send in progress; 
			send_next <= '1'; --ALWAYS TRUE! 
			resend_next <= '0'; -- DON'T RESEND!
		
			-- what about clocked outPut? 
		when complete =>
			-- 
			send_next <= '0'; 
			
	end case; 


end process;


-- Next state; 
process(init_begin_r, resend, finished) 
begin
	--
	case init_begin_r is
		when beginning => 
			--
			init_begin_next <= in_progress; 
		when in_progress => 
			--
			init_begin_next <= in_progress; 
			
			if(finished = '1') then
				init_begin_next <= complete; 
			elsif(resend = '1') then 
				init_begin_next <= beginning; 
			end if
		when complete =>
			-- 
			init_begin_next <= complete; 
			if(resend = '1') then 
				init_begin_next <= beginning; 
			end if; 
			
	end case; 

end process; 


reset <= '1'; -- Normal mode?? WHY? 
xclk  <= clk; 

end arch; 



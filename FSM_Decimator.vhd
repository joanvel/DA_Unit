-- Quartus Prime VHDL Template
-- Four-State Moore State Machine

-- A Moore machine's outputs are dependent only on the current state.
-- The output is written only when the state changes.  (State
-- transitions are synchronous.)

library ieee;
use ieee.std_logic_1164.all;

entity FSM_Decimator is

	port(
		i_clk: in std_logic;
		i_sta: in std_logic;
		i_Comp: in std_logic;
		i_reset: in std_logic;
		o_WR: out std_logic;
		o_resetCount: out std_logic
	);

end entity;

architecture rtl of FSM_Decimator is

	-- Build an enumerated type for the state machine
	type state_type is (s0, s1, s2);

	-- Register to hold the current state
	signal state   : state_type;

begin

	-- Logic to advance to the next state
	process (i_clk, i_reset)
	begin
		if i_reset = '0' then
			state <= s0;
		elsif (rising_edge(i_clk)) then
			case state is
				when s0=>
					if i_sta='1' then
						state<=s1;
					else
						state<=s0;
					end if;
				when s1=>
					if i_Comp='0' then
						state<=s1;
					else
						state<=s2;
					end if;
				when s2=>
					if i_Comp='0' then
						state<=s1;
					else
						state<=s2;
					end if;
				when others=>
					NULL;
			end case;
		end if;
	end process;

	-- Output depends solely on the current state
	process (state)
	begin
		case state is
			when s0 =>
				o_WR<='0';
				o_resetCount<='0';
			when s1 =>
				o_WR<='0';
				o_resetCount<='1';
			when s2 =>
				o_WR<='1';
				o_resetCount<='0';
			when others=>
				NULL;
		end case;
	end process;

end rtl;

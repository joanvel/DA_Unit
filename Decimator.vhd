library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity Decimator is
	generic
		(g_bits:integer:=16
		);
	port
		(i_Clk:in std_logic
		;i_reset:in std_logic
		;i_signal:in std_logic_vector(g_bits-1 downto 0)
		;i_sta: in std_logic
		;i_Decimate:in std_logic_vector(g_bits-1 downto 0)
		;o_signal:out std_logic_vector(g_bits-1 downto 0)
		);
end entity;

Architecture rtl of Decimator is

	component FSM_Decimator is
		port(
			i_clk: in std_logic;
			i_sta: in std_logic;
			i_Comp: in std_logic;
			i_reset: in std_logic;
			o_WR: out std_logic;
			o_resetCount: out std_logic
		);
	end component;

	signal s_Count:std_logic_vector(g_bits-1 downto 0);
	signal s_Comparator:std_logic;
	signal s_resetCount:std_logic;
	signal s_UPCounter:std_logic;
	signal s_WR:std_logic;
	signal s_NClk:std_logic;
begin
	s_NClk<=not(i_Clk);
	--Contador
	process(i_Clk, s_resetCount)
	begin
		if s_resetCount='0' then
			s_Count<=(others=>'0');
		else
			if rising_edge(s_NClk) then
				s_Count<=std_logic_vector(unsigned(s_Count)+to_unsigned(1,g_bits));
			end if;
		end if;
	end process;
	--Comparador
	s_Comparator<='0' when unsigned(i_Decimate)>unsigned(s_Count) else
						'1';
	--Registro
	process(s_NClk, i_reset)
		variable v_Temp:std_logic_vector(g_bits-1 downto 0);
	begin
		if (i_reset = '0') then
			v_Temp := (others=>'0');
		elsif(rising_edge(s_NClk)) then
			if (s_WR = '1') then
				v_Temp := i_signal;
			end if;
		end if;
		o_signal<=v_Temp;
	end process;
	--Porteo los componentes a la máquina de estados
	FSM:	FSM_Decimator	port map (i_Clk, i_sta, s_Comparator, i_reset, s_WR, s_resetCount);
end rtl;
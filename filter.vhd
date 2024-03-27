library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity filter is
	generic
		(g_bits:integer:=16
		;g_samples:integer:=5
		);
	port
		(i_Clk:in std_logic
		;i_signal:in std_logic_vector(g_bits-1 downto 0)
		;i_gain:in std_logic_vector(g_bits*g_samples-1 downto 0)
		;i_reset:in std_logic
		;o_signal:out std_logic_vector(g_bits-1 downto 0)
		);
end entity;

architecture rtl of filter is
	type t_samples is array (0 to g_samples-1) of std_logic_vector(g_bits-1 downto 0);
	type t_gain is array (0 to g_samples-1) of std_logic_vector(g_bits-1 downto 0);
	type t_terms is array (0 to g_samples-1) of std_logic_vector(2*g_bits-1 downto 0);
	
	signal s_samples:t_samples;
	signal s_terms:t_terms;
	signal s_gain:t_gain;
begin
	--Hago algunas asociaciones
	A:	for i in 0 to g_samples-1 generate
			s_gain(i)<=i_gain((i+1)*g_bits-1 downto i*g_bits);
		end generate;
	s_samples(0)<=i_signal;
	--Defino los registros para generar los retrasos
	B:	for i in 1 to g_samples-1 generate
			process(i_Clk,i_reset)
				variable v_Temp:std_logic_vector(g_bits-1 downto 0);
			begin
				if (i_reset='0') then
					v_Temp:=(others=>'0');
				elsif (rising_edge(i_Clk)) then
					v_Temp:=s_samples(i-1);
				end if;
				s_samples(i)<=v_Temp;
			end process;
		end generate;
	--Defino los multiplicadores
	C:	for i in 0 to g_samples-1 generate
			s_terms(i)<=std_logic_vector(signed(s_samples(i))*signed(s_gain(i)));
		end generate;
	--Defino la suma de todos los términos
	D:	process(s_terms)
			variable v_Temp:t_terms;
		begin
			v_Temp(0):=s_terms(0);
			for i in 1 to g_samples-1 loop
				v_Temp(i):=v_Temp(i-1)+s_terms(i);
			end loop;
			o_signal<=v_Temp(g_samples-1)(2*g_bits-2 downto g_bits-1);
		end process;
	
end rtl;
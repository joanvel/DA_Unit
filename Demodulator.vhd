library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity Demodulator is
	generic
		(g_bits:integer:=16
		);
	port
		(i_signal:in std_logic_vector(g_bits-1 downto 0)
		;i_Clk:in std_logic
		;i_Ctrl0:in std_logic_vector(g_bits-1 downto 0)
		;i_Ctrl1:in std_logic_vector(g_bits-1 downto 0)
		;i_reset:in std_logic
		;o_signalI:out std_logic_vector(g_bits-1 downto 0)
		;o_signalQ:out std_logic_vector(g_bits-1 downto 0)
		);
end entity;

architecture rtl of Demodulator is
	
	component DDSSC is
		generic(g_bits:integer:=g_bits);
		port
			(i_Clk:in std_logic
			;i_Ctrl0:in std_logic_vector(g_bits-1 downto 0)
			;i_Ctrl1:in std_logic_vector(g_bits-1 downto 0)
			;i_reset:in std_logic
			;o_sin:out std_logic_vector(g_bits-1 downto 0)
			;o_cos:out std_logic_vector(g_bits-1 downto 0)
			);
	end component;
	
	signal s_sin:std_logic_vector(g_bits-1 downto 0);
	signal s_cos:std_logic_vector(g_bits-1 downto 0);
	signal s_signalI:std_logic_vector(2*g_bits-1 downto 0);
	signal s_signalQ:std_logic_vector(2*g_bits-1 downto 0);
begin
	s_signalI<=std_logic_vector(signed(i_signal)*signed(s_cos));
	s_signalQ<=std_logic_vector(signed(i_signal)*signed(s_sin));
	
	o_signalI<=s_signalI(2*g_bits-3 downto g_bits-2);
	o_signalQ<=s_signalQ(2*g_bits-3 downto g_bits-2);
	
	DDS: DDSSC	port map (i_Clk, i_Ctrl0, i_Ctrl1, i_reset, s_sin, s_cos);
end rtl;
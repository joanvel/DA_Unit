library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use IEEE.math_real.all;

entity DA_Unit is
	generic
		(g_bits:integer:=16
		;g_samples:integer:=10
		;g_Demodulator_modules:integer:=4
		;g_Filter_n_Decimation_modules:integer:=10
		;g_FreePorts:integer:=4
		;g_ADCs:integer:=2
		);
		
	port
		(i_Clk:in std_logic
		;i_sta:in std_logic_vector(g_Filter_n_Decimation_modules-1 downto 0)
		;i_Control0:in std_logic_vector(integer(ceil(LOG2(real(g_ADCs+g_Filter_n_Decimation_modules))))*(g_Demodulator_modules+g_FreePorts)-1 downto 0)
		;i_Control1:in std_logic_vector(integer(ceil(LOG2(real(2*g_Demodulator_modules+g_FreePorts))))*g_Filter_n_Decimation_modules-1 downto 0)
		;i_signals:in std_logic_vector(g_ADCs*g_bits-1 downto 0)
		;i_gain:in std_logic_vector(g_Filter_n_Decimation_modules*g_samples*g_bits-1 downto 0)
		;i_resetFilter:in std_logic_vector(g_Filter_n_Decimation_modules-1 downto 0)
		;i_alpha:in std_logic_vector(g_Demodulator_modules*g_bits-1 downto 0)
		;i_beta:in std_logic_vector(g_Demodulator_modules*g_bits-1 downto 0)
		;i_resetDemo:in std_logic_vector(g_Demodulator_modules-1 downto 0)
		;i_resetDeci:in std_logic_vector(g_Filter_n_Decimation_modules-1 downto 0)
		;i_Decimate:in std_logic_vector(g_Filter_n_Decimation_modules*g_bits-1 downto 0)
		;o_signals:out std_logic_vector(g_Filter_n_Decimation_modules*g_bits-1 downto 0)
		);
end entity;

Architecture rtl of DA_Unit is

	constant c_const0:integer:=integer(ceil(LOG2(real(g_ADCs+g_Filter_n_Decimation_modules))));
	constant c_const1:integer:=integer(ceil(LOG2(real(2*g_Demodulator_modules+g_FreePorts))));
	
	component Demodulator2 is
		generic
			(g_bits:integer:=g_bits
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
	end component;
	
	component filter is
		generic
			(g_bits:integer:=g_bits
			;g_samples:integer:=g_samples
			);
		port
			(i_Clk:in std_logic
			;i_signal:in std_logic_vector(g_bits-1 downto 0)
			;i_gain:in std_logic_vector(g_bits*g_samples-1 downto 0)
			;i_reset:in std_logic
			;o_signal:out std_logic_vector(g_bits-1 downto 0)
			);
	end component;
	
	component Decimator is
		generic
			(g_bits:integer:=g_bits
			);
		port
			(i_Clk:in std_logic
			;i_reset:in std_logic
			;i_signal:in std_logic_vector(g_bits-1 downto 0)
			;i_sta: in std_logic
			;i_Decimate:in std_logic_vector(g_bits-1 downto 0)
			;o_signal:out std_logic_vector(g_bits-1 downto 0)
			);
	end component;
	
	component Multiplexers is
		generic (
			g_select	: positive := positive(ceil(LOG2(real(g_ADCs))));  -- Número de señales de entrada
			g_bits		: positive := g_bits;  -- Número de bits por señal de entrada
			g_DACs		: positive := 5	-- Número de ADCs
		);
		port (
			i_signals : in  std_logic_vector(((2**g_select) * g_bits) - 1 downto 0);
			i_control : in  std_logic_vector(g_select*g_DACs - 1 downto 0);  -- Entrada de control
			o_output  : out std_logic_vector(g_bits*g_DACs - 1 downto 0)
		);
	end component;
	
	type t_signalsIn is array (0 to g_ADCs-1) of std_logic_vector(g_bits-1 downto 0);
	type t_gain is array (0 to g_Filter_n_Decimation_modules-1) of std_logic_vector(g_bits*g_samples-1 downto 0);
	type t_fCtrl is array (0 to g_Demodulator_modules-1) of std_logic_vector(g_bits-1 downto 0);
	type t_signalsOut is array (0 to g_Filter_n_Decimation_modules-1) of std_logic_vector(g_bits-1 downto 0);
	type t_MX0 is array (0 to g_Demodulator_modules+g_FreePorts-1) of std_logic_vector(g_bits-1 downto 0);
	type t_Demo0 is array (0 to 1) of std_logic_vector(g_bits-1 downto 0);
	type t_Demo1 is array (0 to g_Demodulator_modules-1) of t_Demo0;
	
	signal s_gain:t_gain;
	signal s_alpha:t_fCtrl;
	signal s_beta:t_fCtrl;
	signal s_Decimate:t_signalsOut;
	signal s_signals:t_signalsOut;
	signal s_DemoSignalI:t_fCtrl;
	signal s_DemoSignalQ:t_fCtrl;
	
	signal s_MX0:t_MX0;
	signal s_Demo:t_Demo1;
	signal s_MX1:t_signalsOut;
	signal s_Filtered:t_signalsOut;
	
	signal s_signalsMX0: std_logic_vector(((2**c_const0)*g_bits)-1 downto 0);
	signal s_signalsMX1: std_logic_vector(((2**c_const1)*g_bits)-1 downto 0);
	
	signal s_Temp0: std_logic_vector(g_bits*(g_Demodulator_modules+g_FreePorts)-1 downto 0);
	signal s_Temp1: std_logic_vector(g_bits*(g_Filter_n_Decimation_modules)-1 downto 0);
	
	
	
begin
	
	s_signalsMX0(g_ADCs*g_bits-1 downto 0)<=i_signals;
	
	A: for i in 0 to g_Filter_n_Decimation_modules-1 generate
			s_signalsMX0((i+1+g_ADCs)*g_bits-1 downto (i+g_ADCs)*g_bits)<=s_signals(i);
			s_MX1(i)<=s_Temp1((i+1)*g_bits-1 downto i*g_bits);
			s_gain(i)<=i_gain((i+1)*g_bits*g_samples-1 downto i*g_bits*g_samples);
			s_Decimate(i)<=i_Decimate((i+1)*g_bits-1 downto i*g_bits);
			o_signals((i+1)*g_bits-1 downto i*g_bits)<=s_signals(i);
			
			FIR:	filter	port map (i_Clk,s_MX1(i),s_gain(i),i_resetFilter(i),s_Filtered(i));
			
			DEC:	Decimator	port map (i_Clk,i_resetDeci(i),s_Filtered(i),i_sta(i),s_Decimate(i),s_signals(i));
		end generate;
	s_signalsMX0(((2**c_const0)*g_bits)-1 downto (g_Filter_n_Decimation_modules+g_ADCs)*g_bits)<=(others=>'0');
	MX0:	Multiplexers	generic map (c_const0, g_bits, g_Demodulator_modules+g_FreePorts)
								port map (s_signalsMX0, i_Control0, s_Temp0);
	B:	for i in 0 to g_Demodulator_modules-1 generate
			s_MX0(i)<=s_Temp0((i+1)*g_bits-1 downto i*g_bits);
			s_alpha(i)<=i_alpha((i+1)*g_bits-1 downto i*g_bits);
			s_beta(i)<=i_beta((i+1)*g_bits-1 downto i*g_bits);
			
			DM:	Demodulator2	port map (s_MX0(i),i_Clk,s_alpha(i),s_beta(i),i_resetDemo(i),s_DemoSignalI(i),s_DemoSignalQ(i));
			
			s_signalsMX1((i+1)*g_bits-1 downto i*g_bits)<=s_DemoSignalI(i);
			s_signalsMX1((i+1+g_Demodulator_modules)*g_bits-1 downto (i+g_Demodulator_modules)*g_bits)<=s_DemoSignalQ(i);
		end generate;
	C:	for i in 0 to g_FreePorts-1 generate
			s_MX0(i+g_Demodulator_modules)<=s_Temp0((i+1+g_Demodulator_modules)*g_bits-1 downto (i+g_Demodulator_modules)*g_bits);
			s_signalsMX1((i+1+2*g_Demodulator_modules)*g_bits-1 downto (i+2*g_Demodulator_modules)*g_bits)<=s_MX0(i+g_Demodulator_modules);
		end generate;
		
	s_signalsMX1((2**c_const1)*g_bits-1 downto (2*g_Demodulator_modules+g_FreePorts)*g_bits)<=(others=>'0');
	
	MX1:	Multiplexers	generic map (c_const1, g_bits, g_Filter_n_Decimation_modules)
								port map (s_signalsMX1,i_Control1,s_Temp1);
	
		
end rtl;
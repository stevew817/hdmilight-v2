----------------------------------------------------------------------------------
--
-- Copyright (C) 2013 Stephen Robinson
--
-- This file is part of HDMI-Light
--
-- HDMI-Light is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 2 of the License, or
-- (at your option) any later version.
--
-- HDMI-Light is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License
-- along with this code (see the file names COPING).  
-- If not, see <http://www.gnu.org/licenses/>.
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;


entity scaler is
	generic (
		xdivshift : integer := 5;    -- divide X resolution by 32
		ydivshift : integer := 5     -- divide Y resolution by 32
	);
	port ( 
		CLK    : in std_logic;
		CE2    : in std_logic;
		DE     : in std_logic;
		VBLANK : in std_logic;
		RAVG   : in std_logic_vector(7 downto 0);
		GAVG   : in std_logic_vector(7 downto 0);
		BAVG   : in std_logic_vector(7 downto 0);

		LINE_BUF_ADDR : in  std_logic_vector(6 downto 0);
		LINE_BUF_DATA : out std_logic_vector(23 downto 0);
		LINE_READY    : out std_logic;
		LINE_ADDR     : out std_logic_vector(5 downto 0)
	);
end scaler;


architecture Behavioral of scaler is

signal DE_LAST     : std_logic;
signal END_OF_LINE : std_logic;

signal X_COUNT     : std_logic_vector(11 downto 0);
signal X_COUNT_RST : std_logic;

signal Y_COUNT     : std_logic_vector(10 downto 0);
signal Y_COUNT_CE  : std_logic;
signal Y_COUNT_RST : std_logic;

signal Y_COUNT_LAST    : std_logic_vector(10 downto 0);
signal Y_COUNT_LAST_CE : std_logic;

signal LINEBUF_RST  : std_logic;
signal LINEBUF_WE   : std_logic;
signal LINEBUF_ADDR : std_logic_vector(6 downto 0);
signal LINEBUF_D    : std_logic_vector(63 downto 0);
signal LINEBUF_Q    : std_logic_vector(63 downto 0);
signal LINEBUF_DB   : std_logic_vector(63 downto 0);

begin

line_buffer : entity work.blockram
  GENERIC MAP(
	ADDR => 7,
	DATA => 64
  )
  PORT MAP (
	a_clk  => CLK,
	a_rst  => LINEBUF_RST,
	a_en   => CE2,
	a_wr   => LINEBUF_WE,
	a_addr => LINEBUF_ADDR,
	a_din  => LINEBUF_D,
	a_dout => LINEBUF_Q,
	b_clk  => CLK,
	b_en   => '1',
	b_wr   => '0',
	b_rst  => '0',
	b_addr => LINE_BUF_ADDR,
	b_din  => (others => '0'),
	b_dout => LINEBUF_DB
  );


process(CLK)
begin
	if(rising_edge(CLK)) then
		if(CE2 = '1') then
			if(Y_COUNT(4 downto 0) = "11111" and END_OF_LINE = '1') then
				LINE_ADDR  <= Y_COUNT_LAST(10 downto 5);
				LINE_READY <= '1';
			else
				LINE_READY <= '0';
			end if;
		end if;
	end if;
end process;

process(CLK)
begin
	if(rising_edge(CLK)) then
		if(CE2 = '1') then
			if(DE = '0' and DE_LAST = '1') then
				END_OF_LINE <= '1';
			else
				END_OF_LINE <= '0';
			end if;

			DE_LAST <= DE;
		end if;
	end if;
end process;

process(CLK)
begin
	if(rising_edge(CLK)) then
		if(CE2 = '1') then
			if(X_COUNT_RST = '1') then
				X_COUNT <= (others => '0');
			else
				X_COUNT <= std_logic_vector(unsigned(X_COUNT) + 1);
			end if;
		end if;
	end if;
end process;

process(CLK)
begin
	if(rising_edge(CLK)) then
		if(CE2 = '1') then
			if(Y_COUNT_RST = '1') then
				Y_COUNT <= (others => '0');
			else
				if(Y_COUNT_CE = '1') then
					Y_COUNT <= std_logic_vector(unsigned(Y_COUNT) + 1);
				end if;
			end if;
		end if;
	end if;
end process;

process(CLK)
begin
	if(rising_edge(CLK)) then
		if(CE2 = '1') then
			if(Y_COUNT_LAST_CE = '1') then
				Y_COUNT_LAST <= Y_COUNT;
			end if;
		end if;
	end if;
end process;



X_COUNT_RST     <= not DE;
Y_COUNT_RST     <= VBLANK;
Y_COUNT_CE      <= END_OF_LINE;
Y_COUNT_LAST_CE <= END_OF_LINE;


LINEBUF_ADDR  <= Y_COUNT(5) & X_COUNT(9 downto 4);
LINEBUF_RST   <= '1' when Y_COUNT(4 downto 0) = "00000" and X_COUNT(3 downto 1) = "000" else '0';
LINEBUF_WE    <= X_COUNT(0);
LINEBUF_D(63 downto 48) <= (others => '0');
LINEBUF_D(47 downto 32) <= std_logic_vector(unsigned(LINEBUF_Q(47 downto 32)) + unsigned(RAVG));
LINEBUF_D(31 downto 16) <= std_logic_vector(unsigned(LINEBUF_Q(31 downto 16)) + unsigned(GAVG));
LINEBUF_D(15 downto  0) <= std_logic_vector(unsigned(LINEBUF_Q(15 downto  0)) + unsigned(BAVG));



LINE_BUF_DATA( 7 downto  0) <= LINEBUF_DB(15 downto 8);
LINE_BUF_DATA(15 downto  8) <= LINEBUF_DB(31 downto 24);
LINE_BUF_DATA(23 downto 16) <= LINEBUF_DB(47 downto 40);






end Behavioral;


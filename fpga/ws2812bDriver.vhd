----------------------------------------------------------------------------------
--
-- Copyright (C) 2016 Steven Cooreman
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

entity ws2812bDriver is
    Port(-- CLK is 16MHz in HDMI-light
         clk     : in  STD_LOGIC;
         idle    : out STD_LOGIC;
         load    : in  STD_LOGIC;
         datain  : in  STD_LOGIC_VECTOR(23 downto 0);
         dataout : out STD_LOGIC);
end ws2812bDriver;

architecture Behavioral of ws2812bDriver is
    signal bitcount    : std_logic_vector(4 downto 0);
    signal subbitcount : std_logic_vector(4 downto 0);

    signal countEnable : std_logic;

    signal shiftData   : std_logic_vector(23 downto 0);
    signal shiftEnable : std_logic;
    signal shiftOutput : std_logic;

    signal nextOutput : std_logic;

begin
    process(clk)
    begin
        if (rising_edge(clk)) then
            if (load = '1') then
                bitcount    <= (others => '0');
                subbitcount <= (others => '0');
            elsif (countEnable = '1') then
                subbitcount <= std_logic_vector(unsigned(subbitcount) + 1);
                if (subbitcount = "10011") then
                    bitcount    <= std_logic_vector(unsigned(bitcount) + 1);
                    subbitcount <= (others => '0');
                end if;
            end if;
        end if;
    end process;

    process(clk)
    begin
        if (rising_edge(clk)) then
            if (load = '1') then
                shiftData <= datain;
            elsif (shiftEnable = '1') then
                shiftData <= shiftData(22 downto 0) & "0";
            end if;
        end if;
    end process;

    process(clk)
    begin
        if (rising_edge(clk)) then
            dataout <= nextOutput;
        end if;
    end process;

    -- freeze counter when it reaches 24 bytes (24*4 clocks)
    countEnable <= '0' when bitcount = "10111" and subbitcount = "10011" else '1';
    idle        <= not countEnable;

    -- enable shift every 4 clocks
    shiftEnable <= '1' when subbitcount = "10011" else '0';

    shiftOutput <= shiftData(23);

    -- WS2812B specs, in microseconds:
    -- 0 = 0.4 high, 0.85 low
    -- 1 = 0.8 high, 0.45 low
    -- with a .15 tolerance
    -- => 1.25 period
    
    -- so if we reshape this and keep the period (800kHz = 16M div 20)
    -- then we end up with a 6/20 - 13/20 distribution on the 16M clock, such that
    -- 0 = 0.375 high, 0.875 low
    -- 1 = 0.8125 high, 0.4375 low

    nextOutput <= '1' when subbitcount(4 downto 2) = "000" else -- 4 cycles
                  '1' when subbitcount(4 downto 1) = "0010" else -- next 2 cycles, so 6 in total
                  '0' when subbitcount(4 downto 0) = "01101" else -- 13 = 1101
                  '0' when subbitcount(4 downto 1) = "0111" else -- next two: cycles 14 and 15
                  '0' when subbitcount(4) = '1' else -- last section: cycles >= 16
                  shiftOutput;

end Behavioral;

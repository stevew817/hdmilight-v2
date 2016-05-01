--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   23:39:45 04/14/2016
-- Design Name:   
-- Module Name:   D:/bkp/hdmilight-v2/fpga/test_spi.vhd
-- Project Name:  hdmilight
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: spizll
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY test_spi IS
END test_spi;
 
ARCHITECTURE behavior OF test_spi IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT spizll
    PORT(
         sysclk : IN  std_logic;
         rst : IN  std_logic;
         mosi : IN  std_logic;
         miso : OUT  std_logic;
         ss : IN  std_logic;
         sck : IN  std_logic;
         ambi_on : OUT  std_logic;
         mood_on : OUT  std_logic;
         red : OUT  std_logic_vector(7 downto 0);
         blue : OUT  std_logic_vector(7 downto 0);
         green : OUT  std_logic_vector(7 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal sysclk : std_logic := '0';
   signal rst : std_logic := '0';
   signal mosi : std_logic := '0';
   signal ss : std_logic := '0';
   signal sck : std_logic := '0';

 	--Outputs
   signal miso : std_logic;
   signal ambi_on : std_logic;
   signal mood_on : std_logic;
   signal red : std_logic_vector(7 downto 0);
   signal blue : std_logic_vector(7 downto 0);
   signal green : std_logic_vector(7 downto 0);

   -- Clock period definitions
   constant sysclk_period : time := 63 ns;
   
   constant read_cmd  : std_logic_vector(7 downto 0) := "00000001";
   constant write_cmd : std_logic_vector(7 downto 0) := "00000010";
   
   constant addr_ctrl : std_logic_vector(7 downto 0) := "00000000";
   constant addr_r    : std_logic_vector(7 downto 0) := "00000100";
   constant addr_g    : std_logic_vector(7 downto 0) := "00000101";
   constant addr_b    : std_logic_vector(7 downto 0) := "00000110";
   constant addr_w    : std_logic_vector(7 downto 0) := "00000111";
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: spizll PORT MAP (
          sysclk => sysclk,
          rst => rst,
          mosi => mosi,
          miso => miso,
          ss => ss,
          sck => sck,
          ambi_on => ambi_on,
          mood_on => mood_on,
          red => red,
          blue => blue,
          green => green
        );

   -- Clock process definitions
   sysclk_process :process
   begin
		sysclk <= '0';
		wait for sysclk_period/2;
		sysclk <= '1';
		wait for sysclk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
   	-- hold reset state for 100 ns.
   	  rst <= '1';
   	  mosi <= '0';
   	  ss <= '0';
   	  sck <= '0';
   	  
      wait for 100 ns;	
	  
	  rst <= '0';
	  ss <= '1';
	  
      wait for sysclk_period*10;

      -- insert stimulus here 
      ss <= '0';
      
      wait for 1 us;
      for bit in 0 to 7 loop
      	mosi <= write_cmd(7 - bit);
      	wait for 250 ns;
      	sck <= '1';
      	wait for 500 ns;
      	sck <= '0';
      	wait for 250 ns;
      end loop;
      
      for bit in 0 to 7 loop
      	mosi <= addr_ctrl(7 - bit);
      	wait for 250 ns;
      	sck <= '1';
      	wait for 500 ns;
      	sck <= '0';
      	wait for 250 ns;
      end loop;
      
      for bit in 0 to 7 loop
      	mosi <= addr_w(7 - bit);
      	wait for 250 ns;
      	sck <= '1';
      	wait for 500 ns;
      	sck <= '0';
      	wait for 250 ns;
      end loop;
      
      wait for 1 us;
      ss <= '1';
      
      wait for 10 us;
      
      ss <= '0';
      wait for 1 us;
      
      for bit in 0 to 7 loop
      	mosi <= read_cmd(7 - bit);
      	wait for 250 ns;
      	sck <= '1';
      	wait for 500 ns;
      	sck <= '0';
      	wait for 250 ns;
      end loop;
      
      for bit in 0 to 7 loop
      	mosi <= addr_ctrl(7 - bit);
      	wait for 250 ns;
      	sck <= '1';
      	wait for 500 ns;
      	sck <= '0';
      	wait for 250 ns;
      end loop;
      
      for bit in 0 to 7 loop
      	mosi <= '0';
      	wait for 250 ns;
      	sck <= '1';
      	wait for 500 ns;
      	sck <= '0';
      	wait for 250 ns;
      end loop;
      
      wait for 1 us;
      ss <= '1';
            	
      wait;
   end process;

END;

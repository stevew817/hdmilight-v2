library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spizll is
	port (
		sysclk  : in std_logic;
		rst     : in std_logic;
		
		-- SPI input
		mosi    : in std_logic;
		miso    : out std_logic;
		ss      : in std_logic;
		sck     : in std_logic;
		
		-- ambilight output
		ambi_on : out std_logic;
		mood_on : out std_logic;
		
		red     : out std_logic_vector(7 downto 0);
		blue    : out std_logic_vector(7 downto 0);
		green   : out std_logic_vector(7 downto 0)
		
	);
end entity spizll;

architecture Behavioral of spizll is
	
	-- internal shifter
	signal internal_shift_in   : std_logic_vector(7 downto 0);
	signal bit_count_in        : natural range 0 to 7;
	signal cmd_received        : std_logic;
	signal address_received    : std_logic;
	
	signal internal_shift_out  : std_logic_vector(7 downto 0);
	signal bit_count_out       : natural range 0 to 7;
	signal data_out            : std_logic;
	
	--internal buffers
	signal cmd                 : std_logic_vector(7 downto 0);
	signal address             : std_logic_vector(7 downto 0);
	signal data                : std_logic_vector(7 downto 0);
	
	signal ambi_on_buf         : std_logic;
	signal mood_on_buf         : std_logic;
		
	signal red_buf             : std_logic_vector(7 downto 0);
	signal blue_buf            : std_logic_vector(7 downto 0);
	signal green_buf           : std_logic_vector(7 downto 0);
begin
--static assignments
	ambi_on  <= ambi_on_buf;
	mood_on  <= mood_on_buf;
	red      <= red_buf;
	green    <= green_buf;
	blue     <= blue_buf;

-- Receive process
process(ss, rst, sck)
begin
	if(rst = '1' or ss = '1') then
		internal_shift_in   <= (others => '0');
		bit_count_in        <= 0;
		address_received    <= '0';
		cmd_received        <= '0';
		
		cmd                 <= (others => '0');
		address             <= (others => '0');
		data                <= (others => '0');
		
	elsif(rising_edge(sck)) then
		if (bit_count_in < 7) then
			internal_shift_in <= internal_shift_in(6 downto 0) & mosi;
			bit_count_in <= bit_count_in + 1;
		elsif (bit_count_in = 7) then
			internal_shift_in <= (others => '0');
			bit_count_in <= 0;
			if (cmd_received = '0') then
				cmd_received <= '1';
				cmd <= internal_shift_in(6 downto 0) & mosi;
			elsif (address_received = '0') then
				address_received <= '1';
				address <= internal_shift_in(6 downto 0) & mosi;
			else
				data <= internal_shift_in(6 downto 0) & mosi;
			end if;				
		else
			--nop
		end if;
	end if;
end process;

-- Send process
process(ss, rst, sck)
begin
	if(rst = '1' or ss = '1') then
		bit_count_out      <= 0;
		miso               <= '0';
		
	elsif(falling_edge(sck)) then
		if (data_out = '1') then
			if (bit_count_out < 7) then
				bit_count_out <= bit_count_out + 1;
				miso <= internal_shift_out(7 - bit_count_out);
			elsif (bit_count_out = 7) then
				miso <= internal_shift_out(7 - bit_count_out);
				bit_count_out <= 0;		
			else
				--nop
			end if;
		else
			miso <= '0';
		end if;
	end if;
end process;

-- command parser
process(rst, sysclk, ss)
	variable cmd_latched     : std_logic;
	variable add_latched     : std_logic;
	variable internal_add    : std_logic_vector(7 downto 0);
	variable read            : std_logic;
	variable write           : std_logic;
	variable sync_offset     : natural range 0 to 3;
begin
	if(rst = '1') then
		internal_shift_out <= "10100101";
		
		red_buf <= (others => '0');
		blue_buf <= (others => '0');
		green_buf <= (others => '0');
		
		ambi_on_buf <= '1';
		mood_on_buf <= '0';
		
		cmd_latched     := '0';
	    add_latched     := '0';
	    internal_add    := (others => '0');
	    read            := '0';
	    write           := '0';
	    sync_offset     := 0;
		
		data_out        <= '0';
	elsif(ss = '1') then
		cmd_latched     := '0';
	    add_latched     := '0';
	    internal_add    := (others => '0');
	    read            := '0';
	    write           := '0';
	    sync_offset     := 0;
		
		data_out        <= '0';
	elsif(rising_edge(sysclk)) then
		if(bit_count_in = 0) then
			if(sync_offset < 3) then
				sync_offset := sync_offset + 1;
			end if;
			
			if(sync_offset = 2) then	
				if( cmd_received = '1' and cmd_latched = '0' ) then
					cmd_latched := '1';
					-- process command
					if( cmd = "00000001" ) then
						--read
						read := '1';
						write := '0';
					elsif( cmd = "00000010" ) then
						--write
						read := '0';
						write := '1';
					end if;
				elsif( address_received = '1' and add_latched = '0' ) then
					add_latched := '1';
					internal_add := address;
					-- process address here, set up shift-out-buffer if read command
					if( read = '1' ) then
						if( internal_add = "00000000" ) then
							--return command byte
							internal_shift_out <= "000000" & mood_on_buf & ambi_on_buf;
						elsif( internal_add(1 downto 0) = "00" ) then
							internal_shift_out <= red_buf;
						elsif( internal_add(1 downto 0) = "01" ) then
							internal_shift_out <= green_buf;
						elsif( internal_add(1 downto 0) = "10" ) then
							internal_shift_out <= blue_buf;
						else
							internal_shift_out <= "10101010";
						end if;
						data_out <= '1';
					else
						data_out <= '0';
					end if;
				elsif( cmd_received = '1' and address_received = '1' ) then
					if( read = '1' ) then
						internal_add := std_logic_vector(unsigned(internal_add) + 1);
						if(unsigned(internal_add) > 7) then
							internal_add := (others => '0');
						end if;
						
						if( internal_add = "00000000" ) then
							--return command byte
							internal_shift_out <= "000000" & mood_on_buf & ambi_on_buf;
						elsif( internal_add(1 downto 0) = "00" ) then
							internal_shift_out <= red_buf;
						elsif( internal_add(1 downto 0) = "01" ) then
							internal_shift_out <= green_buf;
						elsif( internal_add(1 downto 0) = "10" ) then
							internal_shift_out <= blue_buf;
						else
							internal_shift_out <= "10101010";
						end if;
					elsif( write = '1' and (unsigned(internal_add) < 8)) then
						
						if( internal_add = "00000000" ) then
							--write command byte
							mood_on_buf <= data(1);
							ambi_on_buf <= data(0);
						elsif( internal_add(1 downto 0) = "00" ) then
							red_buf <= data;
						elsif( internal_add(1 downto 0) = "01" ) then
							green_buf <= data;
						elsif( internal_add(1 downto 0) = "10" ) then
							blue_buf <= data;
						end if;
						
						internal_add := std_logic_vector(unsigned(internal_add) + 1);
					end if;
				end if;
			end if;
		else
			sync_offset := 0;
		end if;
	end if;
end process;
	

end architecture Behavioral;

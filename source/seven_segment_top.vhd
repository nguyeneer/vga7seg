-- best viewed with TAB = 2
library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;
	use ieee.numeric_std.all;

library UNISIM;
	use UNISIM.Vcomponents.all;

-- simple top module to demonstrate usage of the VGA seven segment module
entity seven_segment_top is
	port(
		CLK_IN				: in  std_logic;
		--
		O_VIDEO_R			: out std_logic;
		O_VIDEO_G			: out std_logic;
		O_VIDEO_B			: out std_logic;
		O_HSYNC				: out std_logic;
		O_VSYNC				: out std_logic
		);
end seven_segment_top;

architecture rtl of seven_segment_top is
	signal clk						: std_logic;
	signal clk_seconds		: std_logic;
	signal VideoR					: std_logic;
	signal VideoG					: std_logic;
	signal VideoB					: std_logic;
	signal HSync					: std_logic;
	signal VSync					: std_logic;
	signal digit_en				: std_logic_vector(29 downto 0) := (others => '0');
	signal HCnt						: std_logic_vector( 9 downto 0) := (others => '0');
	signal VCnt						: std_logic_vector( 9 downto 0) := (others => '0');
	signal counter				: std_logic_vector(23 downto 0) := (others => '0');
	signal s_sec					: std_logic_vector( 7 downto 0) := x"56";   -- BCD value
	signal s_min					: std_logic_vector( 7 downto 0) := x"34";   -- BCD value
	signal s_hrs					: std_logic_vector( 7 downto 0) := x"12";   -- BCD value
	signal s_day					: std_logic_vector( 7 downto 0) := x"11";   -- BCD value
	signal s_mth					: std_logic_vector( 7 downto 0) := x"11";   -- BCD value
	signal s_yrs					: std_logic_vector(15 downto 0) := x"2011"; -- BCD value
	constant offsetx			: integer := 8;
	constant offsety			: integer := 8;

begin
	-- connect internal video signals to outputs
	O_VIDEO_R <= VideoR;
	O_VIDEO_G <= VideoG;
	O_VIDEO_B <= VideoB;
	O_HSYNC		<= HSync;
	O_VSYNC		<= VSync;

	-- use a DCM to generate 20Mhz clock required by VGA process
	u_clocks : entity work.clock
	port map (
		I_CLK_REF => CLK_IN,
		I_RESET		=> '0',
		O_CLK			=> clk
	 );

	-- VGA 640x480 resolution
	VGA : process
		begin
		wait until rising_edge(clk);
		if (HCnt = 640) then
 			HCnt <= (others => '0');
			if (VCnt = 520) then
				VCnt <= (others => '0');
			else
				VCnt <= VCnt + 1;
	 		end if;
		else
			HCnt <= HCnt + 1;
		end if;

		if (HCnt > 525) and (HCnt < 602) then
			HSync <= '0';
		else
			HSync <= '1';
		end if;

		if (VCnt = 490)  or (VCnt = 491) then
			VSync <= '0';
		else
			VSync <= '1';
		end if;

		-- cludgy color assignment to digits, could be done much better
		VideoR <= digit_en(0)  or digit_en(1)  or digit_en(2)  or digit_en(3)  or digit_en(4)  or digit_en(5)  or digit_en(6)  or digit_en(7)  or -- first 8 static digits
							digit_en(24) or digit_en(25) or digit_en(26) or digit_en(27) or digit_en(28) or digit_en(29) ; -- time
		VideoG <= digit_en(8)  or digit_en(9)  or digit_en(10) or digit_en(11) or digit_en(12) or digit_en(13) or digit_en(14) or digit_en(15) or -- last 8 static digits
							digit_en(16) or digit_en(17) or digit_en(18) or digit_en(19) or digit_en(20) or digit_en(21) or digit_en(22) or digit_en(23) or --date
							digit_en(24) or digit_en(25) or digit_en(26) or digit_en(27) or digit_en(28) or digit_en(29) ; -- time
		VideoB <= digit_en(16) or digit_en(17) or digit_en(18) or digit_en(19) or digit_en(20) or digit_en(21) or digit_en(22) or digit_en(23);   --date
	end process VGA;

	-- create a bunch of static digits on screen to show dex digits 0 though F
	d : for i in 0 to 15 generate
	begin
		digits : entity work.digit
		port map (
			clk     => clk,
			offsetx => 8, -- place at base coord 8,8 on VGA screen
			offsety => 8,
			index   => i,
			seglen  => i*2+2, -- incrementally bigger digits
			gap     => 0,
			hcnt    => HCnt,
			vcnt    => VCnt,
			value   => std_logic_vector(to_unsigned(i,4)), -- assign a static value to each digit
			enable  => digit_en(i) -- accumulate enables in bit vector (this could be done better)
		);
	end generate;

	-- create digits for year
	year : for i in 0 to 3 generate
	begin
		year : entity work.digit
		port map (
			clk     => clk,
			offsetx => 112, -- place at coord 108,80 on VGA screen
			offsety => 80,
			index   => i,
			seglen  => 14,
			gap     => 6,
			hcnt    => HCnt,
			vcnt    => VCnt,
			value   => s_yrs(((4-i)*4)-1 downto ((4-i)*4)-4), -- assign a dynamic value to each digit
			enable  => digit_en(i+16) -- accumulate enables in bit vector (this could be done better)
		);
	end generate;

	-- create digits for month
	month : for i in 0 to 1 generate
	begin
		month : entity work.digit
		port map (
			clk     => clk,
			offsetx => 212, -- place at coord 208,80 on VGA screen
			offsety => 80,
			index   => i,
			seglen  => 14,
			gap     => 6,
			hcnt    => HCnt,
			vcnt    => VCnt,
			value   => s_mth(((2-i)*4)-1 downto ((2-i)*4)-4), -- assign a dynamic value to each digit
			enable  => digit_en(i+20) -- accumulate enables in bit vector (this could be done better)
		);
	end generate;

	-- create digits for day
	day : for i in 0 to 1 generate
	begin
		day : entity work.digit
		port map (
			clk     => clk,
			offsetx => 272, -- place at coord 268,80 on VGA screen
			offsety => 80,
			index   => i,
			seglen  => 14,
			gap     => 6,
			hcnt    => HCnt,
			vcnt    => VCnt,
			value   => s_mth(((2-i)*4)-1 downto ((2-i)*4)-4), -- assign a dynamic value to each digit
			enable  => digit_en(i+22) -- accumulate enables in bit vector (this could be done better)
		);
	end generate;

	-- create digits for hour
	hour : for i in 0 to 1 generate
	begin
		hour : entity work.digit
		port map (
			clk     => clk,
			offsetx => 200, -- place at coord 268,120 on VGA screen
			offsety => 160,
			index   => i,
			seglen  => 8,
			gap     => 2,
			hcnt    => HCnt,
			vcnt    => VCnt,
			value   => s_hrs(((2-i)*4)-1 downto ((2-i)*4)-4), -- assign a dynamic value to each digit
			enable  => digit_en(i+24) -- accumulate enables in bit vector (this could be done better)
		);
	end generate;

	-- create digits for minute
	minute : for i in 0 to 1 generate
	begin
		minute : entity work.digit
		port map (
			clk     => clk,
			offsetx => 230, -- place at coord 268,120 on VGA screen
			offsety => 160,
			index   => i,
			seglen  => 8,
			gap     => 2,
			hcnt    => HCnt,
			vcnt    => VCnt,
			value   => s_min(((2-i)*4)-1 downto ((2-i)*4)-4), -- assign a dynamic value to each digit
			enable  => digit_en(i+26) -- accumulate enables in bit vector (this could be done better)
		);
	end generate;

	-- create digits for second
	second : for i in 0 to 1 generate
	begin
		second : entity work.digit
		port map (
			clk     => clk,
			offsetx => 260, -- place at coord 268,120 on VGA screen
			offsety => 160,
			index   => i,
			seglen  => 8,
			gap     => 2,
			hcnt    => HCnt,
			vcnt    => VCnt,
			value   => s_sec(((2-i)*4)-1 downto ((2-i)*4)-4), -- assign a dynamic value to each digit
			enable  => digit_en(i+28) -- accumulate enables in bit vector (this could be done better)
		);
	end generate;

	-- divide main 20Mhz clock to get 1Hz
	seconds : process
	begin
		wait until rising_edge(clk);
		if counter = std_logic_vector(to_unsigned(10000000,24)) then
			counter <= (others => '0');
			clk_seconds <= not clk_seconds;
		else
			counter <= counter + 1;
		end if;
	end process;

	-- just a dumb clock, for demo only
	-- does not increment day/month/year
	-- the hours count beyond 24...
	-- uses BCD (binary coded decimal) values
	chrono : process
	begin
		wait until rising_edge(clk_seconds);
		s_sec(3 downto 0) <= s_sec(3 downto 0) + 1;
		if s_sec(3 downto 0) = x"9" then
			s_sec(3 downto 0) <= (others => '0');
			s_sec(7 downto 4) <= s_sec(7 downto 4) + 1;
			if s_sec(7 downto 4) = x"5" then
				s_sec(7 downto 4) <= (others => '0');
				s_min(3 downto 0) <= s_min(3 downto 0) + 1;
				if s_min(3 downto 0) = x"9" then
					s_min(3 downto 0) <= (others => '0');
					s_min(7 downto 4) <= s_min(7 downto 4) + 1;
					if s_min(7 downto 4) = x"5" then
						s_min(7 downto 4) <= (others => '0');
						s_hrs(3 downto 0) <= s_hrs(3 downto 0) + 1;
						if s_hrs(3 downto 0) = x"9" then
							s_hrs(3 downto 0) <= (others => '0');
							s_hrs(7 downto 4) <= s_hrs(7 downto 4) + 1;
						end if;
					end if;
				end if;
			end if;
		end if;
	end process;
end;

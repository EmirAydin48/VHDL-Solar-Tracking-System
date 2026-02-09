library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity top_level is
    Port ( 
        clk         : in  STD_LOGIC;
        reset       : in  STD_LOGIC;
        
        vauxp6      : in  STD_LOGIC;  
        vauxn6      : in  STD_LOGIC;  
        vauxp14     : in  STD_LOGIC;  
        vauxn14     : in  STD_LOGIC;  
        
        servo_pwm   : out STD_LOGIC; 
        
        lcd_rs      : out STD_LOGIC;
        lcd_en      : out STD_LOGIC;
        lcd_data    : out STD_LOGIC_VECTOR(7 downto 0);
        
        led         : out STD_LOGIC_VECTOR(15 downto 0)
    );
end top_level;

architecture Behavioral of top_level is

    component clk_divider
    Port ( clk_in, reset : in STD_LOGIC; pulse_1mhz, pulse_1hz : out STD_LOGIC );
    end component;

    component xadc_interface
    Port ( clk, reset : in STD_LOGIC; vauxp6_in, vauxn6_in, vauxp14_in, vauxn14_in : in STD_LOGIC; adc_data_L, adc_data_R : out STD_LOGIC_VECTOR(11 downto 0) );
    end component;

    component sensor_compare
    Port ( clk : in STD_LOGIC; ldr_left, ldr_right : in STD_LOGIC_VECTOR(11 downto 0); move_left, move_right : out STD_LOGIC; diff_out : out integer );
    end component;

    component pwm_gen
    Port ( 
        clk, reset, enable_1mhz, move_left, move_right : in STD_LOGIC; 
        diff_val : in integer; 
        pwm_out : out STD_LOGIC;
        is_moving : out STD_LOGIC
    );
    end component;

    component lcd_controller
    Port ( clk, reset : in STD_LOGIC; val_left, val_right : in STD_LOGIC_VECTOR(11 downto 0); go_left, go_right : in STD_LOGIC; lcd_rs, lcd_en : out STD_LOGIC; lcd_data : out STD_LOGIC_VECTOR(7 downto 0) );
    end component;

    signal tick_1mhz, tick_1hz : std_logic;
    signal val_left, val_right : std_logic_vector(11 downto 0);
    signal go_left, go_right : std_logic;
    signal hb_state : std_logic := '0';
    signal diff_wire : integer range 0 to 4095;
    signal servo_active : std_logic;
    signal show_left    : std_logic;
    signal show_right   : std_logic;
begin
	U1_Clock: clk_divider port map (
		clk => clk, 
		reset => reset,
		pulse_1mhz => tick_1mhz, 
		pulse_1hz => tick_1hz);
    
    U2_Eyes: xadc_interface port map (
		clk => clk, 
		reset => reset,
		vauxp6_in => vauxp6, 
		vauxn6_in => vauxn6,
		vauxp14_in => vauxp14,
		vauxn14_in => vauxn14, 
		adc_data_L => val_left,
		adc_data_R => val_right);

	U3_Brain: sensor_compare port map (
        clk => clk, 
        ldr_left => val_left, 
        ldr_right => val_right, 
        move_left => go_left, 
        move_right => go_right,
        diff_out => diff_wire
    );
    
    U4_Muscle: pwm_gen port map (
        clk => clk, 
        reset => reset, 
        enable_1mhz => tick_1mhz, 
        move_left => go_left, 
        move_right => go_right, 
        diff_val => diff_wire, 
        pwm_out => servo_pwm,
        is_moving => servo_active
    );
    
    show_left  <= go_left AND servo_active;
    show_right <= go_right AND servo_active;
    
    U5_Face: lcd_controller port map (
        clk => clk, 
        reset => reset,
        val_left => val_left, 
        val_right => val_right, 
        go_left => show_left,
        go_right => show_right,
        lcd_rs => lcd_rs, 
        lcd_en => lcd_en, 
        lcd_data => lcd_data
    );

    process(clk) begin
        if rising_edge(clk) and tick_1hz = '1' then hb_state <= not hb_state; end if;
    end process;

    led(15) <= show_left;
    led(0)  <= show_right; 
    led(7) <= hb_state;
    led(14 downto 8) <= (others => '0'); led(6 downto 1) <= (others => '0');

end Behavioral;
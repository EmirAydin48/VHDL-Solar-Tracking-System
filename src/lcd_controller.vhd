library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity lcd_controller is
    Port ( 
        clk         : in  STD_LOGIC;
        reset       : in  STD_LOGIC;
        
        val_left    : in  STD_LOGIC_VECTOR(11 downto 0);
        val_right   : in  STD_LOGIC_VECTOR(11 downto 0);
        go_left     : in  STD_LOGIC;
        go_right    : in  STD_LOGIC;
        
        lcd_rs      : out STD_LOGIC;
        lcd_en      : out STD_LOGIC;
        lcd_data    : out STD_LOGIC_VECTOR(7 downto 0)
    );
end lcd_controller;

architecture Behavioral of lcd_controller is

    type state_type is (IDLE, INIT, SEND_CMD, SEND_DATA, WAIT_EN, DELAY_STATE);
    signal state : state_type := INIT;
    
    signal byte_to_send : std_logic_vector(7 downto 0);
    signal wait_counter : integer := 0;
    signal wait_limit   : integer := 0;
    signal init_step    : integer range 0 to 5 := 0;
    signal char_index   : integer range 0 to 40 := 0;

    type screen_array is array (0 to 31) of std_logic_vector(7 downto 0);
    signal lcd_buffer : screen_array := (others => x"20");
    
    signal cycle_timer  : integer := 0;
    signal display_mode : std_logic := '0'; 
    
    signal refresh_timer : integer := 0;
    signal latched_left  : std_logic_vector(11 downto 0) := (others => '0');
    signal latched_right : std_logic_vector(11 downto 0) := (others => '0');

    function to_hex(val : std_logic_vector(3 downto 0)) return std_logic_vector is
    begin
        if unsigned(val) < 10 then
            return std_logic_vector(to_unsigned(48 + to_integer(unsigned(val)), 8));
        else
            return std_logic_vector(to_unsigned(55 + to_integer(unsigned(val)), 8));
        end if;
    end function;

begin

    process(clk)
        variable v_int : integer;
        variable d3, d2, d1, d0 : integer;
    begin
        if rising_edge(clk) then
            
            if refresh_timer < 50000000 then
                refresh_timer <= refresh_timer + 1;
            else
                refresh_timer <= 0;
                latched_left  <= val_left;
                latched_right <= val_right;
            end if;

            if cycle_timer < 200000000 then
                cycle_timer <= cycle_timer + 1;
            else
                cycle_timer <= 0;
                display_mode <= not display_mode;
            end if;

            if display_mode = '0' then
                
                lcd_buffer(0) <= x"52";
                lcd_buffer(1) <= x"49";
                lcd_buffer(2) <= x"47";
                lcd_buffer(3) <= x"48";
                lcd_buffer(4) <= x"54";
                lcd_buffer(5) <= x"3A";
                lcd_buffer(6) <= x"20";
                
                v_int := to_integer(unsigned(latched_right));
                
                if v_int > 4095 then v_int := 4095; end if;
                
                d3 := v_int / 1000;
                d2 := (v_int / 100) mod 10;
                d1 := (v_int / 10) mod 10;
                d0 := v_int mod 10;
                
                lcd_buffer(7)  <= std_logic_vector(to_unsigned(48 + d3, 8)); 
                lcd_buffer(8)  <= std_logic_vector(to_unsigned(48 + d2, 8));
                lcd_buffer(9)  <= std_logic_vector(to_unsigned(48 + d1, 8)); 
                lcd_buffer(10) <= std_logic_vector(to_unsigned(48 + d0, 8));
                
                lcd_buffer(11 to 15) <= (others => x"20");

                lcd_buffer(16) <= x"4C";
                lcd_buffer(17) <= x"45";
                lcd_buffer(18) <= x"46";
                lcd_buffer(19) <= x"54";
                lcd_buffer(20) <= x"20";
                lcd_buffer(21) <= x"3A";
                lcd_buffer(22) <= x"20";
                
  
                v_int := to_integer(unsigned(latched_left));
                
                if v_int > 4095 then v_int := 4095; end if;

                d3 := v_int / 1000;
                d2 := (v_int / 100) mod 10;
                d1 := (v_int / 10) mod 10;
                d0 := v_int mod 10;

                lcd_buffer(23) <= std_logic_vector(to_unsigned(48 + d3, 8));
                lcd_buffer(24) <= std_logic_vector(to_unsigned(48 + d2, 8));
                lcd_buffer(25) <= std_logic_vector(to_unsigned(48 + d1, 8));
                lcd_buffer(26) <= std_logic_vector(to_unsigned(48 + d0, 8));

                lcd_buffer(27 to 31) <= (others => x"20");

            else
                if go_left = '1' then
                    lcd_buffer(0) <= x"54"; lcd_buffer(1) <= x"55"; lcd_buffer(2) <= x"52"; lcd_buffer(3) <= x"4E"; lcd_buffer(4) <= x"20"; lcd_buffer(5) <= x"4C"; lcd_buffer(6) <= x"45"; lcd_buffer(7) <= x"46"; lcd_buffer(8) <= x"54"; lcd_buffer(9 to 31) <= (others => x"20");
                elsif go_right = '1' then
                    lcd_buffer(0) <= x"54"; lcd_buffer(1) <= x"55"; lcd_buffer(2) <= x"52"; lcd_buffer(3) <= x"4E"; lcd_buffer(4) <= x"20"; lcd_buffer(5) <= x"52"; lcd_buffer(6) <= x"49"; lcd_buffer(7) <= x"47"; lcd_buffer(8) <= x"48"; lcd_buffer(9) <= x"54"; lcd_buffer(10 to 31) <= (others => x"20");
                else
                   -- "IDLE        "
                    lcd_buffer(0) <= x"49";
                    lcd_buffer(1) <= x"44";
                    lcd_buffer(2) <= x"4C";
                    lcd_buffer(3) <= x"45";
                    lcd_buffer(4 to 31) <= (others => x"20");
                end if;
            end if;
        end if;
    end process;
    
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                state <= INIT;
                init_step <= 0;
                wait_counter <= 0;
            else
                case state is
                    when INIT =>
                        wait_limit <= 2000000;
                        if wait_counter < wait_limit then
                            wait_counter <= wait_counter + 1;
                        else
                            wait_counter <= 0;
                            case init_step is
                                when 0 => byte_to_send <= x"38"; state <= SEND_CMD;
                                when 1 => byte_to_send <= x"0C"; state <= SEND_CMD;
                                when 2 => byte_to_send <= x"01"; state <= SEND_CMD;
                                when 3 => byte_to_send <= x"06"; state <= SEND_CMD;
                                when others => state <= IDLE;
                            end case;
                            init_step <= init_step + 1;
                        end if;

                    when SEND_CMD =>
                        lcd_rs <= '0';
                        lcd_data <= byte_to_send;
                        lcd_en <= '1';
                        state <= WAIT_EN;
                        
                    when SEND_DATA =>
                        lcd_rs <= '1';
                        lcd_data <= byte_to_send;
                        lcd_en <= '1';
                        state <= WAIT_EN;

                    when WAIT_EN =>
                        if wait_counter < 5000 then
                            wait_counter <= wait_counter + 1;
                        else
                            lcd_en <= '0';
                            wait_counter <= 0;
                            state <= DELAY_STATE;
                        end if;

                    when DELAY_STATE =>
                        if wait_counter < 200000 then
                            wait_counter <= wait_counter + 1;
                        else
                            wait_counter <= 0;
                            if init_step < 5 then
                                state <= INIT;
                            else
                                state <= IDLE;
                            end if;
                        end if;

                    when IDLE =>
                        if char_index = 0 then
                            byte_to_send <= x"80"; -- Line 1
                            state <= SEND_CMD;
                        elsif char_index > 0 and char_index < 17 then
                            byte_to_send <= lcd_buffer(char_index - 1); 
                            state <= SEND_DATA;
                        elsif char_index = 17 then
                            byte_to_send <= x"C0"; -- Line 2
                            state <= SEND_CMD;
                        elsif char_index > 17 and char_index < 34 then
                            byte_to_send <= lcd_buffer(char_index - 2);
                            state <= SEND_DATA;
                        elsif char_index = 34 then
                            char_index <= 0;
                        end if;
                        
                        if char_index < 34 then
                            char_index <= char_index + 1;
                        end if;
                end case;
            end if;
        end if;
    end process;

end Behavioral;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity pwm_gen is
    Port ( 
        clk         : in  STD_LOGIC;
        reset       : in  STD_LOGIC;
        enable_1mhz : in  STD_LOGIC;
        move_left   : in  STD_LOGIC;
        move_right  : in  STD_LOGIC;
        diff_val    : in  integer; 
        pwm_out     : out STD_LOGIC;
        is_moving   : out STD_LOGIC
    );
end pwm_gen;

architecture Behavioral of pwm_gen is

    constant MIN_POS : integer := 500;
    constant MAX_POS : integer := 2500;
    constant CENTER  : integer := 1500;
    
    constant PWM_PERIOD : integer := 20000;

    signal target_pos  : integer range MIN_POS to MAX_POS := CENTER;
    signal current_pos : integer range MIN_POS to MAX_POS := CENTER;
    signal pwm_count   : integer range 0 to PWM_PERIOD := 0;
    
    signal ramp_timer  : integer range 0 to 5000 := 0; 
    
    signal filter_acc  : integer := 0; 
    signal smooth_diff : integer := 0;

begin

    process(clk, reset)
        variable calc_target: integer;
        variable dist       : integer;
    begin
        if reset = '1' then
            current_pos <= CENTER;
            target_pos  <= CENTER;
            pwm_count   <= 0;
            pwm_out     <= '0';
            ramp_timer  <= 0;
            filter_acc  <= 0;
            smooth_diff <= 0;
            
        elsif rising_edge(clk) then
            if enable_1mhz = '1' then
                
                if pwm_count < PWM_PERIOD - 1 then
                    pwm_count <= pwm_count + 1;
                else
                    pwm_count <= 0;
                end if;

                if pwm_count < current_pos then
                    pwm_out <= '1';
                else
                    pwm_out <= '0';
                end if;

                if filter_acc = 0 then 
                    filter_acc <= diff_val * 32;
                else
                    filter_acc <= filter_acc - (filter_acc / 32) + diff_val;
                end if;
                
                smooth_diff <= filter_acc / 32;
     
                if move_left = '1' then
                    calc_target := CENTER + smooth_diff;
                elsif move_right = '1' then
                    calc_target := CENTER - smooth_diff;
                else
                    calc_target := CENTER;
                end if;

                if calc_target > MAX_POS then calc_target := MAX_POS; end if;
                if calc_target < MIN_POS then calc_target := MIN_POS; end if;

                if calc_target > target_pos then
                    dist := calc_target - target_pos;
                else
                    dist := target_pos - calc_target;
                end if;

                if dist > 40 then 
                    target_pos <= calc_target;
                end if;

                if ramp_timer < 1500 then
                    ramp_timer <= ramp_timer + 1;
                else
                    ramp_timer <= 0;
                    
                    if current_pos < target_pos then
                        current_pos <= current_pos + 1;
                    elsif current_pos > target_pos then
                        current_pos <= current_pos - 1;
                    end if;
                end if;
                
            end if;
        end if;
    end process;
is_moving <= '1' when (current_pos /= target_pos) else '0';
end Behavioral;
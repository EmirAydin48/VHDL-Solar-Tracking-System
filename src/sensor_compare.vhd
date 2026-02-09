library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sensor_compare is
    Port ( 
        clk         : in  STD_LOGIC;
        ldr_left    : in  STD_LOGIC_VECTOR (11 downto 0);
        ldr_right   : in  STD_LOGIC_VECTOR (11 downto 0);
        move_left   : out STD_LOGIC;
        move_right  : out STD_LOGIC;
        diff_out    : out integer range 0 to 4095
    );
end sensor_compare;

architecture Behavioral of sensor_compare is
    constant THRESHOLD : integer := 300;
    signal left_val  : integer range 0 to 4095;
    signal right_val : integer range 0 to 4095;
    signal diff_temp : integer range 0 to 4095;
begin
    left_val  <= to_integer(unsigned(ldr_left));
    right_val <= to_integer(unsigned(ldr_right));

    process(clk)
    begin
        if rising_edge(clk) then
            if left_val > right_val then
                diff_temp <= left_val - right_val;
            else
                diff_temp <= right_val - left_val;
            end if;
            
            diff_out <= diff_temp;

            if left_val > (right_val + THRESHOLD) then
                move_left  <= '1';
                move_right <= '0';
            elsif right_val > (left_val + THRESHOLD) then
                move_left  <= '0';
                move_right <= '1';
            else
                move_left  <= '0';
                move_right <= '0';
            end if;
        end if;
    end process;
end Behavioral;
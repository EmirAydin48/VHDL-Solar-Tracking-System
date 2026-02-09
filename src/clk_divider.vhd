library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity clk_divider is
    Port ( 
        clk      : in  STD_LOGIC;
        reset       : in  STD_LOGIC;
        pulse_1mhz  : out STD_LOGIC;
        pulse_1hz   : out STD_LOGIC
    );
end clk_divider;

architecture Behavioral of clk_divider is

    constant LIMIT_1MHZ : integer := 100;
    constant LIMIT_1HZ  : integer := 100000000;

    signal count_1mhz   : integer range 0 to LIMIT_1MHZ := 0;
    signal count_1hz    : integer range 0 to LIMIT_1HZ  := 0;

begin

    process(clk, reset)
    begin
        if reset = '1' then
            count_1mhz <= 0;
            count_1hz  <= 0;
            pulse_1mhz <= '0';
            pulse_1hz  <= '0';
            
        elsif rising_edge(clk) then
            
            if count_1mhz = LIMIT_1MHZ - 1 then
                count_1mhz <= 0;
                pulse_1mhz <= '1';
            else
                count_1mhz <= count_1mhz + 1;
                pulse_1mhz <= '0';
            end if;

            if count_1hz = LIMIT_1HZ - 1 then
                count_1hz <= 0;
                pulse_1hz <= '1';
            else
                count_1hz <= count_1hz + 1;
                pulse_1hz <= '0';
            end if;
            
        end if;
    end process;

end Behavioral;
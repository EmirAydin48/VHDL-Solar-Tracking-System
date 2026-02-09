library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity xadc_interface is
    Port ( 
        clk         : in  STD_LOGIC;
        reset       : in  STD_LOGIC;
        vauxp6_in   : in  STD_LOGIC;
        vauxn6_in   : in  STD_LOGIC;
        vauxp14_in  : in  STD_LOGIC;
        vauxn14_in  : in  STD_LOGIC;
        adc_data_L  : out STD_LOGIC_VECTOR (11 downto 0);
        adc_data_R  : out STD_LOGIC_VECTOR (11 downto 0)
    );
end xadc_interface;

architecture Behavioral of xadc_interface is

    COMPONENT xadc_wiz_0
    PORT (
        daddr_in    : IN STD_LOGIC_VECTOR(6 DOWNTO 0);
        den_in      : IN STD_LOGIC;
        di_in       : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        dwe_in      : IN STD_LOGIC;
        do_out      : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        drdy_out    : OUT STD_LOGIC;
        dclk_in     : IN STD_LOGIC;
        reset_in    : IN STD_LOGIC;
        vp_in       : IN STD_LOGIC;
        vn_in       : IN STD_LOGIC;
        vauxp6      : IN STD_LOGIC;
        vauxn6      : IN STD_LOGIC;
        vauxp14     : IN STD_LOGIC;
        vauxn14     : IN STD_LOGIC;
        eoc_out     : OUT STD_LOGIC;
        channel_out : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
        alarm_out   : OUT STD_LOGIC;
        eos_out     : OUT STD_LOGIC;
        busy_out    : OUT STD_LOGIC
    );
    END COMPONENT;

    signal daddr    : std_logic_vector(6 downto 0);
    signal den      : std_logic;
    signal do_out   : std_logic_vector(15 downto 0);
    signal drdy     : std_logic;
    signal state    : integer range 0 to 3 := 0; 
    
    constant ADDR_LEFT  : std_logic_vector(6 downto 0) := "0010110";
    constant ADDR_RIGHT : std_logic_vector(6 downto 0) := "0011110";

begin

    XADC_INST : xadc_wiz_0
    port map (
        daddr_in    => daddr,
        den_in      => den,
        di_in       => (others => '0'),
        dwe_in      => '0',
        do_out      => do_out,
        drdy_out    => drdy,
        dclk_in     => clk,
        reset_in    => reset,
        vp_in       => '0', vn_in => '0',
        vauxp6      => vauxp6_in,   vauxn6  => vauxn6_in,
        vauxp14     => vauxp14_in,  vauxn14 => vauxn14_in,
        eoc_out => open, channel_out => open, alarm_out => open, eos_out => open, busy_out => open
    );

    process(clk, reset)
    begin
        if reset = '1' then
            state <= 0;
            den <= '0';
            adc_data_L <= (others => '0');
            adc_data_R <= (others => '0');
        elsif rising_edge(clk) then
            case state is
                when 0 => 
                    daddr <= ADDR_LEFT; 
                    den <= '1'; 
                    state <= 1;
                
                when 1 => 
                    den <= '0';
                    if drdy = '1' then 
                        adc_data_L <= do_out(15 downto 4);
                        state <= 2; 
                    end if;

                when 2 => 
                    daddr <= ADDR_RIGHT; 
                    den <= '1'; 
                    state <= 3;

                when 3 => 
                    den <= '0';
                    if drdy = '1' then 
                        adc_data_R <= do_out(15 downto 4); 
                        state <= 0;
                    end if;
            end case;
        end if;
    end process;

end Behavioral;
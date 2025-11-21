library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_uart_rx is
end tb_uart_rx;

architecture sim of tb_uart_rx is

    component uart_rx is
        port (
            clock_in            : in std_logic;
            reset_in            : in std_logic;
            uart_data_rx        : in std_logic;
            uart_rate_rx_sel    : in std_logic_vector(1 downto 0);
            
            data_p_out          : out std_logic_vector(7 downto 0);
            data_p_en_out       : out std_logic
        );
    end component;

    signal clock_in         : std_logic := '0';
    signal reset_in         : std_logic := '1';
    signal uart_data_rx     : std_logic := '1';
    signal uart_rate_rx_sel : std_logic_vector(1 downto 0) := "00"; -- 9600
    
    signal data_p_out       : std_logic_vector(7 downto 0);
    signal data_p_en_out    : std_logic;

    constant CLK_PERIOD : time := 10 ns;        -- 100 MHz
    constant BAUD_DIV   : integer := 10416;     -- 9600 
    constant BIT_TIME   : time := CLK_PERIOD * BAUD_DIV;

begin

    clock_process : process
    begin
        clock_in <= '0';
        wait for CLK_PERIOD/2;
        clock_in <= '1';
        wait for CLK_PERIOD/2;
    end process;

    dut: uart_rx
        port map (
            clock_in        => clock_in,
            reset_in        => reset_in,
            uart_data_rx    => uart_data_rx,
            uart_rate_rx_sel=> uart_rate_rx_sel,
            data_p_out      => data_p_out,
            data_p_en_out   => data_p_en_out
        );

    stim_proc : process
        variable byte_to_send : std_logic_vector(7 downto 0) := x"A5";
    begin
        wait for 200 ns;
        reset_in <= '0';

        uart_data_rx <= '0';
        wait for BIT_TIME;

        for i in 0 to 7 loop
            uart_data_rx <= byte_to_send(i);
            wait for BIT_TIME;
        end loop;

        uart_data_rx <= '1';
        wait for BIT_TIME;

        wait for 5 * BIT_TIME;

        wait;
    end process;

end architecture sim;

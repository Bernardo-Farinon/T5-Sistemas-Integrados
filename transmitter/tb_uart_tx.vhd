library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_uart_tx is
end tb_uart_tx;

architecture sim of tb_uart_tx is

    component uart_tx is
        port (
            clock_in         : in  std_logic;
            reset_in         : in  std_logic;
            data_p_in        : in  std_logic_vector(7 downto 0);
            data_p_en_in     : in  std_logic;
            uart_rate_tx_sel : in  std_logic_vector(1 downto 0);
            uart_data_tx     : out std_logic
        );
    end component;

    signal clock_in         : std_logic := '0';
    signal reset_in         : std_logic := '1';
    signal data_p_in        : std_logic_vector(7 downto 0) := (others => '0');
    signal data_p_en_in     : std_logic := '0';
    signal uart_rate_tx_sel : std_logic_vector(1 downto 0) := "00";
    signal uart_data_tx     : std_logic;

    constant CLK_PERIOD : time := 10 ns;
    constant BAUD_DIV   : integer := 10416;
    constant BIT_TIME   : time := CLK_PERIOD * BAUD_DIV;

begin

    clock_process : process
    begin
        clock_in <= '0';
        wait for CLK_PERIOD/2;
        clock_in <= '1';
        wait for CLK_PERIOD/2;
    end process;

    dut: uart_tx
        port map (
            clock_in         => clock_in,
            reset_in         => reset_in,
            data_p_in        => data_p_in,
            data_p_en_in     => data_p_en_in,
            uart_rate_tx_sel => uart_rate_tx_sel,
            uart_data_tx     => uart_data_tx
        );

    stim_proc : process
    begin
        wait for 200 ns;
        reset_in <= '0';

        data_p_in    <= x"A5";
        data_p_en_in <= '1';
        wait for BIT_TIME; 
        data_p_en_in <= '0';

        wait for 10 * BIT_TIME;

        wait;
    end process;

end architecture sim;

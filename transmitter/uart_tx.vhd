library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_tx is
    port (
        clock_in         : in  std_logic;
        reset_in         : in  std_logic;
        data_p_in        : in  std_logic_vector(7 downto 0);
        data_p_en_in     : in  std_logic;
        uart_rate_tx_sel : in  std_logic_vector(1 downto 0);

        uart_data_tx     : out std_logic
    );
end entity uart_tx;

architecture rtl of uart_tx is

    -- baudrrate divisor clock_in = 100mhz
    signal baud_divisor : integer := 10416;
    signal baud_cnt     : integer := 0;
    signal baud_tick    : std_logic := '0';

    -- FSM
    type state_type is (IDLE, START, DATA, STOP);
    signal state : state_type := IDLE;

    -- bits
    signal bit_index : integer range 0 to 7 := 0;
    signal data_reg : std_logic_vector(7 downto 0) := (others => '0');

begin
    
    -- baudrate slect
    process(clock_in)
    begin
        if rising_edge(clock_in) then
            case uart_rate_tx_sel is
                when "00" => baud_divisor <= 10416; -- 9600
                when "01" => baud_divisor <= 5208;  -- 19200
                when "10" => baud_divisor <= 3472;  -- 28800
                when "11" => baud_divisor <= 1736;  -- 57600
                when others => baud_divisor <= 10416; -- default 9600
            end case;
        end if;
    end process;

        process(clock_in)
    begin
        if rising_edge(clock_in) then
            if baud_cnt = baud_divisor then
                baud_cnt  <= 0;
                baud_tick <= '1';
            else
                baud_cnt  <= baud_cnt + 1;
                baud_tick <= '0';
            end if;
        end if;
    end process;

        process(clock_in, reset_in)
    begin
        if reset_in = '1' then
            state         <= IDLE;
            bit_index     <= 0;
            data_reg      <= (others => '0');
            uart_data_tx  <= '1'; 

        elsif rising_edge(clock_in) then

            if baud_tick = '1' then

                case state is

                    when IDLE =>
                        uart_data_tx <= '1';
                        if data_p_en_in = '1' then
                            data_reg  <= data_p_in;
                            bit_index <= 0;
                            state     <= START;
                        end if;

                    when START =>
                        uart_data_tx <= '0';
                        state <= DATA;

                    when DATA =>
                        uart_data_tx <= data_reg(bit_index);
                        if bit_index = 7 then
                            state <= STOP;
                        else
                            bit_index <= bit_index + 1;
                        end if;

                    when STOP =>
                        uart_data_tx <= '1';
                        state <= IDLE;

                end case;

            end if;

        end if;
    end process;

end architecture rtl;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_rx is
    port (
        clock_in            : in std_logic;
        reset_in            : in std_logic;
        uart_data_rx        : in std_logic;
        uart_rate_rx_sel    : in std_logic_vector(1 downto 0);
        
        data_p_out          : out std_logic_vector(7 downto 0);
        data_p_en_out       : out std_logic
    );
end entity uart_rx;

architecture rtl of uart_rx is

    -- baudrrate divisor clock_in = 100mhz
    signal baud_divisor     : integer := 10416; -- 9600
    signal baud_div_cnt     : integer := 0;
    signal baud_tick        : std_logic := '0';

    -- FMS idle start data stop
    type state_type is (IDLE, START, DATA, STOP);
    signal state            : state_type := IDLE;

    -- bits
    signal bit_index        : integer range 0 to 7 := 0;
    signal shift_reg        : std_logic_vector(7 downto 0) := (others => '0');

begin

    -- baudrate slect
    process(clock_in)
    begin
        if rising_edge(clock_in) then
            case uart_rate_rx_sel is
                when "00" => baud_divisor <= 10416; -- 9600
                when "01" => baud_divisor <= 5208;  -- 19200
                when "10" => baud_divisor <= 3472;  -- 38400
                when "11" => baud_divisor <= 1736;  -- 57600
                when others => baud_divisor <= 10416; -- default 9600
            end case;
        end if;
    end process;

    -- baudtick generator
    process(clock_in)
    begin
        if rising_edge(clock_in) then
            if baud_div_cnt = baud_divisor then
                baud_div_cnt <= 0;
                baud_tick <= '1';
            else
                baud_div_cnt <= baud_div_cnt + 1;
                baud_tick <= '0';
            end if;
        end if;
    end process;

    -- fsm
    process(clock_in, reset_in)
    begin
        if reset_in = '1' then
            state         <= IDLE;
            bit_index     <= 0;
            shift_reg     <= (others => '0');
            data_p_out    <= (others => '0');
            data_p_en_out <= '0';

        elsif rising_edge(clock_in) then
                        data_p_en_out <= '0';

            if baud_tick = '1' then

                case state is
                    when IDLE =>
                        if uart_data_rx = '0' then  -- detectou borda de início
                            state <= START;
                        end if;

                    when START =>
                        if uart_data_rx = '0' then
                            bit_index <= 0;
                            state     <= DATA;
                        else
                            state <= IDLE; 
                        end if;

                    when DATA =>
                        shift_reg(bit_index) <= uart_data_rx;

                        if bit_index = 7 then
                            state <= STOP;
                        else
                            bit_index <= bit_index + 1;
                        end if;

                    when STOP =>
                        if uart_data_rx = '1' then
                            data_p_out    <= shift_reg;
                            data_p_en_out <= '1';   -- pulso de dado valido
                        end if;

                        state <= IDLE;

                end case;

            end if;  -- baud_tick

        end if; -- rising_edge
    end process;
end architecture rtl;

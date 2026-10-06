library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mcp3208_spi is
    port (
        clk       : in  std_logic;
        reset     : in  std_logic;
        start     : in  std_logic;

        channel   : in  std_logic_vector(2 downto 0);
        adc_miso  : in  std_logic;

        adc_cs    : out std_logic;
        adc_sclk  : out std_logic;
        adc_mosi  : out std_logic;

        adc_data  : out std_logic_vector(11 downto 0);
        adc_done  : out std_logic
    );
end entity mcp3208_spi;


architecture rtl of mcp3208_spi is

    ----------------------------------------------------------------
    -- SPI clock divider
    --
    -- FPGA clock = 27 MHz
    -- SPI clock ≈ 27 MHz / 28
    --             ≈ 964 kHz
    ----------------------------------------------------------------
    constant SPI_DIVIDER : integer := 14;

    signal spi_counter : integer range 0 to SPI_DIVIDER - 1 := 0;

    signal spi_clk : std_logic := '0';

    ----------------------------------------------------------------
    -- SPI transaction
    ----------------------------------------------------------------
    signal busy : std_logic := '0';

    signal bit_count : integer range 0 to 17 := 0;

    signal tx_data : std_logic_vector(4 downto 0)
        := (others => '0');

    signal rx_data : std_logic_vector(11 downto 0)
        := (others => '0');

begin

    ----------------------------------------------------------------
    -- Outputs
    ----------------------------------------------------------------

    adc_cs   <= not busy;
    adc_sclk <= spi_clk when busy = '1' else '0';


    ----------------------------------------------------------------
    -- SPI MOSI command
    --
    -- MCP3208 single-ended command:
    --
    -- Start bit = 1
    -- SGL/DIFF  = 1
    -- D2 D1 D0  = channel
    ----------------------------------------------------------------
    adc_mosi <= tx_data(4)
                when busy = '1'
                else '0';


    ----------------------------------------------------------------
    -- SPI controller
    ----------------------------------------------------------------
    SPI_PROCESS : process(clk)

        variable next_bit : std_logic;

    begin

        if rising_edge(clk) then

            if reset = '1' then

                spi_counter <= 0;
                spi_clk     <= '0';
                busy        <= '0';

                bit_count   <= 0;

                tx_data     <= (others => '0');
                rx_data     <= (others => '0');

                adc_data    <= (others => '0');
                adc_done    <= '0';

            else

                adc_done <= '0';


                ----------------------------------------------------
                -- Start a new ADC transaction
                ----------------------------------------------------
                if start = '1' and busy = '0' then

                    busy <= '1';

                    spi_counter <= 0;
                    spi_clk     <= '0';

                    bit_count <= 0;

                    rx_data <= (others => '0');


                    ------------------------------------------------
                    -- Start + single-ended + channel
                    ------------------------------------------------
                    tx_data <=
                        "11" & channel;

                end if;


                ----------------------------------------------------
                -- SPI clock generation
                ----------------------------------------------------
                if busy = '1' then

                    if spi_counter = SPI_DIVIDER - 1 then

                        spi_counter <= 0;

                        ------------------------------------------------
                        -- Rising edge
                        ------------------------------------------------
                        if spi_clk = '0' then

                            spi_clk <= '1';

                            ------------------------------------------------
                            -- MCP3208 data capture
                            --
                            -- The first response bit is a null bit.
                            -- Following bits contain D11 ... D0.
                            ------------------------------------------------
                            if bit_count >= 6 and
                               bit_count <= 17 then

                                next_bit := adc_miso;

                                rx_data <=
                                    rx_data(10 downto 0) &
                                    next_bit;

                            end if;


                        ------------------------------------------------
                        -- Falling edge
                        ------------------------------------------------
                        else

                            spi_clk <= '0';


                            ------------------------------------------------
                            -- Shift command toward the next bit
                            ------------------------------------------------
                            if bit_count < 4 then

                                tx_data <=
                                    tx_data(3 downto 0) & '0';

                            end if;


                            ------------------------------------------------
                            -- Count SPI clocks
                            ------------------------------------------------
                            if bit_count = 17 then

                                busy <= '0';

                                adc_data <= rx_data;

                                adc_done <= '1';

                                bit_count <= 0;

                            else

                                bit_count <=
                                    bit_count + 1;

                            end if;

                        end if;

                    else

                        spi_counter <=
                            spi_counter + 1;

                    end if;

                end if;

            end if;

        end if;

    end process SPI_PROCESS;

end architecture rtl;

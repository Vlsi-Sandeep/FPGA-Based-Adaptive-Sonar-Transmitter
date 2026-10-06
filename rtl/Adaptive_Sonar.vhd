library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Adaptive_Sonar is
    port (
        clk       : in  std_logic;
        reset     : in  std_logic;

        -- MCP3208 SPI interface
        adc_miso  : in  std_logic;
        adc_cs    : out std_logic;
        adc_mosi  : out std_logic;
        adc_sclk  : out std_logic;

        -- 8-bit DAC output
        dac_data  : out std_logic_vector(7 downto 0)
    );
end entity Adaptive_Sonar;


architecture rtl of Adaptive_Sonar is

    ----------------------------------------------------------------
    -- MCP3208 interface
    ----------------------------------------------------------------
    component mcp3208_spi
        port (
            clk           : in  std_logic;
            reset         : in  std_logic;
            start         : in  std_logic;
            channel       : in  std_logic_vector(2 downto 0);
            adc_miso      : in  std_logic;

            adc_cs        : out std_logic;
            adc_sclk      : out std_logic;
            adc_mosi      : out std_logic;

            adc_data      : out std_logic_vector(11 downto 0);
            adc_done      : out std_logic
        );
    end component;


    ----------------------------------------------------------------
    -- ADC signals
    ----------------------------------------------------------------
    signal adc_start     : std_logic := '0';
    signal adc_done      : std_logic := '0';
    signal adc_channel   : std_logic_vector(2 downto 0) := "000";
    signal adc_value     : std_logic_vector(11 downto 0) := (others => '0');

    signal temperature   : unsigned(11 downto 0) := (others => '0');
    signal turbidity     : unsigned(11 downto 0) := (others => '0');
    signal salinity      : unsigned(11 downto 0) := (others => '0');

    signal temp_filtered : unsigned(11 downto 0) := (others => '0');
    signal turb_filtered : unsigned(11 downto 0) := (others => '0');
    signal salt_filtered : unsigned(11 downto 0) := (others => '0');

    signal environment   : unsigned(11 downto 0) := (others => '0');


    ----------------------------------------------------------------
    -- ADC sampling timer
    -- 27 MHz clock
    -- 270000 cycles = 10 ms
    ----------------------------------------------------------------
    signal adc_timer : integer range 0 to 269999 := 0;


    ----------------------------------------------------------------
    -- DDS / NCO
    ----------------------------------------------------------------
    signal phase_accumulator : unsigned(31 downto 0) := (others => '0');

    signal start_fcw : unsigned(31 downto 0) := to_unsigned(47721859, 32);
    signal stop_fcw  : unsigned(31 downto 0) := to_unsigned(63629145, 32);

    signal current_fcw : unsigned(31 downto 0) := to_unsigned(47721859, 32);
    signal chirp_step  : unsigned(31 downto 0) := (others => '0');


    ----------------------------------------------------------------
    -- Pulse timing
    ----------------------------------------------------------------
    signal pulse_counter : integer range 0 to 53999 := 0;

    constant ACTIVE_CYCLES : integer := 27000;
    constant TOTAL_CYCLES  : integer := 54000;


    ----------------------------------------------------------------
    -- Amplitude control
    ----------------------------------------------------------------
    signal amplitude : unsigned(7 downto 0) := to_unsigned(100, 8);


    ----------------------------------------------------------------
    -- Sine lookup table
    ----------------------------------------------------------------
    type sine_table_type is array (0 to 63)
        of unsigned(7 downto 0);

    constant SINE_TABLE : sine_table_type := (

        128, 140, 153, 165,
        177, 188, 198, 208,
        218, 226, 234, 241,
        246, 251, 254, 255,

        255, 255, 254, 251,
        246, 241, 234, 226,
        218, 208, 198, 188,
        177, 165, 153, 140,

        128, 115, 102, 90,
        78, 67, 57, 47,
        37, 29, 21, 14,
        9, 4, 1, 0,

        0, 0, 1, 4,
        9, 14, 21, 29,
        37, 47, 57, 67,
        78, 90, 102, 115
    );


    ----------------------------------------------------------------
    -- Window table
    -- Approximate Hann window values scaled to 0-255
    ----------------------------------------------------------------
    type window_type is array (0 to 63)
        of unsigned(7 downto 0);

    constant HANN_WINDOW : window_type := (

        0, 1, 2, 4,
        8, 12, 17, 23,
        30, 38, 46, 55,
        65, 75, 86, 97,

        108, 120, 131, 142,
        153, 164, 175, 185,
        195, 205, 214, 222,
        230, 237, 243, 248,

        252, 254, 255, 255,
        254, 252, 248, 243,
        237, 230, 222, 214,
        205, 195, 185, 175,

        164, 153, 142, 131,
        120, 108, 97, 86,
        75, 65, 55, 46,
        38, 30, 23, 17,

        12, 8, 4, 2,
        1, 0, 0, 0
    );


    signal lut_index : integer range 0 to 63 := 0;

    signal sine_value   : unsigned(7 downto 0);
    signal window_value : unsigned(7 downto 0);

    signal waveform_value : unsigned(15 downto 0);


begin

    ----------------------------------------------------------------
    -- MCP3208
    ----------------------------------------------------------------
    ADC_INTERFACE : mcp3208_spi
        port map (
            clk       => clk,
            reset     => reset,
            start     => adc_start,
            channel   => adc_channel,
            adc_miso  => adc_miso,

            adc_cs    => adc_cs,
            adc_sclk  => adc_sclk,
            adc_mosi  => adc_mosi,

            adc_data  => adc_value,
            adc_done  => adc_done
        );


    ----------------------------------------------------------------
    -- ADC sampling and environmental adaptation
    ----------------------------------------------------------------
    ADC_CONTROL : process(clk)
        variable env_value  : integer;
        variable start_int  : integer;
        variable stop_int   : integer;
        variable amp_int    : integer;
    begin

        if rising_edge(clk) then

            if reset = '1' then

                adc_timer   <= 0;
                adc_start   <= '0';
                adc_channel <= "000";

                temperature <= (others => '0');
                turbidity   <= (others => '0');
                salinity    <= (others => '0');

                temp_filtered <= (others => '0');
                turb_filtered <= (others => '0');
                salt_filtered <= (others => '0');

                environment <= (others => '0');

                start_fcw <= to_unsigned(47721859, 32);
                stop_fcw  <= to_unsigned(63629145, 32);

                amplitude <= to_unsigned(100, 8);

            else

                adc_start <= '0';


                ----------------------------------------------------
                -- Start ADC conversion every 10 ms
                ----------------------------------------------------
                if adc_timer = 269999 then

                    adc_timer <= 0;
                    adc_start <= '1';

                else

                    adc_timer <= adc_timer + 1;

                end if;


                ----------------------------------------------------
                -- When ADC conversion completes
                ----------------------------------------------------
                if adc_done = '1' then

                    ------------------------------------------------
                    -- Store channel data
                    ------------------------------------------------
                    case adc_channel is

                        when "000" =>
                            temperature <= unsigned(adc_value);

                        when "001" =>
                            turbidity <= unsigned(adc_value);

                        when "010" =>
                            salinity <= unsigned(adc_value);

                        when others =>
                            null;

                    end case;


                    ------------------------------------------------
                    -- Move to next channel
                    ------------------------------------------------
                    if adc_channel = "010" then
                        adc_channel <= "000";
                    else
                        adc_channel <= std_logic_vector(
                            unsigned(adc_channel) + 1
                        );
                    end if;

                end if;


                ----------------------------------------------------
                -- Simple digital averaging
                --
                -- filtered = 7/8 old + 1/8 new
                ----------------------------------------------------
                temp_filtered <=
                    (temp_filtered * 7 + temperature) / 8;

                turb_filtered <=
                    (turb_filtered * 7 + turbidity) / 8;

                salt_filtered <=
                    (salt_filtered * 7 + salinity) / 8;


                ----------------------------------------------------
                -- Environmental index
                --
                -- E = (Temperature +
                --      2*Turbidity +
                --      Salinity) / 4
                ----------------------------------------------------
                env_value :=
                    (to_integer(temp_filtered) +
                     (2 * to_integer(turb_filtered)) +
                     to_integer(salt_filtered)) / 4;


                if env_value > 4095 then
                    env_value := 4095;
                end if;

                environment <=
                    to_unsigned(env_value, 12);


                ----------------------------------------------------
                -- Adaptive START frequency
                --
                -- Low environment:
                --     300 kHz
                --
                -- High environment:
                --      60 kHz
                --
                -- 27 MHz FPGA clock
                --
                -- FCW = Fout * 2^32 / 27 MHz
                ----------------------------------------------------
                start_int :=
                    47721859 -
                    ((env_value * 38177487) / 4095);


                ----------------------------------------------------
                -- Adaptive STOP frequency
                --
                -- Low environment:
                --     400 kHz
                --
                -- High environment:
                --     100 kHz
                ----------------------------------------------------
                stop_int :=
                    63629145 -
                    ((env_value * 47721859) / 4095);


                ----------------------------------------------------
                -- Ensure valid chirp range
                ----------------------------------------------------
                if stop_int <= start_int then
                    stop_int := start_int + 1000000;
                end if;


                start_fcw <=
                    to_unsigned(start_int, 32);

                stop_fcw <=
                    to_unsigned(stop_int, 32);


                ----------------------------------------------------
                -- Adaptive amplitude
                --
                -- Environment low  -> 100
                -- Environment high -> 55
                ----------------------------------------------------
                amp_int :=
                    100 -
                    ((env_value * 45) / 4095);

                if amp_int < 55 then
                    amp_int := 55;
                end if;

                if amp_int > 100 then
                    amp_int := 100;
                end if;

                amplitude <=
                    to_unsigned(amp_int, 8);

            end if;

        end if;

    end process ADC_CONTROL;


    ----------------------------------------------------------------
    -- DDS + LFM waveform generator
    ----------------------------------------------------------------
    DDS_PROCESS : process(clk)

        variable scaled_sine   : integer;
        variable scaled_window : integer;
        variable final_value   : integer;

    begin

        if rising_edge(clk) then

            if reset = '1' then

                phase_accumulator <= (others => '0');

                current_fcw <=
                    to_unsigned(47721859, 32);

                pulse_counter <= 0;

            else

                ----------------------------------------------------
                -- Pulse timing
                ----------------------------------------------------
                if pulse_counter = TOTAL_CYCLES - 1 then

                    pulse_counter <= 0;

                    current_fcw <= start_fcw;

                else

                    pulse_counter <= pulse_counter + 1;


                    ------------------------------------------------
                    -- LFM chirp
                    ------------------------------------------------
                    if pulse_counter < ACTIVE_CYCLES then

                        if current_fcw < stop_fcw then

                            current_fcw <=
                                current_fcw + chirp_step;

                        end if;

                    end if;

                end if;


                ----------------------------------------------------
                -- Calculate chirp step
                --
                -- Approximately 27,000 FPGA clock cycles
                -- for the active 1 ms chirp.
                ----------------------------------------------------
                if stop_fcw > start_fcw then

                    chirp_step <=
                        (stop_fcw - start_fcw) / ACTIVE_CYCLES;

                else

                    chirp_step <=
                        to_unsigned(0, 32);

                end if;


                ----------------------------------------------------
                -- DDS phase accumulator
                ----------------------------------------------------
                phase_accumulator <=
                    phase_accumulator + current_fcw;


                ----------------------------------------------------
                -- Use upper 6 bits for 64-entry LUT
                ----------------------------------------------------
                lut_index <=
                    to_integer(
                        phase_accumulator(31 downto 26)
                    );


                ----------------------------------------------------
                -- Generate waveform only during active pulse
                ----------------------------------------------------
                if pulse_counter < ACTIVE_CYCLES then

                    sine_value <=
                        SINE_TABLE(lut_index);

                    window_value <=
                        HANN_WINDOW(lut_index);


                    ------------------------------------------------
                    -- Center sine around zero:
                    --
                    -- sine_value - 128
                    ------------------------------------------------
                    scaled_sine :=
                        to_integer(sine_value) - 128;


                    ------------------------------------------------
                    -- Apply Hann window
                    ------------------------------------------------
                    scaled_window :=
                        (scaled_sine *
                         to_integer(window_value)) / 255;


                    ------------------------------------------------
                    -- Apply adaptive amplitude
                    ------------------------------------------------
                    final_value :=
                        128 +
                        ((scaled_window *
                          to_integer(amplitude)) / 100);


                    ------------------------------------------------
                    -- Limit DAC output
                    ------------------------------------------------
                    if final_value < 0 then

                        final_value := 0;

                    elsif final_value > 255 then

                        final_value := 255;

                    end if;


                    waveform_value <=
                        to_unsigned(final_value, 16);

                    dac_data <=
                        std_logic_vector(
                            to_unsigned(final_value, 8)
                        );

                else

                    ------------------------------------------------
                    -- Silence / midpoint
                    ------------------------------------------------
                    dac_data <= "10000000";

                end if;

            end if;

        end if;

    end process DDS_PROCESS;

end architecture rtl;

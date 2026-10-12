# Circuit Connections — Adaptive Software-Defined Sonar

This document describes the hardware interfaces used in the FPGA-based adaptive sonar transmitter prototype developed for Smart India Hackathon 2026, Problem Statement **SIH26058**.

## 1. System Block Diagram

```text
 Potentiometer 1 ──┐
 Potentiometer 2 ──┼──> MCP3208 ADC
 Potentiometer 3 ──┘      12-bit SPI
                              │
                    MISO / MOSI / SCLK / CS
                              │
                              ▼
                     Tang Nano 4K FPGA
                     ┌────────────────┐
                     │ Adaptive logic │
                     │ DDS / NCO      │
                     │ LFM generation │
                     │ Amplitude ctrl │
                     └────────────────┘
                              │
                         8-bit data
                              │
                              ▼
                          DAC0800
                       Current output
                              │
                              ▼
                          MC33078
                     I/V conversion and
                    analog conditioning
                              │
                              ▼
                             DSO
```

## 2. Potentiometers to MCP3208

Three potentiometers act as adjustable environmental input proxies.

| Potentiometer | MCP3208 channel | Simulated input |
|---|---|---|
| POT1 | CH0 | Temperature |
| POT2 | CH1 | Turbidity |
| POT3 | CH2 | Salinity |

### Connections

For each potentiometer:

| Potentiometer terminal | Connect to |
|---|---|
| Outer terminal 1 | +3.3 V |
| Outer terminal 2 | GND |
| Middle terminal (wiper) | Corresponding MCP3208 analog input |

Use the following analog input connections:

- POT1 wiper → MCP3208 pin 1 (CH0)
- POT2 wiper → MCP3208 pin 2 (CH1)
- POT3 wiper → MCP3208 pin 3 (CH2)

The ADC input voltage must remain within the configured ADC reference range.

## 3. MCP3208 to Tang Nano 4K

The MCP3208 communicates with the FPGA through SPI.

| MCP3208 pin | Signal | FPGA top-level signal |
|---|---|---|
| Pin 10 | CS/SHDN | `adc_cs` |
| Pin 11 | DIN | `adc_mosi` |
| Pin 12 | DOUT | `adc_miso` |
| Pin 13 | CLK | `adc_sclk` |
| Pin 9 | DGND | Common GND |
| Pin 14 | AGND | Analog GND |
| Pin 15 | VREF | +3.3 V reference |
| Pin 16 | VDD | +3.3 V supply |

**Important:** The MCP3208 chip-select signal is active-low. Its digital and analog grounds must be connected to the appropriate common ground arrangement.

Place a 100 nF bypass capacitor close to the ADC supply pins. Additional local bulk decoupling may be used.

## 4. Tang Nano 4K to DAC0800

The FPGA generates an 8-bit digital waveform that feeds the DAC0800.

| FPGA signal | DAC0800 pin | Function |
|---|---|---|
| `dac_data[7]` | Pin 5 (B1) | Most significant bit |
| `dac_data[6]` | Pin 6 (B2) | Data bit 6 |
| `dac_data[5]` | Pin 7 (B3) | Data bit 5 |
| `dac_data[4]` | Pin 8 (B4) | Data bit 4 |
| `dac_data[3]` | Pin 9 (B5) | Data bit 3 |
| `dac_data[2]` | Pin 10 (B6) | Data bit 2 |
| `dac_data[1]` | Pin 11 (B7) | Data bit 1 |
| `dac_data[0]` | Pin 12 (B8) | Least significant bit |

The data bus must preserve the correct MSB-to-LSB ordering.

### DAC0800 power and analog connections

| DAC0800 pin | Function | Connection |
|---|---|---|
| Pin 1 | Logic reference (VLC) | Configure as required for the logic interface |
| Pin 2 | Complementary current output | Leave unused if following the single-output prototype arrangement |
| Pin 3 | Negative supply (V−) | Regulated negative rail |
| Pin 4 | Current output (IOUT) | MC33078 current-to-voltage stage |
| Pin 13 | Positive supply (V+) | Regulated positive rail |
| Pin 14 | Positive reference input | Reference network |
| Pin 15 | Negative reference input | Reference network |
| Pin 16 | Compensation | Compensation network per the selected DAC0800 circuit |

The reference network and compensation capacitor must follow the selected DAC0800 application circuit. Consult the [official DAC0800 datasheet](https://www.ti.com/lit/ds/symlink/dac0800.pdf) before applying power.

## 5. DAC0800 to MC33078

The DAC0800 produces a current output. The MC33078 stage converts this current into a measurable voltage.

### First op-amp connections

| MC33078 pin | Function | Connection |
|---|---|---|
| Pin 1 | Output 1 | Analog output |
| Pin 2 | Inverting input 1 | DAC current output and feedback network |
| Pin 3 | Non-inverting input 1 | Analog ground reference |
| Pin 4 | Negative supply | Regulated negative rail |
| Pin 8 | Positive supply | Regulated positive rail |

A transimpedance configuration uses a feedback resistor between pin 1 and pin 2. The output voltage depends on the DAC output current, feedback resistance, and current direction.

The resistor value and compensation should be selected for the intended waveform amplitude and frequency range.

Consult the [MC33078 documentation](https://www.ti.com/product/MC33078) for operating limits and circuit details.

## 6. Analog Output to the Oscilloscope

Connect the conditioned analog output to the DSO input.

- MC33078 conditioned output → DSO channel input
- DSO ground reference → circuit common GND
- Use an appropriate probe and oscilloscope input setting.
- Never attach the oscilloscope ground clip to the negative supply rail.

Observe the waveform, frequency, amplitude, and noise. The prototype produced an observable output during the project demonstration, although frequency fluctuations and noise were present.

## 7. Power and Ground

The ADC, FPGA, DAC, and op-amp have different supply requirements.

- MCP3208: supply and reference appropriate to its configured input range.
- Tang Nano 4K: powered according to the board's specifications.
- DAC0800: use suitable regulated supplies and reference circuitry.
- MC33078: use supplies within its specified operating range.
- Connect signal grounds to a suitable common reference.
- Verify supply polarity and voltage before connecting the ICs.

Do not assume that a single +5 V supply is sufficient for the complete analog stage.

## 8. FPGA Constraints

The FPGA design uses the following top-level signals:

```text
clk
reset
adc_miso
adc_cs
adc_mosi
adc_sclk
dac_data[7:0]
```

The clock constraint is maintained in `constraints/clk.sdc`. Physical pin assignments belong in `constraints/tang_nano_4k.cst` and must match the verified board pinout and actual wiring.

## 9. References

- [Sipeed Tang Nano 4K documentation](https://wiki.sipeed.com/hardware/en/tang/Tang-Nano-4K/Nano-4K.html)
- [MCP3208 datasheet](https://ww1.microchip.com/downloads/en/DeviceDoc/21298E.pdf)
- [DAC0800 datasheet](https://www.ti.com/lit/ds/symlink/dac0800.pdf)
- [MC33078 product documentation](https://www.ti.com/product/MC33078)

---

**Project:** FPGA-Based Adaptive Software-Defined Sonar Transmitter  
**Problem Statement:** SIH26058  
**Platform:** Sipeed Tang Nano 4K FPGA

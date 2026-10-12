# 🌊 FPGA-Based Adaptive Sonar Transmitter

An FPGA-based adaptive sonar transmitter prototype designed for **Autonomous Underwater Vehicles (AUVs)**. The system explores adaptive signal generation by processing simulated environmental inputs and generating a corresponding output waveform for observation using an oscilloscope.

![Oscilloscope Output of the Adaptive Sonar Transmitter](https://raw.githubusercontent.com/Vlsi-Sandeep/FPGA-Based-Adaptive-Sonar-Transmitter/7168460cc118fe8f487f2d38de99812592474837/hardware/oscilloscope-output.jpeg)

---

## 🚀 Project Overview

Underwater environments can vary in turbidity, temperature, and salinity, potentially affecting sonar signal performance. An adaptive sonar transmitter aims to adjust its transmission parameters according to environmental conditions.

This project demonstrates a **hardware prototype of an FPGA-based adaptive sonar transmitter** using a Sipeed Tang Nano 4K FPGA, MCP3208 ADC, DAC0800, and an MC33078 analog stage.

Three potentiometers simulate environmental sensor inputs. The FPGA processes the digitized values and generates waveform data for analog output and oscilloscope observation.

## 🎯 Problem Statement

Conventional sonar transmitters may operate with fixed signal parameters, limiting their flexibility when underwater conditions change.

The objective of this project is to explore a low-power, real-time adaptive transmitter architecture that can modify signal parameters based on environmental input values.

## 💡 Proposed Solution

The prototype combines digital processing and analog circuitry to demonstrate adaptive waveform generation.

- 🌡️ **Simulated environmental sensing:** Three potentiometers provide adjustable analog inputs.
- 🔄 **Analog-to-digital conversion:** The MCP3208 converts analog inputs into digital values.
- 🧠 **FPGA processing:** The Tang Nano 4K processes the input values and selects waveform parameters.
- 📈 **Waveform generation:** VHDL logic generates digital waveform samples.
- ⚡ **Digital-to-analog conversion:** The DAC0800 converts digital data into an analog current output.
- 📊 **Output observation:** An oscilloscope is used to observe the generated waveform.

## 🏗️ System Architecture

```mermaid
flowchart LR
    A["🎛️ Potentiometer Inputs"] --> B["🔄 MCP3208 ADC"]
    B --> C["🧠 Tang Nano 4K FPGA"]
    C --> D["📶 DAC0800"]
    D --> E["⚡ MC33078 Analog Stage"]
    E --> F["📊 Oscilloscope"]

    style A fill:#e0f2fe,stroke:#0284c7,color:#0f172a
    style B fill:#ede9fe,stroke:#7c3aed,color:#0f172a
    style C fill:#dcfce7,stroke:#16a34a,color:#0f172a
    style D fill:#fef3c7,stroke:#d97706,color:#0f172a
    style E fill:#fce7f3,stroke:#db2777,color:#0f172a
    style F fill:#e5e7eb,stroke:#4b5563,color:#0f172a
```

## 🔧 Hardware Components

| Component | Purpose |
|---|---|
| 🧠 Sipeed Tang Nano 4K | FPGA-based digital processing and waveform generation |
| 🔄 MCP3208 | 12-bit, 8-channel SPI analog-to-digital converter |
| 📶 DAC0800LCN | Digital-to-analog conversion |
| ⚡ MC33078 | Analog signal-conditioning stage |
| 🎛️ Three potentiometers | Simulated environmental sensor inputs |
| 📊 Oscilloscope | Waveform observation during testing |
| 🔌 Regulated power supplies | Provide the required circuit supply rails |

## ⚙️ Working Principle

### 1. Environmental Input Simulation
Three potentiometers provide adjustable analog voltages representing environmental parameters.

### 2. Analog-to-Digital Conversion
The MCP3208 samples the analog inputs and supplies digital values to the FPGA through an SPI interface.

### 3. Adaptive Digital Processing
The FPGA processes the sampled values using VHDL logic to determine waveform-generation parameters.

### 4. Waveform Generation
The FPGA generates digital waveform samples according to the implemented control logic.

### 5. Analog Output
The DAC0800 converts the digital samples into an analog current. The MC33078-based analog stage provides the output-conditioning interface.

### 6. Experimental Observation
The output waveform is observed using an oscilloscope to evaluate the prototype's bench-level behavior.

## ✨ Key Features

- 🧠 FPGA-based adaptive control logic.
- 🔄 SPI communication with an external ADC.
- 🎛️ Multiple analog input channels.
- 📈 Digital waveform generation using VHDL.
- ⚡ DAC-based analog output generation.
- 🔬 Hardware prototyping and oscilloscope-based observation.
- 🛠️ Modular architecture for future improvements.

## 🧪 Hardware Prototype

The circuit was assembled on a breadboard using the FPGA board, potentiometers, and associated wiring to demonstrate the prototype's operation.

![Breadboard Hardware Prototype](https://raw.githubusercontent.com/Vlsi-Sandeep/FPGA-Based-Adaptive-Sonar-Transmitter/7168460cc118fe8f487f2d38de99812592474837/hardware/prototype-breadboard.jpeg)

*Figure: Breadboard implementation of the FPGA-based adaptive sonar transmitter prototype.*

## 📊 Experimental Results

The prototype was assembled and tested on hardware, and an output waveform was observed using an oscilloscope.

### Observations

- ✅ The hardware setup generated an observable output waveform.
- 📈 Waveform behavior was examined using an oscilloscope.
- ⚠️ Frequency fluctuations and visible noise were observed during testing.
- 🔍 Further signal conditioning, timing verification, and measurement are needed to improve waveform stability.

These observations represent preliminary bench-level results. They do not establish validated underwater transmission performance.

## 📁 Repository Structure

```text
FPGA-Based-Adaptive-Sonar-Transmitter/
│
├── README.md
│
├── rtl/
│   ├── Adaptive_Sonar.vhd
│   └── mcp3208_spi.vhd
│
├── constraints/
│   └── clk.sdc
│
├── hardware/
│   ├── CIRCUIT_CONNECTIONS.md
│   ├── prototype-breadboard.jpeg
│   └── oscilloscope-output.jpeg
│
├── simulation/
├── documentation/
└── results/
```

*Note: Empty directories will appear in GitHub only after at least one file is added to each directory.*

## 💻 Tools and Technologies

| Technology | Application |
|---|---|
| VHDL | Digital design and FPGA logic |
| Gowin FPGA tools | FPGA development and implementation |
| Sipeed Tang Nano 4K | FPGA hardware platform |
| MCP3208 SPI ADC | Analog input digitization |
| DAC0800 | Analog output conversion |
| MC33078 | Analog signal conditioning |
| Oscilloscope | Hardware waveform observation |

## 🔮 Future Improvements

- 🧹 Reduce output noise and waveform fluctuations.
- ⏱️ Verify clock timing and waveform frequency accuracy.
- 🔄 Validate SPI communication and ADC sampling alignment.
- 📉 Improve analog output filtering and signal conditioning.
- 📏 Measure frequency and amplitude across all operating modes.
- 🌊 Investigate transmission using a suitable underwater transducer.
- 🤖 Explore integration with an AUV platform.
- 🧪 Perform controlled underwater testing and characterize the resulting performance.

## ⚠️ Project Scope and Limitations

This repository documents a **hardware prototype for exploring adaptive sonar transmitter concepts**.

- Potentiometers are used to simulate environmental sensor inputs.
- The output waveform was observed during bench testing.
- Frequency fluctuations and noise were present in the observed output.
- Underwater propagation, echo reception, sonar imaging, and AUV integration have not been validated by this prototype.
- The prototype should not be interpreted as a complete underwater sonar system.

## 📚 References

1. [Sipeed Tang Nano 4K Documentation](https://wiki.sipeed.com/hardware/en/tang/Tang-Nano-4K/Nano-4K.html)
2. [Microchip MCP3208 Datasheet](https://ww1.microchip.com/downloads/en/DeviceDoc/21298E.pdf)
3. [Texas Instruments DAC0800 Datasheet](https://www.ti.com/lit/ds/symlink/dac0800.pdf)
4. [Texas Instruments MC33078 Product Page](https://www.ti.com/product/MC33078)

---

## 👨‍💻 Author

**Sandeep C.**

🎓 Electronics and Communication Engineering  
🔬 Interests: FPGA Design • Digital Systems • VHDL • Embedded Hardware

---

⭐ *Exploring adaptive signal generation through FPGA-based hardware design.*

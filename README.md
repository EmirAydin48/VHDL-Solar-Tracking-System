Available Languages: [English](README.md) | [Türkçe](README_TR.md)

# 🌻 SunflowerBot: FPGA-Based Autonomous Solar Tracking System

![demo](https://github.com/user-attachments/assets/1536b20f-7956-42f9-8431-87e7970cd9c4)

*Figure 1. The Demonstration of The Project Working*

![Status](https://img.shields.io/badge/Status-Completed-success)
![Tech](https://img.shields.io/badge/Language-VHDL-blue) 
![Board](https://img.shields.io/badge/Hardware-Basys3-orange) 

---

## 📌 Overview

SunflowerBot is an autonomous, heliotropic tracking system designed on the Artix-7 FPGA (Basys 3). It mimics nature by using a pair of Light Dependent Resistors (LDRs) to actively orient a servo motor toward the brightest light source in real-time.

Unlike microcontroller-based solutions that rely on sequential software execution, this project leverages FPGA parallelism to handle sensor acquisition, signal processing, and motor control simultaneously in hardware. The system features a custom RTL design that eliminates the need for a soft-core processor, ensuring microsecond-level response times.

---

## 🛠️ Key Design Features

* **⚡ Hardware-Accelerated Control Loop** 
    * Implements a Hysteresis Comparator with a 300-unit deadband to eliminate sensor noise and prevent servo "chattering" (rapid oscillation).
* **📈 Signal Processing Pipeline**
    * Features a custom Infinite Impulse Response Low-Pass Filter to smooth raw 12-bit sensor data before actuation.
* **🖥️ Bare-Metal LCD Driver** 
    * A manual Finite State Machine implementation of the HD44780 protocol, managing microsecond-level timing constraints without external IP cores.
* **🧈 Smooth Motion**
    * 50Hz PWM Generator with Slew-Rate Limiting to ensure smooth motion between two points by gradually accelerating the servo.
* **🔌 XADC Interface**
    * Direct control of the Artix-7 Dynamic Reconfiguration Port to sequence the internal 12-bit Analog-to-Digital Converter.

---

## ⚙️ System Architecture

![System_Block_Diagram](https://github.com/user-attachments/assets/2a5c269f-cfff-4a3c-bdd9-182989aae2f3)
*Figure 2. The Block Diagram Of the System*

The architecture is a fully parallelized "Sense-Think-Act" pipeline:

### 1. Sensing (`xadc_interface.vhd`)
* **Input:** 2x Light Dependent Resistors forming voltage dividers.
* **Mechanism:** Interfaces with the XADC primitive to sample analog voltages at 12-bit resolution.
* **Logic:** Uses a 4-state sequencer to multiplex the single ADC core between two analog channels (VAUX6 & VAUX14).

### 2. Processing (`sensor_compare.vhd` & `pwm_gen.vhd`)
* **Comparison:** Calculates the differential ($\Delta$) between Left and Right sensors.
* **Filtering:** Applies an IIR filter: $y[n] = 0.97 \cdot y[n-1] + 0.03 \cdot x[n]$. This dampens high-frequency noise.
* **Decision:** Moves the servo only if $|\Delta| > \text{Threshold}$.

### 3. Actuation (`pwm_gen.vhd`)
* **Output:** 50Hz PWM Signal (20ms Period).
* **Resolution:** 1µs tick precision (20,000 steps per cycle).
* **Range:** Maps sensor difference to a pulse width between 0.5ms ($0^\circ$) and 2.5ms ($180^\circ$).

### 4. Feedback (`lcd_controller.vhd`)
* **Visuals:** Displays real-time status ("TURN LEFT", "LOCKED") and raw 12-bit sensor values.
* **Conversion:** Includes a binary-to-BCD-to-ASCII converter for human-readable output.

---

### 💻 Technical Implementation Details

#### 1. Digital Signal Processing Implementation

To filter electrical noise from the LDR voltage dividers without using external capacitors, our group have designed a First-Order IIR (Infinite Impulse Response) Filter directly in the FPGA fabric (`pwm_gen.vhd`).

* **The Algorithm:** An **Exponential Moving Average** logic that acts as a digital low-pass filter.
  $$y[n] = \frac{31 \cdot y[n-1] + x[n]}{32}$$
* **Hardware Optimization:** The division by 32 is implemented via bit-shifting (`>> 5`), which consumes zero DSP slices compared to standard division logic.
* **Noise Rejection:** A Hysteresis Comparator with a programmable dead-band (`THRESHOLD = 300`) prevents the servo from oscillating or "chattering" when the light differential is negligible.

#### 2. Servo Control & Slew Rate Limiting
Standard PWM drivers often snap servos to position instantly, causing high current spikes and gear wear. our group have implemented a custom "Soft-Start" Ramp Controller.

* **Slew Rate Limiter:** A secondary counter (`ramp_timer`) slows down the position updates.
* **Logic:** The `current_pos` only increments/decrements towards the `target_pos` once every 1,500 clock cycles ($15\mu s$), creating a smooth, organic velocity profile regardless of the step size.

#### 3. Custom LCD Driver (HD44780)
Our group have developed a bare-metal driver to interface with the 16x2 LCD, managing the strict microsecond-level timing requirements of the HD44780 controller without a CPU.

 ![State_Transition_Table](https://github.com/user-attachments/assets/f2113290-5615-4d34-af94-b5d291377a13)
*Figure 3. The State Transition Table of The LCD Driver*

* **FSM Architecture:** A Mealy State Machine manages the initialization sequence (`0x38` Function Set $\to$ `0x0C` Display On $\to$ `0x01` Clear).
* **Timing Compliance:** The FSM enforces a 50µs setup time (`WAIT_EN` state) and a 2ms command execution time (`DELAY_STATE`) to prevent display corruption.
* **Data Conversion:** Instead of a memory-heavy lookup table, our group have implemented a real-time Binary-to-BCD-to-ASCII conversion algorithm (`val + 48`) to render 12-bit integer sensor values as human-readable text.

#### 4. XADC Interfacing
The project bypasses the XADC's automatic sequencer to implement a deterministic Manual Sequencer via the Dynamic Reconfiguration Port (DRP).

* **Channel Multiplexing:** The FSM explicitly switches addresses between `0x16` (Aux6) and `0x1E` (Aux14), waiting for the `EOC` (End of Conversion) signal before latching data.
* **Resolution:** Captures full 12-bit precision (0-4095 range) mapped to the 0V-1V analog input range of the Artix-7.

---

## 🔌 Hardware Pinout (Basys 3)

| Component | Signal Name | FPGA Pin | Description |
| :--- | :--- | :--- | :--- |
| **System** | `clk` | W5 | 100 MHz Onboard Clock |
| **Sensor L** | `vauxp6` / `vauxn6` | J3 / K3 | Left LDR Analog Input (JXADC Header) |
| **Sensor R** | `vauxp14` / `vauxn14` | L3 / M3 | Right LDR Analog Input (JXADC Header) |
| **Servo** | `servo_pwm` | A14 | PWM Signal Output |
| **LCD** | `lcd_rs` | A16 | Register Select |
| **LCD** | `lcd_en` | B15 | Enable Signal |
| **LCD** | `lcd_data[0-7]` | K17...R18 | 8-bit Data Bus |

---

## 🎥 Demonstration

[▶️ Watch Full Engineering Breakdown on YouTube](https://youtu.be/HuF9bkv2JE8)

---


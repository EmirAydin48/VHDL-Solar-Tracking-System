# SunflowerBot: FPGA-Based Autonomous Solar Tracking System

![demo](https://github.com/user-attachments/assets/1536b20f-7956-42f9-8431-87e7970cd9c4)

![Status](https://img.shields.io/badge/Status-Completed-success) ![Tech](https://img.shields.io/badge/Language-VHDL-blue) ![Board](https://img.shields.io/badge/Hardware-Basys3-orange) ![License](https://img.shields.io/badge/License-MIT-green)

## 🌻 Overview

SunflowerBot is an autonomous, heliotropic tracking system designed on the Artix-7 FPGA (Basys 3). It mimics nature by using a pair of Light Dependent Resistors (LDRs) to actively orient a servo motor toward the brightest light source in real-time.

Unlike microcontroller-based solutions that rely on sequential software execution, this project leverages FPGA parallelism to handle sensor acquisition, signal processing, and motor control simultaneously in hardware. The system features a custom RTL (Register Transfer Level) design that eliminates the need for a soft-core processor, ensuring deterministic, microsecond-level response times.

 🛠️ Key Engineering Features

* ⚡ Hardware-Accelerated Control Loop
    * Implements a Hysteresis Comparator with a 300-unit deadband to eliminate sensor noise and prevent servo "chattering" (rapid oscillation).
* Signal Processing Pipeline (DSP)
    * Features a custom Infinite Impulse Response Low-Pass Filter to smooth raw 12-bit sensor data before actuation.
*  Bare-Metal LCD Driver
    * A manual Finite State Machine implementation of the HD44780 protocol, managing microsecond-level timing constraints without external IP cores.
*  Precise Actuation
    * 50Hz PWM Generator with Slew-Rate Limiting to protect mechanical components from high-torque stress by gradually accelerating the servo.
*  XADC Interface
    * Direct control of the Artix-7 Dynamic Reconfiguration Port (DRP) to sequence the internal 12-bit Analog-to-Digital Converter.

## ⚙️ System Architecture

![System_Block_Diagram](https://github.com/user-attachments/assets/2a5c269f-cfff-4a3c-bdd9-182989aae2f3)

The architecture is a fully parallelized "Sense-Think-Act" pipeline:

### 1. Sensing (`xadc_interface.vhd`)
* **Input:** 2x Light Dependent Resistors (LDRs) forming voltage dividers.
* **Mechanism:** Interfaces with the XADC primitive to sample analog voltages at **12-bit resolution**.
* **Logic:** Uses a 4-state sequencer to multiplex the single ADC core between two analog channels (VAUX6 & VAUX14).

### 2. Processing (`sensor_compare.vhd` & `pwm_gen.vhd`)
* **Comparison:** Calculates the differential ($\Delta$) between Left and Right sensors.
* **Filtering:** Applies an IIR filter: $y[n] = 0.97 \cdot y[n-1] + 0.03 \cdot x[n]$. This dampens high-frequency noise (shadow flicker).
* **Decision:** Moves the servo only if $|\Delta| > \text{Threshold}$.

### 3. Actuation (`pwm_gen.vhd`)
* **Output:** 50Hz PWM Signal (20ms Period).
* **Resolution:** 1µs tick precision (20,000 steps per cycle).
* **Range:** Maps sensor difference to a pulse width between **0.5ms** ($0^\circ$) and **2.5ms** ($180^\circ$).

### 4. Feedback (`lcd_controller.vhd`)
* **Visuals:** Displays real-time status ("TURN LEFT", "LOCKED") and raw 12-bit sensor values.
* **Conversion:** Includes a binary-to-BCD-to-ASCII converter for human-readable output.

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

## 🎥 Demonstration

[▶️ Watch Full Engineering Breakdown on YouTube](https://youtu.be/HuF9bkv2JE8)

---

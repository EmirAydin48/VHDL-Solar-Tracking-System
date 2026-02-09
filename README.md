Available Languages: [English](README.md) | [Türkçe](README_TR.md)
 
# VHDL-Solar-Tracking-System

![demo](https://github.com/user-attachments/assets/1536b20f-7956-42f9-8431-87e7970cd9c4)

![Status](https://img.shields.io/badge/Status-Completed-success) ![Tech](https://img.shields.io/badge/Language-VHDL-blue) ![Board](https://img.shields.io/badge/Hardware-Basys3-orange)
 ## 🌻 Overview
 This project is a dual-axis solar tracking system implemented on the Artix-7 FPGA (Basys 3). It mimics the heliotropic behavior of a sunflower by using light dependent resistors mounted on the left and right sides of a servo motor to actively orient the servo motor towards the brightest light source. Unlike standard microcontroller implementations, this project handles analog signal processing and motor control entirely through digital hardware logic without a soft-core processor.
 ## 🛠️ Key Features
  * ### Closed-Loop Control
    Real-time feedback loop comparing dual LDR sensor values.
  * ### Motion Smoothing Logic
    Implemented a digital low-pass filter to smooth sensor noise and reduce servo shaking.
  * ### Custom LCD Driver
    A custom VHDL state machine to drive the 16x2 LCD, bypassing standard IP libraries.
  * ### XADC Integration
    Direct interface with the Artix-7 on-chip Analog-to-Digital Converter.
 ## ⚙️ System Architecture
 ![System_Block_Diagram](https://github.com/user-attachments/assets/2a5c269f-cfff-4a3c-bdd9-182989aae2f3)
  The system operates as a continuous data pipeline:
   ### 1. Sensing (xadc_interface.vhd) 
   Reads analog voltage from two Light Dependent Resistors (LDRs) using the FPGA's internal XADC primitive.
   ### 2. Logic (sensor_compare.vhd) 
   Calculates the delta between left and right sensors. If the difference exceeds a threshold (300), it triggers a move signal.
   ### 3. Actuation (pwm_gen.vhd) 
   Generates a 50Hz PWM signal. It uses a "ramp timer" to slowly adjust the servo position, creating smooth, organic motion rather than robotic snaps.
   ### 4. Feedback (lcd_controller.vhd) 
   Displays real-time status (e.g., "TURN LEFT", "IDLE") on the visual interface.
 ## 💻 Technical Implementation
 ![State_Transition_Table](https://github.com/user-attachments/assets/f2113290-5615-4d34-af94-b5d291377a13)
  ### 1. Signal Smoothing & Motor Control
   * To mitigate sensor noise, our group implemented a digital low-pass filter (moving average) in pwm_gen.vhd.
   * Smoothing: Sensor values are accumulated and averaged to filter out high-frequency noise. 
   * Ramping: A ramp_timer is used to gradually adjust the servo duty cycle. This ensures smooth, organic movement during travel, though some mechanical hunting may still occur at the precise threshold boundary.
  ### 2. Bare-Metal LCD State Machine
   * Instead of using a pre-made Xilinx IP, our group wrote a custom Finite State Machine (FSM) to handle the HD44780 LCD protocol.
   * Initialization: The FSM automatically cycles through the required 4-bit startup sequence.
   * ASCII Handling: A custom lookup table converts integer sensor values into ASCII characters for display.

[▶️ Watch Full 20-Minute Engineering Breakdown](https://youtu.be/HuF9bkv2JE8)







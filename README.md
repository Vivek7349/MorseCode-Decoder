# Morse Code Decoder on FPGA

**A Verilog RTL implementation of a Morse code decoder with seven-segment and VGA display outputs, targeting the Altera DE1-SoC (Cyclone V) FPGA board.**

![Language](https://img.shields.io/badge/Language-Verilog-3565A4)
![Platform](https://img.shields.io/badge/Platform-FPGA-1F6FEB)
![Device](https://img.shields.io/badge/FPGA-Cyclone%20V-5B4B8A)
![Tool](https://img.shields.io/badge/Tool-Quartus%20Prime-0081C6)

## Overview

This project implements Morse code decoding as a digital hardware design. Instead of using software to interpret the input, the FPGA captures a manually entered sequence of dots and dashes, decodes it into a character identifier, and drives display outputs.

The design is written in **Verilog HDL** and organized into separate modules for input capture, Morse pattern decoding, seven-segment display generation, and VGA output. The supplied Quartus project is configured for the **DE1-SoC board**, using an **Altera Cyclone V `5CSEMA5F31C6`** device.

> **Board note:** The checked-in Quartus settings (`top_mod_morse.qsf`) explicitly select the **DE1-SoC**, not the older DE2 board. If you are using different hardware, verify the FPGA device and pin assignments before programming it.

## Features

- **RTL-based Morse decoding:** Maps manually entered dot/dash sequences to alphabetic character codes.
- **A–Z lookup:** Includes decode entries for all 26 English letters using standard Morse patterns of one to four symbols.
- **Sequential input capture:** Uses a clocked shift register and a symbol counter.
- **User-controlled decoding:** Separate controls for Morse input, clocking, decoding, and display enabling.
- **Seven-segment visualization:** Generates character-oriented segment patterns and two additional displays driven by parts of the decoded identifier.
- **VGA output:** Includes video timing and character-display logic with a configured 640 × 480 active display area.
- **FPGA project files:** Includes Quartus settings, RTL sources, and existing generated build/simulation directories.

## Hardware and tools

| Item | Configuration |
| --- | --- |
| Target development board | Altera DE1-SoC |
| FPGA family | Cyclone V |
| FPGA device | `5CSEMA5F31C6` |
| Hardware description language | Verilog HDL |
| FPGA design software | Quartus Prime Lite (project last saved with 25.1std.0) |
| Simulation tool configured in project | Questa Altera FPGA (Verilog) |
| User interface | Board switches, push button, LEDs, seven-segment displays, VGA |

## How it works

```text
     Switch input (dot / dash)
                |
         Push-button clock
                |
                v
       +------------------+
       |    data_in.v     |
       | Shift register   |
       | + symbol count   |
       +------------------+
                |
                v
       +------------------+     Decode control
       |  data_decoder.v  | <------ SW1
       | Morse lookup     |
       +------------------+
                |
         Character code
                |
      +---------+----------+
      |         |          |
      v         v          v
 +----------+ +----------+ +-------------------+
 |sevenseg.v| |bcd_7_seg | | display_project.v |
 | Letter   | |  .v      | | VGA character     |
 | pattern  | | Code on  | | display and       |
 | on HEX2  | | HEX0/HEX1| | video timing      |
 +----------+ +----------+ +-------------------+
```

1. **Capture input:** Set the data switch to `0` for a dot (`.`) or `1` for a dash (`-`), then provide a rising edge on the input clock. Each symbol is shifted into the input register.
2. **Track symbol count:** The input module increments a counter for the symbols entered.
3. **Decode the sequence:** When the decode control is asserted, `data_decoder.v` uses the count and stored bit pattern to select a character identifier.
4. **Display the result:** The decoded identifier is supplied to the seven-segment modules and the VGA display module.

**Input encoding:** `0 = dot (.)` and `1 = dash (-)`. The sequence is entered **from left to right**, one symbol at a time. This is manual switch-based input; the current RTL does **not** measure audio tones or automatically distinguish dots and dashes by pulse duration.

## Board controls and outputs

The following mapping reflects the comments in `top_mod_morse.v` and the pin assignments in `top_mod_morse.qsf`.

| Board interface | RTL signal | Function |
| --- | --- | --- |
| `SW0` | `data_in` | Morse symbol: dot `0` / dash `1` |
| `KEY0` | `clk` | Clock input used to capture each symbol on a rising edge |
| `SW1` | `send_data` | Enable Morse-pattern decoding |
| `SW2` | `inp` | Enable character-oriented seven-segment output |
| `SW3` | `high` | VGA display control |
| `SW4` | `vga_rst` | VGA reset input |
| `SW5` | `rst` | Decoder/input reset (active low in the input and decoder RTL) |
| 50 MHz board clock | `clk_50m` | VGA logic clock source |
| `LEDR[3:0]` | `count[3:0]` | Number of captured Morse symbols |
| `LEDR[8:4]` | `out[4:0]` | Captured input register contents |
| `HEX2` | `led[6:0]` | Decoded letter's seven-segment pattern |
| `HEX0`, `HEX1` | `seg_out_1`, `seg_out_2` | Segments driven by the low four bits and high bit of the character code |
| VGA connector | `vga_red`, `vga_green`, `vga_blue`, sync signals | Video output |

> The top-level RTL also declares `handshake_sig` (mapped to `LEDR9`), but does not currently assign a driver to it. Do not rely on that LED as a functioning handshake indicator without updating the RTL.

## Morse code examples

| Letter | Morse code | Input bits (`.` = 0, `-` = 1) |
| --- | --- | --- |
| A | `.-` | `01` |
| B | `-...` | `1000` |
| C | `-.-.` | `1010` |
| E | `.` | `0` |
| H | `....` | `0000` |
| M | `--` | `11` |
| O | `---` | `111` |
| S | `...` | `000` |
| T | `-` | `1` |
| V | `...-` | `0001` |

The decoder assigns internal numerical identifiers to letters (`A = 0`, `B = 1`, …, `Z = 25`). These identifiers are used by the display logic; they are **not ASCII values**. The RTL also contains a special internal `SPACE_m` identifier. Note that `bcd_7_seg.v` recognizes digit inputs `0` through `9`; it is not a complete two-digit decimal converter for the full `0`–`25` character-code range.

### Example: Entering the letter A (`.-`)

1. Set `SW5 = 0` to reset the input and decoding logic; then set `SW5 = 1` to release reset.
2. Keep `SW1 = 0` while entering a new sequence.
3. Set `SW0 = 0` (dot) and generate a rising edge on `KEY0`.
4. Set `SW0 = 1` (dash) and generate another rising edge on `KEY0`.
5. Set `SW1 = 1` to enable decoding.
6. Set `SW2 = 1` to enable the decoded-letter seven-segment output. The VGA output is controlled separately by `SW3`.

The letter's internal code and display pattern are produced by the respective decoder/display modules. Push-button inputs may need debouncing for dependable single-step entry on physical hardware.

## Repository structure

```text
MorseCode-Decoder/
├── top_mod_morse.v          # Top-level RTL module and interconnect
├── data_in.v                # Clocked input shift register and count
├── data_decoder.v           # Morse sequence-to-character decoding
├── sevenseg.v               # Letter patterns for seven-segment display
├── bcd_7_seg.v              # Numerical seven-segment encoding
├── display_project.v       # VGA timing and character graphics
├── top_mod_morse.qpf        # Quartus project file
├── top_mod_morse.qsf        # Quartus device, source and pin assignments
├── top_mod_morse.qws        # Quartus workspace settings
├── simulation/
│   └── questa/              # Existing Questa simulation directory
├── output_files/            # Existing Quartus-generated outputs
├── db/                      # Quartus build database
├── incremental_db/          # Quartus incremental compilation database
├── *.v.bak                  # Backup copies of RTL files
└── README.md
```

**Top-level entity:** `top_mod_morse`

The `db/`, `incremental_db/`, backup files, and some contents of `output_files/` are tool-generated. They are included in the current repository, but are generally not required in version control for a clean source-based project.

## Getting started

### 1. Clone the project

```bash
git clone https://github.com/Vivek7349/MorseCode-Decoder.git
cd MorseCode-Decoder
```

### 2. Open the Quartus project

1. Launch a compatible **Quartus Prime Lite** installation with Cyclone V device support.
2. Select **File → Open Project**.
3. Open `top_mod_morse.qpf`.
4. Confirm that the top-level entity is `top_mod_morse`.
5. Check **Assignments → Device** and the pin mappings before compiling for your board.

### 3. Compile the RTL

In Quartus, select **Processing → Start Compilation**. Review the compilation messages and the generated reports for errors, warnings, resource usage, and timing results.

### 4. Program the FPGA

1. Connect the DE1-SoC board and the appropriate programming cable/interface.
2. Open **Tools → Programmer** in Quartus.
3. Select the connected programming hardware.
4. Load the `.sof` programming file **if one is present or generated by a successful compilation**.
5. Program the FPGA and use the mapped controls to enter Morse symbols.

### 5. Simulation

The Quartus project is configured to use **Questa Altera FPGA** for Verilog simulation, and the repository includes a `simulation/questa/` directory. Inspect or prepare the required simulation setup/testbench before running functional verification; the presence of this directory alone does not establish that an automated testbench has been provided or passed.

## Design scope and possible extensions

The current project focuses on **manually entered Morse symbols** and single-character decode/display behavior. Potential enhancements include:

- Button debouncing and input synchronization.
- Automatic dot/dash recognition using pulse-duration measurement.
- Inter-character and inter-word timing detection.
- Decoding complete messages into a character buffer.
- UART output and automated simulation testbenches.
- Additional board-level verification screenshots and a short demo video.

## What this project demonstrates

- Modular RTL design in Verilog.
- Sequential logic using shift registers and counters.
- Combinational lookup and code decoding.
- FPGA board I/O and pin assignment management.
- Seven-segment display interfacing and VGA timing/graphics integration.
- Working with a complete Quartus FPGA project structure.

## Repository

**GitHub:** [Vivek7349/MorseCode-Decoder](https://github.com/Vivek7349/MorseCode-Decoder)

---

*An FPGA digital-design project focused on Morse code decoding and hardware-based display interfacing.*

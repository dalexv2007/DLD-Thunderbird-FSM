# Thunderbird Taillight Controller — FPGA Final Project

A Moore FSM implementation of a 1965 Ford Thunderbird sequential taillight controller, targeting the Basys3 FPGA board. Implemented in SystemVerilog with ModelSim simulation and Vivado synthesis.

## Overview

The Thunderbird taillight system drives six LEDs (three per side) with sequential lighting patterns for turn signals, a full-on brake pattern, and a combined hazard mode. FSM state is decoded and displayed on the onboard seven-segment display.

## Hardware Target

- **Board:** Digilent Basys3 (Artix-7 FPGA)
- **Clock:** 100 MHz onboard oscillator (L18)
- **Inputs:** 4 pushbuttons (active-high)
- **Outputs:** 6 LEDs, 7-segment display (rightmost digit)

## Project Structure

```
thunderbird/
├── thunderbird_FSM.sv         # Core Moore FSM — states, transitions, output logic
├── thunderbird_top.sv         # Top-level integration module
├── sevseg_decoder.sv          # FSM state → 7-segment pattern decoder
├── clock_divider.sv           # 100MHz → ~1.5Hz clock for visible LED sequencing
├── thunderbird_tb.sv          # Self-checking testbench
├── thunderbird_do.do          # ModelSim simulation script
└── thunderbird_constraints.xdc # Pin assignments for Basys3
```

## FSM Design

### Main States (`state_t`)

| State | Encoding | Description |
|---|---|---|
| `S_IDLE` | 3'd0 | All lights off, awaiting input |
| `S_LEFT` | 3'd1 | Left turn sequential sequence |
| `S_RIGHT` | 3'd2 | Right turn sequential sequence |
| `S_BRAKE` | 3'd3 | All lights on, held until released |
| `S_HAZARD` | 3'd4 | Both sides sequence simultaneously |

### Substates (`substate_t`) — Light Sequencer

Turn and hazard sequences are tracked via a parallel substate register rather than counters, keeping output logic a direct combinational lookup.

| Substate | LIGHTS[5:0] | Meaning |
|---|---|---|
| `ID` | `000000` | Idle / all off |
| `LA` | `001000` | Left step 1 |
| `LB` | `011000` | Left step 2 |
| `LC` | `111000` | Left step 3 → exits to IDLE |
| `RA` | `000100` | Right step 1 |
| `RB` | `000110` | Right step 2 |
| `RC` | `000111` | Right step 3 → exits to IDLE |
| `HA` | `001100` | Hazard step 1 |
| `HB` | `011110` | Hazard step 2 |
| `HC` | `111111` | Hazard step 3 → loops to HA |
| `B`  | `111111` | Brake — all on |

### Input Priority (highest to lowest)

1. `RESET` — synchronous, always returns to `S_IDLE`
2. `BRAKE` — overrides any active turn/hazard
3. `LEFT && RIGHT` — enters `S_HAZARD`
4. `LEFT` or `RIGHT` — enters respective turn state
5. Sequence completion — returns to `S_IDLE`

### Seven-Segment Display

The rightmost digit displays the current FSM main state as a letter:

| State | Display |
|---|---|
| IDLE | (off) |
| LEFT | `L` |
| RIGHT | `r` |
| BRAKE | `b` |
| HAZARD | `H` |

## Module Summary

### `thunderbird_FSM.sv`
Core FSM. Three `always` blocks: one sequential (register), one combinational for `STATE`/`LIGHTS` output, one combinational for next-state/next-lights logic. Helper functions `next_left_light`, `next_right_light`, `next_hazard_light` advance the substate sequence.

### `thunderbird_top.sv`
Integrates FSM, clock divider, and display decoder. Expands `LIGHTS[5:0]` to individual LED ports. Holds `sseg_an = 4'b1110` to enable only the rightmost display digit.

### `sevseg_decoder.sv`
Purely combinational. Maps the 3-bit `STATE` value to an 8-bit active-low segment pattern.

### `clock_divider.sv`
Free-running 32-bit counter; `clk_out = counter[25]` produces ~1.49 Hz from 100 MHz, giving a visible LED blink rate.

## Simulation

```bash
# In ModelSim
do thunderbird_do.do
```

The testbench covers: reset, left sequence, right sequence, brake hold/release, hazard loop, brake priority over left, hazard priority over single turn, and brake-release-with-turn-held transition.

**Verified transcript output (100 MHz sim clock, 10ns period):**
```
RESET                → STATE=ff LIGHTS=000000
LEFT LA/LB/LC/IDLE   → STATE=10 LIGHTS=001000/011000/111000/000000
RIGHT RA/RB/RC/IDLE  → STATE=20 LIGHTS=000100/000110/000111/000000
BRAKE on/held/off    → STATE=0c LIGHTS=111111
HAZARD HA/HB/HC/HA   → STATE=0d LIGHTS=001100/011110/111111/001100
BRAKE+LEFT priority  → STATE=0c (BRAKE wins)
BRAKE release + LEFT → STATE=10 (resumes S_LEFT)
```

## Build (Vivado)

1. Create project targeting `xc7a35tcpg236-1` (Basys3)
2. Add all `.sv` source files; set `thunderbird_top` as top
3. Add `thunderbird_constraints.xdc`
4. Run Synthesis → Implementation → Generate Bitstream
5. Program device via JTAG

## Pin Assignments Summary

| Signal | Pin | Notes |
|---|---|---|
| `CLK` | L18 | 100 MHz oscillator |
| `BRAKE` | U12 | Active-high pushbutton |
| `RIGHT` | V12 | Active-high pushbutton |
| `LEFT` | U7 | Active-high pushbutton |
| `RESET` | Y6 | Active-high pushbutton |
| `LC/LB/LA/RA/RB/RC` | V8/W11/W12/V7/Y8/Y9 | Active-high LEDs |
| `sseg_an[3:0]` | J20/J18/H20/K19 | Active-low anode select |
| `ssegout[7:0]` | H19–K20 | Active-low segment outputs |

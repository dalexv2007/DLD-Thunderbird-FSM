# Thunderbird Taillight Controller — Project Todo
**ECEN 2233 | Spring 2026 | Final Project**

> **How to use this file:**
> - In VS Code: install the "Todo Tree" or "Markdown Checkboxes" extension to make checkboxes interactive.
> - On GitHub: paste into a repo Wiki or Issue — checkboxes render and are clickable natively.
> - In Notion: use "Import > Text & Markdown".
> - As a plain text doc: replace `[ ]` with `[x]` manually when done.

---

## Priority Key
- 🔴 **Red** — Fix now (blocks compilation/everything else)
- 🟡 **Amber** — Fix before simulation
- 🟢 **Green** — Implement next
- 🔵 **Blue** — Simulation, verification, and final demo

---

## 🔴 Critical Bugs — Fix Before Anything Else

### 1. `thunderbird_top.sv`: `LIGHTS` wire is declared but never defined
- [ ] **Task:** Add `logic [5:0] LIGHTS;` as an internal signal in `thunderbird_top`, between the port list and the `assign` statements.
- **Why:** The top module drives `LC/LB/LA/RA/RB/RC` from `LIGHTS[5:0]` and passes `LIGHTS` into the FSM, but `LIGHTS` is never declared as an internal wire. This causes a compilation error in both ModelSim and Vivado.
- **Implementation notes:**
  - Place the declaration directly after the module port list, before the `assign` statements.
  - Example: `logic [5:0] LIGHTS;`

---

### 2. `thunderbird_top.sv`: `STATE` output port conflicts with FSM `.STATE` connection
- [ ] **Task:** Declare an intermediate wire `logic [7:0] state_bus;`, connect the FSM and sevseg decoder through it, and assign it to the output port.
- **Why:** You cannot drive an output port from a submodule using the same name without an intermediate wire — some tools accept it, others flag it as a multiple-driver error.
- **Implementation notes:**
  - Declare: `logic [7:0] state_bus;`
  - FSM connection: `.STATE(state_bus)`
  - Sevseg decoder connection: `.data_in(state_bus)`
  - Port assignment: `assign STATE = state_bus;`
  - Alternatively, remove the `STATE` output port entirely — the project spec only requires the 7-seg display, not a raw STATE output.

---

### 3. `sevseg_decoder.sv`: `sseg_digit` has multiple drivers — two separate `always_comb` blocks both assign it
- [ ] **Task:** Merge the two `always_comb` blocks into one, or promote `sseg_digit` to a wire driven only by the state-decode block and compute a separate `muxed_digit` for the counter/anode block.
- **Why:** `sseg_digit` is assigned in one `always_comb` (the state-to-char mapping) and again in a second `always_comb` (the `default` branch sets it to `4'hF`). A signal driven by two separate `always_comb` blocks is a multiple-driver error — illegal in synthesizable SystemVerilog.
- **Implementation notes:**
  - Preferred fix: combine into one `always_comb` block. First decode state → character, then use the counter to gate the anode.
  - Or: rename the blanking assignment target to `logic [3:0] muxed_digit` and use that to feed `sevenseg_hex`.

---

## 🟡 Logic Issues — Fix Before Simulation

### 4. FSM: Hazard state is missing the full sequential pattern (only LA+RA, never advances)
- [ ] **Task:** Add `H1`, `H2`, `H3` states to replace the single `H` state, implement the three-step sequence, and loop it continuously.
- **Why:** The spec requires hazard to sequence: (1) LA+RA → (2) LA+LB+RA+RB → (3) all six on — then repeat. Currently a single `H` state stays at LA+RA forever.
- **Implementation notes:**
  - State encodings (suggest): `H1 = 8'h30`, `H2 = 8'h31`, `H3 = 8'h32`
  - LIGHTS assignments:
    - `H1`: `6'b001100` (LA + RA)
    - `H2`: `6'b011110` (LA + LB + RA + RB)
    - `H3`: `6'b111111` (all six on)
  - Transitions: H1 → H2 → H3 → H1, with BRAKE and RESET priority at each state.
  - Update `sevseg_decoder.sv` to map all three H states (`8'h30`, `8'h31`, `8'h32`) to display character `4'hD` ('H').

---

### 5. `clock_divider.sv`: FSM clock and display multiplexing clock are not connected in the top module
- [ ] **Task:** Instantiate `clock_divider` in `thunderbird_top.sv` and route `clk_1Hz` to the FSM and a fast clock to the sevseg decoder.
- **Why:** The clock divider module exists but is never instantiated anywhere. Both the FSM and sevseg decoder currently receive the raw 100 MHz `CLK`, which makes the FSM transition millions of times per second (invisible to the human eye) and redundantly double-divides the display clock.
- **Implementation notes:**
  - In `thunderbird_top`, add:
    ```systemverilog
    logic clk_fsm, clk_disp;
    clock_divider u_clkdiv (
        .clk_in(CLK),
        .clk_200Hz(clk_disp),
        .clk_1Hz(clk_fsm)
    );
    ```
  - Pass `clk_fsm` (1 Hz) to `thunderbird_FSM`'s CLK port.
  - Pass raw `CLK` (100 MHz) to `sevseg_decoder` for proper ~1 kHz multiplexing.
  - Remove or simplify the internal clock divider inside `sevseg_decoder` — it becomes redundant once the top level handles clock routing.
  - Decision to make with partner: use `clk_1Hz` for a slow visible demo, or `clk_200Hz` for a faster (5 steps/sec) sequence. Note your choice in a comment.

---

### 6. `thunderbird_constraints.xdc`: CLK pin is missing — Vivado will fail without it
- [ ] **Task:** Add the 100 MHz system clock pin constraint and a `create_clock` timing constraint.
- **Why:** The constraints file has buttons, LEDs, and seven segment pins, but no clock pin. Vivado cannot place and route without a defined clock.
- **Implementation notes:**
  - For the OSU lab board (confirm with your TA — board variants differ):
    ```tcl
    set_property PACKAGE_PIN W5 [get_ports CLK]
    set_property IOSTANDARD LVCMOS33 [get_ports CLK]
    create_clock -period 10.000 -name sys_clk [get_ports CLK]
    ```
  - Verify the exact pin number with your lab's board reference sheet or the TA before implementing.

---

### 7. `sevenseg_hex.sv`: Segment patterns for 'L', 'r', 'b', 'H' need visual verification
- [ ] **Task:** Verify each custom character pattern against a standard 7-segment diagram. Correct any wrong patterns before hardware testing.
- **Why:** The segment patterns are asserted but not yet verified against real hardware. An error here will silently produce garbled characters on the display.
- **Implementation notes:**
  - Standard segment positions: `[a=top, b=top-right, c=bot-right, d=bot, e=bot-left, f=top-left, g=mid]`, active-LOW in your design.
  - Draw each on paper first using the diagram below, then confirm the binary value:
    ```
        _
       |_|     Segments: a(top), b(top-R), c(bot-R),
       |_|               d(bot), e(bot-L), f(top-L), g(mid)
    ```
  - **'L'** → segments F, E, D on → bits `[a b c d e f g]` = `1100001` ✓ (verify current value matches)
  - **'r'** → segments G, E on → `0101111` — NOTE: spec says display 'r' (lowercase) for Right, which is more readable on hardware than uppercase 'R'. Check the current `4'hB` mapping.
  - **'b'** → segments C, D, E, F, G on → `1000000` — current value `1100000` may be missing segment D. Verify.
  - **'H'** → segments B, C, E, F, G on → `1001000` ✓ (verify current value matches)

---

## 🟢 Implementation — Write This Next

### 8. Write `thunderbird_tb.sv` — the testbench file is currently empty (100 pts simulation grade)
- [ ] **Task:** Write a complete testbench that exercises all FSM states, priority behavior, and edge cases.
- **Why:** The uploaded testbench file is empty. The ModelSim simulation section is worth 100 of 300 points.
- **Implementation notes:**
  - Module name must be `tb` to match the `.do` file's `vsim work.tb` command.
  - Instantiate `thunderbird_FSM` directly (not the top module) for isolated logic testing.
  - Clock generation: `always #5 CLK = ~CLK;` (10 ns period = 100 MHz equivalent for simulation).
  - Required test sequences (write as sequential `initial` blocks):
    1. **RESET → IDLE**: Assert RESET, verify LIGHTS = `6'b000000` and STATE = IDLE.
    2. **LEFT full sequence**: Deassert RESET, assert LEFT. Verify LA → LB → LC transitions over 3 clock edges.
    3. **LEFT held**: Keep LEFT high at LC, verify restart at LA (not IDLE).
    4. **LEFT released mid-sequence**: Release LEFT during LA, verify return to IDLE at end of sequence.
    5. **RIGHT full sequence**: Mirror of LEFT test.
    6. **BRAKE override**: Start LEFT sequence (in LA), assert BRAKE — verify immediate jump to B state.
    7. **BRAKE release**: Release BRAKE while LEFT still held — verify return to LA.
    8. **HAZARD**: Assert both LEFT and RIGHT — verify H1 → H2 → H3 → H1 loop.
    9. **BRAKE over HAZARD**: Assert BRAKE while in hazard — verify jump to B.
    10. **RESET mid-sequence**: Assert RESET during LB — verify immediate return to IDLE.
  - Add `$monitor("Time=%0t STATE=%h LIGHTS=%b", $time, STATE, LIGHTS);` at the top of `initial` for automatic logging.
  - End with `$finish;`.

---

### 9. Update `do_template.do` to compile all files and run long enough to see full sequences
- [ ] **Task:** Add all module files to the `vlog` compile line and extend the simulation run time.
- **Why:** The current `.do` file only compiles `thunderbird_FSM.sv` and `thunderbird_tb.sv`. Missing files will cause undefined module errors in ModelSim.
- **Implementation notes:**
  - Replace the `vlog` line with:
    ```tcl
    vlog sevenseg_hex.sv sevseg_decoder.sv clock_divider.sv thunderbird_FSM.sv thunderbird_top.sv thunderbird_tb.sv
    ```
  - Change `run 250 ns` to `run 2000 ns` (or longer — at 10 ns clock, a 3-step sequence takes 30 ns, but you need time to observe all test cases).
  - Confirm the `vsim` line matches your testbench module name: `vsim -voptargs=+acc work.tb`

---

### 10. Complete `thunderbird_top.sv`: wire up clock divider and clean up internal signals (after fixing bugs 1–3 and 5)
- [ ] **Task:** After all bug fixes are in, do a final pass to ensure the top module is complete and all ports are connected.
- **Why:** The top module is the integration point — all submodules must be instantiated and connected correctly for both simulation and FPGA synthesis.
- **Implementation notes:**
  - Final checklist for `thunderbird_top`:
    - [ ] `logic [5:0] LIGHTS;` declared
    - [ ] `logic [7:0] state_bus;` declared
    - [ ] `logic clk_fsm, clk_disp;` declared
    - [ ] `clock_divider` instantiated
    - [ ] `thunderbird_FSM` instantiated with `clk_fsm`
    - [ ] `sevseg_decoder` instantiated with raw `CLK`
    - [ ] All `assign` statements for individual LED ports present
    - [ ] No unconnected ports or implicit wires

---

## 🔵 Simulation & Verification

### 11. Run ModelSim — verify all FSM state transitions in the waveform
- [ ] **Task:** Run the `.do` file in ModelSim, capture the waveform, and verify every state transition against expected behavior.
- **Notes:**
  - Verify LIGHTS output matches expected values for each state (reference `[LC LB LA RA RB RC]` bit ordering in the FSM comments).
  - Verify priority: BRAKE while in LA → immediate jump to B next clock edge.
  - Verify hazard sequence: all three H states appear in order and loop.
  - Verify LC with LEFT held → restarts at LA. LC with LEFT released → goes to IDLE.
  - **Take a labeled screenshot of the waveform for your lab report** — annotate key transitions.

---

### 12. Verify seven segment display output in simulation
- [ ] **Task:** Check `sseg_an` and `ssegout` values in the waveform for each FSM state.
- **Notes:**
  - Confirm `sseg_an = 4'b1110` when the rightmost display is active (active-LOW: a 0 enables the digit).
  - Confirm `ssegout` encodes the correct character per state — cross-reference against `sevenseg_hex.sv` patterns.
  - If multiplexing is too fast to observe in sim, temporarily set the counter threshold lower for testbench purposes.

---

### 13. Vivado: synthesize, implement, and check for warnings
- [ ] **Task:** Create a Vivado project, add all files, synthesize and implement, then check reports before generating a bitstream.
- **Notes:**
  - Set `thunderbird_top` as the top module.
  - Add `thunderbird_constraints.xdc` (after adding the CLK pin — see item 6).
  - Synthesis warnings to watch for: undriven signals, latch inferences (`always_comb` without full case coverage), multiple drivers.
  - Implementation: check timing report for failing paths (the slow FSM clock should have ample slack — a failure here signals a wiring error, not a real timing problem).
  - Fix any critical warnings before generating the bitstream.

---

### 14. Hardware demo: test all modes on the physical FPGA board
- [ ] **Task:** Program the board and manually test every mode. Confirm with a TA or record for submission.
- **Notes:**
  - Test each mode individually: LEFT turn, RIGHT turn, BRAKE, HAZARD, RESET.
  - Confirm LED sequence is visible and correctly timed — adjust the clock divider counter bit if too fast or too slow.
  - Confirm 7-seg shows the right character for each mode ('L', 'r', 'H', 'b', blank for IDLE).
  - Test priority explicitly: hold BRAKE + LEFT simultaneously → only brake lights, display shows 'b'.
  - Test RESET mid-sequence: press RESET during a running turn sequence → immediate IDLE.
  - **Record a short video or get TA sign-off for demo credit.**

---

## Submission Checklist
*(from the project spec)*

- [ ] `thunderbird_top.sv`
- [ ] `thunderbird_FSM.sv`
- [ ] `sevseg_decoder.sv` (submitted as `seven_seg_decoder.sv` per spec — rename before submitting)
- [ ] `clock_divider.sv`
- [ ] `thunderbird_tb.sv` (submitted as `tb_thunderbird.sv` per spec — rename before submitting)
- [ ] Lab report (PDF)
- [ ] All files zipped into a single `.zip` and submitted to Canvas

---

*Generated from code review of all project files. Last updated: April 2026.*

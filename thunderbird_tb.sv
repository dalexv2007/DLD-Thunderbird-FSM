module tb;

    logic BRAKE, RIGHT, LEFT, RESET, CLK;
    logic [5:0] LIGHTS;   // output from FSM, [LC LB LA RA RB RC]
    logic [7:0] STATE;    // output from FSM, used by sevseg_decoder upstream

    // --- Instantiate your FSM directly ---
    // thunderbird_FSM is the module under test
    // We skip thunderbird_top here so the clock divider doesn't slow simulation
    thunderbird_FSM dut (
        .BRAKE(BRAKE),
        .RIGHT(RIGHT),
        .LEFT(LEFT),
        .RESET(RESET),
        .CLK(CLK),
        .LIGHTS(LIGHTS),
        .STATE(STATE)
    );

    // --- Clock: 10ns period (100MHz) ---
    // Fast enough to simulate quickly, slow enough to be readable in waveform
    initial CLK = 0;
    always #5 CLK = ~CLK;

    // --- Task: set inputs, wait one clock edge, then print result ---
    // Call this once per expected state transition
    task tick(
        input logic b, r, l, rst,
        input string label
    );
        // Apply inputs combinationally before the clock edge
        BRAKE = b;
        RIGHT = r;
        LEFT  = l;
        RESET = rst;
        @(posedge CLK);   // advance one FSM clock cycle
        #1;               // tiny delay so outputs settle after posedge
        $display("[%0t ns] %-30s | STATE=%0h | LIGHTS=%06b", 
                 $time, label, STATE, LIGHTS);
    endtask

    initial begin
        // Initialize all inputs low
        BRAKE=0; RIGHT=0; LEFT=0; RESET=0;

        // -------------------------------------------------------
        // RESET: should go to S_IDLE, LIGHTS=000000, STATE=0xFF
        // -------------------------------------------------------
        tick(0, 0, 0, 1, "RESET");
        tick(0, 0, 0, 0, "IDLE (after reset)");

        // -------------------------------------------------------
        // LEFT TURN: LA -> LB -> LC -> back to IDLE
        // LIGHTS expected: 001000 -> 011000 -> 111000 -> 000000
        // STATE expected:  0x10 throughout S_LEFT
        // -------------------------------------------------------
        tick(0, 0, 1, 0, "LEFT: expect LA  (001000)");
        tick(0, 0, 1, 0, "LEFT: expect LB  (011000)");
        tick(0, 0, 1, 0, "LEFT: expect LC  (111000)");
        tick(0, 0, 0, 0, "LEFT released:   expect IDLE");

        // -------------------------------------------------------
        // RIGHT TURN: RA -> RB -> RC -> back to IDLE
        // LIGHTS expected: 000100 -> 000110 -> 000111 -> 000000
        // STATE expected:  0x20 throughout S_RIGHT
        // -------------------------------------------------------
        tick(0, 1, 0, 0, "RIGHT: expect RA (000100)");
        tick(0, 1, 0, 0, "RIGHT: expect RB (000110)");
        tick(0, 1, 0, 0, "RIGHT: expect RC (000111)");
        tick(0, 0, 0, 0, "RIGHT released:  expect IDLE");

        // -------------------------------------------------------
        // BRAKE: all lights on, stays until released
        // LIGHTS expected: 111111, STATE=0x0C
        // -------------------------------------------------------
        tick(1, 0, 0, 0, "BRAKE on:        expect 111111");
        tick(1, 0, 0, 0, "BRAKE held:      expect 111111");
        tick(0, 0, 0, 0, "BRAKE released:  expect IDLE");

        // -------------------------------------------------------
        // HAZARD: HA -> HB -> HC -> repeats
        // LIGHTS: 001100 -> 011110 -> 111111 -> repeats
        // STATE=0x0D throughout
        // -------------------------------------------------------
        tick(0, 1, 1, 0, "HAZARD: expect HA (001100)");
        tick(0, 1, 1, 0, "HAZARD: expect HB (011110)");
        tick(0, 1, 1, 0, "HAZARD: expect HC (111111)");
        tick(0, 1, 1, 0, "HAZARD repeat HA  (001100)");

        // -------------------------------------------------------
        // PRIORITY TEST 1: BRAKE beats LEFT
        // Even with LEFT active, BRAKE should win -> STATE=0x0C
        // -------------------------------------------------------
        tick(0, 0, 0, 1, "RESET (clear state)");
        tick(0, 0, 1, 0, "LEFT active (setup LA)");
        tick(1, 0, 1, 0, "BRAKE+LEFT: BRAKE must win (111111)");
        tick(1, 0, 1, 0, "BRAKE+LEFT held: still BRAKE");
        tick(0, 0, 0, 0, "Both released: expect IDLE");

        // -------------------------------------------------------
        // PRIORITY TEST 2: HAZARD beats single turn
        // LEFT+RIGHT together should enter HAZARD, not LEFT
        // -------------------------------------------------------
        tick(0, 1, 1, 0, "LEFT+RIGHT: expect HAZARD HA");
        tick(0, 1, 1, 0, "LEFT+RIGHT: expect HAZARD HB");

        // -------------------------------------------------------
        // BRAKE exit behavior: when BRAKE released with LEFT still held,
        // should transition to S_LEFT not S_IDLE
        // -------------------------------------------------------
        tick(0, 0, 0, 1, "RESET");
        tick(1, 0, 1, 0, "BRAKE+LEFT (brake wins)");
        tick(0, 0, 1, 0, "Release BRAKE, LEFT held: expect S_LEFT LA");

        $display("--- Simulation complete ---");
        $stop;
    end

endmodule
module thunderbird_top(
    input logic BRAKE,
    input logic RIGHT,
    input logic LEFT,
    input logic RESET,
    input logic CLK,
    output logic LC, LB, LA, RA, RB, RC,
    output logic [3:0] sseg_an,    // seven segment anode control (active-low)
    output logic [7:0] ssegout     // seven segment output [a b c d e f g dp]
);

    logic [5:0] LIGHTS;  // 6 bits for the 6 lights
    logic [2:0] STATE;   // 3-bit state for seven segment display
    logic clk_div;  // Clock divider for the seven segment display

    assign sseg_an = 4'b1110; // default rightmost on, others off

    assign LC = LIGHTS[5];  // Bit 5 → LC
    assign LB = LIGHTS[4];  // Bit 4 → LB
    assign LA = LIGHTS[3];  // Bit 3 → LA
    assign RA = LIGHTS[2];  // Bit 2 → RA
    assign RB = LIGHTS[1];  // Bit 1 → RB
    assign RC = LIGHTS[0];  // Bit 0 → RC

    clock_divider u_clock_divider (
        .clk_in(CLK),
        .clk_out(clk_div)
    );

    thunderbird_FSM u_FSM (
        .BRAKE(BRAKE),
        .RIGHT(RIGHT),
        .LEFT(LEFT),
        .RESET(RESET),
        .CLK(clk_div),
        .LIGHTS(LIGHTS),
        .STATE(STATE)
    );
    
    // Seven segment display decoder for STATE
    sevseg_decoder u_sevseg_decoder (
        .data_in(STATE),
        .ssegout(ssegout)
    );
    
endmodule
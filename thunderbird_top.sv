module thunderbird_top(
    input logic BRAKE,
    input logic RIGHT,
    input logic LEFT,
    input logic RESET,
    input logic CLK,
    output logic [5:0] LIGHTS,
    output logic [7:0] STATE,
    output logic [3:0] sseg_an,    // seven segment anode control (active-low)
    output logic [7:0] ssegout     // seven segment output [a b c d e f g dp]
);

    thunderbird_FSM u_FSM (
        .BRAKE(BRAKE),
        .RIGHT(RIGHT),
        .LEFT(LEFT),
        .RESET(RESET),
        .CLK(CLK),
        .LIGHTS(LIGHTS),
        .STATE(STATE)
    );
    
    // Seven segment display decoder for STATE
    sevseg_decoder u_sevseg_decoder (
        .CLK(CLK),
        .data_in(STATE),
        .sseg_an(sseg_an),
        .ssegout(ssegout)
    );
    
endmodule
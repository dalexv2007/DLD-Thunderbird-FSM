// sevseg_decoder.sv
// Maps FSM state values to seven segment display patterns

module sevseg_decoder (
    input logic CLK,
    input logic [7:0] data_in,      // 8-bit STATE from FSM
    output logic [3:0] sseg_an,     // Anode control (active-low)
    output logic [7:0] ssegout      // Segment output [a b c d e f g dp]
);

    logic [3:0] sseg_digit;
    logic [1:0] counter;
    
    // Divide clock for multiplexing (use slower clock for visible display)
    logic [19:0] clk_divider;
    always_ff @(posedge CLK) begin
        clk_divider <= clk_divider + 1;
    end
    
    // Update display at ~1kHz
    always_ff @(posedge clk_divider[11]) begin
        counter <= counter + 1;
    end
    
    // Map FSM state to display character
    always_comb begin
        case (data_in)
            8'h10: sseg_digit = 4'hA;  // L
            8'h20: sseg_digit = 4'hB;  // R
            8'h0C: sseg_digit = 4'hC;  // b
            8'h0D: sseg_digit = 4'hD;  // H
            default: sseg_digit = 4'hF; // blank
        endcase

        case (counter)
            2'b00:  sseg_an = 4'b1110;  // rightmost display on
            default: sseg_an = 4'b1111; // all off
        endcase
    end
    
    // Convert to seven segment
    sevenseg_hex u_sseg (
        .hex(sseg_digit),
        .dp_in(1'b1),      // DP OFF (active-low)
        .ssegout(ssegout)
    );

endmodule

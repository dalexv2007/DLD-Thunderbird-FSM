// sevseg_decoder.sv
// Multiplexes and displays a 4-digit value on seven segment displays

module sevseg_decoder (
    input logic CLK,
    input logic [7:0] data_in,      // 8-bit data to display (shown as 2 hex digits); = STATE
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
    
    // Select which digit to display
    always_comb begin
        case (counter)
            2'b00: begin
                sseg_digit = data_in[3:0];    // Low nibble
                sseg_an = 4'b1110;            // Enable display 0
            end
            2'b01: begin
                sseg_digit = data_in[7:4];    // High nibble
                sseg_an = 4'b1101;            // Enable display 1
            end
            default: begin
                sseg_digit = 4'h0;
                sseg_an = 4'b1111;            // All displays off
            end
        endcase
    end
    
    // Convert to seven segment
    sevenseg_hex u_sseg (
        .hex(sseg_digit),
        .dp_in(1'b1),      // DP OFF (active-low)
        .ssegout(ssegout)
    );

endmodule

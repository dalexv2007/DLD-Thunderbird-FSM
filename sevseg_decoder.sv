// sevseg_decoder.sv
// Maps FSM state values to seven segment display patterns

module sevseg_decoder (
    input logic [2:0] data_in,      // known STATE value 0-4
    output logic [7:0] ssegout      // formatted output to display
); 
    
    // Map FSM state to display character in one comb block
    always_comb begin
        case (data_in)
            3'd0: ssegout = 8'b11111111;  // IDLE = OFF 
            3'd1: ssegout = 8'b11100011;  // LEFT  = L
            3'd2: ssegout = 8'b11110101;  // RIGHT = r
            3'd3: ssegout = 8'b11000001;  // BRAKE = b
            3'd4: ssegout = 8'b10010001;  // HAZARD = H

            default: ssegout = 8'b00000000; // default blank
        endcase
    end

endmodule

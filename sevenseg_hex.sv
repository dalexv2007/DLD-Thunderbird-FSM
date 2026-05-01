// sevenseg_hex.sv
// ssegout[7:0] = [a b c d e f g dp]  (active-LOW)
// Handles hex digits 0-9 and special codes A-F for FSM state letters

module sevenseg_hex (
    input  logic [3:0] hex, //what char to show
    input  logic dp_in,     // 0 = dp ON, 1 = dp OFF (active-low)
    output logic [7:0] ssegout //out to ssgeg display
);
    logic [6:0] seg; // [a b c d e f g] active-low

    always_comb begin
        case (hex)
            // Standard hex digits
            4'h0: seg = 7'b0000001;  // 0
            4'h1: seg = 7'b1001111;  // 1
            4'h2: seg = 7'b0010010;  // 2
            4'h3: seg = 7'b0000110;  // 3
            4'h4: seg = 7'b1001100;  // 4
            4'h5: seg = 7'b0100100;  // 5
            4'h6: seg = 7'b0100000;  // 6
            4'h7: seg = 7'b0001111;  // 7
            4'h8: seg = 7'b0000000;  // 8
            4'h9: seg = 7'b0000100;  // 9
            
            // Special codes for FSM state letters
            4'hA: seg = 7'b1100001;  // 'L' - segments: d e f (left bottom)
            4'hB: seg = 7'b1010111;  // 'R' - segments: a b c e f g (right side + top/middle)
            4'hC: seg = 7'b1100000;  // 'b' - segments: c d e f (bottom right)
            4'hD: seg = 7'b1001000;  // 'H' - segments: b c e f g (right + middle)
            4'hE: seg = 7'b0110000;  // 'E' (if needed)
            4'hF: seg = 7'b1111111;  // Blank/all off (for IDLE state)
            
            default: seg = 7'b1111111; // All segments off
        endcase
    end

    // Pack as [a b c d e f g dp]
    always_comb begin
        ssegout[7:1] = seg;
        ssegout[0]   = dp_in;
    end
endmodule
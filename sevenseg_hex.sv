// sevenseg_hex.sv
// ssegout[7:0] = [a b c d e f g dp]  (active-LOW)

module sevenseg_hex (
    input  logic [3:0] hex,
    input  logic       dp_in,     // 0 = dp ON, 1 = dp OFF (active-low)
    output logic [7:0] ssegout
);
    logic [6:0] seg; // [a b c d e f g] active-low

    always_comb begin
        case (hex)
            4'h0: seg = 7'b0000001;
            4'h1: seg = 7'b1001111;
            4'h2: seg = 7'b0010010;
            4'h3: seg = 7'b0000110;
            4'h4: seg = 7'b1001100;
            4'h5: seg = 7'b0100100;
            4'h6: seg = 7'b0100000;
            4'h7: seg = 7'b0001111;
            4'h8: seg = 7'b0000000;
            4'h9: seg = 7'b0000100;
            4'hA: seg = 7'b0001000;
            4'hB: seg = 7'b1100000;
            4'hC: seg = 7'b0110001;
            4'hD: seg = 7'b1000010;
            4'hE: seg = 7'b0110000;
            4'hF: seg = 7'b0111000;
            default: seg = 7'b1111111;
        endcase
    end

    // Pack as [a b c d e f g dp]
    always_comb begin
        ssegout[7:1] = seg;
        ssegout[0]   = dp_in;
    end
endmodule
module thunderbird_FSM ( //comments represent sevseg display of state. Additional state "H" for hazard state (= L+R together)
    input logic BRAKE, // represented as "b"
    input logic RIGHT, // "R"
    input logic LEFT, // "L"
    input logic RESET, 
    input logic CLK,
    output logic [5:0] LIGHTS,
    output logic [7:0] STATE
);

    typedef enum logic [7:0] {
        IDLE = 8'hFF,  // Idle state (all lights off)
        LA = 8'h10,     // Left turn: LA ON
        LB = 8'h11,     // Left turn: LA + LB ON
        LC = 8'h12,     // Left turn: LA + LB + LC ON
        RA = 8'h20,     // Right turn: RA ON
        RB = 8'h21,     // Right turn: RA + RB ON
        RC = 8'h22,     // Right turn: RA + RB + RC ON
        B = 8'h0C,      // Brake: all lights ON
        H = 8'h0D       // Hazard: LA + RA ON
    } state_t;
    
    state_t current_state, next_state;
    
    // State register
    always_ff @(posedge CLK) begin
        if (RESET) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end
    
    // Output logic
    assign STATE = current_state;
    
    // LIGHTS output: [5:0] = [LC LB LA RA RB RC]
    // Active HIGH: 1 = LED ON
    always_comb begin
        case (current_state)
            LA: LIGHTS = 6'b001000;     // LA ON (left arrow start)
            LB: LIGHTS = 6'b011000;     // LA + LB ON
            LC: LIGHTS = 6'b111000;     // LA + LB + LC ON (full left turn)
            RA: LIGHTS = 6'b000100;     // RA ON (right arrow start)
            RB: LIGHTS = 6'b000110;     // RA + RB ON
            RC: LIGHTS = 6'b000111;     // RA + RB + RC ON (full right turn)
            B: LIGHTS = 6'b111111;      // All lights ON (brake)
            H: LIGHTS = 6'b001100;      // LA and RA ON (hazard)
            IDLE: LIGHTS = 6'b000000;   // All lights OFF
            default: LIGHTS = 6'b000000;
        endcase
    end
    
    // State transition logic
    always_comb begin
        case (current_state)
            IDLE: begin
                if (RESET) next_state = IDLE;
                else if (BRAKE) next_state = B;
                else if (LEFT && RIGHT) next_state = H;
                else if (LEFT) next_state = LA;      // Start left turn sequence
                else if (RIGHT) next_state = RA;     // Start right turn sequence
                else next_state = IDLE;
            end
            
            // Left turn sequence
            LA: begin
                if (RESET) next_state = IDLE;
                else if (BRAKE) next_state = B;
                else if (LEFT && RIGHT) next_state = H;
                else next_state = LB;  // Advance to LB
            end
            
            LB: begin
                if (RESET) next_state = IDLE;
                else if (BRAKE) next_state = B;
                else if (LEFT && RIGHT) next_state = H;
                else next_state = LC;  // Advance to LC
            end
            
            LC: begin
                if (RESET) next_state = IDLE;
                else if (BRAKE) next_state = B;
                else if (LEFT && RIGHT) next_state = H;
                else if (LEFT) next_state = LA;
                else next_state = IDLE;  // restart to LA if LEFT still pressed, otherwise go to IDLE if LEFT released
            end
            
            // Right turn sequence
            RA: begin
                if (RESET) next_state = IDLE;
                else if (BRAKE) next_state = B;
                else if (LEFT && RIGHT) next_state = H;
                else next_state = RB;  // Advance to RB
            end
            
            RB: begin
                if (RESET) next_state = IDLE;
                else if (BRAKE) next_state = B;
                else if (LEFT && RIGHT) next_state = H;
                else next_state = RC;  // Advance to RC
            end
            
            RC: begin
                if (RESET) next_state = IDLE;
                else if (BRAKE) next_state = B;
                else if (LEFT && RIGHT) next_state = H;
                else if (RIGHT) next_state = RA;
                else next_state = IDLE;  // restart to RA if RIGHT still pressed, otherwise go to IDLE if RIGHT released
            end
            
            B: begin  // Brake state
                if (RESET) next_state = IDLE;
                else if (!BRAKE) begin // Return to previous turn state or IDLE
                    if (LEFT && RIGHT) next_state = H;
                    else if (LEFT) next_state = LA;    // begin L/R turns if pressed
                    else if (RIGHT) next_state = RA;
                    else next_state = IDLE;
                end 
                else next_state = B;
            end
            
            H: begin  // Hazard state
                if (RESET) next_state = IDLE;
                else if (BRAKE) next_state = B;
                else if (!(LEFT && RIGHT)) begin //if both not pressed...
                    if (LEFT && !RIGHT) next_state = LA; //enter LA if left only
                    else if (!LEFT && RIGHT) next_state = RA; //enter RA if right only
                    else next_state = IDLE; //otherwise back to IDLE
                end 
                else next_state = H; //if both still pressed, stay in H
            end
            
            default: next_state = IDLE;
        endcase
    end

endmodule
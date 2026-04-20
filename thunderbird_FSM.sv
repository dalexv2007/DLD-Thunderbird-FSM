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
        L = 8'h0A, // L
        R = 8'h0B, // R
        B = 8'h0C, // b (brake)
        H = 8'h0D, // H (hazard)
        IDLE = 8'hFF // Idle state (all lights off)
    } state_t;
    
    state_t current_state, next_state;
    
    // State transition logic
    always_comb begin
        case (current_state)
            IDLE: begin
                if (RESET) next_state = IDLE;
                else if (LEFT && RIGHT) next_state = H; // Hazard if both L and R are pressed
                else if (LEFT) next_state = L;
                else if (RIGHT) next_state = R;
                else if (BRAKE) next_state = B;
                else next_state = IDLE;
            end
            
            L: begin
                if (RESET) next_state = IDLE;
                else if (LEFT && RIGHT) next_state = H;
                else if (!LEFT) next_state = IDLE;
                else next_state = L;
            end
            
            R: begin
                if (RESET) next_state = IDLE;
                else if (LEFT && RIGHT) next_state = H; 
                else if (!RIGHT) next_state = IDLE; 
                else next_state = R; 
            end
            
            B: begin
                if (RESET) next_state = IDLE;
                else if (!BRAKE) next_state = IDLE; 
                else next_state = B; 
            end
            
            H: begin
                if (RESET) next_state = IDLE;
                else if (!LEFT && !RIGHT) next_state = IDLE; 
                else next_state = H; 
            end
        endcase
    end

endmodule
module thunderbird_FSM ( 
    input logic BRAKE, //project inputs, treated as bools where true = 1 = pressed.
    input logic RIGHT, 
    input logic LEFT,
    input logic RESET, 
    input logic CLK,
    output logic [5:0] LIGHTS,
    output logic [7:0] STATE
);

    typedef enum logic [2:0] { //main states
        S_IDLE,
        S_LEFT,
        S_RIGHT,
        S_BRAKE, 
        S_HAZARD
    } state_t;

    state_t current_state, next_state;

    typedef enum logic [3:0] { //substates type. Not containers, just trackers.
        ID,
        LA, LB, LC,
        RA, RB, RC,
        HA, HB, HC,
        B
    } substate_t;
    
    substate_t current_lights, next_lights;
    
    // functions to +1 light sequence for left and right turns (and HAZARD)
    function substate_t next_left_light(substate_t current); //use: next = func(current) sends back next
        case (current)
            LA: return LB;
            LB: return LC;
            default: return LA; //shouldn't reach here, func caller need to just not be stupid. handles errors ig
        endcase
    endfunction
    
    // Function to advance RIGHT light sequence
    function substate_t next_right_light(substate_t current);
        case (current)
            RA: return RB;
            RB: return RC;
            default: return RA; // this is fine, unexpected behavior defaults to simple handling. 
        endcase
    endfunction

    function substate_t next_hazard_light(substate_t current); // S_HAZARD increment
        case (current)
            HA: return HB;
            HB: return HC;
            HC: return HA;
            default: return HA; // this is fine, unexpected behavior defaults to simple handling. 
        endcase
    endfunction

    // register to update state and lights on each cycle
    always_ff @(posedge CLK) begin //on every clock edge update state and lights
        if (RESET) begin
            current_state <= S_IDLE;
            current_lights <= ID;
        end 
        else begin
            current_state <= next_state; //send next state to register to use on next cycle
            current_lights <= next_lights;
        end
    end
    
    // Output logic:

    always_comb begin // switch sets STATE output based on current state
        case(current_state)
            S_IDLE: STATE = 8'hFF; // blank
            S_LEFT: STATE = 8'h10; // L
            S_RIGHT: STATE = 8'h20; // R
            S_BRAKE: STATE = 8'h0C; // b
            S_HAZARD: STATE = 8'h0D; // H
            default: STATE = 8'hFF;
        endcase
    end
    
    always_comb begin
        case (current_lights) // switch sets LED outputs by assigning LIGHT value based on substate current_lights.
            LA: LIGHTS = 6'b001000;
            LB: LIGHTS = 6'b011000;
            LC: LIGHTS = 6'b111000;
            RA: LIGHTS = 6'b000100;
            RB: LIGHTS = 6'b000110;   
            RC: LIGHTS = 6'b000111;
            HA: LIGHTS = 6'b001100;
            HB: LIGHTS = 6'b011110;
            HC: LIGHTS = 6'b111111;     
            B: LIGHTS = 6'b111111;      
            ID: LIGHTS = 6'b000000; 
            default: LIGHTS = 6'b000000;
        endcase
    end

    // State transition logic: here's my main FSM
    always_comb begin // for any state, being in that state = lights are already set, as when next_state is set next_lights is set with it (can i optimize)?
        case (current_state) // = "for whatever button pressed, do this," where button pressed corresponding state_t = true
            S_IDLE: begin // only case with no button input except reset.
                next_state = S_IDLE; //substate logic runs default values at top
                next_lights = ID; // all lights initialized from the case it's coming from.

                if (BRAKE) begin //ifs pretty self explanatory, if (input) -> set that state for next cycle
                    next_state = S_BRAKE;
                    next_lights = B; //also initialize lights for the state
                end 
                else if (LEFT && RIGHT) begin
                    next_state = S_HAZARD;
                    next_lights = HA;
                end 
                else if (LEFT) begin
                    next_state = S_LEFT;
                    next_lights = LA;
                end 
                else if (RIGHT) begin
                    next_state = S_RIGHT;
                    next_lights = RA;
                end
            end
            
            S_LEFT: begin //left sequence, lights should be initialized from wherever it came from
                next_state = S_LEFT;
                next_lights = current_lights; //default to current lights, overwritten in nested logic

                if (BRAKE) begin
                    next_state = S_BRAKE;
                    next_lights = B;
                end else if (LEFT && RIGHT) begin 
                    next_state = S_HAZARD;
                    next_lights = HA;
                end else if (current_lights == LC) begin //won't repeat because LC is an exit condition
                    next_state = S_IDLE;
                    next_lights = ID;
                end //end exit conditions

                else begin //if no exit condition hit, move to next L sequence state
                    next_state = S_LEFT; //reinforces S_LEFT so it'll stay in S_LEFT no matter what unless exit condition hit. should exit S_LEFT upon hitting LC though.
                    next_lights = next_left_light(current_lights); //technically will never receive LC input, if it did func would default to LA and reset seq
                end
            end
            
            S_RIGHT: begin
                next_state = S_RIGHT;
                next_lights = current_lights;

                if (BRAKE) begin
                    next_state = S_BRAKE;
                    next_lights = B;
                end else if (LEFT && RIGHT) begin
                    next_state = S_HAZARD;
                    next_lights = HA;
                end else if (current_lights == RC) begin
                    next_state = S_IDLE;
                    next_lights = ID;
                end  //end exit conditions

                else begin
                    next_state = S_RIGHT;
                    next_lights = next_right_light(current_lights); //call nextlight func
                end
            end
            
            S_BRAKE: begin
                next_state = S_BRAKE;
                next_lights = B;

                if (!BRAKE) begin //only exit condition = when released, find out where to go next or default to S_IDLE.
                    if (LEFT && RIGHT) begin
                        next_state = S_HAZARD;
                        next_lights = HA;
                    end else if (LEFT) begin
                        next_state = S_LEFT;
                        next_lights = LA;
                    end else if (RIGHT) begin
                        next_state = S_RIGHT;
                        next_lights = RA;

                    end else begin //default to S_IDLE
                        next_state = S_IDLE;
                        next_lights = ID;
                    end
                end
            end
            
            S_HAZARD: begin
                next_state = S_HAZARD;
                next_lights = next_hazard_light(current_lights); //default increment logic

                if (BRAKE) begin //only exit condition
                    next_state = S_BRAKE;
                    next_lights = B;
                end
            end
            
            default: begin //naturally default main FSM to S_IDLE.
                next_state = S_IDLE;
                next_lights = ID;
            end
        endcase
    end

endmodule
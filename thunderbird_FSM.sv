module thunderbird_FSM (
    input wire clk,
    input wire rst_n,
    input wire start,
    output reg [2:0] state
);

    typedef enum logic [2:0] {
        IDLE = 3'b000,
        LOAD = 3'b001,
        PROCESS = 3'b010,
        DONE = 3'b011
    } state_t;

    state_t current_state, next_state;

    // State transition logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // Next state logic
    always_comb begin
        case (current_state)
            IDLE: begin
                if (start) begin
                    next_state = LOAD;
                end else begin
                    next_state = IDLE;
                end
            end
            LOAD: begin
                next_state = PROCESS;
            end
            PROCESS: begin
                next_state = DONE;
            end
            DONE: begin
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end

    // Output logic
    always_comb begin
        state = current_state;
    end
endmodule
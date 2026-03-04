// ============================================================================
// ELEVATOR CONTROLLER - FINITE STATE MACHINE
// ============================================================================
// File: elevator_controller.v
// Purpose: 5-state FSM for 3-floor elevator control
// Author: Digital Design Project
// Date: March 2026
//
// Description:
//   Implements Moore-type finite state machine with 5 states:
//   - FLOOR_1 (Ground floor)
//   - MOVING_UP (Ascending)
//   - FLOOR_2 (First floor)
//   - MOVING_DOWN (Descending)
//   - FLOOR_3 (Top floor)
//
// ============================================================================

module elevator_controller (
    // Clock and Reset
    input wire clk,              // System clock
    input wire rst,              // Active-high synchronous reset
    
    // Floor Call Inputs
    input wire call_f1,          // Floor 1 call button
    input wire call_f2,          // Floor 2 call button
    input wire call_f3,          // Floor 3 call button
    
    // Control Inputs from Priority Logic
    input wire [1:0] target_floor,  // Target floor from priority logic (0-3)
    
    // Motor Control Outputs
    output reg motor_up,         // Motor upward control
    output reg motor_down,       // Motor downward control
    
    // Status Outputs
    output reg [1:0] current_floor,  // Current floor indicator [1:0]
    output reg [2:0] current_state_out  // Current state for debugging
);

// ============================================================================
// STATE ENCODING
// ============================================================================
localparam [2:0] FLOOR_1     = 3'b000;  // At ground floor
localparam [2:0] MOVING_UP   = 3'b001;  // Traveling upward
localparam [2:0] FLOOR_2     = 3'b010;  // At first floor
localparam [2:0] MOVING_DOWN = 3'b011;  // Traveling downward
localparam [2:0] FLOOR_3     = 3'b100;  // At top floor

// ============================================================================
// PARAMETERS
// ============================================================================
parameter CLOCK_FREQ = 50_000_000;       // 50 MHz system clock
parameter FLOOR_TRAVEL_TIME = 3;         // Seconds to travel one floor
parameter DOOR_OPEN_TIME = 2;            // Seconds for door operation

// Calculate counter values
localparam TRAVEL_CYCLES = CLOCK_FREQ * FLOOR_TRAVEL_TIME;
localparam DOOR_CYCLES = CLOCK_FREQ * DOOR_OPEN_TIME;

// ============================================================================
// INTERNAL REGISTERS AND SIGNALS
// ============================================================================
reg [2:0] current_state, next_state;
reg [31:0] travel_counter;       // Counter for floor travel timing
reg [31:0] door_counter;         // Counter for door operation timing
reg [1:0] current_floor_reg;     // Internal floor register

// ============================================================================
// STATE REGISTER (Sequential Logic)
// ============================================================================
always @(posedge clk) begin
    if (rst) begin
        current_state <= FLOOR_1;
        current_floor_reg <= 2'b00;  // Start at floor 1
        travel_counter <= 0;
        door_counter <= 0;
    end else begin
        current_state <= next_state;
        
        // Update timers
        if (travel_counter > 0)
            travel_counter <= travel_counter - 1;
        
        if (door_counter > 0)
            door_counter <= door_counter - 1;
        
        // Update floor register when transitioning to floor states
        case (next_state)
            FLOOR_1: current_floor_reg <= 2'b00;
            FLOOR_2: current_floor_reg <= 2'b01;
            FLOOR_3: current_floor_reg <= 2'b10;
            default: current_floor_reg <= current_floor_reg;  // Hold
        endcase
    end
end

// ============================================================================
// NEXT STATE LOGIC (Combinational Logic)
// ============================================================================
always @(*) begin
    // Default: stay in current state
    next_state = current_state;
    
    case (current_state)
        
        // ====================================================================
        // FLOOR_1: Elevator at ground floor
        // ====================================================================
        FLOOR_1: begin
            if (door_counter == 0) begin
                // Doors closed, check for calls
                if (target_floor == 2'b01 || target_floor == 2'b10) begin
                    // Need to go up to floor 2 or 3
                    next_state = MOVING_UP;
                end else begin
                    next_state = FLOOR_1;  // Stay idle
                end
            end else begin
                next_state = FLOOR_1;  // Wait for doors
            end
        end
        
        // ====================================================================
        // MOVING_UP: Elevator ascending
        // ====================================================================
        MOVING_UP: begin
            if (travel_counter == 0) begin
                // Reached destination
                if (target_floor == 2'b01) begin
                    // Going to floor 2
                    next_state = FLOOR_2;
                end else if (target_floor == 2'b10 && current_floor_reg == 2'b00) begin
                    // Going to floor 3, currently passing through from floor 1
                    next_state = FLOOR_2;  // Stop at floor 2 first
                end else begin
                    // Reached floor 3
                    next_state = FLOOR_3;
                end
            end else begin
                next_state = MOVING_UP;  // Continue traveling
            end
        end
        
        // ====================================================================
        // FLOOR_2: Elevator at first floor
        // ====================================================================
        FLOOR_2: begin
            if (door_counter == 0) begin
                // Doors closed, check for calls
                if (target_floor == 2'b10) begin
                    // Need to go up to floor 3
                    next_state = MOVING_UP;
                end else if (target_floor == 2'b00) begin
                    // Need to go down to floor 1
                    next_state = MOVING_DOWN;
                end else begin
                    next_state = FLOOR_2;  // Stay idle
                end
            end else begin
                next_state = FLOOR_2;  // Wait for doors
            end
        end
        
        // ====================================================================
        // MOVING_DOWN: Elevator descending
        // ====================================================================
        MOVING_DOWN: begin
            if (travel_counter == 0) begin
                // Reached destination
                if (target_floor == 2'b01) begin
                    // Going to floor 2
                    next_state = FLOOR_2;
                end else if (target_floor == 2'b00 && current_floor_reg == 2'b10) begin
                    // Going to floor 1, currently passing through from floor 3
                    next_state = FLOOR_2;  // Stop at floor 2 first
                end else begin
                    // Reached floor 1
                    next_state = FLOOR_1;
                end
            end else begin
                next_state = MOVING_DOWN;  // Continue traveling
            end
        end
        
        // ====================================================================
        // FLOOR_3: Elevator at top floor
        // ====================================================================
        FLOOR_3: begin
            if (door_counter == 0) begin
                // Doors closed, check for calls
                if (target_floor == 2'b01 || target_floor == 2'b00) begin
                    // Need to go down to floor 2 or 1
                    next_state = MOVING_DOWN;
                end else begin
                    next_state = FLOOR_3;  // Stay idle
                end
            end else begin
                next_state = FLOOR_3;  // Wait for doors
            end
        end
        
        // ====================================================================
        // DEFAULT: Safety catch for invalid states
        // ====================================================================
        default: begin
            next_state = FLOOR_1;  // Reset to safe state
        end
        
    endcase
end

// ============================================================================
// TIMER INITIALIZATION (Combinational Logic)
// ============================================================================
always @(posedge clk) begin
    if (rst) begin
        travel_counter <= 0;
        door_counter <= 0;
    end else begin
        // Initialize travel counter when entering movement state
        if (current_state != next_state) begin
            case (next_state)
                MOVING_UP, MOVING_DOWN: begin
                    travel_counter <= TRAVEL_CYCLES;
                end
                FLOOR_1, FLOOR_2, FLOOR_3: begin
                    door_counter <= DOOR_CYCLES;
                end
            endcase
        end
    end
end

// ============================================================================
// OUTPUT LOGIC (Combinational Logic)
// ============================================================================
always @(*) begin
    // Default outputs
    motor_up = 1'b0;
    motor_down = 1'b0;
    current_floor = current_floor_reg;
    
    case (current_state)
        FLOOR_1: begin
            motor_up = 1'b0;
            motor_down = 1'b0;
            current_floor = 2'b00;
        end
        
        MOVING_UP: begin
            motor_up = 1'b1;
            motor_down = 1'b0;
            current_floor = current_floor_reg;  // Hold last floor
        end
        
        FLOOR_2: begin
            motor_up = 1'b0;
            motor_down = 1'b0;
            current_floor = 2'b01;
        end
        
        MOVING_DOWN: begin
            motor_up = 1'b0;
            motor_down = 1'b1;
            current_floor = current_floor_reg;  // Hold last floor
        end
        
        FLOOR_3: begin
            motor_up = 1'b0;
            motor_down = 1'b0;
            current_floor = 2'b10;
        end
        
        default: begin
            motor_up = 1'b0;
            motor_down = 1'b0;
            current_floor = 2'b00;
        end
    endcase
end

// Output current state for debugging
assign current_state_out = current_state;

// ============================================================================
// SAFETY ASSERTIONS (for simulation)
// ============================================================================
// synthesis translate_off
always @(posedge clk) begin
    if (!rst) begin
        // Check for shoot-through condition
        if (motor_up && motor_down) begin
            $display("ERROR: Shoot-through detected! Both motor_up and motor_down are HIGH.");
            $stop;
        end
    end
end
// synthesis translate_on

endmodule

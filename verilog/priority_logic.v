// ============================================================================
// PRIORITY LOGIC MODULE
// ============================================================================
// File: priority_logic.v
// Purpose: Implements priority scheduling for elevator call processing
// Author: Digital Design Project
// Date: March 2026
//
// Description:
//   Determines next target floor based on:
//   - Current elevator position
//   - Current direction of movement
//   - Pending floor call requests
//
// Priority Rules:
//   - Moving UP: Serve higher floors first (ascending order)
//   - Moving DOWN: Serve lower floors first (descending order)
//   - IDLE: Serve nearest floor (ties broken by lower floor)
//
// ============================================================================

module priority_logic (
    // Clock and Reset
    input wire clk,              // System clock
    input wire rst,              // Active-high synchronous reset
    
    // Floor Call Inputs
    input wire call_f1,          // Floor 1 call button
    input wire call_f2,          // Floor 2 call button
    input wire call_f3,          // Floor 3 call button
    
    // Current Status Inputs
    input wire [1:0] current_floor,   // Current floor (0=F1, 1=F2, 2=F3)
    input wire [2:0] current_state,   // Current FSM state
    
    // Outputs
    output reg [1:0] target_floor,    // Next target floor (0=none, 1=F2, 2=F3)
    output reg direction              // Direction: 0=down/idle, 1=up
);

// ============================================================================
// STATE ENCODING (must match elevator_controller.v)
// ============================================================================
localparam [2:0] FLOOR_1     = 3'b000;
localparam [2:0] MOVING_UP   = 3'b001;
localparam [2:0] FLOOR_2     = 3'b010;
localparam [2:0] MOVING_DOWN = 3'b011;
localparam [2:0] FLOOR_3     = 3'b100;

// ============================================================================
// INTERNAL REGISTERS
// ============================================================================
reg [2:0] request_queue;     // Latched floor requests [F3, F2, F1]
reg [1:0] current_floor_reg;

// ============================================================================
// REQUEST QUEUE MANAGEMENT (Sequential Logic)
// ============================================================================
always @(posedge clk) begin
    if (rst) begin
        request_queue <= 3'b000;
    end else begin
        // Latch button presses
        if (call_f1)
            request_queue[0] <= 1'b1;
        if (call_f2)
            request_queue[1] <= 1'b1;
        if (call_f3)
            request_queue[2] <= 1'b1;
        
        // Clear request when elevator reaches that floor
        case (current_state)
            FLOOR_1: request_queue[0] <= 1'b0;
            FLOOR_2: request_queue[1] <= 1'b0;
            FLOOR_3: request_queue[2] <= 1'b0;
            default: request_queue <= request_queue;
        endcase
    end
end

// ============================================================================
// PRIORITY SCHEDULING LOGIC (Combinational Logic)
// ============================================================================
always @(*) begin
    // Default outputs
    target_floor = 2'b00;
    direction = 1'b0;
    
    // Determine current direction based on state
    case (current_state)
        MOVING_UP: direction = 1'b1;      // Moving up
        MOVING_DOWN: direction = 1'b0;    // Moving down
        default: direction = 1'b0;        // Idle (treat as down for tie-breaking)
    endcase
    
    // Priority logic based on current floor and direction
    case (current_floor)
        
        // ====================================================================
        // AT FLOOR 1 (Ground)
        // ====================================================================
        2'b00: begin
            // Can only move up or stay
            if (request_queue[1]) begin
                // Floor 2 called
                target_floor = 2'b01;
                direction = 1'b1;
            end else if (request_queue[2]) begin
                // Floor 3 called (no floor 2)
                target_floor = 2'b10;
                direction = 1'b1;
            end else begin
                // No calls
                target_floor = 2'b00;
                direction = 1'b0;
            end
        end
        
        // ====================================================================
        // AT FLOOR 2 (Middle)
        // ====================================================================
        2'b01: begin
            // Can move up or down
            case ({current_state, direction})
                
                // Moving UP or IDLE with upward tendency
                {MOVING_UP, 1'b1}, {FLOOR_2, 1'b1}: begin
                    if (request_queue[2]) begin
                        // Floor 3 called - continue up
                        target_floor = 2'b10;
                        direction = 1'b1;
                    end else if (request_queue[0]) begin
                        // Only floor 1 called - reverse direction
                        target_floor = 2'b00;
                        direction = 1'b0;
                    end else begin
                        // No calls
                        target_floor = 2'b00;
                        direction = 1'b0;
                    end
                end
                
                // Moving DOWN or IDLE with downward tendency
                {MOVING_DOWN, 1'b0}, {FLOOR_2, 1'b0}: begin
                    if (request_queue[0]) begin
                        // Floor 1 called - continue down
                        target_floor = 2'b00;
                        direction = 1'b0;
                    end else if (request_queue[2]) begin
                        // Only floor 3 called - reverse direction
                        target_floor = 2'b10;
                        direction = 1'b1;
                    end else begin
                        // No calls
                        target_floor = 2'b00;
                        direction = 1'b0;
                    end
                end
                
                // Default: prioritize based on nearest floor
                default: begin
                    if (request_queue[2] && request_queue[0]) begin
                        // Both F1 and F3 called - choose based on distance (equal)
                        // Tie-breaker: go down first (lower floor)
                        target_floor = 2'b00;
                        direction = 1'b0;
                    end else if (request_queue[2]) begin
                        // Only F3 called
                        target_floor = 2'b10;
                        direction = 1'b1;
                    end else if (request_queue[0]) begin
                        // Only F1 called
                        target_floor = 2'b00;
                        direction = 1'b0;
                    end else begin
                        // No calls
                        target_floor = 2'b00;
                        direction = 1'b0;
                    end
                end
            endcase
        end
        
        // ====================================================================
        // AT FLOOR 3 (Top)
        // ====================================================================
        2'b10: begin
            // Can only move down or stay
            if (request_queue[1]) begin
                // Floor 2 called
                target_floor = 2'b01;
                direction = 1'b0;
            end else if (request_queue[0]) begin
                // Floor 1 called (no floor 2)
                target_floor = 2'b00;
                direction = 1'b0;
            end else begin
                // No calls
                target_floor = 2'b00;
                direction = 1'b0;
            end
        end
        
        // ====================================================================
        // DEFAULT (Invalid floor)
        // ====================================================================
        default: begin
            target_floor = 2'b00;
            direction = 1'b0;
        end
    endcase
end

// ============================================================================
// DEBUG OUTPUT (for simulation/testbench)
// ============================================================================
// synthesis translate_off
always @(posedge clk) begin
    if (!rst) begin
        $display("[Priority] Time: %0t | Floor: %0d | Requests: [F1=%b F2=%b F3=%b] | Target: %0d | Dir: %s",
                 $time, current_floor + 1, request_queue[0], request_queue[1], request_queue[2],
                 target_floor, direction ? "UP" : "DOWN");
    end
end
// synthesis translate_on

endmodule

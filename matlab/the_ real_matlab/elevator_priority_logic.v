//==============================================================
// Elevator Call Processing - FPGA Priority Logic (Verilog)
// Implements direction-based priority for floor calls
// Author: Elevator Control System
// Date: March 2026
//==============================================================

module elevator_priority_logic (
    input wire clk,                  // System clock
    input wire rst_n,                // Active-low reset
    
    // Floor call buttons (active high)
    input wire floor1_call,          // Call from Floor 1
    input wire floor2_call,          // Call from Floor 2
    input wire floor3_call,          // Call from Floor 3
    
    // Floor sensors (indicates elevator position)
    input wire at_floor1,            // Elevator at Floor 1
    input wire at_floor2,            // Elevator at Floor 2
    input wire at_floor3,            // Elevator at Floor 3
    
    // Current direction input
    input wire [1:0] current_direction, // 00=IDLE, 01=UP, 10=DOWN
    
    // Outputs
    output reg [1:0] target_floor,   // Target floor: 01=F1, 10=F2, 11=F3
    output reg [1:0] motor_direction,// Motor control: 00=STOP, 01=UP, 10=DOWN
    output reg door_open,            // Door control
    output reg call_serviced         // Indicates a call was serviced
);

    //==============================================================
    // State Encoding
    //==============================================================
    localparam STATE_IDLE          = 3'b000;
    localparam STATE_FLOOR_1       = 3'b001;
    localparam STATE_MOVING_UP     = 3'b010;
    localparam STATE_FLOOR_2       = 3'b011;
    localparam STATE_MOVING_DOWN   = 3'b100;
    localparam STATE_FLOOR_3       = 3'b101;
    
    // Direction encoding
    localparam DIR_IDLE = 2'b00;
    localparam DIR_UP   = 2'b01;
    localparam DIR_DOWN = 2'b10;
    
    // Floor encoding
    localparam FLOOR_NONE = 2'b00;
    localparam FLOOR_1    = 2'b01;
    localparam FLOOR_2    = 2'b10;
    localparam FLOOR_3    = 2'b11;

    //==============================================================
    // Internal Registers
    //==============================================================
    reg [2:0] current_state, next_state;
    reg [1:0] saved_direction;       // Last non-idle direction
    reg [2:0] call_queue;            // Registered call queue [F3, F2, F1]
    reg [1:0] current_floor;         // Current floor position
    
    //==============================================================
    // Call Queue Register - Captures and holds floor calls
    //==============================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            call_queue <= 3'b000;
        end else begin
            // Set bits when calls come in
            if (floor1_call) call_queue[0] <= 1'b1;
            if (floor2_call) call_queue[1] <= 1'b1;
            if (floor3_call) call_queue[2] <= 1'b1;
            
            // Clear bits when serviced
            if (call_serviced) begin
                case (current_floor)
                    FLOOR_1: call_queue[0] <= 1'b0;
                    FLOOR_2: call_queue[1] <= 1'b0;
                    FLOOR_3: call_queue[2] <= 1'b0;
                endcase
            end
        end
    end

    //==============================================================
    // Current Floor Detection
    //==============================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_floor <= FLOOR_1;
        end else begin
            if (at_floor1) current_floor <= FLOOR_1;
            else if (at_floor2) current_floor <= FLOOR_2;
            else if (at_floor3) current_floor <= FLOOR_3;
        end
    end

    //==============================================================
    // Priority Logic Function
    // Implements direction-based call servicing:
    // - If moving UP: prioritize higher floor calls
    // - If moving DOWN: prioritize lower floor calls
    // - If IDLE: service closest call
    //==============================================================
    function [1:0] get_priority_target;
        input [2:0] calls;           // Call queue
        input [1:0] floor;           // Current floor
        input [1:0] direction;       // Current direction
        
        reg has_call_above, has_call_below;
        begin
            // Check for calls above current floor
            case (floor)
                FLOOR_1: has_call_above = calls[1] | calls[2]; // F2 or F3
                FLOOR_2: has_call_above = calls[2];            // F3 only
                FLOOR_3: has_call_above = 1'b0;                // None above
                default: has_call_above = 1'b0;
            endcase
            
            // Check for calls below current floor
            case (floor)
                FLOOR_1: has_call_below = 1'b0;                // None below
                FLOOR_2: has_call_below = calls[0];            // F1 only
                FLOOR_3: has_call_below = calls[0] | calls[1]; // F1 or F2
                default: has_call_below = 1'b0;
            endcase
            
            // Priority decision based on direction
            if (direction == DIR_UP && has_call_above) begin
                // Continue UP - find highest call
                if (calls[2]) get_priority_target = FLOOR_3;
                else if (calls[1]) get_priority_target = FLOOR_2;
                else get_priority_target = FLOOR_NONE;
            end
            else if (direction == DIR_DOWN && has_call_below) begin
                // Continue DOWN - find lowest call
                if (calls[0]) get_priority_target = FLOOR_1;
                else if (calls[1]) get_priority_target = FLOOR_2;
                else get_priority_target = FLOOR_NONE;
            end
            else if (has_call_above) begin
                // Go UP - find closest call above
                case (floor)
                    FLOOR_1: begin
                        if (calls[1]) get_priority_target = FLOOR_2;
                        else if (calls[2]) get_priority_target = FLOOR_3;
                        else get_priority_target = FLOOR_NONE;
                    end
                    FLOOR_2: get_priority_target = calls[2] ? FLOOR_3 : FLOOR_NONE;
                    default: get_priority_target = FLOOR_NONE;
                endcase
            end
            else if (has_call_below) begin
                // Go DOWN - find closest call below
                case (floor)
                    FLOOR_3: begin
                        if (calls[1]) get_priority_target = FLOOR_2;
                        else if (calls[0]) get_priority_target = FLOOR_1;
                        else get_priority_target = FLOOR_NONE;
                    end
                    FLOOR_2: get_priority_target = calls[0] ? FLOOR_1 : FLOOR_NONE;
                    default: get_priority_target = FLOOR_NONE;
                endcase
            end
            else begin
                get_priority_target = FLOOR_NONE;
            end
        end
    endfunction

    //==============================================================
    // State Machine - Sequential Logic
    //==============================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= STATE_FLOOR_1;
            saved_direction <= DIR_IDLE;
        end else begin
            current_state <= next_state;
            // Save direction when moving
            if (motor_direction != DIR_IDLE)
                saved_direction <= motor_direction;
        end
    end

    //==============================================================
    // State Machine - Combinational Logic (Next State Decode)
    //==============================================================
    always @(*) begin
        // Default outputs
        next_state = current_state;
        motor_direction = DIR_IDLE;
        door_open = 1'b0;
        call_serviced = 1'b0;
        target_floor = FLOOR_NONE;
        
        case (current_state)
            STATE_FLOOR_1: begin
                door_open = 1'b1;
                call_serviced = call_queue[0]; // Service F1 call if present
                
                // Get priority target
                target_floor = get_priority_target(call_queue, FLOOR_1, saved_direction);
                
                if (target_floor != FLOOR_NONE && target_floor != FLOOR_1) begin
                    next_state = STATE_MOVING_UP;
                end
            end
            
            STATE_MOVING_UP: begin
                motor_direction = DIR_UP;
                door_open = 1'b0;
                
                // Check floor sensors for arrival
                if (at_floor2 && call_queue[1]) begin
                    next_state = STATE_FLOOR_2;
                end
                else if (at_floor3) begin
                    next_state = STATE_FLOOR_3;
                end
            end
            
            STATE_FLOOR_2: begin
                door_open = 1'b1;
                call_serviced = call_queue[1]; // Service F2 call if present
                
                // Get priority target
                target_floor = get_priority_target(call_queue, FLOOR_2, saved_direction);
                
                if (target_floor == FLOOR_3) begin
                    next_state = STATE_MOVING_UP;
                end
                else if (target_floor == FLOOR_1) begin
                    next_state = STATE_MOVING_DOWN;
                end
            end
            
            STATE_MOVING_DOWN: begin
                motor_direction = DIR_DOWN;
                door_open = 1'b0;
                
                // Check floor sensors for arrival
                if (at_floor2 && call_queue[1]) begin
                    next_state = STATE_FLOOR_2;
                end
                else if (at_floor1) begin
                    next_state = STATE_FLOOR_1;
                end
            end
            
            STATE_FLOOR_3: begin
                door_open = 1'b1;
                call_serviced = call_queue[2]; // Service F3 call if present
                
                // Get priority target
                target_floor = get_priority_target(call_queue, FLOOR_3, saved_direction);
                
                if (target_floor != FLOOR_NONE && target_floor != FLOOR_3) begin
                    next_state = STATE_MOVING_DOWN;
                end
            end
            
            default: begin
                next_state = STATE_FLOOR_1;
            end
        endcase
    end

endmodule

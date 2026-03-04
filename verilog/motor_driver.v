// ============================================================================
// MOTOR DRIVER MODULE (H-BRIDGE INTERFACE)
// ============================================================================
// File: motor_driver.v
// Purpose: Interfaces between FSM and H-Bridge motor driver
// Author: Digital Design Project
// Date: March 2026
//
// Description:
//   Provides safe interfacing to H-Bridge motor driver with:
//   - Shoot-through prevention
//   - Deadtime insertion
//   - PWM speed control (optional)
//   - Status monitoring
//
// H-Bridge Truth Table:
//   motor_up | motor_down | IN1 | IN2 | Motor State
//   ---------|------------|-----|-----|-------------
//      0     |     0      |  0  |  0  | STOP/COAST
//      1     |     0      |  1  |  0  | FORWARD (UP)
//      0     |     1      |  0  |  1  | REVERSE (DOWN)
//      1     |     1      | ERR | ERR | INVALID (prevented)
//
// ============================================================================

module motor_driver (
    // Clock and Reset
    input wire clk,              // System clock
    input wire rst,              // Active-high synchronous reset
    
    // Control Inputs from FSM
    input wire motor_up,         // Command to move up
    input wire motor_down,       // Command to move down
    input wire enable,           // Motor enable signal
    
    // H-Bridge Driver Outputs
    output reg h_bridge_in1,     // H-Bridge input 1 (UP control)
    output reg h_bridge_in2,     // H-Bridge input 2 (DOWN control)
    
    // Status Outputs
    output reg motor_active,     // Motor is running
    output reg fault             // Fault condition detected
);

// ============================================================================
// PARAMETERS
// ============================================================================
parameter CLOCK_FREQ = 50_000_000;       // 50 MHz
parameter DEADTIME_US = 2;               // Deadtime in microseconds
localparam DEADTIME_CYCLES = (CLOCK_FREQ / 1_000_000) * DEADTIME_US;

// ============================================================================
// INTERNAL SIGNALS
// ============================================================================
reg [7:0] deadtime_counter;      // Deadtime counter
reg motor_enable_internal;       // Internal enable after deadtime
reg [1:0] motor_state;           // Current motor state
reg [1:0] motor_state_prev;      // Previous motor state for edge detection

// Motor state encoding
localparam [1:0] STATE_STOP   = 2'b00;
localparam [1:0] STATE_UP     = 2'b01;
localparam [1:0] STATE_DOWN   = 2'b10;
localparam [1:0] STATE_FAULT  = 2'b11;

// ============================================================================
// MOTOR STATE DETERMINATION
// ============================================================================
always @(*) begin
    // Determine desired motor state from inputs
    case ({motor_up, motor_down})
        2'b00: motor_state = STATE_STOP;
        2'b01: motor_state = STATE_DOWN;
        2'b10: motor_state = STATE_UP;
        2'b11: motor_state = STATE_FAULT;  // Invalid - shoot-through
        default: motor_state = STATE_STOP;
    endcase
end

// ============================================================================
// DEADTIME LOGIC (Sequential)
// ============================================================================
always @(posedge clk) begin
    if (rst) begin
        deadtime_counter <= 0;
        motor_enable_internal <= 1'b0;
        motor_state_prev <= STATE_STOP;
    end else begin
        motor_state_prev <= motor_state;
        
        // Detect direction change (UP <-> DOWN)
        if ((motor_state_prev == STATE_UP && motor_state == STATE_DOWN) ||
            (motor_state_prev == STATE_DOWN && motor_state == STATE_UP)) begin
            // Direction change - insert deadtime
            deadtime_counter <= DEADTIME_CYCLES;
            motor_enable_internal <= 1'b0;
        end else if (deadtime_counter > 0) begin
            // Count down deadtime
            deadtime_counter <= deadtime_counter - 1;
            motor_enable_internal <= 1'b0;
        end else begin
            // Deadtime expired - enable motor
            motor_enable_internal <= 1'b1;
        end
    end
end

// ============================================================================
// OUTPUT LOGIC (Combinational)
// ============================================================================
always @(*) begin
    // Default outputs
    h_bridge_in1 = 1'b0;
    h_bridge_in2 = 1'b0;
    motor_active = 1'b0;
    fault = 1'b0;
    
    // Apply outputs only if enabled and no deadtime
    if (enable && motor_enable_internal) begin
        case (motor_state)
            STATE_STOP: begin
                h_bridge_in1 = 1'b0;
                h_bridge_in2 = 1'b0;
                motor_active = 1'b0;
            end
            
            STATE_UP: begin
                h_bridge_in1 = 1'b1;
                h_bridge_in2 = 1'b0;
                motor_active = 1'b1;
            end
            
            STATE_DOWN: begin
                h_bridge_in1 = 1'b0;
                h_bridge_in2 = 1'b1;
                motor_active = 1'b1;
            end
            
            STATE_FAULT: begin
                // Fault condition - turn off both
                h_bridge_in1 = 1'b0;
                h_bridge_in2 = 1'b0;
                motor_active = 1'b0;
                fault = 1'b1;
            end
            
            default: begin
                h_bridge_in1 = 1'b0;
                h_bridge_in2 = 1'b0;
                motor_active = 1'b0;
            end
        endcase
    end else begin
        // Disabled or in deadtime - all outputs off
        h_bridge_in1 = 1'b0;
        h_bridge_in2 = 1'b0;
        motor_active = 1'b0;
    end
    
    // Additional safety check: never allow both high
    if (h_bridge_in1 && h_bridge_in2) begin
        h_bridge_in1 = 1'b0;
        h_bridge_in2 = 1'b0;
        fault = 1'b1;
    end
end

// ============================================================================
// SAFETY ASSERTIONS (for simulation)
// ============================================================================
// synthesis translate_off
always @(posedge clk) begin
    if (!rst) begin
        // Check for illegal output combination
        if (h_bridge_in1 && h_bridge_in2) begin
            $display("ERROR: Shoot-through on H-Bridge outputs!");
            $stop;
        end
        
        // Check for fault condition
        if (motor_up && motor_down) begin
            $display("WARNING: Both motor_up and motor_down inputs active!");
        end
    end
end
// synthesis translate_on

endmodule

// ============================================================================
// OPTIONAL: PWM MOTOR SPEED CONTROL MODULE
// ============================================================================
// This module can be added for variable-speed motor control
// Currently uses simple ON/OFF control for simplicity

module pwm_generator (
    input wire clk,
    input wire rst,
    input wire enable,
    input wire [7:0] duty_cycle,    // 0-255 (0-100% duty)
    output reg pwm_out
);

parameter CLOCK_FREQ = 50_000_000;
parameter PWM_FREQ = 20_000;  // 20 kHz PWM frequency
localparam PWM_PERIOD = CLOCK_FREQ / PWM_FREQ;

reg [15:0] pwm_counter;
reg [15:0] duty_threshold;

always @(posedge clk) begin
    if (rst) begin
        pwm_counter <= 0;
        pwm_out <= 1'b0;
    end else begin
        // Calculate duty threshold
        duty_threshold <= (PWM_PERIOD * duty_cycle) >> 8;
        
        // PWM counter
        if (pwm_counter >= PWM_PERIOD - 1)
            pwm_counter <= 0;
        else
            pwm_counter <= pwm_counter + 1;
        
        // Generate PWM signal
        if (enable && pwm_counter < duty_threshold)
            pwm_out <= 1'b1;
        else
            pwm_out <= 1'b0;
    end
end

endmodule

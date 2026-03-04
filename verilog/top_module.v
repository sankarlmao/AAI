// ============================================================================
// TOP MODULE - ELEVATOR CONTROL SYSTEM
// ============================================================================
// File: top_module.v
// Purpose: Top-level integration of elevator control system
// Author: Digital Design Project
// Date: March 2026
//
// Description:
//   Integrates all subsystems:
//   - Priority Logic
//   - State Machine Controller
//   - Motor Driver
//   - Button debouncing
//   - Status indicators
//
// ============================================================================

module elevator_top (
    // Clock and Reset
    input wire clk,              // System clock (50 MHz)
    input wire rst_n,            // Active-low asynchronous reset button
    
    // Floor Call Buttons (active high)
    input wire btn_call_f1,      // Floor 1 call button
    input wire btn_call_f2,      // Floor 2 call button
    input wire btn_call_f3,      // Floor 3 call button
    
    // Emergency Controls
    input wire emergency_stop,   // Emergency stop button (active high)
    
    // Motor Driver Outputs (to H-Bridge)
    output wire motor_in1,       // H-Bridge input 1
    output wire motor_in2,       // H-Bridge input 2
    
    // Status LEDs
    output wire [2:0] led_floor,     // Floor indicator LEDs [F3, F2, F1]
    output wire [2:0] led_call,      // Call indicator LEDs [F3, F2, F1]
    output wire led_motor_up,        // Motor moving up indicator
    output wire led_motor_down,      // Motor moving down indicator
    output wire led_fault,           // Fault indicator
    
    // Seven-Segment Display (optional)
    output wire [6:0] seg7_display,  // 7-segment for floor number
    output wire seg7_dp              // Decimal point
);

// ============================================================================
// INTERNAL SIGNALS
// ============================================================================
wire rst;                        // Synchronous reset (active high)
wire call_f1_db, call_f2_db, call_f3_db;  // Debounced button signals
wire [1:0] target_floor;         // Target floor from priority logic
wire motor_up, motor_down;       // Motor control signals from FSM
wire [1:0] current_floor;        // Current floor from FSM
wire [2:0] current_state;        // Current FSM state
wire direction;                  // Direction flag
wire motor_enable;               // Motor enable signal
wire motor_active;               // Motor active status
wire motor_fault;                // Motor fault status

// ============================================================================
// RESET SYNCHRONIZATION
// ============================================================================
// Convert active-low async reset to active-high sync reset
reg [2:0] rst_sync;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        rst_sync <= 3'b111;
    else
        rst_sync <= {rst_sync[1:0], 1'b0};
end
assign rst = rst_sync[2];

// ============================================================================
// BUTTON DEBOUNCING
// ============================================================================
debouncer #(.DEBOUNCE_TIME_MS(20)) db_f1 (
    .clk(clk),
    .rst(rst),
    .button_in(btn_call_f1),
    .button_out(call_f1_db)
);

debouncer #(.DEBOUNCE_TIME_MS(20)) db_f2 (
    .clk(clk),
    .rst(rst),
    .button_in(btn_call_f2),
    .button_out(call_f2_db)
);

debouncer #(.DEBOUNCE_TIME_MS(20)) db_f3 (
    .clk(clk),
    .rst(rst),
    .button_in(btn_call_f3),
    .button_out(call_f3_db)
);

// ============================================================================
// PRIORITY LOGIC MODULE
// ============================================================================
priority_logic priority_ctrl (
    .clk(clk),
    .rst(rst),
    .call_f1(call_f1_db),
    .call_f2(call_f2_db),
    .call_f3(call_f3_db),
    .current_floor(current_floor),
    .current_state(current_state),
    .target_floor(target_floor),
    .direction(direction)
);

// ============================================================================
// ELEVATOR STATE MACHINE CONTROLLER
// ============================================================================
elevator_controller fsm_ctrl (
    .clk(clk),
    .rst(rst),
    .call_f1(call_f1_db),
    .call_f2(call_f2_db),
    .call_f3(call_f3_db),
    .target_floor(target_floor),
    .motor_up(motor_up),
    .motor_down(motor_down),
    .current_floor(current_floor),
    .current_state_out(current_state)
);

// ============================================================================
// MOTOR DRIVER MODULE
// ============================================================================
// Motor enable: disabled during emergency stop
assign motor_enable = !emergency_stop;

motor_driver motor_ctrl (
    .clk(clk),
    .rst(rst),
    .motor_up(motor_up),
    .motor_down(motor_down),
    .enable(motor_enable),
    .h_bridge_in1(motor_in1),
    .h_bridge_in2(motor_in2),
    .motor_active(motor_active),
    .fault(motor_fault)
);

// ============================================================================
// STATUS LED OUTPUTS
// ============================================================================
// Floor indicator LEDs
assign led_floor[0] = (current_floor == 2'b00);  // F1
assign led_floor[1] = (current_floor == 2'b01);  // F2
assign led_floor[2] = (current_floor == 2'b10);  // F3

// Call indicator LEDs (show pending calls)
assign led_call = {call_f3_db, call_f2_db, call_f1_db};

// Motor status LEDs
assign led_motor_up = motor_up && motor_active;
assign led_motor_down = motor_down && motor_active;

// Fault LED
assign led_fault = motor_fault || emergency_stop;

// ============================================================================
// SEVEN-SEGMENT DISPLAY DECODER
// ============================================================================
seven_segment_decoder seg7_dec (
    .floor(current_floor),
    .segments(seg7_display),
    .dp(seg7_dp)
);

endmodule

// ============================================================================
// BUTTON DEBOUNCER MODULE
// ============================================================================
module debouncer #(
    parameter CLOCK_FREQ = 50_000_000,
    parameter DEBOUNCE_TIME_MS = 20
) (
    input wire clk,
    input wire rst,
    input wire button_in,
    output reg button_out
);

localparam DEBOUNCE_CYCLES = (CLOCK_FREQ / 1000) * DEBOUNCE_TIME_MS;
localparam COUNTER_BITS = $clog2(DEBOUNCE_CYCLES);

reg [COUNTER_BITS-1:0] counter;
reg button_sync_0, button_sync_1;

// Synchronize input
always @(posedge clk) begin
    button_sync_0 <= button_in;
    button_sync_1 <= button_sync_0;
end

// Debounce logic
always @(posedge clk) begin
    if (rst) begin
        counter <= 0;
        button_out <= 1'b0;
    end else begin
        if (button_sync_1 == button_out) begin
            // Input matches output - reset counter
            counter <= 0;
        end else begin
            // Input different from output - count
            if (counter == DEBOUNCE_CYCLES - 1) begin
                // Debounce time elapsed - update output
                button_out <= button_sync_1;
                counter <= 0;
            end else begin
                counter <= counter + 1;
            end
        end
    end
end

endmodule

// ============================================================================
// SEVEN-SEGMENT DISPLAY DECODER
// ============================================================================
module seven_segment_decoder (
    input wire [1:0] floor,      // Floor number (0=F1, 1=F2, 2=F3)
    output reg [6:0] segments,   // 7-segment output [gfedcba]
    output wire dp               // Decimal point (always off)
);

// Segments: [g, f, e, d, c, b, a]
//      a
//     ---
//  f |   | b
//     -g-
//  e |   | c
//     ---
//      d

always @(*) begin
    case (floor)
        2'b00: segments = 7'b0110000;  // "1" (Floor 1)
        2'b01: segments = 7'b1101101;  // "2" (Floor 2)
        2'b10: segments = 7'b1111001;  // "3" (Floor 3)
        default: segments = 7'b0000000; // Blank
    endcase
end

assign dp = 1'b0;  // Decimal point off

endmodule

// ============================================================================
// TESTBENCH (for simulation)
// ============================================================================
// synthesis translate_off
module elevator_top_tb;

reg clk;
reg rst_n;
reg btn_call_f1, btn_call_f2, btn_call_f3;
reg emergency_stop;

wire motor_in1, motor_in2;
wire [2:0] led_floor, led_call;
wire led_motor_up, led_motor_down, led_fault;
wire [6:0] seg7_display;
wire seg7_dp;

// Instantiate DUT
elevator_top dut (
    .clk(clk),
    .rst_n(rst_n),
    .btn_call_f1(btn_call_f1),
    .btn_call_f2(btn_call_f2),
    .btn_call_f3(btn_call_f3),
    .emergency_stop(emergency_stop),
    .motor_in1(motor_in1),
    .motor_in2(motor_in2),
    .led_floor(led_floor),
    .led_call(led_call),
    .led_motor_up(led_motor_up),
    .led_motor_down(led_motor_down),
    .led_fault(led_fault),
    .seg7_display(seg7_display),
    .seg7_dp(seg7_dp)
);

// Clock generation (50 MHz)
initial clk = 0;
always #10 clk = ~clk;

// Test sequence
initial begin
    $display("========================================");
    $display("  ELEVATOR SYSTEM TESTBENCH");
    $display("========================================");
    
    // Initialize
    rst_n = 0;
    btn_call_f1 = 0;
    btn_call_f2 = 0;
    btn_call_f3 = 0;
    emergency_stop = 0;
    
    // Reset
    #100 rst_n = 1;
    $display("[%0t] Reset released", $time);
    
    // Test 1: Call Floor 3
    #1000;
    $display("[%0t] TEST 1: Calling Floor 3", $time);
    btn_call_f3 = 1;
    #50 btn_call_f3 = 0;
    
    // Wait for elevator to reach F3
    #4000000;  // 4 ms (simulated travel time)
    
    // Test 2: Call Floor 1
    $display("[%0t] TEST 2: Calling Floor 1", $time);
    btn_call_f1 = 1;
    #50 btn_call_f1 = 0;
    
    #8000000;  // Wait
    
    // Test 3: Multiple calls
    $display("[%0t] TEST 3: Multiple calls (F2 and F3)", $time);
    btn_call_f2 = 1;
    #50 btn_call_f2 = 0;
    #1000;
    btn_call_f3 = 1;
    #50 btn_call_f3 = 0;
    
    #8000000;
    
    $display("[%0t] Simulation complete", $time);
    $finish;
end

// Monitor
always @(posedge clk) begin
    $display("[%0t] Floor:%0d | Motor:[U=%b D=%b] | Calls:[%b%b%b]",
             $time, led_floor, led_motor_up, led_motor_down,
             led_call[2], led_call[1], led_call[0]);
end

endmodule
// synthesis translate_on

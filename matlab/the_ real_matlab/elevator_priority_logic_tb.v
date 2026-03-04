//==============================================================
// Elevator Priority Logic - Testbench
// Verifies direction-based priority for elevator calls
// Author: Elevator Control System
// Date: March 2026
//==============================================================

`timescale 1ns/1ps

module elevator_priority_logic_tb;

    //==============================================================
    // Testbench Signals
    //==============================================================
    reg clk;
    reg rst_n;
    reg floor1_call, floor2_call, floor3_call;
    reg at_floor1, at_floor2, at_floor3;
    reg [1:0] current_direction;
    
    wire [1:0] target_floor;
    wire [1:0] motor_direction;
    wire door_open;
    wire call_serviced;
    
    //==============================================================
    // DUT Instantiation
    //==============================================================
    elevator_priority_logic DUT (
        .clk(clk),
        .rst_n(rst_n),
        .floor1_call(floor1_call),
        .floor2_call(floor2_call),
        .floor3_call(floor3_call),
        .at_floor1(at_floor1),
        .at_floor2(at_floor2),
        .at_floor3(at_floor3),
        .current_direction(current_direction),
        .target_floor(target_floor),
        .motor_direction(motor_direction),
        .door_open(door_open),
        .call_serviced(call_serviced)
    );
    
    //==============================================================
    // Clock Generation - 10MHz (100ns period)
    //==============================================================
    initial begin
        clk = 0;
        forever #50 clk = ~clk;
    end
    
    //==============================================================
    // Test Stimulus
    //==============================================================
    initial begin
        // Initialize all inputs
        rst_n = 0;
        floor1_call = 0;
        floor2_call = 0;
        floor3_call = 0;
        at_floor1 = 1; // Start at floor 1
        at_floor2 = 0;
        at_floor3 = 0;
        current_direction = 2'b00; // IDLE
        
        // Wait for reset
        #200;
        rst_n = 1;
        #100;
        
        $display("============================================");
        $display("    ELEVATOR PRIORITY LOGIC TESTBENCH       ");
        $display("============================================");
        $display("");
        
        //----------------------------------------------------------
        // TEST CASE 1: Simple call from Floor 1 to Floor 3
        //----------------------------------------------------------
        $display("TEST 1: Call to Floor 3 (from Floor 1)");
        $display("---------------------------------------");
        floor3_call = 1;
        #100;
        floor3_call = 0;
        
        // Wait for elevator to process
        #500;
        $display("  Target Floor: %d", target_floor);
        $display("  Motor Direction: %s", motor_direction == 2'b01 ? "UP" : 
                                          motor_direction == 2'b10 ? "DOWN" : "STOP");
        
        // Simulate moving to floor 2
        #1000;
        at_floor1 = 0;
        at_floor2 = 1;
        #200;
        $display("  At Floor 2 - Door: %s", door_open ? "OPEN" : "CLOSED");
        
        // Continue to floor 3
        #500;
        at_floor2 = 0;
        at_floor3 = 1;
        #200;
        $display("  At Floor 3 - Door: %s", door_open ? "OPEN" : "CLOSED");
        $display("");
        
        //----------------------------------------------------------
        // TEST CASE 2: Priority Test - Floor 1 and Floor 3 pressed
        // Elevator at Floor 2, was moving UP
        //----------------------------------------------------------
        $display("TEST 2: Priority Test (F1 & F3 calls, at F2, was UP)");
        $display("----------------------------------------------------");
        
        // Reset to floor 2
        at_floor3 = 0;
        at_floor2 = 1;
        current_direction = 2'b01; // Was moving UP
        #200;
        
        // Both Floor 1 and Floor 3 call simultaneously
        floor1_call = 1;
        floor3_call = 1;
        #100;
        floor1_call = 0;
        floor3_call = 0;
        
        #500;
        $display("  Current Direction: UP");
        $display("  Priority Target: Floor %d", target_floor);
        $display("  Expected: Floor 3 (continue UP direction)");
        $display("  Motor: %s", motor_direction == 2'b01 ? "UP" : 
                                motor_direction == 2'b10 ? "DOWN" : "STOP");
        $display("");
        
        //----------------------------------------------------------
        // TEST CASE 3: Priority Test - Direction DOWN
        //----------------------------------------------------------
        $display("TEST 3: Priority Test (F1 & F3 calls, at F2, was DOWN)");
        $display("-----------------------------------------------------");
        
        current_direction = 2'b10; // Was moving DOWN
        #200;
        
        floor1_call = 1;
        floor3_call = 1;
        #100;
        floor1_call = 0;
        floor3_call = 0;
        
        #500;
        $display("  Current Direction: DOWN");
        $display("  Priority Target: Floor %d", target_floor);
        $display("  Expected: Floor 1 (continue DOWN direction)");
        $display("  Motor: %s", motor_direction == 2'b01 ? "UP" : 
                                motor_direction == 2'b10 ? "DOWN" : "STOP");
        $display("");
        
        //----------------------------------------------------------
        // TEST CASE 4: All floors called
        //----------------------------------------------------------
        $display("TEST 4: All Floors Called (starting at F1)");
        $display("------------------------------------------");
        
        // Reset to floor 1
        at_floor2 = 0;
        at_floor1 = 1;
        current_direction = 2'b00; // IDLE
        #200;
        
        floor1_call = 1;
        floor2_call = 1;
        floor3_call = 1;
        #100;
        floor1_call = 0;
        floor2_call = 0;
        floor3_call = 0;
        
        #300;
        $display("  At Floor 1 - Servicing F1 call first");
        $display("  Door: %s, Call Serviced: %b", door_open ? "OPEN" : "CLOSED", call_serviced);
        
        #500;
        $display("  Next Target: Floor %d", target_floor);
        $display("  Motor: %s", motor_direction == 2'b01 ? "UP" : 
                                motor_direction == 2'b10 ? "DOWN" : "STOP");
        
        // Move to floor 2
        #500;
        at_floor1 = 0;
        at_floor2 = 1;
        #300;
        $display("  At Floor 2 - Door: %s", door_open ? "OPEN" : "CLOSED");
        
        // Move to floor 3
        #500;
        at_floor2 = 0;
        at_floor3 = 1;
        #300;
        $display("  At Floor 3 - Door: %s", door_open ? "OPEN" : "CLOSED");
        
        $display("");
        $display("============================================");
        $display("    TESTBENCH COMPLETE                      ");
        $display("============================================");
        
        #1000;
        $finish;
    end
    
    //==============================================================
    // Monitor Output Changes
    //==============================================================
    always @(posedge clk) begin
        if (rst_n && (motor_direction != 2'b00 || door_open)) begin
            $display("  [%0t] State Change - Motor:%s Door:%s Target:F%0d", 
                    $time,
                    motor_direction == 2'b01 ? "UP  " : 
                    motor_direction == 2'b10 ? "DOWN" : "STOP",
                    door_open ? "OPEN " : "CLOSE",
                    target_floor);
        end
    end
    
    //==============================================================
    // VCD Dump for Waveform Viewing
    //==============================================================
    initial begin
        $dumpfile("elevator_priority_tb.vcd");
        $dumpvars(0, elevator_priority_logic_tb);
    end

endmodule

# ELEVATOR CONTROL SYSTEM - TEST CASES

## Overview
This document provides comprehensive test cases for verifying elevator control system functionality. Tests cover FSM transitions, priority logic, motor control, and edge cases.

---

## Test Case Template

```
TEST ID: TC-XXX
Title: [Brief description]
Category: [FSM/Priority/Motor/Integration/Edge Case]
Initial State: [Starting conditions]
Input: [Test inputs]
Expected Output: [Expected behavior]
Pass Criteria: [What defines success]
```

---

## CATEGORY 1: FINITE STATE MACHINE TESTS

### TC-001: Power-On Reset
**Category:** FSM  
**Initial State:** System powered off  
**Input:** 
- Apply power
- Assert reset signal

**Expected Output:**
- current_state = FLOOR_1
- current_floor = 1
- motor_up = 0
- motor_down = 0

**Pass Criteria:** 
- Elevator initializes to ground floor
- All motor signals LOW
- No movement occurs

---

### TC-002: Single Call - Floor 1 to Floor 3
**Category:** FSM  
**Initial State:** 
- current_state = FLOOR_1
- current_floor = 1

**Input:** 
- Call_F3 = 1 (press floor 3 button)

**Expected Output:**
1. State: FLOOR_1 → MOVING_UP
2. Motor_Up = 1, Motor_Down = 0
3. After travel time: State → FLOOR_2 → MOVING_UP → FLOOR_3
4. At FLOOR_3: Motor_Up = 0, Call_F3 cleared

**Pass Criteria:**
- Complete travel from F1 to F3
- Stops at F2 if needed (depends on priority)
- Motor signals correct throughout
- Total time < 7 seconds (2 floors × 3s + margin)

---

### TC-003: Single Call - Floor 3 to Floor 1
**Category:** FSM  
**Initial State:** 
- current_state = FLOOR_3
- current_floor = 3

**Input:** 
- Call_F1 = 1

**Expected Output:**
1. State: FLOOR_3 → MOVING_DOWN
2. Motor_Up = 0, Motor_Down = 1
3. After travel time: State → FLOOR_2 → MOVING_DOWN → FLOOR_1
4. At FLOOR_1: Motor_Down = 0, Call_F1 cleared

**Pass Criteria:**
- Complete travel from F3 to F1
- Motor signals correct
- Total time < 7 seconds

---

### TC-004: Call for Current Floor
**Category:** FSM  
**Initial State:** 
- current_state = FLOOR_2
- current_floor = 2

**Input:** 
- Call_F2 = 1

**Expected Output:**
- State remains FLOOR_2
- Motor_Up = 0, Motor_Down = 0
- Call_F2 immediately cleared
- No movement

**Pass Criteria:**
- Elevator does not move
- Call is acknowledged and cleared
- Doors operate (in real implementation)

---

### TC-005: Rapid State Transitions
**Category:** FSM  
**Initial State:** 
- current_state = FLOOR_1

**Input:** 
- t=0s: Call_F3 = 1
- t=1s: Call_F2 = 1 (while moving up)

**Expected Output:**
1. Start moving to F3
2. When F2 call detected: Stop at F2
3. Serve F2, then continue to F3

**Pass Criteria:**
- Both calls serviced
- Proper state transitions
- No missed stops

---

## CATEGORY 2: PRIORITY LOGIC TESTS

### TC-101: Upward Priority
**Category:** Priority  
**Initial State:** 
- current_floor = 1
- direction = UP

**Input:** 
- Call_F2 = 1
- Call_F3 = 1

**Expected Output:**
- target_floor = 2 (serve F2 first)
- After reaching F2: target_floor = 3

**Pass Criteria:**
- Visits floors in ascending order: F1 → F2 → F3
- Does not skip F2 to go to F3

---

### TC-102: Downward Priority
**Category:** Priority  
**Initial State:** 
- current_floor = 3
- direction = DOWN

**Input:** 
- Call_F2 = 1
- Call_F1 = 1

**Expected Output:**
- target_floor = 2 (serve F2 first)
- After reaching F2: target_floor = 1

**Pass Criteria:**
- Visits floors in descending order: F3 → F2 → F1
- Does not skip F2 to go to F1

---

### TC-103: Direction Reversal
**Category:** Priority  
**Initial State:** 
- current_floor = 2
- direction = UP
- Call_F3 = 0

**Input:** 
- Call_F1 = 1 (opposite direction)

**Expected Output:**
- Complete current direction (check for F3)
- Then reverse: target_floor = 1
- State: MOVING_UP → FLOOR_2 → MOVING_DOWN

**Pass Criteria:**
- Direction reverses only when no calls in current direction
- Transition is smooth

---

### TC-104: Idle State - Nearest Floor
**Category:** Priority  
**Initial State:** 
- current_floor = 2
- direction = IDLE

**Input:** 
- Call_F1 = 1
- Call_F3 = 1 (simultaneous)

**Expected Output:**
- target_floor = 1 OR 3 (both equidistant)
- Tie-breaker: Lower floor wins → target_floor = 1

**Pass Criteria:**
- Selects nearest floor
- Tie broken by lower floor preference
- Eventually serves both calls

---

### TC-105: All Floors Called
**Category:** Priority  
**Initial State:** 
- current_floor = 2
- direction = IDLE

**Input:** 
- Call_F1 = 1
- Call_F2 = 1
- Call_F3 = 1

**Expected Output:**
1. Serve F2 (current floor) - clear immediately
2. Serve F1 (nearest)
3. Serve F3 (remaining)

**Pass Criteria:**
- All three calls serviced
- Optimal path chosen
- Total time < 10 seconds

---

## CATEGORY 3: MOTOR DRIVER TESTS

### TC-201: Motor Up Command
**Category:** Motor  
**Initial State:** Motor stopped

**Input:** 
- motor_up = 1
- motor_down = 0

**Expected Output:**
- h_bridge_in1 = 1
- h_bridge_in2 = 0
- Motor rotates clockwise (UP)
- motor_active = 1

**Pass Criteria:**
- Correct H-Bridge signals
- No shoot-through
- Motor responds

---

### TC-202: Motor Down Command
**Category:** Motor  
**Initial State:** Motor stopped

**Input:** 
- motor_up = 0
- motor_down = 1

**Expected Output:**
- h_bridge_in1 = 0
- h_bridge_in2 = 1
- Motor rotates counter-clockwise (DOWN)
- motor_active = 1

**Pass Criteria:**
- Correct H-Bridge signals
- No shoot-through
- Motor responds

---

### TC-203: Motor Stop Command
**Category:** Motor  
**Initial State:** Motor running (either direction)

**Input:** 
- motor_up = 0
- motor_down = 0

**Expected Output:**
- h_bridge_in1 = 0
- h_bridge_in2 = 0
- Motor coasts to stop
- motor_active = 0

**Pass Criteria:**
- Both H-Bridge signals LOW
- Motor decelerates smoothly

---

### TC-204: Shoot-Through Prevention
**Category:** Motor - Safety  
**Initial State:** Motor stopped

**Input:** 
- motor_up = 1
- motor_down = 1 (INVALID - should never occur)

**Expected Output:**
- h_bridge_in1 = 0
- h_bridge_in2 = 0
- fault = 1
- Motor停 (stopped)

**Pass Criteria:**
- System detects fault
- Motor disabled immediately
- No damage to H-Bridge

---

### TC-205: Direction Change with Deadtime
**Category:** Motor  
**Initial State:** 
- Motor running UP
- motor_up = 1, motor_down = 0

**Input:** 
- Change to: motor_up = 0, motor_down = 1

**Expected Output:**
1. Deadtime period: both H-Bridge signals = 0
2. Deadtime duration: 2µs (configurable)
3. After deadtime: h_bridge_in2 = 1 (DOWN)

**Pass Criteria:**
- Deadtime inserted
- No overlap of opposing signals
- Smooth direction reversal

---

## CATEGORY 4: INTEGRATION TESTS

### TC-301: Complete Journey - F1 to F3 to F1
**Category:** Integration  
**Initial State:** 
- current_state = FLOOR_1

**Input Sequence:**
1. t=0s: Call_F3 = 1
2. t=8s: Call_F1 = 1 (after reaching F3)

**Expected Output:**
1. F1 → MOVING_UP → F2 → MOVING_UP → F3 (arrive ~6s)
2. F3 → MOVING_DOWN → F2 → MOVING_DOWN → F1 (arrive ~14s)

**Pass Criteria:**
- Complete round trip
- All states visited correctly
- Total time < 15 seconds
- Motor signals correct throughout

---

### TC-302: Multiple Simultaneous Calls with Priority
**Category:** Integration  
**Initial State:** 
- current_floor = 1
- All calls inactive

**Input:** 
- t=0s: Call_F2 = 1, Call_F3 = 1 (simultaneous)

**Expected Output:**
1. Elevator moves UP
2. Stops at F2 first (closer)
3. Continues to F3
4. Both calls serviced in order

**Pass Criteria:**
- Priority logic works correctly
- Sequential service: F2 before F3
- Total time < 7 seconds

---

### TC-303: Call While Traveling
**Category:** Integration  
**Initial State:** 
- current_state = MOVING_UP (from F1 to F3)
- Currently between F1 and F2

**Input:** 
- Call_F2 = 1 (pressed during travel)

**Expected Output:**
- Elevator stops at F2
- Serves F2 call
- Continues to F3

**Pass Criteria:**
- Dynamic call handled correctly
- No missed stops
- Smooth deceleration at F2

---

### TC-304: Emergency Stop
**Category:** Integration - Safety  
**Initial State:** 
- Motor running (moving between floors)

**Input:** 
- emergency_stop = 1

**Expected Output:**
- motor_up = 0, motor_down = 0 immediately
- Motor stops (brake)
- fault = 1
- System halts

**Pass Criteria:**
- Immediate motor shutdown
- No further motion
- System remains in safe state

---

### TC-305: Continuous Operation - 10 Calls
**Category:** Integration - Stress Test  
**Initial State:** 
- current_floor = 1

**Input:** Random sequence of 10 floor calls

**Expected Output:**
- All 10 calls serviced
- No stuck states
- No motor faults
- System responsive throughout

**Pass Criteria:**
- 100% call completion rate
- No timeout errors
- System stability maintained

---

## CATEGORY 5: EDGE CASES

### TC-401: Repeated Button Press
**Category:** Edge Case  
**Initial State:** 
- current_floor = 1
- Call_F3 latched (button already pressed)

**Input:** 
- Call_F3 = 1 (pressed again)

**Expected Output:**
- No duplicate action
- Single call remains latched
- Elevator behavior unchanged

**Pass Criteria:**
- Idempotent behavior
- No double-booking

---

### TC-402: Call Cancel (Button Un-Press)
**Category:** Edge Case  
**Initial State:** 
- Call_F3 = 1 (latched)
- Elevator has not yet moved

**Input:** 
- Call_F3 = 0 (button released before service)

**Expected Output:**
- Call remains latched (system remembers)
- Elevator still goes to F3
- Call cleared only upon arrival

**Pass Criteria:**
- Button release does not cancel call
- Latching logic works correctly

---

### TC-403: Maximum Travel Time
**Category:** Edge Case  
**Initial State:** 
- current_floor = 1

**Input:** 
- Call_F3 = 1

**Expected Output:**
- Travel time = 2 floors × 3 seconds = 6 seconds
- State transitions timed correctly

**Pass Criteria:**
- Timer accuracy ±1%
- No premature transitions

---

### TC-404: Reset During Operation
**Category:** Edge Case  
**Initial State:** 
- Moving between floors

**Input:** 
- rst = 1 (reset asserted)

**Expected Output:**
- Immediate transition to FLOOR_1
- Motor stopped
- All calls cleared
- System reinitialized

**Pass Criteria:**
- Safe reset behavior
- No hung states
- Clean restart

---

### TC-405: Clock Glitch Immunity
**Category:** Edge Case  
**Initial State:** Normal operation

**Input:** 
- Introduce clock jitter (simulation)

**Expected Output:**
- System continues operating
- State machine stable
- No erroneous transitions

**Pass Criteria:**
- Synchronous design prevents glitches
- No metastability issues

---

## TEST EXECUTION SUMMARY

### MATLAB Simulation Tests
Execute by running:
```matlab
cd matlab/
run_all_tests
```

Expected results:
- TC-001 to TC-005: FSM tests
- TC-101 to TC-105: Priority logic
- TC-301 to TC-305: Integration tests

### Verilog Testbench
Execute in simulator:
```bash
iverilog -o elevator_tb top_module.v
vvp elevator_tb
```

Verify waveforms in GTKWave:
```bash
gtkwave elevator.vcd
```

### Hardware Tests (FPGA)
1. Program FPGA with bitstream
2. Connect floor buttons
3. Connect motor driver
4. Execute test cases manually
5. Verify with LEDs and 7-segment display

---

## TEST METRICS

### Coverage Goals
- [ ] State Coverage: 100% (all 5 states visited)
- [ ] Transition Coverage: 100% (all valid transitions)
- [ ] Branch Coverage: >95% (all decision points)
- [ ] Motor Command Coverage: 100% (UP, DOWN, STOP)

### Pass/Fail Criteria
- **PASS**: All expected outputs match actual outputs
- **FAIL**: Any deviation from expected behavior
- **PARTIAL**: Functionality works but timing off

---

## DEBUGGING CHECKLIST

If test fails, check:
- [ ] Initial conditions set correctly
- [ ] Timing parameters (travel_time, door_time)
- [ ] State encoding matches between modules
- [ ] Request queue clearing logic
- [ ] Motor driver safety interlocks
- [ ] Clock frequency and period
- [ ] Reset signal polarity and synchronization

---

## TEST LOG TEMPLATE

```
Test ID: TC-XXX
Date: YYYY-MM-DD
Tester: [Name]
Platform: [MATLAB/Verilog/FPGA]

Results:
- Expected: [Description]
- Actual: [Description]
- Status: [PASS/FAIL/PARTIAL]

Notes:
[Any observations, issues, or comments]
```

---

## AUTOMATED TEST SCRIPT (MATLAB Example)

```matlab
function test_results = run_all_tests()
    test_results = struct();
    
    % TC-002: F1 to F3
    test_results.TC002 = test_floor_1_to_3();
    
    % TC-003: F3 to F1
    test_results.TC003 = test_floor_3_to_1();
    
    % Add more tests...
    
    % Summary
    total = length(fieldnames(test_results));
    passed = sum(structfun(@(x) x.passed, test_results));
    fprintf('Tests Passed: %d / %d\n', passed, total);
end
```


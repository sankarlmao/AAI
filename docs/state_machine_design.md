# STATE MACHINE DESIGN

## FSM Overview

The elevator controller uses a Moore-type Finite State Machine where outputs depend only on the current state. The FSM has 5 distinct states representing elevator position and motion.

---

## State Definitions

### State Encoding

```
FLOOR_1      = 3'b000  // Elevator at Floor 1 (Ground)
MOVING_UP    = 3'b001  // Elevator moving upward
FLOOR_2      = 3'b010  // Elevator at Floor 2 (First)
MOVING_DOWN  = 3'b011  // Elevator moving downward
FLOOR_3      = 3'b100  // Elevator at Floor 3 (Second/Top)
```

### State Descriptions

**FLOOR_1** (Ground Floor)
- Elevator is stationary at ground floor
- Motor_Up = 0, Motor_Down = 0
- Current_Floor = 2'b00
- Doors can open
- Ready to accept calls

**MOVING_UP** (Ascending)
- Elevator is traveling upward
- Motor_Up = 1, Motor_Down = 0
- Current_Floor = previous floor (transitioning)
- Cannot open doors
- Destination: Floor 2 or Floor 3

**FLOOR_2** (First Floor)
- Elevator is stationary at first floor
- Motor_Up = 0, Motor_Down = 0
- Current_Floor = 2'b01
- Doors can open
- Can move up or down

**MOVING_DOWN** (Descending)
- Elevator is traveling downward
- Motor_Up = 0, Motor_Down = 1
- Current_Floor = previous floor (transitioning)
- Cannot open doors
- Destination: Floor 1 or Floor 2

**FLOOR_3** (Top Floor)
- Elevator is stationary at top floor
- Motor_Up = 0, Motor_Down = 0
- Current_Floor = 2'b10
- Doors can open
- Can only move down

---

## State Transition Table

| Current State | Call_F1 | Call_F2 | Call_F3 | Target Floor | Next State   |
|--------------|---------|---------|---------|--------------|-------------|
| FLOOR_1      | X       | 1       | X       | 2            | MOVING_UP   |
| FLOOR_1      | X       | 0       | 1       | 3            | MOVING_UP   |
| FLOOR_1      | X       | 0       | 0       | -            | FLOOR_1     |
| MOVING_UP    | X       | X       | X       | 2            | FLOOR_2     |
| MOVING_UP    | X       | X       | X       | 3            | FLOOR_2     |
| FLOOR_2      | 1       | X       | 0       | 1            | MOVING_DOWN |
| FLOOR_2      | 0       | X       | 1       | 3            | MOVING_UP   |
| FLOOR_2      | 0       | X       | 0       | -            | FLOOR_2     |
| MOVING_DOWN  | X       | X       | X       | 2            | FLOOR_2     |
| MOVING_DOWN  | X       | X       | X       | 1            | FLOOR_2     |
| FLOOR_3      | 1       | X       | X       | 1            | MOVING_DOWN |
| FLOOR_3      | 0       | 1       | X       | 2            | MOVING_DOWN |
| FLOOR_3      | 0       | 0       | X       | -            | FLOOR_3     |

**Note**: Target Floor is determined by Priority Logic module

---

## State Transition Diagram (ASCII)

```
                    +-------------+
         +--------->|   FLOOR_1   |<----------+
         |          | (Ground)    |           |
         |          +------+------+           |
         |                 |                  |
         |                 | Call_F2=1 OR     |
         |                 | Call_F3=1        |
         |                 v                  |
         |          +-------------+           |
         |          |  MOVING_UP  |           |
         |          +------+------+           |
         |                 |                  |
         |        +--------+--------+         |
         |        |                 |         |
         |        v                 v         |
         | +-------------+   +-------------+  |
         | |   FLOOR_2   |   |   FLOOR_3   |  |
         | | (First)     |   | (Top)       |  |
         | +------+------+   +------+------+  |
         |        |                 |         |
         |        | Call_F1=1       | Call_F1=1 OR
         |        | (and no F3)     | Call_F2=1
         |        v                 v         |
         | +-------------+   +-------------+  |
         | | MOVING_DOWN |<--| MOVING_DOWN |<-+
         | +------+------+   +-------------+
         |        |
         +--------+
         (Reaches F1)
```

---

## Detailed State Transitions

### From FLOOR_1 (Ground Floor)

```
IF (Call_F2 == 1 OR Call_F3 == 1) THEN
    direction = UP
    IF (Call_F2 == 1) THEN
        target_floor = 2
    ELSE
        target_floor = 3
    END IF
    next_state = MOVING_UP
ELSE
    next_state = FLOOR_1  // Stay idle
END IF
```

### From MOVING_UP

```
// Transition occurs after timer expires (floor reached)
IF (target_floor == 2) THEN
    next_state = FLOOR_2
ELSIF (target_floor == 3 AND current_position == 2) THEN
    next_state = FLOOR_2  // Pass through
ELSIF (target_floor == 3 AND current_position == approaching_3) THEN
    next_state = FLOOR_3
END IF
```

### From FLOOR_2 (Middle Floor)

```
IF (Call_F3 == 1) THEN
    direction = UP
    target_floor = 3
    next_state = MOVING_UP
ELSIF (Call_F1 == 1) THEN
    direction = DOWN
    target_floor = 1
    next_state = MOVING_DOWN
ELSE
    next_state = FLOOR_2  // Stay idle
END IF
```

### From MOVING_DOWN

```
// Transition occurs after timer expires (floor reached)
IF (target_floor == 2) THEN
    next_state = FLOOR_2
ELSIF (target_floor == 1 AND current_position == 2) THEN
    next_state = FLOOR_2  // Pass through
ELSIF (target_floor == 1 AND current_position == approaching_1) THEN
    next_state = FLOOR_1
END IF
```

### From FLOOR_3 (Top Floor)

```
IF (Call_F1 == 1 OR Call_F2 == 1) THEN
    direction = DOWN
    IF (Call_F2 == 1) THEN
        target_floor = 2
    ELSE
        target_floor = 1
    END IF
    next_state = MOVING_DOWN
ELSE
    next_state = FLOOR_3  // Stay idle
END IF
```

---

## Output Logic

### Motor Control Outputs

```
CASE current_state IS
    WHEN FLOOR_1:
        Motor_Up = 0
        Motor_Down = 0
        Current_Floor = 2'b00
    
    WHEN MOVING_UP:
        Motor_Up = 1
        Motor_Down = 0
        Current_Floor = (last floor value)
    
    WHEN FLOOR_2:
        Motor_Up = 0
        Motor_Down = 0
        Current_Floor = 2'b01
    
    WHEN MOVING_DOWN:
        Motor_Up = 0
        Motor_Down = 1
        Current_Floor = (last floor value)
    
    WHEN FLOOR_3:
        Motor_Up = 0
        Motor_Down = 0
        Current_Floor = 2'b10
END CASE
```

---

## Timing Considerations

### Movement Duration
Each MOVING state remains active for a pre-defined period:

```
FLOOR_TRAVEL_TIME = 3 seconds  (configurable)
CYCLES_PER_FLOOR = CLOCK_FREQ × FLOOR_TRAVEL_TIME
```

### State Transition Timing
```verilog
// Timer countdown in MOVING states
if (current_state == MOVING_UP || current_state == MOVING_DOWN) begin
    if (travel_counter == 0) begin
        // Reached destination
        current_state <= next_floor_state;
    end else begin
        travel_counter <= travel_counter - 1;
    end
end
```

### Idle Timing
- FLOOR states have no minimum duration
- State change occurs on next clock after conditions met
- Allows immediate response to button presses

---

## Reset Behavior

```
ON Reset = 1:
    current_state <= FLOOR_1
    travel_counter <= 0
    Motor_Up <= 0
    Motor_Down <= 0
    Current_Floor <= 2'b00
    Clear all request flags
```

Elevator always initializes to Floor 1 (ground floor) on reset.

---

## State Machine Implementation Styles

### Mealy vs Moore

**This design uses MOORE machine**:
- Outputs depend only on current state
- More stable, less prone to glitches
- Easier to debug and verify
- Slight delay in output response

Alternative Mealy implementation could output motor signals based on state + inputs, but this risks glitches during input transitions.

---

## Verification and Validation

### State Coverage
All 5 states must be reachable:
- ✓ FLOOR_1: Initial state
- ✓ MOVING_UP: From F1 or F2 with upper call
- ✓ FLOOR_2: From MOVING_UP or MOVING_DOWN
- ✓ MOVING_DOWN: From F2 or F3 with lower call
- ✓ FLOOR_3: From MOVING_UP

### Transition Coverage
All valid transitions must be tested:
- F1 → MOVING_UP → F2 → MOVING_UP → F3
- F3 → MOVING_DOWN → F2 → MOVING_DOWN → F1
- F2 → MOVING_UP → F3 (direct)
- F2 → MOVING_DOWN → F1 (direct)

### Illegal States
States that should NOT occur:
- Motor_Up = 1 AND Motor_Down = 1 (shoot-through)
- Stuck in MOVING state (watchdog needed)
- Invalid state encoding (3'b101, 3'b110, 3'b111)

---

## FSM Optimization

### Minimal State Encoding
5 states require ⌈log₂(5)⌉ = 3 bits

Current encoding uses 3 bits:
- 000, 001, 010, 011, 100 (5 states)
- 3 unused states: 101, 110, 111

### Alternative Encodings

**One-Hot Encoding** (easier debugging):
```
FLOOR_1     = 5'b00001
MOVING_UP   = 5'b00010
FLOOR_2     = 5'b00100
MOVING_DOWN = 5'b01000
FLOOR_3     = 5'b10000
```
Pros: Simpler decode logic, easier debug
Cons: More flip-flops (5 vs 3)

**Gray Code** (minimize switching):
```
FLOOR_1     = 3'b000
MOVING_UP   = 3'b001
FLOOR_2     = 3'b011
MOVING_DOWN = 3'b010
FLOOR_3     = 3'b110
```
Pros: Reduced power consumption
Cons: Complex decode logic

---

## State Machine Simulation Tips

### Testbench Scenarios
1. **Power-On**: Verify reset to FLOOR_1
2. **Single Call**: F1 → call F3 → observe transitions
3. **Direction Reversal**: F3 → F1 called → verify full descent
4. **Multi-Call**: Multiple buttons → verify priority
5. **Rapid Calls**: Button pressed while moving

### Debug Outputs
Add to simulation:
```verilog
$display("Time: %0t | State: %s | Floor: %0d | Motor(U/D): %b/%b",
         $time, state_name, current_floor, motor_up, motor_down);
```

### Waveform Analysis
Monitor signals:
- state[2:0]
- target_floor[1:0]
- motor_up, motor_down
- travel_counter
- All call buttons

---

## Common FSM Bugs and Solutions

| Bug | Symptom | Solution |
|-----|---------|----------|
| Missing state | Undefined behavior | Ensure all 2^(state_bits) covered |
| Blocking assignments | Race conditions | Use non-blocking (<=) in sequential |
| Combinational loops | Synthesis error | Separate next_state logic clearly |
| Reset not complete | Random startup state | Reset all state registers |
| Travel timer overflow | Elevator stuck moving | Add counter overflow check |


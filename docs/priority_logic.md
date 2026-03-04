# PRIORITY LOGIC AND SCHEDULING ALGORITHM

## Overview

The priority logic module determines which floor the elevator should serve next when multiple calls are pending. The scheduling algorithm minimizes travel distance and wait time by considering the current direction of movement.

---

## Priority Rules

### Rule 1: Directional Continuity
**When moving UP**:
- Serve all pending floors above current position
- Visit floors in ascending order
- Only reverse direction when no higher floors are pending

**When moving DOWN**:
- Serve all pending floors below current position
- Visit floors in descending order
- Only reverse direction when no lower floors are pending

### Rule 2: Nearest Floor First (When Idle)
- If elevator is stationary (at any floor)
- Select the nearest pending call
- Break ties by selecting lower floor

### Rule 3: Request Queuing
- All button presses are latched until served
- A floor request remains pending until elevator arrives at that floor
- Pressing already-lit button has no additional effect

---

## Algorithm Pseudocode

### Main Priority Logic

```pseudocode
FUNCTION priority_logic(current_floor, direction, call_f1, call_f2, call_f3)
    
    // Inputs:
    // current_floor: 1, 2, or 3
    // direction: 'UP', 'DOWN', or 'IDLE'
    // call_f1, call_f2, call_f3: Boolean flags
    
    // Output: next_target_floor (1, 2, 3, or 0 if none)
    
    // Store pending requests in array
    pending_floors = []
    IF call_f1 == 1 THEN append 1 to pending_floors
    IF call_f2 == 1 THEN append 2 to pending_floors
    IF call_f3 == 1 THEN append 3 to pending_floors
    
    // No pending requests
    IF pending_floors is empty THEN
        RETURN 0  // Stay at current floor
    END IF
    
    // Remove current floor from pending (already here)
    pending_floors = remove(pending_floors, current_floor)
    
    IF pending_floors is empty THEN
        RETURN 0  // All calls were for current floor
    END IF
    
    // Apply directional priority
    CASE direction OF
        
        'UP':
            // Find floors above current
            floors_above = filter(pending_floors, floor > current_floor)
            
            IF floors_above is not empty THEN
                RETURN min(floors_above)  // Nearest higher floor
            ELSE
                // No floors above, reverse direction
                RETURN max(pending_floors)  // Highest pending floor
            END IF
        
        'DOWN':
            // Find floors below current
            floors_below = filter(pending_floors, floor < current_floor)
            
            IF floors_below is not empty THEN
                RETURN max(floors_below)  // Nearest lower floor
            ELSE
                // No floors below, reverse direction
                RETURN min(pending_floors)  // Lowest pending floor
            END IF
        
        'IDLE':
            // Calculate distances to all pending floors
            distances = []
            FOR EACH floor IN pending_floors DO
                distance = abs(floor - current_floor)
                append (floor, distance) to distances
            END FOR
            
            // Find minimum distance
            min_distance = min(distances by distance)
            
            // If tie, prefer lower floor
            candidates = filter(distances, distance == min_distance)
            RETURN min(candidates by floor)
    
    END CASE
    
END FUNCTION
```

---

## Detailed Examples

### Example 1: Moving Up with Multiple Calls

**Initial Conditions**:
- Current Floor: 1
- Direction: UP
- Pending Calls: Call_F2=1, Call_F3=1

**Analysis**:
```
pending_floors = [2, 3]
direction = UP
floors_above = [2, 3]  (both above floor 1)
next_target = min([2, 3]) = 2
```

**Result**: Elevator goes to Floor 2 first, then Floor 3

**Sequence**:
```
Floor 1 → Floor 2 (serve) → Floor 3 (serve)
```

---

### Example 2: Moving Down with Multiple Calls

**Initial Conditions**:
- Current Floor: 3
- Direction: DOWN
- Pending Calls: Call_F1=1, Call_F2=1

**Analysis**:
```
pending_floors = [1, 2]
direction = DOWN
floors_below = [1, 2]  (both below floor 3)
next_target = max([1, 2]) = 2
```

**Result**: Elevator goes to Floor 2 first, then Floor 1

**Sequence**:
```
Floor 3 → Floor 2 (serve) → Floor 1 (serve)
```

---

### Example 3: Direction Reversal

**Initial Conditions**:
- Current Floor: 2
- Direction: UP
- Pending Calls: Call_F1=1

**Analysis**:
```
pending_floors = [1]
direction = UP
floors_above = []  (no floors above 2)
// Must reverse direction
next_target = max([1]) = 1
```

**Result**: Elevator changes to DOWN direction, goes to Floor 1

**Sequence**:
```
Floor 2 → Moving Down → Floor 1 (serve)
```

---

### Example 4: Idle State Selection

**Initial Conditions**:
- Current Floor: 2
- Direction: IDLE
- Pending Calls: Call_F1=1, Call_F3=1

**Analysis**:
```
pending_floors = [1, 3]
direction = IDLE
distances = [(1, |1-2|=1), (3, |3-2|=1)]
min_distance = 1
candidates = [1, 3]  (both distance 1)
// Tie-breaker: select lower floor
next_target = 1
```

**Result**: Elevator goes to Floor 1

---

### Example 5: Current Floor Pressed

**Initial Conditions**:
- Current Floor: 2
- Direction: IDLE
- Pending Calls: Call_F2=1

**Analysis**:
```
pending_floors = [2]
Remove current floor: pending_floors = []
next_target = 0  (no movement needed)
```

**Result**: Elevator stays at Floor 2, doors open

---

## Request Queue Management

### Queue Operations

```pseudocode
// Global queue structure
request_queue = [0, 0, 0]  // [F1, F2, F3] bit flags

FUNCTION add_request(floor_number)
    request_queue[floor_number - 1] = 1
END FUNCTION

FUNCTION clear_request(floor_number)
    request_queue[floor_number - 1] = 0
END FUNCTION

FUNCTION get_pending_floors()
    pending = []
    FOR i = 1 TO 3 DO
        IF request_queue[i - 1] == 1 THEN
            append i to pending
        END IF
    END FOR
    RETURN pending
END FUNCTION
```

### Button Press Handling

```pseudocode
// Called every clock cycle
FUNCTION update_requests(call_f1, call_f2, call_f3, current_floor, reached_floor)
    
    // Add new requests (latch button presses)
    IF call_f1 == 1 THEN add_request(1)
    IF call_f2 == 1 THEN add_request(2)
    IF call_f3 == 1 THEN add_request(3)
    
    // Clear request when floor reached
    IF reached_floor == true THEN
        clear_request(current_floor)
    END IF
    
END FUNCTION
```

---

## Direction Determination

### Direction Update Logic

```pseudocode
FUNCTION update_direction(current_floor, target_floor, current_direction)
    
    IF target_floor == 0 THEN
        // No pending calls
        RETURN 'IDLE'
    
    ELSIF target_floor > current_floor THEN
        RETURN 'UP'
    
    ELSIF target_floor < current_floor THEN
        RETURN 'DOWN'
    
    ELSE
        // target_floor == current_floor
        RETURN current_direction  // Maintain direction
    
    END IF
    
END FUNCTION
```

---

## Advanced Scheduling Scenarios

### Scenario A: Call During Movement

**Situation**: Elevator moving F1 → F3, F2 is pressed mid-travel

**Algorithm Response**:
```
Initial: Moving UP to F3
New Call: F2 pressed
Priority Check:
    - Direction: UP
    - Current position: between F1 and F2
    - Pending: [2, 3]
    - Floors above current: [2, 3]
    - Next target: min([2, 3]) = 2
Action: Stop at F2, then continue to F3
```

---

### Scenario B: Opposite Direction Call

**Situation**: Elevator at F3 moving to F2, F1 is pressed

**Algorithm Response**:
```
Initial: Moving DOWN to F2
New Call: F1 pressed
Priority Check:
    - Direction: DOWN
    - Current: F3
    - Pending: [1, 2]
    - Floors below: [1, 2]
    - Next target: max([1, 2]) = 2
Action: Serve F2 first, then F1 (maintain direction)
```

---

### Scenario C: Multiple Idle Presses

**Situation**: Elevator idle at F2, all buttons pressed simultaneously

**Algorithm Response**:
```
State: IDLE at F2
Calls: [1, 2, 3]
Remove current: [1, 3]
Distances: F1=1, F3=1
Tie-breaker: Lower floor wins
Next target: F1
New direction: DOWN
Sequence: F2 → F1 → F2 → F3
```

---

## Implementation Considerations

### Hardware Implementation (Verilog)

```verilog
// Priority logic combinational block
always @(*) begin
    // Default: no target
    next_target = 2'b00;
    
    case (current_state)
        FLOOR_1: begin
            if (call_f2) next_target = 2'b01;
            else if (call_f3) next_target = 2'b10;
        end
        
        FLOOR_2: begin
            if (direction == UP) begin
                if (call_f3) next_target = 2'b10;
                else if (call_f1) next_target = 2'b00;
            end else begin
                if (call_f1) next_target = 2'b00;
                else if (call_f3) next_target = 2'b10;
            end
        end
        
        FLOOR_3: begin
            if (call_f2) next_target = 2'b01;
            else if (call_f1) next_target = 2'b00;
        end
    endcase
end
```

### Software Implementation (MATLAB)

```matlab
function target = priority_logic(current_floor, direction, calls)
    % calls = [call_f1, call_f2, call_f3]
    
    pending = find(calls == 1);  % Get floor numbers 1,2,3
    pending(pending == current_floor) = [];  % Remove current
    
    if isempty(pending)
        target = 0;
        return;
    end
    
    switch direction
        case 1  % UP
            above = pending(pending > current_floor);
            if ~isempty(above)
                target = min(above);
            else
                target = max(pending);
            end
            
        case -1  % DOWN
            below = pending(pending < current_floor);
            if ~isempty(below)
                target = max(below);
            else
                target = min(pending);
            end
            
        otherwise  % IDLE
            [~, idx] = min(abs(pending - current_floor));
            target = pending(idx);
    end
end
```

---

## Performance Metrics

### Average Wait Time
Expected wait time with priority scheduling:
```
T_wait_avg = (T_F1_to_F2 + T_F2_to_F3) / 2
For T_floor = 3 seconds:
T_wait_avg = 3 seconds
```

### Worst Case
Maximum time from call to service:
```
T_worst = 2 × T_floor × (NUM_FLOORS - 1)
For 3 floors: T_worst = 2 × 3 × 2 = 12 seconds
(Elevator at F1, call F1, but moving to F3 first)
```

### Best Case
```
T_best = 0 (already at floor)
```

---

## Comparison with Other Algorithms

### FCFS (First-Come-First-Served)
**Disadvantage**: Elevator bounces between floors inefficiently
**Example**: F1 → F3 → F2 → F1 (calls in that order)

### Priority Scheduling (This Implementation)
**Advantage**: Completes all calls in one direction before reversing
**Example**: Same calls → F1 → F2 → F3 → F1

### SCAN (Elevator Algorithm)
**Behavior**: Similar to our implementation + continues to ends
**Difference**: Our algorithm reverses earlier if no pending calls

---

## Testing Priority Logic

### Test Vectors

| Test | Cur Floor | Dir | F1 | F2 | F3 | Expected Target |
|------|-----------|-----|----|----|----|----|
| 1    | 1         | IDLE| 0  | 1  | 0  | 2  |
| 2    | 2         | UP  | 0  | 0  | 1  | 3  |
| 3    | 3         | DOWN| 1  | 1  | 0  | 2  |
| 4    | 2         | UP  | 1  | 0  | 0  | 1  |
| 5    | 1         | IDLE| 1  | 1  | 1  | 2  |
| 6    | 2         | IDLE| 1  | 0  | 1  | 1 or 3 (tie) |
| 7    | 2         | DOWN| 0  | 0  | 0  | 0  |

### Verification Checklist
- [ ] Upward priority verified
- [ ] Downward priority verified
- [ ] Direction reversal works
- [ ] Idle state tie-breaking works
- [ ] Current floor ignored
- [ ] Empty queue returns 0
- [ ] All requests eventually served


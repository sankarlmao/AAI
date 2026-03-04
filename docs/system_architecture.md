# SYSTEM ARCHITECTURE

## Block Diagram

```
+-------------------+
|  Floor Buttons    |
|  Call_F1          |
|  Call_F2          |
|  Call_F3          |
+--------+----------+
         |
         | (Button States)
         v
+-------------------+
|   Priority Logic  |
|                   |
| • Current Floor   |
| • Direction       |
| • Target Select   |
+--------+----------+
         |
         | (Next Target Floor)
         v
+-------------------+
|  State Machine    |
|   Controller      |
|                   |
| • FSM Logic       |
| • State Register  |
| • Transition Logic|
+--------+----------+
         |
         | (Motor Commands)
         v
+-------------------+
|   Motor Driver    |
|   (H-Bridge)      |
|                   |
| • IN1, IN2        |
| • Direction Ctrl  |
+--------+----------+
         |
         | (Power Signals)
         v
+-------------------+
|  Elevator Motor   |
|   (DC Motor)      |
|                   |
| • Upward Motion   |
| • Downward Motion |
+-------------------+
```

---

## Block Descriptions

### 1. Floor Buttons
**Purpose**: User interface for elevator calls

**Components**:
- Three momentary push buttons (Call_F1, Call_F2, Call_F3)
- Debouncing circuitry
- LED indicators (optional)

**Outputs**: Digital signals to Priority Logic

---

### 2. Priority Logic
**Purpose**: Intelligent request scheduling

**Functions**:
- Stores all pending floor requests
- Analyzes current elevator position
- Determines current direction of travel
- Selects next target floor based on priority rules

**Priority Rules**:
- **Moving UP**: Visit higher pending floors first
- **Moving DOWN**: Visit lower pending floors first
- **Idle**: Visit nearest floor

**Outputs**: Target floor to State Machine Controller

---

### 3. State Machine Controller
**Purpose**: Core control logic using FSM

**States**:
```
FLOOR_1      [2'b00] - At ground floor
MOVING_UP    [2'b01] - Traveling upward
FLOOR_2      [2'b10] - At first floor
MOVING_DOWN  [2'b11] - Traveling downward
FLOOR_3      [2'b100]- At top floor (3 bits for encoding)
```

**Functions**:
- Maintains current state
- Processes state transitions
- Generates motor control signals
- Updates current floor indicator

**Outputs**: Motor_Up, Motor_Down signals to Motor Driver

---

### 4. Motor Driver (H-Bridge)
**Purpose**: Bidirectional DC motor control

**Components**:
- 4 Power MOSFETs (2 P-channel, 2 N-channel)
- Gate drivers
- Shoot-through protection
- Flyback diodes

**Control Logic**:
```
Motor_Up = 1, Motor_Down = 0  → Clockwise rotation (UP)
Motor_Up = 0, Motor_Down = 1  → Counter-clockwise (DOWN)
Motor_Up = 0, Motor_Down = 0  → Motor STOP
Motor_Up = 1, Motor_Down = 1  → INVALID (prevented)
```

**Outputs**: Drive signals to motor

---

### 5. Elevator Motor
**Purpose**: Physical actuation

**Model**:
- DC motor with armature resistance (Ra)
- Inductance (La)
- Back-EMF (Ke × ω)
- Mechanical load (inertia + friction)

**Electrical Model**:
```
V_motor = I × Ra + La × (dI/dt) + Ke × ω
Torque = Kt × I
```

---

## System Timing Diagram

```
Clock     : _|‾|_|‾|_|‾|_|‾|_|‾|_|‾|_|‾|_|‾|_
Call_F3   : _____|‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
State     : F1__|__MOVING_UP__|__F2__|__MOVING_UP__|__F3
Motor_Up  : _____|‾‾‾‾‾‾‾‾‾‾‾‾‾|_____|‾‾‾‾‾‾‾‾‾‾‾‾|_____
Motor_Down: _________________________________________
Floor[1:0]: 00__|_____01______|__01__|_____10______|__10
```

---

## Data Flow

### Request Processing Flow
```
1. User presses button → Button signal goes HIGH
2. Priority Logic evaluates:
   - Current elevator position
   - Current direction
   - All pending requests
3. Priority Logic outputs next target floor
4. State Machine compares current and target:
   - If target > current → Enter MOVING_UP
   - If target < current → Enter MOVING_DOWN
   - If target = current → Stay at floor
5. Motor Driver receives motor commands
6. Motor actuates elevator movement
7. Upon reaching floor:
   - State transitions to FLOOR_X
   - Clear that floor request
   - Repeat from step 2
```

---

## Control Signal Interface

### Input Signals
| Signal    | Type    | Width | Description              |
|-----------|---------|-------|--------------------------|
| Clock     | Input   | 1     | System clock             |
| Reset     | Input   | 1     | Active-high reset        |
| Call_F1   | Input   | 1     | Floor 1 request          |
| Call_F2   | Input   | 1     | Floor 2 request          |
| Call_F3   | Input   | 1     | Floor 3 request          |

### Output Signals
| Signal        | Type    | Width | Description              |
|---------------|---------|-------|--------------------------|
| Motor_Up      | Output  | 1     | Upward motor command     |
| Motor_Down    | Output  | 1     | Downward motor command   |
| Current_Floor | Output  | 2     | Floor indicator [1:0]    |

### Internal Signals
| Signal         | Width | Description                    |
|----------------|-------|--------------------------------|
| current_state  | 3     | FSM state register             |
| next_state     | 3     | FSM next state logic           |
| target_floor   | 2     | Next destination floor         |
| direction      | 1     | 0=DOWN, 1=UP                   |
| request_queue  | 3     | Pending floor requests [3:1]   |

---

## Power Requirements

### Logic Supply
- Voltage: 3.3V or 5V (FPGA dependent)
- Current: < 100mA
- Used for: FSM, Priority Logic, I/O

### Motor Supply
- Voltage: 12V - 24V DC
- Current: 2A - 5A (motor dependent)
- Used for: H-Bridge and motor

**Note**: Logic and power supplies must be isolated with separate grounds connected at single point.

---

## Clock and Timing

### System Clock
- Frequency: 50 MHz (typical FPGA)
- Can be scaled with clock divider

### State Timing
- Each state persists for configurable clock cycles
- MOVING_UP/DOWN states: ~100-500 cycles (represents floor travel time)
- FLOOR_X states: Minimum 10 cycles (door operation simulation)

### Debouncing
- Button inputs debounced for 20ms
- Requires ~1,000,000 clock cycles @ 50MHz

---

## Safety Features

1. **Mutual Exclusion**: Motor_Up and Motor_Down cannot be HIGH simultaneously
2. **Hard Limits**: Physical limit switches at Floor_1 and Floor_3
3. **Emergency Stop**: Dedicated STOP input overrides all commands
4. **Watchdog Timer**: Detects stuck states

---

## System Configuration Parameters

```verilog
// Configurable parameters
parameter CLOCK_FREQ = 50_000_000;      // 50 MHz
parameter FLOOR_TRAVEL_TIME = 3;         // seconds
parameter FLOOR_CYCLES = CLOCK_FREQ * FLOOR_TRAVEL_TIME;
parameter DEBOUNCE_TIME = 20;            // milliseconds
parameter DEBOUNCE_CYCLES = CLOCK_FREQ * DEBOUNCE_TIME / 1000;
```

---

## Integration Checklist

- [ ] All input signals properly debounced
- [ ] Clock distribution verified
- [ ] Reset signal reaches all registers
- [ ] Motor driver supply separated from logic
- [ ] H-Bridge shoot-through protection verified
- [ ] Flyback diodes installed on motor terminals
- [ ] Current limiting implemented
- [ ] Emergency stop functional
- [ ] All state transitions tested
- [ ] Priority logic validated

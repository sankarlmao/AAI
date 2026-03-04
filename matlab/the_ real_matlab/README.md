# Elevator Call Processing System

A complete elevator control system implementation featuring state machine design, motor driver simulation, and FPGA priority logic.

## Project Structure

```
elevator-control/
├── MATLAB/Simulink Files
│   ├── elevator_state_machine.m      # State machine class implementation
│   ├── elevator_test.m               # Test script for state machine
│   ├── create_elevator_simulink_model.m     # Basic Simulink model generator
│   └── create_elevator_stateflow_model.m    # Stateflow state machine generator
│
├── LTSpice Files
│   ├── elevator_hbridge_motor_driver.asc    # LTSpice schematic
│   └── elevator_hbridge_motor_driver.sp     # SPICE netlist
│
└── FPGA Files (Verilog)
    ├── elevator_priority_logic.v     # Priority logic module
    └── elevator_priority_logic_tb.v  # Testbench
```

## Component Details

### 1. State Machine (MATLAB)

**States:**
- `FLOOR_1` - Elevator at Floor 1, door can open
- `MOVING_UP` - Elevator moving upward
- `FLOOR_2` - Elevator at Floor 2, door can open
- `MOVING_DOWN` - Elevator moving downward
- `FLOOR_3` - Elevator at Floor 3, door can open

**State Diagram:**
```
                    ┌─────────────┐
                    │   FLOOR_1   │
                    │  (Initial)  │
                    └──────┬──────┘
                           │ [call above]
                           ▼
                    ┌─────────────┐
         ┌─────────│  MOVING_UP  │─────────┐
         │ [at F2] └─────────────┘ [at F3] │
         ▼                                  ▼
  ┌─────────────┐                   ┌─────────────┐
  │   FLOOR_2   │                   │   FLOOR_3   │
  └──────┬──────┘                   └──────┬──────┘
         │ [call below]                    │ [call below]
         ▼                                  │
  ┌─────────────┐                          │
  │ MOVING_DOWN │◄─────────────────────────┘
  └─────────────┘
```

**Usage:**
```matlab
% Run the test script
elevator_test

% Or create and run manually:
elevator = elevator_state_machine();
elevator.add_call(3);
elevator.run_simulation([], 10);
```

### 2. Simulink Model

Run `create_elevator_stateflow_model.m` in MATLAB to generate the Simulink model `elevator_stateflow_model.slx`.

**Inputs:**
- `floor1_call` - Floor 1 button press
- `floor2_call` - Floor 2 button press
- `floor3_call` - Floor 3 button press

**Outputs:**
- `current_floor` - Current elevator position
- `motor_up` - Motor UP command
- `motor_down` - Motor DOWN command
- `door_open` - Door status

### 3. LTSpice H-Bridge Motor Driver

**Circuit Description:**
Full H-Bridge configuration for bidirectional DC motor control.

**Components:**
- 4 MOSFETs (2 PMOS high-side, 2 NMOS low-side)
- Gate driver logic
- DC Motor model (R + L + back-EMF)
- Flyback diodes for protection

**Operation:**
| DIR_A | DIR_B | Motor Action |
|-------|-------|--------------|
| HIGH  | LOW   | Forward (UP) |
| LOW   | HIGH  | Reverse (DOWN) |
| LOW   | LOW   | Coast/Free |
| HIGH  | HIGH  | Brake |

**Simulation:**
1. Open `elevator_hbridge_motor_driver.asc` in LTSpice
2. Or use the netlist: `elevator_hbridge_motor_driver.sp`
3. Run transient analysis: `.tran 200m`

### 4. FPGA Priority Logic (Verilog)

**Priority Algorithm:**
When multiple floors are called, the priority is determined by:
1. **Continue in current direction** - If moving UP and calls exist above, continue UP
2. **Reverse direction** - If no calls in current direction, reverse
3. **Closest call** - When IDLE, service the closest floor first

**Example: Floor 1 and Floor 3 pressed simultaneously**
- If elevator is moving UP → Go to Floor 3 first
- If elevator is moving DOWN → Go to Floor 1 first
- If elevator is IDLE at Floor 2 → Go to closest (either)

**Simulation:**
```bash
# Using Icarus Verilog
iverilog -o elevator_tb elevator_priority_logic.v elevator_priority_logic_tb.v
vvp elevator_tb

# View waveforms
gtkwave elevator_priority_tb.vcd
```

**Module Interface:**
```verilog
module elevator_priority_logic (
    input wire clk,
    input wire rst_n,
    input wire floor1_call, floor2_call, floor3_call,
    input wire at_floor1, at_floor2, at_floor3,
    input wire [1:0] current_direction,
    output reg [1:0] target_floor,
    output reg [1:0] motor_direction,
    output reg door_open,
    output reg call_serviced
);
```

## Quick Start

### MATLAB Simulation
```matlab
cd /path/to/project
elevator_test  % Run basic simulation
```

### Generate Simulink Model
```matlab
create_elevator_stateflow_model  % Creates .slx file
```

### LTSpice Simulation
1. Open LTSpice XVII
2. File → Open → `elevator_hbridge_motor_driver.asc`
3. Simulate → Run

### Verilog Simulation
```bash
# Compile and run testbench
iverilog -o elevator_sim elevator_priority_logic.v elevator_priority_logic_tb.v
vvp elevator_sim
```

## System Integration

```
┌─────────────────────────────────────────────────────────────┐
│                    ELEVATOR SYSTEM                          │
│                                                             │
│  ┌──────────┐    ┌─────────────┐    ┌─────────────────┐   │
│  │  FPGA    │    │   Control   │    │  Motor Driver   │   │
│  │ Priority │───▶│   Logic     │───▶│  (H-Bridge)     │   │
│  │  Logic   │    │(State Mach.)│    │                 │   │
│  └──────────┘    └─────────────┘    └────────┬────────┘   │
│       ▲                                       │            │
│       │                                       ▼            │
│  ┌────┴─────┐                          ┌─────────────┐    │
│  │  Floor   │                          │  DC Motor   │    │
│  │ Buttons  │                          │  (Elevator) │    │
│  └──────────┘                          └─────────────┘    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Author
Elevator Control System - March 2026

# ELEVATOR CALL PROCESSING LOGIC WITH MOTOR DRIVER SIMULATION

## PROJECT OVERVIEW

### Problem Statement
This project implements a 3-floor elevator control system with intelligent call processing, state machine-based control, and motor driver simulation. The system handles multiple simultaneous floor requests using priority scheduling based on the current direction of travel.

### Why State Machines?
State machines provide a systematic approach to modeling sequential systems like elevators where:
- The system has clearly defined states (floors and movement states)
- Transitions depend on current state and inputs (button presses)
- Outputs are determined by state (motor control signals)
- Behavior is deterministic and verifiable

### Priority Scheduling
When multiple floor buttons are pressed simultaneously, the elevator uses directional priority:
- **Moving UP**: Serves higher floors first before reversing direction
- **Moving DOWN**: Serves lower floors first before reversing direction
- **Idle**: Serves nearest floor first

This minimizes travel distance and reduces passenger wait time.

### H-Bridge Motor Driver
The H-Bridge driver enables bidirectional motor control:
- Uses 4 MOSFETs arranged in a bridge configuration
- Controls motor direction by switching diagonal MOSFET pairs
- Provides UP, DOWN, and STOP functionality
- Protects against shoot-through conditions

---

## System Specifications

### Floors
- Floor_1 (Ground Floor)
- Floor_2 (First Floor)
- Floor_3 (Second Floor)

### States
- `FLOOR_1` - Elevator at ground floor
- `MOVING_UP` - Elevator traveling upward
- `FLOOR_2` - Elevator at first floor
- `MOVING_DOWN` - Elevator traveling downward
- `FLOOR_3` - Elevator at top floor

### Inputs
- `Call_F1` - Floor 1 button
- `Call_F2` - Floor 2 button
- `Call_F3` - Floor 3 button
- `Clock` - System clock
- `Reset` - System reset (active high)

### Outputs
- `Motor_Up` - Motor upward control signal
- `Motor_Down` - Motor downward control signal
- `Current_Floor` - 2-bit floor indicator [00=F1, 01=F2, 10=F3]

---

## Project Structure

```
alan/
├── README.md                          # This file
├── docs/
│   ├── system_architecture.md         # Block diagrams and architecture
│   ├── state_machine_design.md        # FSM design details
│   ├── priority_logic.md              # Scheduling algorithm
│   ├── motor_driver.md                # H-Bridge design
│   └── project_report_outline.md     # Complete report structure
├── matlab/
│   ├── elevator_main.m                # Main simulation script
│   ├── elevator_controller.m          # State machine controller
│   ├── priority_logic.m               # Priority scheduler
│   └── motor_driver_model.m           # Motor simulation model
├── verilog/
│   ├── top_module.v                   # Top-level integration
│   ├── elevator_controller.v          # FSM implementation
│   ├── priority_logic.v               # Priority logic module
│   └── motor_driver.v                 # Motor driver interface
├── ltspice/
│   └── h_bridge_simulation.txt        # LTSpice netlist and guide
└── test_cases/
    └── test_scenarios.md              # Comprehensive test cases
```

---

## Quick Start

### MATLAB Simulation
```matlab
cd matlab/
elevator_main
```

### FPGA Synthesis (Verilog)
```bash
cd verilog/
# Synthesize with your preferred tool (Vivado, Quartus, etc.)
```

### LTSpice Motor Driver Simulation
```
1. Open ltspice/h_bridge_simulation.txt
2. Copy netlist to LTSpice
3. Run transient analysis
```

---

## Key Features

1. **Finite State Machine Control**: Robust 5-state FSM design
2. **Intelligent Priority Scheduling**: Direction-aware call processing
3. **Motor Driver Simulation**: H-Bridge circuit modeling
4. **Dual Implementation**: MATLAB and Verilog versions
5. **Comprehensive Testing**: Multiple test scenarios included
6. **FPGA-Ready**: Synthesizable Verilog HDL code

---

## Authors
Digital Design Project - Power Electronics & Control Systems

## Date
March 2026

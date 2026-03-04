# Elevator Simulink Models (SLX Folder)

This folder contains MATLAB scripts to generate working Simulink elevator models.

## Files

| Script | Model Generated | Complexity | Description |
|--------|----------------|------------|-------------|
| `create_simplest_elevator.m` | `elevator_simple.slx` | **Easiest** | Single input, basic feedback control |
| `create_basic_elevator_model.m` | `elevator_basic.slx` | Medium | Slider controls for each floor |
| `create_simple_elevator_model.m` | `elevator_system.slx` | Advanced | Full Stateflow state machine |
| `create_elevator_model.m` | `elevator_control.slx` | Advanced | MATLAB Function based controller |

---

## Quick Start (Recommended)

### 1. Run the Simplest Model

```matlab
% In MATLAB, navigate to SLX folder and run:
create_simplest_elevator
```

### 2. Use the Model

1. **Open** `elevator_simple.slx` (opens automatically)
2. **Double-click** the green `Target_Floor` block
3. **Change** the value to `1`, `2`, or `3`
4. **Click Run** (green play button)
5. **Watch** the displays show elevator movement!

---

## Model Diagram (elevator_simple.slx)

```
┌─────────────┐    ┌─────────┐    ┌─────────────┐    ┌──────────────┐    ┌────────────┐
│ Target_Floor│───▶│  Error  │───▶│ Motor_Gain  │───▶│ Motor_Limit  │───▶│ Integrator │
│   (1/2/3)   │    │  (+/-)  │    │   (0.5x)    │    │  (-1 to +1)  │    │ (Position) │
└─────────────┘    └────┬────┘    └─────────────┘    └──────┬───────┘    └─────┬──────┘
                        │                                   │                   │
                        │◄──────────────────────────────────────────────────────┘
                        │ (Feedback)                        │
                                                            ▼
                                              ┌──────────────────────────┐
                                              │     OUTPUT DISPLAYS      │
                                              │ • Current Floor (1-3)    │
                                              │ • Motor (+UP, -DOWN)     │
                                              │ • Door (1=Open, 0=Close) │
                                              └──────────────────────────┘
```

---

## How Each Model Works

### elevator_simple.slx (Simplest)
- **Input**: Target floor (1, 2, or 3)
- **Control**: PID-like feedback loop
- **Output**: Floor position, motor direction, door status
- **Best for**: Understanding basic control concepts

### elevator_basic.slx
- **Input**: Three slider gains (one per floor)
- **Control**: Weighted sum control
- **Output**: Same as simple
- **Best for**: Calling multiple floors

### elevator_system.slx (Stateflow)
- **Input**: Three constant blocks (set to 0 or 1)
- **Control**: Full state machine with 5 states
- **Output**: Same as simple
- **Best for**: Realistic state-based control

---

## State Machine States

```
FLOOR_1 ──▶ MOVING_UP ──▶ FLOOR_2 ──▶ MOVING_UP ──▶ FLOOR_3
   ▲                         │                         │
   │                         ▼                         │
   └──── MOVING_DOWN ◀────────────── MOVING_DOWN ◀─────┘
```

---

## Outputs Meaning

| Display | Value | Meaning |
|---------|-------|---------|
| Current_Floor | 1 | Elevator at Floor 1 |
| Current_Floor | 2 | Elevator at Floor 2 |
| Current_Floor | 3 | Elevator at Floor 3 |
| Motor | +ve (0.1 to 1) | Moving UP |
| Motor | -ve (-1 to -0.1) | Moving DOWN |
| Motor | 0 | Stopped |
| Door | 1 | Door OPEN |
| Door | 0 | Door CLOSED |

---

## Troubleshooting

### "Model won't open"
```matlab
% Close any open models first:
bdclose all

% Then run the script again:
create_simplest_elevator
```

### "Blocks not found"
Make sure you have Simulink installed. Check with:
```matlab
ver simulink
```

### "Stateflow not available"
Use `create_simplest_elevator.m` or `create_basic_elevator_model.m` instead - they don't require Stateflow.

---

## Author
Elevator Control System - March 2026

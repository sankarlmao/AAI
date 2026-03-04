# Elevator Call Processing – FSM Digital Circuit (MATLAB/Simulink)

## Project Overview

Finite-State Machine (FSM) for a 3-floor elevator, implemented both as a
**Stateflow chart** (high-level) and as a **digital circuit subsystem** with
D flip-flops and combinational logic gates — matching the Logisim-style layout
shown in the reference image.

---

## State Diagram

```
         RESET  ──────────────────────────────────────────┐
                                                          ↓
  ┌──────────┐  c2||c3   ┌────────────┐  c3    ┌──────────┐
  │ Floor_1  │ ────────► │ Moving_Up  │ ─────► │ Floor_3  │
  │  (IDLE)  │           │   (UP=1)   │        │  (IDLE)  │
  └──────────┘           └────────────┘        └──────────┘
       ▲                       │ c2&&~c3             │ c1||c2
       │                       ▼                     │
       │                 ┌──────────┐                │
       │         c3 ◄──  │ Floor_2  │  ──► c3        │
       │                 │  (IDLE)  │                │
       │                 └──────────┘                │
       │                       │ c1&&~c3             │
       │                       ▼                     ▼
       │               ┌──────────────┐ ◄────────────┘
       └────────────── │ Moving_Down  │
          c1 or ~c1~c2 │   (DOWN=1)   │
                       └──────────────┘
```

| State        | Q2 | Q1 | Q0 | UP | DOWN | IDLE |
|--------------|----|----|----|----|------|------|
| Floor_1      |  0 |  0 |  0 |  0 |  0   |  1   |
| Moving_Up    |  0 |  0 |  1 |  1 |  0   |  0   |
| Floor_2      |  0 |  1 |  0 |  0 |  0   |  1   |
| Moving_Down  |  0 |  1 |  1 |  0 |  1   |  0   |
| Floor_3      |  1 |  0 |  0 |  0 |  0   |  1   |

---

## Inputs & Outputs

| Signal         | Direction | Type    | Description                     |
|----------------|-----------|---------|----------------------------------|
| `c1`           | Input     | boolean | Call button – Floor 1            |
| `c2`           | Input     | boolean | Call button – Floor 2            |
| `c3`           | Input     | boolean | Call button – Floor 3            |
| `RESET`        | Input     | boolean | Synchronous reset → Floor_1      |
| `UP`           | Output    | boolean | Elevator moving upward           |
| `DOWN`         | Output    | boolean | Elevator moving downward         |
| `IDLE`         | Output    | boolean | Elevator idle at a floor         |
| `current_floor`| Output    | uint8   | Current floor (1, 2, or 3)       |

---

## Files

| File | Purpose |
|------|---------|
| `ElevatorFSM.slx`             | **Simulink model** – open directly in MATLAB |
| `create_ElevatorFSM.m`        | MATLAB script to rebuild the .slx from scratch |
| `ElevatorNextState.m`         | Combinational logic function (digital circuit layer) |
| `testbench_ElevatorFSM.m`     | Pure-MATLAB testbench (no Simulink needed) |
| `generate_ElevatorFSM_slx.py` | Python script that generated ElevatorFSM.slx |

---

## How to Open in MATLAB

```matlab
% Option 1 – open the pre-built model
open('ElevatorFSM.slx')

% Option 2 – rebuild from script (if .slx needs updating)
create_ElevatorFSM

% Option 3 – run testbench without Simulink
testbench_ElevatorFSM
```

### Recommended input blocks (for simulation)
Replace the `Inport` blocks with one of:
- **Constant** (set to 0/1) for static tests
- **Pulse Generator** for timed floor calls  
- **Manual Switch** for interactive testing

---

## Digital Circuit Architecture (mirrors Logisim image)

```
 c1 ─┐                          ┌─► nQ2 ──► DFF_Q2 ──► Q2 ─┐
 c2 ─┤   Combinational Logic    ├─► nQ1 ──► DFF_Q1 ──► Q1 ─┤
 c3 ─┤   (AND / OR / NOT gates) ├─► nQ0 ──► DFF_Q0 ──► Q0 ─┤
RST ─┤   ElevatorNextState.m    ├─► UP                      │
 Q2 ─┤                          ├─► DOWN                    │
 Q1 ─┤                          └─► IDLE                    │
 Q0 ─┘◄──────────────────────────────────────────────────────┘
              CLK (sample time = 1 s)
```

The `Digital_Circuit` subsystem inside the model contains:
- **3 × Unit Delay** blocks acting as D flip-flops (Q2, Q1, Q0)
- **MATLAB Function** block (`ElevatorNextState`) implements all AND/OR/NOT logic
- Output decode: UP = Moving_Up state, DOWN = Moving_Down, IDLE = floor states

---

## Simulation Results (testbench)

Run `testbench_ElevatorFSM` to see:

```
Tick c1     c2     c3     RST   | State          | UP   DWN  IDL
-----------------------------------------------------------------
1    0      0      0      1     | Floor_1        | 0    0    1
2    0      0      0      0     | Floor_1        | 0    0    1
3    0      0      1      0     | Floor_1        | 0    0    1
4    0      0      1      0     | Moving_Up      | 1    0    0
5    0      0      0      0     | Floor_3        | 0    0    1
6    0      1      0      0     | Floor_3        | 0    0    1
7    0      1      0      0     | Moving_Down    | 0    1    0
8    0      0      0      0     | Floor_2        | 0    0    1
9    1      0      0      0     | Floor_2        | 0    0    1
10   1      0      0      0     | Moving_Down    | 0    1    0
11   0      0      0      0     | Floor_1        | 0    0    1
```

---

## Requirements

- MATLAB **R2019b** or later  
- **Simulink** toolbox  
- **Stateflow** toolbox (for FSM chart; optional if using Digital_Circuit only)

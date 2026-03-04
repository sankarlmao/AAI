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

## HOW TO RUN - DETAILED STEP-BY-STEP GUIDE

This section provides comprehensive instructions for running all components of the elevator control system project.

---

### 📊 OPTION 1: MATLAB SIMULATION (Recommended for Beginners)

MATLAB simulation is the easiest way to visualize elevator behavior and verify control logic.

#### Prerequisites
- MATLAB R2018b or later installed
- No additional toolboxes required

#### Step-by-Step Instructions

**Step 1: Navigate to Project Directory**
```bash
# Open terminal (Linux/Mac) or Command Prompt (Windows)
cd /path/to/alan
```

**Step 2: Open MATLAB**
- **Windows**: Start → MATLAB
- **Linux/Mac**: Type `matlab` in terminal
- **Or**: Double-click MATLAB icon

**Step 3: Set Working Directory in MATLAB**
```matlab
% In MATLAB Command Window, type:
cd matlab/
% Verify you're in the correct directory:
pwd
% Should show: /path/to/alan/matlab
```

**Step 4: Run the Main Simulation**
```matlab
% Simply type and press Enter:
elevator_main
```

**Step 5: Observe the Output**

You will see:
1. **Console Output**: Real-time status updates showing:
   - Current time
   - Elevator state (Floor_1, Moving_Up, etc.)
   - Current floor number
   - Active call buttons
   - Motor control signals

   Example output:
   ```
   Time  | State         | Floor | Calls [1 2 3] | Motor [U D]
   ------|---------------|-------|---------------|-------------
    0.0  | Floor_1       |     1 | [0 0 0]       | [0 0]
    2.0  | Moving_Up     |     1 | [0 0 1]       | [1 0]
    5.0  | Floor_2       |     2 | [0 0 1]       | [0 0]
   ```

2. **Graphical Plots**: Four subplot figures appear:
   - **Plot 1**: Elevator position vs. time
   - **Plot 2**: State machine states vs. time
   - **Plot 3**: Motor control signals (Up/Down)
   - **Plot 4**: Floor call button status

3. **Results File**: `elevator_simulation_results.mat` saved in matlab/ folder

**Step 6: Analyze Results**
```matlab
% Load saved results (if needed later):
load('elevator_simulation_results.mat')

% Plot specific data:
plot(time_log, floor_log)
xlabel('Time (s)')
ylabel('Floor')
title('Elevator Position')

% Check statistics:
whos  % Shows all variables and their sizes
```

**Step 7: Modify Simulation (Optional)**

To change button presses, edit `elevator_main.m`:
```matlab
% Open the file:
edit elevator_main.m

% Find line ~55 with button_schedule:
button_schedule = [
    2.0, 3;     % At t=2s, call floor 3
    5.0, 2;     % At t=5s, call floor 2
    10.0, 1;    % At t=10s, call floor 1
    % Add your own: time, floor_number
    15.0, 3;    % Example: call floor 3 at t=15s
];

% Save file: Ctrl+S (Windows/Linux) or Cmd+S (Mac)
% Re-run: elevator_main
```

**Step 8: Test Individual Functions**

Test priority logic separately:
```matlab
% Test priority logic function:
target = priority_logic(1, 0, [0, 1, 1])
% Arguments: current_floor, direction, [call_f1, call_f2, call_f3]
% Returns: next target floor

% Test state machine:
[next_state, motor_up, motor_down, dir] = ...
    elevator_controller(1, 2, 1, 0, 0)
% Arguments: current_state, target_floor, current_floor, 
%            travel_timer, door_timer
```

#### Troubleshooting MATLAB

| Problem | Solution |
|---------|----------|
| "File not found" | Ensure you're in `matlab/` directory: `pwd` |
| "Undefined function" | Check all 4 .m files are in same folder |
| No plots appear | Type `figure` then re-run |
| Plots close immediately | Add `pause` at end of script |

---

### 💻 OPTION 2: VERILOG SIMULATION (HDL Verification)

Simulate the hardware design before FPGA implementation.

#### Prerequisites

Choose ONE of these simulators:

**Option A: Icarus Verilog (Free, Open Source)**
- **Linux**: `sudo apt-get install iverilog gtkwave`
- **Mac**: `brew install icarus-verilog gtkwave`
- **Windows**: Download from http://bleyer.org/icarus/

**Option B: ModelSim (Industry Standard)**
- Download Intel ModelSim (free Starter Edition)
- Or use Xilinx Vivado built-in simulator

**Option C: Xilinx Vivado (for Xilinx FPGAs)**
- Download from Xilinx website (free WebPACK edition)

#### Step-by-Step Instructions (Using Icarus Verilog)

**Step 1: Navigate to Verilog Directory**
```bash
cd /path/to/alan/verilog/
```

**Step 2: Compile All Verilog Files**
```bash
# Compile all modules together:
iverilog -o elevator_sim \
    top_module.v \
    elevator_controller.v \
    priority_logic.v \
    motor_driver.v

# Check for errors - should complete silently if successful
```

If you see errors:
- Check syntax in .v files
- Ensure all files are in same directory
- Verify file names match exactly

**Step 3: Run Simulation**
```bash
# Execute the compiled simulation:
vvp elevator_sim

# You will see console output:
# ========================================
#   ELEVATOR SYSTEM TESTBENCH
# ========================================
# [time] Reset released
# [time] TEST 1: Calling Floor 3
# ...
```

**Step 4: View Waveforms**

The simulation generates a waveform file. View it with GTKWave:

```bash
# If VCD file was generated (add to testbench if needed):
gtkwave elevator.vcd &
```

**To generate VCD file**, add to testbench in `top_module.v`:
```verilog
// Add inside initial block of testbench:
initial begin
    $dumpfile("elevator.vcd");
    $dumpvars(0, elevator_top_tb);
end
```

**Step 5: Analyze Waveforms in GTKWave**

1. GTKWave window opens
2. Left panel: Expand hierarchy to see signals
3. Click signals to select them
4. Click "Append" or drag to waveform viewer
5. Signals to view:
   - `clk` - Clock signal
   - `current_floor` - Floor indicator
   - `motor_in1`, `motor_in2` - Motor control
   - `led_floor` - Floor LEDs
   - `current_state` - FSM state

**Step 6: Advanced Simulation (ModelSim)**

If using ModelSim:

```bash
# Create work library:
vlib work

# Compile source files:
vlog top_module.v elevator_controller.v priority_logic.v motor_driver.v

# Simulate:
vsim -c work.elevator_top_tb -do "run -all; quit"

# Or with GUI:
vsim work.elevator_top_tb
# In ModelSim: run -all
```

**Step 7: Synthesis Check (Optional)**

Verify code is synthesizable:

**For Xilinx (Vivado):**
```tcl
# Create project:
create_project elevator_proj ./elevator_proj -part xc7a35tcpg236-1

# Add source files:
add_files {top_module.v elevator_controller.v priority_logic.v motor_driver.v}

# Run synthesis:
synth_design -top elevator_top -part xc7a35tcpg236-1
```

**For Intel (Quartus):**
1. File → New Project Wizard
2. Add all .v files
3. Set `elevator_top` as top-level entity
4. Processing → Start Compilation

#### Troubleshooting Verilog

| Problem | Solution |
|---------|----------|
| "command not found: iverilog" | Install Icarus Verilog (see Prerequisites) |
| Compilation errors | Check line numbers in error message, fix syntax |
| "unknown module" | Ensure all .v files compiled together |
| No waveform | Add `$dumpfile` and `$dumpvars` to testbench |
| Simulation hangs | Add `$finish` or timeout in testbench |

---

### ⚡ OPTION 3: LTSPICE CIRCUIT SIMULATION (Motor Driver)

Simulate the H-Bridge motor driver circuit to verify power electronics design.

#### Prerequisites
- LTSpice XVII (free download from Analog Devices)
- **Download**: https://www.analog.com/en/design-center/design-tools-and-calculators/ltspice-simulator.html
- **Platforms**: Windows, Mac, Linux (via Wine)

#### Step-by-Step Instructions

**Step 1: Install LTSpice**
- Download installer from Analog Devices
- Run installer (no special options needed)
- Launch LTSpice

**Step 2: Open the Netlist File**
```bash
# Navigate to project directory:
cd /path/to/alan/ltspice/

# Open the text file in any editor:
notepad h_bridge_simulation.txt    # Windows
gedit h_bridge_simulation.txt       # Linux
open -a TextEdit h_bridge_simulation.txt  # Mac
```

**Step 3: Copy Netlist to LTSpice**

**Method A: Import Netlist Directly**
1. In LTSpice: File → Open
2. Change file type to "All Files (*.*)"
3. Browse to `ltspice/h_bridge_simulation.txt`
4. Click Open
5. LTSpice will parse the SPICE netlist

**Method B: Create Schematic Manually**
1. File → New Schematic
2. Press `F2` to open component browser
3. Build circuit as shown in the netlist comments
4. Follow detailed instructions in `ltspice/h_bridge_simulation.txt`

**Step 4: Configure Simulation**

1. Click **Simulate** → **Edit Simulation Command**
2. Select **Transient** tab
3. Set parameters:
   - Stop time: `20ms`
   - Time to start saving data: `0`
   - Maximum timestep: `1us`
4. Click **OK**
5. Click anywhere on schematic to place `.tran` directive

**Step 5: Run Simulation**

1. Click **Run** button (running person icon) or press `F5`
2. Simulation runs - progress bar shows status
3. When complete, black waveform window appears

**Step 6: View Results**

**Add voltage traces:**
1. Click on any node (wire) in schematic
   - Click `MotorA` node → `V(MotorA)` appears in waveform
   - Click `MotorB` node → `V(MotorB)` appears in waveform

**Add current traces:**
1. Click on component (e.g., resistor Rmotor)
   - Shows `I(Rmotor)` current through motor

**Add expressions:**
1. Right-click waveform window
2. Click "Add Traces"
3. In expression box, type: `V(MotorA)-V(MotorB)`
4. This shows motor terminal voltage

**Step 7: Analyze Waveforms**

**Expected results:**
- Motor voltage: Alternates between +24V and -24V
- Motor current: Rises exponentially (L/R = 5ms time constant)
- Control signals (IN1, IN2): Square waves

**Measurements:**
1. Right-click waveform → View → FFT
2. Or add cursors: Right-click → Cursor → 1st/2nd cursor
3. Place cursors to measure rise time, peak voltage, etc.

**Step 8: Modify and Re-run**

Change component values:
1. Right-click component in schematic
2. Edit value (e.g., change Rmotor from 2Ω to 5Ω)
3. Re-run simulation (F5)
4. Compare waveforms

**Step 9: Export Results**

Save waveform data:
1. File → Export → Export data as Text
2. Choose variables to export
3. Save as CSV file
4. Import into Excel/Python/MATLAB for analysis

Save waveform image:
1. Waveform window → File → Export → Export Plot as Bitmap
2. Save as PNG/BMP
3. Include in report

#### Troubleshooting LTSpice

| Problem | Solution |
|---------|----------|
| "Unknown subcircuit" | Check MOSFET model definitions in netlist |
| Simulation too slow | Increase timestep or reduce simulation time |
| "Timestep too small" | Add `.options reltol=0.01` to netlist |
| No waveforms | Click directly on nodes/components in schematic |
| LTSpice crashes | Reduce capacitor values, simplify circuit |

---

### 🔧 OPTION 4: FPGA IMPLEMENTATION (Hardware)

Program real FPGA hardware to run the elevator controller.

#### Prerequisites

**Hardware:**
- FPGA development board (recommended):
  - Xilinx: Basys3, Nexys A7, Arty A7
  - Intel: DE10-Lite, DE0-Nano
  - Lattice: iCE40 HX8K breakout
- USB cable (usually included)
- Computer with USB port

**Software:**
- **Xilinx boards**: Vivado Design Suite (free WebPACK)
- **Intel boards**: Quartus Prime Lite (free)
- **Lattice boards**: iCEcube2 or open-source IceStorm

**Downloads:**
- Xilinx Vivado: https://www.xilinx.com/support/download.html
- Intel Quartus: https://www.intel.com/content/www/us/en/software/programmable/quartus-prime/download.html

#### Step-by-Step Instructions (Xilinx Vivado)

**Step 1: Install Vivado**
1. Download Vivado WebPACK (free version)
2. Run installer (~50GB disk space required)
3. Select "Vivado" and "WebPACK" edition
4. Install cable drivers when prompted

**Step 2: Create New Project**

Launch Vivado and follow wizard:

1. Click **Create Project**
2. Project name: `elevator_control`
3. Project location: Choose directory
4. Click **Next**

5. Project type: **RTL Project**
6. Check "Do not specify sources at this time" (we'll add later)
7. Click **Next**

8. **Default Part**: Select your FPGA board
   - Example: For Basys3, select `xc7a35tcpg236-1`
   - Or click **Boards** tab and select your board model
9. Click **Next** → **Finish**

**Step 3: Add Source Files**

1. In Flow Navigator (left panel), click **Add Sources**
2. Choose **Add or create design sources** → Next
3. Click **Add Files**
4. Navigate to `/path/to/alan/verilog/`
5. Select ALL .v files:
   - `top_module.v`
   - `elevator_controller.v`
   - `priority_logic.v`
   - `motor_driver.v`
6. Check **Copy sources into project**
7. Click **Finish**

**Step 4: Create Constraints File (Pin Mapping)**

1. **Add Sources** → **Add or create constraints**
2. Click **Create File**
3. File name: `elevator_constraints.xdc`
4. Click **OK** → **Finish**

5. Double-click `elevator_constraints.xdc` to open
6. Add pin assignments (example for Basys3):

```tcl
# Clock signal (100 MHz on Basys3)
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} [get_ports clk]

# Reset button (active low)
set_property PACKAGE_PIN U18 [get_ports rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports rst_n]

# Floor call buttons
set_property PACKAGE_PIN T18 [get_ports btn_call_f1]
set_property PACKAGE_PIN W19 [get_ports btn_call_f2]
set_property PACKAGE_PIN T17 [get_ports btn_call_f3]
set_property IOSTANDARD LVCMOS33 [get_ports btn_call_f1]
set_property IOSTANDARD LVCMOS33 [get_ports btn_call_f2]
set_property IOSTANDARD LVCMOS33 [get_ports btn_call_f3]

# Motor outputs (connect to LEDs for testing)
set_property PACKAGE_PIN U16 [get_ports motor_in1]
set_property PACKAGE_PIN E19 [get_ports motor_in2]
set_property IOSTANDARD LVCMOS33 [get_ports motor_in1]
set_property IOSTANDARD LVCMOS33 [get_ports motor_in2]

# Floor LEDs
set_property PACKAGE_PIN L1 [get_ports {led_floor[0]}]
set_property PACKAGE_PIN P1 [get_ports {led_floor[1]}]
set_property PACKAGE_PIN N3 [get_ports {led_floor[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led_floor[*]}]

# 7-segment display (cathodes)
set_property PACKAGE_PIN W7 [get_ports {seg7_display[0]}]
set_property PACKAGE_PIN W6 [get_ports {seg7_display[1]}]
set_property PACKAGE_PIN U8 [get_ports {seg7_display[2]}]
set_property PACKAGE_PIN V8 [get_ports {seg7_display[3]}]
set_property PACKAGE_PIN U5 [get_ports {seg7_display[4]}]
set_property PACKAGE_PIN V5 [get_ports {seg7_display[5]}]
set_property PACKAGE_PIN U7 [get_ports {seg7_display[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg7_display[*]}]
```

**Note**: Pin numbers vary by board. Check your board's manual!

**Step 5: Run Synthesis**

1. Flow Navigator → **SYNTHESIS**
2. Click **Run Synthesis**
3. Wait for completion (2-5 minutes)
4. When done, click **Cancel** on popup (don't run implementation yet)

Check for errors:
- Messages tab at bottom
- 0 errors = success
- If errors: Fix HDL code, re-run synthesis

**Step 6: Run Implementation**

1. Flow Navigator → **IMPLEMENTATION**
2. Click **Run Implementation**
3. Wait for completion (3-10 minutes)
4. When done, a dialog appears
5. Select **Generate Bitstream** → OK

**Step 7: Generate Bitstream**

1. Bitstream generation runs automatically
2. Wait for completion
3. Dialog appears: "Bitstream Generation successfully completed"
4. Click **Open Hardware Manager**

**Step 8: Program FPGA**

1. Connect FPGA board to computer via USB
2. Power on the board
3. In Hardware Manager, click **Open target** → **Auto Connect**
4. Vivado detects your FPGA
5. Click **Program device**
6. Bitstream file auto-selected: `elevator_control.bit`
7. Click **Program**
8. Programming takes 5-10 seconds
9. "Programming successful" message appears

**Step 9: Test on Hardware**

Your elevator controller is now running on FPGA!

**Testing:**
1. Press **Reset** button on board (usually center button)
2. Observe floor LEDs - Floor 1 should be lit
3. Press button assigned to `btn_call_f3`
4. Watch LEDs - should see motor indication
5. After ~3 seconds, Floor 2 LED lights
6. After another ~3 seconds, Floor 3 LED lights

**Debug tips:**
- If nothing happens: Check pin assignments in constraints file
- Use onboard LEDs connected to motor signals to verify output
- 7-segment display shows current floor number

#### Step-by-Step Instructions (Intel Quartus)

**Step 1-2: Create Project**
1. File → New Project Wizard
2. Set name and directory
3. Choose your FPGA device (e.g., Cyclone IV on DE10-Lite)
4. Finish wizard

**Step 3: Add Files**
1. Project → Add/Remove Files
2. Add all .v files from verilog/ folder
3. Click OK

**Step 4: Set Top-Level**
1. Right-click `top_module.v` → Set as Top-Level Entity

**Step 5: Pin Assignment**
1. Assignments → Pin Planner
2. Manually assign pins according to your board manual
3. Or import .qsf file if available

**Step 6: Compile**
1. Processing → Start Compilation
2. Wait 5-10 minutes
3. Check for errors in Messages

**Step 7: Program FPGA**
1. Tools → Programmer
2. Hardware Setup → Select USB-Blaster
3. Click Start
4. Wait for programming to complete

#### Troubleshooting FPGA

| Problem | Solution |
|---------|----------|
| Synthesis errors | Check HDL syntax, fix errors shown in log |
| "Port 'xxx' not found" | Ensure port names match between modules |
| Implementation fails | Check timing constraints, reduce clock freq |
| FPGA not detected | Install cable drivers, check USB connection |
| Nothing works on hardware | Verify pin assignments match board |
| Timing violations | Add timing constraints or reduce clock speed |

---

### 📚 OPTION 5: VIEW DOCUMENTATION

All documentation is in Markdown format and can be viewed in any text editor or Markdown viewer.

#### Using Terminal/Text Editor

```bash
# View README:
cat README.md
more README.md

# View system architecture:
cat docs/system_architecture.md

# Edit files:
nano docs/state_machine_design.md   # Linux
notepad docs/priority_logic.md      # Windows
```

#### Using VS Code (Recommended)

1. Install VS Code: https://code.visualstudio.com/
2. Open project folder: File → Open Folder → Select `/alan`
3. Install Markdown Preview:
   - Extensions → Search "Markdown All in One"
   - Install
4. View markdown: Right-click `.md` file → Open Preview

#### Using Online Markdown Viewers

1. Copy content of any `.md` file
2. Visit: https://dillinger.io/ or https://stackedit.io/
3. Paste and view formatted document

#### Generate PDF Reports

**Using Pandoc:**
```bash
# Install pandoc:
sudo apt-get install pandoc    # Linux
brew install pandoc             # Mac

# Convert to PDF:
pandoc docs/system_architecture.md -o system_architecture.pdf

# Convert to Word:
pandoc docs/state_machine_design.md -o state_machine_design.docx
```

---

### 🧪 OPTION 6: RUN TEST CASES

Execute comprehensive test scenarios to verify system functionality.

#### MATLAB Test Execution

```matlab
cd test_cases/

% Create simple test script (test_runner.m):
% Copy test cases from test_scenarios.md
% Run each scenario programmatically

% Example: Test TC-002 (F1 to F3)
cd ../matlab/
clear all;
% Modify button_schedule in elevator_main.m
% Run simulation
elevator_main
```

#### Verilog Testbench

The testbench is included in `top_module.v`:

```bash
cd verilog/

# The testbench automatically runs tests:
iverilog -o test top_module.v elevator_controller.v priority_logic.v motor_driver.v
vvp test

# Output shows test results:
# [time] TEST 1: Calling Floor 3
# [time] TEST 2: Calling Floor 1
# ...
```

#### Manual Hardware Testing

Follow test cases in `test_cases/test_scenarios.md`:

1. Program FPGA with bitstream
2. Perform each test case manually
3. Record results in test log
4. Verify expected vs. actual behavior

---

## NEXT STEPS AFTER RUNNING

### Learning Path

1. ✅ Run MATLAB simulation first (easiest)
2. ✅ Study the documentation in `docs/` folder
3. ✅ Run Verilog simulation
4. ✅ Simulate motor driver in LTSpice
5. ✅ If you have FPGA, implement on hardware
6. ✅ Customize and extend the design

### Customization Ideas

- **Change floor count**: Modify FSM for 4+ floors
- **Add door timing**: Implement door open/close logic
- **Variable speed**: Add PWM motor control
- **Multiple elevators**: Coordinate multiple cars
- **Add sensors**: Implement position feedback
- **User interface**: Add LCD display or GUI

### Report Writing

Use the outline in `docs/project_report_outline.md` to write your complete project report. Include:
- Screenshots from MATLAB plots
- Waveforms from simulation
- Photos of FPGA hardware (if implemented)
- Test results and analysis

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

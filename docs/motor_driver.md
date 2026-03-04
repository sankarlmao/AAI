# MOTOR DRIVER (H-BRIDGE) DESIGN

## Overview

The H-Bridge motor driver enables bidirectional control of the DC elevator motor. The circuit uses four switching elements (MOSFETs) configured in a bridge topology to reverse motor polarity, thus controlling direction.

---

## H-Bridge Topology

### Circuit Configuration (ASCII Diagram)

```
                    V_supply (+12V to +24V)
                         |
                         |
            +------------+------------+
            |                         |
         +--+--+                   +--+--+
         | Q1  |                   | Q2  |
         | P-CH|                   | P-CH|
         +--+--+                   +--+--+
            |                         |
    IN1 ----+                         +---- IN2
            |                         |
            +------------+------------+
                         |
                    +----+----+
                    |  MOTOR  |
                    |   M     |
                    +----+----+
                         |
            +------------+------------+
            |                         |
         +--+--+                   +--+--+
         | Q3  |                   | Q4  |
         | N-CH|                   | N-CH|
         +--+--+                   +--+--+
            |                         |
    IN1 ----+                         +---- IN2
            |                         |
            +------------+------------+
                         |
                        GND
```

### Component Details

**Q1, Q2**: P-Channel MOSFETs (High-side switches)
- Part example: IRF9540 (100V, 23A)
- Turn ON when gate is LOW
- Connected to positive supply rail

**Q3, Q4**: N-Channel MOSFETs (Low-side switches)
- Part example: IRF540 (100V, 33A)
- Turn ON when gate is HIGH
- Connected to ground rail

**Motor (M)**: DC Motor
- Voltage: 12V - 24V
- Current: 2A - 5A
- Type: Permanent Magnet DC Motor

**Flyback Diodes**: D1-D4 (body diodes in MOSFETs sufficient)
- Protect against back-EMF
- Part: 1N5822 Schottky (fast recovery)

---

## Control Truth Table

### Basic H-Bridge Control

| IN1 | IN2 | Q1 | Q2 | Q3 | Q4 | Motor Terminal A | Motor Terminal B | Motor State | Physical Direction |
|-----|-----|----|----|----|----|------------------|------------------|-------------|-------------------|
| 0   | 0   | OFF| OFF| OFF| OFF| Floating         | Floating         | COAST       | None (coasting)   |
| 1   | 0   | OFF| ON | ON | OFF| GND              | V+               | FORWARD     | UP                |
| 0   | 1   | ON | OFF| OFF| ON | V+               | GND              | REVERSE     | DOWN              |
| 1   | 1   | OFF| OFF| ON | ON | GND              | GND              | BRAKE       | Stop (brake)      |

**INVALID STATES** (must prevent):
| IN1 | IN2 | Problem |
|-----|-----|---------|
| Both HIGH sides ON | Shoot-through | Short circuit V+ to GND |

---

## Detailed Operation Modes

### Mode 1: MOTOR UP (Forward Direction)

**Control Signals**:
- IN1 = HIGH (1)
- IN2 = LOW (0)

**MOSFET States**:
- Q1 = OFF
- Q2 = ON
- Q3 = ON
- Q4 = OFF

**Current Path**:
```
V+ → Q2 → Motor(B→A) → Q3 → GND
```

**Result**: Motor rotates clockwise, elevator moves UP

---

### Mode 2: MOTOR DOWN (Reverse Direction)

**Control Signals**:
- IN1 = LOW (0)
- IN2 = HIGH (1)

**MOSFET States**:
- Q1 = ON
- Q2 = OFF
- Q3 = OFF
- Q4 = ON

**Current Path**:
```
V+ → Q1 → Motor(A→B) → Q4 → GND
```

**Result**: Motor rotates counter-clockwise, elevator moves DOWN

---

### Mode 3: BRAKE (Active Braking)

**Control Signals**:
- IN1 = HIGH (1)
- IN2 = HIGH (1)

**MOSFET States**:
- Q1 = OFF
- Q2 = OFF
- Q3 = ON
- Q4 = ON

**Current Path**:
```
Motor generates back-EMF
Current: Motor(A) → Q3 → GND
         Motor(B) → Q4 → GND
```

**Result**: Motor terminals shorted to GND, rapid deceleration

---

### Mode 4: COAST (Free-running)

**Control Signals**:
- IN1 = LOW (0)
- IN2 = LOW (0)

**MOSFET States**:
- All OFF

**Result**: Motor decelerates slowly due to friction only

---

## Gate Drive Circuit

### MOSFET Gate Requirements

**N-Channel (Q3, Q4)**:
- V_GS(threshold) ≈ 2-4V
- V_GS(operating) = 10-12V
- Drive directly from logic: Yes (if logic is 5V)

**P-Channel (Q1, Q2)**:
- V_GS(threshold) ≈ -2 to -4V
- V_GS(operating) = -10 to -12V
- Requires level shifting from logic

### Level Shifter for High-Side

```
                    V_supply
                        |
                      [R1]
                        |
Logic IN1 ----[R2]----|-+---- Gate of Q1
                      |
                    [Q_NPN]
                      |
                     GND

R1 = 10kΩ (pull-up)
R2 = 1kΩ (base resistor)
Q_NPN = 2N2222 or BC547
```

**Operation**:
- IN1 = LOW → NPN OFF → Gate pulled HIGH (Q1 OFF)
- IN1 = HIGH → NPN ON → Gate pulled LOW (Q1 ON)

---

## Protection Circuits

### 1. Shoot-Through Prevention

**Hardware Interlock**:
```
IN1_SAFE = IN1 AND NOT(IN2)
IN2_SAFE = IN2 AND NOT(IN1)
```

**Deadtime Insertion**:
- Add 1-2μs delay when switching between directions
- Ensures one MOSFET fully OFF before other turns ON

```verilog
// Verilog implementation
reg [7:0] deadtime_counter;
reg motor_enable;

always @(posedge clk) begin
    if (direction_change) begin
        deadtime_counter <= 100;  // 2μs @ 50MHz
        motor_enable <= 0;
    end else if (deadtime_counter > 0) begin
        deadtime_counter <= deadtime_counter - 1;
    end else begin
        motor_enable <= 1;
    end
end
```

---

### 2. Overcurrent Protection

**Current Sense Resistor**:
```
         Motor
           |
        [R_sense]  (0.1Ω, 5W)
           |
          GND
```

**Sense Voltage**:
```
V_sense = I_motor × R_sense
If I_max = 5A, then V_sense_max = 0.5V
```

**Comparator Circuit**:
```
V_sense → [Op-Amp Comparator] → Fault Signal
             ↑
          V_ref (0.5V threshold)
```

If V_sense > V_ref → Trigger shutdown

---

### 3. Thermal Protection

**Temperature Sensor**:
- Thermistor or IC sensor (LM35) on MOSFET heatsink
- Threshold: 85°C
- Action: Disable H-Bridge, assert error flag

---

### 4. Back-EMF Suppression

**Flyback Diodes**:
- Parallel to each MOSFET (body diode)
- External fast-recovery diodes recommended

```
        +---[Diode]---+
        |             |
      [MOSFET]   [Motor Terminal]
        |             |
        +-------------+
```

**Snubber Network** (optional, for high-speed switching):
```
   +--[R_snub]--+--[C_snub]--+
   |            |             |
[Motor_A]      GND       [Motor_B]

R_snub = 10Ω
C_snub = 100nF
```

---

## Power Supply Design

### Specifications

**Logic Supply** (for controller):
- Voltage: 5V or 3.3V
- Current: 100mA
- Source: Linear regulator (LM7805) or buck converter

**Motor Supply**:
- Voltage: 12V, 18V, or 24V (motor dependent)
- Current: 5A continuous, 10A peak
- Source: Switching power supply (high efficiency)

### Supply Decoupling

**Bulk Capacitors**:
```
V_motor_supply
      |
    [1000μF]  (electrolytic, low ESR)
      |
     GND
```

**Ceramic Capacitors** (close to MOSFETs):
```
V_motor_supply
      |
    [100nF]  (X7R ceramic, near Q1-Q4)
      |
     GND
```

---

## PCB Layout Considerations

### Critical Design Rules

1. **Power Traces**:
   - Width ≥ 100 mils (2.54mm) for 5A
   - Copper: 2oz (70μm) thickness
   - Keep motor supply traces short

2. **Ground Plane**:
   - Separate analog (sense) ground from power ground
   - Star ground connection at supply

3. **Gate Drive Traces**:
   - Keep gate traces < 5cm
   - Route away from motor power traces
   - Add series gate resistor (10Ω) to dampen ringing

4. **Thermal Management**:
   - Heatsink for Q1-Q4 (TO-220 package)
   - Thermal vias under MOSFETs
   - Adequate airflow

---

## Component Selection Guide

### MOSFETs

**Key Parameters**:
| Parameter | Requirement | Reasoning |
|-----------|-------------|-----------|
| V_DS      | ≥ 2× V_supply | Safety margin |
| I_D       | ≥ 2× I_motor_avg | Handle startup surge |
| R_DS(on)  | < 50mΩ | Minimize conduction loss |
| Q_g       | Low | Fast switching, low drive loss |

**Recommended Parts**:
- **P-Channel**: IRF9540, FQP27P06
- **N-Channel**: IRF540, IRLZ44N

---

### Gate Drivers

**Integrated H-Bridge Drivers**:
- **L298N**: Dual H-Bridge, 2A per channel, 46V
- **L293D**: Quad half-H, 1A per channel, 36V
- **DRV8871**: Single H-Bridge, 3.6A, 45V, current limiting

**High-Power Drivers** (for separate MOSFETs):
- **IR2110**: High/low side driver, bootstrap supply
- **UCC27211**: 4A gate driver

---

## Mathematical Analysis

### Power Dissipation

**Conduction Loss**:
```
P_cond = I_motor² × R_DS(on) × 2  (two MOSFETs in path)
Example: (5A)² × 0.05Ω × 2 = 2.5W
```

**Switching Loss**:
```
P_sw = (V_supply × I_motor × t_transition × f_sw) / 2
Example: (24V × 5A × 50ns × 20kHz) / 2 = 60mW
```

**Total Loss per H-Bridge**:
```
P_total = P_cond + P_sw = 2.5W + 0.06W ≈ 2.56W
```

### Heatsink Requirement

**Thermal Calculation**:
```
T_junction = T_ambient + (θ_JC + θ_CS + θ_SA) × P_total

Where:
θ_JC = Junction-to-case (0.5°C/W, from datasheet)
θ_CS = Case-to-sink (0.5°C/W, with thermal paste)
θ_SA = Sink-to-ambient (required)

If T_ambient = 40°C, T_junction_max = 150°C:
θ_SA ≤ (150 - 40)/2.56 - 0.5 - 0.5 = 42°C/W
```

Select heatsink with θ_SA < 42°C/W (or add fan)

---

## LTSpice Simulation

### Circuit Netlist

```spice
* H-Bridge Motor Driver Simulation
* Elevator Motor Control

.title H-Bridge DC Motor Driver

* Power Supply
Vsupply Vdd 0 DC 24V

* Control Inputs (Pulse sources for testing)
Vin1 IN1 0 PULSE(0 5 0 1u 1u 5m 10m)
Vin2 IN2 0 PULSE(0 5 5m 1u 1u 5m 10m)

* High-Side P-Channel MOSFETs
M1 MotorA IN1 Vdd Vdd IRF9540
M2 MotorB IN2 Vdd Vdd IRF9540

* Low-Side N-Channel MOSFETs
M3 MotorA IN1 0 0 IRF540
M4 MotorB IN2 0 0 IRF540

* DC Motor Model (R-L with back-EMF)
Rmotor MotorA MotorX 2
Lmotor MotorX MotorB 10mH
Eback MotorB MotorA DC 0  ; Back-EMF source (varies with speed)

* Flyback Diodes (external, parallel to body diodes)
D1 Vdd MotorA 1N5822
D2 Vdd MotorB 1N5822
D3 MotorA 0 1N5822
D4 MotorB 0 1N5822

* Current Sense Resistor
Rsense MotorB Vsense 0.1
Vsense_gnd Vsense 0 DC 0

* Decoupling Capacitor
Cbypass Vdd 0 1000uF IC=24V

* MOSFET Models (include library)
.lib IRF540.lib
.lib IRF9540.lib

* Diode Model
.model 1N5822 D(Is=1e-12 Rs=0.05 N=1.5 Cjo=500pF)

* Analysis
.tran 0 20ms 0 1us

* Output
.probe V(MotorA) V(MotorB) I(Rmotor) V(IN1) V(IN2)
.print tran V(MotorA) V(MotorB) I(Rmotor)

.end
```

---

## Simulation Steps (LTSpice)

### Step 1: Create Schematic
1. Open LTSpice XVII
2. File → New Schematic
3. Place components:
   - Press `F2` → type "nmos" → place Q3, Q4
   - Press `F2` → type "pmos" → place Q1, Q2
   - Press `F2` → type "voltage" → place Vsupply, Vin1, Vin2
   - Press `F2` → type "ind" → place Lmotor (10mH)
   - Press `F2` → type "res" → place Rmotor (2Ω)
   - Press `F2` → type "diode" → place D1-D4

### Step 2: Configure Components
- Right-click each MOSFET → change model to IRF540 / IRF9540
- Right-click Vsupply → DC Value = 24V
- Right-click Vin1 → PULSE(0 5 0 1u 1u 5m 10m)
- Right-click Vin2 → PULSE(0 5 5m 1u 1u 5m 10m)

### Step 3: Run Simulation
1. Click **Simulate** → Edit Simulation Command
2. Select **Transient**
3. Stop Time: 20ms
4. Time to Start Saving Data: 0
5. Click **OK**, place .tran directive on schematic
6. Run simulation (gear icon)

### Step 4: View Results
- Click on nodes to plot voltage
- Click on components to plot current
- Expected waveforms:
  - Motor voltage alternates +24V and -24V
  - Motor current rises exponentially (L-R response)

---

## Hardware Testing Procedure

### Test 1: Static Control Test
1. Apply power (no motor connected)
2. Set IN1=1, IN2=0
3. Measure: MotorA=GND, MotorB=Vsupply
4. Set IN1=0, IN2=1
5. Measure: MotorA=Vsupply, MotorB=GND

### Test 2: Motor Direction Test
1. Connect motor
2. IN1=1, IN2=0 → Verify motor rotates UP direction
3. IN1=0, IN2=1 → Verify motor rotates DOWN direction

### Test 3: Current Limit Test
1. Stall motor (hold shaft)
2. Verify overcurrent protection triggers
3. Measure I_max < specified limit

### Test 4: Thermal Test
1. Run motor continuously for 10 minutes
2. Measure MOSFET temperature
3. Verify T < 80°C

---

## Troubleshooting Guide

| Symptom | Probable Cause | Solution |
|---------|----------------|----------|
| Motor doesn't run | No gate drive voltage | Check gate signals with scope |
| Motor runs one direction only | One MOSFET failed | Test MOSFETs individually |
| Overheating | Insufficient heatsink | Add larger heatsink or fan |
| Erratic operation | Shoot-through | Add deadtime in control logic |
| Motor slow | High R_DS(on) | Use lower resistance MOSFETs |
| Noise/ringing | Poor layout | Add gate resistors, snubbers |

---

## Safety Warnings

⚠️ **HIGH VOLTAGE**: Motor supply can be 24V+
⚠️ **HIGH CURRENT**: Short circuits can cause fire
⚠️ **MOVING PARTS**: Test motor with safety guards
⚠️ **BACK-EMF**: Motor generates voltage when stopping

**Always**:
- Use current-limited power supply during testing
- Add emergency stop switch
- Isolate logic ground from motor ground
- Wear safety glasses when testing


* Elevator H-Bridge Motor Driver - LTSpice Netlist
* Simulates bidirectional DC motor control for elevator cab movement
* Author: Elevator Control System
* Date: March 2026

*==============================================================
* CIRCUIT DESCRIPTION:
* Full H-Bridge using N-channel MOSFETs with gate drivers
* Motor: 12V DC Motor (modeled as R + L series)
* Features: Direction control, PWM speed control, brake mode
*==============================================================

* Power Supply
VCC VCC 0 DC 12V

* Direction Control Signals (from FPGA/Controller)
* DIR_A = High, DIR_B = Low -> Motor Forward (UP)
* DIR_A = Low, DIR_B = High -> Motor Reverse (DOWN)
* DIR_A = DIR_B -> Brake

* Test signals - Forward then Reverse
V_DIR_A DIR_A 0 PULSE(0 5 0 1n 1n 50m 100m)
V_DIR_B DIR_B 0 PULSE(5 0 0 1n 1n 50m 100m)

* PWM Enable Signal (speed control)
V_PWM PWM 0 PULSE(0 5 0 10u 10u 40u 100u)

*==============================================================
* H-BRIDGE MOSFET CONFIGURATION
*==============================================================

* High-side switches (P-channel MOSFETs)
* M_HS1: Connects V+ to Motor terminal A
M_HS1 VCC GATE_HS1 MOTOR_A MOTOR_A PMOS_POWER W=10m L=0.5u
* M_HS2: Connects V+ to Motor terminal B  
M_HS2 VCC GATE_HS2 MOTOR_B MOTOR_B PMOS_POWER W=10m L=0.5u

* Low-side switches (N-channel MOSFETs)
* M_LS1: Connects Motor terminal A to GND
M_LS1 MOTOR_A GATE_LS1 0 0 NMOS_POWER W=10m L=0.5u
* M_LS2: Connects Motor terminal B to GND
M_LS2 MOTOR_B GATE_LS2 0 0 NMOS_POWER W=10m L=0.5u

*==============================================================
* GATE DRIVER LOGIC
*==============================================================

* AND gates for PWM control with direction
* HS1 gate: Active when DIR_A=0 AND PWM=1 (inverted for PMOS)
E_G_HS1 GATE_HS1_PRE 0 VALUE={IF(V(DIR_A)<2.5 & V(PWM)>2.5, 0, 5)}
R_G_HS1 GATE_HS1_PRE GATE_HS1 10

* HS2 gate: Active when DIR_B=0 AND PWM=1 (inverted for PMOS)
E_G_HS2 GATE_HS2_PRE 0 VALUE={IF(V(DIR_B)<2.5 & V(PWM)>2.5, 0, 5)}
R_G_HS2 GATE_HS2_PRE GATE_HS2 10

* LS1 gate: Active when DIR_B=1 AND PWM=1
E_G_LS1 GATE_LS1_PRE 0 VALUE={IF(V(DIR_B)>2.5 & V(PWM)>2.5, 5, 0)}
R_G_LS1 GATE_LS1_PRE GATE_LS1 10

* LS2 gate: Active when DIR_A=1 AND PWM=1
E_G_LS2 GATE_LS2_PRE 0 VALUE={IF(V(DIR_A)>2.5 & V(PWM)>2.5, 5, 0)}
R_G_LS2 GATE_LS2_PRE GATE_LS2 10

*==============================================================
* MOTOR MODEL (DC Motor equivalent circuit)
*==============================================================

* Motor armature resistance
R_MOTOR MOTOR_A MOTOR_MID 2

* Motor armature inductance
L_MOTOR MOTOR_MID MOTOR_B 5m IC=0

* Back-EMF source (proportional to motor current/speed)
* Simplified model - in reality would be f(speed)
E_BEMF MOTOR_B MOTOR_BEMF VALUE={0.1*I(L_MOTOR)}
R_BEMF MOTOR_BEMF 0 1MEG

*==============================================================
* FLYBACK DIODES (freewheeling diodes)
*==============================================================

D_FW1 0 MOTOR_A DIODE_FW
D_FW2 MOTOR_A VCC DIODE_FW
D_FW3 0 MOTOR_B DIODE_FW
D_FW4 MOTOR_B VCC DIODE_FW

*==============================================================
* CURRENT SENSE (for overcurrent protection)
*==============================================================

R_SENSE 0 SENSE_OUT 0.1
V_SENSE_DUMMY SENSE_OUT 0 DC 0
E_CURRENT I_SENSE 0 VALUE={ABS(I(V_SENSE_DUMMY))}

*==============================================================
* MOSFET MODELS
*==============================================================

.MODEL NMOS_POWER NMOS (VTO=2 KP=0.5 LAMBDA=0.01)
.MODEL PMOS_POWER PMOS (VTO=-2 KP=0.25 LAMBDA=0.01)
.MODEL DIODE_FW D (IS=1E-14 RS=0.01 BV=100)

*==============================================================
* SIMULATION COMMANDS
*==============================================================

.TRAN 0 200m 0 10u
.OPTIONS RELTOL=0.01 ABSTOL=1n VNTOL=1m

*==============================================================
* MEASUREMENT COMMANDS
*==============================================================

.MEAS TRAN I_MOTOR_MAX MAX I(L_MOTOR)
.MEAS TRAN I_MOTOR_AVG AVG I(L_MOTOR)
.MEAS TRAN V_MOTOR_MAX MAX V(MOTOR_A,MOTOR_B)

.END

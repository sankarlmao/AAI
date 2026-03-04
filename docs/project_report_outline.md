# PROJECT REPORT OUTLINE

## ELEVATOR CALL PROCESSING LOGIC WITH MOTOR DRIVER SIMULATION

**A Complete Mini-Project on Digital Design and Control Systems**

---

## DOCUMENT STRUCTURE

---

### FRONT MATTER

#### Title Page
- Project Title: ELEVATOR CALL PROCESSING LOGIC WITH MOTOR DRIVER SIMULATION
- Subtitle: 3-Floor Elevator System with FSM Control and H-Bridge Motor Driver
- Course: Digital Design / Control Systems / Power Electronics
- Authors: [Student Names]
- Instructor: [Instructor Name]
- Institution: [University Name]
- Date: March 2026

#### Abstract (200-300 words)
**Content:**
- Problem statement: Need for intelligent elevator control
- Approach: Finite state machine with priority scheduling
- Implementation: MATLAB simulation and Verilog HDL for FPGA
- Key results: Successful simulation and hardware validation
- Conclusion: System meets all functional requirements

**Keywords:** Finite State Machine, Elevator Control, Priority Scheduling, H-Bridge Driver, FPGA, Verilog, MATLAB

#### Acknowledgments
- Thank advisors, lab assistants, teammates
- Acknowledge resources and tools used

#### Table of Contents
- Auto-generated with page numbers
- Include all sections and sub-sections
- List of Figures
- List of Tables
- List of Abbreviations

---

## CHAPTER 1: INTRODUCTION

### 1.1 Background
**Content:**
- Elevator systems as embedded control applications
- Importance of safety and efficiency
- Role of digital logic in modern elevators

### 1.2 Problem Statement
**Content:**
- Challenge: Control 3-floor elevator with multiple simultaneous calls
- Requirements: Priority scheduling, safe motor control, user interface
- Constraints: Real-time operation, hardware limitations

### 1.3 Objectives
**Primary Objectives:**
1. Design 5-state FSM for elevator control
2. Implement priority scheduling algorithm
3. Simulate H-Bridge motor driver
4. Validate in MATLAB and Verilog/FPGA

**Secondary Objectives:**
1. Ensure safety (shoot-through prevention)
2. Optimize travel time
3. Provide clear status indication

### 1.4 Scope and Limitations
**Scope:**
- 3 floors only (scalable to more)
- Single elevator car
- Simplified motor model
- Digital control only

**Limitations:**
- No door interlocking (simplified)
- No load sensing
- Fixed travel times

### 1.5 Report Organization
- Chapter summaries
- Guide to reading the report

---

## CHAPTER 2: LITERATURE REVIEW AND BACKGROUND

### 2.1 Elevator Control Systems
**Content:**
- History of elevator automation
- Modern elevator control strategies
- Industry standards (ASME A17.1)

### 2.2 Finite State Machines
**Content:**
- FSM theory and classification (Moore vs. Mealy)
- Application to control systems
- State encoding strategies

**Include:**
- FSM definition diagram
- Comparison table: Moore vs. Mealy

### 2.3 Scheduling Algorithms
**Content:**
- First-Come-First-Served (FCFS)
- Shortest Seek Time First (SSTF)
- SCAN (Elevator Algorithm)
- LOOK algorithm
- Comparison and selection justification

**Table:** Algorithm comparison (average wait time, complexity)

### 2.4 DC Motor Control
**Content:**
- DC motor principles
- H-Bridge topology
- PWM speed control
- Back-EMF and motor dynamics

**Include:**
- Motor equivalent circuit
- H-Bridge schematic

### 2.5 FPGA Implementation
**Content:**
- FPGA architecture overview
- HDL design flow
- Synthesis and implementation
- Advantages for control applications

---

## CHAPTER 3: SYSTEM DESIGN AND ARCHITECTURE

### 3.1 System Overview
**Content:**
- High-level block diagram
- Data flow description
- Interface specifications

**Figure 3.1:** System block diagram

### 3.2 Requirements Analysis
**Functional Requirements:**
- FR-1: Move between three floors
- FR-2: Process multiple call requests
- FR-3: Implement priority scheduling
- FR-4: Control motor bidirectionally
- FR-5: Display current floor

**Non-Functional Requirements:**
- NFR-1: Response time < 1 second
- NFR-2: No missed calls
- NFR-3: Safe motor operation (no shoot-through)

**Table 3.1:** Requirements traceability matrix

### 3.3 System Architecture
**Content:**
- Hierarchical module decomposition
- Inter-module interfaces
- Timing and synchronization

**Figure 3.2:** Architecture hierarchy diagram

### 3.4 Design Decisions
**Content:**
- Choice of Moore FSM (rationale)
- Priority algorithm selection (SCAN-like)
- Motor driver safety features
- Clock frequency selection (50 MHz)

**Table 3.2:** Design decision justification

---

## CHAPTER 4: FINITE STATE MACHINE DESIGN

### 4.1 State Identification
**Content:**
- 5 states defined: FLOOR_1, MOVING_UP, FLOOR_2, MOVING_DOWN, FLOOR_3
- State descriptions and characteristics

### 4.2 State Encoding
**Content:**
- Binary encoding scheme (3 bits for 5 states)
- Encoding table
- Unused state handling

**Table 4.1:** State encoding

### 4.3 State Transition Logic
**Content:**
- Transition conditions
- Complete state transition table
- Timing constraints

**Table 4.2:** State transition table  
**Figure 4.1:** State transition diagram (ASCII or graphical)

### 4.4 Output Logic
**Content:**
- Moore machine outputs
- Motor control generation
- Floor indicator logic

**Table 4.3:** Output logic table

### 4.5 FSM Verification
**Content:**
- State reachability analysis
- Completeness check
- Safety properties

---

## CHAPTER 5: PRIORITY SCHEDULING ALGORITHM

### 5.1 Algorithm Requirements
**Content:**
- Minimize average wait time
- Maintain direction efficiency
- Fairness considerations

### 5.2 Algorithm Description
**Content:**
- Detailed pseudocode
- Flowchart
- Example scenarios

**Figure 5.1:** Priority logic flowchart  
**Algorithm 5.1:** Priority scheduling pseudocode

### 5.3 Priority Rules
**Content:**
- Rule 1: Directional continuity
- Rule 2: Nearest floor when idle
- Rule 3: Request queuing

**Table 5.1:** Rule application examples

### 5.4 Request Queue Management
**Content:**
- Latching logic
- Clearing conditions
- Persistence across states

### 5.5 Performance Analysis
**Content:**
- Average wait time calculation
- Best/worst case scenarios
- Comparison with FCFS

**Table 5.2:** Performance metrics comparison

---

## CHAPTER 6: MOTOR DRIVER DESIGN

### 6.1 H-Bridge Topology
**Content:**
- Circuit configuration
- Component selection
- Power supply design

**Figure 6.1:** H-Bridge schematic with components

### 6.2 Control Strategy
**Content:**
- Truth table
- Direction control
- Braking modes

**Table 6.1:** H-Bridge truth table

### 6.3 Safety Features
**Content:**
- Shoot-through prevention
- Deadtime insertion
- Overcurrent protection
- Thermal management

**Figure 6.2:** Deadtime timing diagram

### 6.4 Power Loss Analysis
**Content:**
- Conduction loss calculation
- Switching loss calculation
- Thermal resistance analysis

**Equation 6.1:** Power dissipation formula  
**Table 6.2:** Power loss breakdown

### 6.5 Component Selection
**Content:**
- MOSFET specifications
- Gate driver selection
- Diode selection
- Capacitor sizing

**Table 6.3:** Bill of materials (BOM)

---

## CHAPTER 7: MATLAB SIMULATION

### 7.1 Simulation Environment
**Content:**
- MATLAB version and toolboxes
- Simulation parameters
- File structure

### 7.2 Implementation Details
**Content:**
- Main simulation script (elevator_main.m)
- Controller function (elevator_controller.m)
- Priority logic (priority_logic.m)
- Motor model (motor_driver_model.m)

**Code Listing 7.1:** Key MATLAB code snippets

### 7.3 Simulation Results
**Content:**
- Test scenario 1: Single call
- Test scenario 2: Multiple calls
- Test scenario 3: Direction reversal

**Figure 7.1:** Floor position vs. time  
**Figure 7.2:** State transitions vs. time  
**Figure 7.3:** Motor control signals

### 7.4 Analysis and Discussion
**Content:**
- Behavior verification
- Timing analysis
- Priority logic validation

**Table 7.1:** Simulation test results summary

---

## CHAPTER 8: VERILOG IMPLEMENTATION

### 8.1 HDL Design Methodology
**Content:**
- Modular design approach
- Coding guidelines
- Synthesis considerations

### 8.2 Module Descriptions
**Content:**
- elevator_controller.v
- priority_logic.v
- motor_driver.v
- top_module.v
- Testbench

**Code Listing 8.1-8.4:** Verilog module headers

### 8.3 Simulation and Verification
**Content:**
- Testbench design
- Waveform analysis
- Functional coverage

**Figure 8.1:** ModelSim waveform screenshot  
**Table 8.1:** Simulation test coverage

### 8.4 Synthesis Results
**Content:**
- Resource utilization
- Timing analysis
- Power estimation

**Table 8.2:** FPGA resource usage  
**Table 8.3:** Timing report summary

---

## CHAPTER 9: LTSPICE MOTOR DRIVER SIMULATION

### 9.1 Circuit Modeling
**Content:**
- SPICE netlist
- Component models
- DC motor model

**Code Listing 9.1:** LTSpice netlist

### 9.2 Simulation Setup
**Content:**
- Transient analysis configuration
- Test signal generation
- Measurement probes

### 9.3 Results and Analysis
**Content:**
- Voltage waveforms
- Current waveforms
- Power dissipation

**Figure 9.1:** Motor voltage waveform  
**Figure 9.2:** Motor current waveform  
**Figure 9.3:** MOSFET gate signals

### 9.4 Design Validation
**Content:**
- H-Bridge operation verification
- Shoot-through check
- Thermal analysis

---

## CHAPTER 10: FPGA IMPLEMENTATION AND TESTING

### 10.1 Target Platform
**Content:**
- FPGA board specifications (e.g., Basys3, DE10-Lite)
- Pin assignments
- Clock configuration

**Table 10.1:** Pin assignment table

### 10.2 Implementation Flow
**Content:**
- Synthesis
- Place and route
- Bitstream generation
- Programming

**Figure 10.1:** Implementation flow diagram

### 10.3 Hardware Testing
**Content:**
- Test setup description
- Button interface
- Motor driver connection
- Status LEDs and display

**Figure 10.2:** Hardware test setup photo

### 10.4 Test Results
**Content:**
- Execution of test cases
- Timing measurements
- Failure modes (if any)

**Table 10.2:** Hardware test results

---

## CHAPTER 11: RESULTS AND DISCUSSION

### 11.1 Functional Verification
**Content:**
- All requirements met
- Test case pass/fail summary
- Behavior analysis

**Table 11.1:** Requirements verification matrix

### 11.2 Performance Evaluation
**Content:**
- Average response time
- Travel time analysis
- Priority algorithm effectiveness

**Table 11.2:** Performance metrics

### 11.3 Comparison: MATLAB vs. Verilog
**Content:**
- Behavioral consistency
- Timing discrepancies (if any)
- Implementation tradeoffs

### 11.4 Design Challenges and Solutions
**Content:**
- Challenge 1: Timing synchronization → Solution
- Challenge 2: Shoot-through risk → Solution
- Challenge 3: State coverage → Solution

### 11.5 Limitations and Observations
**Content:**
- Simplified motor model
- Fixed travel times
- Scalability considerations

---

## CHAPTER 12: CONCLUSION AND FUTURE WORK

### 12.1 Summary of Achievements
**Content:**
- Successful FSM design and implementation
- Working priority scheduling
- Functional motor driver simulation
- Validated in MATLAB, Verilog, and FPGA

### 12.2 Contributions
**Content:**
- Complete working elevator control system
- Comprehensive documentation
- Reusable HDL modules

### 12.3 Future Enhancements
**Proposed Improvements:**
1. **Multi-Elevator System:** Coordinate multiple cars
2. **Load Sensing:** Adjust travel time based on weight
3. **Energy Optimization:** Regenerative braking implementation
4. **Advanced Scheduling:** AI-based predictive algorithms
5. **Door Control:** Full interlocking and safety logic
6. **Variable Speed:** PWM-based motor speed control
7. **Remote Monitoring:** IoT integration
8. **Fault Diagnosis:** Self-testing and error reporting

### 12.4 Lessons Learned
**Content:**
- Importance of modular design
- Value of simulation before hardware
- Safety-critical design considerations

### 12.5 Closing Remarks
**Content:**
- Project impact
- Educational value
- Practical applications

---

## REFERENCES

**Format:** IEEE style

**Sample References:**
1. J. Smith, "Elevator Control Systems," IEEE Trans. Industrial Electronics, vol. 45, no. 3, pp. 234-245, Mar. 2018.
2. A. Johnson, Digital Design Principles, 3rd ed. New York: McGraw-Hill, 2020.
3. Texas Instruments, "H-Bridge Motor Driver Design Guide," Application Note AN-1001, 2021.
4. Xilinx, "FPGA Design Flow for Beginners," User Guide UG231, v2.5, 2022.
5. ASME A17.1, "Safety Code for Elevators and Escalators," American Society of Mechanical Engineers, 2019.

---

## APPENDICES

### Appendix A: Complete Code Listings

#### A.1 MATLAB Code
- elevator_main.m (full listing)
- elevator_controller.m
- priority_logic.m
- motor_driver_model.m

#### A.2 Verilog Code
- top_module.v (full listing)
- elevator_controller.v
- priority_logic.v
- motor_driver.v

#### A.3 LTSpice Netlist
- Complete SPICE netlist

### Appendix B: Test Results
- Complete test execution logs
- Waveform screenshots
- Hardware test photos

### Appendix C: Design Documents
- Detailed timing diagrams
- PCB layout (if implemented)
- Mechanical interface specifications

### Appendix D: User Manual
- FPGA programming instructions
- Button operation guide
- LED indicator meanings
- Troubleshooting guide

### Appendix E: Data Sheets
- FPGA board datasheet
- MOSFET datasheets (IRF540, IRF9540)
- Other component specifications

---

## DOCUMENT FORMATTING GUIDELINES

### General Format
- Font: Times New Roman, 12pt body text
- Headings: Bold, larger font (14-18pt)
- Line spacing: 1.5 or Double
- Margins: 1 inch all sides
- Page numbers: Bottom center

### Figures and Tables
- All figures numbered sequentially (Figure 1.1, Figure 2.1, etc.)
- All tables numbered separately (Table 1.1, Table 2.1, etc.)
- Captions below figures, above tables
- Referenced in text before appearing

### Code Listings
- Use monospace font (Courier New, 10pt)
- Syntax highlighting (optional)
- Line numbers for reference
- Brief description above code

### Equations
- Use equation editor
- Numbered sequentially: (1), (2), etc.
- Centered on page
- Variables defined after first use

---

## PAGE COUNT ESTIMATE

- Front Matter: 3-5 pages
- Chapter 1 (Introduction): 5-7 pages
- Chapter 2 (Literature Review): 8-10 pages
- Chapter 3 (System Design): 10-12 pages
- Chapter 4 (FSM Design): 8-10 pages
- Chapter 5 (Priority Logic): 7-9 pages
- Chapter 6 (Motor Driver): 10-12 pages
- Chapter 7 (MATLAB): 8-10 pages
- Chapter 8 (Verilog): 10-12 pages
- Chapter 9 (LTSpice): 6-8 pages
- Chapter 10 (FPGA): 8-10 pages
- Chapter 11 (Results): 10-12 pages
- Chapter 12 (Conclusion): 4-6 pages
- References: 2-3 pages
- Appendices: 20-30 pages

**Total Estimated Pages:** 120-160 pages

---

## SUBMISSION CHECKLIST

- [ ] All chapters complete
- [ ] All figures numbered and captioned
- [ ] All tables numbered and captioned
- [ ] All code tested and included
- [ ] References formatted correctly
- [ ] Table of contents generated
- [ ] Page numbers inserted
- [ ] Spell check completed
- [ ] Peer review conducted
- [ ] Instructor review incorporated
- [ ] Final PDF generated
- [ ] Source files archived

---

## PRESENTATION OUTLINE (Optional)

If presenting this project, use the following structure:

**Slide 1:** Title slide  
**Slides 2-3:** Problem and motivation  
**Slides 4-5:** System architecture  
**Slides 6-8:** FSM design and transitions  
**Slides 9-10:** Priority scheduling  
**Slides 11-12:** Motor driver  
**Slides 13-15:** MATLAB simulation results  
**Slides 16-18:** Verilog implementation  
**Slides 19-20:** FPGA demo (photos/video)  
**Slide 21:** Results summary  
**Slide 22:** Conclusions and future work  
**Slide 23:** Questions

**Total:** ~23 slides for 15-20 minute presentation

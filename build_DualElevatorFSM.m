%% ============================================================
%  build_DualElevatorFSM.m
%  Run this in MATLAB to create DualElevatorFSM.slx
%  Requires: Simulink  (no Stateflow needed)
%
%  TWO Elevators  (A and B) — 3 Floors each
%  Priority Controller assigns each floor call to the best elevator:
%    Rule 1 – Already at that floor → assign immediately
%    Rule 2 – Idle & closer         → assign to nearest idle
%    Rule 3 – Only one idle         → assign to idle one
%    Rule 4 – Both busy / tie       → assign to Elevator A
%
%  Inputs  : c1, c2, c3 (floor call buttons), RESET
%  Outputs : UP/DOWN/IDLE/Floor for Elevator A and Elevator B
%% ============================================================

mdl = 'DualElevatorFSM';

%% -- clean up ------------------------------------------------
if bdIsLoaded(mdl), close_system(mdl,0); end
new_system(mdl);
open_system(mdl);

set_param(mdl,'SolverType','Fixed-step','Solver','FixedStepDiscrete',...
              'FixedStep','1','StopTime','40',...
              'SaveTime','on','SaveOutput','on');

%% ============================================================
%  LAYOUT MAP
%
%  x= 50  : Call inputs   (c1,c2,c3,RESET)
%  x= 50  : Delayed FB    (floorA_d, floorB_d, IDLE_A_d, IDLE_B_d)
%  x=180  : Priority Controller  (MATLAB Function)
%  x=420  : Elevator A FSM       (MATLAB Function)
%  x=420  : Elevator B FSM       (MATLAB Function)
%  x=640  : Unit Delay (feedback floorA, floorB, IDLE_A, IDLE_B)
%  x=760  : Displays + Scope
%% ============================================================

%% ── 1. CALL INPUT CONSTANTS (c1 c2 c3 RESET) ───────────────
callNames = {'c1','c2','c3','RESET'};
callY     = [50 120 190 260];
callH     = zeros(1,4);
for k = 1:4
    blk = [mdl '/' callNames{k}];
    add_block('simulink/Sources/Constant', blk, ...
              'Value','0','OutDataTypeStr','boolean', ...
              'Position',[50, callY(k), 100, callY(k)+24]);
    callH(k) = get_param(blk,'Handle');
end

%% ── 2. DELAYED FEEDBACK INPUTS (fed from Unit Delays) ───────
%  These break the algebraic loop.
%  Initial values: Elev A starts at floor 1, Elev B starts at floor 1
fbNames = {'floorA_d','floorB_d','IDLE_A_d','IDLE_B_d'};
fbY     = [360 430 500 570];
fbInit  = {'1','1','true','true'};   % both start idle at floor 1
fbType  = {'int8','int8','boolean','boolean'};
fbH     = zeros(1,4);
for k = 1:4
    blk = [mdl '/FB_' fbNames{k}];
    add_block('simulink/Discrete/Unit Delay', blk, ...
              'SampleTime','1', ...
              'InitialCondition', fbInit{k}, ...
              'OutDataTypeStr', fbType{k}, ...
              'Position',[50, fbY(k), 100, fbY(k)+24]);
    fbH(k) = get_param(blk,'Handle');
end

%% ── 3. PRIORITY CONTROLLER BLOCK ────────────────────────────
%  Inputs  (8): c1,c2,c3,  floorA_d, floorB_d, IDLE_A_d, IDLE_B_d, RESET
%  Outputs (6): cA1,cA2,cA3,  cB1,cB2,cB3
prioBlk = [mdl '/Priority_Controller'];
add_block('simulink/User-Defined Functions/MATLAB Function', prioBlk, ...
          'Position',[180, 40, 390, 610], ...
          'BackgroundColor','yellow');

prioCode = [
"function [cA1,cA2,cA3, cB1,cB2,cB3] = Priority_Controller("
"                           c1,c2,c3, floorA,floorB, idleA,idleB, RESET)"
"% Priority Controller — assigns floor calls to Elevator A or B"
"% Rule 1: elevator already AT the called floor → wins"
"% Rule 2: idle & closest                       → wins"
"% Rule 3: only one idle                        → gets the call"
"% Rule 4: tie / both busy                      → Elevator A wins"
""
"calls = [logical(c1), logical(c2), logical(c3)];"
"fA    = double(floorA);   % current floor of elevator A (0 = moving)"
"fB    = double(floorB);"
""
"cA1=false; cA2=false; cA3=false;"
"cB1=false; cB2=false; cB3=false;"
"cA = [cA1,cA2,cA3];"
"cB = [cB1,cB2,cB3];"
""
"if RESET"
"    cA1=false;cA2=false;cA3=false;"
"    cB1=false;cB2=false;cB3=false;"
"    return;"
"end"
""
"for fl = 1:3"
"    if ~calls(fl), continue; end"
"    distA = abs(fA - fl);   % 0 if already there or if fA=0 (moving)"
"    distB = abs(fB - fl);"
"    % if moving (floor=0) treat as worst priority (distance=10)"
"    if fA == 0, distA = 10; end"
"    if fB == 0, distB = 10; end"
""
"    % Decide assignment"
"    if distA <= distB && idleA"
"        assignA = true;              % A is idle and closer (or equal)"
"    elseif distB < distA && idleB"
"        assignA = false;             % B is idle and closer"
"    elseif idleA && ~idleB"
"        assignA = true;              % only A is idle"
"    elseif ~idleA && idleB"
"        assignA = false;             % only B is idle"
"    else"
"        assignA = true;              % tie / both busy → A wins"
"    end"
""
"    if assignA"
"        cA(fl) = true;"
"    else"
"        cB(fl) = true;"
"    end"
"end"
""
"cA1=cA(1); cA2=cA(2); cA3=cA(3);"
"cB1=cB(1); cB2=cB(2); cB3=cB(3);"
];

%% ── 4. ELEVATOR A FSM BLOCK ──────────────────────────────────
%  Inputs  (4): cA1, cA2, cA3, RESET
%  Outputs (4): UP_A, DOWN_A, IDLE_A, floor_A
elevABlk = [mdl '/Elevator_A'];
add_block('simulink/User-Defined Functions/MATLAB Function', elevABlk, ...
          'Position',[420, 40, 620, 290], ...
          'BackgroundColor','cyan');

elevCode_A = [
"function [UP, DOWN, IDLE, floor_num] = Elevator_A(c1,c2,c3,RESET)"
"% Elevator A FSM  — 3 floors"
"% States: 0=Floor_1  1=Moving_Up  2=Floor_2  3=Moving_Down  4=Floor_3"
"persistent state;"
"if isempty(state), state = int8(0); end"
""
"UP       = (state == int8(1));"
"DOWN     = (state == int8(3));"
"IDLE     = (state==int8(0)) || (state==int8(2)) || (state==int8(4));"
"if     state==int8(0), floor_num = int8(1);"
"elseif state==int8(2), floor_num = int8(2);"
"elseif state==int8(4), floor_num = int8(3);"
"else,                  floor_num = int8(0); end"
""
"if RESET, state=int8(0); return; end"
""
"switch state"
"  case int8(0)  % Floor_1"
"    if c2||c3, state=int8(1); end"
"  case int8(1)  % Moving_Up"
"    if c3,        state=int8(4);"
"    else,         state=int8(2); end"
"  case int8(2)  % Floor_2"
"    if c3,        state=int8(1);"
"    elseif c1,    state=int8(3); end"
"  case int8(3)  % Moving_Down"
"    if c2&&~c1,   state=int8(2);"
"    else,         state=int8(0); end"
"  case int8(4)  % Floor_3"
"    if c1||c2,    state=int8(3); end"
"end"
];

%% ── 5. ELEVATOR B FSM BLOCK ──────────────────────────────────
%  Starts at Floor 3 (so both elevators spread across floors)
elevBBlk = [mdl '/Elevator_B'];
add_block('simulink/User-Defined Functions/MATLAB Function', elevBBlk, ...
          'Position',[420, 330, 620, 580], ...
          'BackgroundColor','magenta');

elevCode_B = [
"function [UP, DOWN, IDLE, floor_num] = Elevator_B(c1,c2,c3,RESET)"
"% Elevator B FSM  — 3 floors  (starts at Floor_3)"
"% States: 0=Floor_1  1=Moving_Up  2=Floor_2  3=Moving_Down  4=Floor_3"
"persistent state;"
"if isempty(state), state = int8(4); end   % start at Floor_3"
""
"UP       = (state == int8(1));"
"DOWN     = (state == int8(3));"
"IDLE     = (state==int8(0)) || (state==int8(2)) || (state==int8(4));"
"if     state==int8(0), floor_num = int8(1);"
"elseif state==int8(2), floor_num = int8(2);"
"elseif state==int8(4), floor_num = int8(3);"
"else,                  floor_num = int8(0); end"
""
"if RESET, state=int8(4); return; end   % reset B to Floor_3"
""
"switch state"
"  case int8(0)  % Floor_1"
"    if c2||c3, state=int8(1); end"
"  case int8(1)  % Moving_Up"
"    if c3,        state=int8(4);"
"    else,         state=int8(2); end"
"  case int8(2)  % Floor_2"
"    if c3,        state=int8(1);"
"    elseif c1,    state=int8(3); end"
"  case int8(3)  % Moving_Down"
"    if c2&&~c1,   state=int8(2);"
"    else,         state=int8(0); end"
"  case int8(4)  % Floor_3"
"    if c1||c2,    state=int8(3); end"
"end"
];

%% ── 6. INJECT FUNCTION CODE VIA STATEFLOW API ───────────────
rt  = sfroot();
m   = rt.find('-isa','Simulink.BlockDiagram','Name', mdl);
ems = m.find('-isa','Stateflow.EMChart');

% Match each EMChart to its block by path
for i = 1:length(ems)
    blkPath = ems(i).Path;
    if contains(blkPath,'Priority_Controller')
        ems(i).Script = strjoin(prioCode,  newline);
    elseif contains(blkPath,'Elevator_A')
        ems(i).Script = strjoin(elevCode_A, newline);
    elseif contains(blkPath,'Elevator_B')
        ems(i).Script = strjoin(elevCode_B, newline);
    end
end

%% ── 7. UNIT DELAY BLOCKS (feedback: floor + IDLE signals) ───
%  Connected AFTER elevators, their outputs feed back to FB_ delays
udFloorA = [mdl '/UD_floorA'];
udFloorB = [mdl '/UD_floorB'];
udIdleA  = [mdl '/UD_IDLE_A'];
udIdleB  = [mdl '/UD_IDLE_B'];

add_block('simulink/Discrete/Unit Delay', udFloorA, ...
          'SampleTime','1','InitialCondition','1','OutDataTypeStr','int8', ...
          'Position',[650, 250, 700, 274]);
add_block('simulink/Discrete/Unit Delay', udFloorB, ...
          'SampleTime','1','InitialCondition','3','OutDataTypeStr','int8', ...
          'Position',[650, 540, 700, 564]);
add_block('simulink/Discrete/Unit Delay', udIdleA, ...
          'SampleTime','1','InitialCondition','true','OutDataTypeStr','boolean', ...
          'Position',[650, 290, 700, 314]);
add_block('simulink/Discrete/Unit Delay', udIdleB, ...
          'SampleTime','1','InitialCondition','true','OutDataTypeStr','boolean', ...
          'Position',[650, 580, 700, 604]);

%% ── 8. DISPLAY BLOCKS ────────────────────────────────────────
dispNamesA = {'UP_A','DOWN_A','IDLE_A','Floor_A'};
dispNamesB = {'UP_B','DOWN_B','IDLE_B','Floor_B'};
dispYA     = [50 120 190 260];
dispYB     = [340 410 480 550];
dispXD     = 760;

dispHA = zeros(1,4);
dispHB = zeros(1,4);
for k = 1:4
    blkA = [mdl '/Disp_' dispNamesA{k}];
    add_block('simulink/Sinks/Display', blkA, ...
              'Position',[dispXD, dispYA(k), dispXD+80, dispYA(k)+24]);
    dispHA(k) = get_param(blkA,'Handle');

    blkB = [mdl '/Disp_' dispNamesB{k}];
    add_block('simulink/Sinks/Display', blkB, ...
              'Position',[dispXD, dispYB(k), dispXD+80, dispYB(k)+24]);
    dispHB(k) = get_param(blkB,'Handle');
end

%% ── 9. SCOPE (8 signals: 4 per elevator) ────────────────────
scopeBlk = [mdl '/Scope'];
add_block('simulink/Sinks/Scope', scopeBlk, ...
          'NumInputPorts','8', ...
          'Position',[760, 630, 810, 860]);

%% ── 10. WIRE EVERYTHING ──────────────────────────────────────
prioPH  = get_param(prioBlk,  'PortHandles');
elevAPH = get_param(elevABlk, 'PortHandles');
elevBPH = get_param(elevBBlk, 'PortHandles');
scopePH = get_param(scopeBlk, 'PortHandles');

udFloorAPH = get_param(udFloorA,'PortHandles');
udFloorBPH = get_param(udFloorB,'PortHandles');
udIdleAPH  = get_param(udIdleA, 'PortHandles');
udIdleBPH  = get_param(udIdleB, 'PortHandles');

% ---- (a) Call buttons → Priority Controller  (in 1..4 = c1,c2,c3,RESET)
for k = 1:4
    srcPH = get_param(callH(k),'PortHandles');
    add_line(mdl, srcPH.Outport(1), prioPH.Inport(k), 'autorouting','on');
end
% Delayed feedback → Priority Controller (in 5..8)
fbBlkNames = {['FB_' fbNames{1}],['FB_' fbNames{2}], ...
              ['FB_' fbNames{3}],['FB_' fbNames{4}]};
for k = 1:4
    srcPH = get_param([mdl '/' fbBlkNames{k}],'PortHandles');
    add_line(mdl, srcPH.Outport(1), prioPH.Inport(k+4), 'autorouting','on');
end
% RESET also into Priority (in 8 = RESET already covered above since k=4 is RESET→in4)
% Correction: prioPH.Inport order is c1(1),c2(2),c3(3),floorA(4+1??)
% Let me recount: the function signature is:
%   (c1,c2,c3, floorA,floorB, idleA,idleB, RESET)  →  8 inputs
% So wiring:
%   in1=c1, in2=c2, in3=c3, in4=floorA_d, in5=floorB_d, in6=IDLE_A_d, in7=IDLE_B_d, in8=RESET

% redo wiring cleanly
delete_line(mdl, get_param(callH(4),'PortHandles').Outport(1), prioPH.Inport(4));
for k = 1:4
    try
        delete_line(mdl, get_param([mdl '/' fbBlkNames{k}],'PortHandles').Outport(1), prioPH.Inport(k+4));
    catch, end
end

% c1→in1, c2→in2, c3→in3
for k = 1:3
    srcPH = get_param(callH(k),'PortHandles');
    add_line(mdl, srcPH.Outport(1), prioPH.Inport(k), 'autorouting','on');
end
% floorA_d→in4, floorB_d→in5, IDLE_A_d→in6, IDLE_B_d→in7
for k = 1:4
    srcPH = get_param([mdl '/' fbBlkNames{k}],'PortHandles');
    add_line(mdl, srcPH.Outport(1), prioPH.Inport(k+3), 'autorouting','on');
end
% RESET → in8
srcRST = get_param(callH(4),'PortHandles');
add_line(mdl, srcRST.Outport(1), prioPH.Inport(8), 'autorouting','on');

% ---- (b) Priority Controller outputs → Elevator A (cA1,cA2,cA3)
for k = 1:3
    add_line(mdl, prioPH.Outport(k), elevAPH.Inport(k), 'autorouting','on');
end
% RESET → Elevator A in4
add_line(mdl, srcRST.Outport(1), elevAPH.Inport(4), 'autorouting','on');

% ---- (c) Priority Controller outputs → Elevator B (cB1,cB2,cB3)
for k = 1:3
    add_line(mdl, prioPH.Outport(k+3), elevBPH.Inport(k), 'autorouting','on');
end
% RESET → Elevator B in4
add_line(mdl, srcRST.Outport(1), elevBPH.Inport(4), 'autorouting','on');

% ---- (d) Elevator A outputs → Displays A  (UP,DOWN,IDLE,floor)
for k = 1:4
    dstPH = get_param(dispHA(k),'PortHandles');
    add_line(mdl, elevAPH.Outport(k), dstPH.Inport(1), 'autorouting','on');
end

% ---- (e) Elevator B outputs → Displays B
for k = 1:4
    dstPH = get_param(dispHB(k),'PortHandles');
    add_line(mdl, elevBPH.Outport(k), dstPH.Inport(1), 'autorouting','on');
end

% ---- (f) Elevator A: floor(out4) and IDLE(out3) → Unit Delays
add_line(mdl, elevAPH.Outport(4), udFloorAPH.Inport(1), 'autorouting','on');
add_line(mdl, elevAPH.Outport(3), udIdleAPH.Inport(1),  'autorouting','on');
% ---- Elevator B: floor(out4) and IDLE(out3) → Unit Delays
add_line(mdl, elevBPH.Outport(4), udFloorBPH.Inport(1), 'autorouting','on');
add_line(mdl, elevBPH.Outport(3), udIdleBPH.Inport(1),  'autorouting','on');

% ---- (g) Unit Delay outputs → FB_ Unit Delays (the actual feedback delay blocks)
%   udFloorA.out → FB_floorA_d.in,   udIdleA.out → FB_IDLE_A_d.in
%   (The FB_ blocks declared earlier ARE the unit delays —
%    remove them and directly wire udFloorA/B/Idle output to priority)
% Actually let us simplify: remove FB_ blocks and just wire udFloor/Idle
% directly to the prioPH.Inport(4..7)

% Delete the FB_ delay blocks (they were redundant placeholders)
for k = 1:4
    delete_block([mdl '/' fbBlkNames{k}]);
end

% Re-wire Unit Delay outputs straight to Priority Controller feedback inputs
add_line(mdl, udFloorAPH.Outport(1), prioPH.Inport(4), 'autorouting','on');
add_line(mdl, udFloorBPH.Outport(1), prioPH.Inport(5), 'autorouting','on');
add_line(mdl, udIdleAPH.Outport(1),  prioPH.Inport(6), 'autorouting','on');
add_line(mdl, udIdleBPH.Outport(1),  prioPH.Inport(7), 'autorouting','on');

% ---- (h) All outputs → Scope
for k = 1:4
    add_line(mdl, elevAPH.Outport(k), scopePH.Inport(k),   'autorouting','on');
end
for k = 1:4
    add_line(mdl, elevBPH.Outport(k), scopePH.Inport(k+4), 'autorouting','on');
end

%% ── 11. ARRANGE & SAVE ───────────────────────────────────────
Simulink.BlockDiagram.arrangeSystem(mdl);
save_system(mdl, fullfile(pwd,'DualElevatorFSM.slx'));

fprintf('\n========================================\n');
fprintf('  DualElevatorFSM.slx  — created OK\n');
fprintf('========================================\n\n');
fprintf('  INPUTS  (set Constant value to 0 or 1):\n');
fprintf('    c1 = call button Floor 1\n');
fprintf('    c2 = call button Floor 2\n');
fprintf('    c3 = call button Floor 3\n');
fprintf('    RESET = 1  →  both elevators return to home floor\n\n');
fprintf('  OUTPUTS:\n');
fprintf('    UP_A / UP_B     = 1 while moving up\n');
fprintf('    DOWN_A / DOWN_B = 1 while moving down\n');
fprintf('    IDLE_A / IDLE_B = 1 while stopped at a floor\n');
fprintf('    Floor_A / Floor_B = current floor (1/2/3)  0 = in transit\n\n');
fprintf('  PRIORITY RULES:\n');
fprintf('    1. Elevator already AT called floor  →  wins\n');
fprintf('    2. Idle & nearest                    →  wins\n');
fprintf('    3. Only one idle                     →  gets the call\n');
fprintf('    4. Tie / both busy                   →  Elevator A wins\n\n');
fprintf('  Elevator A starts at Floor 1.  Elevator B starts at Floor 3.\n');
fprintf('  Press Ctrl+T to simulate.\n\n');

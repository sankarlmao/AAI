%% ============================================================
%  build_ElevatorFSM.m
%  Run this in MATLAB to create ElevatorFSM.slx
%  Requires: Simulink  (no Stateflow needed)
%
%  Elevator FSM — 3 Floors
%  States : Floor_1 → Moving_Up → Floor_2 / Floor_3 → Moving_Down
%  Inputs : c1, c2, c3 (floor call buttons), RESET
%  Outputs: UP, DOWN, IDLE, current_floor
%% ============================================================

mdl = 'ElevatorFSM';

%% -- clean up -------------------------------------------------
if bdIsLoaded(mdl), close_system(mdl,0); end
new_system(mdl);
open_system(mdl);

%% -- solver: fixed-step discrete (digital circuit) -----------
set_param(mdl,'SolverType','Fixed-step','Solver','FixedStepDiscrete',...
              'FixedStep','1','StopTime','30',...
              'SaveTime','on','SaveOutput','on');

%% ============================================================
%  BLOCK LAYOUT
%  Col A (x=60)  : Input Constant blocks
%  Col B (x=250) : FSM MATLAB Function block
%  Col C (x=510) : Display / Scope outputs
%% ============================================================

%% -- A: Input blocks (Constant — user edits value to 0/1) ----
inputs  = {'c1','c2','c3','RESET'};
ypos    = [80 150 220 290];   % vertical positions

inPH = zeros(1,4);
for k = 1:4
    blk = [mdl '/' inputs{k}];
    add_block('simulink/Sources/Constant', blk, ...
              'Value','0', ...
              'OutDataTypeStr','boolean', ...
              'Position',[60, ypos(k), 110, ypos(k)+24]);
    set_param(blk,'Name',inputs{k});
    inPH(k) = get_param(blk,'Handle');
end

%% -- B: FSM implemented as a MATLAB Function block -----------
fsmBlk = [mdl '/ElevatorFSM_Logic'];
add_block('simulink/User-Defined Functions/MATLAB Function', fsmBlk, ...
          'Position',[200 70 430 320], ...
          'BackgroundColor','cyan');

% Write the FSM function (persistent state = D flip-flop memory)
fsmCode = [
"function [UP, DOWN, IDLE, floor_num] = ElevatorFSM_Logic(c1, c2, c3, RESET)"
"% Elevator FSM Digital Circuit"
"% States (encoded): 0=Floor_1, 1=Moving_Up, 2=Floor_2, 3=Moving_Down, 4=Floor_3"
"persistent state;"
"if isempty(state), state = int8(0); end"
""
"% ---- Output decode (current state) ----"
"UP    = (state == int8(1));"
"DOWN  = (state == int8(3));"
"IDLE  = (state == int8(0)) || (state == int8(2)) || (state == int8(4));"
"if     state == int8(0), floor_num = int8(1);"
"elseif state == int8(2), floor_num = int8(2);"
"elseif state == int8(4), floor_num = int8(3);"
"else,                    floor_num = int8(0);  % moving"
"end"
""
"% ---- Next-state logic (combinational, clocked by sample time) ----"
"if RESET"
"    state = int8(0);  % → Floor_1"
"    return;"
"end"
""
"switch state"
"  case int8(0)  % Floor_1"
"    if c2 || c3,  state = int8(1); end   % → Moving_Up"
""
"  case int8(1)  % Moving_Up"
"    if c3,        state = int8(4);       % → Floor_3"
"    else,         state = int8(2); end   % → Floor_2"
""
"  case int8(2)  % Floor_2"
"    if c3,        state = int8(1);       % → Moving_Up"
"    elseif c1,    state = int8(3); end   % → Moving_Down"
""
"  case int8(3)  % Moving_Down"
"    if c2 && ~c1, state = int8(2);       % stop at Floor_2"
"    else,         state = int8(0); end   % → Floor_1"
""
"  case int8(4)  % Floor_3"
"    if c1 || c2,  state = int8(3); end   % → Moving_Down"
"end"
];

% Inject code via Stateflow API (MATLAB Function editor)
rt   = sfroot();
m    = rt.find('-isa','Simulink.BlockDiagram','Name',mdl);
fsm  = m.find('-isa','Stateflow.EMChart');
fsm.Script = strjoin(fsmCode, newline);

%% -- C: Output Display blocks --------------------------------
outs  = {'UP','DOWN','IDLE','Floor'};
ydisp = [80 150 220 290];

outPH = zeros(1,4);
for k = 1:4
    blk = [mdl '/Display_' outs{k}];
    add_block('simulink/Sinks/Display', blk, ...
              'Position',[510, ydisp(k), 600, ydisp(k)+24]);
    outPH(k) = get_param(blk,'Handle');
end

%% -- Scope for waveform view ---------------------------------
scopeBlk = [mdl '/Scope'];
add_block('simulink/Sinks/Scope', scopeBlk, ...
          'NumInputPorts','4', ...
          'Position',[510 340 560 510]);

%% -- Connect inputs → FSM ------------------------------------
fsmPH = get_param(fsmBlk,'PortHandles');
for k = 1:4
    srcPH = get_param(inPH(k),'PortHandles');
    add_line(mdl, srcPH.Outport(1), fsmPH.Inport(k), 'autorouting','on');
end

%% -- Connect FSM outputs → Displays -------------------------
for k = 1:4
    dstPH  = get_param(outPH(k),'PortHandles');
    add_line(mdl, fsmPH.Outport(k), dstPH.Inport(1), 'autorouting','on');
end

%% -- Connect FSM outputs → Scope ----------------------------
scopePH = get_param(scopeBlk,'PortHandles');
for k = 1:4
    add_line(mdl, fsmPH.Outport(k), scopePH.Inport(k), 'autorouting','on');
end

%% -- Arrange & Save ------------------------------------------
Simulink.BlockDiagram.arrangeSystem(mdl);
save_system(mdl, fullfile(pwd,'ElevatorFSM.slx'));

fprintf('\n  ElevatorFSM.slx created successfully.\n');
fprintf('  Change c1/c2/c3/RESET Constant values, then press Run (Ctrl+T).\n\n');
fprintf('  State legend:\n');
fprintf('    UP=1  → Moving_Up    (Floor 1→2→3)\n');
fprintf('    DOWN=1→ Moving_Down  (Floor 3→2→1)\n');
fprintf('    IDLE=1→ At a floor   (Floor 1, 2, or 3)\n');
fprintf('    Floor → 1, 2, 3 or 0 (while moving)\n\n');

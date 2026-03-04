%% ================================================================
%  DualElevator.m  —  Run in MATLAB to build DualElevator.slx
%
%  Two elevators (A and B) on 3 floors with priority dispatcher.
%
%  INPUTS  (Constant blocks — change value to 0 or 1, then Ctrl+T)
%    c1    = floor 1 call button
%    c2    = floor 2 call button
%    c3    = floor 3 call button
%    RESET = send both elevators home  (A→Floor1, B→Floor3)
%
%  OUTPUTS (Display blocks + Scope)
%    UP_A / DOWN_A / IDLE_A / Floor_A   —  Elevator A status
%    UP_B / DOWN_B / IDLE_B / Floor_B   —  Elevator B status
%
%  PRIORITY RULES (inside Priority_Controller block)
%    1. Elevator already at the called floor        → it responds
%    2. Closest idle elevator                       → it responds
%    3. Only one elevator idle                      → that one responds
%    4. Both busy or exact tie                      → Elevator A wins
%% ================================================================

mdl = 'DualElevator';

%% ── housekeeping ──────────────────────────────────────────────
if bdIsLoaded(mdl), close_system(mdl,0); end
new_system(mdl);
open_system(mdl);
set_param(mdl,'SolverType','Fixed-step','Solver','FixedStepDiscrete',...
              'FixedStep','1','StopTime','40');

%% ================================================================
%  HELPER – add a Constant input block
%% ================================================================
function h = addConst(mdl, name, x, y)
    add_block('simulink/Sources/Constant',[mdl '/' name], ...
              'Value','0','OutDataTypeStr','boolean', ...
              'Position',[x y x+50 y+24]);
    h = get_param([mdl '/' name],'PortHandles');
end

%% ================================================================
%  HELPER – add a Display output block
%% ================================================================
function h = addDisp(mdl, name, x, y)
    add_block('simulink/Sinks/Display',[mdl '/' name], ...
              'Position',[x y x+70 y+24]);
    h = get_param([mdl '/' name],'PortHandles');
end

%% ================================================================
%  HELPER – add a Unit Delay block (for FSM feedback)
%% ================================================================
function h = addUD(mdl, name, dtype, ic, x, y)
    add_block('simulink/Discrete/Unit Delay',[mdl '/' name], ...
              'SampleTime','1','InitialCondition',ic, ...
              'OutDataTypeStr',dtype, ...
              'Position',[x y x+40 y+24]);
    h = get_param([mdl '/' name],'PortHandles');
end

%% ================================================================
%  BLOCK 1 — INPUTS  (x=30)
%% ================================================================
c1PH    = addConst(mdl,'c1',   30,  60);
c2PH    = addConst(mdl,'c2',   30, 110);
c3PH    = addConst(mdl,'c3',   30, 160);
rstPH   = addConst(mdl,'RESET',30, 210);

%% ================================================================
%  BLOCK 2 — PRIORITY CONTROLLER  (x=180)
%  Inputs  (8): c1 c2 c3 RESET  floorA floorB idleA idleB
%  Outputs (6): cA1 cA2 cA3  cB1 cB2 cB3
%% ================================================================
add_block('simulink/User-Defined Functions/MATLAB Function', ...
          [mdl '/Priority_Controller'], ...
          'Position',[180 40 370 400],'BackgroundColor','yellow');

%% ================================================================
%  BLOCK 3 — ELEVATOR A FSM  (x=450, top half)
%  Inputs  (4): cA1 cA2 cA3 RESET
%  Outputs (4): UP DOWN IDLE floor
%  Starts at Floor 1
%% ================================================================
add_block('simulink/User-Defined Functions/MATLAB Function', ...
          [mdl '/Elevator_A'], ...
          'Position',[450 40 630 230],'BackgroundColor','cyan');

%% ================================================================
%  BLOCK 4 — ELEVATOR B FSM  (x=450, bottom half)
%  Inputs  (4): cB1 cB2 cB3 RESET
%  Outputs (4): UP DOWN IDLE floor
%  Starts at Floor 3
%% ================================================================
add_block('simulink/User-Defined Functions/MATLAB Function', ...
          [mdl '/Elevator_B'], ...
          'Position',[450 280 630 470],'BackgroundColor','magenta');

%% ================================================================
%  INJECT FSM CODE via Stateflow API
%% ================================================================
rt  = sfroot();
m   = rt.find('-isa','Simulink.BlockDiagram','Name',mdl);
ems = m.find('-isa','Stateflow.EMChart');

prioCode = strjoin({
"function [cA1,cA2,cA3,cB1,cB2,cB3] = Priority_Controller(c1,c2,c3,RESET,floorA,floorB,idleA,idleB)"
"% Assigns each floor call to the best elevator."
"% floorA/floorB = current floor (1/2/3), 0 means in transit."
"% idleA/idleB   = true when stopped at a floor."
"cA1=false;cA2=false;cA3=false;"
"cB1=false;cB2=false;cB3=false;"
"if RESET, return; end"
"calls=[logical(c1),logical(c2),logical(c3)];"
"fA=double(floorA); fB=double(floorB);"
"cAv=[false,false,false]; cBv=[false,false,false];"
"for fl=1:3"
"  if ~calls(fl), continue; end"
"  dA=abs(fA-fl); if fA==0, dA=99; end"
"  dB=abs(fB-fl); if fB==0, dB=99; end"
"  % Rule 1: already at floor"
"  if dA==0 && idleA,      cAv(fl)=true;"
"  elseif dB==0 && idleB,  cBv(fl)=true;"
"  % Rule 2 & 3: closest idle"
"  elseif idleA && idleB"
"    if dA<=dB, cAv(fl)=true; else, cBv(fl)=true; end"
"  elseif idleA,            cAv(fl)=true;"
"  elseif idleB,            cBv(fl)=true;"
"  % Rule 4: both busy → A"
"  else,                    cAv(fl)=true;"
"  end"
"end"
"cA1=cAv(1);cA2=cAv(2);cA3=cAv(3);"
"cB1=cBv(1);cB2=cBv(2);cB3=cBv(3);"
}, newline);

elevACode = strjoin({
"function [UP,DOWN,IDLE,floor_num] = Elevator_A(c1,c2,c3,RESET)"
"% Elevator A FSM — starts at Floor 1"
"% 0=Floor_1  1=Moving_Up  2=Floor_2  3=Moving_Down  4=Floor_3"
"persistent s; if isempty(s), s=int8(0); end"
"UP=(s==int8(1)); DOWN=(s==int8(3));"
"IDLE=(s==int8(0))||(s==int8(2))||(s==int8(4));"
"if s==int8(0),floor_num=int8(1);"
"elseif s==int8(2),floor_num=int8(2);"
"elseif s==int8(4),floor_num=int8(3);"
"else, floor_num=int8(0); end"
"if RESET, s=int8(0); return; end"
"switch s"
"  case int8(0), if c2||c3, s=int8(1); end"
"  case int8(1), if c3, s=int8(4); else, s=int8(2); end"
"  case int8(2), if c3, s=int8(1); elseif c1, s=int8(3); end"
"  case int8(3), if c2&&~c1, s=int8(2); else, s=int8(0); end"
"  case int8(4), if c1||c2, s=int8(3); end"
"end"
}, newline);

elevBCode = strjoin({
"function [UP,DOWN,IDLE,floor_num] = Elevator_B(c1,c2,c3,RESET)"
"% Elevator B FSM — starts at Floor 3"
"% 0=Floor_1  1=Moving_Up  2=Floor_2  3=Moving_Down  4=Floor_3"
"persistent s; if isempty(s), s=int8(4); end"
"UP=(s==int8(1)); DOWN=(s==int8(3));"
"IDLE=(s==int8(0))||(s==int8(2))||(s==int8(4));"
"if s==int8(0),floor_num=int8(1);"
"elseif s==int8(2),floor_num=int8(2);"
"elseif s==int8(4),floor_num=int8(3);"
"else, floor_num=int8(0); end"
"if RESET, s=int8(4); return; end"
"switch s"
"  case int8(0), if c2||c3, s=int8(1); end"
"  case int8(1), if c3, s=int8(4); else, s=int8(2); end"
"  case int8(2), if c3, s=int8(1); elseif c1, s=int8(3); end"
"  case int8(3), if c2&&~c1, s=int8(2); else, s=int8(0); end"
"  case int8(4), if c1||c2, s=int8(3); end"
"end"
}, newline);

for i = 1:length(ems)
    p = ems(i).Path;
    if contains(p,'Priority_Controller'), ems(i).Script = prioCode;
    elseif contains(p,'Elevator_A'),      ems(i).Script = elevACode;
    elseif contains(p,'Elevator_B'),      ems(i).Script = elevBCode;
    end
end

%% ================================================================
%  UNIT DELAYS — break algebraic loop in priority feedback
%  floorA(t-1) and idleA(t-1) fed back to Priority Controller
%% ================================================================
udFA = addUD(mdl,'UD_floorA','int8',  '1',    660, 140);
udIA = addUD(mdl,'UD_idleA', 'boolean','true', 660, 180);
udFB = addUD(mdl,'UD_floorB','int8',  '3',    660, 370);
udIB = addUD(mdl,'UD_idleB', 'boolean','true', 660, 410);

%% ================================================================
%  OUTPUT DISPLAYS  (x=760)
%% ================================================================
dUPA   = addDisp(mdl,'UP_A',   760,  55);
dDNA   = addDisp(mdl,'DOWN_A', 760,  95);
dIDA   = addDisp(mdl,'IDLE_A', 760, 135);
dFLA   = addDisp(mdl,'Floor_A',760, 175);
dUPB   = addDisp(mdl,'UP_B',   760, 290);
dDNB   = addDisp(mdl,'DOWN_B', 760, 330);
dIDB   = addDisp(mdl,'IDLE_B', 760, 370);
dFLB   = addDisp(mdl,'Floor_B',760, 410);

%% ================================================================
%  SCOPE — all 8 output signals
%% ================================================================
add_block('simulink/Sinks/Scope',[mdl '/Scope'], ...
          'NumInputPorts','8','Position',[760 480 810 700]);
scPH = get_param([mdl '/Scope'],'PortHandles');

%% ================================================================
%  WIRING
%% ================================================================
priPH = get_param([mdl '/Priority_Controller'],'PortHandles');
eAPH  = get_param([mdl '/Elevator_A'],          'PortHandles');
eBPH  = get_param([mdl '/Elevator_B'],          'PortHandles');

% ── Inputs → Priority Controller ─────────────────────────────
add_line(mdl, c1PH.Outport(1),  priPH.Inport(1),'autorouting','on');
add_line(mdl, c2PH.Outport(1),  priPH.Inport(2),'autorouting','on');
add_line(mdl, c3PH.Outport(1),  priPH.Inport(3),'autorouting','on');
add_line(mdl, rstPH.Outport(1), priPH.Inport(4),'autorouting','on');
% feedback (unit delay outputs)
add_line(mdl, udFA.Outport(1),  priPH.Inport(5),'autorouting','on');
add_line(mdl, udFB.Outport(1),  priPH.Inport(6),'autorouting','on');
add_line(mdl, udIA.Outport(1),  priPH.Inport(7),'autorouting','on');
add_line(mdl, udIB.Outport(1),  priPH.Inport(8),'autorouting','on');

% ── Priority Controller → Elevator A ─────────────────────────
add_line(mdl, priPH.Outport(1), eAPH.Inport(1),'autorouting','on'); % cA1
add_line(mdl, priPH.Outport(2), eAPH.Inport(2),'autorouting','on'); % cA2
add_line(mdl, priPH.Outport(3), eAPH.Inport(3),'autorouting','on'); % cA3
add_line(mdl, rstPH.Outport(1), eAPH.Inport(4),'autorouting','on'); % RESET

% ── Priority Controller → Elevator B ─────────────────────────
add_line(mdl, priPH.Outport(4), eBPH.Inport(1),'autorouting','on'); % cB1
add_line(mdl, priPH.Outport(5), eBPH.Inport(2),'autorouting','on'); % cB2
add_line(mdl, priPH.Outport(6), eBPH.Inport(3),'autorouting','on'); % cB3
add_line(mdl, rstPH.Outport(1), eBPH.Inport(4),'autorouting','on'); % RESET

% ── Elevator A outputs → Displays + UnitDelays + Scope ───────
add_line(mdl, eAPH.Outport(1), dUPA.Inport(1),'autorouting','on'); % UP
add_line(mdl, eAPH.Outport(2), dDNA.Inport(1),'autorouting','on'); % DOWN
add_line(mdl, eAPH.Outport(3), dIDA.Inport(1),'autorouting','on'); % IDLE
add_line(mdl, eAPH.Outport(4), dFLA.Inport(1),'autorouting','on'); % floor
add_line(mdl, eAPH.Outport(4), udFA.Inport(1),'autorouting','on'); % floor → UD
add_line(mdl, eAPH.Outport(3), udIA.Inport(1),'autorouting','on'); % IDLE  → UD
add_line(mdl, eAPH.Outport(1), scPH.Inport(1),'autorouting','on');
add_line(mdl, eAPH.Outport(2), scPH.Inport(2),'autorouting','on');
add_line(mdl, eAPH.Outport(3), scPH.Inport(3),'autorouting','on');
add_line(mdl, eAPH.Outport(4), scPH.Inport(4),'autorouting','on');

% ── Elevator B outputs → Displays + UnitDelays + Scope ───────
add_line(mdl, eBPH.Outport(1), dUPB.Inport(1),'autorouting','on');
add_line(mdl, eBPH.Outport(2), dDNB.Inport(1),'autorouting','on');
add_line(mdl, eBPH.Outport(3), dIDB.Inport(1),'autorouting','on');
add_line(mdl, eBPH.Outport(4), dFLB.Inport(1),'autorouting','on');
add_line(mdl, eBPH.Outport(4), udFB.Inport(1),'autorouting','on');
add_line(mdl, eBPH.Outport(3), udIB.Inport(1),'autorouting','on');
add_line(mdl, eBPH.Outport(1), scPH.Inport(5),'autorouting','on');
add_line(mdl, eBPH.Outport(2), scPH.Inport(6),'autorouting','on');
add_line(mdl, eBPH.Outport(3), scPH.Inport(7),'autorouting','on');
add_line(mdl, eBPH.Outport(4), scPH.Inport(8),'autorouting','on');

%% ================================================================
%  ARRANGE & SAVE
%% ================================================================
Simulink.BlockDiagram.arrangeSystem(mdl);
save_system(mdl, fullfile(pwd,'DualElevator.slx'));

disp('=========================================');
disp('  DualElevator.slx  created successfully.');
disp('=========================================');
disp('  Set c1/c2/c3 = 1 to call a floor.');
disp('  RESET = 1 returns both elevators home.');
disp('  Press Ctrl+T to run the simulation.');
disp(' ');
disp('  Elevator A starts at Floor 1 (bottom).');
disp('  Elevator B starts at Floor 3 (top).');
disp('  Nearest idle elevator gets each call.');

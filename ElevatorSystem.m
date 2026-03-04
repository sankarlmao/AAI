%% ================================================================
%  ElevatorSystem.m
%  Run in MATLAB  >>  ElevatorSystem
%  Generates:  ElevatorSystem.slx
%
%  Contains TWO subsystems in one model:
%  ┌─────────────────────────────────────────────────────────┐
%  │  [1] Single_Elevator  —  gate-level digital circuit      │
%  │      Matches the Logisim schematic (image reference)     │
%  │      3 call-register DFFs  +  state DFFs  +  DIR DFF    │
%  │      Signals: ANY_ABOVE, ANY_BELOW → UP, DOWN outputs   │
%  │                                                          │
%  │  [2] Dual_Elevator  —  two FSMs + Priority Controller   │
%  │      Rule 1: already at floor → wins                    │
%  │      Rule 2: idle & closest   → wins                    │
%  │      Rule 3: only one idle    → wins                    │
%  │      Rule 4: tie / both busy  → Elevator A wins         │
%  └─────────────────────────────────────────────────────────┘
%
%  INPUTS  (Constant blocks, set to 0 or 1, then Ctrl+T)
%    call1, call2, call3  = floor call buttons
%    RESET                = reset both systems
%% ================================================================

mdl = 'ElevatorSystem';
if bdIsLoaded(mdl), close_system(mdl,0); end
new_system(mdl);
open_system(mdl);
set_param(mdl,'SolverType','Fixed-step','Solver','FixedStepDiscrete',...
              'FixedStep','1','StopTime','40');

%% ================================================================
%  SHARED INPUT CONSTANTS  (top of canvas)
%% ================================================================
inputs = {'call1','call2','call3','RESET'};
xIn = 30;  yIn = [30 90 150 210];
iPH = cell(1,4);
for k = 1:4
    add_block('simulink/Sources/Constant',[mdl '/' inputs{k}],...
              'Value','0','OutDataTypeStr','boolean',...
              'Position',[xIn yIn(k) xIn+50 yIn(k)+24]);
    iPH{k} = get_param([mdl '/' inputs{k}],'PortHandles');
end

%% ================================================================
%  SUBSYSTEM 1 — SINGLE ELEVATOR (gate-level circuit)
%  Mirrors the Logisim schematic exactly:
%    • 3 call-register D flip-flops  (Q_F1, Q_F2, Q_F3)
%    • 2 state D flip-flops           (Q1, Q0)
%    • 1 direction D flip-flop        (DIR)
%    • ANY_ABOVE / ANY_BELOW combinational logic
%    • UP and DOWN outputs
%% ================================================================
add_block('simulink/Ports & Subsystems/Subsystem',...
          [mdl '/Single_Elevator'],...
          'Position',[160 30 520 310],...
          'BackgroundColor','cyan');

% delete default in/out inside
delete_block([mdl '/Single_Elevator/In1']);
delete_block([mdl '/Single_Elevator/Out1']);

SE = [mdl '/Single_Elevator'];

% --- Inputs inside subsystem
seIn = {'call1','call2','call3','RESET'};
seInY = [30 90 150 210];
sePH_in = cell(1,4);
for k=1:4
    add_block('simulink/Sources/In1',[SE '/se_' seIn{k}],...
              'Position',[20 seInY(k) 50 seInY(k)+20],...
              'OutDataTypeStr','boolean');
    sePH_in{k} = get_param([SE '/se_' seIn{k}],'PortHandles');
end

% --- MATLAB Function block (entire gate-level logic)
add_block('simulink/User-Defined Functions/MATLAB Function',...
          [SE '/GateCircuit'],...
          'Position',[120 20 380 290],...
          'BackgroundColor','white');

% --- Output ports
seOut = {'Q_F1','Q_F2','Q_F3','UP','DOWN','State_Q1Q0'};
seOutY = [30 70 110 150 190 230];
sePH_out = cell(1,6);
for k=1:6
    add_block('simulink/Sinks/Out1',[SE '/se_out_' seOut{k}],...
              'Position',[450 seOutY(k) 480 seOutY(k)+20]);
    sePH_out{k} = get_param([SE '/se_out_' seOut{k}],'PortHandles');
end

% --- Inject gate-level FSM code
%  Circuit description (matches Logisim image):
%  CALL REGISTERS (one per floor):
%    Each floor has a DFF. Set when call pressed, cleared when elevator arrives.
%  STATE MACHINE:  Q1 Q0   →   00=Floor1  01=Moving_Up  10=Floor2+3zone  11=Moving_Down
%    (simplified two-bit encoding matching Q1,Q0 DFFs in image)
%  ANY_ABOVE = pending calls above current floor
%  ANY_BELOW = pending calls below current floor
%  DIR DFF   = 1 if moving/was moving up, 0 if down
%  UP  = elevator should move up
%  DOWN= elevator should move down

seCode = strjoin({
"function [QF1,QF2,QF3,UP,DOWN,stateQQ] = GateCircuit(call1,call2,call3,RESET)"
"% Gate-level elevator controller — matches Logisim circuit diagram"
"% CALL REGISTER DFFs (Q_F1 Q_F2 Q_F3) — stores pending calls"
"% STATE DFFs      (Q1 Q0)  00=Floor1 01=MovingUp 10=Floor2 11=Floor3->Down"
"% DIRECTION DFF   (DIR)     1=Up  0=Down"
"% ANY_ABOVE / ANY_BELOW combinational then UP/DOWN outputs"
"persistent QF1r QF2r QF3r Q1r Q0r DIRr;"
"if isempty(QF1r)"
"    QF1r=false;QF2r=false;QF3r=false;"
"    Q1r=false; Q0r=false; DIRr=false;"
"end"
""
"if RESET"
"    QF1r=false;QF2r=false;QF3r=false;"
"    Q1r=false; Q0r=false; DIRr=false;"
"    QF1=false;QF2=false;QF3=false;"
"    UP=false; DOWN=false; stateQQ=int8(0);"
"    return;"
"end"
""
"% ---- Current floor decode (from Q1 Q0) ----"
"% 00 = Floor 1 | 01 = Moving Up | 10 = Floor 2 | 11 = Floor 3"
"at_F1 =  ~Q1r & ~Q0r;"
"at_F2 =  ~Q1r &  Q0r;   % repurposed: 01=at floor2 after arriving"
"at_F3 =   Q1r & ~Q0r;"
"moving = Q1r & Q0r;     % 11 = in transit"
""
"% ---- Call register logic (OR gate = latch set, AND+NOT = clear on arrival) ----"
"% Set call if button pressed, clear when elevator at that floor"
"nQF1 = (QF1r | call1) & ~at_F1;"
"nQF2 = (QF2r | call2) & ~at_F2;"
"nQF3 = (QF3r | call3) & ~at_F3;"
""
"% ---- ANY_ABOVE  (pending calls above current floor) ----"
"any_above = (at_F1 & (nQF2 | nQF3)) | ..."
"            (at_F2 & nQF3);"
""
"% ---- ANY_BELOW  (pending calls below current floor) ----"
"any_below = (at_F3 & (nQF1 | nQF2)) | ..."
"            (at_F2 & nQF1);"
""
"% ---- Direction flip-flop (DIR) ----"
"% Set when any_above, clear when any_below, hold when moving"
"nDIR = (any_above | (DIRr & ~any_below));"
""
"% ---- Next state logic ----"
"% From Floor1: if any_above → go up (01)"
"% From Floor2: if any_above → go up, if any_below → go down"
"% From Floor3: if any_below → go down"
"% Moving: continue until target floor"
"nQ1 = false; nQ0 = false;"
"if at_F1"
"    if any_above, nQ0=true; end      % → moving up (01)"
"    % else stay 00"
"elseif at_F2"
"    if any_above,     nQ0=true;      % → moving up (01)"
"    elseif any_below, nQ1=true; nQ0=true;  % → moving down (11)"
"    else,             nQ1=false; nQ0=true; % stay Floor2 (01 clarified below)"
"    end"
"    if ~any_above && ~any_below      % no calls, stay Floor2"
"        nQ1=false; nQ0=false;"
"        nQ1=false; nQ0=true;"
"    end"
"elseif at_F3"
"    if any_below, nQ1=true; nQ0=true; end  % → moving down"
"    % else stay 10=Floor3"
"    if ~any_below, nQ1=true; nQ0=false; end"
"elseif moving"
"    % continue in current direction"
"    if nDIR   % going up"
"        if nQF3,         nQ1=true;  nQ0=false;  % arrive Floor3"
"        elseif nQF2,     nQ1=false; nQ0=true;   % arrive Floor2"
"        else,            nQ1=false; nQ0=false;  % back to Floor1"
"        end"
"    else      % going down"
"        if nQF1,         nQ1=false; nQ0=false;  % arrive Floor1"
"        elseif nQF2,     nQ1=false; nQ0=true;   % arrive Floor2"
"        else,            nQ1=true;  nQ0=false;  % stay Floor3"
"        end"
"    end"
"end"
""
"% ---- UP / DOWN output gates ----"
"UP   = any_above & nDIR  & ~moving;"
"DOWN = any_below & ~nDIR & ~moving;"
""
"% ---- Clock edge: update all DFFs ----"
"QF1r=nQF1; QF2r=nQF2; QF3r=nQF3;"
"Q1r=nQ1;   Q0r=nQ0;   DIRr=nDIR;"
""
"% ---- Outputs ----"
"QF1=QF1r; QF2=QF2r; QF3=QF3r;"
"stateQQ = int8(2*Q1r + Q0r);"
}, newline);

rt  = sfroot();
m   = rt.find('-isa','Simulink.BlockDiagram','Name',mdl);
ems = m.find('-isa','Stateflow.EMChart');
for i=1:length(ems)
    if contains(ems(i).Path,'GateCircuit')
        ems(i).Script = seCode;
    end
end

% Wire subsystem internals
gcPH = get_param([SE '/GateCircuit'],'PortHandles');
for k=1:4
    add_line(SE, sePH_in{k}.Outport(1), gcPH.Inport(k),'autorouting','on');
end
for k=1:6
    add_line(SE, gcPH.Outport(k), sePH_out{k}.Inport(1),'autorouting','on');
end

%% ================================================================
%  SINGLE ELEVATOR — DISPLAY BLOCKS
%% ================================================================
seDispNames = {'QF1(call)','QF2(call)','QF3(call)','UP','DOWN','State'};
seDispY     = [30 70 110 150 190 230];
seDispH     = cell(1,6);
sePH_se = get_param([mdl '/Single_Elevator'],'PortHandles');
for k=1:6
    blk = [mdl '/SE_' seDispNames{k}];
    add_block('simulink/Sinks/Display', blk,...
              'Position',[560 seDispY(k)+30 650 seDispY(k)+54]);
    seDispH{k} = get_param(blk,'PortHandles');
end

% Scope for single elevator
add_block('simulink/Sinks/Scope',[mdl '/SE_Scope'],...
          'NumInputPorts','5','Position',[560 290 610 460]);
seScopePH = get_param([mdl '/SE_Scope'],'PortHandles');

%% ================================================================
%  SUBSYSTEM 2 — DUAL ELEVATOR  (below Single_Elevator, y offset 380)
%  Blocks inside: Priority_Controller, Elevator_A, Elevator_B
%% ================================================================
add_block('simulink/Ports & Subsystems/Subsystem',...
          [mdl '/Dual_Elevator'],...
          'Position',[160 370 520 650],...
          'BackgroundColor','yellow');

delete_block([mdl '/Dual_Elevator/In1']);
delete_block([mdl '/Dual_Elevator/Out1']);

DE = [mdl '/Dual_Elevator'];

% Inputs inside dual subsystem
deIn = {'call1','call2','call3','RESET'};
deInY = [30 90 150 210];
dePH_in = cell(1,4);
for k=1:4
    add_block('simulink/Sources/In1',[DE '/de_' deIn{k}],...
              'Position',[20 deInY(k) 50 deInY(k)+20],...
              'OutDataTypeStr','boolean');
    dePH_in{k} = get_param([DE '/de_' deIn{k}],'PortHandles');
end

% Priority Controller block
add_block('simulink/User-Defined Functions/MATLAB Function',...
          [DE '/Priority_Ctrl'],...
          'Position',[110 20 290 370],'BackgroundColor','[1 0.8 0]');

% Elevator A block
add_block('simulink/User-Defined Functions/MATLAB Function',...
          [DE '/Elev_A'],...
          'Position',[360 20 530 190],'BackgroundColor','cyan');

% Elevator B block
add_block('simulink/User-Defined Functions/MATLAB Function',...
          [DE '/Elev_B'],...
          'Position',[360 220 530 390],'BackgroundColor','magenta');

% Unit Delays for feedback
add_block('simulink/Discrete/Unit Delay',[DE '/UD_fA'],...
          'SampleTime','1','InitialCondition','1','OutDataTypeStr','int8',...
          'Position',[600 80 640 104]);
add_block('simulink/Discrete/Unit Delay',[DE '/UD_iA'],...
          'SampleTime','1','InitialCondition','true','OutDataTypeStr','boolean',...
          'Position',[600 120 640 144]);
add_block('simulink/Discrete/Unit Delay',[DE '/UD_fB'],...
          'SampleTime','1','InitialCondition','3','OutDataTypeStr','int8',...
          'Position',[600 280 640 304]);
add_block('simulink/Discrete/Unit Delay',[DE '/UD_iB'],...
          'SampleTime','1','InitialCondition','true','OutDataTypeStr','boolean',...
          'Position',[600 320 640 344]);

% Output ports inside DE
deOuts = {'UP_A','DOWN_A','IDLE_A','Floor_A','UP_B','DOWN_B','IDLE_B','Floor_B'};
deOutY = [30 70 110 150 220 260 300 340];
dePH_out = cell(1,8);
for k=1:8
    add_block('simulink/Sinks/Out1',[DE '/de_out_' deOuts{k}],...
              'Position',[700 deOutY(k) 730 deOutY(k)+20]);
    dePH_out{k} = get_param([DE '/de_out_' deOuts{k}],'PortHandles');
end

% --- Inject code for all MATLAB Function blocks
prioCode = strjoin({
"function [cA1,cA2,cA3,cB1,cB2,cB3] = Priority_Ctrl(c1,c2,c3,RESET,fA,fB,iA,iB)"
"% Priority Controller — assigns each floor call to best elevator"
"cA1=false;cA2=false;cA3=false;"
"cB1=false;cB2=false;cB3=false;"
"if RESET, return; end"
"calls=[logical(c1),logical(c2),logical(c3)];"
"fAd=double(fA); fBd=double(fB);"
"cAv=[false false false]; cBv=[false false false];"
"for fl=1:3"
"  if ~calls(fl), continue; end"
"  dA=abs(fAd-fl); if fAd==0, dA=99; end"
"  dB=abs(fBd-fl); if fBd==0, dB=99; end"
"  if     dA==0 && iA,        cAv(fl)=true;"   % Rule1: A already there
"  elseif dB==0 && iB,        cBv(fl)=true;"   % Rule1: B already there
"  elseif iA && iB && dA<=dB, cAv(fl)=true;"   % Rule2: A closer idle
"  elseif iA && iB && dB<dA,  cBv(fl)=true;"   % Rule2: B closer idle
"  elseif iA,                 cAv(fl)=true;"   % Rule3: only A idle
"  elseif iB,                 cBv(fl)=true;"   % Rule3: only B idle
"  else,                      cAv(fl)=true;"   % Rule4: tie → A wins
"  end"
"end"
"cA1=cAv(1);cA2=cAv(2);cA3=cAv(3);"
"cB1=cBv(1);cB2=cBv(2);cB3=cBv(3);"
}, newline);

elevACode = strjoin({
"function [UP,DOWN,IDLE,floor_num] = Elev_A(c1,c2,c3,RESET)"
"% Elevator A FSM — starts Floor 1"
"% States: 0=Floor1  1=MovingUp  2=Floor2  3=MovingDown  4=Floor3"
"persistent s; if isempty(s), s=int8(0); end"
"UP=(s==int8(1)); DOWN=(s==int8(3));"
"IDLE=(s==int8(0))||(s==int8(2))||(s==int8(4));"
"if s==int8(0),floor_num=int8(1);"
"elseif s==int8(2),floor_num=int8(2);"
"elseif s==int8(4),floor_num=int8(3);"
"else,floor_num=int8(0); end"
"if RESET, s=int8(0); return; end"
"switch s"
"  case int8(0), if c2||c3, s=int8(1); end"
"  case int8(1), if c3,s=int8(4); else,s=int8(2); end"
"  case int8(2), if c3,s=int8(1); elseif c1,s=int8(3); end"
"  case int8(3), if c2&&~c1,s=int8(2); else,s=int8(0); end"
"  case int8(4), if c1||c2,s=int8(3); end"
"end"
}, newline);

elevBCode = strjoin({
"function [UP,DOWN,IDLE,floor_num] = Elev_B(c1,c2,c3,RESET)"
"% Elevator B FSM — starts Floor 3"
"persistent s; if isempty(s), s=int8(4); end"
"UP=(s==int8(1)); DOWN=(s==int8(3));"
"IDLE=(s==int8(0))||(s==int8(2))||(s==int8(4));"
"if s==int8(0),floor_num=int8(1);"
"elseif s==int8(2),floor_num=int8(2);"
"elseif s==int8(4),floor_num=int8(3);"
"else,floor_num=int8(0); end"
"if RESET, s=int8(4); return; end"
"switch s"
"  case int8(0), if c2||c3, s=int8(1); end"
"  case int8(1), if c3,s=int8(4); else,s=int8(2); end"
"  case int8(2), if c3,s=int8(1); elseif c1,s=int8(3); end"
"  case int8(3), if c2&&~c1,s=int8(2); else,s=int8(0); end"
"  case int8(4), if c1||c2,s=int8(3); end"
"end"
}, newline);

% Push code into blocks
ems2 = m.find('-isa','Stateflow.EMChart');
for i=1:length(ems2)
    p=ems2(i).Path;
    if contains(p,'GateCircuit'),    ems2(i).Script=seCode;
    elseif contains(p,'Priority_Ctrl'), ems2(i).Script=prioCode;
    elseif contains(p,'Elev_A'),     ems2(i).Script=elevACode;
    elseif contains(p,'Elev_B'),     ems2(i).Script=elevBCode;
    end
end

%% ================================================================
%  WIRE DUAL ELEVATOR SUBSYSTEM
%% ================================================================
priPH = get_param([DE '/Priority_Ctrl'],'PortHandles');
eAPH  = get_param([DE '/Elev_A'],       'PortHandles');
eBPH  = get_param([DE '/Elev_B'],       'PortHandles');
udFAPH= get_param([DE '/UD_fA'],        'PortHandles');
udIAPH= get_param([DE '/UD_iA'],        'PortHandles');
udFBPH= get_param([DE '/UD_fB'],        'PortHandles');
udIBPH= get_param([DE '/UD_iB'],        'PortHandles');

% calls → Priority
for k=1:3
    add_line(DE, dePH_in{k}.Outport(1), priPH.Inport(k),'autorouting','on');
end
add_line(DE, dePH_in{4}.Outport(1), priPH.Inport(4),'autorouting','on'); % RESET
% feedback → Priority (in 5..8)
add_line(DE, udFAPH.Outport(1), priPH.Inport(5),'autorouting','on');
add_line(DE, udFBPH.Outport(1), priPH.Inport(6),'autorouting','on');
add_line(DE, udIAPH.Outport(1), priPH.Inport(7),'autorouting','on');
add_line(DE, udIBPH.Outport(1), priPH.Inport(8),'autorouting','on');

% Priority → Elev A (cA1,cA2,cA3,RESET)
for k=1:3
    add_line(DE, priPH.Outport(k), eAPH.Inport(k),'autorouting','on');
end
add_line(DE, dePH_in{4}.Outport(1), eAPH.Inport(4),'autorouting','on');

% Priority → Elev B (cB1,cB2,cB3,RESET)
for k=1:3
    add_line(DE, priPH.Outport(k+3), eBPH.Inport(k),'autorouting','on');
end
add_line(DE, dePH_in{4}.Outport(1), eBPH.Inport(4),'autorouting','on');

% Elev A → Unit Delays (feedback)
add_line(DE, eAPH.Outport(4), udFAPH.Inport(1),'autorouting','on'); % floor
add_line(DE, eAPH.Outport(3), udIAPH.Inport(1),'autorouting','on'); % IDLE

% Elev B → Unit Delays (feedback)
add_line(DE, eBPH.Outport(4), udFBPH.Inport(1),'autorouting','on');
add_line(DE, eBPH.Outport(3), udIBPH.Inport(1),'autorouting','on');

% Elev A/B → output ports
for k=1:4
    add_line(DE, eAPH.Outport(k), dePH_out{k}.Inport(1),'autorouting','on');
    add_line(DE, eBPH.Outport(k), dePH_out{k+4}.Inport(1),'autorouting','on');
end

%% ================================================================
%  WIRE TOP-LEVEL MODEL
%  shared inputs → both subsystems
%% ================================================================
sePH = get_param([mdl '/Single_Elevator'],'PortHandles');
dePH = get_param([mdl '/Dual_Elevator'],  'PortHandles');

for k=1:4
    % → Single_Elevator
    add_line(mdl, iPH{k}.Outport(1), sePH.Inport(k),'autorouting','on');
    % → Dual_Elevator
    add_line(mdl, iPH{k}.Outport(1), dePH.Inport(k),'autorouting','on');
end

%% ================================================================
%  SINGLE ELEVATOR DISPLAYS  (right of subsystem)
%% ================================================================
for k=1:6
    add_line(mdl, sePH.Outport(k), seDispH{k}.Inport(1),'autorouting','on');
end
% Scope: UP(4), DOWN(5), State(6), QF1(1), QF2(2)
add_line(mdl, sePH.Outport(1), seScopePH.Inport(1),'autorouting','on');
add_line(mdl, sePH.Outport(2), seScopePH.Inport(2),'autorouting','on');
add_line(mdl, sePH.Outport(4), seScopePH.Inport(3),'autorouting','on');
add_line(mdl, sePH.Outport(5), seScopePH.Inport(4),'autorouting','on');
add_line(mdl, sePH.Outport(6), seScopePH.Inport(5),'autorouting','on');

%% ================================================================
%  DUAL ELEVATOR DISPLAYS  (right of subsystem)
%% ================================================================
deDispNames={'UP_A','DOWN_A','IDLE_A','Floor_A','UP_B','DOWN_B','IDLE_B','Floor_B'};
deDispY=[380 420 460 500 540 580 620 660];
deScopePH_blk = [mdl '/DE_Scope'];
add_block('simulink/Sinks/Scope',deScopePH_blk,...
          'NumInputPorts','8','Position',[760 370 810 640]);
deScopePH = get_param(deScopePH_blk,'PortHandles');

for k=1:8
    blk=[mdl '/DE_' deDispNames{k}];
    add_block('simulink/Sinks/Display',blk,...
              'Position',[660 deDispY(k) 750 deDispY(k)+24]);
    dh = get_param(blk,'PortHandles');
    add_line(mdl, dePH.Outport(k), dh.Inport(1),'autorouting','on');
    add_line(mdl, dePH.Outport(k), deScopePH.Inport(k),'autorouting','on');
end

%% ================================================================
%  LABELS / ANNOTATIONS
%% ================================================================
add_block('built-in/Note',[mdl '/Label_SE'],...
          'Position',[160 12 520 28],...
          'AttributesFormatString',...
          '--- SINGLE ELEVATOR (gate-level: call-register DFFs + state DFFs + DIR DFF + ANY_ABOVE/BELOW logic) ---');
add_block('built-in/Note',[mdl '/Label_DE'],...
          'Position',[160 352 520 368],...
          'AttributesFormatString',...
          '--- DUAL ELEVATOR  (Elevator A=cyan starts F1 | Elevator B=magenta starts F3 | Priority Controller=gold) ---');

%% ================================================================
%  ARRANGE & SAVE
%% ================================================================
Simulink.BlockDiagram.arrangeSystem(mdl);
save_system(mdl, fullfile(pwd,'ElevatorSystem.slx'));

disp('=========================================================');
disp('  ElevatorSystem.slx  created — open in MATLAB Simulink');
disp('=========================================================');
disp(' ');
disp('  SET INPUTS (double-click Constant blocks, change to 0/1):');
disp('    call1 = Floor 1 button    call2 = Floor 2 button');
disp('    call3 = Floor 3 button    RESET = send home');
disp(' ');
disp('  SUBSYSTEM 1 — Single_Elevator (CYAN)');
disp('    Gate-level circuit: call-register DFFs, state Q1/Q0,');
disp('    DIR flip-flop, ANY_ABOVE/ANY_BELOW logic → UP / DOWN');
disp(' ');
disp('  SUBSYSTEM 2 — Dual_Elevator (YELLOW)');
disp('    Elevator A (cyan)   starts Floor 1');
disp('    Elevator B (magenta) starts Floor 3');
disp('    Priority: closest idle wins | tie → Elevator A');
disp(' ');
disp('  Press Ctrl+T to simulate.');

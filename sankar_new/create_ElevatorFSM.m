%% =========================================================
%  Elevator Call Processing – FSM + Digital Circuit
%  Run this script in MATLAB to auto-generate ElevatorFSM.slx
%
%  States  : Floor_1 | Moving_Up | Floor_2 | Moving_Down | Floor_3
%  Inputs  : c1, c2, c3  (call buttons), RESET, CLK
%  Outputs : UP, DOWN, IDLE, current_floor
%
%  Digital-circuit layer uses D flip-flops + logic gates
%  (mirrors the Logisim layout shown in the reference image).
%% =========================================================

function create_ElevatorFSM()

modelName = 'ElevatorFSM';

%% --- Close / clean up any previous session ---
if bdIsLoaded(modelName)
    close_system(modelName, 0);
end
if exist([modelName '.slx'], 'file')
    delete([modelName '.slx']);
end

%% === 1. CREATE MODEL =====================================
new_system(modelName);
open_system(modelName);

% Fixed-step discrete solver (digital logic)
set_param(modelName, 'SolverType',   'Fixed-step');
set_param(modelName, 'Solver',       'FixedStepDiscrete');
set_param(modelName, 'FixedStep',    '1');
set_param(modelName, 'StopTime',     '60');
set_param(modelName, 'SystemTargetFile', 'grt.tlc');

%% === 2. STATEFLOW FSM CHART ==============================
% Add the Stateflow chart block
chartPos = [300 80 700 480];
sfBlock  = add_block('sflib/Chart', [modelName '/ElevatorController'], ...
                     'Position', chartPos);
set_param(sfBlock, 'BackgroundColor', 'cyan');

% Access the chart via Stateflow API
rt    = sfroot();
mdl   = rt.find('-isa','Simulink.BlockDiagram','Name', modelName);
chart = mdl.find('-isa','Stateflow.Chart');
chart.ChartUpdate       = 'DISCRETE';
chart.ExecutionOrder    = 1;
chart.ActionLanguage    = 'MATLAB';

% ---- Chart-level data (I/O) --------------------------------
function d = addData(chart, name, scope, dtype, initVal)
    d           = Stateflow.Data(chart);
    d.Name      = name;
    d.Scope     = scope;
    d.DataType  = dtype;
    if nargin == 5
        d.Props.InitialValue = num2str(initVal);
    end
end

addData(chart,'c1',           'Input',  'boolean');
addData(chart,'c2',           'Input',  'boolean');
addData(chart,'c3',           'Input',  'boolean');
addData(chart,'RESET',        'Input',  'boolean');
addData(chart,'UP',           'Output', 'boolean', 0);
addData(chart,'DOWN',         'Output', 'boolean', 0);
addData(chart,'IDLE',         'Output', 'boolean', 1);
addData(chart,'current_floor','Output', 'uint8',   1);

% ---- Helper: create a state ------------------------------------
function s = makeState(chart, name, posRect, labelStr)
    s              = Stateflow.State(chart);
    s.Name         = name;
    s.Position     = posRect;
    s.LabelString  = labelStr;
end

% State positions  [x  y   w   h]
pF1  = [ 30  60 200  90];
pMU  = [280  60 200  90];
pF2  = [530  60 200  90];
pMD  = [530 240 200  90];
pF3  = [280 240 200  90];

sF1 = makeState(chart,'Floor_1',pF1, ...
    ['Floor_1\n' ...
     'entry: IDLE=true; UP=false; DOWN=false; current_floor=uint8(1);']);

sMU = makeState(chart,'Moving_Up',pMU, ...
    ['Moving_Up\n' ...
     'entry: UP=true; DOWN=false; IDLE=false;']);

sF2 = makeState(chart,'Floor_2',pF2, ...
    ['Floor_2\n' ...
     'entry: IDLE=true; UP=false; DOWN=false; current_floor=uint8(2);']);

sMD = makeState(chart,'Moving_Down',pMD, ...
    ['Moving_Down\n' ...
     'entry: DOWN=true; UP=false; IDLE=false;']);

sF3 = makeState(chart,'Floor_3',pF3, ...
    ['Floor_3\n' ...
     'entry: IDLE=true; UP=false; DOWN=false; current_floor=uint8(3);']);

% ---- Default transition → Floor_1 --------------------------
dt             = Stateflow.Transition(chart);
dt.Destination = sF1;
dt.DestinationOClock = 9;

% ---- Helper: add a transition ------------------------------
function addTrans(src, dst, label)
    t              = Stateflow.Transition(chart);
    t.Source       = src;
    t.Destination  = dst;
    t.LabelString  = label;
end

% Floor_1 → Moving_Up   when any upper floor is called
addTrans(sF1, sMU, '[~RESET && (c2||c3)]');
% Floor_1 → Floor_1     self-loop (stay if only local call or no call)
addTrans(sF1, sF1, '[~RESET && ~c2 && ~c3]');

% Moving_Up → Floor_2   stop at 2 if c2 requested & no c3
addTrans(sMU, sF2, '[~RESET && c2 && ~c3]');
% Moving_Up → Floor_3   pass through / stop at 3
addTrans(sMU, sF3, '[~RESET && c3]');

% Floor_2 → Moving_Up   if c3 called
addTrans(sF2, sMU, '[~RESET && c3]');
% Floor_2 → Moving_Down if c1 called (and no c3)
addTrans(sF2, sMD, '[~RESET && c1 && ~c3]');
% Floor_2 → Floor_2     no action
addTrans(sF2, sF2, '[~RESET && ~c1 && ~c3]');

% Floor_3 → Moving_Down if a lower floor is called
addTrans(sF3, sMD, '[~RESET && (c1||c2)]');
% Floor_3 → Floor_3     no calls
addTrans(sF3, sF3, '[~RESET && ~c1 && ~c2]');

% Moving_Down → Floor_2 stop at 2 if c2 needed & c1 not required
addTrans(sMD, sF2, '[~RESET && c2 && ~c1]');
% Moving_Down → Floor_1
addTrans(sMD, sF1, '[~RESET && ~c2 && c1]');
% Moving_Down → Floor_1 direct (no stops)
addTrans(sMD, sF1, '[~RESET && c1 && ~c2]');

% RESET from anywhere → Floor_1
addTrans(sMU, sF1, '[RESET]');
addTrans(sF2, sF1, '[RESET]');
addTrans(sF3, sF1, '[RESET]');
addTrans(sMD, sF1, '[RESET]');

fprintf('✓  Stateflow FSM chart created.\n');

%% === 3. INPUT SIGNAL BLOCKS ==============================
% Place on the left side of the model
y_base = 100;
dy     = 60;

inputs = {'c1','c2','c3','RESET'};
inHandles = containers.Map();

for k = 1:numel(inputs)
    bname = [modelName '/In_' inputs{k}];
    bh = add_block('simulink/Sources/In1', bname, ...
                   'Position', [50, y_base+(k-1)*dy, 100, y_base+(k-1)*dy+30]);
    set_param(bh, 'PortDataType', 'boolean');
    set_param(bh, 'Name', ['In_' inputs{k}]);
    inHandles(inputs{k}) = bh;
end

%% === 4. OUTPUT DISPLAY BLOCKS ============================
y_out = 100;
dy_o  = 60;
outputs = {'UP','DOWN','IDLE','current_floor'};
outHandles = containers.Map();

for k = 1:numel(outputs)
    bname = [modelName '/Out_' outputs{k}];
    bh    = add_block('simulink/Sinks/Out1', bname, ...
                      'Position', [800, y_out+(k-1)*dy_o, 860, y_out+(k-1)*dy_o+30]);
    set_param(bh, 'Name', ['Out_' outputs{k}]);
    outHandles(outputs{k}) = bh;
end

%% === 5. CONNECT INPUTS TO CHART ==========================
% Chart ports: inputs c1=1,c2=2,c3=3,RESET=4
% Connect each input In_ block to corresponding chart port
for k = 1:numel(inputs)
    srcPort = get_param(inHandles(inputs{k}), 'PortHandles');
    dstPort = get_param(sfBlock, 'PortHandles');
    add_line(modelName, srcPort.Outport(1), dstPort.Inport(k), ...
             'autorouting','on');
end

%% === 6. CONNECT CHART OUTPUTS TO OUT BLOCKS ==============
chartPH = get_param(sfBlock, 'PortHandles');
for k = 1:numel(outputs)
    dstPH = get_param(outHandles(outputs{k}), 'PortHandles');
    add_line(modelName, chartPH.Outport(k), dstPH.Inport(1), ...
             'autorouting','on');
end

fprintf('✓  Input/Output connections done.\n');

%% === 7. SCOPE / DISPLAY for UP / DOWN / IDLE =============
scopePos = [900 80 960 460];
scopeH   = add_block('simulink/Sinks/Scope', [modelName '/Scope_Outputs'], ...
                     'Position', scopePos, ...
                     'NumInputPorts', '4', ...
                     'BackgroundColor', 'yellow');
set_param(scopeH, 'SaveToWorkspace', 'on');
set_param(scopeH, 'SaveName',        'ElevatorScope');

chartPH2 = get_param(sfBlock, 'PortHandles');
scopePH  = get_param(scopeH,  'PortHandles');
for k = 1:4
    add_line(modelName, chartPH2.Outport(k), scopePH.Inport(k), ...
             'autorouting','on');
end

%% === 8. DIGITAL CIRCUIT SUBSYSTEM ========================
%  Implements the SAME FSM using D flip-flops + combinational
%  logic gates  (mirrors the Logisim image).
%  State encoding (3 bits Q2 Q1 Q0):
%    Floor_1    = 000
%    Moving_Up  = 001
%    Floor_2    = 010
%    Moving_Down= 011
%    Floor_3    = 100

dcName = [modelName '/Digital_Circuit'];
dcH    = add_block('simulink/Ports & Subsystems/Subsystem', dcName, ...
                   'Position', [300 520 700 800], ...
                   'BackgroundColor', 'green');

% Delete default in/out inside the subsystem
delete_block([dcName '/In1']);
delete_block([dcName '/Out1']);

% ---- Subsystem inputs  -----------------------------------
dcInputs  = {'c1','c2','c3','RESET','CLK'};
dcOutputs = {'UP','DOWN','IDLE','Q2','Q1','Q0'};

dcInH = struct();
for k = 1:numel(dcInputs)
    bh = add_block('simulink/Sources/In1', ...
                   [dcName '/dcIn_' dcInputs{k}], ...
                   'Position',[30, 50+k*55, 80, 50+k*55+28], ...
                   'PortDataType','boolean');
    set_param(bh,'Name',['dcIn_' dcInputs{k}]);
    dcInH.(dcInputs{k}) = bh;
end

dcOutH = struct();
for k = 1:numel(dcOutputs)
    bh = add_block('simulink/Sinks/Out1', ...
                   [dcName '/dcOut_' dcOutputs{k}], ...
                   'Position',[900, 50+k*55, 950, 50+k*55+28]);
    set_param(bh,'Name',['dcOut_' dcOutputs{k}]);
    dcOutH.(dcOutputs{k}) = bh;
end

% ---- 3 D Flip-Flops (Unit Delay = D flip-flop in discrete)
dffPos = {[500  80 560 120], [500 160 560 200], [500 240 560 280]};
dffNames = {'DFF_Q2','DFF_Q1','DFF_Q0'};
dffH = struct();
for k = 1:3
    bh = add_block('simulink/Discrete/Unit Delay', ...
                   [dcName '/' dffNames{k}], ...
                   'Position', dffPos{k}, ...
                   'SampleTime','1', ...
                   'InitialCondition','0', ...
                   'OutDataTypeStr','boolean');
    dffH.(dffNames{k}) = bh;
end

% ---- MUX to bundle Q2,Q1,Q0 into current state -----------
muxH = add_block('simulink/Signal Routing/Mux', ...
                 [dcName '/State_Mux'], ...
                 'Position',[620 120 660 280], ...
                 'Inputs','3');

% ---- Next-state & output logic via MATLAB Function block -
nslH = add_block('simulink/User-Defined Functions/MATLAB Function', ...
                 [dcName '/NextState_OutputLogic'], ...
                 'Position',[720 80 880 480]);

% Set the MATLAB function code inside the block
nslCode = [...
'function [nQ2,nQ1,nQ0,UP,DOWN,IDLE] = NextState_OutputLogic(c1,c2,c3,RESET,Q2,Q1,Q0)\n'...
'%% Elevator FSM – combinational next-state & output logic\n'...
'%  State encoding: Floor_1=000, Moving_Up=001, Floor_2=010,\n'...
'%                  Moving_Down=011, Floor_3=100\n'...
'\n'...
'%  Pack current state\n'...
'state = 4*Q2 + 2*Q1 + Q0;   % integer 0..4\n'...
'\n'...
'%  Defaults\n'...
'nQ2=false; nQ1=false; nQ0=false;\n'...
'UP=false; DOWN=false; IDLE=false;\n'...
'\n'...
'if RESET\n'...
'    % Force Floor_1 (000)\n'...
'    nQ2=false; nQ1=false; nQ0=false;\n'...
'    IDLE=true;\n'...
'    return;\n'...
'end\n'...
'\n'...
'switch state\n'...
'  case 0  %% Floor_1 (000)\n'...
'    IDLE = true;\n'...
'    if c2||c3          % go up\n'...
'        nQ0 = true;   % → Moving_Up (001)\n'...
'    end\n'...
'\n'...
'  case 1  %% Moving_Up (001)\n'...
'    UP = true;\n'...
'    if c3              % keep going to floor 3\n'...
'        nQ2=true; nQ1=false; nQ0=false;  % → Floor_3 (100)\n'...
'    elseif c2          % stop at floor 2\n'...
'        nQ1=true; nQ0=false;             % → Floor_2 (010)\n'...
'    else               % no pending—stop at floor 2 anyway\n'...
'        nQ1=true; nQ0=false;\n'...
'    end\n'...
'\n'...
'  case 2  %% Floor_2 (010)\n'...
'    IDLE = true;\n'...
'    if c3              % go up to floor 3\n'...
'        nQ0 = true;   % → Moving_Up (011 via 001?)\n'...
'        nQ1 = false;  % re-enter Moving_Up = 001\n'...
'    elseif c1          % go down to floor 1\n'...
'        nQ1=true; nQ0=true;  % → Moving_Down (011)\n'...
'    else\n'...
'        nQ1=true;            % stay Floor_2 (010)\n'...
'    end\n'...
'\n'...
'  case 3  %% Moving_Down (011)\n'...
'    DOWN = true;\n'...
'    if c2              % stop at floor 2\n'...
'        nQ1=true;     % → Floor_2 (010)\n'...
'    else               % continue to floor 1\n'...
'        % → Floor_1 (000)  all zeros\n'...
'    end\n'...
'\n'...
'  case 4  %% Floor_3 (100)\n'...
'    IDLE = true;\n'...
'    if c1||c2          % go down\n'...
'        nQ1=true; nQ0=true; % → Moving_Down (011)\n'...
'    else\n'...
'        nQ2=true;           % stay Floor_3 (100)\n'...
'    end\n'...
'\n'...
'  otherwise\n'...
'    IDLE = true;  % safe default\n'...
'end\n'...
];

% Write the function into the block via set_param
set_param(nslH, 'FunctionName', 'NextState_OutputLogic');

fprintf('✓  Digital circuit subsystem skeleton created.\n');
fprintf('   (Open the Digital_Circuit subsystem to view gate layout.)\n');

%% === 9. ANNOTATION / LABELS ==============================
add_block('built-in/Note', [modelName '/Note1'], ...
    'Position',[30 20 400 55], ...
    'AttributesFormatString', ...
    'ELEVATOR FSM  –  Floor_1 | Moving_Up | Floor_2 | Moving_Down | Floor_3');

add_block('built-in/Note', [modelName '/Note2'], ...
    'Position',[300 490 720 520], ...
    'AttributesFormatString', ...
    'Digital Circuit Subsystem  (D flip-flops + combinational logic)');

%% === 10. ARRANGE & SAVE ==================================
Simulink.BlockDiagram.arrangeSystem(modelName);
save_system(modelName, fullfile(pwd, [modelName '.slx']));
fprintf('\n================================================\n');
fprintf(' Model saved:  %s\n', fullfile(pwd, [modelName '.slx']));
fprintf('================================================\n');
fprintf(' Open MATLAB → run  create_ElevatorFSM()  to rebuild.\n');
fprintf(' Then press Ctrl+T (or Run) to simulate.\n\n');
fprintf(' Inputs (constant/pulse generators recommended):\n');
fprintf('   In_c1, In_c2, In_c3  – boolean floor-call pulses\n');
fprintf('   In_RESET              – boolean high to reset\n\n');
fprintf(' Outputs:\n');
fprintf('   Out_UP, Out_DOWN, Out_IDLE, Out_current_floor\n');
fprintf('================================================\n');

end   %% end function create_ElevatorFSM

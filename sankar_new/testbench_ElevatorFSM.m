%% =========================================================
%  Elevator FSM – Software Testbench (pure MATLAB, no Simulink)
%  Validates next-state & output logic before running .slx
%% =========================================================

clear; clc;
fprintf('====== Elevator FSM Testbench ======\n\n');

%% ---- Initial state: Floor_1 (000) ----------------------
Q2=false; Q1=false; Q0=false;
state_names = {'Floor_1','Moving_Up','Floor_2','Moving_Down','Floor_3','???','???','???'};

function name = stateName(Q2,Q1,Q0)
    idx = 4*Q2 + 2*Q1 + Q0 + 1;
    names = {'Floor_1','Moving_Up','Floor_2','Moving_Down','Floor_3','???','???','???'};
    name = names{idx};
end

%% ---- Simulation scenario --------------------------------
%  t  c1  c2  c3   RESET   Description
scenario = [
%  t   c1   c2   c3   RST
    1   0    0    0    1 ;   % RESET
    2   0    0    0    0 ;   % idle at floor 1
    3   0    0    1    0 ;   % call to floor 3
    4   0    0    1    0 ;   % still moving up
    5   0    0    0    0 ;   % arrived at floor 3
    6   0    1    0    0 ;   % call floor 2 from floor 3
    7   0    1    0    0 ;   % moving down
    8   0    0    0    0 ;   % arrived floor 2
    9   1    0    0    0 ;   % call floor 1
   10   1    0    0    0 ;   % moving down
   11   0    0    0    0 ;   % arrived floor 1
   12   0    1    0    0 ;   % call floor 2 again
   13   0    1    1    0 ;   % also call floor 3
   14   0    0    0    0 ;   % at floor 3
   15   0    0    0    1 ;   % RESET
];

fprintf('%-4s %-6s %-6s %-6s %-5s | %-14s | %-4s %-4s %-4s\n',...
        'Tick','c1','c2','c3','RST','State','UP','DWN','IDL');
fprintf('%s\n', repmat('-',1,65));

for row = 1:size(scenario,1)
    t    = scenario(row,1);
    c1   = logical(scenario(row,2));
    c2   = logical(scenario(row,3));
    c3   = logical(scenario(row,4));
    RST  = logical(scenario(row,5));

    [nQ2,nQ1,nQ0,UP,DOWN,IDLE] = ElevatorNextState(c1,c2,c3,RST,Q2,Q1,Q0);

    fprintf('%-4d %-6d %-6d %-6d %-5d | %-14s | %-4d %-4d %-4d\n',...
            t, c1, c2, c3, RST, stateName(Q2,Q1,Q0), UP, DOWN, IDLE);

    % Clock edge: flip-flops capture next state
    Q2=nQ2; Q1=nQ1; Q0=nQ0;
end

fprintf('\n');
fprintf('✓  All %d clock cycles simulated.\n', size(scenario,1));
fprintf('\nTo build the Simulink model (.slx), run:\n');
fprintf('   >> create_ElevatorFSM\n');

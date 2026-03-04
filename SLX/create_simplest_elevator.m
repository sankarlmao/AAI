%% SIMPLEST Elevator Simulink Model
% This creates the most basic working elevator model
% Easy to understand and modify
% Date: March 2026

function create_simplest_elevator()
    modelName = 'elevator_simple';
    
    % Cleanup
    if bdIsLoaded(modelName), close_system(modelName, 0); end
    if exist([modelName '.slx'], 'file'), delete([modelName '.slx']); end
    
    fprintf('Creating Simplest Elevator Model...\n');
    
    new_system(modelName);
    open_system(modelName);
    
    %% ===== INPUTS =====
    % Target Floor Selector (1, 2, or 3)
    add_block('simulink/Sources/Constant', [modelName '/Target_Floor']);
    set_param([modelName '/Target_Floor'], 'Position', [50, 100, 100, 130]);
    set_param([modelName '/Target_Floor'], 'Value', '1');  % Change this to 1, 2, or 3
    set_param([modelName '/Target_Floor'], 'BackgroundColor', 'green');
    
    %% ===== CURRENT FLOOR (Integrator with limits) =====
    % Subtract to get error
    add_block('simulink/Math Operations/Sum', [modelName '/Error']);
    set_param([modelName '/Error'], 'Position', [170, 100, 200, 130]);
    set_param([modelName '/Error'], 'Inputs', '+-');
    
    % Gain for motor speed
    add_block('simulink/Math Operations/Gain', [modelName '/Motor_Gain']);
    set_param([modelName '/Motor_Gain'], 'Position', [230, 100, 260, 130]);
    set_param([modelName '/Motor_Gain'], 'Gain', '0.5');  % Speed control
    
    % Saturation for motor limits
    add_block('simulink/Discontinuities/Saturation', [modelName '/Motor_Limit']);
    set_param([modelName '/Motor_Limit'], 'Position', [290, 100, 320, 130]);
    set_param([modelName '/Motor_Limit'], 'LowerLimit', '-1');
    set_param([modelName '/Motor_Limit'], 'UpperLimit', '1');
    
    % Integrator = Position (Current Floor)
    add_block('simulink/Continuous/Integrator', [modelName '/Elevator_Position']);
    set_param([modelName '/Elevator_Position'], 'Position', [350, 100, 380, 130]);
    set_param([modelName '/Elevator_Position'], 'InitialCondition', '1');
    set_param([modelName '/Elevator_Position'], 'LowerSaturationLimit', '1');
    set_param([modelName '/Elevator_Position'], 'UpperSaturationLimit', '3');
    
    %% ===== OUTPUTS =====
    % Round for discrete floor number
    add_block('simulink/Math Operations/Rounding Function', [modelName '/Round_Floor']);
    set_param([modelName '/Round_Floor'], 'Position', [420, 100, 450, 130]);
    
    % Current Floor Display
    add_block('simulink/Sinks/Display', [modelName '/Current_Floor_Display']);
    set_param([modelName '/Current_Floor_Display'], 'Position', [500, 95, 580, 135]);
    set_param([modelName '/Current_Floor_Display'], 'BackgroundColor', 'cyan');
    
    % Motor Direction Display
    add_block('simulink/Sinks/Display', [modelName '/Motor_Display']);
    set_param([modelName '/Motor_Display'], 'Position', [500, 160, 580, 200]);
    set_param([modelName '/Motor_Display'], 'BackgroundColor', 'orange');
    
    % Scope for visualization
    add_block('simulink/Sinks/Scope', [modelName '/Elevator_Scope']);
    set_param([modelName '/Elevator_Scope'], 'Position', [500, 230, 540, 270]);
    set_param([modelName '/Elevator_Scope'], 'NumInputPorts', '2');
    
    %% ===== DOOR LOGIC =====
    % Door opens when motor speed is near zero
    add_block('simulink/Math Operations/Abs', [modelName '/Abs_Motor']);
    set_param([modelName '/Abs_Motor'], 'Position', [350, 180, 380, 210]);
    
    add_block('simulink/Logic and Bit Operations/Compare To Constant', [modelName '/Is_Stopped']);
    set_param([modelName '/Is_Stopped'], 'Position', [400, 180, 430, 210]);
    set_param([modelName '/Is_Stopped'], 'relop', '<=');
    set_param([modelName '/Is_Stopped'], 'const', '0.05');
    
    add_block('simulink/Sinks/Display', [modelName '/Door_Display']);
    set_param([modelName '/Door_Display'], 'Position', [500, 295, 580, 335]);
    set_param([modelName '/Door_Display'], 'BackgroundColor', 'lightBlue');
    
    %% ===== LABELS =====
    % Add text annotations
    annotation = Simulink.Annotation([modelName '/InputLabel']);
    annotation.Text = 'INPUT:\nSet Target_Floor to 1, 2, or 3';
    annotation.Position = [50, 60];
    
    annotation2 = Simulink.Annotation([modelName '/OutputLabel']);
    annotation2.Text = 'OUTPUTS:\nFloor: Current position\nMotor: +ve=UP, -ve=DOWN\nDoor: 1=OPEN, 0=CLOSED';
    annotation2.Position = [500, 30];
    
    %% ===== CONNECT =====
    add_line(modelName, 'Target_Floor/1', 'Error/1');
    add_line(modelName, 'Elevator_Position/1', 'Error/2', 'autorouting', 'on');
    add_line(modelName, 'Error/1', 'Motor_Gain/1');
    add_line(modelName, 'Motor_Gain/1', 'Motor_Limit/1');
    add_line(modelName, 'Motor_Limit/1', 'Elevator_Position/1');
    add_line(modelName, 'Elevator_Position/1', 'Round_Floor/1');
    add_line(modelName, 'Round_Floor/1', 'Current_Floor_Display/1');
    add_line(modelName, 'Motor_Limit/1', 'Motor_Display/1', 'autorouting', 'on');
    add_line(modelName, 'Motor_Limit/1', 'Abs_Motor/1', 'autorouting', 'on');
    add_line(modelName, 'Abs_Motor/1', 'Is_Stopped/1');
    add_line(modelName, 'Is_Stopped/1', 'Door_Display/1', 'autorouting', 'on');
    add_line(modelName, 'Round_Floor/1', 'Elevator_Scope/1', 'autorouting', 'on');
    add_line(modelName, 'Motor_Limit/1', 'Elevator_Scope/2', 'autorouting', 'on');
    
    %% ===== SIMULATION SETTINGS =====
    set_param(modelName, 'StopTime', '20');
    set_param(modelName, 'Solver', 'ode45');
    
    %% ===== SAVE =====
    save_system(modelName);
    
    fprintf('\n');
    fprintf('╔═══════════════════════════════════════════════════════════╗\n');
    fprintf('║        SIMPLEST ELEVATOR MODEL CREATED                    ║\n');
    fprintf('║              %s.slx                              ║\n', modelName);
    fprintf('╠═══════════════════════════════════════════════════════════╣\n');
    fprintf('║                                                           ║\n');
    fprintf('║  HOW TO USE:                                              ║\n');
    fprintf('║  ─────────────────────────────────────────────────────    ║\n');
    fprintf('║  1. Double-click the green "Target_Floor" block           ║\n');
    fprintf('║  2. Change the value to: 1, 2, or 3                       ║\n');
    fprintf('║  3. Click "Run" button                                    ║\n');
    fprintf('║  4. Watch the elevator move to target floor!              ║\n');
    fprintf('║                                                           ║\n');
    fprintf('║  WHAT YOU''LL SEE:                                         ║\n');
    fprintf('║  ─────────────────────────────────────────────────────    ║\n');
    fprintf('║  • Current_Floor_Display: Shows floor 1, 2, or 3          ║\n');
    fprintf('║  • Motor_Display: +ve=Going UP, -ve=Going DOWN, 0=Stop    ║\n');
    fprintf('║  • Door_Display: 1=Door OPEN, 0=Door CLOSED               ║\n');
    fprintf('║  • Elevator_Scope: Visual graph of movement               ║\n');
    fprintf('║                                                           ║\n');
    fprintf('╚═══════════════════════════════════════════════════════════╝\n');
end

% Run the function
create_simplest_elevator();

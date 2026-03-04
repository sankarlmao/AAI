%% Interactive 3-Button Elevator Model
% Three separate buttons to call floors - most user-friendly
% Date: March 2026

function create_3button_elevator()
    modelName = 'elevator_3button';
    
    % Cleanup
    if bdIsLoaded(modelName), close_system(modelName, 0); end
    if exist([modelName '.slx'], 'file'), delete([modelName '.slx']); end
    
    fprintf('Creating 3-Button Elevator Model...\n');
    
    new_system(modelName);
    open_system(modelName);
    
    %% =========== FLOOR 1 BUTTON ===========
    add_block('simulink/Sources/Constant', [modelName '/BTN_Floor1']);
    set_param([modelName '/BTN_Floor1'], 'Position', [50, 40, 110, 70]);
    set_param([modelName '/BTN_Floor1'], 'Value', '0');
    set_param([modelName '/BTN_Floor1'], 'BackgroundColor', '[0.2, 0.8, 0.2]');  % Green
    
    add_block('simulink/Math Operations/Gain', [modelName '/G1']);
    set_param([modelName '/G1'], 'Position', [140, 45, 165, 65]);
    set_param([modelName '/G1'], 'Gain', '1');
    
    %% =========== FLOOR 2 BUTTON ===========
    add_block('simulink/Sources/Constant', [modelName '/BTN_Floor2']);
    set_param([modelName '/BTN_Floor2'], 'Position', [50, 100, 110, 130]);
    set_param([modelName '/BTN_Floor2'], 'Value', '0');
    set_param([modelName '/BTN_Floor2'], 'BackgroundColor', '[0.9, 0.9, 0.2]');  % Yellow
    
    add_block('simulink/Math Operations/Gain', [modelName '/G2']);
    set_param([modelName '/G2'], 'Position', [140, 105, 165, 125]);
    set_param([modelName '/G2'], 'Gain', '2');
    
    %% =========== FLOOR 3 BUTTON ===========
    add_block('simulink/Sources/Constant', [modelName '/BTN_Floor3']);
    set_param([modelName '/BTN_Floor3'], 'Position', [50, 160, 110, 190]);
    set_param([modelName '/BTN_Floor3'], 'Value', '0');
    set_param([modelName '/BTN_Floor3'], 'BackgroundColor', '[0.9, 0.3, 0.3]');  % Red
    
    add_block('simulink/Math Operations/Gain', [modelName '/G3']);
    set_param([modelName '/G3'], 'Position', [140, 165, 165, 185]);
    set_param([modelName '/G3'], 'Gain', '3');
    
    %% =========== TARGET CALCULATION ===========
    % Sum of button presses
    add_block('simulink/Math Operations/Sum', [modelName '/ButtonSum']);
    set_param([modelName '/ButtonSum'], 'Position', [200, 95, 230, 135]);
    set_param([modelName '/ButtonSum'], 'Inputs', '+++');
    
    % Count active buttons
    add_block('simulink/Math Operations/Sum', [modelName '/CountSum']);
    set_param([modelName '/CountSum'], 'Position', [200, 160, 230, 200]);
    set_param([modelName '/CountSum'], 'Inputs', '+++');
    
    % Divide to get average target (priority)
    add_block('simulink/Math Operations/Divide', [modelName '/Average']);
    set_param([modelName '/Average'], 'Position', [270, 115, 300, 150]);
    
    % Prevent divide by zero
    add_block('simulink/Math Operations/MinMax', [modelName '/MaxOne']);
    set_param([modelName '/MaxOne'], 'Position', [250, 170, 280, 195]);
    set_param([modelName '/MaxOne'], 'Function', 'max');
    set_param([modelName '/MaxOne'], 'Inputs', '2');
    
    add_block('simulink/Sources/Constant', [modelName '/OneConst']);
    set_param([modelName '/OneConst'], 'Position', [200, 205, 230, 225]);
    set_param([modelName '/OneConst'], 'Value', '1');
    
    %% =========== ELEVATOR CONTROL LOOP ===========
    % Error calculation
    add_block('simulink/Math Operations/Sum', [modelName '/Error']);
    set_param([modelName '/Error'], 'Position', [350, 115, 380, 145]);
    set_param([modelName '/Error'], 'Inputs', '+-');
    
    % Motor speed gain
    add_block('simulink/Math Operations/Gain', [modelName '/MotorGain']);
    set_param([modelName '/MotorGain'], 'Position', [410, 115, 440, 145]);
    set_param([modelName '/MotorGain'], 'Gain', '0.3');
    
    % Motor saturation
    add_block('simulink/Discontinuities/Saturation', [modelName '/MotorSat']);
    set_param([modelName '/MotorSat'], 'Position', [470, 115, 500, 145]);
    set_param([modelName '/MotorSat'], 'LowerLimit', '-1');
    set_param([modelName '/MotorSat'], 'UpperLimit', '1');
    
    % Integrator (Elevator Position)
    add_block('simulink/Continuous/Integrator', [modelName '/Position']);
    set_param([modelName '/Position'], 'Position', [530, 115, 560, 145]);
    set_param([modelName '/Position'], 'InitialCondition', '1');
    set_param([modelName '/Position'], 'LowerSaturationLimit', '1');
    set_param([modelName '/Position'], 'UpperSaturationLimit', '3');
    
    %% =========== OUTPUT PROCESSING ===========
    % Round to nearest floor
    add_block('simulink/Math Operations/Rounding Function', [modelName '/Round']);
    set_param([modelName '/Round'], 'Position', [590, 115, 620, 145]);
    
    % Floor Display
    add_block('simulink/Sinks/Display', [modelName '/FLOOR']);
    set_param([modelName '/FLOOR'], 'Position', [680, 105, 760, 155]);
    set_param([modelName '/FLOOR'], 'BackgroundColor', 'cyan');
    set_param([modelName '/FLOOR'], 'FontSize', '14');
    
    % Motor Display
    add_block('simulink/Sinks/Display', [modelName '/MOTOR']);
    set_param([modelName '/MOTOR'], 'Position', [680, 175, 760, 225]);
    set_param([modelName '/MOTOR'], 'BackgroundColor', 'orange');
    
    % Door Logic
    add_block('simulink/Math Operations/Abs', [modelName '/AbsMotor']);
    set_param([modelName '/AbsMotor'], 'Position', [530, 200, 560, 230]);
    
    add_block('simulink/Logic and Bit Operations/Compare To Constant', [modelName '/IsStopped']);
    set_param([modelName '/IsStopped'], 'Position', [590, 200, 630, 230]);
    set_param([modelName '/IsStopped'], 'relop', '<=');
    set_param([modelName '/IsStopped'], 'const', '0.05');
    
    add_block('simulink/Sinks/Display', [modelName '/DOOR']);
    set_param([modelName '/DOOR'], 'Position', [680, 245, 760, 295]);
    set_param([modelName '/DOOR'], 'BackgroundColor', 'lightBlue');
    
    % Scope
    add_block('simulink/Sinks/Scope', [modelName '/Scope']);
    set_param([modelName '/Scope'], 'Position', [680, 315, 720, 355]);
    set_param([modelName '/Scope'], 'NumInputPorts', '2');
    
    %% =========== ANNOTATIONS ===========
    ann1 = Simulink.Annotation([modelName '/LabelInput']);
    ann1.Text = sprintf('FLOOR BUTTONS\n═════════════\nSet value to 1\nto call floor');
    ann1.Position = [30, 10];
    ann1.FontSize = 10;
    
    ann2 = Simulink.Annotation([modelName '/LabelOutput']);
    ann2.Text = sprintf('STATUS\n══════');
    ann2.Position = [700, 80];
    ann2.FontSize = 10;
    
    ann3 = Simulink.Annotation([modelName '/Title']);
    ann3.Text = '3-FLOOR ELEVATOR CONTROL SYSTEM';
    ann3.Position = [350, 10];
    ann3.FontSize = 14;
    ann3.FontWeight = 'bold';
    
    %% =========== CONNECT ALL LINES ===========
    % Button to gains
    add_line(modelName, 'BTN_Floor1/1', 'G1/1');
    add_line(modelName, 'BTN_Floor2/1', 'G2/1');
    add_line(modelName, 'BTN_Floor3/1', 'G3/1');
    
    % Gains to weighted sum
    add_line(modelName, 'G1/1', 'ButtonSum/1', 'autorouting', 'on');
    add_line(modelName, 'G2/1', 'ButtonSum/2', 'autorouting', 'on');
    add_line(modelName, 'G3/1', 'ButtonSum/3', 'autorouting', 'on');
    
    % Button count
    add_line(modelName, 'BTN_Floor1/1', 'CountSum/1', 'autorouting', 'on');
    add_line(modelName, 'BTN_Floor2/1', 'CountSum/2', 'autorouting', 'on');
    add_line(modelName, 'BTN_Floor3/1', 'CountSum/3', 'autorouting', 'on');
    
    % Divide by count
    add_line(modelName, 'ButtonSum/1', 'Average/1');
    add_line(modelName, 'CountSum/1', 'MaxOne/1');
    add_line(modelName, 'OneConst/1', 'MaxOne/2');
    add_line(modelName, 'MaxOne/1', 'Average/2');
    
    % Control loop
    add_line(modelName, 'Average/1', 'Error/1');
    add_line(modelName, 'Position/1', 'Error/2', 'autorouting', 'on');
    add_line(modelName, 'Error/1', 'MotorGain/1');
    add_line(modelName, 'MotorGain/1', 'MotorSat/1');
    add_line(modelName, 'MotorSat/1', 'Position/1');
    
    % Outputs
    add_line(modelName, 'Position/1', 'Round/1');
    add_line(modelName, 'Round/1', 'FLOOR/1');
    add_line(modelName, 'MotorSat/1', 'MOTOR/1', 'autorouting', 'on');
    add_line(modelName, 'MotorSat/1', 'AbsMotor/1', 'autorouting', 'on');
    add_line(modelName, 'AbsMotor/1', 'IsStopped/1');
    add_line(modelName, 'IsStopped/1', 'DOOR/1', 'autorouting', 'on');
    
    % Scope
    add_line(modelName, 'Round/1', 'Scope/1', 'autorouting', 'on');
    add_line(modelName, 'MotorSat/1', 'Scope/2', 'autorouting', 'on');
    
    %% =========== SIMULATION SETTINGS ===========
    set_param(modelName, 'StopTime', '30');
    set_param(modelName, 'Solver', 'ode45');
    
    %% =========== SAVE ===========
    save_system(modelName);
    
    fprintf('\n');
    fprintf('╔═════════════════════════════════════════════════════════════════╗\n');
    fprintf('║          3-BUTTON ELEVATOR MODEL CREATED!                       ║\n');
    fprintf('║                  elevator_3button.slx                           ║\n');
    fprintf('╠═════════════════════════════════════════════════════════════════╣\n');
    fprintf('║                                                                 ║\n');
    fprintf('║   ┌─────────────────────────────────────────────────────────┐   ║\n');
    fprintf('║   │  HOW TO USE:                                            │   ║\n');
    fprintf('║   │                                                         │   ║\n');
    fprintf('║   │  1. Double-click BTN_Floor1 (green) → set to 1          │   ║\n');
    fprintf('║   │  2. Double-click BTN_Floor2 (yellow) → set to 1         │   ║\n');
    fprintf('║   │  3. Double-click BTN_Floor3 (red) → set to 1            │   ║\n');
    fprintf('║   │  4. Press RUN (▶) to start simulation                   │   ║\n');
    fprintf('║   │  5. Watch FLOOR, MOTOR, DOOR displays!                  │   ║\n');
    fprintf('║   └─────────────────────────────────────────────────────────┘   ║\n');
    fprintf('║                                                                 ║\n');
    fprintf('║   TRY THIS:                                                     ║\n');
    fprintf('║   • Set BTN_Floor3 = 1, Run → Elevator goes to Floor 3          ║\n');
    fprintf('║   • Set BTN_Floor1 = 1 and BTN_Floor3 = 1 → Goes to Floor 2     ║\n');
    fprintf('║     (average of 1 and 3)                                        ║\n');
    fprintf('║                                                                 ║\n');
    fprintf('╚═════════════════════════════════════════════════════════════════╝\n');
end

% Run
create_3button_elevator();

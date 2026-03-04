%% Elevator Simulink Model Generator
% This script creates a Simulink model for elevator control simulation
% Run this script to generate 'elevator_model.slx'
% Author: Elevator Control System
% Date: March 2026

function create_elevator_simulink_model()
    % Model name
    modelName = 'elevator_model';
    
    % Close model if already open
    if bdIsLoaded(modelName)
        close_system(modelName, 0);
    end
    
    % Delete existing model file
    if exist([modelName '.slx'], 'file')
        delete([modelName '.slx']);
    end
    
    fprintf('Creating Simulink model: %s\n', modelName);
    
    % Create new model
    new_system(modelName);
    open_system(modelName);
    
    %% Add Stateflow Chart for State Machine
    % Create Stateflow chart block
    chartPath = [modelName '/Elevator_StateMachine'];
    add_block('sflib/Chart', chartPath);
    set_param(chartPath, 'Position', [200, 100, 400, 300]);
    
    %% Add Input blocks
    % Floor 1 Button
    add_block('simulink/Sources/Constant', [modelName '/Floor1_Button']);
    set_param([modelName '/Floor1_Button'], 'Position', [50, 100, 80, 130]);
    set_param([modelName '/Floor1_Button'], 'Value', '0');
    
    % Floor 2 Button
    add_block('simulink/Sources/Constant', [modelName '/Floor2_Button']);
    set_param([modelName '/Floor2_Button'], 'Position', [50, 150, 80, 180]);
    set_param([modelName '/Floor2_Button'], 'Value', '0');
    
    % Floor 3 Button
    add_block('simulink/Sources/Constant', [modelName '/Floor3_Button']);
    set_param([modelName '/Floor3_Button'], 'Position', [50, 200, 80, 230]);
    set_param([modelName '/Floor3_Button'], 'Value', '0');
    
    %% Add Output blocks
    % Current Floor Display
    add_block('simulink/Sinks/Display', [modelName '/Current_Floor']);
    set_param([modelName '/Current_Floor'], 'Position', [500, 100, 580, 130]);
    
    % Motor Direction Display
    add_block('simulink/Sinks/Display', [modelName '/Motor_Direction']);
    set_param([modelName '/Motor_Direction'], 'Position', [500, 150, 580, 180]);
    
    % Door Status Display
    add_block('simulink/Sinks/Display', [modelName '/Door_Status']);
    set_param([modelName '/Door_Status'], 'Position', [500, 200, 580, 230]);
    
    %% Add Motor Driver Subsystem (H-Bridge representation)
    add_block('simulink/Ports & Subsystems/Subsystem', [modelName '/Motor_Driver']);
    set_param([modelName '/Motor_Driver'], 'Position', [350, 350, 450, 420]);
    
    %% Add Scope for visualization
    add_block('simulink/Sinks/Scope', [modelName '/Elevator_Scope']);
    set_param([modelName '/Elevator_Scope'], 'Position', [500, 260, 530, 290]);
    set_param([modelName '/Elevator_Scope'], 'NumInputPorts', '3');
    
    %% Configure simulation parameters
    set_param(modelName, 'StopTime', '100');
    set_param(modelName, 'Solver', 'FixedStepDiscrete');
    set_param(modelName, 'FixedStep', '0.1');
    
    %% Save model
    save_system(modelName);
    
    fprintf('Simulink model created successfully: %s.slx\n', modelName);
    fprintf('Open the model and customize the Stateflow chart with states:\n');
    fprintf('  - FLOOR_1\n');
    fprintf('  - MOVING_UP\n');
    fprintf('  - FLOOR_2\n');
    fprintf('  - MOVING_DOWN\n');
    fprintf('  - FLOOR_3\n');
end

% Run the function
create_elevator_simulink_model();

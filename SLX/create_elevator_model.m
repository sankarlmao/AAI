%% Create Simple Elevator Simulink Model
% This script creates a working Simulink model for 3-floor elevator
% Run this script in MATLAB to generate 'elevator_control.slx'
% Author: Elevator Control System
% Date: March 2026

function create_elevator_model()
    modelName = 'elevator_control';
    
    % Close if already open
    if bdIsLoaded(modelName)
        close_system(modelName, 0);
    end
    
    % Delete existing
    if exist([modelName '.slx'], 'file')
        delete([modelName '.slx']);
    end
    
    fprintf('Creating Simulink Model: %s\n', modelName);
    
    % Create new model
    new_system(modelName);
    open_system(modelName);
    
    %% ===== INPUT SECTION - Floor Call Buttons =====
    % Manual Switch for Floor 1 Call
    add_block('simulink/Sources/Manual Switch', [modelName '/Floor_1_Button']);
    set_param([modelName '/Floor_1_Button'], 'Position', [50, 50, 80, 80]);
    
    % Manual Switch for Floor 2 Call
    add_block('simulink/Sources/Manual Switch', [modelName '/Floor_2_Button']);
    set_param([modelName '/Floor_2_Button'], 'Position', [50, 120, 80, 150]);
    
    % Manual Switch for Floor 3 Call
    add_block('simulink/Sources/Manual Switch', [modelName '/Floor_3_Button']);
    set_param([modelName '/Floor_3_Button'], 'Position', [50, 190, 80, 220]);
    
    %% ===== CONTROLLER - MATLAB Function Block =====
    add_block('simulink/User-Defined Functions/MATLAB Function', [modelName '/Elevator_Controller']);
    set_param([modelName '/Elevator_Controller'], 'Position', [200, 80, 350, 200]);
    
    % Get the MATLAB Function block and set its code
    % Note: The function code is set via the model after creation
    
    %% ===== OUTPUT SECTION - Displays =====
    % Current Floor Display
    add_block('simulink/Sinks/Display', [modelName '/Current_Floor']);
    set_param([modelName '/Current_Floor'], 'Position', [450, 50, 530, 80]);
    
    % Motor Direction Display (1=UP, 0=STOP, -1=DOWN)
    add_block('simulink/Sinks/Display', [modelName '/Motor_Direction']);
    set_param([modelName '/Motor_Direction'], 'Position', [450, 110, 530, 140]);
    
    % Door Status Display (1=OPEN, 0=CLOSED)
    add_block('simulink/Sinks/Display', [modelName '/Door_Status']);
    set_param([modelName '/Door_Status'], 'Position', [450, 170, 530, 200]);
    
    % State Display
    add_block('simulink/Sinks/Display', [modelName '/State']);
    set_param([modelName '/State'], 'Position', [450, 230, 530, 260]);
    
    %% ===== ADD SCOPE FOR VISUALIZATION =====
    add_block('simulink/Sinks/Scope', [modelName '/Elevator_Scope']);
    set_param([modelName '/Elevator_Scope'], 'Position', [550, 120, 580, 160]);
    set_param([modelName '/Elevator_Scope'], 'NumInputPorts', '2');
    
    %% ===== MUX for combining inputs =====
    add_block('simulink/Signal Routing/Mux', [modelName '/Input_Mux']);
    set_param([modelName '/Input_Mux'], 'Position', [130, 95, 135, 185]);
    set_param([modelName '/Input_Mux'], 'Inputs', '3');
    
    %% ===== DEMUX for separating outputs =====
    add_block('simulink/Signal Routing/Demux', [modelName '/Output_Demux']);
    set_param([modelName '/Output_Demux'], 'Position', [390, 95, 395, 185]);
    set_param([modelName '/Output_Demux'], 'Outputs', '4');
    
    %% ===== CONNECT BLOCKS =====
    % Inputs to Mux
    add_line(modelName, 'Floor_1_Button/1', 'Input_Mux/1');
    add_line(modelName, 'Floor_2_Button/1', 'Input_Mux/2');
    add_line(modelName, 'Floor_3_Button/1', 'Input_Mux/3');
    
    % Mux to Controller
    add_line(modelName, 'Input_Mux/1', 'Elevator_Controller/1');
    
    % Controller to Demux
    add_line(modelName, 'Elevator_Controller/1', 'Output_Demux/1');
    
    % Demux to Displays
    add_line(modelName, 'Output_Demux/1', 'Current_Floor/1');
    add_line(modelName, 'Output_Demux/2', 'Motor_Direction/1');
    add_line(modelName, 'Output_Demux/3', 'Door_Status/1');
    add_line(modelName, 'Output_Demux/4', 'State/1');
    
    % To Scope
    add_line(modelName, 'Output_Demux/1', 'Elevator_Scope/1');
    add_line(modelName, 'Output_Demux/2', 'Elevator_Scope/2');
    
    %% ===== ADD LABELS =====
    % Add annotations
    add_block('simulink/Annotations/Area', [modelName '/Input_Area']);
    set_param([modelName '/Input_Area'], 'Position', [30, 30, 150, 240]);
    
    add_block('simulink/Annotations/Area', [modelName '/Output_Area']);
    set_param([modelName '/Output_Area'], 'Position', [430, 30, 600, 280]);
    
    %% ===== SIMULATION PARAMETERS =====
    set_param(modelName, 'StopTime', '100');
    set_param(modelName, 'Solver', 'FixedStepDiscrete');
    set_param(modelName, 'FixedStep', '0.1');
    
    %% ===== SAVE MODEL =====
    save_system(modelName);
    
    fprintf('\n========================================\n');
    fprintf('Model created: %s.slx\n', modelName);
    fprintf('========================================\n');
    fprintf('\nIMPORTANT: After opening the model:\n');
    fprintf('1. Double-click "Elevator_Controller" block\n');
    fprintf('2. Replace the code with elevator_controller_code.m content\n');
    fprintf('3. Save and run the simulation\n');
    fprintf('\nControls:\n');
    fprintf('- Double-click Floor buttons to toggle ON/OFF\n');
    fprintf('- Run simulation to see elevator respond\n');
    fprintf('========================================\n');
end

% Run the function
create_elevator_model();

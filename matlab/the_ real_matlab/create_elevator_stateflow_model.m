%% Elevator Stateflow Model Creator
% Creates a complete Stateflow-based elevator state machine model
% Author: Elevator Control System
% Date: March 2026

function create_elevator_stateflow_model()
    modelName = 'elevator_stateflow_model';
    
    % Close and delete existing model
    if bdIsLoaded(modelName)
        close_system(modelName, 0);
    end
    if exist([modelName '.slx'], 'file')
        delete([modelName '.slx']);
    end
    
    fprintf('Creating Stateflow Elevator Model...\n');
    
    % Create new model
    new_system(modelName);
    open_system(modelName);
    
    %% Create Stateflow Chart
    chartPath = [modelName '/ElevatorController'];
    add_block('sflib/Chart', chartPath);
    set_param(chartPath, 'Position', [250, 80, 450, 280]);
    
    % Get Stateflow root and chart
    rt = sfroot;
    ch = rt.find('-isa', 'Stateflow.Chart', '-and', 'Path', chartPath);
    
    %% Add Input Data
    % Floor call buttons
    floor1_call = Stateflow.Data(ch);
    floor1_call.Name = 'floor1_call';
    floor1_call.Scope = 'Input';
    floor1_call.DataType = 'boolean';
    
    floor2_call = Stateflow.Data(ch);
    floor2_call.Name = 'floor2_call';
    floor2_call.Scope = 'Input';
    floor2_call.DataType = 'boolean';
    
    floor3_call = Stateflow.Data(ch);
    floor3_call.Name = 'floor3_call';
    floor3_call.Scope = 'Input';
    floor3_call.DataType = 'boolean';
    
    %% Add Output Data
    current_floor = Stateflow.Data(ch);
    current_floor.Name = 'current_floor';
    current_floor.Scope = 'Output';
    current_floor.DataType = 'uint8';
    
    motor_up = Stateflow.Data(ch);
    motor_up.Name = 'motor_up';
    motor_up.Scope = 'Output';
    motor_up.DataType = 'boolean';
    
    motor_down = Stateflow.Data(ch);
    motor_down.Name = 'motor_down';
    motor_down.Scope = 'Output';
    motor_down.DataType = 'boolean';
    
    door_open = Stateflow.Data(ch);
    door_open.Name = 'door_open';
    door_open.Scope = 'Output';
    door_open.DataType = 'boolean';
    
    %% Add Local Data
    direction = Stateflow.Data(ch);
    direction.Name = 'direction';
    direction.Scope = 'Local';
    direction.DataType = 'int8';
    
    %% Create States
    % Floor 1 State
    s_floor1 = Stateflow.State(ch);
    s_floor1.Name = 'Floor_1';
    s_floor1.Position = [50, 50, 100, 60];
    s_floor1.LabelString = sprintf('Floor_1\nentry: current_floor=1; door_open=true; motor_up=false; motor_down=false;');
    
    % Moving Up State
    s_moving_up = Stateflow.State(ch);
    s_moving_up.Name = 'Moving_Up';
    s_moving_up.Position = [200, 50, 100, 60];
    s_moving_up.LabelString = sprintf('Moving_Up\nentry: motor_up=true; motor_down=false; door_open=false; direction=1;');
    
    % Floor 2 State
    s_floor2 = Stateflow.State(ch);
    s_floor2.Name = 'Floor_2';
    s_floor2.Position = [350, 50, 100, 60];
    s_floor2.LabelString = sprintf('Floor_2\nentry: current_floor=2; door_open=true; motor_up=false; motor_down=false;');
    
    % Moving Down State
    s_moving_down = Stateflow.State(ch);
    s_moving_down.Name = 'Moving_Down';
    s_moving_down.Position = [200, 150, 100, 60];
    s_moving_down.LabelString = sprintf('Moving_Down\nentry: motor_down=true; motor_up=false; door_open=false; direction=-1;');
    
    % Floor 3 State
    s_floor3 = Stateflow.State(ch);
    s_floor3.Name = 'Floor_3';
    s_floor3.Position = [500, 50, 100, 60];
    s_floor3.LabelString = sprintf('Floor_3\nentry: current_floor=3; door_open=true; motor_up=false; motor_down=false;');
    
    %% Create Transitions
    % Default transition to Floor_1
    dt = Stateflow.Transition(ch);
    dt.Destination = s_floor1;
    dt.DestinationOClock = 9;
    dt.SourceEndPoint = [s_floor1.Position(1)-30, s_floor1.Position(2)+30];
    
    % Floor_1 -> Moving_Up
    t1 = Stateflow.Transition(ch);
    t1.Source = s_floor1;
    t1.Destination = s_moving_up;
    t1.SourceOClock = 3;
    t1.DestinationOClock = 9;
    t1.LabelString = '[floor2_call || floor3_call]';
    
    % Moving_Up -> Floor_2
    t2 = Stateflow.Transition(ch);
    t2.Source = s_moving_up;
    t2.Destination = s_floor2;
    t2.SourceOClock = 3;
    t2.DestinationOClock = 9;
    t2.LabelString = '[floor2_call && current_floor==1]';
    
    % Moving_Up -> Floor_3
    t3 = Stateflow.Transition(ch);
    t3.Source = s_moving_up;
    t3.Destination = s_floor3;
    t3.SourceOClock = 3;
    t3.DestinationOClock = 9;
    t3.LabelString = '[floor3_call]';
    
    % Floor_2 -> Moving_Up
    t4 = Stateflow.Transition(ch);
    t4.Source = s_floor2;
    t4.Destination = s_moving_up;
    t4.SourceOClock = 9;
    t4.DestinationOClock = 3;
    t4.LabelString = '[floor3_call && direction>=0]';
    
    % Floor_2 -> Moving_Down
    t5 = Stateflow.Transition(ch);
    t5.Source = s_floor2;
    t5.Destination = s_moving_down;
    t5.SourceOClock = 6;
    t5.DestinationOClock = 12;
    t5.LabelString = '[floor1_call]';
    
    % Floor_3 -> Moving_Down
    t6 = Stateflow.Transition(ch);
    t6.Source = s_floor3;
    t6.Destination = s_moving_down;
    t6.SourceOClock = 6;
    t6.DestinationOClock = 3;
    t6.LabelString = '[floor1_call || floor2_call]';
    
    % Moving_Down -> Floor_2
    t7 = Stateflow.Transition(ch);
    t7.Source = s_moving_down;
    t7.Destination = s_floor2;
    t7.SourceOClock = 12;
    t7.DestinationOClock = 6;
    t7.LabelString = '[floor2_call && current_floor==3]';
    
    % Moving_Down -> Floor_1
    t8 = Stateflow.Transition(ch);
    t8.Source = s_moving_down;
    t8.Destination = s_floor1;
    t8.SourceOClock = 9;
    t8.DestinationOClock = 6;
    t8.LabelString = '[floor1_call]';
    
    %% Add Input Blocks
    add_block('simulink/Sources/Constant', [modelName '/Floor1_Call']);
    set_param([modelName '/Floor1_Call'], 'Position', [50, 100, 80, 130]);
    set_param([modelName '/Floor1_Call'], 'Value', '0');
    set_param([modelName '/Floor1_Call'], 'OutDataTypeStr', 'boolean');
    
    add_block('simulink/Sources/Constant', [modelName '/Floor2_Call']);
    set_param([modelName '/Floor2_Call'], 'Position', [50, 160, 80, 190]);
    set_param([modelName '/Floor2_Call'], 'Value', '0');
    set_param([modelName '/Floor2_Call'], 'OutDataTypeStr', 'boolean');
    
    add_block('simulink/Sources/Constant', [modelName '/Floor3_Call']);
    set_param([modelName '/Floor3_Call'], 'Position', [50, 220, 80, 250]);
    set_param([modelName '/Floor3_Call'], 'Value', '0');
    set_param([modelName '/Floor3_Call'], 'OutDataTypeStr', 'boolean');
    
    %% Add Output Displays
    add_block('simulink/Sinks/Display', [modelName '/CurrentFloor_Display']);
    set_param([modelName '/CurrentFloor_Display'], 'Position', [550, 80, 620, 110]);
    
    add_block('simulink/Sinks/Display', [modelName '/MotorUp_Display']);
    set_param([modelName '/MotorUp_Display'], 'Position', [550, 130, 620, 160]);
    
    add_block('simulink/Sinks/Display', [modelName '/MotorDown_Display']);
    set_param([modelName '/MotorDown_Display'], 'Position', [550, 180, 620, 210]);
    
    add_block('simulink/Sinks/Display', [modelName '/DoorOpen_Display']);
    set_param([modelName '/DoorOpen_Display'], 'Position', [550, 230, 620, 260]);
    
    %% Connect blocks
    add_line(modelName, 'Floor1_Call/1', 'ElevatorController/1');
    add_line(modelName, 'Floor2_Call/1', 'ElevatorController/2');
    add_line(modelName, 'Floor3_Call/1', 'ElevatorController/3');
    add_line(modelName, 'ElevatorController/1', 'CurrentFloor_Display/1');
    add_line(modelName, 'ElevatorController/2', 'MotorUp_Display/1');
    add_line(modelName, 'ElevatorController/3', 'MotorDown_Display/1');
    add_line(modelName, 'ElevatorController/4', 'DoorOpen_Display/1');
    
    %% Set simulation parameters
    set_param(modelName, 'StopTime', '50');
    set_param(modelName, 'Solver', 'FixedStepDiscrete');
    set_param(modelName, 'FixedStep', '0.1');
    
    %% Save model
    save_system(modelName);
    
    fprintf('Stateflow Elevator Model created: %s.slx\n', modelName);
    fprintf('\nStates created:\n');
    fprintf('  - Floor_1 (Initial state)\n');
    fprintf('  - Moving_Up\n');
    fprintf('  - Floor_2\n');
    fprintf('  - Moving_Down\n');
    fprintf('  - Floor_3\n');
end

% Run the creator
create_elevator_stateflow_model();

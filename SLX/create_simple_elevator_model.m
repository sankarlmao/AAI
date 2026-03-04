%% Create Simple Working Elevator Simulink Model with Stateflow
% Creates a complete working elevator model with interactive controls
% Run this in MATLAB to generate elevator_system.slx
% Date: March 2026

function create_simple_elevator_model()
    modelName = 'elevator_system';
    
    % Close and delete if exists
    if bdIsLoaded(modelName)
        close_system(modelName, 0);
    end
    if exist([modelName '.slx'], 'file')
        delete([modelName '.slx']);
    end
    
    fprintf('Creating Simple Elevator Model...\n');
    
    % Create model
    new_system(modelName);
    open_system(modelName);
    
    % Set model background color
    set_param(modelName, 'BackgroundColor', 'white');
    
    %% ========== INPUT CONTROLS ==========
    % Floor 1 Button (Constant that can be changed)
    add_block('simulink/Sources/Constant', [modelName '/F1_Call']);
    set_param([modelName '/F1_Call'], 'Position', [50, 80, 100, 110]);
    set_param([modelName '/F1_Call'], 'Value', '0');
    set_param([modelName '/F1_Call'], 'OutDataTypeStr', 'double');
    set_param([modelName '/F1_Call'], 'BackgroundColor', 'green');
    
    % Floor 2 Button
    add_block('simulink/Sources/Constant', [modelName '/F2_Call']);
    set_param([modelName '/F2_Call'], 'Position', [50, 150, 100, 180]);
    set_param([modelName '/F2_Call'], 'Value', '0');
    set_param([modelName '/F2_Call'], 'OutDataTypeStr', 'double');
    set_param([modelName '/F2_Call'], 'BackgroundColor', 'yellow');
    
    % Floor 3 Button
    add_block('simulink/Sources/Constant', [modelName '/F3_Call']);
    set_param([modelName '/F3_Call'], 'Position', [50, 220, 100, 250]);
    set_param([modelName '/F3_Call'], 'Value', '0');
    set_param([modelName '/F3_Call'], 'OutDataTypeStr', 'double');
    set_param([modelName '/F3_Call'], 'BackgroundColor', 'red');
    
    %% ========== STATEFLOW CHART ==========
    chartPath = [modelName '/Elevator_State_Machine'];
    add_block('sflib/Chart', chartPath);
    set_param(chartPath, 'Position', [200, 70, 400, 280]);
    
    % Get chart object
    rt = sfroot;
    ch = rt.find('-isa', 'Stateflow.Chart', '-and', 'Path', chartPath);
    
    % Set chart properties
    ch.ActionLanguage = 'MATLAB';
    
    %% Add Input Data to Chart
    f1_in = Stateflow.Data(ch);
    f1_in.Name = 'f1_call';
    f1_in.Scope = 'Input';
    f1_in.DataType = 'double';
    
    f2_in = Stateflow.Data(ch);
    f2_in.Name = 'f2_call';
    f2_in.Scope = 'Input';
    f2_in.DataType = 'double';
    
    f3_in = Stateflow.Data(ch);
    f3_in.Name = 'f3_call';
    f3_in.Scope = 'Input';
    f3_in.DataType = 'double';
    
    %% Add Output Data to Chart
    floor_out = Stateflow.Data(ch);
    floor_out.Name = 'current_floor';
    floor_out.Scope = 'Output';
    floor_out.DataType = 'double';
    
    motor_out = Stateflow.Data(ch);
    motor_out.Name = 'motor';
    motor_out.Scope = 'Output';
    motor_out.DataType = 'double';
    
    door_out = Stateflow.Data(ch);
    door_out.Name = 'door';
    door_out.Scope = 'Output';
    door_out.DataType = 'double';
    
    %% Create States in Stateflow
    % State: Floor_1 (Initial)
    s1 = Stateflow.State(ch);
    s1.Name = 'Floor_1';
    s1.Position = [50, 30, 120, 80];
    s1.LabelString = sprintf('Floor_1\nentry:\ncurrent_floor=1;\ndoor=1;\nmotor=0;');
    
    % State: Moving_Up
    s2 = Stateflow.State(ch);
    s2.Name = 'Moving_Up';
    s2.Position = [220, 30, 120, 80];
    s2.LabelString = sprintf('Moving_Up\nentry:\ndoor=0;\nmotor=1;');
    
    % State: Floor_2
    s3 = Stateflow.State(ch);
    s3.Name = 'Floor_2';
    s3.Position = [390, 30, 120, 80];
    s3.LabelString = sprintf('Floor_2\nentry:\ncurrent_floor=2;\ndoor=1;\nmotor=0;');
    
    % State: Floor_3
    s4 = Stateflow.State(ch);
    s4.Name = 'Floor_3';
    s4.Position = [390, 150, 120, 80];
    s4.LabelString = sprintf('Floor_3\nentry:\ncurrent_floor=3;\ndoor=1;\nmotor=0;');
    
    % State: Moving_Down
    s5 = Stateflow.State(ch);
    s5.Name = 'Moving_Down';
    s5.Position = [220, 150, 120, 80];
    s5.LabelString = sprintf('Moving_Down\nentry:\ndoor=0;\nmotor=-1;');
    
    %% Create Transitions
    % Default transition to Floor_1
    dt = Stateflow.Transition(ch);
    dt.Destination = s1;
    dt.DestinationOClock = 9;
    dt.SourceEndPoint = [s1.Position(1)-30, s1.Position(2)+40];
    
    % Floor_1 -> Moving_Up [f2 or f3 pressed]
    t1 = Stateflow.Transition(ch);
    t1.Source = s1;
    t1.Destination = s2;
    t1.SourceOClock = 3;
    t1.DestinationOClock = 9;
    t1.LabelString = '[f2_call>0 || f3_call>0]';
    
    % Moving_Up -> Floor_2 [f2 pressed]
    t2 = Stateflow.Transition(ch);
    t2.Source = s2;
    t2.Destination = s3;
    t2.SourceOClock = 3;
    t2.DestinationOClock = 9;
    t2.LabelString = 'after(2,sec)[f2_call>0]';
    
    % Moving_Up -> Floor_3 [f3 pressed, not f2]
    t3 = Stateflow.Transition(ch);
    t3.Source = s2;
    t3.Destination = s4;
    t3.SourceOClock = 3;
    t3.DestinationOClock = 9;
    t3.LabelString = 'after(4,sec)[f3_call>0 && f2_call==0]';
    
    % Floor_2 -> Moving_Up [f3 pressed]
    t4 = Stateflow.Transition(ch);
    t4.Source = s3;
    t4.Destination = s2;
    t4.SourceOClock = 12;
    t4.DestinationOClock = 6;
    t4.LabelString = 'after(1,sec)[f3_call>0]';
    
    % Floor_2 -> Moving_Down [f1 pressed]
    t5 = Stateflow.Transition(ch);
    t5.Source = s3;
    t5.Destination = s5;
    t5.SourceOClock = 6;
    t5.DestinationOClock = 3;
    t5.LabelString = 'after(1,sec)[f1_call>0]';
    
    % Floor_3 -> Moving_Down [f1 or f2 pressed]
    t6 = Stateflow.Transition(ch);
    t6.Source = s4;
    t6.Destination = s5;
    t6.SourceOClock = 9;
    t6.DestinationOClock = 3;
    t6.LabelString = '[f1_call>0 || f2_call>0]';
    
    % Moving_Down -> Floor_2 [f2 pressed]
    t7 = Stateflow.Transition(ch);
    t7.Source = s5;
    t7.Destination = s3;
    t7.SourceOClock = 12;
    t7.DestinationOClock = 6;
    t7.LabelString = 'after(2,sec)[f2_call>0]';
    
    % Moving_Down -> Floor_1 [f1 pressed, not f2]
    t8 = Stateflow.Transition(ch);
    t8.Source = s5;
    t8.Destination = s1;
    t8.SourceOClock = 9;
    t8.DestinationOClock = 3;
    t8.LabelString = 'after(4,sec)[f1_call>0 && f2_call==0]';
    
    %% ========== OUTPUT DISPLAYS ==========
    % Current Floor Display
    add_block('simulink/Sinks/Display', [modelName '/Floor_Display']);
    set_param([modelName '/Floor_Display'], 'Position', [500, 70, 580, 100]);
    set_param([modelName '/Floor_Display'], 'BackgroundColor', 'cyan');
    
    % Motor Direction Display
    add_block('simulink/Sinks/Display', [modelName '/Motor_Display']);
    set_param([modelName '/Motor_Display'], 'Position', [500, 130, 580, 160]);
    set_param([modelName '/Motor_Display'], 'BackgroundColor', 'orange');
    
    % Door Status Display
    add_block('simulink/Sinks/Display', [modelName '/Door_Display']);
    set_param([modelName '/Door_Display'], 'Position', [500, 190, 580, 220]);
    set_param([modelName '/Door_Display'], 'BackgroundColor', 'lightBlue');
    
    %% ========== SCOPE ==========
    add_block('simulink/Sinks/Scope', [modelName '/Monitor_Scope']);
    set_param([modelName '/Monitor_Scope'], 'Position', [500, 250, 540, 290]);
    set_param([modelName '/Monitor_Scope'], 'NumInputPorts', '3');
    
    %% ========== CONNECT LINES ==========
    % Inputs to Stateflow
    add_line(modelName, 'F1_Call/1', 'Elevator_State_Machine/1', 'autorouting', 'on');
    add_line(modelName, 'F2_Call/1', 'Elevator_State_Machine/2', 'autorouting', 'on');
    add_line(modelName, 'F3_Call/1', 'Elevator_State_Machine/3', 'autorouting', 'on');
    
    % Stateflow to Outputs
    add_line(modelName, 'Elevator_State_Machine/1', 'Floor_Display/1', 'autorouting', 'on');
    add_line(modelName, 'Elevator_State_Machine/2', 'Motor_Display/1', 'autorouting', 'on');
    add_line(modelName, 'Elevator_State_Machine/3', 'Door_Display/1', 'autorouting', 'on');
    
    % To Scope
    add_line(modelName, 'Elevator_State_Machine/1', 'Monitor_Scope/1', 'autorouting', 'on');
    add_line(modelName, 'Elevator_State_Machine/2', 'Monitor_Scope/2', 'autorouting', 'on');
    add_line(modelName, 'Elevator_State_Machine/3', 'Monitor_Scope/3', 'autorouting', 'on');
    
    %% ========== ADD TEXT LABELS ==========
    % Input Label
    add_block('simulink/Annotations/Note', [modelName '/InputLabel']);
    set_param([modelName '/InputLabel'], 'Position', [30, 50]);
    set_param([modelName '/InputLabel'], 'Text', 'FLOOR BUTTONS\n(Set to 1 to call)');
    
    % Output Label
    add_block('simulink/Annotations/Note', [modelName '/OutputLabel']);
    set_param([modelName '/OutputLabel'], 'Position', [500, 50]);
    set_param([modelName '/OutputLabel'], 'Text', 'OUTPUTS');
    
    %% ========== SIMULATION SETTINGS ==========
    set_param(modelName, 'StopTime', 'inf');  % Run indefinitely
    set_param(modelName, 'Solver', 'FixedStepDiscrete');
    set_param(modelName, 'FixedStep', '0.1');
    
    %% ========== SAVE ==========
    save_system(modelName);
    
    fprintf('\n');
    fprintf('╔════════════════════════════════════════════════════════════╗\n');
    fprintf('║     ELEVATOR MODEL CREATED: %s.slx              ║\n', modelName);
    fprintf('╠════════════════════════════════════════════════════════════╣\n');
    fprintf('║  HOW TO USE:                                               ║\n');
    fprintf('║  1. Double-click F1_Call, F2_Call, or F3_Call             ║\n');
    fprintf('║  2. Change value from 0 to 1 to call that floor           ║\n');
    fprintf('║  3. Click Run to start simulation                         ║\n');
    fprintf('║  4. Watch displays and scope for elevator movement        ║\n');
    fprintf('║                                                            ║\n');
    fprintf('║  OUTPUTS:                                                  ║\n');
    fprintf('║  - Floor_Display: Current floor (1, 2, or 3)              ║\n');
    fprintf('║  - Motor_Display: 1=UP, 0=STOP, -1=DOWN                   ║\n');
    fprintf('║  - Door_Display: 1=OPEN, 0=CLOSED                         ║\n');
    fprintf('╚════════════════════════════════════════════════════════════╝\n');
end

% Run
create_simple_elevator_model();

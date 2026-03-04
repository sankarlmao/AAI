%% Very Simple Elevator Model - Basic Simulink Blocks Only
% No Stateflow required - uses standard blocks
% Creates elevator_basic.slx
% Date: March 2026

function create_basic_elevator_model()
    modelName = 'elevator_basic';
    
    % Cleanup
    if bdIsLoaded(modelName)
        close_system(modelName, 0);
    end
    if exist([modelName '.slx'], 'file')
        delete([modelName '.slx']);
    end
    
    fprintf('Creating Basic Elevator Model...\n');
    
    new_system(modelName);
    open_system(modelName);
    
    %% ===== INPUTS: Slider Gains for easy control =====
    % Floor 1 Call
    add_block('simulink/Math Operations/Slider Gain', [modelName '/F1_Button']);
    set_param([modelName '/F1_Button'], 'Position', [50, 50, 80, 80]);
    set_param([modelName '/F1_Button'], 'low', '0');
    set_param([modelName '/F1_Button'], 'high', '1');
    set_param([modelName '/F1_Button'], 'gain', '0');
    
    % Floor 2 Call
    add_block('simulink/Math Operations/Slider Gain', [modelName '/F2_Button']);
    set_param([modelName '/F2_Button'], 'Position', [50, 120, 80, 150]);
    set_param([modelName '/F2_Button'], 'low', '0');
    set_param([modelName '/F2_Button'], 'high', '1');
    set_param([modelName '/F2_Button'], 'gain', '0');
    
    % Floor 3 Call
    add_block('simulink/Math Operations/Slider Gain', [modelName '/F3_Button']);
    set_param([modelName '/F3_Button'], 'Position', [50, 190, 80, 220]);
    set_param([modelName '/F3_Button'], 'low', '0');
    set_param([modelName '/F3_Button'], 'high', '1');
    set_param([modelName '/F3_Button'], 'gain', '0');
    
    % Input constants (value of 1)
    add_block('simulink/Sources/Constant', [modelName '/One1']);
    set_param([modelName '/One1'], 'Position', [10, 55, 30, 75]);
    set_param([modelName '/One1'], 'Value', '1');
    
    add_block('simulink/Sources/Constant', [modelName '/One2']);
    set_param([modelName '/One2'], 'Position', [10, 125, 30, 145]);
    set_param([modelName '/One2'], 'Value', '1');
    
    add_block('simulink/Sources/Constant', [modelName '/One3']);
    set_param([modelName '/One3'], 'Position', [10, 195, 30, 215]);
    set_param([modelName '/One3'], 'Value', '1');
    
    %% ===== CONTROLLER SUBSYSTEM =====
    add_block('simulink/Ports & Subsystems/Subsystem', [modelName '/Controller']);
    set_param([modelName '/Controller'], 'Position', [180, 90, 320, 200]);
    
    % Delete default contents and rebuild
    delete_line([modelName '/Controller'], 'In1/1', 'Out1/1');
    delete_block([modelName '/Controller/In1']);
    delete_block([modelName '/Controller/Out1']);
    
    % Add inputs to subsystem
    add_block('simulink/Ports & Subsystems/In1', [modelName '/Controller/F1_In']);
    set_param([modelName '/Controller/F1_In'], 'Position', [30, 40, 60, 60]);
    set_param([modelName '/Controller/F1_In'], 'Port', '1');
    
    add_block('simulink/Ports & Subsystems/In1', [modelName '/Controller/F2_In']);
    set_param([modelName '/Controller/F2_In'], 'Position', [30, 90, 60, 110]);
    set_param([modelName '/Controller/F2_In'], 'Port', '2');
    
    add_block('simulink/Ports & Subsystems/In1', [modelName '/Controller/F3_In']);
    set_param([modelName '/Controller/F3_In'], 'Position', [30, 140, 60, 160]);
    set_param([modelName '/Controller/F3_In'], 'Port', '3');
    
    % Add outputs from subsystem
    add_block('simulink/Ports & Subsystems/Out1', [modelName '/Controller/Floor_Out']);
    set_param([modelName '/Controller/Floor_Out'], 'Position', [400, 40, 430, 60]);
    set_param([modelName '/Controller/Floor_Out'], 'Port', '1');
    
    add_block('simulink/Ports & Subsystems/Out1', [modelName '/Controller/Motor_Out']);
    set_param([modelName '/Controller/Motor_Out'], 'Position', [400, 90, 430, 110]);
    set_param([modelName '/Controller/Motor_Out'], 'Port', '2');
    
    add_block('simulink/Ports & Subsystems/Out1', [modelName '/Controller/Door_Out']);
    set_param([modelName '/Controller/Door_Out'], 'Position', [400, 140, 430, 160]);
    set_param([modelName '/Controller/Door_Out'], 'Port', '3');
    
    % Weighted sum to calculate target floor
    add_block('simulink/Math Operations/Gain', [modelName '/Controller/G1']);
    set_param([modelName '/Controller/G1'], 'Position', [100, 35, 130, 65]);
    set_param([modelName '/Controller/G1'], 'Gain', '1');
    
    add_block('simulink/Math Operations/Gain', [modelName '/Controller/G2']);
    set_param([modelName '/Controller/G2'], 'Position', [100, 85, 130, 115]);
    set_param([modelName '/Controller/G2'], 'Gain', '2');
    
    add_block('simulink/Math Operations/Gain', [modelName '/Controller/G3']);
    set_param([modelName '/Controller/G3'], 'Position', [100, 135, 130, 165]);
    set_param([modelName '/Controller/G3'], 'Gain', '3');
    
    % Sum for target
    add_block('simulink/Math Operations/Sum', [modelName '/Controller/TargetSum']);
    set_param([modelName '/Controller/TargetSum'], 'Position', [170, 80, 200, 120]);
    set_param([modelName '/Controller/TargetSum'], 'Inputs', '+++');
    
    % Integrator for position (simulates elevator movement)
    add_block('simulink/Continuous/Integrator', [modelName '/Controller/Position']);
    set_param([modelName '/Controller/Position'], 'Position', [320, 35, 350, 65]);
    set_param([modelName '/Controller/Position'], 'InitialCondition', '1');
    set_param([modelName '/Controller/Position'], 'LowerSaturationLimit', '1');
    set_param([modelName '/Controller/Position'], 'UpperSaturationLimit', '3');
    
    % Difference to get motor command
    add_block('simulink/Math Operations/Sum', [modelName '/Controller/Error']);
    set_param([modelName '/Controller/Error'], 'Position', [230, 35, 260, 65]);
    set_param([modelName '/Controller/Error'], 'Inputs', '+-');
    
    % Saturation for motor speed
    add_block('simulink/Discontinuities/Saturation', [modelName '/Controller/MotorSat']);
    set_param([modelName '/Controller/MotorSat'], 'Position', [280, 35, 310, 65]);
    set_param([modelName '/Controller/MotorSat'], 'LowerLimit', '-1');
    set_param([modelName '/Controller/MotorSat'], 'UpperLimit', '1');
    
    % Door logic: open when motor is stopped
    add_block('simulink/Math Operations/Abs', [modelName '/Controller/AbsMotor']);
    set_param([modelName '/Controller/AbsMotor'], 'Position', [280, 130, 310, 160]);
    
    add_block('simulink/Logic and Bit Operations/Compare To Constant', [modelName '/Controller/MotorZero']);
    set_param([modelName '/Controller/MotorZero'], 'Position', [330, 130, 360, 160]);
    set_param([modelName '/Controller/MotorZero'], 'relop', '<=');
    set_param([modelName '/Controller/MotorZero'], 'const', '0.1');
    
    % Connect inside subsystem
    add_line([modelName '/Controller'], 'F1_In/1', 'G1/1');
    add_line([modelName '/Controller'], 'F2_In/1', 'G2/1');
    add_line([modelName '/Controller'], 'F3_In/1', 'G3/1');
    add_line([modelName '/Controller'], 'G1/1', 'TargetSum/1');
    add_line([modelName '/Controller'], 'G2/1', 'TargetSum/2');
    add_line([modelName '/Controller'], 'G3/1', 'TargetSum/3');
    add_line([modelName '/Controller'], 'TargetSum/1', 'Error/1');
    add_line([modelName '/Controller'], 'Position/1', 'Error/2', 'autorouting', 'on');
    add_line([modelName '/Controller'], 'Error/1', 'MotorSat/1');
    add_line([modelName '/Controller'], 'MotorSat/1', 'Position/1');
    add_line([modelName '/Controller'], 'Position/1', 'Floor_Out/1');
    add_line([modelName '/Controller'], 'MotorSat/1', 'Motor_Out/1', 'autorouting', 'on');
    add_line([modelName '/Controller'], 'MotorSat/1', 'AbsMotor/1', 'autorouting', 'on');
    add_line([modelName '/Controller'], 'AbsMotor/1', 'MotorZero/1');
    add_line([modelName '/Controller'], 'MotorZero/1', 'Door_Out/1');
    
    %% ===== OUTPUTS =====
    add_block('simulink/Sinks/Display', [modelName '/Floor']);
    set_param([modelName '/Floor'], 'Position', [420, 60, 500, 90]);
    
    add_block('simulink/Sinks/Display', [modelName '/Motor']);
    set_param([modelName '/Motor'], 'Position', [420, 120, 500, 150]);
    
    add_block('simulink/Sinks/Display', [modelName '/Door']);
    set_param([modelName '/Door'], 'Position', [420, 180, 500, 210]);
    
    % Scope
    add_block('simulink/Sinks/Scope', [modelName '/Scope']);
    set_param([modelName '/Scope'], 'Position', [420, 240, 460, 280]);
    set_param([modelName '/Scope'], 'NumInputPorts', '2');
    
    % Rounding for floor display
    add_block('simulink/Math Operations/Rounding Function', [modelName '/Round']);
    set_param([modelName '/Round'], 'Position', [370, 62, 400, 88]);
    set_param([modelName '/Round'], 'Operator', 'round');
    
    %% ===== CONNECT MAIN MODEL =====
    add_line(modelName, 'One1/1', 'F1_Button/1');
    add_line(modelName, 'One2/1', 'F2_Button/1');
    add_line(modelName, 'One3/1', 'F3_Button/1');
    add_line(modelName, 'F1_Button/1', 'Controller/1', 'autorouting', 'on');
    add_line(modelName, 'F2_Button/1', 'Controller/2', 'autorouting', 'on');
    add_line(modelName, 'F3_Button/1', 'Controller/3', 'autorouting', 'on');
    add_line(modelName, 'Controller/1', 'Round/1');
    add_line(modelName, 'Round/1', 'Floor/1');
    add_line(modelName, 'Controller/2', 'Motor/1', 'autorouting', 'on');
    add_line(modelName, 'Controller/3', 'Door/1', 'autorouting', 'on');
    add_line(modelName, 'Round/1', 'Scope/1', 'autorouting', 'on');
    add_line(modelName, 'Controller/2', 'Scope/2', 'autorouting', 'on');
    
    %% ===== SETTINGS =====
    set_param(modelName, 'StopTime', '30');
    set_param(modelName, 'Solver', 'ode45');
    
    %% ===== SAVE =====
    save_system(modelName);
    
    fprintf('\n');
    fprintf('╔════════════════════════════════════════════════════════╗\n');
    fprintf('║    BASIC ELEVATOR MODEL: %s.slx             ║\n', modelName);
    fprintf('╠════════════════════════════════════════════════════════╣\n');
    fprintf('║  HOW TO USE:                                          ║\n');
    fprintf('║  1. Double-click F1/F2/F3_Button slider               ║\n');
    fprintf('║  2. Move slider to 1 to call that floor               ║\n');
    fprintf('║  3. Run simulation                                    ║\n');
    fprintf('║                                                        ║\n');
    fprintf('║  OUTPUTS:                                              ║\n');
    fprintf('║  - Floor: 1, 2, or 3                                  ║\n');
    fprintf('║  - Motor: Positive=UP, Negative=DOWN, 0=STOP          ║\n');
    fprintf('║  - Door: 1=OPEN, 0=CLOSED                             ║\n');
    fprintf('╚════════════════════════════════════════════════════════╝\n');
end

% Run
create_basic_elevator_model();

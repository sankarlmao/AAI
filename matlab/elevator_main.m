%% ELEVATOR MAIN SIMULATION SCRIPT
% File: elevator_main.m
% Purpose: Main simulation controller for 3-floor elevator system
% Author: Digital Design Project
% Date: March 2026
%
% This script initializes the elevator system, processes user inputs,
% and simulates elevator movement with state machine control and
% priority scheduling.

clear all;
close all;
clc;

fprintf('========================================\n');
fprintf('  ELEVATOR CONTROL SYSTEM SIMULATION\n');
fprintf('========================================\n\n');

%% SIMULATION PARAMETERS
sim_time = 30;              % Total simulation time (seconds)
dt = 0.1;                   % Time step (seconds)
floor_travel_time = 3;      % Time to move between floors (seconds)
door_open_time = 2;         % Time doors stay open at floor (seconds)

%% INITIALIZE SYSTEM STATE
current_floor = 1;          % Start at floor 1 (ground floor)
current_state = 1;          % State: 1=F1, 2=Moving_Up, 3=F2, 4=Moving_Down, 5=F3
direction = 0;              % Direction: 0=Idle, 1=Up, -1=Down
target_floor = 0;           % Current target floor (0=none)
travel_timer = 0;           % Timer for movement between floors
door_timer = 0;             % Timer for door operations

% Request queue (persistent floor calls)
call_f1 = 0;
call_f2 = 0;
call_f3 = 0;

% Output signals
motor_up = 0;
motor_down = 0;

%% DATA LOGGING ARRAYS
time_log = [];
floor_log = [];
state_log = [];
motor_up_log = [];
motor_down_log = [];
calls_log = [];

%% SIMULATE USER BUTTON PRESSES
% Create a schedule of button presses [time, floor]
button_schedule = [
    2.0, 3;     % At t=2s, call floor 3
    5.0, 2;     % At t=5s, call floor 2
    10.0, 1;    % At t=10s, call floor 1
    15.0, 3;    % At t=15s, call floor 3
    18.0, 2;    % At t=18s, call floor 2
    25.0, 1;    % At t=25s, call floor 1
];

button_index = 1;

%% MAIN SIMULATION LOOP
fprintf('Starting simulation...\n');
fprintf('Time  | State         | Floor | Calls [1 2 3] | Motor [U D]\n');
fprintf('------|---------------|-------|---------------|-------------\n');

for t = 0:dt:sim_time
    
    %% PROCESS BUTTON PRESSES
    % Check if any scheduled buttons should be pressed at this time
    while button_index <= size(button_schedule, 1) && ...
          button_schedule(button_index, 1) <= t
        
        floor_pressed = button_schedule(button_index, 2);
        
        switch floor_pressed
            case 1
                call_f1 = 1;
                fprintf('>>> Button F1 pressed at t=%.1fs\n', t);
            case 2
                call_f2 = 1;
                fprintf('>>> Button F2 pressed at t=%.1fs\n', t);
            case 3
                call_f3 = 1;
                fprintf('>>> Button F3 pressed at t=%.1fs\n', t);
        end
        
        button_index = button_index + 1;
    end
    
    %% UPDATE TIMERS
    if travel_timer > 0
        travel_timer = travel_timer - dt;
    end
    
    if door_timer > 0
        door_timer = door_timer - dt;
    end
    
    %% CLEAR CALL WHEN FLOOR REACHED
    % If we're at a floor and doors are operating, clear that floor's call
    if door_timer > 0
        if current_floor == 1
            call_f1 = 0;
        elseif current_floor == 2
            call_f2 = 0;
        elseif current_floor == 3
            call_f3 = 0;
        end
    end
    
    %% CALL PRIORITY LOGIC
    % Determine next target floor based on current state and calls
    target_floor = priority_logic(current_floor, direction, ...
                                   [call_f1, call_f2, call_f3]);
    
    %% CALL STATE MACHINE CONTROLLER
    % Get next state and motor commands
    [next_state, motor_up, motor_down, new_direction] = ...
        elevator_controller(current_state, target_floor, current_floor, ...
                           travel_timer, door_timer);
    
    %% UPDATE STATE TRANSITIONS
    % Handle state changes
    if next_state ~= current_state
        
        % State transition occurred
        old_state = current_state;
        current_state = next_state;
        
        % State-specific actions
        switch current_state
            case 1  % Arrived at Floor 1
                current_floor = 1;
                door_timer = door_open_time;
                travel_timer = 0;
                
            case 2  % Started moving up
                travel_timer = floor_travel_time;
                door_timer = 0;
                
            case 3  % Arrived at Floor 2
                current_floor = 2;
                door_timer = door_open_time;
                travel_timer = 0;
                
            case 4  % Started moving down
                travel_timer = floor_travel_time;
                door_timer = 0;
                
            case 5  % Arrived at Floor 3
                current_floor = 3;
                door_timer = door_open_time;
                travel_timer = 0;
        end
    end
    
    % Update direction
    direction = new_direction;
    
    %% SIMULATE MOTOR RESPONSE
    % Call motor driver model (for simulation purposes)
    [motor_state, motor_speed] = motor_driver_model(motor_up, motor_down);
    
    %% LOG DATA
    time_log = [time_log; t];
    floor_log = [floor_log; current_floor];
    state_log = [state_log; current_state];
    motor_up_log = [motor_up_log; motor_up];
    motor_down_log = [motor_down_log; motor_down];
    calls_log = [calls_log; call_f1, call_f2, call_f3];
    
    %% DISPLAY STATUS (every 0.5 seconds)
    if mod(t, 0.5) < dt
        state_names = {'Floor_1', 'Moving_Up', 'Floor_2', 'Moving_Down', 'Floor_3'};
        fprintf('%5.1f | %-13s | %5d | [%d %d %d]       | [%d %d]\n', ...
                t, state_names{current_state}, current_floor, ...
                call_f1, call_f2, call_f3, motor_up, motor_down);
    end
    
end

fprintf('\nSimulation complete.\n\n');

%% GENERATE PLOTS
fprintf('Generating plots...\n');

figure('Name', 'Elevator Simulation Results', 'Position', [100, 100, 1200, 800]);

% Plot 1: Floor Position
subplot(4, 1, 1);
plot(time_log, floor_log, 'b-', 'LineWidth', 2);
ylim([0.5, 3.5]);
yticks([1, 2, 3]);
yticklabels({'Floor 1', 'Floor 2', 'Floor 3'});
xlabel('Time (s)');
ylabel('Elevator Floor');
title('Elevator Position vs Time');
grid on;

% Plot 2: State Machine
subplot(4, 1, 2);
plot(time_log, state_log, 'r-', 'LineWidth', 2);
ylim([0.5, 5.5]);
yticks([1, 2, 3, 4, 5]);
yticklabels({'Floor_1', 'Moving_Up', 'Floor_2', 'Moving_Down', 'Floor_3'});
xlabel('Time (s)');
ylabel('System State');
title('State Machine State vs Time');
grid on;

% Plot 3: Motor Control Signals
subplot(4, 1, 3);
hold on;
plot(time_log, motor_up_log, 'g-', 'LineWidth', 2);
plot(time_log, motor_down_log, 'r-', 'LineWidth', 2);
hold off;
ylim([-0.2, 1.2]);
xlabel('Time (s)');
ylabel('Motor Control');
title('Motor Driver Signals');
legend('Motor Up', 'Motor Down', 'Location', 'best');
grid on;

% Plot 4: Floor Call Buttons
subplot(4, 1, 4);
hold on;
plot(time_log, calls_log(:,1), 'b-', 'LineWidth', 1.5);
plot(time_log, calls_log(:,2), 'g-', 'LineWidth', 1.5);
plot(time_log, calls_log(:,3), 'r-', 'LineWidth', 1.5);
hold off;
ylim([-0.2, 1.2]);
xlabel('Time (s)');
ylabel('Call Status');
title('Floor Call Buttons (1 = Active)');
legend('Call Floor 1', 'Call Floor 2', 'Call Floor 3', 'Location', 'best');
grid on;

%% SAVE RESULTS
fprintf('Saving results to file...\n');
save('elevator_simulation_results.mat', 'time_log', 'floor_log', 'state_log', ...
     'motor_up_log', 'motor_down_log', 'calls_log', 'sim_time', 'dt');

fprintf('\n========================================\n');
fprintf('  SIMULATION COMPLETED SUCCESSFULLY\n');
fprintf('========================================\n');
fprintf('Results saved to: elevator_simulation_results.mat\n');
fprintf('Plots generated and displayed.\n\n');

%% PERFORMANCE STATISTICS
fprintf('PERFORMANCE STATISTICS:\n');
fprintf('Total simulation time: %.1f seconds\n', sim_time);
fprintf('Total button presses: %d\n', size(button_schedule, 1));

% Count state transitions
state_changes = sum(diff(state_log) ~= 0);
fprintf('Total state transitions: %d\n', state_changes);

% Calculate time in each state
states_unique = [1, 2, 3, 4, 5];
state_names = {'Floor_1', 'Moving_Up', 'Floor_2', 'Moving_Down', 'Floor_3'};
fprintf('\nTime spent in each state:\n');
for i = 1:length(states_unique)
    time_in_state = sum(state_log == states_unique(i)) * dt;
    percentage = (time_in_state / sim_time) * 100;
    fprintf('  %s: %.1f s (%.1f%%)\n', state_names{i}, time_in_state, percentage);
end

fprintf('\n');

%% Elevator System - Simple Simulation Script
% Complete simulation demonstrating state machine and priority logic
% Author: Elevator Control System
% Date: March 2026

clear all; clc;

fprintf('╔══════════════════════════════════════════════════════════════╗\n');
fprintf('║          ELEVATOR CONTROL SYSTEM SIMULATION                  ║\n');
fprintf('║                    3-Floor System                            ║\n');
fprintf('╚══════════════════════════════════════════════════════════════╝\n\n');

%% State Definitions
FLOOR_1 = 1;
MOVING_UP = 2;
FLOOR_2 = 3;
MOVING_DOWN = 4;
FLOOR_3 = 5;

state_names = {'FLOOR_1', 'MOVING_UP', 'FLOOR_2', 'MOVING_DOWN', 'FLOOR_3'};

%% Initialize Variables
current_state = FLOOR_1;
current_floor = 1;
direction = 0;  % 0=IDLE, 1=UP, -1=DOWN
call_queue = [];
simulation_time = 0;
time_step = 1;  % seconds

% Log arrays for plotting
time_log = [];
floor_log = [];
state_log = [];
direction_log = [];

%% Priority Logic Function
% Determines which floor to visit based on current direction
function target = get_priority_target(calls, floor, dir)
    if isempty(calls)
        target = 0;
        return;
    end
    
    calls_above = calls(calls > floor);
    calls_below = calls(calls < floor);
    
    if dir == 1 && ~isempty(calls_above)
        % Moving UP - continue to highest call above
        target = min(calls_above);  % Closest call above
    elseif dir == -1 && ~isempty(calls_below)
        % Moving DOWN - continue to lowest call below
        target = max(calls_below);  % Closest call below
    elseif ~isempty(calls_above)
        % Go UP
        target = min(calls_above);
    elseif ~isempty(calls_below)
        % Go DOWN
        target = max(calls_below);
    else
        target = 0;
    end
end

%% Simulation Function
function [state, floor, dir, queue, logs] = simulate_elevator(calls, max_steps)
    % Initialize
    state = 1;  % FLOOR_1
    floor = 1;
    dir = 0;
    queue = calls;
    
    logs.time = [];
    logs.floor = [];
    logs.state = [];
    
    state_names = {'FLOOR_1', 'MOVING_UP', 'FLOOR_2', 'MOVING_DOWN', 'FLOOR_3'};
    
    fprintf('\n--- Simulation Start ---\n');
    fprintf('Initial calls: [%s]\n\n', num2str(queue));
    
    for step = 1:max_steps
        % Log current state
        logs.time(end+1) = step;
        logs.floor(end+1) = floor;
        logs.state(end+1) = state;
        
        old_state = state;
        
        switch state
            case 1  % FLOOR_1
                floor = 1;
                queue = queue(queue ~= 1);  % Remove F1 from queue
                
                target = get_priority_target(queue, floor, dir);
                if target > 1
                    dir = 1;
                    state = 2;  % MOVING_UP
                end
                
            case 2  % MOVING_UP
                if floor < 3
                    floor = floor + 0.5;  % Simulate movement
                end
                
                % Check if arrived at a called floor
                if floor == 2 && ismember(2, queue)
                    state = 3;  % FLOOR_2
                elseif floor >= 3
                    floor = 3;
                    state = 5;  % FLOOR_3
                end
                
            case 3  % FLOOR_2
                floor = 2;
                queue = queue(queue ~= 2);  % Remove F2 from queue
                
                target = get_priority_target(queue, floor, dir);
                if target == 3
                    state = 2;  % MOVING_UP
                elseif target == 1
                    dir = -1;
                    state = 4;  % MOVING_DOWN
                end
                
            case 4  % MOVING_DOWN
                if floor > 1
                    floor = floor - 0.5;  % Simulate movement
                end
                
                % Check if arrived at a called floor
                if floor == 2 && ismember(2, queue)
                    state = 3;  % FLOOR_2
                elseif floor <= 1
                    floor = 1;
                    state = 1;  % FLOOR_1
                end
                
            case 5  % FLOOR_3
                floor = 3;
                queue = queue(queue ~= 3);  % Remove F3 from queue
                
                target = get_priority_target(queue, floor, dir);
                if target < 3
                    dir = -1;
                    state = 4;  % MOVING_DOWN
                end
        end
        
        % Print state transition
        if state ~= old_state
            fprintf('Step %2d: %s → %s (Floor: %.1f)\n', ...
                step, state_names{old_state}, state_names{state}, floor);
        end
        
        % Check if done
        if isempty(queue) && (state == 1 || state == 3 || state == 5)
            fprintf('\nAll calls serviced at Step %d\n', step);
            break;
        end
    end
    
    fprintf('--- Simulation End ---\n\n');
end

%% Test Case 1: Simple call F1 to F3
fprintf('═══════════════════════════════════════════════════════════════\n');
fprintf('TEST CASE 1: Call to Floor 3 (starting at Floor 1)\n');
fprintf('═══════════════════════════════════════════════════════════════\n');
[~, ~, ~, ~, logs1] = simulate_elevator([3], 20);

%% Test Case 2: Priority Test - F1 and F3 pressed
fprintf('═══════════════════════════════════════════════════════════════\n');
fprintf('TEST CASE 2: Floor 1 and Floor 3 called simultaneously\n');
fprintf('Priority: Continue in current direction\n');
fprintf('═══════════════════════════════════════════════════════════════\n');
[~, ~, ~, ~, logs2] = simulate_elevator([1, 3], 25);

%% Test Case 3: All floors called
fprintf('═══════════════════════════════════════════════════════════════\n');
fprintf('TEST CASE 3: All floors called (F1, F2, F3)\n');
fprintf('═══════════════════════════════════════════════════════════════\n');
[~, ~, ~, ~, logs3] = simulate_elevator([1, 2, 3], 30);

%% Test Case 4: Random calls
fprintf('═══════════════════════════════════════════════════════════════\n');
fprintf('TEST CASE 4: Calls in order [3, 1, 2]\n');
fprintf('═══════════════════════════════════════════════════════════════\n');
[~, ~, ~, ~, logs4] = simulate_elevator([3, 1, 2], 35);

%% Plot Results
figure('Name', 'Elevator Simulation Results', 'Position', [100 100 1000 600]);

subplot(2,2,1);
stairs(logs1.time, logs1.floor, 'b-', 'LineWidth', 2);
xlabel('Time Step'); ylabel('Floor');
title('Test 1: Call to F3');
ylim([0.5 3.5]); yticks([1 2 3]);
grid on;

subplot(2,2,2);
stairs(logs2.time, logs2.floor, 'r-', 'LineWidth', 2);
xlabel('Time Step'); ylabel('Floor');
title('Test 2: F1 & F3 Priority');
ylim([0.5 3.5]); yticks([1 2 3]);
grid on;

subplot(2,2,3);
stairs(logs3.time, logs3.floor, 'g-', 'LineWidth', 2);
xlabel('Time Step'); ylabel('Floor');
title('Test 3: All Floors');
ylim([0.5 3.5]); yticks([1 2 3]);
grid on;

subplot(2,2,4);
stairs(logs4.time, logs4.floor, 'm-', 'LineWidth', 2);
xlabel('Time Step'); ylabel('Floor');
title('Test 4: Calls [3,1,2]');
ylim([0.5 3.5]); yticks([1 2 3]);
grid on;

sgtitle('Elevator Position Over Time');

fprintf('\n╔══════════════════════════════════════════════════════════════╗\n');
fprintf('║               SIMULATION COMPLETE                            ║\n');
fprintf('╚══════════════════════════════════════════════════════════════╝\n');

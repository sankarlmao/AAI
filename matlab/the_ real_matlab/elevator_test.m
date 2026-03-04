%% Elevator Simulation Test Script
% Simple test script to run the elevator state machine
% Author: Elevator Control System
% Date: March 2026

clear all;
clc;

fprintf('============================================\n');
fprintf('    ELEVATOR CONTROL SYSTEM SIMULATION     \n');
fprintf('    3-Floor Elevator State Machine         \n');
fprintf('============================================\n\n');

%% Create elevator instance
elevator = elevator_state_machine();

%% Test Case 1: Simple call from Floor 1 to Floor 3
fprintf('\n*** TEST CASE 1: Floor 1 to Floor 3 ***\n');
elevator.add_call(3);
elevator.run_simulation([], 10);

%% Reset elevator
elevator = elevator_state_machine();

%% Test Case 2: Multiple calls - Floor 1 and Floor 3 pressed
fprintf('\n*** TEST CASE 2: Floor 1 and Floor 3 calls ***\n');
elevator.run_simulation([1, 3], 10);

%% Reset elevator
elevator = elevator_state_machine();

%% Test Case 3: All floors pressed
fprintf('\n*** TEST CASE 3: All floors called ***\n');
elevator.run_simulation([3, 1, 2], 15);

%% Test Case 4: Priority Logic Test
fprintf('\n*** TEST CASE 4: Priority Logic Test ***\n');
fprintf('Testing: Elevator at Floor 2, calls from Floor 1 and Floor 3\n');
fprintf('Direction-based priority should determine which floor to visit first\n\n');

elevator2 = elevator_state_machine();
% Move to floor 2 first
elevator2.add_call(2);
for i = 1:3
    elevator2.process_state();
end
elevator2.display_status();

% Now add calls from floor 1 and 3
fprintf('Adding calls from Floor 1 and Floor 3...\n');
elevator2.add_call(1);
elevator2.add_call(3);
elevator2.display_status();

% Process and see priority decision
for i = 1:10
    elevator2.process_state();
    elevator2.display_status();
    if isempty(elevator2.call_queue)
        break;
    end
end

fprintf('\n============================================\n');
fprintf('    SIMULATION COMPLETE                     \n');
fprintf('============================================\n');

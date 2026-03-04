function [next_state, motor_up, motor_down, direction] = ...
    elevator_controller(current_state, target_floor, current_floor, ...
                       travel_timer, door_timer)
%% ELEVATOR STATE MACHINE CONTROLLER
% File: elevator_controller.m
% Purpose: Implements finite state machine for elevator control
%
% INPUTS:
%   current_state  - Current FSM state (1-5)
%                    1=Floor_1, 2=Moving_Up, 3=Floor_2, 
%                    4=Moving_Down, 5=Floor_3
%   target_floor   - Target floor from priority logic (0=none, 1-3)
%   current_floor  - Physical floor position (1-3)
%   travel_timer   - Countdown timer for floor travel (seconds)
%   door_timer     - Countdown timer for door operations (seconds)
%
% OUTPUTS:
%   next_state     - Next FSM state (1-5)
%   motor_up       - Motor up control signal (0 or 1)
%   motor_down     - Motor down control signal (0 or 1)
%   direction      - Direction indicator (0=Idle, 1=Up, -1=Down)
%
% STATE ENCODING:
%   FLOOR_1      = 1  (at ground floor)
%   MOVING_UP    = 2  (ascending)
%   FLOOR_2      = 3  (at first floor)
%   MOVING_DOWN  = 4  (descending)
%   FLOOR_3      = 5  (at top floor)

% Initialize outputs with default values
next_state = current_state;  % By default, stay in current state
motor_up = 0;
motor_down = 0;
direction = 0;  % Idle

%% STATE MACHINE LOGIC
switch current_state
    
    case 1  % FLOOR_1 (Ground Floor)
        % Motor outputs
        motor_up = 0;
        motor_down = 0;
        direction = 0;  % Idle
        
        % Check if doors are still operating
        if door_timer > 0
            % Stay at floor while doors are open
            next_state = 1;
        else
            % Check for calls to upper floors
            if target_floor == 2
                % Need to go to floor 2
                next_state = 2;  % Transition to MOVING_UP
                direction = 1;   % Set direction UP
            elseif target_floor == 3
                % Need to go to floor 3
                next_state = 2;  % Transition to MOVING_UP
                direction = 1;   % Set direction UP
            else
                % No calls, stay idle at floor 1
                next_state = 1;
                direction = 0;
            end
        end
    
    case 2  % MOVING_UP (Ascending)
        % Motor outputs - moving upward
        motor_up = 1;
        motor_down = 0;
        direction = 1;  % UP
        
        % Check if travel timer expired (reached destination)
        if travel_timer <= 0
            % Determine which floor we reached
            if target_floor == 2 || (target_floor == 3 && current_floor == 1)
                % Arrived at floor 2 (either final destination or passing through)
                next_state = 3;  % Transition to FLOOR_2
            elseif target_floor == 3 && current_floor == 2
                % Continue moving up to floor 3
                next_state = 5;  % Transition to FLOOR_3
            else
                % Default: stop at next floor
                if current_floor < 3
                    next_state = 3;  % Stop at floor 2
                else
                    next_state = 5;  % Stop at floor 3
                end
            end
        else
            % Still traveling
            next_state = 2;
        end
    
    case 3  % FLOOR_2 (First Floor)
        % Motor outputs
        motor_up = 0;
        motor_down = 0;
        direction = 0;  % Idle
        
        % Check if doors are still operating
        if door_timer > 0
            % Stay at floor while doors are open
            next_state = 3;
        else
            % Check target floor
            if target_floor == 3
                % Need to go up to floor 3
                next_state = 2;  % Transition to MOVING_UP
                direction = 1;   % Set direction UP
            elseif target_floor == 1
                % Need to go down to floor 1
                next_state = 4;  % Transition to MOVING_DOWN
                direction = -1;  % Set direction DOWN
            else
                % No calls or already at target, stay idle
                next_state = 3;
                direction = 0;
            end
        end
    
    case 4  % MOVING_DOWN (Descending)
        % Motor outputs - moving downward
        motor_up = 0;
        motor_down = 1;
        direction = -1;  % DOWN
        
        % Check if travel timer expired (reached destination)
        if travel_timer <= 0
            % Determine which floor we reached
            if target_floor == 2 || (target_floor == 1 && current_floor == 3)
                % Arrived at floor 2 (either final destination or passing through)
                next_state = 3;  % Transition to FLOOR_2
            elseif target_floor == 1 && current_floor == 2
                % Continue moving down to floor 1
                next_state = 1;  % Transition to FLOOR_1
            else
                % Default: stop at next floor
                if current_floor > 1
                    next_state = 3;  % Stop at floor 2
                else
                    next_state = 1;  % Stop at floor 1
                end
            end
        else
            % Still traveling
            next_state = 4;
        end
    
    case 5  % FLOOR_3 (Top Floor)
        % Motor outputs
        motor_up = 0;
        motor_down = 0;
        direction = 0;  % Idle
        
        % Check if doors are still operating
        if door_timer > 0
            % Stay at floor while doors are open
            next_state = 5;
        else
            % Can only move down from floor 3
            if target_floor == 2
                % Need to go down to floor 2
                next_state = 4;  % Transition to MOVING_DOWN
                direction = -1;  % Set direction DOWN
            elseif target_floor == 1
                % Need to go down to floor 1
                next_state = 4;  % Transition to MOVING_DOWN
                direction = -1;  % Set direction DOWN
            else
                % No calls, stay idle at floor 3
                next_state = 5;
                direction = 0;
            end
        end
    
    otherwise
        % Invalid state - default to Floor 1 (safety)
        next_state = 1;
        motor_up = 0;
        motor_down = 0;
        direction = 0;
        warning('Invalid state detected: %d. Resetting to Floor_1.', current_state);
end

%% SAFETY CHECKS
% Ensure motor signals are mutually exclusive (prevent shoot-through)
if motor_up == 1 && motor_down == 1
    % Both motors should never be ON - this is a critical error
    warning('SAFETY VIOLATION: Both motor_up and motor_down are HIGH!');
    motor_up = 0;
    motor_down = 0;
end

% Door safety: motors should not run while doors are operating
if door_timer > 0 && (motor_up == 1 || motor_down == 1)
    warning('SAFETY VIOLATION: Motor running while doors operating!');
    motor_up = 0;
    motor_down = 0;
end

end

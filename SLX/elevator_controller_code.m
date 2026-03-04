function output = elevator_controller(input)
%% ELEVATOR CONTROLLER - MATLAB Function for Simulink
% Inputs: [floor1_call, floor2_call, floor3_call]
% Outputs: [current_floor, motor_direction, door_open, state]
%
% States: 1=FLOOR_1, 2=MOVING_UP, 3=FLOOR_2, 4=MOVING_DOWN, 5=FLOOR_3
% Motor: 1=UP, 0=STOP, -1=DOWN
% Door: 1=OPEN, 0=CLOSED

    % Persistent variables to maintain state between calls
    persistent current_state current_floor direction timer
    
    if isempty(current_state)
        current_state = 1;  % Start at FLOOR_1
        current_floor = 1;
        direction = 0;
        timer = 0;
    end
    
    % Parse inputs
    floor1_call = input(1) > 0.5;
    floor2_call = input(2) > 0.5;
    floor3_call = input(3) > 0.5;
    
    % State constants
    FLOOR_1 = 1;
    MOVING_UP = 2;
    FLOOR_2 = 3;
    MOVING_DOWN = 4;
    FLOOR_3 = 5;
    
    % Default outputs
    motor_dir = 0;
    door_open = 0;
    
    % Timer for state transitions
    timer = timer + 1;
    
    % State machine logic
    switch current_state
        case FLOOR_1
            current_floor = 1;
            door_open = 1;
            motor_dir = 0;
            
            % Check for calls above
            if (floor2_call || floor3_call) && timer > 10
                door_open = 0;
                direction = 1;
                current_state = MOVING_UP;
                timer = 0;
            end
            
        case MOVING_UP
            door_open = 0;
            motor_dir = 1;
            
            % Simulate floor transition
            if timer > 20
                if current_floor < 3
                    current_floor = current_floor + 1;
                end
                
                % Check if need to stop at Floor 2
                if current_floor == 2 && floor2_call
                    current_state = FLOOR_2;
                    timer = 0;
                % Arrived at Floor 3
                elseif current_floor >= 3
                    current_floor = 3;
                    current_state = FLOOR_3;
                    timer = 0;
                else
                    timer = 0;  % Reset timer for next floor
                end
            end
            
        case FLOOR_2
            current_floor = 2;
            door_open = 1;
            motor_dir = 0;
            
            if timer > 10
                % Decide direction based on calls
                if floor3_call && direction >= 0
                    door_open = 0;
                    direction = 1;
                    current_state = MOVING_UP;
                    timer = 0;
                elseif floor1_call
                    door_open = 0;
                    direction = -1;
                    current_state = MOVING_DOWN;
                    timer = 0;
                elseif floor3_call
                    door_open = 0;
                    direction = 1;
                    current_state = MOVING_UP;
                    timer = 0;
                end
            end
            
        case MOVING_DOWN
            door_open = 0;
            motor_dir = -1;
            
            % Simulate floor transition
            if timer > 20
                if current_floor > 1
                    current_floor = current_floor - 1;
                end
                
                % Check if need to stop at Floor 2
                if current_floor == 2 && floor2_call
                    current_state = FLOOR_2;
                    timer = 0;
                % Arrived at Floor 1
                elseif current_floor <= 1
                    current_floor = 1;
                    current_state = FLOOR_1;
                    timer = 0;
                else
                    timer = 0;
                end
            end
            
        case FLOOR_3
            current_floor = 3;
            door_open = 1;
            motor_dir = 0;
            
            % Check for calls below
            if (floor1_call || floor2_call) && timer > 10
                door_open = 0;
                direction = -1;
                current_state = MOVING_DOWN;
                timer = 0;
            end
            
        otherwise
            current_state = FLOOR_1;
    end
    
    % Pack outputs
    output = [current_floor; motor_dir; door_open; current_state];
end

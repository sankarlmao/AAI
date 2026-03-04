%% Elevator State Machine - 3 Floor System
% State Machine Implementation for Elevator Control
% States: FLOOR_1, MOVING_UP, FLOOR_2, MOVING_DOWN, FLOOR_3
% Author: Elevator Control System
% Date: March 2026

classdef elevator_state_machine < handle
    properties
        current_state       % Current state of elevator
        current_floor       % Current floor number (1, 2, or 3)
        target_floor        % Target floor to reach
        direction           % 1 = UP, -1 = DOWN, 0 = IDLE
        call_queue          % Queue of floor calls
        door_open           % Door status
    end
    
    % State enumeration
    properties (Constant)
        FLOOR_1 = 1
        MOVING_UP = 2
        FLOOR_2 = 3
        MOVING_DOWN = 4
        FLOOR_3 = 5
    end
    
    methods
        %% Constructor
        function obj = elevator_state_machine()
            obj.current_state = obj.FLOOR_1;
            obj.current_floor = 1;
            obj.target_floor = 1;
            obj.direction = 0;
            obj.call_queue = [];
            obj.door_open = false;
            fprintf('Elevator initialized at Floor 1\n');
        end
        
        %% Add floor call to queue
        function add_call(obj, floor)
            if floor >= 1 && floor <= 3
                if ~ismember(floor, obj.call_queue)
                    obj.call_queue = [obj.call_queue, floor];
                    fprintf('Call added for Floor %d\n', floor);
                end
            else
                fprintf('Invalid floor number: %d\n', floor);
            end
        end
        
        %% Get state name string
        function name = get_state_name(obj, state)
            switch state
                case obj.FLOOR_1
                    name = 'FLOOR_1';
                case obj.MOVING_UP
                    name = 'MOVING_UP';
                case obj.FLOOR_2
                    name = 'FLOOR_2';
                case obj.MOVING_DOWN
                    name = 'MOVING_DOWN';
                case obj.FLOOR_3
                    name = 'FLOOR_3';
                otherwise
                    name = 'UNKNOWN';
            end
        end
        
        %% Process next state transition
        function process_state(obj)
            old_state = obj.current_state;
            
            switch obj.current_state
                case obj.FLOOR_1
                    obj.current_floor = 1;
                    obj.door_open = true;
                    obj.remove_from_queue(1);
                    
                    % Check for calls above
                    if obj.has_calls_above(1)
                        obj.door_open = false;
                        obj.direction = 1;
                        obj.current_state = obj.MOVING_UP;
                    end
                    
                case obj.MOVING_UP
                    obj.door_open = false;
                    % Move up
                    if obj.current_floor < 3
                        obj.current_floor = obj.current_floor + 1;
                    end
                    
                    % Check if we need to stop at current floor
                    if ismember(obj.current_floor, obj.call_queue)
                        if obj.current_floor == 2
                            obj.current_state = obj.FLOOR_2;
                        elseif obj.current_floor == 3
                            obj.current_state = obj.FLOOR_3;
                        end
                    elseif obj.current_floor == 3
                        obj.current_state = obj.FLOOR_3;
                    end
                    
                case obj.FLOOR_2
                    obj.current_floor = 2;
                    obj.door_open = true;
                    obj.remove_from_queue(2);
                    
                    % Decide direction based on remaining calls
                    if obj.direction == 1 && obj.has_calls_above(2)
                        obj.door_open = false;
                        obj.current_state = obj.MOVING_UP;
                    elseif obj.direction == -1 && obj.has_calls_below(2)
                        obj.door_open = false;
                        obj.current_state = obj.MOVING_DOWN;
                    elseif obj.has_calls_above(2)
                        obj.door_open = false;
                        obj.direction = 1;
                        obj.current_state = obj.MOVING_UP;
                    elseif obj.has_calls_below(2)
                        obj.door_open = false;
                        obj.direction = -1;
                        obj.current_state = obj.MOVING_DOWN;
                    else
                        obj.direction = 0;
                    end
                    
                case obj.MOVING_DOWN
                    obj.door_open = false;
                    % Move down
                    if obj.current_floor > 1
                        obj.current_floor = obj.current_floor - 1;
                    end
                    
                    % Check if we need to stop at current floor
                    if ismember(obj.current_floor, obj.call_queue)
                        if obj.current_floor == 2
                            obj.current_state = obj.FLOOR_2;
                        elseif obj.current_floor == 1
                            obj.current_state = obj.FLOOR_1;
                        end
                    elseif obj.current_floor == 1
                        obj.current_state = obj.FLOOR_1;
                    end
                    
                case obj.FLOOR_3
                    obj.current_floor = 3;
                    obj.door_open = true;
                    obj.remove_from_queue(3);
                    
                    % Check for calls below
                    if obj.has_calls_below(3)
                        obj.door_open = false;
                        obj.direction = -1;
                        obj.current_state = obj.MOVING_DOWN;
                    end
            end
            
            % Print state transition
            if old_state ~= obj.current_state
                fprintf('State: %s -> %s (Floor: %d)\n', ...
                    obj.get_state_name(old_state), ...
                    obj.get_state_name(obj.current_state), ...
                    obj.current_floor);
            end
        end
        
        %% Check if there are calls above current floor
        function result = has_calls_above(obj, floor)
            result = any(obj.call_queue > floor);
        end
        
        %% Check if there are calls below current floor
        function result = has_calls_below(obj, floor)
            result = any(obj.call_queue < floor);
        end
        
        %% Remove floor from call queue
        function remove_from_queue(obj, floor)
            obj.call_queue = obj.call_queue(obj.call_queue ~= floor);
        end
        
        %% Display current status
        function display_status(obj)
            fprintf('\n=== Elevator Status ===\n');
            fprintf('Current Floor: %d\n', obj.current_floor);
            fprintf('Current State: %s\n', obj.get_state_name(obj.current_state));
            fprintf('Direction: %d (1=UP, -1=DOWN, 0=IDLE)\n', obj.direction);
            fprintf('Door Open: %s\n', string(obj.door_open));
            fprintf('Call Queue: [%s]\n', num2str(obj.call_queue));
            fprintf('=======================\n\n');
        end
        
        %% Run simulation
        function run_simulation(obj, calls, steps)
            fprintf('\n========== ELEVATOR SIMULATION START ==========\n');
            
            % Add all calls
            for i = 1:length(calls)
                obj.add_call(calls(i));
            end
            
            obj.display_status();
            
            % Process states
            for i = 1:steps
                fprintf('--- Step %d ---\n', i);
                obj.process_state();
                obj.display_status();
                
                % Check if all calls served
                if isempty(obj.call_queue) && obj.direction == 0
                    fprintf('All calls served!\n');
                    break;
                end
            end
            
            fprintf('========== ELEVATOR SIMULATION END ==========\n\n');
        end
    end
end

function target_floor = priority_logic(current_floor, direction, calls)
%% PRIORITY LOGIC - ELEVATOR CALL SCHEDULING
% File: priority_logic.m
% Purpose: Determines next target floor based on priority scheduling
%
% INPUTS:
%   current_floor - Current elevator position (1, 2, or 3)
%   direction     - Current direction (0=Idle, 1=Up, -1=Down)
%   calls         - Array of call buttons [call_f1, call_f2, call_f3]
%                   Each element is 0 (not pressed) or 1 (pressed)
%
% OUTPUT:
%   target_floor  - Next floor to visit (0=none, 1-3)
%
% PRIORITY RULES:
%   1. If moving UP: serve higher floors first (ascending order)
%   2. If moving DOWN: serve lower floors first (descending order)
%   3. If IDLE: serve nearest floor (ties broken by lower floor)
%   4. Ignore calls for current floor (already there)
%
% ALGORITHM:
%   - Extract pending floor requests
%   - Remove current floor from pending
%   - Apply directional priority logic
%   - Return next target floor

%% EXTRACT CALL INFORMATION
call_f1 = calls(1);
call_f2 = calls(2);
call_f3 = calls(3);

% Build list of pending floors
pending_floors = [];
if call_f1 == 1
    pending_floors = [pending_floors, 1];
end
if call_f2 == 1
    pending_floors = [pending_floors, 2];
end
if call_f3 == 1
    pending_floors = [pending_floors, 3];
end

%% CHECK FOR NO PENDING CALLS
if isempty(pending_floors)
    % No calls pending
    target_floor = 0;
    return;
end

%% REMOVE CURRENT FLOOR FROM PENDING
% If the only call is for current floor, elevator is already there
pending_floors(pending_floors == current_floor) = [];

if isempty(pending_floors)
    % All calls were for current floor
    target_floor = 0;
    return;
end

%% APPLY PRIORITY LOGIC BASED ON DIRECTION

if direction == 1  % MOVING UP
    % Priority: Serve floors above current, then reverse
    
    % Find floors above current position
    floors_above = pending_floors(pending_floors > current_floor);
    
    if ~isempty(floors_above)
        % Serve nearest higher floor (minimum of floors above)
        target_floor = min(floors_above);
    else
        % No floors above, must reverse direction
        % Go to highest pending floor
        target_floor = max(pending_floors);
    end
    
elseif direction == -1  % MOVING DOWN
    % Priority: Serve floors below current, then reverse
    
    % Find floors below current position
    floors_below = pending_floors(pending_floors < current_floor);
    
    if ~isempty(floors_below)
        % Serve nearest lower floor (maximum of floors below)
        target_floor = max(floors_below);
    else
        % No floors below, must reverse direction
        % Go to lowest pending floor
        target_floor = min(pending_floors);
    end
    
else  % IDLE (direction == 0)
    % Priority: Serve nearest floor, ties broken by lower floor
    
    % Calculate distance to each pending floor
    distances = abs(pending_floors - current_floor);
    
    % Find minimum distance
    min_distance = min(distances);
    
    % Find all floors at minimum distance
    candidates = pending_floors(distances == min_distance);
    
    % If multiple floors at same distance, choose lower floor
    target_floor = min(candidates);
    
end

%% VALIDATE OUTPUT
% Ensure target_floor is valid (0, 1, 2, or 3)
if target_floor < 0 || target_floor > 3
    warning('Invalid target_floor computed: %d. Setting to 0.', target_floor);
    target_floor = 0;
end

end

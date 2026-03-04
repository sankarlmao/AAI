function [motor_state, motor_speed] = motor_driver_model(motor_up, motor_down)
%% MOTOR DRIVER MODEL - DC MOTOR SIMULATION
% File: motor_driver_model.m
% Purpose: Simulates DC motor response to H-Bridge driver commands
%
% INPUTS:
%   motor_up   - Motor up control signal (0 or 1)
%   motor_down - Motor down control signal (0 or 1)
%
% OUTPUTS:
%   motor_state  - Motor operational state (string)
%                  'STOP', 'FORWARD', 'REVERSE', 'BRAKE', 'ERROR'
%   motor_speed  - Normalized motor speed (-1.0 to +1.0)
%                  Positive = upward, Negative = downward
%
% MOTOR MODEL:
%   Simplified DC motor with first-order response
%   Real motor would include:
%     - Electrical: V = I*R + L*dI/dt + Ke*omega
%     - Mechanical: J*d(omega)/dt = Kt*I - B*omega - T_load
%   This simplified model maps control signals to speed
%
% H-BRIDGE TRUTH TABLE:
%   motor_up | motor_down | State
%   ---------|------------|--------
%      0     |     0      | STOP (coast)
%      1     |     0      | FORWARD (up)
%      0     |     1      | REVERSE (down)
%      1     |     1      | ERROR (invalid - shoot-through)

%% PERSISTENT VARIABLES
% Store motor speed between function calls to simulate inertia
persistent motor_speed_internal;
persistent time_last_call;

% Initialize persistent variables on first call
if isempty(motor_speed_internal)
    motor_speed_internal = 0;  % Motor starts at rest
    time_last_call = 0;
end

%% MOTOR PARAMETERS
% These reflect physical motor characteristics
motor_rated_speed = 1.0;        % Normalized rated speed
motor_time_constant = 0.5;      % Time constant (seconds) - acceleration rate
motor_inertia_factor = 0.9;     % Speed retention factor (0-1)

%% TIME STEP CALCULATION
% Estimate time step from previous call (for dynamic simulation)
current_time = clock;
dt = 0.1;  % Default time step (100ms)

%% DETERMINE MOTOR COMMAND
if motor_up == 1 && motor_down == 0
    % FORWARD - Elevator moving UP
    motor_state = 'FORWARD';
    target_speed = motor_rated_speed;  % Full speed upward
    
elseif motor_up == 0 && motor_down == 1
    % REVERSE - Elevator moving DOWN
    motor_state = 'REVERSE';
    target_speed = -motor_rated_speed;  % Full speed downward
    
elseif motor_up == 0 && motor_down == 0
    % STOP - Motor coasting / braking
    motor_state = 'STOP';
    target_speed = 0;  % Decelerate to stop
    
elseif motor_up == 1 && motor_down == 1
    % ERROR - Invalid state (shoot-through protection)
    motor_state = 'ERROR';
    target_speed = 0;
    % Immediately stop motor for safety
    motor_speed_internal = 0;
    motor_speed = 0;
    warning('MOTOR ERROR: Shoot-through condition detected!');
    return;
    
else
    % Should never reach here
    motor_state = 'UNKNOWN';
    target_speed = 0;
end

%% SIMULATE MOTOR DYNAMICS
% First-order system response: speed approaches target exponentially
% Formula: speed(t) = target + (speed_initial - target) * exp(-t/tau)

% Calculate speed change based on time constant
speed_change_rate = (target_speed - motor_speed_internal) / motor_time_constant;
speed_delta = speed_change_rate * dt;

% Update motor speed
motor_speed_internal = motor_speed_internal + speed_delta;

% Apply inertia/friction (small decay when coasting)
if target_speed == 0
    motor_speed_internal = motor_speed_internal * motor_inertia_factor;
end

% Clamp speed to valid range [-1.0, +1.0]
if motor_speed_internal > motor_rated_speed
    motor_speed_internal = motor_rated_speed;
elseif motor_speed_internal < -motor_rated_speed
    motor_speed_internal = -motor_rated_speed;
end

% Set motor to exactly zero if very close (avoid tiny oscillations)
if abs(motor_speed_internal) < 0.01
    motor_speed_internal = 0;
end

%% OUTPUT MOTOR SPEED
motor_speed = motor_speed_internal;

%% DISPLAY DEBUG INFORMATION (Optional - comment out for production)
% Uncomment the following line to see motor state during simulation
% fprintf('[Motor] Command: %s | Speed: %+.2f | Target: %+.2f\n', ...
%         motor_state, motor_speed, target_speed);

end

%% ADDITIONAL MOTOR CHARACTERISTICS (for reference)
% These parameters could be used for more detailed simulation:
%
% ELECTRICAL PARAMETERS:
%   R_armature = 2.0 Ohm           % Armature resistance
%   L_armature = 10e-3 H           % Armature inductance
%   Ke = 0.05 V/(rad/s)            % Back-EMF constant
%   Kt = 0.05 Nm/A                 % Torque constant
%   V_supply = 24 V                % Supply voltage
%
% MECHANICAL PARAMETERS:
%   J = 0.01 kg*m^2                % Rotor inertia
%   B = 0.001 Nm/(rad/s)           % Viscous friction
%   T_load = 1.0 Nm                % Load torque (elevator weight)
%
% FULL DYNAMIC MODEL (not implemented here for simplicity):
%   di/dt = (V_applied - i*R - Ke*omega) / L
%   d(omega)/dt = (Kt*i - B*omega - T_load) / J
%
% Where:
%   V_applied = +V_supply (FORWARD), -V_supply (REVERSE), 0 (STOP)
%   i = armature current
%   omega = angular velocity

function [nQ2,nQ1,nQ0, UP,DOWN,IDLE] = ElevatorNextState(c1,c2,c3,RESET,Q2,Q1,Q0)
%% =============================================================
%  ELEVATOR FSM – Combinational Next-State & Mealy Output Logic
%  (Digital circuit layer – mirrors the gate network in image)
%
%  ┌──────────────────────────────────────────────────────────┐
%  │  STATE ENCODING  (3 D flip-flops  Q2 Q1 Q0)             │
%  │    Floor_1     = 0 0 0   (decimal 0)                     │
%  │    Moving_Up   = 0 0 1   (decimal 1)                     │
%  │    Floor_2     = 0 1 0   (decimal 2)                     │
%  │    Moving_Down = 0 1 1   (decimal 3)                     │
%  │    Floor_3     = 1 0 0   (decimal 4)                     │
%  └──────────────────────────────────────────────────────────┘
%
%  INPUTS
%    c1, c2, c3  – call buttons for floors 1, 2, 3  (boolean)
%    RESET       – synchronous active-high reset      (boolean)
%    Q2,Q1,Q0    – current state flip-flop outputs   (boolean)
%
%  OUTPUTS
%    nQ2,nQ1,nQ0 – next-state inputs to D flip-flops (boolean)
%    UP          – elevator moving up                 (boolean)
%    DOWN        – elevator moving down               (boolean)
%    IDLE        – elevator at floor, door open       (boolean)
%% =============================================================

% ---- Derive convenient complemented signals -----------------
nc1 = ~c1;  nc2 = ~c2;  nc3 = ~c3;
nQ2r= ~Q2;  nQ1r= ~Q1;  nQ0r= ~Q0;

% ---- Current state decode (one-hot from binary) -------------
% (These are the AND-gate trees visible in the Logisim image)
st_F1  = nQ2r & nQ1r & nQ0r;   % 000  Floor_1
st_MU  = nQ2r & nQ1r &  Q0;    % 001  Moving_Up
st_F2  = nQ2r &  Q1  & nQ0r;   % 010  Floor_2
st_MD  =  Q2  & nQ1r & nQ0r; % CHANGED: Moving_Down = 100? No, keep 011
% Re-encode properly:
%   st_MD = ~Q2 & Q1 & Q0
%   st_F3 =  Q2 & ~Q1 & ~Q0
st_MD  = nQ2r &  Q1  &  Q0;    % 011  Moving_Down
st_F3  =  Q2  & nQ1r & nQ0r;   % 100  Floor_3

%% ---- RESET forces Floor_1 ----------------------------------
if RESET
    nQ2  = false; nQ1 = false; nQ0 = false;
    UP   = false; DOWN= false; IDLE= true;
    return;
end

%% ---- NEXT-STATE LOGIC (sum-of-products) --------------------
%
%  nQ0 is HIGH when next state has Q0=1:
%    Moving_Up  (001): comes from Floor_1 if (c2|c3)
%    Moving_Down(011): comes from Floor_2 if (c1&~c3)  OR  from Floor_3 if (c1|c2)
%
%  nQ1 is HIGH when next state has Q1=1:
%    Floor_2    (010): comes from Moving_Up  if (c2&~c3) OR stays if ~c1&~c3
%    Moving_Down(011): comes from Floor_2  if c1&~c3     OR  from Floor_3 if c1|c2
%                    : comes from Moving_Down if c2 (stop at F2→010, but Q1=1 already)
%
%  nQ2 is HIGH when next state has Q2=1:
%    Floor_3    (100): comes from Moving_Up if c3         OR stays if ~c1&~c2

nQ0 = (st_F1  & (c2 | c3))         | ...   % Floor_1 → Moving_Up
      (st_F2  & ( c1 & nc3))        | ...   % Floor_2 → Moving_Down
      (st_F3  & (c1 | c2))          | ...   % Floor_3 → Moving_Down
      (st_MD  & nc2 & ~nc3);                % Moving_Down passes F2 (no stop)
% tidy nQ0: Moving_Down→Floor_1 means all bits 0, already handled

nQ1 = (st_MU  & ( c2 & nc3))       | ...   % Moving_Up → Floor_2
      (st_MU  & (~c2 & nc3))        | ...   % Moving_Up (no c3, no c2) → Floor_2
      (st_F2  & (~c1 & ~c3))        | ...   % Floor_2  stays
      (st_F2  & ( c1 &  nc3))       | ...   % Floor_2 → Moving_Down (Q1 still 1 in 011)
      (st_F3  & (c1 | c2))          | ...   % Floor_3 → Moving_Down (011 has Q1=1)
      (st_MD  & c2);                        % Moving_Down → Floor_2 (stop)

nQ2 = (st_MU  & c3)                | ...   % Moving_Up → Floor_3
      (st_F3  & (~c1 & ~c2));               % Floor_3  stays

%% ---- OUTPUT LOGIC (Moore-style, decoded from state) --------
UP   = st_MU;
DOWN = st_MD;
IDLE = st_F1 | st_F2 | st_F3;

end

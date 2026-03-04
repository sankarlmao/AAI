function ElevatorCallProcessing()
% =========================================================================
%  ELEVATOR CALL PROCESSING SYSTEM
%  Single-file MATLAB GUI — State Machine | H-Bridge Motor Driver | FPGA
%
%  Run:  ElevatorCallProcessing()
%  Req:  MATLAB R2018b+ (uifigure / uitabgroup)
% =========================================================================

%% ── Shared State ─────────────────────────────────────────────────────────
S.currentFloor  = 1;          % 1 | 2 | 3
S.direction     = 'idle';     % 'idle' | 'up' | 'down'
S.smState       = 'FLOOR_1';  % state-machine state string
S.smQueue       = [];         % pending floor requests
S.smMoving      = false;
S.motorState    = 'off';      % 'up' | 'down' | 'off'
S.fpgaPos       = 1;
S.fpgaDir       = 'idle';
S.fpgaCalls     = [];         % e.g. [1 3]
S.logLines      = {'[00:00]  System initialised.  Elevator at Floor 1.  Idle.'};
S.logTime       = 0;

%% ── Main Figure ──────────────────────────────────────────────────────────
fig = uifigure('Name','Elevator Call Processing System', ...
               'Position',[60 40 1180 760], ...
               'Color',[0.08 0.09 0.11], ...
               'Resize','on');

% Title bar
uititle = uilabel(fig,'Text','▲  ELEVATOR CALL PROCESSING SYSTEM', ...
    'Position',[0 720 1180 40], ...
    'FontSize',18,'FontWeight','bold', ...
    'FontColor',[0.35 0.65 1], ...
    'HorizontalAlignment','center', ...
    'BackgroundColor',[0.10 0.14 0.22]);

% Sub-title
uilabel(fig,'Text','State Machine  |  H-Bridge Motor Driver (LTSpice)  |  FPGA Priority Logic', ...
    'Position',[0 700 1180 22], ...
    'FontSize',10,'FontColor',[0.55 0.60 0.65], ...
    'HorizontalAlignment','center', ...
    'BackgroundColor',[0.08 0.09 0.11]);

%% ── Tab Group ────────────────────────────────────────────────────────────
tg = uitabgroup(fig,'Position',[10 10 1160 688], ...
    'SelectionChangedFcn', @onTabChange);

tab1 = uitab(tg,'Title',' ▶  State Machine ','BackgroundColor',[0.11 0.13 0.17]);
tab2 = uitab(tg,'Title',' ⚡  H-Bridge Motor Driver ','BackgroundColor',[0.11 0.13 0.17]);
tab3 = uitab(tg,'Title',' ◼  FPGA Priority Logic ','BackgroundColor',[0.11 0.13 0.17]);

%% ══════════════════════════════════════════════════════════════════════════
%%  TAB 1 – STATE MACHINE
%% ══════════════════════════════════════════════════════════════════════════
axSM = uiaxes(tab1,'Position',[10 200 740 460], ...
    'Color',[0.08 0.09 0.11], ...
    'XColor','none','YColor','none', ...
    'Box','off');
axSM.Toolbar.Visible = 'off';

% Control buttons
uibutton(tab1,'Text','CALL  Floor 1','Position',[10 155 160 38], ...
    'BackgroundColor',[0.12 0.30 0.18],'FontColor',[0.25 0.85 0.42], ...
    'FontWeight','bold','FontSize',11, ...
    'ButtonPushedFcn', @(~,~) smRequestFloor(1));

uibutton(tab1,'Text','CALL  Floor 2','Position',[185 155 160 38], ...
    'BackgroundColor',[0.30 0.25 0.10],'FontColor',[0.88 0.70 0.18], ...
    'FontWeight','bold','FontSize',11, ...
    'ButtonPushedFcn', @(~,~) smRequestFloor(2));

uibutton(tab1,'Text','CALL  Floor 3','Position',[360 155 160 38], ...
    'BackgroundColor',[0.32 0.11 0.11],'FontColor',[0.96 0.32 0.32], ...
    'FontWeight','bold','FontSize',11, ...
    'ButtonPushedFcn', @(~,~) smRequestFloor(3));

uibutton(tab1,'Text','↺  Reset','Position',[535 155 100 38], ...
    'BackgroundColor',[0.16 0.18 0.22],'FontColor',[0.55 0.60 0.65], ...
    'FontWeight','bold','FontSize',11, ...
    'ButtonPushedFcn', @(~,~) smReset());

% Log area
logArea = uitextarea(tab1,'Position',[10 10 740 140], ...
    'Value', S.logLines, ...
    'Editable','off', ...
    'BackgroundColor',[0.05 0.06 0.08], ...
    'FontColor',[0.25 0.85 0.42], ...
    'FontName','Courier New','FontSize',9);

% State-transition table (right panel)
uilabel(tab1,'Text','State Transition Table', ...
    'Position',[760 630 390 26], ...
    'FontSize',12,'FontWeight','bold','FontColor',[0.35 0.65 1], ...
    'BackgroundColor','none');

colNames = {'Current State','Trigger','Next State','Action'};
colData  = {
  'FLOOR_1',     'Call F2 or F3',          'MOVING_UP',    'Motor UP, doors close';
  'MOVING_UP',   'Reach Floor 2 sensor',   'FLOOR_2',      'Stop, open doors';
  'MOVING_UP',   'Reach Floor 3 sensor',   'FLOOR_3',      'Stop, open doors';
  'FLOOR_2',     'Call F3',                'MOVING_UP',    'Motor UP';
  'FLOOR_2',     'Call F1',                'MOVING_DOWN',  'Motor DOWN';
  'MOVING_DOWN', 'Reach Floor 2 sensor',   'FLOOR_2',      'Stop, open doors';
  'MOVING_DOWN', 'Reach Floor 1 sensor',   'FLOOR_1',      'Stop, open doors';
  'FLOOR_3',     'Call F1 or F2',          'MOVING_DOWN',  'Motor DOWN, doors close';
  'FLOOR_3',     'No pending calls',       'FLOOR_3',      'Remain stationary';
};
smTable = uitable(tab1,'Position',[755 80 395 550], ...
    'Data', colData, ...
    'ColumnName', colNames, ...
    'ColumnWidth',{90,130,90,130}, ...
    'RowName',[], ...
    'FontSize',9, ...
    'BackgroundColor',[0.11 0.13 0.17; 0.14 0.16 0.20], ...
    'FontColor',[0.88 0.90 0.93]);

%% ══════════════════════════════════════════════════════════════════════════
%%  TAB 2 – H-BRIDGE
%% ══════════════════════════════════════════════════════════════════════════
axHB = uiaxes(tab2,'Position',[10 220 760 440], ...
    'Color',[0.08 0.09 0.11], ...
    'XColor','none','YColor','none','Box','off');
axHB.Toolbar.Visible = 'off';

% Motor control buttons
uibutton(tab2,'Text','▲  MOVE UP  (Q1+Q4 ON)','Position',[10 175 230 38], ...
    'BackgroundColor',[0.12 0.30 0.18],'FontColor',[0.25 0.85 0.42], ...
    'FontWeight','bold','FontSize',11, ...
    'ButtonPushedFcn', @(~,~) setMotor('up'));

uibutton(tab2,'Text','■  STOP  (All OFF)','Position',[255 175 200 38], ...
    'BackgroundColor',[0.16 0.18 0.22],'FontColor',[0.55 0.60 0.65], ...
    'FontWeight','bold','FontSize',11, ...
    'ButtonPushedFcn', @(~,~) setMotor('off'));

uibutton(tab2,'Text','▼  MOVE DOWN  (Q2+Q3 ON)','Position',[470 175 250 38], ...
    'BackgroundColor',[0.32 0.11 0.11],'FontColor',[0.96 0.32 0.32], ...
    'FontWeight','bold','FontSize',11, ...
    'ButtonPushedFcn', @(~,~) setMotor('down'));

% Status label
hbStatus = uilabel(tab2,'Text','Motor State:  STOPPED', ...
    'Position',[10 140 400 32], ...
    'FontSize',13,'FontWeight','bold','FontColor',[0.55 0.60 0.65], ...
    'BackgroundColor','none');

% H-Bridge truth table
uilabel(tab2,'Text','H-Bridge Truth Table & LTSpice Parameters', ...
    'Position',[760 646 395 22], ...
    'FontSize',12,'FontWeight','bold','FontColor',[0.35 0.65 1]);

hbColNames = {'Mode','Q1','Q2','Q3','Q4','Direction','Current Path'};
hbData = {
  '▲ Moving UP',   'ON','OFF','OFF','ON',  'FORWARD', 'VCC→Q1→M+→M-→Q4→GND';
  '▼ Moving DOWN', 'OFF','ON','ON','OFF',  'REVERSE', 'VCC→Q2→M-→M+→Q3→GND';
  '■ STOP (Coast)','OFF','OFF','OFF','OFF','STOPPED',  'Open circuit';
  '⊟ BRAKE',       'ON','OFF','ON','OFF',  'BRAKE',    'Motor shorted via low-side';
  '✗ FORBIDDEN',   'ON','ON','—','—',      'SHOOT-THRU','VCC→GND  !! DANGER !!';
};
hbTable = uitable(tab2,'Position',[755 390 395 255], ...
    'Data', hbData, ...
    'ColumnName', hbColNames, ...
    'ColumnWidth',{90,30,30,30,30,70,130}, ...
    'RowName',[], ...
    'FontSize',8.5, ...
    'BackgroundColor',[0.11 0.13 0.17; 0.14 0.16 0.20], ...
    'FontColor',[0.88 0.90 0.93]);

uilabel(tab2,'Text','LTSpice Component Parameters', ...
    'Position',[760 370 395 22], ...
    'FontSize',11,'FontWeight','bold','FontColor',[0.35 0.65 1]);

ltData = {
  'V1 (Vsupply)',   'DC Source',          '12 V',            'H-Bridge power supply';
  'Q1,Q2 Hi-side',  'PMOS IRF9540',       'Vgs = -10 V',     'Connect motor to VCC';
  'Q3,Q4 Lo-side',  'NMOS IRF540',        'Vgs = +10 V',     'Connect motor to GND';
  'M1 (Motor)',     'DC Motor RL Load',   'R=5Ω L=10mH',     'Elevator cab drive';
  'D1–D4 Flyback',  'Schottky 1N5819',    'Vf = 0.3 V',      'Back-EMF protection';
  'C1 Decouple',    'Electrolytic',       '100 µF / 25 V',   'Switching transients';
  'R_sense',        'Current sense',      '0.1 Ω / 2 W',     'Motor current monitor';
  'Gate Hi-side',   'PMOS gate drive',    '0V(on) / -10V(off)', 'PMOS control';
  'Gate Lo-side',   'NMOS gate drive',    '10V(on) / 0V(off)', 'NMOS control';
};
uitable(tab2,'Position',[755 10 395 355], ...
    'Data', ltData, ...
    'ColumnName',{'Component','Type','Value','Role'}, ...
    'ColumnWidth',{90,90,90,110}, ...
    'RowName',[], ...
    'FontSize',8.5, ...
    'BackgroundColor',[0.11 0.13 0.17; 0.14 0.16 0.20], ...
    'FontColor',[0.88 0.90 0.93]);

%% ══════════════════════════════════════════════════════════════════════════
%%  TAB 3 – FPGA PRIORITY LOGIC
%% ══════════════════════════════════════════════════════════════════════════
axFP = uiaxes(tab3,'Position',[10 380 1150 280], ...
    'Color',[0.08 0.09 0.11], ...
    'XColor','none','YColor','none','Box','off');
axFP.Toolbar.Visible = 'off';

% ── Input Controls ────────────────────────────────────────────────────────
panelColor = [0.11 0.13 0.17];

uilabel(tab3,'Text','Current Position:', ...
    'Position',[10 340 130 22],'FontSize',10,'FontColor',[0.55 0.60 0.65]);
btnFpPos(1) = uibutton(tab3,'Text','Floor 1','Position',[10  315 80 26], ...
    'BackgroundColor',[0.12 0.30 0.18],'FontColor',[0.25 0.85 0.42], ...
    'FontWeight','bold','FontSize',9,'ButtonPushedFcn',@(~,~) setFpgaPos(1));
btnFpPos(2) = uibutton(tab3,'Text','Floor 2','Position',[95  315 80 26], ...
    'BackgroundColor',[0.16 0.18 0.22],'FontColor',[0.55 0.60 0.65], ...
    'FontWeight','bold','FontSize',9,'ButtonPushedFcn',@(~,~) setFpgaPos(2));
btnFpPos(3) = uibutton(tab3,'Text','Floor 3','Position',[180 315 80 26], ...
    'BackgroundColor',[0.16 0.18 0.22],'FontColor',[0.55 0.60 0.65], ...
    'FontWeight','bold','FontSize',9,'ButtonPushedFcn',@(~,~) setFpgaPos(3));

uilabel(tab3,'Text','Direction of Travel:', ...
    'Position',[280 340 150 22],'FontSize',10,'FontColor',[0.55 0.60 0.65]);
btnFpDir(1) = uibutton(tab3,'Text','Idle','Position',[280 315 72 26], ...
    'BackgroundColor',[0.12 0.30 0.18],'FontColor',[0.25 0.85 0.42], ...
    'FontWeight','bold','FontSize',9,'ButtonPushedFcn',@(~,~) setFpgaDir('idle'));
btnFpDir(2) = uibutton(tab3,'Text','▲ Up','Position',[358 315 72 26], ...
    'BackgroundColor',[0.16 0.18 0.22],'FontColor',[0.55 0.60 0.65], ...
    'FontWeight','bold','FontSize',9,'ButtonPushedFcn',@(~,~) setFpgaDir('up'));
btnFpDir(3) = uibutton(tab3,'Text','▼ Down','Position',[436 315 80 26], ...
    'BackgroundColor',[0.16 0.18 0.22],'FontColor',[0.55 0.60 0.65], ...
    'FontWeight','bold','FontSize',9,'ButtonPushedFcn',@(~,~) setFpgaDir('down'));

uilabel(tab3,'Text','Pending Floor Calls:', ...
    'Position',[540 340 160 22],'FontSize',10,'FontColor',[0.55 0.60 0.65]);
btnFpCall(1) = uibutton(tab3,'Text','Call F1','Position',[540 315 80 26], ...
    'BackgroundColor',[0.16 0.18 0.22],'FontColor',[0.55 0.60 0.65], ...
    'FontWeight','bold','FontSize',9,'ButtonPushedFcn',@(~,~) toggleFpgaCall(1));
btnFpCall(2) = uibutton(tab3,'Text','Call F2','Position',[626 315 80 26], ...
    'BackgroundColor',[0.16 0.18 0.22],'FontColor',[0.55 0.60 0.65], ...
    'FontWeight','bold','FontSize',9,'ButtonPushedFcn',@(~,~) toggleFpgaCall(2));
btnFpCall(3) = uibutton(tab3,'Text','Call F3','Position',[712 315 80 26], ...
    'BackgroundColor',[0.16 0.18 0.22],'FontColor',[0.55 0.60 0.65], ...
    'FontWeight','bold','FontSize',9,'ButtonPushedFcn',@(~,~) toggleFpgaCall(3));

% Output display labels
uilabel(tab3,'Text','▶  FPGA Decision Output', ...
    'Position',[820 356 330 22],'FontSize',11,'FontWeight','bold', ...
    'FontColor',[0.35 0.65 1]);
fpgaOutLabels(1) = uilabel(tab3,'Text','Next Target :  —', ...
    'Position',[820 328 330 22],'FontSize',10,'FontColor',[0.88 0.90 0.93]);
fpgaOutLabels(2) = uilabel(tab3,'Text','Direction   :  —', ...
    'Position',[820 304 330 22],'FontSize',10,'FontColor',[0.88 0.90 0.93]);
fpgaOutLabels(3) = uilabel(tab3,'Text','H-Bridge    :  —', ...
    'Position',[820 280 330 22],'FontSize',10,'FontColor',[0.88 0.90 0.93]);
fpgaOutLabels(4) = uilabel(tab3,'Text','OUTPUT[2:0] :  —', ...
    'Position',[820 256 330 22],'FontSize',10,'FontColor',[0.74 0.55 1.00]);

fpgaRuleLabel = uilabel(tab3,'Text','Priority Rule:  No active calls.', ...
    'Position',[10 256 800 22],'FontSize',9,'FontColor',[0.55 0.60 0.65]);

% Priority truth table (lower)
uilabel(tab3,'Text','Priority Decision Truth Table', ...
    'Position',[10 228 600 22],'FontSize',11,'FontWeight','bold', ...
    'FontColor',[0.35 0.65 1]);

fpTTData = {
  'F1','Idle/Up', '0','1','0', 'Floor 2','Only call';
  'F1','Idle/Up', '0','0','1', 'Floor 3','Only call';
  'F1','Idle/Up', '0','1','1', 'Floor 2 first','Serve in direction (up)';
  'F2','Up',      '1','0','1', 'Floor 3 first','Continue current direction';
  'F2','Down',    '1','0','1', 'Floor 1 first','Continue current direction';
  'F2','Idle',    '1','0','1', 'Floor 1 first','Down preference when idle';
  'F3','Down',    '1','1','0', 'Floor 2 first','Serve in direction (down)';
  'F3','Down',    '1','0','0', 'Floor 1','Only call';
  'Any','UP→F3 / DOWN→F1','1','0','1','Direction-dependent','UP→F3 first, DOWN/IDLE→F1 first';
};
uitable(tab3,'Position',[10 10 1140 215], ...
    'Data', fpTTData, ...
    'ColumnName',{'Position','Direction','Call F1','Call F2','Call F3','Next Target','Priority Rule'}, ...
    'ColumnWidth',{60,100,55,55,55,120,220}, ...
    'RowName',[], ...
    'FontSize',8.5, ...
    'BackgroundColor',[0.11 0.13 0.17; 0.14 0.16 0.20], ...
    'FontColor',[0.88 0.90 0.93]);

%% ══════════════════════════════════════════════════════════════════════════
%%  INITIAL DRAW
%% ══════════════════════════════════════════════════════════════════════════
drawStateMachine(axSM, S.smState);
drawHBridge(axHB, S.motorState);
drawFPGALogic(axFP, S.fpgaPos, S.fpgaDir, S.fpgaCalls);
updateFpgaOutput();

%% ══════════════════════════════════════════════════════════════════════════
%%  NESTED CALLBACK / DRAW FUNCTIONS
%% ══════════════════════════════════════════════════════════════════════════

    % ── Tab change ──────────────────────────────────────────────────────
    function onTabChange(~, evt)
        drawnow;
        switch evt.NewValue.Title
            case ' ▶  State Machine '
                drawStateMachine(axSM, S.smState);
            case ' ⚡  H-Bridge Motor Driver '
                drawHBridge(axHB, S.motorState);
            case ' ◼  FPGA Priority Logic '
                drawFPGALogic(axFP, S.fpgaPos, S.fpgaDir, S.fpgaCalls);
        end
    end

    % ────────────────────────────────────────────────────────────────────
    %  STATE MACHINE FUNCTIONS
    % ────────────────────────────────────────────────────────────────────
    function smRequestFloor(f)
        target = sprintf('FLOOR_%d', f);
        if strcmp(S.smState, target)
            smLog(sprintf('Already at Floor %d.', f), 'warn');
            return;
        end
        if S.smMoving
            S.smQueue(end+1) = f;
            smLog(sprintf('Floor %d queued (elevator busy).', f), 'info');
            return;
        end
        smDoTransition(f);
    end

    function smDoTransition(f)
        S.smMoving = true;
        path = buildSmPath(S.currentFloor, f);
        smLog(sprintf('Departing Floor %d → Floor %d', S.currentFloor, f), 'info');
        smAnimatePath(path, 1);
    end

    function path = buildSmPath(from, to)
        path = {};
        if to > from
            for flr = from:to
                if flr > from, path{end+1} = 'MOVING_UP'; end %#ok<AGROW>
                path{end+1} = sprintf('FLOOR_%d', flr);       %#ok<AGROW>
            end
        else
            for flr = from:-1:to
                if flr < from, path{end+1} = 'MOVING_DOWN'; end %#ok<AGROW>
                path{end+1} = sprintf('FLOOR_%d', flr);          %#ok<AGROW>
            end
        end
    end

    function smAnimatePath(path, idx)
        if idx > numel(path)
            S.smMoving = false;
            drawStateMachine(axSM, S.smState);
            if ~isempty(S.smQueue)
                nxt = S.smQueue(1);
                S.smQueue(1) = [];
                smDoTransition(nxt);
            end
            return;
        end
        S.smState = path{idx};
        isFloor = startsWith(S.smState, 'FLOOR_');
        if isFloor
            fnum = S.smState(end);
            S.currentFloor = str2double(fnum);
            smLog(sprintf('Arrived at Floor %s. Doors opening.', fnum));
        else
            if strcmp(S.smState,'MOVING_UP')
                smLog('Elevator moving UP ↑');
            else
                smLog('Elevator moving DOWN ↓');
            end
        end
        drawStateMachine(axSM, S.smState);
        drawnow;
        delay = 0.8;
        if isFloor, delay = 1.0; end
        timer_obj = timer('ExecutionMode','singleShot','StartDelay',delay, ...
            'TimerFcn', @(~,~) smAnimatePath(path, idx+1));
        start(timer_obj);
    end

    function smReset()
        S.currentFloor = 1;
        S.smState      = 'FLOOR_1';
        S.smQueue      = [];
        S.smMoving     = false;
        S.logLines     = {'[00:00]  System reset.  Elevator at Floor 1.  Idle.'};
        S.logTime      = 0;
        logArea.Value  = S.logLines;
        drawStateMachine(axSM, S.smState);
    end

    function smLog(msg, type)
        if nargin < 2, type = 'ok'; end
        S.logTime = S.logTime + 1;
        mm = floor(S.logTime/60);
        ss = mod(S.logTime, 60);
        prefix = sprintf('[%02d:%02d]  ', mm, ss);
        switch type
            case 'warn', entry = [prefix '⚠ ' msg];
            case 'info', entry = [prefix '→ ' msg];
            otherwise,   entry = [prefix '✓ ' msg];
        end
        S.logLines{end+1} = entry;
        logArea.Value = S.logLines;
        scroll(logArea,'bottom');
    end

    % ────────────────────────────────────────────────────────────────────
    %  H-BRIDGE FUNCTIONS
    % ────────────────────────────────────────────────────────────────────
    function setMotor(st)
        S.motorState = st;
        switch st
            case 'up'
                hbStatus.Text      = 'Motor State:  MOVING UP ↑';
                hbStatus.FontColor = [0.25 0.85 0.42];
            case 'down'
                hbStatus.Text      = 'Motor State:  MOVING DOWN ↓';
                hbStatus.FontColor = [0.96 0.32 0.32];
            otherwise
                hbStatus.Text      = 'Motor State:  STOPPED';
                hbStatus.FontColor = [0.55 0.60 0.65];
        end
        drawHBridge(axHB, st);
    end

    % ────────────────────────────────────────────────────────────────────
    %  FPGA FUNCTIONS
    % ────────────────────────────────────────────────────────────────────
    function setFpgaPos(p)
        S.fpgaPos = p;
        for k=1:3
            if k==p
                btnFpPos(k).BackgroundColor = [0.12 0.30 0.18];
                btnFpPos(k).FontColor       = [0.25 0.85 0.42];
            else
                btnFpPos(k).BackgroundColor = [0.16 0.18 0.22];
                btnFpPos(k).FontColor       = [0.55 0.60 0.65];
            end
        end
        updateFpgaOutput();
        drawFPGALogic(axFP, S.fpgaPos, S.fpgaDir, S.fpgaCalls);
    end

    function setFpgaDir(d)
        S.fpgaDir = d;
        dmap = {'idle','up','down'};
        for k=1:3
            if strcmp(dmap{k}, d)
                btnFpDir(k).BackgroundColor = [0.12 0.18 0.30];
                btnFpDir(k).FontColor       = [0.35 0.65 1.00];
            else
                btnFpDir(k).BackgroundColor = [0.16 0.18 0.22];
                btnFpDir(k).FontColor       = [0.55 0.60 0.65];
            end
        end
        updateFpgaOutput();
        drawFPGALogic(axFP, S.fpgaPos, S.fpgaDir, S.fpgaCalls);
    end

    function toggleFpgaCall(f)
        idx = find(S.fpgaCalls == f, 1);
        if isempty(idx)
            S.fpgaCalls(end+1) = f;
            btnFpCall(f).BackgroundColor = [0.20 0.12 0.30];
            btnFpCall(f).FontColor       = [0.74 0.55 1.00];
        else
            S.fpgaCalls(idx)   = [];
            btnFpCall(f).BackgroundColor = [0.16 0.18 0.22];
            btnFpCall(f).FontColor       = [0.55 0.60 0.65];
        end
        updateFpgaOutput();
        drawFPGALogic(axFP, S.fpgaPos, S.fpgaDir, S.fpgaCalls);
    end

    function updateFpgaOutput()
        [tgt, ndir, rule] = computePriority(S.fpgaPos, S.fpgaDir, S.fpgaCalls);
        if isempty(tgt)
            fpgaOutLabels(1).Text      = 'Next Target :  No pending calls';
            fpgaOutLabels(2).Text      = 'Direction   :  STOP';
            fpgaOutLabels(3).Text      = 'H-Bridge    :  All OFF';
            fpgaOutLabels(4).Text      = 'OUTPUT[2:0] :  000';
            fpgaRuleLabel.Text = ['Priority Rule:  ' rule];
            return;
        end
        dirStr  = upper(ndir);
        hbCmd   = 'Q1+Q4 ON (UP)';
        if strcmp(ndir,'down'), hbCmd = 'Q2+Q3 ON (DOWN)'; end
        outBus  = '001';
        if tgt==2, outBus='010'; elseif tgt==3, outBus='100'; end

        fpgaOutLabels(1).Text = sprintf('Next Target :  Floor %d', tgt);
        fpgaOutLabels(2).Text = sprintf('Direction   :  %s', dirStr);
        fpgaOutLabels(3).Text = sprintf('H-Bridge    :  %s', hbCmd);
        fpgaOutLabels(4).Text = sprintf('OUTPUT[2:0] :  %s  (Floor %d)', outBus, tgt);
        fpgaRuleLabel.Text    = ['Priority Rule:  ' rule];

        tColors = {[0.25 0.85 0.42],[0.88 0.70 0.18],[0.96 0.32 0.32]};
        fpgaOutLabels(1).FontColor = tColors{tgt};
        fpgaOutLabels(2).FontColor = ...
            [0.25 0.85 0.42]*(strcmp(ndir,'up')) + [0.96 0.32 0.32]*(strcmp(ndir,'down'));
    end

end % ElevatorCallProcessing()


%% ══════════════════════════════════════════════════════════════════════════
%%  STANDALONE DRAWING FUNCTIONS (outside nested scope for clarity)
%% ══════════════════════════════════════════════════════════════════════════

% ─── computePriority ──────────────────────────────────────────────────────
function [target, direction, rule] = computePriority(pos, dir, calls)
    target    = [];
    direction = '';
    rule      = 'No active calls.';
    if isempty(calls), return; end
    filtered = calls(calls ~= pos);
    if isempty(filtered)
        rule = 'Already at called floor.';
        return;
    end
    above = sort(filtered(filtered > pos), 'ascend');
    below = sort(filtered(filtered < pos), 'descend');

    if strcmp(dir,'up')
        if ~isempty(above)
            target    = above(1);
            direction = 'up';
            rule      = sprintf('Moving UP → serve next floor above first: Floor %d', target);
            return;
        end
        target    = below(1);
        direction = 'down';
        rule      = sprintf('No floors above → reverse DOWN to Floor %d', target);
        return;
    end
    if strcmp(dir,'down')
        if ~isempty(below)
            target    = below(1);
            direction = 'down';
            rule      = sprintf('Moving DOWN → serve next floor below first: Floor %d', target);
            return;
        end
        target    = above(1);
        direction = 'up';
        rule      = sprintf('No floors below → reverse UP to Floor %d', target);
        return;
    end
    % idle – closest, break tie by going down
    all_d = abs(filtered - pos);
    [~,mi] = min(all_d);
    target    = filtered(mi);
    direction = 'up';
    if target < pos, direction = 'down'; end
    rule = sprintf('Idle: serve closest call → Floor %d', target);
end


% ─── drawStateMachine ────────────────────────────────────────────────────
function drawStateMachine(ax, currentState)
    cla(ax);
    ax.XLim = [0 10]; ax.YLim = [0 7];
    ax.Color = [0.08 0.09 0.11];
    hold(ax,'on');

    % Node definitions: [cx, cy, radius, label, colorActive, colorInactive]
    nodes = struct();
    nodes.FLOOR_1     = struct('cx',1.1, 'cy',3.5, 'r',0.75, 'lbl',{'FLOOR 1','(Idle)'}, 'col',[0.25 0.85 0.42]);
    nodes.MOVING_UP   = struct('cx',3.8, 'cy',5.8, 'r',0.75, 'lbl',{'MOVING','UP ↑'},     'col',[0.35 0.65 1.00]);
    nodes.FLOOR_2     = struct('cx',6.5, 'cy',3.5, 'r',0.75, 'lbl',{'FLOOR 2','(Stop)'},  'col',[0.88 0.70 0.18]);
    nodes.MOVING_DOWN = struct('cx',3.8, 'cy',1.2, 'r',0.75, 'lbl',{'MOVING','DOWN ↓'},   'col',[0.86 0.43 0.17]);
    nodes.FLOOR_3     = struct('cx',9.0, 'cy',3.5, 'r',0.75, 'lbl',{'FLOOR 3','(Idle)'},  'col',[0.96 0.32 0.32]);

    stateNames = fieldnames(nodes);

    % ── Draw transitions ──────────────────────────────────────────────
    edges = {
        'FLOOR_1',    'MOVING_UP',    'Call F2/F3',      0.30,  0.70;
        'MOVING_UP',  'FLOOR_2',      'Sensor F2',       0.30,  0.70;
        'MOVING_UP',  'FLOOR_3',      'Sensor F3',       0.20,  0.80;
        'FLOOR_2',    'MOVING_UP',    'Call F3',         0.30,  0.70;
        'FLOOR_2',    'MOVING_DOWN',  'Call F1',         0.30,  0.70;
        'MOVING_DOWN','FLOOR_2',      'Sensor F2',       0.30,  0.70;
        'MOVING_DOWN','FLOOR_1',      'Sensor F1',       0.40,  0.60;
        'FLOOR_3',    'MOVING_DOWN',  'Call F1/F2',      0.30,  0.70;
    };

    for e = 1:size(edges,1)
        n1   = nodes.(edges{e,1});
        n2   = nodes.(edges{e,2});
        lbl  = edges{e,3};
        t1   = edges{e,4};
        t2   = edges{e,5};

        % Offset to avoid overlap (parallel edges use midpoint perturbation)
        mx = (n1.cx + n2.cx)/2;  my = (n1.cy + n2.cy)/2;
        dx = n2.cx - n1.cx;      dy = n2.cy - n1.cy;
        ln = max(sqrt(dx^2+dy^2),0.01);
        % Normal perturbation
        px = -dy/ln * 0.35;  py = dx/ln * 0.35;

        cpx = mx + px;  cpy = my + py;

        % Bezier sample points
        tt = linspace(0,1,60);
        bx = (1-tt).^2*n1.cx + 2*(1-tt).*tt*cpx + tt.^2*n2.cx;
        by = (1-tt).^2*n1.cy + 2*(1-tt).*tt*cpy + tt.^2*n2.cy;

        % Trim to circle edges
        [~,i1] = min(abs(tt-t1));
        [~,i2] = min(abs(tt-t2));
        bxp = bx(i1:i2);  byp = by(i1:i2);

        plot(ax, bxp, byp, '-', 'Color',[0.30 0.34 0.40], 'LineWidth',1.4);

        % Arrowhead at end
        if numel(bxp)>2
            arx = bxp(end);  ary = byp(end);
            adx = bxp(end)-bxp(end-2);  ady = byp(end)-byp(end-2);
            ang = atan2(ady,adx);
            sz  = 0.18;
            ax1 = arx - sz*cos(ang-0.35);  ay1 = ary - sz*sin(ang-0.35);
            ax2 = arx - sz*cos(ang+0.35);  ay2 = ary - sz*sin(ang+0.35);
            patch(ax,[arx ax1 ax2],[ary ay1 ay2],[0.30 0.34 0.40], ...
                'EdgeColor','none','FaceAlpha',0.9);
        end

        % Edge label at midpoint of trimmed bezier
        lx = bxp(round(numel(bxp)/2)) + px*0.55;
        ly = byp(round(numel(byp)/2)) + py*0.55;
        text(ax, lx, ly, lbl, 'Color',[0.55 0.60 0.65], ...
            'FontSize',7.5,'HorizontalAlignment','center', ...
            'BackgroundColor',[0.10 0.11 0.14],'Margin',1);
    end

    % ── Draw nodes ────────────────────────────────────────────────────
    th = linspace(0, 2*pi, 80);
    for k = 1:numel(stateNames)
        nm  = stateNames{k};
        nd  = nodes.(nm);
        act = strcmp(nm, currentState);
        col = nd.col;
        fc  = col*0.15 + [0.08 0.09 0.11]*(1-0.15);
        if act, fc = col*0.30; end
        ec  = col; if ~act, ec = [0.30 0.34 0.40]; end
        lw  = 1.5; if act, lw = 3; end

        xc = nd.cx + nd.r*cos(th);
        yc = nd.cy + nd.r*sin(th);
        patch(ax, xc, yc, fc, 'EdgeColor', ec, 'LineWidth', lw);

        % Label
        fc2 = [0.55 0.60 0.65];  fw = 'normal';
        if act, fc2 = col; fw = 'bold'; end
        for li = 1:numel(nd.lbl)
            yoff = (li-1)*0.28 - (numel(nd.lbl)-1)*0.14;
            text(ax, nd.cx, nd.cy + yoff, nd.lbl{li}, ...
                'Color',fc2,'FontSize',9,'FontWeight',fw, ...
                'HorizontalAlignment','center','VerticalAlignment','middle');
        end
        if act
            text(ax, nd.cx, nd.cy - nd.r - 0.22, '● ACTIVE', ...
                'Color', col, 'FontSize',8,'FontWeight','bold', ...
                'HorizontalAlignment','center');
        end
    end

    % Legend
    text(ax, 0.2, 0.35, 'States:', 'Color',[0.35 0.65 1.00], ...
        'FontSize',9,'FontWeight','bold');
    legCols = {[0.25 0.85 0.42],[0.35 0.65 1],[0.88 0.70 0.18],[0.86 0.43 0.17],[0.96 0.32 0.32]};
    legTxt  = {'Floor 1','Moving Up','Floor 2','Moving Down','Floor 3'};
    for k=1:5
        patch(ax,[0.15+0 0.38+0 0.38+0 0.15+0], [0.1+(k-1)*0.01 0.1+(k-1)*0.01 0.26+(k-1)*0.01 0.26+(k-1)*0.01]-0.07, ...
            legCols{k},'EdgeColor','none');
    end
    text(ax,0.25,0.18, strjoin(legTxt,' | '), 'Color',[0.55 0.60 0.65],'FontSize',7.5);

    title(ax, 'Elevator State Machine — 5-State FSM', ...
        'Color',[0.35 0.65 1],'FontSize',12,'FontWeight','bold');
    hold(ax,'off');
end


% ─── drawHBridge ──────────────────────────────────────────────────────────
function drawHBridge(ax, motorState)
    cla(ax);
    ax.XLim = [0 14]; ax.YLim = [0 10];
    ax.Color = [0.08 0.09 0.11];
    hold(ax,'on');

    q1on = strcmp(motorState,'up');
    q4on = strcmp(motorState,'up');
    q2on = strcmp(motorState,'down');
    q3on = strcmp(motorState,'down');

    ON  = [0.25 0.85 0.42];
    OFF = [0.30 0.34 0.40];
    MC  = [0.30 0.34 0.40];
    if strcmp(motorState,'up'),   MC = [0.25 0.85 0.42]; end
    if strcmp(motorState,'down'), MC = [0.96 0.32 0.32]; end

    % VCC rail
    rectangle(ax,'Position',[1.5 8.8 11 0.5], ...
        'FaceColor',[0.10 0.22 0.14],'EdgeColor',[0.25 0.85 0.42],'LineWidth',1.5);
    text(ax,7,9.12,'VCC  +12 V','Color',[0.25 0.85 0.42], ...
        'FontSize',10,'FontWeight','bold','HorizontalAlignment','center');

    % GND rail
    rectangle(ax,'Position',[1.5 0.7 11 0.5], ...
        'FaceColor',[0.22 0.10 0.10],'EdgeColor',[0.96 0.32 0.32],'LineWidth',1.5);
    text(ax,7,0.97,'GND','Color',[0.96 0.32 0.32], ...
        'FontSize',10,'FontWeight','bold','HorizontalAlignment','center');

    % Motor box (center)
    rectangle(ax,'Position',[5.2 4.0 3.6 2.0], ...
        'FaceColor',MC*0.22 + [0.05 0.06 0.08]*0.78, ...
        'EdgeColor',MC,'LineWidth',2.5,'Curvature',[0.15 0.25]);
    text(ax,7,5.25,'M','Color',MC,'FontSize',18,'FontWeight','bold', ...
        'HorizontalAlignment','center');
    text(ax,7,4.35,'DC Motor','Color',MC,'FontSize',8.5, ...
        'HorizontalAlignment','center');
    text(ax,5.5,5.1,'M+','Color',MC,'FontSize',8,'FontWeight','bold');
    text(ax,8.2,5.1,'M-','Color',MC,'FontSize',8,'FontWeight','bold');

    % ── Transistors ──────────────────────────────────────────────────
    % Q1 top-left, Q2 top-right, Q3 bottom-left, Q4 bottom-right
    drawFET(ax, 2.5, 7.0, q1on, 'Q1','PMOS','top-left');
    drawFET(ax,11.5, 7.0, q2on, 'Q2','PMOS','top-right');
    drawFET(ax, 2.5, 3.0, q3on, 'Q3','NMOS','bot-left');
    drawFET(ax,11.5, 3.0, q4on, 'Q4','NMOS','bot-right');

    % ── Wires ─────────────────────────────────────────────────────────
    % Left column
    drawWire(ax,2.5,8.8, 2.5,7.6, q1on);   % VCC → Q1
    drawWire(ax,2.5,6.4, 2.5,5.0, q1on);   % Q1 → M+
    drawWire(ax,2.5,5.0, 5.2,5.0, q1on);   % → Motor M+
    drawWire(ax,2.5,3.6, 2.5,2.4, q3on);   % Q3 → ...
    drawWire(ax,2.5,5.0, 2.5,3.6, q3on);   % M- side (bot)
    drawWire(ax,2.5,2.4, 2.5,1.2, q3on);   % → GND
    % Right column
    drawWire(ax,11.5,8.8,11.5,7.6, q2on);
    drawWire(ax,11.5,6.4,11.5,5.0, q2on);
    drawWire(ax,11.5,5.0, 8.8,5.0, q2on);
    drawWire(ax,11.5,3.6,11.5,2.4, q4on);
    drawWire(ax,11.5,5.0,11.5,3.6, q4on);
    drawWire(ax,11.5,2.4,11.5,1.2, q4on);

    % Current direction arrow (dashed) when active
    if strcmp(motorState,'up')
        drawDashed(ax,[2.5 7],[8.5 8.5],ON);
        drawDashed(ax,[7 11.5],[8.5 8.5],ON);
        text(ax,7,8.1,'Current flow: Q1→M+→M-→Q4','Color',ON, ...
            'FontSize',8,'HorizontalAlignment','center');
    elseif strcmp(motorState,'down')
        drawDashed(ax,[2.5 7],[1.5 1.5],[0.96 0.32 0.32]);
        drawDashed(ax,[7 11.5],[1.5 1.5],[0.96 0.32 0.32]);
        text(ax,7,2.0,'Current flow: Q2→M-→M+→Q3','Color',[0.96 0.32 0.32], ...
            'FontSize',8,'HorizontalAlignment','center');
    end

    % Flyback diodes
    drawDiode(ax, 1.5, 5.0, 'D1');
    drawDiode(ax, 3.5, 5.0, 'D2');
    drawDiode(ax,10.5, 5.0, 'D3');
    drawDiode(ax,12.5, 5.0, 'D4');

    % Decoupling cap
    drawCap(ax, 7.0, 9.35, 'C1 100µF');

    % Gate signal label
    text(ax,7,6.8,'← FPGA Gate Drive Signals →','Color',[0.88 0.70 0.18], ...
        'FontSize',8,'HorizontalAlignment','center','FontAngle','italic');

    % Gate lines (to Q1 and Q4 if UP, Q2 Q3 if DOWN)
    if strcmp(motorState,'up')
        plot(ax,[3.3 3.8],[7.0 7.0],'-','Color',[0.88 0.70 0.18],'LineWidth',1.2);
        plot(ax,[10.2 10.7],[3.0 3.0],'-','Color',[0.88 0.70 0.18],'LineWidth',1.2);
        text(ax,4,7.05,'IN1=1','Color',[0.88 0.70 0.18],'FontSize',7);
        text(ax,9.5,3.05,'IN4=1','Color',[0.88 0.70 0.18],'FontSize',7);
    elseif strcmp(motorState,'down')
        plot(ax,[10.2 10.7],[7.0 7.0],'-','Color',[0.88 0.70 0.18],'LineWidth',1.2);
        plot(ax,[3.3 3.8],[3.0 3.0],'-','Color',[0.88 0.70 0.18],'LineWidth',1.2);
        text(ax,9.5,7.05,'IN2=1','Color',[0.88 0.70 0.18],'FontSize',7);
        text(ax,4,3.05,'IN3=1','Color',[0.88 0.70 0.18],'FontSize',7);
    end

    title(ax,'H-Bridge Motor Driver Circuit  (LTSpice Simulation Model)', ...
        'Color',[0.35 0.65 1],'FontSize',12,'FontWeight','bold');
    hold(ax,'off');
end

function drawFET(ax, cx, cy, ison, name, ptype, pos)
    col  = [0.25 0.85 0.42]*ison + [0.30 0.34 0.40]*(1-ison);
    fc   = col*0.25 + [0.08 0.09 0.11]*0.75;
    r    = 0.6;
    th   = linspace(0,2*pi,60);
    patch(ax, cx+r*cos(th), cy+r*sin(th), fc, ...
        'EdgeColor',col,'LineWidth',ison*2+1);
    text(ax, cx, cy+0.1, name,'Color',col,'FontSize',8,'FontWeight','bold', ...
        'HorizontalAlignment','center');
    text(ax, cx, cy-0.22, ptype,'Color',col,'FontSize',7, ...
        'HorizontalAlignment','center');
    if ison
        text(ax, cx, cy-0.52,'ON','Color',col,'FontSize',7.5,'FontWeight','bold', ...
            'HorizontalAlignment','center');
    end
end

function drawWire(ax, x1,y1,x2,y2, active)
    col = [0.25 0.85 0.42]*active + [0.20 0.22 0.27]*(1-active);
    lw  = 2.0*active + 1.2*(1-active);
    plot(ax,[x1 x2],[y1 y2],'-','Color',col,'LineWidth',lw);
end

function drawDashed(ax, xs, ys, col)
    plot(ax, xs, ys,'--','Color',col,'LineWidth',1.5);
end

function drawDiode(ax, cx, cy, name)
    col = [0.74 0.55 1.00];
    patch(ax,[cx-0.18 cx-0.18 cx+0.18],[cy-0.22 cy+0.22 cy],col*0.5, ...
        'EdgeColor',col,'LineWidth',1);
    plot(ax,[cx+0.18 cx+0.18],[cy-0.22 cy+0.22],'-','Color',col,'LineWidth',1.5);
    text(ax,cx,cy-0.38,name,'Color',col,'FontSize',7,'HorizontalAlignment','center');
end

function drawCap(ax, cx, cy, name)
    col = [0.35 0.65 1.00];
    plot(ax,[cx-0.4 cx+0.4],[cy cy],'-','Color',col,'LineWidth',2);
    plot(ax,[cx-0.4 cx+0.4],[cy-0.12 cy-0.12],'-','Color',col,'LineWidth',2);
    text(ax,cx,cy-0.28,name,'Color',col,'FontSize',7,'HorizontalAlignment','center');
end


% ─── drawFPGALogic ────────────────────────────────────────────────────────
function drawFPGALogic(ax, pos, dir, calls)
    cla(ax);
    ax.XLim = [0 14]; ax.YLim = [0 8];
    ax.Color = [0.08 0.09 0.11];
    hold(ax,'on');

    [tgt, ndir, ~] = computePriority(pos, dir, calls);
    hasTarget = ~isempty(tgt);

    % Block definitions: [x y w h label color]
    blocks = {
        1.0, 2.5, 1.8, 3.5, {'INPUTS','Floor Calls','Position','Direction'},  [0.88 0.70 0.18];
        3.5, 2.5, 2.0, 3.5, {'PRIORITY','ENCODER','(Combinational','Logic)'},  [0.35 0.65 1.00];
        6.2, 2.5, 2.0, 3.5, {'DIRECTION','FSM','(Sequential','Logic)'},        [0.74 0.55 1.00];
        8.9, 2.8, 1.8, 3.0, {'H-BRIDGE','CTRL'},                               [0.86 0.43 0.17];
       11.4, 3.2, 1.5, 2.2, {'MOTOR'},  [0.25 0.85 0.42]*hasTarget + [0.30 0.34 0.40]*(1-hasTarget);
    };

    for k = 1:size(blocks,1)
        bx=blocks{k,1}; by=blocks{k,2}; bw=blocks{k,3}; bh=blocks{k,4};
        lbl=blocks{k,5}; col=blocks{k,6};
        rectangle(ax,'Position',[bx by bw bh], ...
            'FaceColor',col*0.18+[0.05 0.06 0.08]*0.82, ...
            'EdgeColor',col,'LineWidth',2,'Curvature',[0.1 0.15]);
        cy2 = by + bh/2;
        for li=1:numel(lbl)
            yoff = (li - (numel(lbl)+1)/2)*0.5;
            text(ax,bx+bw/2,cy2+yoff,lbl{li},'Color',col, ...
                'FontSize',8.5,'FontWeight','bold','HorizontalAlignment','center');
        end
    end

    % Connections between blocks
    conns = {1,2; 2,3; 3,4; 4,5};
    connCols = {blocks{1,6}; blocks{2,6}; blocks{3,6}; blocks{4,6}};
    for k=1:size(conns,1)
        a = conns{k,1}; b = conns{k,2};
        x1 = blocks{a,1}+blocks{a,3};  x2 = blocks{b,1};
        y1 = blocks{a,2}+blocks{a,4}/2; y2 = blocks{b,2}+blocks{b,4}/2;
        col = connCols{k}*hasTarget + [0.20 0.22 0.27]*(1-hasTarget);
        plot(ax,[x1 x2],[y1 y2],'-','Color',col,'LineWidth',2);
        % arrowhead
        ang = atan2(y2-y1, x2-x1);
        sz=0.22;
        ax1=x2-sz*cos(ang-0.3); ay1=y2-sz*sin(ang-0.3);
        ax2=x2-sz*cos(ang+0.3); ay2=y2-sz*sin(ang+0.3);
        patch(ax,[x2 ax1 ax2],[y2 ay1 ay2],col,'EdgeColor','none');
    end

    % Bus labels
    busLabels = {
        2.85, 6.35, {'call[2:0]','pos[1:0]','dir[1:0]'}, blocks{1,6};
        5.55, 6.35, {'target[1:0]','next_dir'},            blocks{2,6};
        8.25, 6.35, {'state[2:0]'},                        blocks{3,6};
       10.75, 6.10, {'IN[3:0]'},                           blocks{4,6};
    };
    for k=1:size(busLabels,1)
        bsx=busLabels{k,1}; bsy=busLabels{k,2};
        txt=busLabels{k,3}; bcol=busLabels{k,4};
        for li=1:numel(txt)
            text(ax,bsx,bsy-(li-1)*0.42,txt{li},'Color',bcol,'FontSize',7.5, ...
                'HorizontalAlignment','center','FontName','Courier New');
        end
    end

    % Input bit display (left side)
    inputBits = {
        'F1_CALL', ismember(1,calls);
        'F2_CALL', ismember(2,calls);
        'F3_CALL', ismember(3,calls);
        'POS[1:0]', pos;
        'DIR[1:0]', dir;
    };
    for k=1:size(inputBits,1)
        yp = 5.8 - (k-1)*0.65;
        text(ax, 0.05, yp, inputBits{k,1},'Color',[0.55 0.60 0.65], ...
            'FontSize',7.5,'FontName','Courier New','HorizontalAlignment','left');
        val = inputBits{k,2};
        if isnumeric(val) && isscalar(val) && val<=3 && val>=0 && val==round(val)
            if k<=3
                vc=[0.25 0.85 0.42]*val+[0.30 0.34 0.40]*(1-val);
                vs=num2str(val);
            else
                vc=[0.35 0.65 1.00]; vs=sprintf('%d',val);
            end
        elseif ischar(val)||isstring(val)
            vc=[0.88 0.70 0.18]; vs=char(val);
        else
            vc=[0.35 0.65 1.00]; vs=mat2str(val);
        end
        rectangle(ax,'Position',[0.72 yp-0.22 0.22 0.28],'FaceColor',vc*0.5,'EdgeColor',vc);
        text(ax, 0.83, yp-0.08, vs,'Color',vc,'FontSize',7, ...
            'HorizontalAlignment','center','FontWeight','bold');
    end

    % Output display (right)
    if hasTarget
        dirStr = upper(ndir);
        outBus = '001'; if tgt==2,outBus='010'; elseif tgt==3,outBus='100'; end
        tCol=[0.25 0.85 0.42]; if tgt==2,tCol=[0.88 0.70 0.18]; elseif tgt==3,tCol=[0.96 0.32 0.32]; end
        dCol=[0.25 0.85 0.42]; if strcmp(ndir,'down'),dCol=[0.96 0.32 0.32]; end
        outTxt = {sprintf('TARGET: F%d',tgt); sprintf('DIR: %s',dirStr); sprintf('OUT: %s',outBus)};
        outCols= {tCol; dCol; [0.74 0.55 1.00]};
        for k=1:3
            text(ax,13.0,5.5-(k-1)*0.7,outTxt{k},'Color',outCols{k}, ...
                'FontSize',8.5,'FontWeight','bold','FontName','Courier New', ...
                'HorizontalAlignment','left');
        end
    end

    title(ax,'FPGA Priority Logic — Block Diagram', ...
        'Color',[0.35 0.65 1],'FontSize',12,'FontWeight','bold');
    hold(ax,'off');
end

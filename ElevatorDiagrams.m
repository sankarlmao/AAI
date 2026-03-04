% =========================================================================
%  ELEVATOR CALL PROCESSING SYSTEM — Digital Circuit Diagrams
%  Run: ElevatorDiagrams
%  Shows: (1) FSM  (2) H-Bridge  (3) FPGA Priority Logic
% =========================================================================
close all;

%% ── Figure 1: State Machine (FSM) ───────────────────────────────────────
f1 = figure('Name','(1) Elevator FSM','Color',[0.08 0.09 0.11],...
    'Position',[50 80 900 640]);
ax = axes(f1,'Color',[0.08 0.09 0.11],'Position',[0 0.06 1 0.90],...
    'XColor','none','YColor','none'); hold(ax,'on');
ax.XLim=[0 10]; ax.YLim=[0 8];

% ── node definitions ──────────────────────────────────────────────────────
%  id   x    y    label-lines             color
NX = [1.2  3.8  6.4  3.8  9.2];
NY = [4.0  6.2  4.0  1.8  4.0];
NC = {[0.25 0.85 0.42],...   % F1 green
      [0.35 0.65 1.00],...   % MOVING_UP blue
      [0.88 0.70 0.18],...   % F2 yellow
      [0.86 0.43 0.17],...   % MOVING_DOWN orange
      [0.96 0.32 0.32]};     % F3 red
NL = {{'FLOOR_1','(Idle)'},{'MOVING','UP'},{'FLOOR_2','(Stop)'},...
      {'MOVING','DOWN'},{'FLOOR_3','(Idle)'}};
R  = 0.78;
th = linspace(0,2*pi,120);

%  edges: [from to  offset  label  label-x-nudge  label-y-nudge]
E = { 1,2, 0.38,'Call F2/F3', 0, 0.18;
      2,3, 0.38,'Sensor F2',  0,-0.18;
      2,5, 0.28,'Sensor F3',  0, 0.18;
      3,2, 0.38,'Call F3',    0, 0.18;
      3,4, 0.38,'Call F1',    0,-0.18;
      4,3, 0.38,'Sensor F2',  0, 0.18;
      4,1, 0.38,'Sensor F1',  0,-0.18;
      5,4, 0.38,'Call F1/F2', 0, 0.18 };

for e = 1:size(E,1)
    i1=E{e,1}; i2=E{e,2}; no=E{e,3}; lbl=E{e,4};
    bezArrow(ax, NX(i1),NY(i1), NX(i2),NY(i2), no, lbl);
end

for k = 1:5
    c = NC{k};
    patch(ax, NX(k)+R*cos(th), NY(k)+R*sin(th), ...
        c*0.18+[0.06 0.07 0.09]*0.82, 'EdgeColor',c,'LineWidth',2.2);
    lbs = NL{k};
    for li = 1:numel(lbs)
        text(ax, NX(k), NY(k)+(li-1)*0.36-(numel(lbs)-1)*0.18, lbs{li}, ...
            'Color',c,'FontSize',9.5,'FontWeight','bold',...
            'HorizontalAlignment','center','VerticalAlignment','middle');
    end
end

% state names along bottom
sn = {'FLOOR_1','MOVING_UP','FLOOR_2','MOVING_DOWN','FLOOR_3'};
for k=1:5, text(ax,NX(k),NY(k)-R-0.28,sn{k},'Color',NC{k}*0.75,'FontSize',7,...
    'HorizontalAlignment','center'); end

text(ax,5,0.32,...
    'Green = Floor 1  |  Blue = Moving Up  |  Yellow = Floor 2  |  Orange = Moving Down  |  Red = Floor 3',...
    'Color',[0.45 0.50 0.55],'FontSize',7.5,'HorizontalAlignment','center');

title(ax,'Elevator Finite State Machine  (5-State FSM)',...
    'Color',[0.35 0.65 1],'FontSize',14,'FontWeight','bold');
hold(ax,'off');


%% ── Figure 2: H-Bridge Motor Driver ─────────────────────────────────────
f2 = figure('Name','(2) H-Bridge Motor Driver','Color',[0.08 0.09 0.11],...
    'Position',[100 60 1000 680]);
ax2 = axes(f2,'Color',[0.08 0.09 0.11],'Position',[0 0.04 1 0.92],...
    'XColor','none','YColor','none'); hold(ax2,'on');
ax2.XLim=[0 16]; ax2.YLim=[0 11];

G  = [0.25 0.85 0.42];   % green  (VCC / active)
RD = [0.96 0.32 0.32];   % red    (GND)
BL = [0.35 0.65 1.00];   % blue   (signal)
YL = [0.88 0.70 0.18];   % yellow (labels)
PU = [0.74 0.55 1.00];   % purple (diodes)
GR = [0.30 0.34 0.40];   % grey   (inactive)

% ── power rails ──────────────────────────────────────────────────────────
rectangle(ax2,'Position',[1.2 9.6 13.6 0.6], ...
    'FaceColor',G*0.18+[0.04 0.06 0.06]*0.82,'EdgeColor',G,'LineWidth',2);
text(ax2,8,9.95,'VCC  (+12 V)','Color',G,'FontSize',11,'FontWeight','bold','HorizontalAlignment','center');

rectangle(ax2,'Position',[1.2 0.8 13.6 0.6], ...
    'FaceColor',RD*0.18+[0.06 0.04 0.04]*0.82,'EdgeColor',RD,'LineWidth',2);
text(ax2,8,1.1,'GND','Color',RD,'FontSize',11,'FontWeight','bold','HorizontalAlignment','center');

% ── motor ─────────────────────────────────────────────────────────────────
rectangle(ax2,'Position',[5.6 4.4 4.8 2.2], ...
    'FaceColor',[0.09 0.11 0.14],'EdgeColor',[0.50 0.55 0.60],'LineWidth',2.5,'Curvature',[0.12 0.20]);
text(ax2,8,5.8,'M','Color',[0.70 0.75 0.80],'FontSize',24,'FontWeight','bold','HorizontalAlignment','center');
text(ax2,8,4.75,'DC Motor  (R=5Ω, L=10mH)','Color',[0.50 0.55 0.60],'FontSize',8,'HorizontalAlignment','center');
text(ax2,5.9,5.55,'M+','Color',BL,'FontSize',9,'FontWeight','bold');
text(ax2,9.8,5.55,'M−','Color',BL,'FontSize',9,'FontWeight','bold');

% ── FETs (Q1-Q4) ──────────────────────────────────────────────────────────
%  Q1 PMOS top-left     Q2 PMOS top-right
%  Q3 NMOS bot-left     Q4 NMOS bot-right
hbFET2(ax2, 2.8, 7.8, [0.30 0.80 0.40], 'Q1', 'PMOS', 'IRF9540');
hbFET2(ax2,13.2, 7.8, [0.30 0.80 0.40], 'Q2', 'PMOS', 'IRF9540');
hbFET2(ax2, 2.8, 3.2, [0.30 0.80 0.40], 'Q3', 'NMOS', 'IRF540');
hbFET2(ax2,13.2, 3.2, [0.30 0.80 0.40], 'Q4', 'NMOS', 'IRF540');

% ── wiring ────────────────────────────────────────────────────────────────
W = [0.25 0.35 0.40];
% left column
plot(ax2,[2.8 2.8],[10.2 8.5],'-','Color',W,'LineWidth',2);   % VCC->Q1
plot(ax2,[2.8 2.8],[7.1 5.5],'-','Color',W,'LineWidth',2);    % Q1->node
plot(ax2,[2.8 5.6],[5.5 5.5],'-','Color',W,'LineWidth',2);    % node->M+
plot(ax2,[2.8 2.8],[5.5 3.9],'-','Color',W,'LineWidth',2);    % node->Q3
plot(ax2,[2.8 2.8],[2.5 1.4],'-','Color',W,'LineWidth',2);    % Q3->GND
% right column
plot(ax2,[13.2 13.2],[10.2 8.5],'-','Color',W,'LineWidth',2);
plot(ax2,[13.2 13.2],[7.1 6.5],'-','Color',W,'LineWidth',2);
plot(ax2,[13.2 10.4],[6.5 6.5],'-','Color',W,'LineWidth',2);  % Q2->M-
plot(ax2,[13.2 13.2],[6.5 3.9],'-','Color',W,'LineWidth',2);
plot(ax2,[13.2 13.2],[2.5 1.4],'-','Color',W,'LineWidth',2);

% ── flyback diodes ────────────────────────────────────────────────────────
%  placed at mid-rail junctions
dposX = [1.6  3.9  12.1  14.4];
for k = 1:4
    dx = dposX(k); dy = 5.5;
    patch(ax2,[dx-0.22 dx-0.22 dx+0.22],[dy-0.28 dy+0.28 dy],PU*0.35,'EdgeColor',PU,'LineWidth',1.2);
    plot(ax2,[dx+0.22 dx+0.22],[dy-0.28 dy+0.28],'-','Color',PU,'LineWidth',1.8);
    labels={'D1','D2','D3','D4'};
    text(ax2,dx,dy-0.55,labels{k},'Color',PU,'FontSize',7.5,'HorizontalAlignment','center');
    text(ax2,dx,dy+0.55,'1N5819','Color',PU*0.7,'FontSize',6.5,'HorizontalAlignment','center');
end

% ── gate drive lines ──────────────────────────────────────────────────────
plot(ax2,[2.8  2.8],[7.8 7.0],'--','Color',YL,'LineWidth',1.2);  % gate Q1
plot(ax2,[2.2  2.8],[7.4 7.4],'->','Color',YL,'LineWidth',1.2);
text(ax2,1.8,7.4,'IN1','Color',YL,'FontSize',8,'FontWeight','bold','HorizontalAlignment','right');

plot(ax2,[13.2 13.2],[7.8 7.0],'--','Color',YL,'LineWidth',1.2);
plot(ax2,[13.8 13.2],[7.4 7.4],'->','Color',YL,'LineWidth',1.2);
text(ax2,14.2,7.4,'IN2','Color',YL,'FontSize',8,'FontWeight','bold');

plot(ax2,[2.8  2.8],[3.2 2.5],'--','Color',YL,'LineWidth',1.2);
plot(ax2,[2.2  2.8],[2.8 2.8],'->','Color',YL,'LineWidth',1.2);
text(ax2,1.8,2.8,'IN3','Color',YL,'FontSize',8,'FontWeight','bold','HorizontalAlignment','right');

plot(ax2,[13.2 13.2],[3.2 2.5],'--','Color',YL,'LineWidth',1.2);
plot(ax2,[13.8 13.2],[2.8 2.8],'->','Color',YL,'LineWidth',1.2);
text(ax2,14.2,2.8,'IN4','Color',YL,'FontSize',8,'FontWeight','bold');

% ── decoupling cap ────────────────────────────────────────────────────────
plot(ax2,[7.2 8.8],[10.5 10.5],'-','Color',BL,'LineWidth',2.2);
plot(ax2,[7.2 8.8],[10.28 10.28],'-','Color',BL,'LineWidth',2.2);
plot(ax2,[8.0 8.0],[10.5 9.6],'-','Color',BL,'LineWidth',1.5);
plot(ax2,[8.0 8.0],[10.28 10.28],'-','Color',BL,'LineWidth',1);
text(ax2,8.0,10.75,'C1  100µF / 25V','Color',BL,'FontSize',8,'HorizontalAlignment','center');

% ── current-sense resistor ────────────────────────────────────────────────
rectangle(ax2,'Position',[7.2 0.5 1.6 0.35],'FaceColor',[0.12 0.14 0.16],...
    'EdgeColor',[0.60 0.65 0.70],'LineWidth',1.5);
text(ax2,8.0,0.31,'Rsense  0.1Ω / 2W','Color',[0.60 0.65 0.70],'FontSize',7.5,'HorizontalAlignment','center');

% ── truth table annotation ────────────────────────────────────────────────
tbY = 9.0; tbX = 0.25;
text(ax2,tbX,tbY,   'MODE         Q1  Q2  Q3  Q4  CURRENT PATH','Color',[0.50 0.55 0.60],'FontSize',7.5,'FontName','Courier');
text(ax2,tbX,tbY-0.45,'Move UP      ON  OFF OFF ON   VCC->Q1->M+->M-->Q4->GND','Color',G,'FontSize',7.5,'FontName','Courier');
text(ax2,tbX,tbY-0.90,'Move DOWN    OFF ON  ON  OFF  VCC->Q2->M-->M+->Q3->GND','Color',RD,'FontSize',7.5,'FontName','Courier');
text(ax2,tbX,tbY-1.35,'STOP (coast) OFF OFF OFF OFF  Open circuit','Color',[0.55 0.60 0.65],'FontSize',7.5,'FontName','Courier');
text(ax2,tbX,tbY-1.80,'FORBIDDEN    ON  ON  --  --   Shoot-through! VCC->GND','Color',[1 0.3 0.3],'FontSize',7.5,'FontName','Courier');

title(ax2,'H-Bridge Motor Driver  (LTSpice / IRF9540 + IRF540)',...
    'Color',[0.35 0.65 1],'FontSize',14,'FontWeight','bold');
hold(ax2,'off');


%% ── Figure 3: FPGA Priority Logic Block Diagram ──────────────────────────
f3 = figure('Name','(3) FPGA Priority Logic','Color',[0.08 0.09 0.11],...
    'Position',[150 50 1050 620]);
ax3 = axes(f3,'Color',[0.08 0.09 0.11],'Position',[0 0.04 1 0.92],...
    'XColor','none','YColor','none'); hold(ax3,'on');
ax3.XLim=[0 18]; ax3.YLim=[0 10];

% ── pin names on the left ─────────────────────────────────────────────────
pinY = [7.8 7.2 6.6 6.0 5.4];
pins = {'F1\_CALL [bit 0]','F2\_CALL [bit 1]','F3\_CALL [bit 2]','POS [1:0]','DIR [1:0]'};
pC   = {[0.25 0.85 0.42],[0.88 0.70 0.18],[0.96 0.32 0.32],[0.35 0.65 1],[0.74 0.55 1]};
for k=1:5
    text(ax3,0.1,pinY(k),pins{k},'Color',pC{k},'FontSize',8.5,...
        'FontName','Courier New','VerticalAlignment','middle');
    plot(ax3,[1.9 2.6],[pinY(k) pinY(k)],'-','Color',pC{k},'LineWidth',1.5);
end

% ── 5 pipeline blocks ─────────────────────────────────────────────────────
blk = { ...
  2.6, 5.0, 1.8, 4.0, {'INPUT','REGISTERS'},       [0.88 0.70 0.18] ; ...
  5.0, 4.8, 2.4, 4.4, {'PRIORITY','ENCODER','(combinational)'},  [0.35 0.65 1.00] ; ...
  8.0, 4.5, 2.4, 5.0, {'DIRECTION','FSM','(sequential)'},         [0.74 0.55 1.00] ; ...
 11.0, 4.3, 2.0, 5.4, {'H-BRIDGE','CONTROLLER'},   [0.86 0.43 0.17] ; ...
 13.6, 4.8, 1.8, 4.4, {'MOTOR','(3-phase','equiv)'},[0.25 0.85 0.42] ; ...
};

for k=1:size(blk,1)
    bx=blk{k,1}; by=blk{k,2}; bw=blk{k,3}; bh=blk{k,4};
    lb=blk{k,5}; bc=blk{k,6};
    rectangle(ax3,'Position',[bx by bw bh],'FaceColor',bc*0.15+[0.05 0.06 0.08]*0.85,...
        'EdgeColor',bc,'LineWidth',2.2,'Curvature',[0.06 0.10]);
    cy = by+bh/2;
    for li=1:numel(lb)
        text(ax3,bx+bw/2, cy+(li-(numel(lb)+1)/2)*0.58, lb{li},...
            'Color',bc,'FontSize',9,'FontWeight','bold','HorizontalAlignment','center');
    end
end

% ── arrows between blocks ─────────────────────────────────────────────────
busLC = {[0.88 0.70 0.18],[0.35 0.65 1],[0.74 0.55 1],[0.86 0.43 0.17]};
busLB = {'call[2:0]  pos[1:0]  dir[1:0]', 'target[1:0]  next\_dir', 'state[2:0]', 'IN3  IN2  IN1  IN0'};
for k=1:4
    bx1=blk{k,1}+blk{k,3}; by1=blk{k,2}+blk{k,4}/2;
    bx2=blk{k+1,1};           by2=blk{k+1,2}+blk{k+1,4}/2;
    plot(ax3,[bx1 bx2],[by1 by2],'-','Color',busLC{k},'LineWidth',2.2);
    arrowHead(ax3,bx1,by1,bx2,by2,busLC{k});
    text(ax3,(bx1+bx2)/2,(by1+by2)/2+0.35,busLB{k},'Color',busLC{k},...
        'FontSize',7,'HorizontalAlignment','center','FontName','Courier New');
end

% ── output pins on the right ──────────────────────────────────────────────
outY = [7.6 7.0 6.4];
outLabels = {'TARGET FLOOR [1:0]', 'DIRECTION  [up/dn]', 'OUTPUT     [2:0]'};
outC = {[0.35 0.65 1],[0.25 0.85 0.42],[0.74 0.55 1]};
for k=1:3
    plot(ax3,[15.4 16.0],[outY(k) outY(k)],'-','Color',outC{k},'LineWidth',1.5);
    text(ax3,16.1,outY(k),outLabels{k},'Color',outC{k},'FontSize',8.5,...
        'FontName','Courier New','VerticalAlignment','middle');
end

% ── priority rule legend ──────────────────────────────────────────────────
lx=0.1; stp=0.44;
lY0=4.0;
rules = { ...
'Priority Rules:', [0.50 0.55 0.60]; ...
'1.  Moving UP   -> serve next floor ABOVE first', [0.35 0.65 1]; ...
'2.  Moving DOWN -> serve next floor BELOW first', [0.74 0.55 1]; ...
'3.  IDLE        -> serve CLOSEST floor (down-preference on tie)', [0.88 0.70 0.18]; ...
'4.  F1 + F3 pressed (moving UP) -> serve F2 then F3', [0.86 0.43 0.17]; ...
'5.  F1 + F3 pressed (moving DOWN) -> serve F2 then F1',[0.86 0.43 0.17]; ...
};
for k=1:size(rules,1)
    text(ax3,lx,lY0-(k-1)*stp,rules{k,1},'Color',rules{k,2},'FontSize',8.5);
end

% ── encoding table ────────────────────────────────────────────────────────
tx=7.5; ty=4.0;
rows = {'OUTPUT encoding:', 'Floor 1 -> 001', 'Floor 2 -> 010', 'Floor 3 -> 100', ...
        'UP    dir  -> 1', 'DOWN  dir  -> 0'};
tC2  = {[0.50 0.55 0.60],[0.25 0.85 0.42],[0.88 0.70 0.18],[0.96 0.32 0.32],[0.35 0.65 1],[0.96 0.32 0.32]};
for k=1:numel(rows)
    text(ax3,tx,ty-(k-1)*stp,rows{k},'Color',tC2{k},'FontSize',8.5,'FontName','Courier New');
end

title(ax3,'FPGA Priority Logic  —  Block Diagram  (Elevator Arbitration)',...
    'Color',[0.35 0.65 1],'FontSize',14,'FontWeight','bold');
hold(ax3,'off');


%% ── helper functions ─────────────────────────────────────────────────────
function bezArrow(ax,x1,y1,x2,y2,noff,lbl)
    mx=(x1+x2)/2; my=(y1+y2)/2;
    dx=x2-x1; dy=y2-y1; ln=max(hypot(dx,dy),0.01);
    px=-dy/ln*noff; py=dx/ln*noff;
    cpx=mx+px; cpy=my+py;
    tt=linspace(0,1,80);
    bx=(1-tt).^2*x1+2*(1-tt).*tt*cpx+tt.^2*x2;
    by=(1-tt).^2*y1+2*(1-tt).*tt*cpy+tt.^2*y2;
    i1=find(tt>=0.18,1); i2=find(tt>=0.82,1);
    plot(ax,bx(i1:i2),by(i1:i2),'-','Color',[0.28 0.33 0.40],'LineWidth',1.6);
    if i2>2
        ang=atan2(by(i2)-by(i2-2),bx(i2)-bx(i2-2)); sz=0.20;
        patch(ax,[bx(i2) bx(i2)-sz*cos(ang-0.38) bx(i2)-sz*cos(ang+0.38)],...
                  [by(i2) by(i2)-sz*sin(ang-0.38) by(i2)-sz*sin(ang+0.38)],...
            [0.28 0.33 0.40],'EdgeColor','none');
    end
    text(ax,cpx+px*0.45,cpy+py*0.45,lbl,'Color',[0.55 0.60 0.65],'FontSize',7.5,...
        'HorizontalAlignment','center','BackgroundColor',[0.08 0.09 0.11],'Margin',1.5);
end

function hbFET2(ax,cx,cy,col,name,ptype,part)
    th2=linspace(0,2*pi,80);
    patch(ax,cx+0.7*cos(th2),cy+0.7*sin(th2),col*0.20+[0.06 0.07 0.08]*0.80,...
        'EdgeColor',col,'LineWidth',2);
    text(ax,cx,cy+0.20,name,'Color',col,'FontSize',10,'FontWeight','bold','HorizontalAlignment','center');
    text(ax,cx,cy-0.18,ptype,'Color',col,'FontSize',8,'HorizontalAlignment','center');
    text(ax,cx,cy-0.50,part,'Color',col*0.70,'FontSize',7,'HorizontalAlignment','center');
end

function arrowHead(ax,x1,y1,x2,y2,col)
    ang=atan2(y2-y1,x2-x1); sz=0.28;
    patch(ax,[x2 x2-sz*cos(ang-0.30) x2-sz*cos(ang+0.30)],...
              [y2 y2-sz*sin(ang-0.30) y2-sz*sin(ang+0.30)],col,'EdgeColor','none');
end

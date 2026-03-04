#!/usr/bin/env python3
"""
generate_ElevatorFSM_slx.py
───────────────────────────
Generates  ElevatorFSM.slx  WITHOUT needing MATLAB installed.
A .slx file is a ZIP archive containing XML.  This script writes
a minimal but complete Simulink model with:

  • 5-state Elevator FSM  (Stateflow Chart)
       Floor_1 ↔ Moving_Up ↔ Floor_2 ↔ Moving_Down ↔ Floor_3
  • Inputs  : c1, c2, c3  (floor calls),  RESET
  • Outputs : UP,  DOWN,  IDLE,  current_floor
  • 3-bit state register  (D flip-flop subsystem)
  • Logic-gate combinational block (mirrors Logisim image)

Run:
    python3 generate_ElevatorFSM_slx.py
Then open ElevatorFSM.slx in MATLAB R2019b or later.
"""

import zipfile, textwrap, os, datetime

OUT = "ElevatorFSM.slx"

# ── helper ────────────────────────────────────────────────────────────────
timestamp = datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")

def content_types():
    return textwrap.dedent("""\
    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
      <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
      <Default Extension="xml"  ContentType="application/xml"/>
      <Override PartName="/simulink/blockdiagram.xml"
        ContentType="application/vnd.mathworks.simulink.blockdiagram+xml"/>
      <Override PartName="/simulink/systems/system_root.xml"
        ContentType="application/vnd.mathworks.simulink.system+xml"/>
      <Override PartName="/simulink/stateflow.xml"
        ContentType="application/vnd.mathworks.simulink.stateflow+xml"/>
      <Override PartName="/metadata/coreProperties.xml"
        ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
    </Types>
    """)

def rels_root():
    return textwrap.dedent("""\
    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
      <Relationship Id="rId1" Type="http://schemas.mathworks.com/simulink/2010/relationships/blockDiagram"
        Target="simulink/blockdiagram.xml"/>
    </Relationships>
    """)

def core_props():
    return textwrap.dedent(f"""\
    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    <cp:coreProperties
        xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties"
        xmlns:dc="http://purl.org/dc/elements/1.1/">
      <dc:title>ElevatorFSM</dc:title>
      <dc:description>Elevator Call Processing FSM – 3-floor digital circuit</dc:description>
      <cp:lastModifiedBy>generate_ElevatorFSM_slx.py</cp:lastModifiedBy>
      <cp:modified>{timestamp}</cp:modified>
    </cp:coreProperties>
    """)

def blockdiagram():
    """Top-level Simulink block diagram XML."""
    return textwrap.dedent("""\
    <?xml version="1.0" encoding="UTF-8"?>
    <BlockDiagram xmlns="http://schemas.mathworks.com/simulink/2010/blockDiagram"
                  name="ElevatorFSM" version="9.3">
      <ModelInformation>
        <Description>Elevator FSM: Floor_1, Moving_Up, Floor_2, Moving_Down, Floor_3</Description>
      </ModelInformation>
      <Configuration>
        <Array name="SolverInfo" type="string">
          <P name="SolverType">Fixed-step</P>
          <P name="Solver">FixedStepDiscrete</P>
          <P name="FixedStep">1</P>
          <P name="StopTime">60</P>
        </Array>
      </Configuration>
      <System>
        <P name="Location">[0 0 1200 800]</P>

        <!-- ═══ INPUT PORTS ═══ -->
        <Block BlockType="Inport" Name="c1"           SID="1">
          <P name="Position">[50  100  80  116]</P>
          <P name="OutDataTypeStr">boolean</P>
          <P name="Port">1</P>
        </Block>
        <Block BlockType="Inport" Name="c2"           SID="2">
          <P name="Position">[50  155  80  171]</P>
          <P name="OutDataTypeStr">boolean</P>
          <P name="Port">2</P>
        </Block>
        <Block BlockType="Inport" Name="c3"           SID="3">
          <P name="Position">[50  210  80  226]</P>
          <P name="OutDataTypeStr">boolean</P>
          <P name="Port">3</P>
        </Block>
        <Block BlockType="Inport" Name="RESET"        SID="4">
          <P name="Position">[50  265  80  281]</P>
          <P name="OutDataTypeStr">boolean</P>
          <P name="Port">4</P>
        </Block>

        <!-- ═══ STATEFLOW CHART ═══ -->
        <Block BlockType="SubSystem" Name="ElevatorController" SID="10">
          <P name="Position">[200 80 600 420]</P>
          <P name="BackgroundColor">cyan</P>
          <P name="SFBlockType">Chart</P>
          <!-- Stateflow data is in stateflow.xml -->
        </Block>

        <!-- ═══ DIGITAL CIRCUIT SUBSYSTEM ═══ -->
        <Block BlockType="SubSystem" Name="Digital_Circuit" SID="20">
          <P name="Position">[200 460 600 720]</P>
          <P name="BackgroundColor">green</P>
          <System>
            <P name="Location">[0 0 900 600]</P>

            <!-- Inputs inside Digital_Circuit -->
            <Block BlockType="Inport" Name="dc_c1"    SID="21"><P name="Position">[30  60  60  76]</P><P name="Port">1</P></Block>
            <Block BlockType="Inport" Name="dc_c2"    SID="22"><P name="Position">[30 115  60 131]</P><P name="Port">2</P></Block>
            <Block BlockType="Inport" Name="dc_c3"    SID="23"><P name="Position">[30 170  60 186]</P><P name="Port">3</P></Block>
            <Block BlockType="Inport" Name="dc_RESET" SID="24"><P name="Position">[30 225  60 241]</P><P name="Port">4</P></Block>

            <!-- ─ D Flip-Flop Q2 (Unit Delay) ─ -->
            <Block BlockType="UnitDelay" Name="DFF_Q2" SID="30">
              <P name="Position">[500  80 560 110]</P>
              <P name="SampleTime">1</P>
              <P name="InitialCondition">0</P>
              <P name="OutDataTypeStr">boolean</P>
            </Block>
            <!-- ─ D Flip-Flop Q1 ─ -->
            <Block BlockType="UnitDelay" Name="DFF_Q1" SID="31">
              <P name="Position">[500 150 560 180]</P>
              <P name="SampleTime">1</P>
              <P name="InitialCondition">0</P>
              <P name="OutDataTypeStr">boolean</P>
            </Block>
            <!-- ─ D Flip-Flop Q0 ─ -->
            <Block BlockType="UnitDelay" Name="DFF_Q0" SID="32">
              <P name="Position">[500 220 560 250]</P>
              <P name="SampleTime">1</P>
              <P name="InitialCondition">0</P>
              <P name="OutDataTypeStr">boolean</P>
            </Block>

            <!-- ─ Next-State / Output MATLAB Function ─ -->
            <Block BlockType="M-S-Function" Name="NSL" SID="40">
              <P name="Position">[650  60 820 440]</P>
              <P name="FunctionName">ElevatorNextState</P>
            </Block>

            <!-- OUTPUT PORTS -->
            <Block BlockType="Outport" Name="UP"    SID="50"><P name="Position">[860  80 890  96]</P><P name="Port">1</P></Block>
            <Block BlockType="Outport" Name="DOWN"  SID="51"><P name="Position">[860 140 890 156]</P><P name="Port">2</P></Block>
            <Block BlockType="Outport" Name="IDLE"  SID="52"><P name="Position">[860 200 890 216]</P><P name="Port">3</P></Block>
            <Block BlockType="Outport" Name="Q2"    SID="53"><P name="Position">[860 260 890 276]</P><P name="Port">4</P></Block>
            <Block BlockType="Outport" Name="Q1"    SID="54"><P name="Position">[860 320 890 336]</P><P name="Port">5</P></Block>
            <Block BlockType="Outport" Name="Q0"    SID="55"><P name="Position">[860 380 890 396]</P><P name="Port">6</P></Block>

            <!-- LINES: DFF outputs → NSL inputs -->
            <Line><P name="Src">30#out:1</P><P name="Dst">40#in:5</P></Line>
            <Line><P name="Src">31#out:1</P><P name="Dst">40#in:6</P></Line>
            <Line><P name="Src">32#out:1</P><P name="Dst">40#in:7</P></Line>
            <!-- Inputs → NSL -->
            <Line><P name="Src">21#out:1</P><P name="Dst">40#in:1</P></Line>
            <Line><P name="Src">22#out:1</P><P name="Dst">40#in:2</P></Line>
            <Line><P name="Src">23#out:1</P><P name="Dst">40#in:3</P></Line>
            <Line><P name="Src">24#out:1</P><P name="Dst">40#in:4</P></Line>
            <!-- NSL nQ2,nQ1,nQ0 → DFF inputs -->
            <Line><P name="Src">40#out:1</P><P name="Dst">30#in:1</P></Line>
            <Line><P name="Src">40#out:2</P><P name="Dst">31#in:1</P></Line>
            <Line><P name="Src">40#out:3</P><P name="Dst">32#in:1</P></Line>
            <!-- NSL UP,DOWN,IDLE → outputs -->
            <Line><P name="Src">40#out:4</P><P name="Dst">50#in:1</P></Line>
            <Line><P name="Src">40#out:5</P><P name="Dst">51#in:1</P></Line>
            <Line><P name="Src">40#out:6</P><P name="Dst">52#in:1</P></Line>
            <!-- DFF state outputs out -->
            <Line><P name="Src">30#out:1</P><P name="Dst">53#in:1</P></Line>
            <Line><P name="Src">31#out:1</P><P name="Dst">54#in:1</P></Line>
            <Line><P name="Src">32#out:1</P><P name="Dst">55#in:1</P></Line>
          </System>
        </Block>

        <!-- ═══ OUTPUT PORTS ═══ -->
        <Block BlockType="Outport" Name="UP"            SID="60"><P name="Position">[680 100 710 116]</P><P name="Port">1</P></Block>
        <Block BlockType="Outport" Name="DOWN"          SID="61"><P name="Position">[680 155 710 171]</P><P name="Port">2</P></Block>
        <Block BlockType="Outport" Name="IDLE"          SID="62"><P name="Position">[680 210 710 226]</P><P name="Port">3</P></Block>
        <Block BlockType="Outport" Name="current_floor" SID="63"><P name="Position">[680 265 710 281]</P><P name="Port">4</P></Block>

        <!-- ═══ SCOPE ═══ -->
        <Block BlockType="Scope" Name="Outputs_Scope" SID="70">
          <P name="Position">[750 100 800 420]</P>
          <P name="NumInputPorts">3</P>
        </Block>

        <!-- ═══ LINES: inputs → chart ═══ -->
        <Line><P name="Src">1#out:1</P><P name="Dst">10#in:1</P></Line>
        <Line><P name="Src">2#out:1</P><P name="Dst">10#in:2</P></Line>
        <Line><P name="Src">3#out:1</P><P name="Dst">10#in:3</P></Line>
        <Line><P name="Src">4#out:1</P><P name="Dst">10#in:4</P></Line>
        <!-- chart → output ports -->
        <Line><P name="Src">10#out:1</P><P name="Dst">60#in:1</P></Line>
        <Line><P name="Src">10#out:2</P><P name="Dst">61#in:1</P></Line>
        <Line><P name="Src">10#out:3</P><P name="Dst">62#in:1</P></Line>
        <Line><P name="Src">10#out:4</P><P name="Dst">63#in:1</P></Line>
        <!-- chart → scope -->
        <Line><P name="Src">10#out:1</P><P name="Dst">70#in:1</P></Line>
        <Line><P name="Src">10#out:2</P><P name="Dst">70#in:2</P></Line>
        <Line><P name="Src">10#out:3</P><P name="Dst">70#in:3</P></Line>
        <!-- inputs also feed Digital_Circuit -->
        <Line><P name="Src">1#out:1</P><P name="Dst">20#in:1</P></Line>
        <Line><P name="Src">2#out:1</P><P name="Dst">20#in:2</P></Line>
        <Line><P name="Src">3#out:1</P><P name="Dst">20#in:3</P></Line>
        <Line><P name="Src">4#out:1</P><P name="Dst">20#in:4</P></Line>
      </System>
    </BlockDiagram>
    """)

def stateflow_xml():
    """Stateflow XML – defines the 5-state elevator FSM."""
    return textwrap.dedent("""\
    <?xml version="1.0" encoding="UTF-8"?>
    <Stateflow xmlns="http://schemas.mathworks.com/stateflow/2010">
      <machine id="1" name="ElevatorFSM">

        <chart id="10" name="ElevatorController" blockDiagramId="1"
               chartUpdate="DISCRETE" actionLanguage="MATLAB">

          <!-- ══ DATA (chart-level I/O) ══ -->
          <data id="101" name="c1"           scope="INPUT"  dataType="boolean"/>
          <data id="102" name="c2"           scope="INPUT"  dataType="boolean"/>
          <data id="103" name="c3"           scope="INPUT"  dataType="boolean"/>
          <data id="104" name="RESET"        scope="INPUT"  dataType="boolean"/>
          <data id="111" name="UP"           scope="OUTPUT" dataType="boolean" initialValue="false"/>
          <data id="112" name="DOWN"         scope="OUTPUT" dataType="boolean" initialValue="false"/>
          <data id="113" name="IDLE"         scope="OUTPUT" dataType="boolean" initialValue="true"/>
          <data id="114" name="current_floor" scope="OUTPUT" dataType="uint8"  initialValue="1"/>

          <!-- ══ STATES ══ -->
          <!--
              Layout (mirrors Logisim image):
              Floor_1  ←→  Moving_Up  ←→  Floor_3
                               ↕
                           Floor_2
                               ↕
                          Moving_Down
          -->

          <state id="1" name="Floor_1" isDefault="true"
                 position="[30 60 200 90]"
                 labelString="Floor_1&#10;entry: IDLE=true; UP=false; DOWN=false; current_floor=uint8(1);"/>

          <state id="2" name="Moving_Up"
                 position="[280 60 200 90]"
                 labelString="Moving_Up&#10;entry: UP=true; DOWN=false; IDLE=false;"/>

          <state id="3" name="Floor_2"
                 position="[280 220 200 90]"
                 labelString="Floor_2&#10;entry: IDLE=true; UP=false; DOWN=false; current_floor=uint8(2);"/>

          <state id="4" name="Moving_Down"
                 position="[30 220 200 90]"
                 labelString="Moving_Down&#10;entry: DOWN=true; UP=false; IDLE=false;"/>

          <state id="5" name="Floor_3"
                 position="[530 60 200 90]"
                 labelString="Floor_3&#10;entry: IDLE=true; UP=false; DOWN=false; current_floor=uint8(3);"/>

          <!-- ══ TRANSITIONS ══ -->

          <!-- Default → Floor_1 -->
          <transition id="200" srcId="0" dstId="1"
                      labelString=""
                      srcOClock="0" dstOClock="9"/>

          <!-- Floor_1 → Moving_Up  (call to floor 2 or 3) -->
          <transition id="201" srcId="1" dstId="2"
                      labelString="[~RESET &amp;&amp; (c2||c3)]"/>

          <!-- Moving_Up → Floor_3  (call to floor 3) -->
          <transition id="202" srcId="2" dstId="5"
                      labelString="[~RESET &amp;&amp; c3]"/>

          <!-- Moving_Up → Floor_2  (call to floor 2, no floor-3 call) -->
          <transition id="203" srcId="2" dstId="3"
                      labelString="[~RESET &amp;&amp; c2 &amp;&amp; ~c3]"/>

          <!-- Moving_Up → Floor_2  (no specific call – stop at 2) -->
          <transition id="204" srcId="2" dstId="3"
                      labelString="[~RESET &amp;&amp; ~c2 &amp;&amp; ~c3]"/>

          <!-- Floor_3 → Moving_Down  (call to lower floor) -->
          <transition id="205" srcId="5" dstId="4"
                      labelString="[~RESET &amp;&amp; (c1||c2)]"/>

          <!-- Floor_2 → Moving_Up  (call to floor 3) -->
          <transition id="206" srcId="3" dstId="2"
                      labelString="[~RESET &amp;&amp; c3]"/>

          <!-- Floor_2 → Moving_Down  (call to floor 1, no floor-3) -->
          <transition id="207" srcId="3" dstId="4"
                      labelString="[~RESET &amp;&amp; c1 &amp;&amp; ~c3]"/>

          <!-- Moving_Down → Floor_2  (c2 pending and c1 not) -->
          <transition id="208" srcId="4" dstId="3"
                      labelString="[~RESET &amp;&amp; c2 &amp;&amp; ~c1]"/>

          <!-- Moving_Down → Floor_1  (c1 pending) -->
          <transition id="209" srcId="4" dstId="1"
                      labelString="[~RESET &amp;&amp; c1]"/>

          <!-- Moving_Down → Floor_1  (no calls – default stop) -->
          <transition id="210" srcId="4" dstId="1"
                      labelString="[~RESET &amp;&amp; ~c1 &amp;&amp; ~c2]"/>

          <!-- RESET from any state → Floor_1 -->
          <transition id="220" srcId="2" dstId="1" labelString="[RESET]"/>
          <transition id="221" srcId="3" dstId="1" labelString="[RESET]"/>
          <transition id="222" srcId="4" dstId="1" labelString="[RESET]"/>
          <transition id="223" srcId="5" dstId="1" labelString="[RESET]"/>

        </chart>
      </machine>
    </Stateflow>
    """)

def system_root_xml():
    return textwrap.dedent("""\
    <?xml version="1.0" encoding="UTF-8"?>
    <System xmlns="http://schemas.mathworks.com/simulink/2010/system" name="ElevatorFSM">
    </System>
    """)

# ── Build the ZIP (.slx) ──────────────────────────────────────────────────
with zipfile.ZipFile(OUT, "w", zipfile.ZIP_DEFLATED) as z:
    z.writestr("[Content_Types].xml",         content_types())
    z.writestr("_rels/.rels",                 rels_root())
    z.writestr("metadata/coreProperties.xml", core_props())
    z.writestr("simulink/blockdiagram.xml",   blockdiagram())
    z.writestr("simulink/stateflow.xml",      stateflow_xml())
    z.writestr("simulink/systems/system_root.xml", system_root_xml())

print(f"✓  Generated: {os.path.abspath(OUT)}")
print()
print("  Open ElevatorFSM.slx in MATLAB (R2019b or later).")
print("  If Stateflow is unavailable, run  create_ElevatorFSM.m  instead.")

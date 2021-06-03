import QtQuick 2.11
import QtQuick.Controls 2.4
import QtQuick.Controls.Material 2.4
import QtQuick.Layouts 1.11

import fkin.Dds 1.0

/// Window with elements for controlling simulators and external processes
RowLayout {
  x: 30; ///< Placement x
  y: 30; ///< Placement y
  width: 1920 - 2*x; ///< Width of element
  spacing: 30; // Spacing
  ///

  /// Control elements
  GridLayout {
    id: controls;
    x: 0;
    y: 0;
    columns: 4;
    //width: 700
    //width: parent.width > 600 ? 600 : parent.width
    columnSpacing: 5;
    rowSpacing: 5;
    Layout.minimumWidth: 700;
    Layout.maximumWidth: 700;
    Layout.alignment: Qt.AlignTop;

    property int statusWidth: 130;

    // Need to find out how to dynamically add items and let it still follow GridLayout,
    // Currently each row is does not respect alignment of grid cells
    /*
      FkinServiceCtrl
      {
      id: testimator;
      Layout.columnSpan: 3;
      Layout.fillWidth: true;

      // theSwitch.text: "My Test which is very long";
      // theSwitch.onToggled: { console.log(" OH yeah"); }
      // theStatus: "Working";
      // theMsg: "Nothing";
      }*/

    function stateColor(input)
    {
      if(input == FKIN.IDLE)
        return Material.color(Material.Indigo, Material.Shade400);
      else if(input == FKIN.INITIALIZING)
        return Material.color(Material.Orange);
      else if(input == FKIN.RUNNING)
        return Material.color(Material.Green);
      else if(input == FKIN.FAILURE)
        return Material.color(Material.Red);
      else if(input == FKIN.DEAD)
        return Material.color(Material.Red);
      else if(input == FKIN.UNKNOWN)
        return Material.color(Material.Grey);
      else
        return Material.color(Material.Grey);
    }

    Label {
      Layout.alignment: Qt.AlignHCenter;
      text: qsTr("Service controls");
      font.bold: true;
      Layout.columnSpan: 4;
      //Layout.fillWidth: true;
    }

    Rectangle { color: "transparent"; Layout.fillWidth: true; height: 10; Layout.columnSpan: 4; }

    Label { text: qsTr("Decision support"); font.bold: true; }

    RowLayout {
      //Layout.minimumWidth: 500;
      Layout.columnSpan: 3;
      Layout.alignment: Qt.AlignRight;

      /// Start decision support
      Button {
        id: dsStart;
        text: qsTr("Start");
        Layout.alignment: Qt.AlignRight;

        onClicked:
        {
          switch_StateEstimator.checked = true;
          switch_StateEstimator.toggled();
          switch_PathPlanner.checked = true;
          switch_PathPlanner.toggled();
        }
      }

      /// Stop decision support
      Button {
        id: dsStop;
        text: qsTr("Stop");
        Layout.alignment: Qt.AlignLeft;

        onClicked:
        {
          switch_StateEstimator.checked = false;
          switch_StateEstimator.toggled();
          switch_PathPlanner.checked = false;
          switch_PathPlanner.toggled();
        }
      }
    }

    /// Toggle state estimator
    Switch {
      id: switch_StateEstimator;
      text: qsTr("State estimator");
      onToggled:
      {
        if(checked)
          ddsCmdEstimator.command = FKIN.START_PROCESS;
        else
        {
          ddsCmdEstimator.command = FKIN.STOP_PROCESS;
          //ddsEstimator.clearBuffers();
        }
      }

    }
    /// Display status of estimator process
    Pane {
      id: status_StateEstimator;
      Layout.preferredWidth: controls.statusWidth;
      background: Rectangle {
        color: 'transparent';
        border.color: controls.stateColor(ddsEstimatorState.state);
        radius: 2;
      }

      Label {
        horizontalAlignment: Text.AlignHCenter;
        width: parent.width;
        text: ddsEstimatorState.stateName;

        onTextChanged:
        {
          Material.foreground = controls.stateColor(ddsEstimatorState.state);
          if(!switch_StateEstimator.checked && ddsEstimatorState.state == FKIN.RUNNING)
            switch_StateEstimator.checked = true;
        }
      }
    }

    Item { /*width: 30*/ Layout.fillWidth: true }

    /// Display message regarding estimator process
    Label {
      id: msg_StateEstimator;
      text: ddsCmdEstimator.responseMessage;
      Layout.alignment: Qt.AlignRight;
    }

    /// Toggle path planner
    Switch {
      id: switch_PathPlanner;
      text: qsTr("Path planner");
      onToggled:
      {
        if(checked)
          ddsCmdPlanner.command = FKIN.START_PROCESS;
        else
        {
          ddsCmdPlanner.command = FKIN.STOP_PROCESS;
          //ddsPlanner.clearBuffers();
        }
      }

    }

    /// Display status of path planner process
    Pane {
      id: status_PathPlanner;
      Layout.preferredWidth: controls.statusWidth;
      background: Rectangle {
        color: 'transparent';
        border.color: controls.stateColor(ddsPlannerState.state);
        radius: 2;
      }
      Label {
        Layout.alignment: Text.AlignHCenter;
        width: parent.width;
        text: ddsPlannerState.stateName;

        onTextChanged:
        {
          Material.foreground = controls.stateColor(ddsPlannerState.state);
          if(!switch_PathPlanner.checked && ddsPlannerState.state == FKIN.RUNNING)
            switch_PathPlanner.checked = true;
        }
      }
    }

    Item { /*width: 30*/ Layout.fillWidth: true; }
    //Item { width: 30/*Layout.fillWidth: true*/ }

    /// Display message regarding path planner process
    Label {
      //width: 400;
      id: msg_PathPlanner;
      text: ddsCmdPlanner.responseMessage;
      Layout.alignment: Qt.AlignRight;
    }

    Rectangle { color: "transparent"; Layout.fillWidth: true; height: 10; Layout.columnSpan: 4; }

    Label { text: qsTr("Simulators"); font.bold: true; }

    RowLayout {
      Layout.columnSpan: 3;
      Layout.alignment: Qt.AlignRight;

      /// Start all simulators.
      Button {
        id: simStart;
        text: qsTr("Start");
        Layout.alignment: Qt.AlignRight;

        onClicked:
        {
          switch_FishSchool.checked = true;
          switch_FishSchool.toggled();
          switch_Vessel.checked = true;
          switch_Vessel.toggled();
          switch_Leadline.checked = true;
          switch_Leadline.toggled();
        }
      }

      /// Stop all simulators.
      Button {
        id: simStop;
        text: qsTr("Stop");
        Layout.alignment: Qt.AlignLeft;

        onClicked:
        {
          switch_FishSchool.checked = false;
          switch_FishSchool.toggled();
          switch_Vessel.checked = false;
          switch_Vessel.toggled();
          switch_Leadline.checked = false;
          switch_Leadline.toggled();
        }
      }
    }

    /// toggle fish school simulator.
    Switch {
      id: switch_FishSchool;
      text: qsTr("Fish School");

      onToggled:
      {
        if(checked)
          ddsCmdFishSchool.command = FKIN.START_PROCESS;
        else
        {
          ddsCmdFishSchool.command = FKIN.STOP_PROCESS;
          ddsFish.clearBuffers();
        }
      }

    }

    /// Display status of fish school simulator.
    Pane {
      id: status_FishSchool;
      Layout.preferredWidth: controls.statusWidth;
      background: Rectangle {
        color: 'transparent';
        border.color: controls.stateColor(ddsFishSchoolState.state);
        radius: 2;
      }
      Label {
        Layout.alignment: Text.AlignHCenter;
        width: parent.width;
        text: ddsFishSchoolState.stateName;

        onTextChanged:
        {
          Material.foreground = controls.stateColor(ddsFishSchoolState.state);
          if(!switch_FishSchool.checked && ddsFishSchoolState.state == FKIN.RUNNING)
            switch_FishSchool.checked = true;
        }
      }
    }

    Item { /*width: 30*/ Layout.fillWidth: true }
    //Item { width: 30/*Layout.fillWidth: true*/ }

    /// Display message regarding fish school simulator.
    Label {
      id: msg_FishSchool;
      text: ddsCmdFishSchool.responseMessage;
      Layout.alignment: Qt.AlignRight;
    }

    /// Toggle vessel simulator.
    Switch {
      id: switch_Vessel;
      text: qsTr("Vessel");

      onToggled:
      {
        if(checked)
          ddsCmdVessel.command = FKIN.START_PROCESS;
        else
        {
          ddsCmdVessel.command = FKIN.STOP_PROCESS;
          ddsVessel.clearBuffers();
        }
      }

    }

    /// Display status of vessel simulator.
    Pane {
      id: status_Vessel;
      Layout.preferredWidth: controls.statusWidth;
      background: Rectangle {
        color: 'transparent';
        border.color: controls.stateColor(ddsVesselState.state);
        radius: 2;
      }
      Label {
        Layout.alignment: Text.AlignHCenter;
        width: parent.width;
        text: ddsVesselState.stateName;

        onTextChanged:
        {
          Material.foreground = controls.stateColor(ddsVesselState.state);
          if(!switch_Vessel.checked && ddsVesselState.state == FKIN.RUNNING)
            switch_Vessel.checked = true;
        }
      }
    }
    Item { /*width: 30*/ Layout.fillWidth: true }
    //Item { width: 30/*Layout.fillWidth: true*/ }

    /// Display message regarding vessel simulator
    Label {
      id: msg_Vessel;
      text: ddsCmdVessel.responseMessage;
      Layout.alignment: Qt.AlignRight;
    }

    /// Toggle leadline simulator.
    Switch {
      id: switch_Leadline;
      text: qsTr("Leadline");
      onToggled:
      {
        if(checked)
          ddsCmdLeadline.command = FKIN.START_PROCESS;
        else
        {
          ddsCmdLeadline.command = FKIN.STOP_PROCESS;
          //ddsLeadline.clearBuffers();
        }
      }

    }

    /// Display status of leadline simulator.
    Pane {
      id: status_Leadline;
      Layout.preferredWidth: controls.statusWidth;
      background: Rectangle {
        color: 'transparent';
        border.color: controls.stateColor(ddsLeadlineState.state);
        radius: 2;
      }
      Label {
        Layout.alignment: Text.AlignHCenter;
        width: parent.width;
        text: ddsLeadlineState.stateName;

        onTextChanged:
        {
          Material.foreground = controls.stateColor(ddsLeadlineState.state);
          if(!switch_Leadline.checked && ddsLeadlineState.state == FKIN.RUNNING)
            switch_Leadline.checked = true;
        }
      }
    }
    Item { /*width: 30*/ Layout.fillWidth: true }
    //Item { width: 30/*Layout.fillWidth: true*/ }

    /// Display message regarding leadline simulator.
    Label {
      id: msg_Leadline;
      text: ddsCmdLeadline.responseMessage;
      Layout.alignment: Qt.AlignRight;
    }

    Rectangle { color: "transparent"; Layout.fillWidth: true; height: 10; Layout.columnSpan: 4; }

  }

  Item{ Layout.fillWidth: true; }

  GridLayout {
    //Layout.columnSpan: 4
    columns: 4;
    width: 700;
    //width: parent.width > 600 ? 600 : parent.width;
    columnSpacing: 5;
    rowSpacing: 5;
    Layout.alignment: Qt.AlignTop;

    Label {
      text: qsTr("Simulator control signals");
      font.bold: true;
      Layout.columnSpan: 4;
      Layout.alignment: Qt.AlignHCenter;
    }
    Label { text: qsTr("Vessel speed"); }
    Item { width: 30; /*Layout.fillWidth: true; */}
    Slider {
      from: 0;
      value: 0;
      to: 4;
      stepSize: 0.1;
      snapMode: Slider.SnapOnRelease;
      onValueChanged: { ddsVesselCtrl.value.x = value; }
    }
    Label {
      Layout.preferredWidth: 150;
      text: Number(ddsVesselCtrl.value.x).toLocaleString(Qt.locale(),'f',1) + " m/s";
    }



    Label { text: qsTr("Vessel rate of turn"); }
    Item { width: 30; /*Layout.fillWidth: true; */}
    Slider {
      from: -20;
      value: 0;
      to: 20;
      stepSize: 0.05;
      snapMode: Slider.SnapOnRelease;
      onValueChanged: { ddsVesselCtrl.value.z = value*Math.PI/180; }
    }
    Label {
      Layout.preferredWidth: 150;
      Layout.alignment: Qt.AlignRight;
      text: Number(180*ddsVesselCtrl.value.z/Math.PI).toLocaleString(Qt.locale(),'f',2) + " deg/s";
    }

    Rectangle { color: "transparent"; Layout.fillWidth: true; height: 10; Layout.columnSpan: 4; }

    Label { text: qsTr("Fish speed"); }
    Item { width: 30; /*Layout.fillWidth: true; */}
    Slider {
      from: 0;
      value: 0;
      to: 4;
      stepSize: 0.1;
      snapMode: Slider.SnapOnRelease;
      onValueChanged: { ddsFishCtrl.value.x = value; }
    }
    Label {
      Layout.preferredWidth: 150;
      text: Number(ddsFishCtrl.value.x).toLocaleString(Qt.locale(),'f',1) + " m/s";
    }

    Label { text: qsTr("Fish rate of turn"); }
    Item { width: 30; /*Layout.fillWidth: true; */}
    Slider {
      from: -40;
      value: 0;
      to: 40;
      stepSize: 0.05;
      snapMode: Slider.SnapOnRelease;
      onValueChanged: { ddsFishCtrl.value.z = value*Math.PI/180; }
    }
    Label {
      Layout.preferredWidth: 150;
      text: Number(180*ddsFishCtrl.value.z/Math.PI).toLocaleString(Qt.locale(),'f',2) + " deg/s";
    }

    //Label { text: qsTr("Fish rate of dive") }
    Label { text: qsTr("Fish target depth"); }
    Item { width: 30; /*Layout.fillWidth: true; */}

    Slider {
      from: 0;
      value: 0;
      to: 200;
      stepSize: 1;
      snapMode: Slider.SnapOnRelease;
      onValueChanged: { ddsFishCtrl.value.y = value; }
    }
    Label {
      Layout.preferredWidth: 150;
      text: Number(ddsFishCtrl.value.y).toLocaleString(Qt.locale(),'f',2) + " m";
    }

    Rectangle { color: "transparent"; Layout.fillWidth: true; height: 10; Layout.columnSpan: 4; }

    Label { text: qsTr("Current"); }
    Item { width: 30; /*Layout.fillWidth: true; */}
    Slider {
      from: 0;
      value: 0;
      to: 1;
      stepSize: 0.1;
      snapMode: Slider.SnapOnRelease;
      onValueChanged: { ddsCurrentCtrl.value = value; }
    }
    Label {
      Layout.preferredWidth: 150;
      text: Number(ddsCurrentCtrl.value).toLocaleString(Qt.locale(),'f',1) + " m/s";
    }

    Rectangle { color: "transparent"; Layout.fillWidth: true; height: 10; Layout.columnSpan: 4; }


    Label {
      text: qsTr("Simulator initial conditions");
      font.bold: true;
      Layout.columnSpan: 4;
      Layout.alignment: Qt.AlignHCenter;
    }
    Label { text: qsTr("Vessel North"); }
    Item { width: 30; /*Layout.fillWidth: true; */}
    Slider {
      from: -200;
      value: 0;
      to: 200;
      stepSize: 1;
      snapMode: Slider.SnapOnRelease;
      onValueChanged: { ddsVesselInit.value.x = value; }
    }
    Label {
      Layout.preferredWidth: 150;
      text: Number(ddsVesselInit.value.x).toLocaleString(Qt.locale(),'f',2) + " m";
    }

    Label { text: qsTr("Vessel Eash"); }
    Item { width: 30; /*Layout.fillWidth: true; */}
    Slider {
      from: -200;
      value: 0;
      to: 200;
      stepSize: 1;
      snapMode: Slider.SnapOnRelease;
      onValueChanged: { ddsVesselInit.value.y = value; }
    }
    Label {
      Layout.preferredWidth: 150;
      text: Number(ddsVesselInit.value.y).toLocaleString(Qt.locale(),'f',2) + " m";
    }

    Label { text: qsTr("Vessel Course"); }
    Item { width: 30; /*Layout.fillWidth: true; */}
    Slider {
      from: -180;
      value: 0;
      to: 180;
      stepSize: 1;
      snapMode: Slider.SnapOnRelease;
      onValueChanged: { ddsVesselInit.value.z = value*Math.PI/180; }
    }
    Label {
      Layout.preferredWidth: 150;
      text: Number(180*ddsVesselInit.value.z/Math.PI).toLocaleString(Qt.locale(),'f',2) + " degrees";
    }

    Rectangle { color: "transparent"; Layout.fillWidth: true; height: 10; Layout.columnSpan: 4; }


    Label { text: qsTr("Fish North"); }
    Item { width: 30; /*Layout.fillWidth: true; */}
    Slider {
      from: -200;
      value: 0;
      to: 200;
      stepSize: 1;
      snapMode: Slider.SnapOnRelease;
      onValueChanged: { ddsFishInitPos.value.x = value; }
    }
    Label {
      Layout.preferredWidth: 150;
      text: Number(ddsFishInitPos.value.x).toLocaleString(Qt.locale(),'f',2) + " m";
    }

    Label { text: qsTr("Fish Eash"); }
    Item { width: 30; /*Layout.fillWidth: true; */}
    Slider {
      from: -200;
      value: 0;
      to: 200;
      stepSize: 1;
      snapMode: Slider.SnapOnRelease;
      onValueChanged: { ddsFishInitPos.value.y = value; }
    }
    Label {
      Layout.preferredWidth: 150;
      text: Number(ddsFishInitPos.value.y).toLocaleString(Qt.locale(),'f',2) + " m";
    }

    Label { text: qsTr("Fish Depth"); }
    Item { width: 30; /*Layout.fillWidth: true; */}
    Slider {
      from: 0;
      value: 50;
      to: 200;
      stepSize: 1;
      snapMode: Slider.SnapOnRelease;
      onValueChanged: { ddsFishInitPos.value.z = value; }
    }
    Label {
      Layout.preferredWidth: 150;
      text: Number(ddsFishInitPos.value.z).toLocaleString(Qt.locale(),'f',2) + " m";
    }

    Label { text: qsTr("Fish Course"); }
    Item { width: 30; /*Layout.fillWidth: true; */}
    Slider {
      from: -180;
      value: 0;
      to: 180;
      stepSize: 1;
      snapMode: Slider.SnapOnRelease;
      onValueChanged: { ddsFishInitEuler.value.z = value*Math.PI/180; }
    }

    Label {
      Layout.preferredWidth: 150;
      text: Number(180*ddsFishInitEuler.value.z/Math.PI).toLocaleString(Qt.locale(),'f',2) + " degrees";
    }

  }
}

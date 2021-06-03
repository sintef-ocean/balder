import QtQuick 2.11
import QtQuick.Controls 2.4
import QtQuick.Controls.Material 2.4
import QtQuick.Layouts 1.11

import fkin.Dds 1.0

/// A remote program control with toggle, program name, and status
GridLayout {
  id: root;
  columns: 2;
  /// Width of program status cell
  property int statusWidth: 130;
  /// Width of program name cell
  property int programWidth: 250;
  /// Reference to command status subscriber (DDS)
  property alias sub: ddsCommandSub;
  /// Reference to command publisher (DDS)
  property alias pub: ddsCommandPub;
  /// Reference to DDS signal to indicate state of program
  property alias state: ddsProgramState;
  /// Program name
  property alias program_name: branch.programName;
  DdsCommandSubscriber { id: ddsCommandSub; }
  DdsCommandPublisher { id: ddsCommandPub; }
  DdsStateNotification  { id: ddsProgramState; }

  Connections {
    target: ddsCommandPub;
    onCommandChanged: { commandResponse.visible = true; responseMsgTimer.running = true; }
  }

  /*
  Connections {
    target: ddsCommandSub;
    onCommandNameChanged: { console.log("Command received: " + commandName); }
  }*/

  /*
  Connections {
    target: ddsProgramState;
    onStateNameChanged: { console.log("Program is in state: " + stateName); }
  }
  */

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


  Label { /*width: 30*/ Layout.fillWidth: false; }
  RowLayout {

    id: branch;
    property alias programName: programToggle.text;

    /// Toggle state process
    Switch {
      id: programToggle;
      text: qsTr("Program");
      Layout.preferredWidth: root.programWidth;
      onToggled:
      {
        if(checked)
          ddsCommandPub.command = FKIN.START_PROCESS;
        else
          ddsCommandPub.command = FKIN.STOP_PROCESS;
      }
    }
    /// Display status of process
    Pane {
      id: statusProgram;
      Layout.preferredWidth: root.statusWidth;
      background: Rectangle {
        color: 'transparent';
        border.color: root.stateColor(ddsProgramState.state);
        radius: 2;
      }

      Label {
        horizontalAlignment: Text.AlignHCenter;
        width: parent.width;
        text: ddsProgramState.stateName;

        onTextChanged:
        {
          Material.foreground = root.stateColor(ddsProgramState.state);
          if(!programToggle.checked && ddsProgramState.state == FKIN.RUNNING)
            programToggle.checked = true;
          if(programToggle.checked && ddsProgramState.state == FKIN.DEAD)
            programToggle.checked = false;
          if(programToggle.checked && ddsProgramState.state == FKIN.IDLE)
            programToggle.checked = false;
        }
      }
    }
    /// Display message regarding process
    Label {
      id: commandResponse;
      text: ddsCommandPub.responseMessage;
      Layout.alignment: Qt.AlignRight;
      Layout.leftMargin: 20;

    }

    // Hide response message
    Timer {
      id: responseMsgTimer;
      interval: 8000;
      running: false;
      repeat: false;
      onTriggered:
      {
        commandResponse.visible = false;
      }
    }
  }
}

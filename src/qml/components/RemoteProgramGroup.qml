import QtQuick 2.11
import QtQuick.Controls 2.4
import QtQuick.Controls.Material 2.4
import QtQuick.Layouts 1.11

import fkin.Dds 1.0

RowLayout {
  id: root;
  /// List RemoteProgramCommands to control together
  property var programs : [];

  Button {
    id: sendStart;
    text: qsTr("Start");
    Layout.fillWidth: false;
    onClicked: {
      for(let i = 0; i < root.programs.length; ++i)
        root.programs[i].pub.command = FKIN.START_PROCESS;
    }
  }
  Button {
    id: sendStop;
    text: qsTr("Stop");
    Layout.fillWidth: false;
    onClicked: {
      for(let i = 0; i < root.programs.length; ++i)
        root.programs[i].pub.command = FKIN.STOP_PROCESS;
    }
  }
  Button {
    id: sendTerminate;
    text: qsTr("Terminate");
    Layout.fillWidth: false;
    onClicked: {
      for(let i = 0; i < root.programs.length; ++i)
        root.programs[i].pub.command = FKIN.TERMINATE_PROCESS;
    }
  }
}

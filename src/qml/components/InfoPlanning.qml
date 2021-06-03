import QtQuick 2.11
import QtQuick.Controls 2.4
import QtQuick.Controls.Material 2.4
import QtQuick.Layouts 1.11

import fkin.Dds 1.0

/// Visual component to show status on algorithm
RowLayout {
  id: root;

  FkinStyle { id: style; }
  /// Icon font (default: IcoFont)
  property font iconFont: Qt.font({
    family: "IcoFont", pointSize: style.numberFont.pointSize + 10, weight: Font.Medium });
  /// Icon font character to display
  property alias entity: icon_.text;
  /// ToolTip description for component
  property alias title: icon_.toolTipText;
  /// ToolTip description for clock icon
  property alias description: clockIcon.toolTipText;
  /// Color for OK status
  property color statusOK: Material.color(Material.Green);
  /// Color for FAIL status
  property color statusFAIL: Material.color(Material.Red);
  /// Color for SLOW (late) status
  property color statusSLOW: Material.color(Material.Orange);
  /// String to show in running state
  property string statusRunning: qsTr("RUNNING");
  /// String to show in not running state
  property string statusNotRunning: qsTr("STOPPED");
  /// Is the algorithm running
  property bool running: false;
  /// Expected period
  property int expected: 10000; // milliseconds
  /// Count timer downward
  property bool down: false;
  /// Value when timer reset
  property int count0: 0;
  /// Resets timer
  signal reseted;

  onReseted:
  {
    chrono_.reset();
  }

  Label {
    id: icon_;
    text: "\uef50";
    font: root.iconFont;
    color: status_.statusColor;
    property string toolTipText: qsTr("Info");
    ToolTip.text: toolTipText;
    ToolTip.visible: toolTipText ? ma.containsMouse : false;
    MouseArea {
      id: ma;
      anchors.fill: parent;
      hoverEnabled: true;
    }
  }

  Pane {
    id: status_;
    Layout.rightMargin: 40;
    Layout.leftMargin: 10;
    property color statusColor: root.running ? root.statusOK : root.statusFAIL;
    background: Rectangle {
      color: 'transparent';
      border.color: status_.statusColor;
      radius: 2;
    }

    Label {
      horizontalAlignment: Text.AlignHCenter;
      width: parent.width;
      text: root.running ? root.statusRunning : root.statusNotRunning;
      color: status_.statusColor;
    }
  }

  Label {
    id: clockIcon;
    text: "\uedcd";
    font: root.iconFont;
    color: counter_.statusColor;
    property string toolTipText: qsTr("Info");
    ToolTip.text: toolTipText;
    ToolTip.visible: toolTipText ? ma_.containsMouse : false;
    MouseArea {
      id: ma_;
      anchors.fill: parent;
      hoverEnabled: true;
    }
  }


  Pane {
    id: counter_;
    Layout.leftMargin: 10;
    property int count;
    property color statusColor: root.running ?
      (counter_.count <= root.expected ? root.statusOK : root.statusSLOW) : root.statusFAIL;
    background: Rectangle {
      color: 'transparent';
      border.color: counter_.statusColor;
      radius: 2;
    }

    Component.onCompleted: count = root.count0;

    Label {
      id: chrono_;
      text: "00:00";
      Layout.rightMargin: 15;
      color: counter_.statusColor;

      function reset(){
        counter_.count = root.count0;
        chrono_.text = new Date(counter_.count).toLocaleTimeString(Qt.locale(), "mm:ss.z");
      }

      Timer {
        id: timer_;
        interval: 500;
        running: root.running;
        repeat: true;
        onTriggered:
        {
          counter_.count = counter_.count + (1 - 2*root.down)*timer_.interval;
          if(counter_.count < 0){
            counter_.count = 0;
          }
          chrono_.text =
            new Date(counter_.count).toLocaleTimeString(Qt.locale(), "mm:ss.z");
        }
      }
    }
  }

}

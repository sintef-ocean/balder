import QtQuick 2.11
import QtQuick.Controls 2.4
import QtQuick.Controls.Material 2.4
import QtQuick.Layouts 1.11

import fkin.Dds 1.0

RowLayout {
  id: root;
  Layout.topMargin: 10;
  Layout.bottomMargin: 10;
  Layout.fillWidth: true;

  FkinStyle { id: fkinStyle; }
  /// Value to be indicated
  property alias value: indicator.value;
  /// Instead of value use this text
  property alias valueText: indicator.text;
  /// Is the decision algorithm running
  property bool running: false;
  /// IcoFont unicode character to display logo
  property alias entity: icon_.text;
  /// ToolTip description
  property alias description: icon_.toolTipText;
  /// Unit of value
  property string unit: "";

  Label {
    id: icon_;
    text: "\uef50"; // info
    font: fkinStyle.iconFontHuge;
    property string toolTipText: qsTr("Info");
    ToolTip.text: toolTipText;
    ToolTip.visible: toolTipText ? ma_rot.containsMouse : false;
    MouseArea {
      id: ma_rot;
      anchors.fill: parent;
      hoverEnabled: true;
    }
  }

  Pane {
    id: status_;
    Layout.leftMargin: 10;
    Layout.rightMargin: 20;
    Layout.preferredWidth: 120;
    background: Rectangle {
      color: 'transparent';
      border.color: Material.foreground;
      radius: 2;
    }
    Label {
      id: indicator;
      font.pointSize: fkinStyle.numberFont.pointSize;
      property real value: 0;
      property int decimals: 1;
      text: isNaN(indicator.value) || !root.running ? "-" + root.unit :
        Number(indicator.value).toLocaleString(Qt.locale(), 'f', indicator.decimals) + root.unit;

      //Layout.alignment: Qt.AlignCenter;
      horizontalAlignment: Text.AlignHCenter;
      width: parent.width;
    }
  }
}

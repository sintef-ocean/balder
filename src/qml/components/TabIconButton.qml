import QtQuick 2.11
import QtQuick.Layouts 1.11
import QtQuick.Controls 2.4
import QtQuick.Controls.Material 2.4

/// Extended tap button to include icon
TabButton {
  id: control;
  height: parent.height;

  /// Unicode character for icon in tab.
  property alias iconText: content.iconText;

  contentItem: RowLayout {
    id: content;

    property alias iconText: icon.text;
    Layout.fillWidth: true;
    Layout.alignment: Qt.AlignCenter;
    Label {
      id: icon;
      Layout.alignment: Qt.AlignRight | Qt.AlignVCenter;
      Layout.rightMargin: 5;
      color: control.down || control.checked ? Material.accent : Material.foreground;
      font.family: "IcoFont";
      font.pointSize: 25;
      font.weight: Font.Medium;
    }
    Label {
      Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter;
      Layout.fillWidth: true;
      text: control.text;
      font: control.font;
      Component.onCompleted: font.capitalization = Font.AllUppercase;
      color: control.down || control.checked ? Material.accent : Material.foreground;
      elide: Text.ElideRight;
    }
  }
}

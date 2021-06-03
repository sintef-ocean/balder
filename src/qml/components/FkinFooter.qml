import QtQuick 2.11
import QtQuick.Controls 2.4
import QtQuick.Controls.Material 2.4
import QtQuick.Layouts 1.11

/// Application footer with logos.
RowLayout {
  id: footer;
  width: parent.width; /// Footer width equals parent width.

  /// FKIN logo container.
  Rectangle {
    id: fkinLogo;
    color: 'transparent';
    height: 50;
    width: 160;
    Layout.margins: 4;
    Image {
      anchors.fill: parent;
      /*source: "icons/FkinLogo.png"
        fillMode: Image.Stretch
        sourceSize.width: 100
        sourceSize.height: 100
      */
      source: Material.theme == Material.Dark ? "icons/LogoFkinNegative.png" : "icons/LogoFkinColor.png";
      fillMode: Image.PreserveAspectFit;
      anchors.centerIn: parent;
      sourceSize.height: fkinLogo.height;
    }
  }

  /// Transparent spacer
  Rectangle {
    id: centerMatter;
    color: 'transparent';
    Layout.fillWidth: true;
  }

  /// FHF Logo container.
  Rectangle {
    id: fhfLogo;
    color: 'transparent';
    height: 50;
    width: 180;
    Layout.margins: 4;
    Image {
      source: Material.theme == Material.Dark ? "images/FHF-white-txt.png" : "images/FHF-black-txt.png";
      fillMode: Image.PreserveAspectFit;
      anchors.centerIn: parent;
      sourceSize.height: 30;
    }
  }

  /// SINTEF logo container.
  Rectangle {
    id: sintefLogo;
    color: 'transparent'; //'#00457C'
    height: 50;
    width: 180;
    Layout.margins: 4;
    Image {
      source: Material.theme == Material.Dark ? "images/sintef-white-txt.png" : "images/sintef-blue-txt.png";
      fillMode: Image.PreserveAspectFit;
      sourceSize.height: 50;
    }
  }
}

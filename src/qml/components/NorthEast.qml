import QtQuick 2.11
import QtQuick.Controls 2.4
import QtQuick.Controls.Material 2.4
import QtQuick.Layouts 1.11
import QtCharts 2.2

import fkin.Dds 1.0

/// Map plot for with equal scaling of the axes North-East
ChartView {
  id: map;
  Layout.minimumWidth: 400;
  Layout.minimumHeight: 400;
  Layout.fillWidth: true;
  Layout.fillHeight: true;
  theme: style.chartTheme;
  backgroundColor: Material.background;
  titleColor: Material.foreground;
  titleFont : style.plotFont;
  antialiasing: true;
  animationOptions: ChartView.NoAnimation;
  //title: qsTr("Map plot");
  Component.onCompleted: themeChanged();

  /// Indicate that theme has changed and a redraw is necessary
  signal themeChanged;

  onThemeChanged:
  {
    map.titleFont = style.plotFont;
    map.axisX.labelsFont = style.plotFont;
    map.axisX.titleFont = style.plotFont;
    map.axisY.labelsFont = style.plotFont;
    map.axisY.titleFont = style.plotFont;
    map.legend.font = style.plotFont;
  }

  /// Custom style to fix QtCharts quirks
  property alias style: fkinStyle;
  FkinStyle { id: fkinStyle; }

  legend.visible: false;
  /// Adds a minimal field of view indicated by fovX and fovY at component creation
  property bool addMinFOV: false;
  /// Minimal field of view along x-axis
  property point fovX: Qt.point(-50, 50);
  /// Minimal field of view along y-axis
  property point fovY: Qt.point(-50, 50);
  /// Ensures that the axes has same scaling
  property alias equalizer: mapEqualizer;
  /// Reference to x-axis ValueAxis
  property alias axisX: mapX;
  /// Reference to y-axis ValueAxis
  property alias axisY: mapY;

  // Updating axis may cause a subtle bind loop that changes plotArea.
  // The changed is not revealed in the plotArea on its previous value, but two or three ago.
  // This timer is a temporary solution to avoid event loop congestion in those cases.
  Timer {
    id: axisAdjuster;
    interval: 100;
    running: false;
    repeat: false;
    onTriggered:
    {
      // When an axis update causes change of plot area
      mapX.min = mapEqualizer.equalAxisX.x;
      mapX.max = mapEqualizer.equalAxisX.y;
      mapY.min = mapEqualizer.equalAxisY.x;
      mapY.max = mapEqualizer.equalAxisY.y;
    }
  }

  AxisEqualizer {
    id: mapEqualizer;
    plotArea: map.plotArea;
    Component.onCompleted: if (addMinFOV) mapEqualizer.registerBox("FOV", map.fovX, map.fovY);
    onEqualAxisChanged: axisAdjuster.start();
  }

  ValueAxis {
    id: mapY;
    titleText: qsTr("North")+" [m]";
    labelsFont: map.style.plotFont;
  }

  ValueAxis {
    id: mapX;
    titleText: qsTr("East")+" [m]";
    labelsFont: map.style.plotFont;
    tickCount: 5;
  }

}

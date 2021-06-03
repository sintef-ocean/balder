import QtQuick 2.11
import QtQuick.Controls 2.4
import QtQuick.Controls.Material 2.4
import QtQuick.Layouts 1.11
import QtCharts 2.2

import fkin.Dds 1.0
import "fkinHelpers.js" as Fkin

/// Time series plot, x-axis is a DateTimeAxis
ChartView {
  id: timeChart;
  height: 300;
  Layout.fillWidth: true;
  Layout.minimumWidth: 600;
  theme: style.chartTheme;
  backgroundColor: Material.background;
  titleColor: Material.foreground;
  titleFont: style.plotFont;
  antialiasing: true;
  animationOptions: ChartView.NoAnimation;

  Component.onCompleted: themeChanged();

  legend.visible: false;
  /// Add this time (milliseconds) to the tip to ensure some margin
  property int futureMS: 1000;
  /// Width of time interval in milliseconds
  property int widthMS: 30000;
  /// Calculated horizon in milliseconds (widthMS - futureMS)
  property int horizonMS: widthMS - futureMS;
  /// Field of view for y-axis
  property point fovY: Qt.point(0, 0.1);
  /// Reference to time axis DateTimeAxis
  property alias axisT: timeAxis;
  /// Reference to y-axis ValueAxis
  property alias axisY: yAxis;
  /// y-axis label text
  property alias labelY: yAxis.titleText;

  /// Custom style to fix QtCharts quirks
  property alias style: fkinStyle;
  FkinStyle { id: fkinStyle; }

  /// Indicate that theme has changed and a redraw is necessary
  signal themeChanged;

  onThemeChanged:
  {
    timeChart.titleFont = style.plotFont;
    timeChart.axisT.setStyle();
    timeChart.axisY.setStyle();
    timeChart.legend.font = style.plotFont;
  }


  DateTimeAxis {
    id: timeAxis;
    titleText: qsTr("Time");
    format: "hh:mm:ss";
    labelsFont: style.dateFont;
    titleFont: style.plotFont;
    tickCount : 5;
    min: new Date();
    max: new Date();

    function setStyle(){
      timeAxis.labelsFont = style.dateFont;
      timeAxis.titleFont = style.dateFont;
    }

  }

  ValueAxis {
    id: yAxis;
    titleText: "Y";
    labelsFont: style.plotFont;
    min: 0;
    max: 1;

    function setStyle(){
      yAxis.labelsFont = style.plotFont;
      yAxis.titleFont = style.plotFont;
    }

  }

  /// Update visible time range so that (minT, maxT) is included
  function updateRangeT(minT, maxT){

    timeChart.axisT.min = minT;
    timeChart.axisT.max = maxT;
    Fkin.ensureTimeHorizon(timeChart, timeChart.horizonMS, timeChart.futureMS, minT, maxT);

  }


}

import QtQuick 2.11
import QtQuick.Controls 2.4
import QtQuick.Controls.Material 2.4
import QtQuick.Layouts 1.11
import QtCharts 2.2

import fkin.Dds 1.0
import "fkinHelpers.js" as Fkin

ColumnLayout {
  id: root;

  /// Custom style to fix QtChart quirks
  property alias style: fkinStyle;
  /// Plot height for visual plot elements
  property int plotHeight: 400;

  FkinStyle { id: fkinStyle; }
  FkinDdsTopics { id: topic; }

  /// Indicate that theme has changed and a redraw is necessary
  signal themeChanged;

  DdsIdVec1dBuffer {id: ddsFishDepthBuffer; }

  /// Initialize DDS data structures.
  function init(participant)
  {
    ddsFishDepthBuffer.init(participant, topic.fishDepth, topic.idFish, 300, false);
  }


  // ===================
  // Visual elements
  // ===================

  RowLayout {

    ColumnLayout {
      TimeChart {
        id: depthChart;
        title: qsTr("Fish depth");
        height: root.plotHeight;
        labelY: "[m]";
        fovY: Qt.point(0, 5);
        axisY.reverse: true;
        horizonMS: 12000;

        LineSeries {
          id: depthLine;
          name: qsTr("Fish");

          axisX: depthChart.axisT;
          axisY: depthChart.axisY;

          // QTBUG-58230: cannot use OpenGL because 32 bit int overflow (time is int64)
          useOpenGL: false;

          Component.onCompleted: setStyle();

          function setStyle()
          {
            color = root.style.defaultLineColor;
            style = Qt.SolidLine;
            width = 3;
          }

        }
      }
      Connections {
        target: root;
        onThemeChanged:
        {
          depthChart.themeChanged();
          depthLine.setStyle();
        }
      }
    }
  }

  // Connect buffer data to be plotted to line series.
  Connections {
    target: ddsFishDepthBuffer;
    onNewData:
    {
      ddsFishDepthBuffer.updateSeries(depthLine, FKIN.T, FKIN.X);
    }
    onRangeChanged:
    {

      if(dim == FKIN.X)
      {
        depthLine.axisY.min = range.x;
        depthLine.axisY.max = range.y;
        Fkin.zoomToFrame(range, depthChart.fovY, depthLine.axisY, 2);
      }
    }
    onRangeTChanged:
    {
      depthChart.updateRangeT(ddsFishDepthBuffer.rangeTmin, ddsFishDepthBuffer.rangeTmax);
    }
  }
}

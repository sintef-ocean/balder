import QtQuick 2.11
import QtQuick.Controls 2.4
import QtQuick.Controls.Material 2.4
import QtQuick.Layouts 1.11
import QtCharts 2.2

import fkin.Dds 1.0
import "fkinHelpers.js" as Fkin

/// Optimization visual elements with control and status information
ColumnLayout {
  id: root;
  /// Name to display for NLP stats
  property alias program_name: title.text;
  /// Reference to sinspekto::DdsNlpConfigSubscriber instance
  property alias config: ddsNlpConfig;
  /// Reference to sinspekto::DdsOptoStatsSubscriber instance
  property alias stats: ddsOptiStats;
  /// Custom style to fix QtChart quirks
  property alias style: fkinStyle;
  /// Plot height for visual plot elements
  property int plotHeight: 400;

  FkinStyle { id: fkinStyle; }
  DdsNlpConfigSubscriber { id: ddsNlpConfig; }
  DdsOptiStatsSubscriber { id: ddsOptiStats; }

  /// Indicate that theme has changed and a redraw is necessary
  signal themeChanged;

  // Retransmit selection of stats to DDS type with buffer
  DdsIdVec4dPublisher {
    id: ddsOptiSelectionPub;
    value: Qt.vector4d(
      ddsOptiStats.status,
      ddsOptiStats.iterations,
      ddsOptiStats.obj,
      ddsOptiStats.solve_time);
  }

  // Buffer with selection of stats to be plotted.
  DdsIdVec4dBuffer {id: ddsOptiBuffer; }

  /// Initialize DDS data structures.
  function init(participant, bufferSize, nlpConfigTopic, nlpStatsTopic, id)
  {
    ddsNlpConfig.init(participant, nlpConfigTopic, id);
    ddsOptiStats.init(participant, nlpStatsTopic, id);

    // Local DDS types
    ddsOptiSelectionPub.init(participant, "fkinNlpInfoSelection", id, Qt.vector4d(0,0,0,0), false);
    ddsOptiBuffer.init(participant, "fkinNlpInfoSelection", id, 40, true);
  }


  // ===================
  // Visual elements
  // ===================

  RowLayout {

    // Future: TableView available for  Qt 5.11 <
    GridLayout {
      columns: 2;
      Layout.alignment: Qt.AlignTop;
      Label { text: ""; Layout.columnSpan: 2; }
      Label {
        id: title;
        font.pointSize: root.style.largerPoints;
        Layout.rightMargin: 20;
      }
      Label { text: qsTr("NLP config"); font.pointSize: root.style.largerPoints;}

      Label { text: ""; Layout.columnSpan: 2; font.pointSize: 1; }

      Label { text: qsTr("Technique"); }         Label { text: ddsNlpConfig.technique; }
      Label { text: qsTr("Solver"); }            Label { text: ddsNlpConfig.solver; }
      Label { text: qsTr("Horizon") + " [s]"; }  Label { text: ddsNlpConfig.horizon; }
      Label { text: qsTr("Elements"); }          Label { text: ddsNlpConfig.elements; }

      Label {
        textFormat: Text.RichText;
        text: "n<sub>x</sub>";
      }
      Label { text: ddsNlpConfig.nx; }

      Label {
        textFormat: Text.RichText;
        text: "n<sub>p</sub>";
      }
      Label { text: ddsNlpConfig.np; }

      Label {
        textFormat: Text.RichText;
        text: "n<sub>g</sub>";
      }
      Label { text: ddsNlpConfig.ng; }

      Label { text: ""; Layout.columnSpan: 2; }

      Label {
        text: qsTr("Solve statistics");
        font.pointSize: root.style.largerPoints;
        Layout.columnSpan: 2;
      }

      Label { text: ""; Layout.columnSpan: 2; font.pointSize: 1; }

      // Add statistics
      Label { text: qsTr("Iterations"); }      Label { text: ddsOptiStats.iterations; }

      Label { text: qsTr("Objective"); }
      Label { text: Number(ddsOptiStats.obj).toLocaleString(Qt.locale(), 'f', 2); }

      Label { text: qsTr("Solve time") + " [s]"; }
      Label { text: Number(ddsOptiStats.solve_time).toLocaleString(Qt.locale(), 'f', 3); }

      Label {
        text: qsTr("Status:");
        Layout.columnSpan: 2;
      }

      Label {
        text: ddsOptiStats.status_text;
        Layout.columnSpan: 2;
      }

    }

    ColumnLayout {
      TimeChart {
        id: iterationsChart;
        //title: qsTr("NLP solver iterations");
        height: root.plotHeight;
        labelY: "Iterations [#]";
        fovY: Qt.point(0, 5);

        LineSeries {
          id: iterationsLine;
          name: qsTr("Iterations");

          axisX: iterationsChart.axisT;
          axisY: iterationsChart.axisY;

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
      TimeChart {
        id: objectiveChart;
        //title: qsTr("Objective function value");
        height: root.plotHeight;
        labelY: "Objective [-]";
        fovY: Qt.point(0, 0.01);

        LineSeries {
          id: objectiveLine;
          name: qsTr("Objective");

          axisX: objectiveChart.axisT;
          axisY: objectiveChart.axisY;

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
      TimeChart {
        id: solveTimeChart;
        //title: qsTr("Solve time");
        height: root.plotHeight;
        labelY: "Solve [s]";
        fovY: Qt.point(0, 0.01);

        LineSeries {
          id: solveTimeLine;
          name: qsTr("Solve time");

          axisX: solveTimeChart.axisT;
          axisY: solveTimeChart.axisY;

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
          iterationsChart.themeChanged();
          iterationsLine.setStyle();
          objectiveChart.themeChanged();
          objectiveLine.setStyle();
          solveTimeChart.themeChanged();
          solveTimeLine.setStyle();
        }
      }
    }
  }

  // Connect buffer data to be plotted to line series.
  Connections {
    target: ddsOptiBuffer;
    onNewData:
    {
      ddsOptiBuffer.updateSeries(iterationsLine, FKIN.T, FKIN.Y);
      ddsOptiBuffer.updateSeries(objectiveLine, FKIN.T, FKIN.Z);
      ddsOptiBuffer.updateSeries(solveTimeLine, FKIN.T, FKIN.W);
    }
    onRangeChanged:
    {

      if(dim == FKIN.Y)
      {
        iterationsLine.axisY.min = range.x;
        iterationsLine.axisY.max = range.y;
        Fkin.zoomToFrame(range, iterationsChart.fovY, iterationsLine.axisY, 0.2);
      }
      if(dim == FKIN.Z)
      {
        objectiveLine.axisY.min = range.x;
        objectiveLine.axisY.max = range.y;
        Fkin.zoomToFrame(range, objectiveChart.fovY, objectiveLine.axisY, 0.05);
      }
      if(dim == FKIN.W)
      {
        solveTimeLine.axisY.min = range.x;
        solveTimeLine.axisY.max = range.y;
        Fkin.zoomToFrame(range, solveTimeChart.fovY, solveTimeLine.axisY, 0.05);
      }
    }
    onRangeTChanged:
    {
      iterationsChart.updateRangeT(ddsOptiBuffer.rangeTmin, ddsOptiBuffer.rangeTmax);
      objectiveChart.updateRangeT(ddsOptiBuffer.rangeTmin, ddsOptiBuffer.rangeTmax);
      solveTimeChart.updateRangeT(ddsOptiBuffer.rangeTmin, ddsOptiBuffer.rangeTmax);
    }
  }
}

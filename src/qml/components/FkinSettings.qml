import QtQuick 2.11
import QtQuick.Controls 2.4
import QtQuick.Controls.Material 2.4
import QtQuick.Layouts 1.11
import QtQuick.Shapes 1.11
import QtCharts 2.2

import fkin.Dds 1.0
import "fkinHelpers.js" as Fkin

/// Window with elements for controlling simulators and external processes
ColumnLayout {
  id: root;

  /// Reference to connection that deals with the theme
  property alias themeChanger: themeChanger_;
  /// Is the DDS members initialized
  property bool ddsInitialized: false;


  /// Coordinate of mouse hover
  property point mouseTip: Qt.point(0,0);
  /// Helper boolean for active mouse hover
  property bool mouseActive: false;
  /// Mouse hovered above a point pnt
  signal pointHovered(point pnt);

  onPointHovered:{
    mouseTip = pnt;
    mouseActive = true;
    hoverShow.restart();
  }

  Timer {
    id: hoverShow;
    interval: 1500;
    running: false;
    repeat: false;
    onTriggered: {
      root.mouseActive = false;
    }
  }

  FkinStyle { id: style; }
  FkinDdsTopics { id: topic; }

  /// Initialize DDS member variables
  function init(participant){

    dds.purseSpeed.init(participant,
                        topic.vesselSettingSpeed,
                        topic.idPursePlanner,
                        settingSpeed.value*1.852/3.6,
                        true);
    dds.purseRadius.init(participant,
                         topic.vesselSettingRadius,
                         topic.idPursePlanner,
                         Qt.vector2d(settingDiameter_x.value/2,settingDiameter_y.value/2),
                         true);
    dds.purseArcLength.init(participant,
                            topic.aimPointArcLength,
                            topic.idPursePlanner,
                            alongPath.value,
                            true);

    dds.purseFishMargin.init(participant,
                            topic.fishMargin,
                            topic.idPursePlanner,
                            fishMargin.value,
                            true);

    dds.purseLeadMargin.init(participant,
                             topic.leadMargin,
                             topic.idPursePlanner,
                             marginLead.value,
                             true);

    dds.purseLeadline.init(participant,
                           topic.leadlineParameters,
                           topic.idLeadline,
                           Qt.vector2d(tauLead.value, setPointLead.value),
                           true);

    ddsLeadlineTrajectoryBuffer.init(participant,
                                     topic.leadlineResponse,
                                     topic.idLeadline,
                                     2000,
                                     true);

  }

  function estimateO(a, b){
    var h = Math.pow((a - b), 2) / Math.pow((a + b), 2);
    return Math.PI*(a + b)*(1 + 3*h/(10 + Math.pow((4 - 3*h), (1/2)) ));
  }

  Item {
    id: dds;

    property alias purseSpeed: purseSpeed_;
    property alias purseRadius: purseRadius_;
    property alias purseArcLength: purseArcLength_;
    property alias purseFishMargin: purseFishMargin_;
    property alias purseLeadMargin: purseLeadMargin_;
    property alias purseLeadline: purseLeadline_;

    // Added some helper types for some parameters in FkinPurseDashboard

    DdsIdVec1dPublisher { id: purseSpeed_;      value: settingSpeed.value*1.852/3.6; }
    DdsIdVec2dPublisher { id: purseRadius_;     value: Qt.vector2d(settingDiameter_x.value/2,
                                                                   settingDiameter_y.value/2); }
    DdsIdVec1dPublisher { id: purseArcLength_;  value: alongPath.value; }
    DdsIdVec1dPublisher { id: purseFishMargin_; value: fishMargin.value; }
    DdsIdVec1dPublisher { id: purseLeadMargin_; value: marginLead.value; }
    DdsIdVec2dPublisher { id: purseLeadline_;   value: Qt.vector2d(tauLead.value,
                                                                   setPointLead.value); }
    DdsIdVec1dBuffer { id: ddsLeadlineTrajectoryBuffer; }

  }

  // Forcefully send parameters regularly
  Timer {
    interval: 2000;
    running: true;
    repeat: true;
    onTriggered: {
      if(root.ddsInitialized)
      {
        dds.purseSpeed.publish();
        dds.purseRadius.publish();
        dds.purseArcLength.publish();
        dds.purseFishMargin.publish();
        dds.purseLeadMargin.publish();
        dds.purseLeadline.publish();
      }
    }
  }


  RowLayout {
    Layout.alignment: Qt.AlignTop | Qt.AlignLeft;
    Label {
      font: style.iconFontBig;
      text: "\uebfc";
    }
    Label {
      text: qsTr("Pursing settings");
      font.weight: Font.DemiBold;
      font.underline: true;
    }
  }
  RowLayout {
    id: sets;
    width: parent.width;
    GridLayout {
      Layout.alignment: Qt.AlignTop | Qt.AlignLeft;
      columns: 2;

      Label {
        text: qsTr("Setting speed");
        property string toolTipText: qsTr("Speed in water, knots");
        ToolTip.text: toolTipText;
        ToolTip.visible: toolTipText ? ma_sp.containsMouse : false;
        MouseArea {
          id: ma_sp;
          anchors.fill: parent;
          hoverEnabled: true;
        }
      }
      RowLayout {
        Slider {
          id: settingSpeed;
          from: 5;
          value: 12;
          to: 15;
          stepSize: 1;
          snapMode: Slider.SnapOnRelease;
          //onValueChanged: console.log(qsTr("Setting speed: ") + value);

        }
        Label { text: settingSpeed.value + " kn";  }
      }

      Label {
        text: qsTr("Setting diameter, along");
        property string toolTipText: qsTr("Idealized setting diameter along fish direction");
        ToolTip.text: toolTipText;
        ToolTip.visible: toolTipText ? ma_diaX.containsMouse : false;
        MouseArea {
          id: ma_diaX;
          anchors.fill: parent;
          hoverEnabled: true;
        }

      }
      RowLayout {
        Slider {
          id: settingDiameter_x;
          from: 200;
          value: 300;
          to: 400;
          stepSize: 5;
          snapMode: Slider.SnapOnRelease;
          //onValueChanged: console.log(qsTr("Setting diameter: ") + value);
        }
        Label { text: settingDiameter_x.value + " m";  }
      }

      Label {
        text: qsTr("Setting diameter, across");
        property string toolTipText: qsTr("Idealized setting diameter across fish direction");
        ToolTip.text: toolTipText;
        ToolTip.visible: toolTipText ? ma_diaY.containsMouse : false;
        MouseArea {
          id: ma_diaY;
          anchors.fill: parent;
          hoverEnabled: true;
        }

      }
      RowLayout {
        Slider {
          id: settingDiameter_y;
          from: 200;
          value: 300;
          to: 400;
          stepSize: 5;
          snapMode: Slider.SnapOnRelease;
          //onValueChanged: console.log(qsTr("Setting diameter: ") + value);
        }
        Label { text: settingDiameter_y.value + " m";  }
      }

      Label {
        text: qsTr("Aim point distance");
        property string toolTipText: qsTr("Distance along vessel path from deployment point to the point at which the fish would collide, meter");
        ToolTip.text: toolTipText;
        ToolTip.visible: toolTipText ? ma.containsMouse : false;
        MouseArea {
          id: ma;
          anchors.fill: parent;
          hoverEnabled: true;
        }
      }

      RowLayout {
        Slider {

          id: alongPath;
          from: root.estimateO(settingDiameter_x.value/2, settingDiameter_y.value/2)/4; // (quarter)
          value: alongPath.from*4*1.75/5;       // default: 35% of circumference
          to: alongPath.from*4*3/5;          // approx. 60% of circumference
          stepSize: 5;
          snapMode: Slider.SnapOnRelease;
          //onValueChanged: console.log(qsTr("Along path distance: ") + value);

        }
        Label { text: Number(alongPath.value).toLocaleString(Qt.locale(),'f',0) + " m"; }
      }
      Label { text: qsTr("Circumference:"); }
      Label {
        id: circumInfo;
        property real circumference: root.estimateO(settingDiameter_x.value/2, settingDiameter_y.value/2);
        text: Number(circumference).toLocaleString(Qt.locale(),'f',0) + " m,  85%: " +
          Number(0.85*circumference).toLocaleString(Qt.locale(), 'f', 0) + " m"; }

      Label {
        text: qsTr("Fish margin when set");
        property string toolTipText: qsTr("Minimum distance to fish when finished setting, meter");
        ToolTip.text: toolTipText;
        ToolTip.visible: toolTipText ? ma_fm.containsMouse : false;
        MouseArea {
          id: ma_fm;
          anchors.fill: parent;
          hoverEnabled: true;
        }
      }
      RowLayout {
        Slider {
          id: fishMargin;
          from: 1;
          value: settingDiameter_x.value/3;
          to: settingDiameter_x.value*3/4;
          stepSize: 1;
          snapMode: Slider.SnapOnRelease;
        }
        Label { text: Number(fishMargin.value).toLocaleString(Qt.locale(),'f',0) + " m";  }
      }
      Label {
        text: qsTr("Leadline sink margin");
        property string toolTipText: qsTr("Margin at collision point = leadline depth - fish depth");
        ToolTip.text: toolTipText;
        ToolTip.visible: toolTipText ? maMarg.containsMouse : false;
        MouseArea {
          id: maMarg;
          anchors.fill: parent;
          hoverEnabled: true;
        }
      }
      RowLayout {
        Slider {
          id: marginLead;
          from: 1;
          to: setPointLead.value - 1;
          value: 50;
          stepSize: 1;
          snapMode: Slider.SnapOnRelease;
        }
        Label{ text: marginLead.value + " m"; }
      }
      Label {
        text: qsTr("Leadline time constant");
        property string toolTipText: qsTr("Time to reach about 2/3 of set point");
        ToolTip.text: toolTipText;
        ToolTip.visible: toolTipText ? maTau.containsMouse : false;
        MouseArea {
          id: maTau;
          anchors.fill: parent;
          hoverEnabled: true;
        }
      }
      RowLayout {
        Slider {
          id: tauLead;
          from: 250;
          to: 450;
          value: 350;
          stepSize: 5;
          snapMode: Slider.SnapOnRelease;
        }
        Label{ text: tauLead.value + " s"; }
      }
      Label {
        text: qsTr("Leadline set point");
        property string toolTipText: qsTr("Depth if not hauled");
        ToolTip.text: toolTipText;
        ToolTip.visible: toolTipText ? maSet.containsMouse : false;
        MouseArea {
          id: maSet;
          anchors.fill: parent;
          hoverEnabled: true;
        }
      }
      RowLayout {
        Slider {
          id: setPointLead;
          from: 80;
          to: 200;
          value: 160;
          stepSize: 2;
          snapMode: Slider.SnapOnRelease;
        }
        Label{ text: setPointLead.value + " m"; }
      }
    }

    ColumnLayout {
    Shape {
      width: settingDiameter_x.to*scale + 30;
      height: settingDiameter_x.to*scale + 20;
      id: shape;

      property real scale: 0.7;
      property real radiusX: scale*settingDiameter_x.value/2;
      property real radiusY: scale*settingDiameter_y.value/2;
      property real settingSweep: 360*(alongPath.value*shape.scale)/root.estimateO(shape.radiusX,shape.radiusY);
      property real eightySweep: 306 - settingSweep;
      // multisample, decide based on your scene settings
      layer.enabled: true;
      layer.samples: 6;


      ShapePath {
        fillColor: "transparent"; //Material.background;
        strokeColor: Material.color(Material.Orange, Material.Shade500);
        strokeWidth: 5;
        capStyle: ShapePath.FlatCap;

        PathAngleArc {
          id: sweepAlong;
          centerX: shape.radiusY + 10 + 10;
          centerY: shape.radiusX + 10;
          radiusX: shape.radiusY;
          radiusY: shape.radiusX;
          startAngle: -90;
          sweepAngle: -shape.settingSweep;
          //onSweepAngleChanged: console.log(sweepAngle);
        }
      }

      ShapePath {
        fillColor: "transparent";//Material.background;
        strokeColor: Material.accent;
        //strokeStyle: ShapePath.DashLine;
        strokeWidth: 4;
        capStyle: ShapePath.RoundCap;

        PathAngleArc {
          id: sentrum;
          centerX: sweepAlong.centerX; centerY: sweepAlong.centerY;
          radiusX: shape.radiusY; radiusY: shape.radiusX;
          startAngle: -90; //sweepAlong.startAngle + sweepAlong.sweepAngle;
          sweepAngle: shape.eightySweep;//300 - sweepAlong.sweepAngle;
        }
      }

      ShapePath {
        id: fishDir;
        strokeColor: Material.color(Material.DeepOrange, Material.Shade500);
        strokeWidth: 4;
        fillColor: "transparent";
        joinStyle: ShapePath.RoundJoin;


        startX: sweepAlong.centerX; startY: sweepAlong.centerY;
        PathLine {
          id: fishPoint;
          x: fishDir.startX; y: fishDir.startY - 0.3*shape.radiusX; }
        PathLine { relativeX: 7; relativeY: 7; }
        PathLine { relativeX: -14; relativeY: 0; }
        PathLine { relativeX: 7; relativeY: -7; }
      }

      ShapePath {
        id: trapMargin;
        strokeColor: Material.color(Material.Blue);
        strokeWidth: 3;
        fillColor: "transparent";
        joinStyle: ShapePath.RoundCap;
        strokeStyle: ShapePath.DashLine;

        startX: sentrum.centerX;
        startY: sentrum.centerY + shape.radiusX;
        PathLine { relativeX: 0; relativeY: -fishMargin.value*shape.scale; }

      }
    }
      Shape {
        width: 200;
        height: 100;
        id: shapeMargin;
        // multisample, decide based on your scene settings
        layer.enabled: true;
        layer.samples: 6;

        ShapePath {
          id: fishIndication;
          strokeColor: Material.color(Material.DeepOrange);
          strokeWidth: 3;
          fillColor: "transparent";

          startX: 50;
          startY: 10;
          PathLine { relativeX: 100; relativeY: 0; }

        }
        ShapePath {
          id: marginSink;
          strokeColor: Material.color(Material.Blue);
          strokeWidth: 3;
          fillColor: "transparent";
          strokeStyle: ShapePath.DashLine;
          startX: 150;
          startY: 10;
          PathLine { relativeX: 0; relativeY: 100*marginLead.value/marginLead.to; }
        }
      }
    }
  }

  RowLayout {
    id: leadPosition;
    Label { text: "\uef50"; font: style.iconFont; } // info
    Label {
      text: !root.mouseActive ? "" :
        new Date(root.mouseTip.x - new Date()).toLocaleTimeString(Qt.locale(), "mm:ss") + ": " +
        Number(root.mouseTip.y).toLocaleString(Qt.locale(),'f', 0) + " m";
      Layout.preferredWidth: 200;
    }
  }

  TimeChart {
    id: leadlineChart;
    //title: qsTr("Leadline response");
    Layout.fillWidth: true;
    Layout.maximumWidth: 1000;
    //Layout.preferredWidth: 0.8*parent.width;
    height: 350;
    labelY: "Leadline [m]";
    fovY: Qt.point(0, 5);
    axisY.reverse: true;
    widthMS: 1000000;
    futureMS: 0;
    axisT.tickCount: 8;

    axisT.visible: false;

    DateTimeAxis {
      id: anotherTime;
      titleText: qsTr("Time [min]");
      labelsFont: style.dateFont;
      titleFont: style.plotFont;
      format: "m";
      tickCount : 9;
      min: new Date(0);
      max: new Date(leadlineChart.widthMS);

      function setStyle(){
        anotherTime.labelsFont = style.dateFont;
        anotherTime.titleFont = style.dateFont;
      }
    }

    ScatterSeries {
      id: dummy;
      axisX: anotherTime;
      axisYRight: leadlineChart.axisY;
    }


    LineSeries {
      id: leadlineLine;
      name: qsTr("Leadline");
      axisX: leadlineChart.axisT;
      axisYRight: leadlineChart.axisY;
      // QTBUG-58230: cannot use OpenGL because 32 bit int overflow (time is int64)
      useOpenGL: false;
      Component.onCompleted: setStyle();
      function setStyle()
      {
        color = style.defaultLineColor;
        leadlineLine.style = Qt.SolidLine;
        width = 3;
      }

      onHovered: if(state){ root.pointHovered(point); }
    }

    Connections {
      target: themeChanger_;
      onToggled:
      {
        leadlineChart.themeChanged();
        leadlineLine.setStyle();
        anotherTime.setStyle();
      }
    }

    // Connect buffer data to be plotted to line series.
    Connections {
      target: ddsLeadlineTrajectoryBuffer;
      onNewData:
      {
        ddsLeadlineTrajectoryBuffer.updateSeries(leadlineLine, FKIN.T, FKIN.X);
        ddsLeadlineTrajectoryBuffer.clearBuffers();
      }
      onRangeChanged:
      {

        if(dim == FKIN.X)
        {
          leadlineLine.axisYRight.min = range.x;
          leadlineLine.axisYRight.max = range.y;
          Fkin.zoomToFrame(range, leadlineChart.fovY, leadlineLine.axisYRight, 2);
        }
      }
      onRangeTChanged:
      {
        leadlineChart.updateRangeT(ddsLeadlineTrajectoryBuffer.rangeTmin,
                                   ddsLeadlineTrajectoryBuffer.rangeTmax);
      }
    }

  }

  ProgressBar {
    // Horizontal line
    implicitWidth: parent.width;
    value: 1.0;
    Layout.alignment: Qt.AlignLeft;
  }


  RowLayout {
    Layout.alignment: Qt.AlignTop | Qt.AlignLeft;
    Label {
      font: style.iconFontBig;
      text: "\uef24"; // eye
    }
    Label {
      text: qsTr("Appearance");
      font.weight: Font.DemiBold;
      font.underline: true;
    }
  }
  RowLayout {
    Layout.alignment: Qt.AlignLeft;
    Label { text: qsTr("Styling");  }
    Switch {
      id: themeChanger_;
      text: qsTr("Dark Theme");

      Component.onCompleted:{
        if(Material.theme == Material.Dark)
          toggle();
      }
    }
  }

  // TODO: add settings for parameters of optimization problem

}

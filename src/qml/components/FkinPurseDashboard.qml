import QtQuick 2.11
import QtQuick.Layouts 1.11
import QtQuick.Controls 2.4
import QtQuick.Controls.Material 2.4
import QtCharts 2.2

import fkin.Dds 1.0
import "fkinHelpers.js" as Fkin
import ratatosk 1.0

/// Main dashboard component
RowLayout {

  id: root;
  FkinStyle { id: fkinStyle; }
  /// (lat,lon) origin of NED
  property vector2d originNED: Qt.vector2d(63.4581027, 10.3683367);
  /// Indicates a reset, i.e. a new trajectory is to be visualized
  signal triggerReset;
  /// Indicate that the theme has changed and a redraw is needed
  signal themeChanged;
  /// Is the purse path planner running
  property bool plannerRunning: false;
  /// Has the DDS member variables been initialized
  property bool ddsInitialized: false;

  /// Temporary "fake" properties for current and wind indicators, x: m/s, y: radians, z: m
  property vector3d currentMagDirDepth: Qt.vector3d(0.25, 0, 0);
  /// Wind magnitude and direction
  property vector2d windMagDir: Qt.vector2d(4, 0.5);
  /// Sea current at fish school depth, magnitude direction (?)
  property vector2d fishCurrent: Qt.vector2d(0.35, 0.35); // also published dds
  /// Sea current at surface, also published dds.
  property vector2d seaCurrent: Qt.vector2d(currentMagDirDepth.x*Math.cos(currentMagDirDepth.y),
                                            currentMagDirDepth.x*Math.sin(currentMagDirDepth.y));

  /// Coordinate of mouse hover
  property point mouseTip: Qt.point(0,0);
  /// Helper boolean for active mouse hover
  property bool mouseActive: false;
  /// Switch to indicate if manual fish parameters are to be used, not from measurements
  property bool manualFishCtrl: manualFish.checked; // Togglable switch

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

  /// Color of displayed vessel
  property color vesselColor: Material.color(Material.Blue, Material.Shade500);
  /// Color of deployment graph
  property color deployColor: Material.color(Material.Blue, Material.Shade500);
  /// Color of fish trajectory
  property color fishColor: Material.color(Material.DeepOrange, Material.Shade500);
  /// Color of wind indication
  property color windColor: Material.color(Material.Cyan, Material.Shade500);
  /// Color of sea current indication
  property color currentColor: Material.color(Material.Indigo, Material.Shade500);

  FkinDdsTopics { id: topic; }

  // Notifies new solution (resets time since update timer)
  Connections {
    target: ddsVesselTrajectoryBuffer;
    onNewData:  root.triggerReset();
  }

  /// Initialize DDS member variables.
  function init(ddsParticipant){

    // The if buffer size is too small, you will not get all data..
    ddsVesselTrajectoryBuffer.init(
      ddsParticipant, topic.vesselTrajectory, topic.idPursePlanner, 3000, true);
    ddsFishTrajectoryBuffer.init(
      ddsParticipant, topic.fishTrajectory, topic.idPursePlanner, 3000, true);

    ddsVesselPosInfo.init(ddsParticipant, topic.vesselPosInfo);
    vesselNED.init(ddsParticipant, topic.vesselPosInfo, topic.localNedTopic, "vessel");
    ddsVesselBuffer.init(ddsParticipant, topic.localNedTopic, "vessel", 30);

    ddsFishPosInfo.init(ddsParticipant, topic.fishPosInfo);
    fishNED.init(ddsParticipant, topic.fishPosInfo, topic.localNedTopic, "fish");
    fishRelative.init(ddsParticipant, topic.fishRelativePos);
    ddsFishBuffer.init(ddsParticipant, topic.localNedTopic, "fish", 30);

    currentSurface.init(ddsParticipant, topic.currentSurface, Qt.vector2d(0, 0), true);
    currentFish.init(ddsParticipant, topic.currentFish, root.fishCurrent, true);

    fishDepth.init(ddsParticipant, topic.fishDepth, topic.idFish, fishRelative.value.z, true);
    fishVelocityOverGround.init(ddsParticipant, topic.fishVelocityOverGround, Qt.vector2d(0, 0), false);

    // This is TEMOPORARY, TODO: use vessel pos info lat lon instead
    gpsOrigin.init(ddsParticipant, topic.gpsOrigin, root.originNED, true);

    vessel_rot_desired.init(ddsParticipant, topic.vesselRotDesired);

    vessel_deploy_position.init(ddsParticipant, topic.deployPosition);
    fish_collide_position.init(ddsParticipant, topic.collidePosition);
    vessel_deploy_time.init(ddsParticipant, topic.deployTime);

    keepSuggestion.init(ddsParticipant, topic.keepSolution, keeper.keepIt, true);




    }

  Item {
    id: dds;

    DdsKinematics2DBuffer { id: ddsVesselTrajectoryBuffer; }
    DdsKinematics2DBuffer { id: ddsFishTrajectoryBuffer; }

    RatatoskPosInfoSubscriber { id: ddsVesselPosInfo; }
    RatatoskPosInfoSubscriber { id: ddsFishPosInfo; }
    RatatoskDouble3Subscriber { id: fishRelative; }
    RatatoskDoubleValSubscriber { id: vessel_rot_desired; }
    RatatoskDouble2Subscriber { id: vessel_deploy_position; }
    RatatoskDouble2Subscriber { id: fish_collide_position; }
    RatatoskDoubleValSubscriber { id: vessel_deploy_time; }

    RatatoskDouble2Publisher { id: gpsOrigin; }
    RatatoskDouble2Publisher { id: currentSurface; value: root.seaCurrent; }
    RatatoskDouble2Publisher { id: currentFish;    value: root.fishCurrent; }
    DdsIdVec1dPublisher { id: fishDepth;    value: root.manualFishCtrl ? fishDepthPred.value : fishRelative.value.z; }
    RatatoskDouble2Publisher {
      id: fishVelocityOverGround;
      value: root.manualFishCtrl ?
        Qt.vector2d( fishSpeedPred.value*Math.cos(Math.PI*fishCoursePred.value/180),
                     fishSpeedPred.value*Math.sin(Math.PI*fishCoursePred.value/180)) :
        Qt.vector2d( ddsFishPosInfo.sog*Math.cos(Math.PI*ddsFishPosInfo.cog/180),
                     ddsFishPosInfo.sog*Math.sin(Math.PI*ddsFishPosInfo.cog/180));
    }



    // Forcefully send parameters regularly
    Timer {
      interval: 2000;
      running: true;
      repeat: true;
      onTriggered: {
        if(root.ddsInitialized)
        {
          currentSurface.publish();
          currentFish.publish();
          fishDepth.publish();
          fishVelocityOverGround.publish();
          gpsOrigin.publish();
        }
      }
    }
    /*
    Timer {
      interval: 10000;
      running: true;
      repeat: true;
      onTriggered: ddsVesselTrajectoryBuffer.clearBuffers();
    }*/

    TransformToNED {
      id: vesselNED;
      lat: root.originNED.x;
      lon: root.originNED.y;
    }
    DdsIdVec3dBuffer { id: ddsVesselBuffer; }


    TransformToNED {
      id: fishNED;
      lat: root.originNED.x;
      lon: root.originNED.y;
    }
    DdsIdVec3dBuffer { id: ddsFishBuffer; }

  }

  NorthEast {
    id: plot;
    legend.visible: false;
    legend.markerShape: Legend.MarkerShapeCircle;
    legend.alignment: Qt.AlignBottom;
    fovX: Qt.point(-100, 100);
    fovY: Qt.point(-100, 100);
    addMinFOV: false;
    axisX.tickCount: 8;
    axisY.tickCount: 8;
    margins.left: 10;
    margins.right: 10;
    margins.bottom: 10;
    margins.top: 10;

    // Use offseted axes instead based on vessel NED position
    axisX.visible: false;
    axisY.visible: false;

    function setStyle() {
      offY.labelsFont = fkinStyle.plotFont;
      offY.titleFont = fkinStyle.plotFont;
      offX.labelsFont = fkinStyle.plotFont;
      offX.titleFont = fkinStyle.plotFont;
      vesselTrack.setStyle();
      vesselNow.setStyle();
      vesselFuture.setStyle();
      fishTrack.setStyle();
      fishNow.setStyle();
      fishFuture.setStyle();
      plot.themeChanged();
      deployPos.setStyle();
      collidePos.setStyle();
    }


    Component.onCompleted: setStyle();

    ValueAxis {
      id: offX;
      titleText: qsTr("East")+ " [m]";
      labelsFont: plot.style.plotFont;
      tickCount: 8;
      min: plot.axisX.min;
      max: plot.axisX.max;
    }

    ValueAxis {
      id: offY;
      titleText: qsTr("North")+ " [m]";
      labelsFont: plot.style.plotFont;
      tickCount: 8;
      min: plot.axisY.min;
      max: plot.axisY.max;
    }

    LineSeries {
      id: dummy;
      axisXTop: offX;
      axisY: offY;
      visible: false;
    }


    Connections {
      target: root;
      onThemeChanged: plot.setStyle();
    }

    /// Vessel trajectory plot
    LineSeries {
      id: vesselTrack;
      name: qsTr("Vessel");
      // useOpenGL: true
      // style: Qt.DotLine // no effect with openGL
      axisXTop: plot.axisX;
      axisY: plot.axisY;

      onHovered: if(state){ root.pointHovered(point); }
      Component.onCompleted: setStyle();

      function setStyle(){
        color = root.vesselColor;
        width = 3;
      }

    }

    LineSeries {
      id: vesselFuture;
      name: qsTr("Vessel future");
      axisXTop: plot.axisX;
      axisY: plot.axisY;

      Component.onCompleted: setStyle();

      function setStyle(){
        color = root.vesselColor;
        width = 3;
        style = Qt.DotLine;
      }

      onHovered: if(state){ root.pointHovered(point); }

    }

    /// Current position of vessel
    ScatterSeries {
      id: vesselNow;
      axisXTop: plot.axisX;
      axisY: plot.axisY;
      color: root.vesselColor;

      Component.onCompleted: setStyle();

      function setStyle(){
        color = root.vesselColor;
        borderWidth = 0;
        markerSize = 12;
        markerShape = ScatterSeries.MarkerShapeCircle;
      }

      onHovered: if(state){ root.pointHovered(point); }

    }

    /// Deploy position of vessel
    ScatterSeries {
      id: deployPos;
      axisXTop: plot.axisX;
      axisY: plot.axisY;
      color: root.deployColor;

      Component.onCompleted: setStyle();

      function setStyle(){
        color = root.deployColor;
        borderWidth = 0;
        markerSize = 20;
        markerShape = ScatterSeries.MarkerShapeRectangle;
      }

      onHovered: if(state){ root.pointHovered(point); }

    }

    /// Update marker for deployment position
    Connections {
      target: vessel_deploy_position;
      onValueChanged:
      {
        deployPos.remove(0);
        deployPos.append(value.y, value.x);
      }
    }

    /// Collide position of fish
    ScatterSeries {
      id: collidePos;
      axisXTop: plot.axisX;
      axisY: plot.axisY;
      color: root.deployColor;

      Component.onCompleted: setStyle();

      function setStyle(){
        color = root.fishColor;
        borderWidth = 0;
        markerSize = 20;
        markerShape = ScatterSeries.MarkerShapeRectangle;
      }

      onHovered: if(state){ root.pointHovered(point); }

    }

    /// Update marker for deployment position
    Connections {
      target: fish_collide_position;
      onValueChanged:
      {
        collidePos.remove(0);
        collidePos.append(value.y, value.x);
      }
    }

    /// Connection between DDS data structure holding vessel track and visualizer component
    Connections {
      target: ddsVesselBuffer;
      onNewData:
      {
        ddsVesselBuffer.updateSeries(vesselTrack, FKIN.Y, FKIN.X);
      }
      onRangeChanged:
      {
        // Note that things are opposite (x, y is switched due to North is y, but x)
        if(dim == FKIN.X)        {
          plot.equalizer.registerBox("Vessel",
                                     ddsVesselBuffer.rangeY,
                                     Qt.point(range.x-50, range.y + 50));
        }
        if(dim == FKIN.Y){
          plot.equalizer.registerBox("Vessel",
                                     Qt.point(range.x-50, range.y + 50),
                                     ddsVesselBuffer.rangeX);
        }
      }
    }

    /// Connection between vessel position DDS signal and visualizer component
    Connections {
      target: vesselNED.ned; //ddsVesselNow;
      onValueChanged:
      {
        vesselNow.remove(0);
        vesselNow.append(value.y, value.x);

        offX.min = plot.axisX.min - value.y;
        offX.max = plot.axisX.max - value.y;
        offY.min = plot.axisY.min - value.x;
        offY.max = plot.axisY.max - value.x;
        plot.equalizer.registerBox("VesselNow",
                                   Qt.point(value.y-20, value.y+20),
                                   Qt.point(value.x-20, value.x+20));
        plot.equalizer.registerBox("VesselNowBig",
                                   Qt.point(value.y-250, value.y+250),
                                   Qt.point(value.x-250, value.x+250));

        /* With this the FOV grows.
        var middleX = 2*(value.y - (plot.axisX.min +  (plot.axisX.max - plot.axisX.min)/2));
        var rngX = Qt.point(plot.axisX.min + (middleX<0)*middleX + 10,
                           plot.axisX.max + (middleX>0)*middleX - 10);
        var middleY = 2*(value.y - (plot.axisX.min +  (plot.axisX.max - plot.axisX.min)/2));
        var rngY = Qt.point(plot.axisY.min + (middleY<0)*middleY + 10,
                            plot.axisY.max + (middleY>0)*middleY - 10);

        plot.equalizer.registerBox("VesselInMiddle", rngX, rngY);
        */
      }
    }


    Connections {
      target: ddsVesselTrajectoryBuffer;
      onNewData:
      {
        // remove old
        ddsVesselTrajectoryBuffer.updateSeries(vesselFuture, FKIN.PosY, FKIN.PosX);
        ddsVesselTrajectoryBuffer.clearBuffers(); // remove after consumption.
      }
      onRangeChanged:
      {
        // Note that things are opposite (x, y is switched due to North is y, but x)
        if(dim == FKIN.PosX){
          plot.equalizer.registerBox("VesselFuture",
                                     ddsVesselTrajectoryBuffer.rangePosY,
                                     Qt.point(range.x-50, range.y+50));
        }

        if(dim == FKIN.PosY){
          plot.equalizer.registerBox("VesselFuture",
                                     Qt.point(range.x-50, range.y+50),
                                     ddsVesselTrajectoryBuffer.rangePosX);
        }
      }
    }


    /// Fish trajectory plot
    LineSeries {
      id: fishTrack;
      name: qsTr("Fish");
      // useOpenGL: true
      // style: Qt.DotLine // no effect with openGL
      axisXTop: plot.axisX;
      axisY: plot.axisY;

      onHovered: if(state){ root.pointHovered(point); }
      Component.onCompleted: setStyle();

      function setStyle(){
        color = root.fishColor;
        width = 3;
      }
    }

    LineSeries {
      id: fishFuture;
      name: qsTr("Fish future");
      axisXTop: plot.axisX;
      axisY: plot.axisY;

      onHovered: if(state){ root.pointHovered(point); }
      Component.onCompleted: setStyle();

      function setStyle(){
        color = root.fishColor;
        width = 3;
        style = Qt.DotLine;
      }
    }

    /// Current position of fish
    ScatterSeries {
      id: fishNow;
      axisXTop: plot.axisX;
      axisY: plot.axisY;
      color: root.fishColor;

      onHovered: if(state){ root.pointHovered(point); }
      Component.onCompleted: setStyle();

      function setStyle(){
        color = root.fishColor;
        borderWidth = 0;
        markerSize = 12;
        markerShape = ScatterSeries.MarkerShapeCircle;
      }
    }

    /// Connection between DDS data structure holding fish track and visualizer component
    Connections {
      target: ddsFishBuffer;
      onNewData:
      {
        ddsFishBuffer.updateSeries(fishTrack, FKIN.Y, FKIN.X);
      }
      onRangeChanged:
      {
        // Note that things are opposite (x, y is switched due to North is y, but x)
        if(dim == FKIN.X)
          plot.equalizer.registerBox("Fish", ddsFishBuffer.rangeY, range);
        if(dim == FKIN.Y)
          plot.equalizer.registerBox("Fish", range, ddsFishBuffer.rangeX);
      }
    }

    /// Connection between fish position DDS signal and visualizer component
    Connections {
      target: fishNED.ned;
      onValueChanged:
      {
        fishNow.remove(0);
        fishNow.append(value.y, value.x);

        plot.equalizer.registerBox("FishNow",
                                   Qt.point(value.y-20, value.y+20),
                                   Qt.point(value.x-20, value.x+20));

      }
    }

    Connections {
      target: ddsFishTrajectoryBuffer;
      onNewData:
      {
        ddsFishTrajectoryBuffer.updateSeries(fishFuture, FKIN.PosY, FKIN.PosX);
        ddsFishTrajectoryBuffer.clearBuffers(); // remove after consumption.

      }
      onRangeChanged:
      {
        // Note that things are opposite (x, y is switched due to North is y, but x)
        if(dim == FKIN.PosX){
          plot.equalizer.registerBox("FishFuture",
                                     ddsFishTrajectoryBuffer.rangePosY,
                                     Qt.point(range.x-50, range.y+50));
        }

        if(dim == FKIN.PosY){
          plot.equalizer.registerBox("FishFuture",
                                     Qt.point(range.x-50, range.y+50),
                                     ddsFishTrajectoryBuffer.rangePosX);
        }
      }
    }

  }
  ColumnLayout {
    id: infotain;
    Layout.alignment: Qt.AlignTop;
    Layout.topMargin: 30;
    Layout.rightMargin: 10;

    function toDegrees(rad){
      // returns -180, 180.
      var deg = Math.atan2(Math.sin(rad), Math.cos(rad))*180/Math.PI;
      deg += (deg < 0)*360; // maps negative rot to [180,360]
      return deg;
    }

    function toKnots(mps){
      return mps*3.6/1.852;
    }

    RowLayout {
      Layout.alignment: Qt.AlignCenter;
      Layout.bottomMargin: 20;
      Layout.rightMargin: 20;

      Label {
        text: "\uf022";
        font: fkinStyle.iconFontBig;
        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter;
      }
      Label {
        id: clock;
        font.pointSize: fkinStyle.numberFont.pointSize + 2;
        property date klokka: new Date();
        text: klokka.toLocaleString(Qt.locale(), "hh:mm:ss");
        Layout.alignment: Qt.AlignCenter;
        Timer {
          interval: 1000;
          running: true;
          repeat: true;
          onTriggered: {
            var time = new Date;
            clock.klokka = time;
          }
        }
      }
    }

    InfoDirectionMagnitude {
      id: wind;
      Layout.alignment: Qt.AlignRight;
      Layout.bottomMargin: 15;
      entity: "\uee98"; // wind
      description: qsTr("Wind");
      arrow: "\uea5b"; // down-arrow since wind direction from where it originates
      unit: "kn";
      colorFont: root.windColor;
      magnitude: infotain.toKnots(root.windMagDir.x);
      orientation: infotain.toDegrees(root.windMagDir.y);
    }
    InfoDirectionMagnitude {
      id: current;
      Layout.alignment: Qt.AlignRight;
      Layout.bottomMargin: 15;
      entity: "\uee97"; // wind-waves
      description: qsTr("Current");
      unit: "kn";
      colorFont: root.currentColor;
      magnitude: infotain.toKnots(root.currentMagDirDepth.x);
      orientation: infotain.toDegrees(root.currentMagDirDepth.y);
      extra: Number(root.currentMagDirDepth.z).toLocaleString(Qt.locale(), 'f', 0) + " m";

    }
    InfoDirectionMagnitude {
      id: currentDeep;
      Layout.alignment: Qt.AlignRight;
      Layout.bottomMargin: 15;
      entity: "\uee97"; // wind-waves
      description: qsTr("Current at depth");
      unit: "kn";
      colorFont: root.currentColor;
      magnitude: infotain.toKnots(root.fishCurrent.length());
      orientation: infotain.toDegrees(Math.atan2(root.fishCurrent.y, root.fishCurrent.x));
      extra: isNaN(fishRelative.value.z) ? "-" :
        Number(fishRelative.value.z).toLocaleString(Qt.locale(), 'f', 0) + " m";

    }
    InfoDirectionMagnitude {
      id: vessel;
      Layout.alignment: Qt.AlignRight;
      Layout.bottomMargin: 15;
      entity: "\uee34"; // ship
      description: qsTr("Ship: speed and course over ground");
      unit: "kn";
      colorFont: root.vesselColor;
      magnitude: infotain.toKnots(ddsVesselPosInfo.sog);
      orientation: ddsVesselPosInfo.cog;

    }
    InfoDirectionMagnitude {
      id: fish;
      Layout.alignment: Qt.AlignRight;
      Layout.bottomMargin: 5;
      entity: "\ue850"; // fish-2
      description: qsTr("Fish: speed and course over ground");
      unit: "kn";
      colorFont: root.fishColor;
      magnitude: infotain.toKnots(ddsFishPosInfo.sog);
      orientation: ddsFishPosInfo.cog;
      extra: isNaN(fishRelative.value.z) ? "-" :
        Number(fishRelative.value.z).toLocaleString(Qt.locale(), 'f', 0) + " m";
    }
    ProgressBar {
      // Horizontal line
      implicitWidth: parent.width;
      value: 1.0;
      Layout.alignment: Qt.AlignLeft;
      Layout.bottomMargin: 5;
    }

    RowLayout {
      id: debugItem;
      visible: false;
      implicitWidth: parent.width;
      Label {
        id: icon_;
        text: "\ueec7"; // bug
        font: fkinStyle.iconFontBig;
        Layout.rightMargin: 10;
      }
      Button {
        id: clearGraphs;
        text: qsTr("Clear buffers");
        Layout.alignment: Qt.AlignRight;


        onClicked:
        {
          ddsVesselBuffer.clearBuffers();
          ddsFishBuffer.clearBuffers();
          ddsVesselTrajectoryBuffer.clearBuffers();
          ddsFishTrajectoryBuffer.clearBuffers();
          //fishNow.remove(0);
          //vesselNow.remove(0);

        }
      }
    }

    Label { Layout.fillHeight: true; } // Empty Filler

    // Captain's indicating fish speed and direction

    InfoDirectionMagnitude {
      id: fish_input;
      Layout.alignment: Qt.AlignRight;
      Layout.bottomMargin: 20;
      entity: "\ue850"; // fish-2
      description: qsTr("Captain's prediction of fish speed and course over ground");
      unit: "kn";
      colorFont: root.manaulFishCtrl ? root.fishColor : Material.color(Material.Grey);
      magnitude: infotain.toKnots(fishSpeedPred.value);
      orientation: fishCoursePred.value;
      extra: isNaN(fishDepthPred.value) ? "-" :
        Number(fishDepthPred.value).toLocaleString(Qt.locale(), 'f', 0) + " m";

      //visible: root.manualFishCtrl;
    }

    ColumnLayout {
      Layout.alignment: Qt.AlignCenter;
      Layout.bottomMargin: 10;
      RowLayout {
        ColumnLayout {
          RowLayout {
            Label { text: qsTr("Course"); }
            Slider {
              id: fishCoursePred;
              from: 0;
              value: 0;
              to: 360;
              stepSize: 2;
              snapMode: Slider.SnapOnRelease;
            }
          }
          RowLayout {
            Label { text: qsTr("Speed"); }
            Slider {
              id: fishSpeedPred;
              from: 0.05;
              value: 2;
              to: 4;
              stepSize: 0.05;
              snapMode: Slider.SnapOnRelease;
            }
          }
          RowLayout {
            Label { text: qsTr("Depth"); }
            Slider {
              id: fishDepthPred;
              from: 0;
              value: 50;
              to: 120;
              stepSize: 1;
              snapMode: Slider.SnapOnRelease;
            }
          }
        }
        ColumnLayout {

          Label {
            font: fkinStyle.iconFontHuge;
            text: "\ue850"; // fish
            color: root.manualFishCtrl ? root.fishColor : Material.color(Material.Grey);
            Layout.alignment: Qt.AlignCenter;
            property string toolTipText: qsTr("Manual fish input");
            ToolTip.text: toolTipText;
            ToolTip.visible: toolTipText ? ma_fish.containsMouse : false;
            MouseArea {
              id: ma_fish;
              anchors.fill: parent;
              hoverEnabled: true;
            }
          }
          Switch {
            id: manualFish; rotation: 270;
            Layout.alignment: Qt.AlignCenter;

            onToggled:
            {
              if(checked)
                fish_input.colorFont = root.fishColor;
              else
                fish_input.colorFont = Material.color(Material.Grey);

            }
          }
        }
      }
    }

    InfoPlanning {
      id: plan;
      entity: "\uf020"; // ef8a
      title: qsTr("Path Planner");
      description: qsTr("Duration since new path");
      running: root.plannerRunning;
      down: false;
      expected: 4000; // expected period of optimization

      Connections {
        target: root;
        onTriggerReset: plan.reseted();
      }

    }

    RowLayout {
      FkinDecisionIndicator {
        id: recommendedRotIndicator;

        value: vessel_rot_desired.val;
        running: root.plannerRunning;
        entity: "\ue81b"; // ship-wheel
        description: qsTr("Recommended rate of turn, deg/sec");
        unit: " \u00b0/s";
      }


      FkinDecisionIndicator {
        id: recommendedSettingTime;
        entity: "\uebb1"; // cannon-firing, \ueeca :bullet
        description: qsTr("Countdown to deploy");
        unit: "";
        running: root.plannerRunning;

        Connections {
          target: vessel_deploy_time;
          onValChanged:
          {
            recommendedSettingTime.count = val;
          }
        }
        property double count: 0;
        valueText: !root.plannerRunning ? "00:00" :
          new Date(recommendedSettingTime.count*1000).toLocaleTimeString(
            Qt.locale(), "mm:ss");

        Timer {
          id: settingTimer;
          interval: 500;
          running: root.plannerRunning;
          repeat: true;
          onTriggered:
          {
            recommendedSettingTime.count = recommendedSettingTime.count - settingTimer.interval/1000;
            if(recommendedSettingTime.count < 0){
              recommendedSettingTime.count = 0;
            }
          }
        }
      }
    }

    RowLayout {
      Layout.alignment: Qt.AlignCenter;
      id: keeper;
      property bool keepIt: false;
      DdsBitPublisher {
        id: keepSuggestion;
      }
      Button {
        id: keepTrajectory;
        text: keeper.keepIt ? qsTr("Reject") : qsTr("Keep");
        Layout.fillWidth: false;
        onClicked: {
          keepSuggestion.signal = !keeper.keepIt;
          keeper.keepIt = !keeper.keepIt;
        }
      }
    }

    RowLayout {
      id: mapPosition;
      Label {
        text: "\uef8a";
        font: fkinStyle.iconFontBig;
        Layout.rightMargin: 10;
      }
      Label {
        font: fkinStyle.numberFont;
        text: isNaN(vesselNED.ned.value.x) || !root.mouseActive ? "" :
          Number(root.mouseTip.y - vesselNED.ned.value.x).toLocaleString(
            Qt.locale(),'f', 0) + ", " +
          Number(root.mouseTip.x - vesselNED.ned.value.y).toLocaleString(
            Qt.locale(),'f', 0) + " m";
        Layout.preferredWidth: 200;
      }
      Label {
        font: fkinStyle.numberFont;
        text: isNaN(vesselNED.ned.value.x) || !root.mouseActive ? "" :
          qsTr("Distance: ") + Number(Qt.vector2d(root.mouseTip.y - vesselNED.ned.value.x,
                             root.mouseTip.x - vesselNED.ned.value.y).length())
          .toLocaleString(Qt.locale(),'f', 0) + " m";
      }
    }
  }
}

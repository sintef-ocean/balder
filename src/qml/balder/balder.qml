import QtQuick 2.11
import QtQuick.Window 2.11
import QtQuick.Layouts 1.11
import QtQuick.Controls 2.4
import QtQuick.Controls.Material 2.4
import QtCharts 2.2

import fkin.Dds 1.0
import "fkinHelpers.js" as Fkin
import ratatosk 1.0

/// Main application for *balder*, which are loaded by Qt on startup.
QtObject {

  /// Variable holding the main ApplicationWindow instance.
  property var applicationWindow: ApplicationWindow {
    id: window;
    title: qsTr("Balder");
    width: 1440;    //Screen.width;
    height: 1080;   //Screen.height;
    font : style.defaultFont;
    visible: false;
    FkinStyle { id: style; }
    property alias ddsParticipant: dds_.participant;

    Item {
      id: dds_;
      property alias participant: participant_;

      FkinDdsTopics { id: topic; }

      QtToDds {
        id: participant_;
        readonly property int domain: 0;


        Component.onCompleted: {
          init(domain);

          // DDS for program commands and state
          mimirCmdPurse.sub.init(participant_, topic.commands, topic.idPursePlanner);
          mimirCmdPurse.pub.init(participant_, topic.commands, topic.idPursePlanner, topic.commandResponses, 5000);
          mimirCmdLeadline.sub.init(participant_, topic.commands, topic.idLeadline);
          mimirCmdLeadline.pub.init(participant_, topic.commands, topic.idLeadline, topic.commandResponses, 2000);
          mimirCmdPurse.state.init(participant_, topic.stateNotifications, topic.idPursePlanner);
          mimirCmdLeadline.state.init(participant_, topic.stateNotifications, topic.idLeadline);
          mimirNlpInfo.init(participant_, 50, topic.purseConfig, topic.purseStats, topic.idPursePlanner);

          dashTab.init(participant_);
          seriesTab.init(participant_);

          configurationTab.init(participant_);

        }
      }
    }

    header: TabBar {
      id: navbar;
      width: parent.width;
      TabIconButton { text: qsTr("Map plot"); iconText: "\uef8b"; }
      TabIconButton { text: qsTr("Time series"); iconText: "\ue980"; }
      TabIconButton { text: qsTr("Config"); iconText: "\uf014"; }
      TabIconButton { text: qsTr("Algorithms"); iconText: "\ueea9"; }
      currentIndex: 0;

      Action {
      id: copyAction;
      text: "&Doc";
      shortcut: StandardKey.HelpContents;
      onTriggered: Qt.openUrlExternally(Qt.resolvedUrl("file:///" + AppPath + "/../share/doc/balder/html/index.html"));
      }
    }

    StackLayout {
      id: stack;
      currentIndex: navbar.currentIndex;
      property int margins: 20;
      anchors.fill: parent;
      anchors.margins: margins;

      ScrollView {
        id: dashScroll;
        Layout.preferredWidth: stack.width;
        clip: true;
        FkinPurseDashboard {
          id: dashTab;
          //Layout.preferredWidth: stack.width;
          width: dashScroll.availableWidth;
          plannerRunning: mimirCmdPurse.state.state == FKIN.RUNNING;
          ddsInitialized: window.ddsParticipant.initialized;

          Connections {
            target: mimirCmdPurse.state;
            onStateChanged: dashTab.triggerReset(); // path planner state changed (reset timer)
          }
        }
      }
      FkinTimeSeries {
        id: seriesTab;
        Layout.preferredWidth: stack.width;


      }
      ScrollView {
        id: configurationScroll;
        Layout.preferredWidth: stack.width;
        clip: true;
        FkinSettings {
          id: configurationTab;
          ddsInitialized: window.ddsParticipant.initialized;
          width: configurationScroll.availableWidth; //Math.max(implicitWidth, configurationScroll.availableWidth);

          Connections {
            target: configurationTab.themeChanger;

            onToggled:
            {
              if(configurationTab.themeChanger.checked)
                window.Material.theme = Material.Dark;
              else
                window.Material.theme = Material.Light;

              mimirNlpInfo.themeChanged();
              dashTab.themeChanged();
              seriesTab.themeChanged();
              // add more components that are affected by themeChanger

            }
          }
        }
      }
      ScrollView {
        id: nlpOverviewTab;
        Layout.preferredWidth: stack.width;
        clip: true;
        ColumnLayout {
          width: Math.max(implicitWidth, nlpOverviewTab.availableWidth);
          Layout.alignment: Qt.AlignTop;

          Connections {
            target: programGroup;
            Component.onCompleted: {
              programGroup.programs.push(mimirCmdPurse);
              programGroup.programs.push(mimirCmdLeadline);
              // push more controlled programs here.
            }
          }

          RowLayout {
            Layout.bottomMargin: 10;
            Label { text: qsTr("Decision Support"); Layout.rightMargin: 20; }
            RemoteProgramGroup{ id: programGroup; }
          }
          RemoteProgramCommands {
            id: mimirCmdPurse;
            program_name: qsTr("Purse Planner");
          }
          RemoteProgramCommands {
            id: mimirCmdLeadline;
            program_name: qsTr("Leadline");
          }
          NlpInfo {
            id: mimirNlpInfo;
            plotHeight: 320;
            program_name: qsTr("Purse Planner");
          }
        }
      }

    }
    footer: FkinFooter{ id: fkinFooter; }

    Component.onCompleted: splashWindow.timerRun = true;


  }

  /// Splash window showing logo on startup.
  property var splashWindow: Splash {
    onTimeout:
    {
      splashWindow.visible = false;
      applicationWindow.visible = true;
    }
  }
}

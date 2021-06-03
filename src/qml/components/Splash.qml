import QtQuick 2.11
import QtQuick.Window 2.11

/// Splash window for that shows project logo
Window {
  id: splash;
  property int timeoutInterval: 500; ///< Duration of visible splash screen.
  property int frameBorder: 50; ///< Frame border size pixels.
  property alias timerRun: timer.running; ///< Alias for timer.running boolean.
  signal timeout; ///< Signal indicating that splash window visibility is done.

  title: "Splash Window"; ///< Window title.
  modality: Qt.ApplicationModal; ///< Blocks input to all windows.
  flags: Qt.SplashScreen; ///< Flag indicating that the window is a splash screen.
  width: splashImage.width + frameBorder; ///< Width of splash image plus frame border.
  height: splashImage.height + frameBorder; ///< Height of splash image plus frame border.
  x: (Screen.width - splashImage.width + frameBorder) / 2; ///< Placement of splash image along screen width axis.
  y: (Screen.height - splashImage.height + frameBorder) / 2; ///< Placement of splash image along screen height axis.
  color: "#303030"; // Undocumentable entity (bug in doxyqml?)
  ///

  /// Component that holds the splash image
  Image {
    id: splashImage;
    source: "icons/LogoFkinNegative.png";
    anchors.centerIn: parent;
  }

  /// Timer that hides splash screen and signals timeout()
  Timer {
    id: timer;
    interval: timeoutInterval;
    running: false;
    repeat: false;
    onTriggered:
    {
      visible = false;
      splash.timeout();
    }
  }

  /// \brief callback: onCompleted, shows splash screen
  Component.onCompleted: { visible = true; }

}

//pragma Singleton
import QtQuick 2.11
import QtQuick.Controls 2.4
import QtQuick.Controls.Material 2.4
import QtCharts 2.2

/// Component to hold common styling
Item {

  //TODO: usage of this should probably be a singleton available everywhere it is used

  /// Default font
  readonly property string fontFamily: "Oswald"; // Or Public Sans
  /// QtChart theme, which is ChartView.ChartTheme{Light,Dark} in sync with Material.{Light,Dark}
  property int chartTheme: {
    Material.theme == Material.Light ? ChartView.ChartThemeLight : ChartView.ChartThemeDark; }
  /// Default font with pointSize 20
  property font defaultFont: Qt.font({ family: fontFamily, pointSize: 20, weight: Font.Medium });
  /// Plot font with pointSize 19
  property font plotFont:    Qt.font({ family: fontFamily, pointSize: 19, weight: Font.Medium });
  /// Date font with pointSize 19
  property font dateFont:    Qt.font({ family: fontFamily, pointSize: 19, weight: Font.Medium });
  /// Number font with pointSize 25
  property font numberFont:  Qt.font({ family: fontFamily, pointSize: 25, weight: Font.Medium });
  /// Icon font (default: IcoFont), pointSize 22
  property font iconFont: Qt.font({ family: "IcoFont", pointSize: 22, weight: Font.Medium });
  /// Icon font (default: IcoFont), pointSize 25
  property font iconFontBig: Qt.font({ family: "IcoFont", pointSize: 25, weight: Font.Medium });
  /// Icon font (default: IcoFont), pointSize 35
  property font iconFontHuge: Qt.font({ family: "IcoFont", pointSize: 35, weight: Font.Medium });

  /// PointSize +3 from default font point size
  property real largerPoints: defaultFont.pointSize + 3;
  /// PointSize -3 from default font point size
  property real smallerPoints: defaultFont.pointSize - 3;
  /// Default line color, which is Material.Teal
  property color defaultLineColor: Material.color(Material.Teal, Material.Shade500);

}

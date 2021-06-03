#include <QtGlobal>
#include <QLoggingCategory>
#include <QApplication>
#include <QCommandLineParser>
#include <QDir>
#include <QFontDatabase>
#include <QTranslator>
#include <QQmlEngine>
#include <QQmlComponent>
#include <QQmlContext>
#include <QQuickWindow>
#include <QUrl>
#include <QDebug>

#include <cstdlib>
#include <iostream>
#include <vector>

#include "sinspekto/SinspektoQml.hpp"

void PrintBanner()
{
  std::vector<std::string> banner;
  banner.push_back("  ____        _     _            ");
  banner.push_back(" |  _ \\      | |   | |          ");
  banner.push_back(" | |_) | __ _| | __| | ___ _ __  ");
  banner.push_back(" |  _ < / _` | |/ _` |/ _ \\ '__|");
  banner.push_back(" | |_) | (_| | | (_| |  __/ |    ");
  banner.push_back(" |____/ \\__,_|_|\\__,_|\\___|_| ");

  for (auto &line : banner)
    std::cout << line << std::endl;
}

int main(int argc, char *argv[])
{

  // We are using old connection syntax to support 5.12 and older
  // This suppresses the warning for Qt 5.15
  // If only newer Qt is to be supported, refactoring should be done
  // https://doc.qt.io/qt-5/qml-qtqml-connections.html
#if QT_VERSION > QT_VERSION_CHECK(5, 15, 0)
  QLoggingCategory::setFilterRules("qt.qml.connections=false");
#endif


  QApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#if QT_VERSION >= QT_VERSION_CHECK(5, 14, 0)
  QGuiApplication::setHighDpiScaleFactorRoundingPolicy(Qt::HighDpiScaleFactorRoundingPolicy::PassThrough);
#endif
  QApplication app(argc, argv);
  app.setOrganizationName("SINTEF Ocean");
  app.setApplicationName("Balder");

  qint32 fontId = QFontDatabase::addApplicationFont(":/fonts/PublicSans-VariableFont_wght.ttf");
  QFontDatabase::addApplicationFont(":/fonts/icofont/fonts/icofont.ttf");
  fontId = QFontDatabase::addApplicationFont(":/fonts/Oswald-VariableFont_wght.ttf");
  QStringList fontList = QFontDatabase::applicationFontFamilies(fontId);
  QString family = fontList.at(0);
  //std::cout << "Using font " << family.toStdString() << std::endl;
  QApplication::setFont(QFont(family));


  QTranslator translator;
  QCommandLineParser parser;
  parser.setApplicationDescription("Balder: graphical user interface for purse seine decision support");
  parser.addHelpOption();

  QCommandLineOption selectLanguage(QStringList() << "l" << "language",
                                    QApplication::tr("Select displayed language <language>"),
                                    QApplication::tr("language"));

  selectLanguage.setDefaultValue("no");
  parser.addOption(selectLanguage);
  parser.process(app);
  QString lang = parser.value(selectLanguage);

  PrintBanner();

  bool translationLoaded = false;

  if (lang.compare("no", Qt::CaseInsensitive) == 0
      || lang.compare("norwegian", Qt::CaseInsensitive) == 0
      || lang.compare("norsk", Qt::CaseInsensitive) == 0)
    {
      std::cout << "Loading Norwegian" << std::endl;
      translationLoaded = translator.load(":/fkin_no");
    }
  else if (lang.compare("en", Qt::CaseInsensitive) == 0
           || lang.compare("english", Qt::CaseInsensitive) == 0)
    {
      std::cout << "Loading English" << std::endl;
      translationLoaded = translator.load(":/fkin_en");
    }

  if(!translationLoaded)
    std::cerr << "No translation applied" << std::endl;
  else
    app.installTranslator(&translator);

#if defined(_WIN64) || defined(_WIN32)

  auto ospl_uri = qEnvironmentVariable("OSPL_URI");
  auto ospl_home = qEnvironmentVariable("OSPL_HOME");
  auto program_dir = QCoreApplication::applicationDirPath();

  qInfo() << "OSPL_HOME is: " << ospl_home;
  qInfo() << "program directory is: " << program_dir;

  if(ospl_uri.isEmpty()){
    ospl_uri = "file://" + QDir::toNativeSeparators( program_dir + "/ospl.xml" );
    qInfo() << "Setting OSPL_URI " << ospl_uri;
    auto did_ospl_uri = qputenv("OSPL_URI", ospl_uri.toLocal8Bit());
    if(!did_ospl_uri)
       qInfo() << "Setting OSPL_URI failed, program will not work properly";
  }

  if(ospl_home.isEmpty()){
    ospl_home = program_dir + "/";// QDir::toNativeSeparators( program_dir );
    qInfo() << "Setting OSPL_HOME " << ospl_home;
    auto did_ospl_home = qputenv("OSPL_HOME", ospl_home.toLocal8Bit());
    if(!did_ospl_home)
       qInfo() << "Setting OSPL_HOME failed, program will not work properly";
  }

#endif


  sinspekto::LoadSinspektoQmlTypes();
  QQmlEngine engine;
  // engine.addImportPath("qrc:///"); // qmldir, WIP,
  // https://doc.qt.io/qt-5/qtqml-modules-qmldir.html
  // https://stackoverflow.com/questions/31726321/load-qmldir-from-qrc-file
  // https://stackoverflow.com/questions/54551128/how-to-import-qml-singleton
  QQmlComponent component(&engine);
  QQuickWindow::setDefaultAlphaBuffer(true);

  engine.rootContext()->setContextProperty("AppPath", QString(QCoreApplication::applicationDirPath()));
  // Should set doc path here, if not found, alternative.

  component.loadUrl(QUrl(QStringLiteral("qrc:/balder.qml")));

  if (component.isReady() )
    component.create();
  else
    qWarning() << component.errorString();

  return app.exec();

}

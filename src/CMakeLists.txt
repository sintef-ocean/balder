
# ===================================
# Set up language-aware program

# Currently not supported for ANDROID

if(NOT ANDROID)
  qt5_create_translation(QM_FILES ${CMAKE_CURRENT_SOURCE_DIR}/qml/balder.qrc
    ${PROJECT_SOURCE_DIR}/data/languages/fkin_en.ts
    ${PROJECT_SOURCE_DIR}/data/languages/fkin_no.ts)

  set(TS_FILES
    ${PROJECT_SOURCE_DIR}/data/languages/fkin_en.ts
    ${PROJECT_SOURCE_DIR}/data/languages/fkin_no.ts)
  qt5_add_translation(QM_FILES ${TS_FILES})

  # You need to manually translate files with $> linguist shovel_*.ts
  # Note: Beware that 'make clean' deletes the *.ts files

  # Resources are found relative to its .qrc file.
  # qm-files are the binary directory, this copies .qrc to the binary directory
  configure_file(${PROJECT_SOURCE_DIR}/data/translations.qrc ${CMAKE_BINARY_DIR}/src COPYONLY)

  # since qml-resources listed in the ${RESOURCES} files are not explicit dependencies,
  # they will not be picked up by this.. You must edit one file in ${RESOURCES}
  # for *.ts files (qt5_create_translation to be re-run).
  #add_custom_target(translations ALL DEPENDS ${QM_FILES})
  #add_custom_target(trans_resrc ALL DEPENDS ${RESOURCES})
  #add_dependencies(trans_resrc translations)
endif()

#======================================
# Balder Application

set(RESOURCES
  qml/balder.qrc
  ${PROJECT_SOURCE_DIR}/data/qtresources.qrc)

if(WIN32)
  set(RESOURCES ${RESOURCES} ${PROJECT_SOURCE_DIR}/data/app.rc)
  if(NOT WITH_CONSOLE)
    set(BALDER_WIN32 WIN32)
  endif()
endif()

set(HUMAN_APP_NAME balder)
set(BALDER_APP_NAME ${HUMAN_APP_NAME} PARENT_SCOPE)
set(APP_NAME balder)

set(PROG_FILES
  programs/balder/balder.cpp
  )

if(ANDROID)

  add_library(${APP_NAME} SHARED
    ${PROG_FILES}
    ${RESOURCES})
    #${CMAKE_BINARY_DIR}/src/translations.qrc
    #${QM_FILES})

  FetchContent_MakeAvailable(qt-android-cmake)

  add_qt_android_apk(BalderAPK ${APP_NAME}
    NAME "Balder"
    VERSION_CODE 1
    PACKAGE_NAME "no.fkin.balder"
    PACKAGE_SOURCES ${CMAKE_SOURCE_DIR}/data/android
    KEYSTORE ${CMAKE_SOURCE_DIR}/data/balder.keystore
    KEY_ALIAS balder_app
    KEYSTORE_PASSWORD balderblaa
    DEPENDS ${ODIN_LIB_PATHS}
    ${BALDER_INSTALL})

  set(BALDER_EXTRA_TARGETS Qt5::AndroidExtras log)

else()

  add_executable(${APP_NAME} ${BALDER_WIN32}
    ${PROG_FILES}
    ${RESOURCES}
    ${CMAKE_BINARY_DIR}/src/translations.qrc
    ${QM_FILES}
    )

  # CMAKE_DEBUG_POSTFIX does not apply to executable targets, so:
  set_target_properties(${APP_NAME}
    PROPERTIES
      DEBUG_POSTFIX ${CMAKE_DEBUG_POSTFIX})

  install(TARGETS ${APP_NAME}
    RUNTIME
      COMPONENT runtime
      DESTINATION ${CMAKE_INSTALL_BINDIR})

endif()

target_include_directories(${APP_NAME}
  PUBLIC
    $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/include>
  PRIVATE
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>)

target_link_libraries(${APP_NAME} PRIVATE
  Qt5::Widgets
  Qt5::Quick
  #Qt5::Qml
  #Qt5::Charts
  #PkgConfig::Qwt
  sinspekto::sinspekto
  ${BALDER_EXTRA_TARGETS})


if(UNIX AND NOT APPLE)
  install(FILES ${CMAKE_SOURCE_DIR}/data/ospl/ospl.xml
    COMPONENT runtime
    DESTINATION ${CMAKE_INSTALL_DATADIR})
  install(FILES ${CMAKE_SOURCE_DIR}/data/ospl/ospl_metaconfig.xml
    COMPONENT runtime
    DESTINATION lib/etc)

  configure_file(${PROJECT_SOURCE_DIR}/data/template.desktop ${APP_NAME}.desktop)

  file(COPY ${CMAKE_CURRENT_BINARY_DIR}/${APP_NAME}.desktop
    DESTINATION ${CMAKE_CURRENT_BINARY_DIR}
    FILE_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
    )

  install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${APP_NAME}.desktop
    COMPONENT runtime
    DESTINATION ${CMAKE_INSTALL_DATADIR}/applications)

elseif(WIN32 AND NOT UNIX)

  install(FILES
    ${CMAKE_SOURCE_DIR}/data/ospl/ospl.xml
    ${CMAKE_SOURCE_DIR}/data/ospl/ospl_metaconfig.xml
    ${CMAKE_SOURCE_DIR}/data/ospl/ospl_env.bat
    COMPONENT runtime
    DESTINATION
    ${CMAKE_INSTALL_BINDIR})

endif()

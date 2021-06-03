cmake_minimum_required(VERSION 3.13)

set(THE_PROJECT_AUTHOR "Joakim Haugen")
set(THE_PROJECT_MAINTAINER "SINTEF Ocean <joakim.haugen@sintef.no>")
set(THE_PROJECT_VENDOR "SINTEF Ocean")

file(STRINGS "${CMAKE_SOURCE_DIR}/version.txt" projectVersion)

find_package(kluster-scripts CONFIG QUIET)

if(kluster-scripts_FOUND)
  # Use git tag and synchronize version.txt
  kluster_get_version_from_git(projectTagVersion ${projectVersion})
  kluster_use_version(${projectTagVersion} "${CMAKE_SOURCE_DIR}/version.txt" projectVersion)
endif()

project(
  balder
  VERSION ${projectVersion}
  LANGUAGES CXX
  DESCRIPTION "Purse Seine deploy decision support")

option(WITH_DOC     "Build documentation target" OFF)
option(WITH_CONSOLE "With console output on windows (Qt WIN32 on executable)" ON)
option(WITH_INSTALL "Auto install to emulator (android)" OFF)
option(WITH_API_DOC "Build API documentation" ON)


if(WITH_INSTALL)
  set(BALDER_INSTALL INSTALL) # Install to emulator (android)
endif()

# Qt-specific convenience:
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
# Qt preset AUTORCC for all targets. Executes rcc on *.qrc files. add_executable(x x.cpp
# rsrc.qrc). CMAKE_AUTORCC_OPTIONS set(CMAKE_INCLUDE_CURRENT_DIR ON) # Let generated files
# that are put the build dir to be included when compiling. CMake>3.7: not necessary for
# Qt-generated any more.

# https://cliutils.gitlab.io/modern-cmake/chapters/features/cpp11.html
# should be set as target properties instead
set(CMAKE_CXX_EXTENSIONS OFF) # Disable compiler flag extension (use -std=c++11 instead of -std=gnu++11)
set(CMAKE_CXX_STANDARD 17) # The default CXX_STANDARD (resolves to a flag -std=c++17)..
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_DEBUG_POSTFIX "_d" CACHE STRING "Generate debug library name with a postfix.")
set(CMAKE_POSITION_INDEPENDENT_CODE ON) # -fPIC by default

if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
  add_compile_options("-Wall" "-Wextra" "-Wpedantic" "-Werror")
  add_compile_options("-Wno-parentheses")
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
  add_compile_options("/W4" "/WX")
  add_compile_options("/wd4251")
  add_compile_options("/wd4127")
  add_definitions("-D_SCL_SECURE_NO_WARNINGS" "-D_CRT_SECURE_NO_WARNINGS")
  add_definitions("-D_SILENCE_CXX17_ITERATOR_BASE_CLASS_DEPRECATION_WARNING")
endif()

if(DEFINED ENV{ANDROID_ABI})
  message(STATUS "ANDROID_ABI defined, setting ANDROID ON")
  set(ANDROID ON CACHE INTERNAL "Enabled ANDROID")
endif()

# Conan setup
if(EXISTS ${CMAKE_BINARY_DIR}/conanbuildinfo.cmake)
  include(${CMAKE_BINARY_DIR}/conanbuildinfo.cmake)
  conan_basic_setup()
  set(BALDER_CONAN ON)
elseif(ANDROID)
  message(FATAL_ERROR "Using Conan is required when building for Android")
else()
  message(STATUS "Configuring without Conan, did you forget 'conan install'?")
  # Use bundled FindOpenSplice
  list(INSERT CMAKE_MODULE_PATH 0 "${CMAKE_CURRENT_SOURCE_DIR}/cmake")
  if(GENERATOR_IS_MULTI_CONFIG)
    message(STATUS "NOTE: Adjusting output directories: Multi-configuration (Release and Debug) builds will replace each other")
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/bin)
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/lib)
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_RELEASE ${CMAKE_RUNTIME_OUTPUT_DIRECTORY})
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_RELEASE ${CMAKE_LIBRARY_OUTPUT_DIRECTORY})
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_DEBUG ${CMAKE_RUNTIME_OUTPUT_DIRECTORY})
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_DEBUG ${CMAKE_LIBRARY_OUTPUT_DIRECTORY})
  endif()
endif()

include(FetchContent)
include(cmake/OdinHelpers.cmake)

if(ANDROID)
  odin_prepare_for_android()
  set(BALDER_EXTRAS AndroidExtras)
else()
  set(BALDER_EXTRAS LinguistTools)
endif()

find_package(Qt5 5.11 CONFIG COMPONENTS Widgets Qml Quick Charts ${BALDER_EXTRAS} REQUIRED)
find_package(sinspekto 0.4.0 CONFIG REQUIRED)
find_package(kluster-scripts CONFIG QUIET) # For CICD

if(ANDROID)
  # used to find transitive dependencies to bundle
  find_package(qt MODULE REQUIRED)
endif()

# -------------------------------------------------------------------
#  Library targets to bundle

if (ANDROID)
  # qt::qt bundles libcrypto and libssl
  # They cause conflict with system installed libcrypto(?); need to be skipped
  # Other may cause problems down the line: libssl, libjpeg, libz
  # BEWARE DANGER

  list(APPEND _depTargets "sinspekto::sinspekto")
  list(APPEND _depTargets "qt::qt")
  list(APPEND _skipLibs "libssl.so;libcrypto.so")

endif()

if (WIN32 AND NOT UNIX)
  list(APPEND _depTargets  "sinspekto::sinspekto")
endif()

list(APPEND _depTargets
  "OpenSplice::isocpp2;OpenSplice::durability;OpenSplice::ddsi2;OpenSplice::spliced")

message(STATUS "Finding extra libraries to bundle..")
message(STATUS "Skip list: ${_skipLibs}")
message(STATUS "Dependent targets: ${_depTargets}")

odin_bundle_paths(TARGETS ${_depTargets} SKIP "${_skipLibs}")
# ODIN_LIB_PATHS variable contains paths to libraries to bundle with application

message(STATUS "ODIN_LIB_PATHS to bundle:")
foreach(balder_item IN ITEMS ${ODIN_LIB_PATHS})
  message(STATUS "  ${balder_item}")
endforeach()

# --------------------------------------------------------------------
#  Libraries, export targets and install files

include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

set(INSTALL_CONFIGDIR ${CMAKE_INSTALL_LIBDIR}/cmake/${CMAKE_PROJECT_NAME})

add_subdirectory(src)

if(WITH_DOC)
  add_subdirectory(docs)
  set(BALDER_DOC doc)
endif()

install(FILES LICENSE
  COMPONENT dev
  DESTINATION ${CMAKE_INSTALL_DATADIR}/${PROJECT_NAME})

install(FILES data/icons/FkinLogo.png
  COMPONENT runtime
  DESTINATION ${CMAKE_INSTALL_DATADIR}/${PROJECT_NAME})

# --------------------------------------------------------------------
# Packaging

if(NOT ANDROID)

  string(TOLOWER ${CMAKE_CXX_COMPILER_ID} COMPILER)
  set(COMPILER_VERSION ${CMAKE_CXX_COMPILER_VERSION})
  string(REPLACE "." ";" comp_list "${COMPILER_VERSION}")

  list(GET comp_list 0 COMP_MAJOR)
  #list(GET comp_list 1 COMP_MINOR) # no need for gnu > 6, but what about other compilers?

  set(COMPILER ${COMPILER}-${COMP_MAJOR})

  if(CMAKE_SYSTEM_PROCESSOR STREQUAL "x86_64" OR CMAKE_SYSTEM_PROCESSOR STREQUAL "AMD64")
    set(ARCHITECTURE amd64)
  elseif(CMAKE_SYSTEM_PROCESSOR STREQUAL "arm64")
    set(ARCHITECTURE arm64)
  elseif(CMAKE_SYSTEM_PROCESSOR STREQUAL "armv7l")
    set(ARCHITECTURE armhf)
  else()
    set(ARCHITECTURE i386)
  endif()

  set(THE_PACKAGE_LINUX_INSTALL_PREFIX /usr/local)
  set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "${PROJECT_DESCRIPTION}")
  set(CPACK_PACKAGE_VENDOR "${THE_PROJECT_VENDOR}")
  set(CPACK_PACKAGE_DESCRIPTION_FILE "${CMAKE_CURRENT_SOURCE_DIR}/README.org")
  set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_CURRENT_SOURCE_DIR}/LICENSE")

  set(CPACK_PACKAGE_VERSION_MAJOR ${PROJECT_VERSION_MAJOR})
  set(CPACK_PACKAGE_VERSION_MINOR ${PROJECT_VERSION_MINOR})
  set(CPACK_PACKAGE_VERSION_PATCH ${PROJECT_VERSION_PATCH})
  set(CPACK_DEBIAN_PACKAGE_VERSION
    ${CPACK_PACKAGE_VERSION_MAJOR}.${CPACK_PACKAGE_VERSION_MINOR}.${CPACK_PACKAGE_VERSION_PATCH})

  set(CPACK_PACKAGE_FILE_NAME
    ${CMAKE_PROJECT_NAME}-${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}.${PROJECT_VERSION_PATCH}-${ARCHITECTURE})
  set(THE_PACKAGE_FILE_NAME ${CPACK_PACKAGE_FILE_NAME}) # needed, since include CPack changes things

  set(CPACK_DEB_COMPONENT_INSTALL ON)
  set(CPACK_COMPONENTS_ALL runtime ${BALDER_DOC})
  set(CPACK_COMPONENT_RUNTIME_DESCRIPTION "${PROJECT_DESCRIPTION} - runtime")
  if(WITH_DOC)
    set(CPACK_COMPONENT_DOC_DESCRIPTION "${PROJECT_DESCRIPTION} - documentation")
  endif()

  # -------------------------
  # --- WINDOWS packaging ---
  if(WIN32 AND NOT UNIX)

    find_program(WINDEPLOYQT_EXECUTABLE windeployqt REQUIRED DOC "Qt resource bundler")
    # message(WARNING "windeployqt: ${WINDEPLOYQT_EXECUTABLE}")
    add_custom_target(bundle ALL
      COMMAND ${WINDEPLOYQT_EXECUTABLE} ${BALDER_APP_NAME}${CMAKE_EXECUTABLE_SUFFIX}
      --qmldir ${CMAKE_CURRENT_SOURCE_DIR}/src
      --no-compiler-runtime
      --verbose 0
      COMMAND ${CMAKE_COMMAND} -E copy ${ODIN_LIB_PATHS} ${CMAKE_BINARY_DIR}/bin
      WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/bin
      COMMENT "Deploy Qt dependencies into binary directory for ${BALDER_APP_NAME}"
      )
    add_dependencies(bundle ${BALDER_APP_NAME})

    install(DIRECTORY ${CMAKE_BINARY_DIR}/bin/
      COMPONENT runtime
      DESTINATION ${CMAKE_INSTALL_BINDIR}
      USE_SOURCE_PERMISSIONS
      PATTERN "${BALDER_APP_NAME}${CMAKE_EXECUTABLE_SUFFIX}" EXCLUDE
      )

    # https://blog.nathanosman.com/2017/11/24/using-windeployqt-with-cpack.html
    set(CMAKE_INSTALL_UCRT_LIBRARIES TRUE)
    include(InstallRequiredSystemLibraries)

    set(CPACK_GENERATOR "NSIS;TGZ")
    set(CPACK_PACKAGE_INSTALL_DIRECTORY ${CMAKE_PROJECT_NAME}-${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR})
    set(CPACK_SOURCE_PACKAGE_FILE_NAME ${CMAKE_PROJECT_NAME}-${VERSION_NUMBER})
    set(CPACK_NSIS_DISPLAY_NAME  "${CPACK_PACKAGE_INSTALL_DIRECTORY}")
    set(CPACK_NSIS_MUI_ICON "${CMAKE_SOURCE_DIR}/data/icons/icon.ico")
    set(CPACK_NSIS_MODIFY_PATH ON)
    set(CPACK_NSIS_CONTACT "${THE_PROJECT_MAINTAINER}")
    set(CPACK_PACKAGE_EXECUTABLES "${BALDER_APP_NAME}" "${CMAKE_PROJECT_NAME}" )
    set(CPACK_CREATE_DESKTOP_LINKS "${BALDER_APP_NAME}")
    set(CPACK_NSIS_INSTALLED_ICON_NAME bin\\\\${BALDER_APP_NAME}.exe)

    if(WITH_DOC)
      set(CPACK_NSIS_MENU_LINKS
        "share/doc/${CMAKE_PROJECT_NAME}/html/index.html" "Balder Documentation")
    endif()

  # ---------------------------
  # --- LINUX packaging deb ---
  else(WIN32 AND NOT UNIX)

    set(CPACK_GENERATOR "DEB;TGZ")
    set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE ${ARCHITECTURE})
    set(CPACK_DEBIAN_PACKAGE_MAINTAINER "${THE_PROJECT_MAINTAINER}")
    set(CPACK_DEBIAN_PACKAGE_PRIORITY optional)
    set(CPACK_PACKAGING_INSTALL_PREFIX "${THE_PACKAGE_LINUX_INSTALL_PREFIX}")
    set(CPACK_DEBIAN_ENABLE_COMPONENT_DEPENDS ON)

    set(CPACK_DEBIAN_RUNTIME_PACKAGE_DEPENDS "\
    libqt5charts5, \
    libqt5core5a, \
    libqt5gui5, \
    libqt5qml5, \
    libqt5widgets5, \
    libqt5waylandclient5, \
    qml-module-qtcharts, \
    qml-module-qtquick2, \
    qml-module-qtquick-controls2, \
    qml-module-qtquick-layouts, \
    qml-module-qtquick-shapes, \
    qml-module-qtquick-window2, \
    qtwayland5, \
    sinspekto-runtime")

    if(BALDER_CONAN)
      # Because these are not the dependencies the library is built with (versions)
      unset(CPACK_DEBIAN_RUNTIME_PACKAGE_DEPENDS)
    endif()

  endif(WIN32 AND NOT UNIX)

  include(CPack)

endif()

# ----------------------
# --- LINUX AppImage ---

if(UNIX AND NOT APPLE AND NOT ANDROID)

  if(ARCHITECTURE STREQUAL "amd64")
    message(STATUS "Linuxdeploy for your architecture is supported")
    set(BALDER_APPIMAGE ON)
  else()
    message(WARNING "Linuxdeploy is only available for 'x86_64/amd64'")
    set(BALDER_APPIMAGE OFF)
  endif()

  if(BALDER_APPIMAGE)

    set(BALDER_DEPLOYER ${CMAKE_CURRENT_BINARY_DIR}/linuxdeploy.AppImage)

    FetchContent_Declare(
      linuxdeploy
      URL https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage
      DOWNLOAD_NO_EXTRACT TRUE
      DOWNLOAD_DIR ${CMAKE_CURRENT_BINARY_DIR}/tmp
      DOWNLOAD_NAME linuxdeploy.AppImage)

    FetchContent_MakeAvailable(linuxdeploy)
    file(COPY ${CMAKE_CURRENT_BINARY_DIR}/tmp/linuxdeploy.AppImage
      DESTINATION ${CMAKE_CURRENT_BINARY_DIR}
      FILE_PERMISSIONS OWNER_READ OWNER_EXECUTE GROUP_EXECUTE WORLD_EXECUTE
      )

    FetchContent_Declare(
      linuxdeploy-qt
      URL https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases/download/continuous/linuxdeploy-plugin-qt-x86_64.AppImage
      DOWNLOAD_NO_EXTRACT TRUE
      DOWNLOAD_DIR ${CMAKE_CURRENT_BINARY_DIR}/tmp
      DOWNLOAD_NAME linuxdeploy-plugin-qt-x86_64.AppImage)

    FetchContent_MakeAvailable(linuxdeploy-qt)
    file(COPY ${CMAKE_CURRENT_BINARY_DIR}/tmp/linuxdeploy-plugin-qt-x86_64.AppImage
      DESTINATION ${CMAKE_CURRENT_BINARY_DIR}
      FILE_PERMISSIONS OWNER_READ OWNER_EXECUTE GROUP_EXECUTE WORLD_EXECUTE
      )

    # Set variables to control deployment
    set(DESTDIR AppDir)
    set(QML_SOURCES_PATHS ${CMAKE_SOURCE_DIR}/src) # project qml dir
    set(BALDER_APPDIR ${CMAKE_CURRENT_BINARY_DIR}/${DESTDIR})

    if(NOT ${CMAKE_INSTALL_PREFIX} STREQUAL /usr)
      message(STATUS "CMAKE_INSTALL_PREFIX is: ${CMAKE_INSTALL_PREFIX}")
    endif()
    # Push install prefix, to use /usr, then pop
    set(BALDER_INSTALL_PREFIX ${CMAKE_INSTALL_PREFIX})

    if(CMAKE_VERSION VERSION_LESS 3.17)
      set(CMAKE_RM remove)
    else()
      set(CMAKE_RM rm)
    endif()

    # This target executes commands in a specific order
    # 1. Create directory so copying bundle libs for dlopen (opensplice)
    # 2. Install explicit dependencies from odin_bundle_paths ODIN_LIB_PATHS
    # 3. Install program to DESTDIR, including extra resources
    # 4. Install to DESTDIR with linuxdeploy and create appimage

    set(BALDER_APPIMAGE_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}-${PROJECT_VERSION}-x86_64.AppImage")
    add_custom_target(appimage DEPENDS ${BALDER_APPIMAGE_OUTPUT})

    add_custom_command(
      OUTPUT ${BALDER_APPIMAGE_OUTPUT}
      DEPENDS ${BALDER_APP_NAME}
      COMMAND ${CMAKE_COMMAND} -E make_directory ${BALDER_APPDIR}/usr/lib
      COMMAND
        ${CMAKE_COMMAND} -E copy ${ODIN_LIB_PATHS}
        ${BALDER_APPDIR}/usr/lib/
      COMMAND ${CMAKE_COMMAND} .. -DCMAKE_INSTALL_PREFIX=/usr
      COMMAND ${CMAKE_COMMAND} --build . --target install DESTDIR=${DESTDIR}
      COMMAND ${CMAKE_COMMAND} .. -DCMAKE_INSTALL_PREFIX=${BALDER_INSTALL_PREFIX}
      COMMAND ${CMAKE_COMMAND} -E ${CMAKE_RM} ${CMAKE_BINARY_DIR}/${DESTDIR}/usr/share/applications/balder.desktop
      COMMAND
        QML_SOURCES_PATHS=${QML_SOURCES_PATHS}
        OSPL_ENV_FILE=${CMAKE_SOURCE_DIR}/data/ospl/ospl_env.sh
        PATH=$ENV{PATH}:${CMAKE_SOURCE_DIR}/tools/scripts
        VERSION=${projectVersion}
        ${BALDER_DEPLOYER} --verbosity 1
          --appdir ${DESTDIR}
          --plugin qt
          --plugin ospl
          --output appimage
          --executable bin/${BALDER_APP_NAME}
          --desktop-file ${CMAKE_SOURCE_DIR}/data/${BALDER_APP_NAME}.desktop
          --icon-file ${CMAKE_SOURCE_DIR}/data/icons/FkinLogo.png
      WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})

    if(WITH_DOC)
      add_dependencies(appimage doc)
    endif()

  endif(BALDER_APPIMAGE)
endif()


#---------------------------------------------------------------------
# If kluster-scripts found, add upload, deliver, and deploy targets


if(kluster-scripts_FOUND AND ANDROID)
  set(THE_APK_PATH "src/${BALDER_APP_NAME}-${ANDROID_ABI}/build/outputs/apk/release")
  set(THE_APK_FILE_NAME "${BALDER_APP_NAME}-${ANDROID_ABI}-release-signed.apk")
  kluster_upload_apk_target()
elseif(kluster-scripts_FOUND AND UNIX)
  kluster_add_artifactory_target(${BALDER_DOC})
  kluster_add_aptly_targets(${BALDER_DOC})
  if(BALDER_APPIMAGE)
    message(STATUS "Create upload target for appimage")
    set(THE_APPIMAGE_FILE_NAME "balder-${PROJECT_VERSION}-x86_64.AppImage")
    kluster_upload_appimage_target()
  endif()
elseif(kluster-scripts_FOUND AND WIN32)
  kluster_add_artifactory_target(${BALDER_DOC})
else()
  add_custom_target(package_it
    COMMAND cmake --build . --target package --config Release
    COMMENT "Package project ${CMAKE_PROJECT_NAME}"
    VERBATIM)
  if(WITH_DOC)
    add_dependencies(package_it doc)
  endif()
endif()

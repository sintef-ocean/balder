# Define FetchContent_MakeAvailable for CMake < 3.14
#
if(${CMAKE_VERSION} VERSION_LESS 3.14)
  macro(FetchContent_MakeAvailable NAME)
    FetchContent_GetProperties(${NAME})
    if(NOT ${NAME}_POPULATED)
      FetchContent_Populate(${NAME})
      if(EXISTS ${${NAME}_SOURCE_DIR}/CMakeLists.txt)
        add_subdirectory(${${NAME}_SOURCE_DIR} ${${NAME}_BINARY_DIR})
      endif()
    endif()
  endmacro()
endif()

# odin_prepare_for_android()
#
# Prepares environment for ANDROID by setting variables
#  - ANDROID_BUILDTOOLS_REVISION
#  - ANDROID_STL
# Fetching content for QtAndroidCMake scripts
macro(odin_prepare_for_android)

  # $ENV{ANDROID_SDK_ROOT}/build-tools/<folder_name>

  if(NOT ANDROID_BUILDTOOLS_REVISION)
    if(ENV{ANDROID_BUILDTOOLS_REVISION})
      set(ANDROID_BUILDTOOLS_REVISION $ENV{ANDROID_BUILDTOOLS_REVISION})
    endif()

    if(NOT ANDROID_SDK_ROOT)
      set(ANDROID_SDK_ROOT $ENV{ANDROID_SDK_ROOT})
    endif()
    set(_curdir ${ANDROID_SDK_ROOT}/build-tools)
    file(GLOB children RELATIVE ${_curdir} ${_curdir}/*)
    list(LENGTH children _num_tools)
    if(_num_tools EQUAL 1)
      list(GET children 0 ANDROID_BUILDTOOLS_REVISION)
      message(STATUS "Android SDK build tools version: ${ANDROID_BUILDTOOLS_REVISION}")
    elseif(_num_tools GREATER 1)
      list(GET children 0 ANDROID_BUILDTOOLS_REVISION)
      message(WARNING "More than one android sdk build tool installed, arbitrarily choosing: ${ANDROID_BUILDTOOLS_REVISION}, to override, set ANDROID_BUILDTOOLS_REVISION")
    else()
      message(WARNING "ANDROID_SDK_ROOT: ${ANDROID_SDK_ROOT}")
      message(FATAL_ERROR "Could not find android sdk build tools, ANDROID_BUILDTOOLS_REVISION is unset")
    endif()
  endif()

  if(NOT ${ANDROID_STL} STREQUAL $ENV{ANDROID_STL})
    message(FATAL_ERROR "Not same: ${ANDROID_STL} vs $ENV{ANDROID_STL}")
  endif()
  if(DEFINED ENV{ANDROID_STL} AND NOT DEFINED ANDROID_STL)
    set(ANDROID_STL $ENV{ANDROID_STL})
    message(WARNING "Did set ANDROID_STL to ${ANDROID_STL}")
  endif()

  message(STATUS "ANDROID_STL is: ${ANDROID_STL}")
  if(NOT ${ANDROID_STL} STREQUAL $ENV{ANDROID_STL})
    message(WARNING "environment variable ANDROID_STL: $ENV{ANDROID_STL}")
  endif()
  #message(STATUS "ANDROID_BUILDTOOLS_REVISION is: ${ANDROID_BUILDTOOLS_REVISION}")

  FetchContent_Declare(qt-android-cmake
    GIT_REPOSITORY https://github.com/OlivierLDff/QtAndroidCMake)

endmacro()


# odin_all_linked_libs(
#   <libs_var>
#   TARGET <var>
#   [SKIP <list>])
#
# This macro traverses all targets of TARGET specified by <var> and adds their library
# paths to <libs_var>. It does not add libraries found in SKIP <list>
#
# The <libs_var> contains absolute paths to dependent libraries.
# This macro is called internally by odin_bundle_paths()
#
macro(odin_transitive_libs iReturnValue)
  cmake_parse_arguments(_ODIN "" "TARGET" "SKIP" ${ARGN} )

  if(TARGET ${_ODIN_TARGET})
    get_target_property(type ${_ODIN_TARGET} TYPE)
    if (NOT ${type} STREQUAL "INTERFACE_LIBRARY")
      get_target_property(path ${_ODIN_TARGET} LOCATION)
      #message(STATUS "Location of ${_ODIN_TARGET} is ${path}")
      if(NOT ${path} IN_LIST ${iReturnValue})
        if(path)
          get_filename_component(is_static ${path} EXT)
          string(COMPARE EQUAL "${is_static}" ".a" it_is_static)
          if(NOT it_is_static)

            get_filename_component(libName ${path} NAME)
            set(sexyList ${_ODIN_SKIP})
            separate_arguments(sexyList)
            #message(STATUS " ${path}")
            if(${libName} IN_LIST sexyList)
              #message(STATUS "  Skipping: ${libName}")
            else()
              message(STATUS "  ${libName}")
              list(APPEND ${iReturnValue} ${path})
            endif()
          else()
            #message(WARNING "Skipping static ${path}")
          endif()
        endif()
      else()
        #message(STATUS "Already found ${_ODIN_TARGET}")
      endif()
    endif()
    get_target_property(linkedLibraries ${_ODIN_TARGET} INTERFACE_LINK_LIBRARIES)
    #message(STATUS "INTERFACE_LINK_LIBRARIES for ${_ODIN_TARGET}: ${linkedLibraries}")

    if(NOT "${linkedLibraries}" STREQUAL "")
      foreach(linkedLibrary ${linkedLibraries})
        #message(STATUS ${linkedLibrary})
        odin_transitive_libs(${iReturnValue} TARGET ${linkedLibrary} SKIP "${args_SKIP}")
      endforeach()
    endif()
  endif()
endmacro()


# odin_bundle_paths(
#  TARGETS <target_list>
#  SKIP <skip_list>)
#
# Function that creates a list of full paths to dynamic libraries specified by TARGETS
# <target_list>.  The full path list is typically used by deployment tool to be bundled
# with application.  SKIP <skip_list> is a list of libraries to be skipped from the full
# path list.
#
# The function sets ODIN_LIB_PATHS to contain all library paths.
#
function(odin_bundle_paths)
  set(multiValArgs TARGETS SKIP)
  cmake_parse_arguments(PARSE_ARGV 0 args "" "" "${multiValArgs}")
  if(args_UNPARSE_ARGUMENTS)
    message(FATAL_ERROR "Invalid argument(s): ${args_UNPARSED_ARGUMENTS}")
  endif()
  if(NOT args_TARGETS)
    message(FATAL_ERROR "Missing argument: TARGETS")
  endif()

  # Must be done to accept variants of input targets vars with and without ""..
  set(_odin_targets ${args_TARGETS})
  separate_arguments(_odin_targets)
  #message(STATUS "TARGETS: ${_odin_targets}")
  #message(STATUS "SKIPS: ${args_SKIP}")

  foreach(depTarget IN LISTS _odin_targets)
    message(STATUS "Checking target: ${depTarget}")
    odin_transitive_libs(_extraDeps TARGET "${depTarget}" SKIP "${args_SKIP}")
    list(APPEND _odinDeps "${_extraDeps}")
  endforeach()

  set(ODIN_LIB_PATHS "${_odinDeps}" PARENT_SCOPE)

endfunction()

cmake_minimum_required(VERSION 3.16)

project(rester VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(NOT DEFINED QT_QML_GENERATE_QMLLS_INI)
  set(QT_QML_GENERATE_QMLLS_INI ON CACHE BOOL "Generate qml-ls .ini files" FORCE)
endif()

##################################################################
# Libs
##################################################################
find_package(Qt6 REQUIRED COMPONENTS Core Quick Qml QuickControls2 Gui WebSockets Concurrent)
qt_standard_project_setup(REQUIRES 6.11)

find_package(ZLIB)
find_package(gRPC CONFIG REQUIRED)
find_package(yaml-cpp CONFIG REQUIRED)
find_package(Brotli CONFIG REQUIRED)


##################################################################
# Sources
##################################################################
file(GLOB PROJECT_SOURCES CONFIGURE_DEPENDS
    *.cpp
    *.h
    models/*.h
    models/*.cpp
    app_data/*.h
    app_data/*.cpp
    app_data/settings/*.h
    app_data/settings/*.cpp
    highliters/*.h
    highliters/*.cpp
    parsers/*.h
    parsers/*.cpp
    clients/*.h
    clients/*.cpp
    importers/*.h
    importers/*.cpp
    exporters/*.h
    exporters/*.cpp
)

qt_add_executable(
    rester
    # ${PROJECT_SOURCES}
)

##################################################################
# QML
##################################################################
qt_add_qml_module(
    rester
    URI io.rester
    VERSION 1.0
    RESOURCE_PREFIX /qt/qml
    QML_FILES
        # UIKit
        resource/qml/common/components/uikit/RstDropdown.qml
        resource/qml/common/components/uikit/RstInput.qml
        resource/qml/common/components/uikit/RstButton.qml
        resource/qml/common/components/uikit/RstPropertyList.qml
        resource/qml/common/components/uikit/RstTabGroup.qml
        resource/qml/common/components/uikit/RstDivider.qml

        # General
        Main.qml
        resource/qml/Constants.qml
        resource/qml/colors/Colors.qml
        resource/qml/common/components/DropdownButton.qml
        resource/qml/common/components/FlickableEdit.qml
        resource/qml/common/components/Toast.qml
        resource/qml/common/components/ToastManager.qml
        resource/qml/home/modal/CreateRequestDialog.qml
        resource/qml/home/modal/InputDialog.qml
        resource/qml/home/modal/UpdateNodeDialog.qml

        # Containers
        resource/qml/home/GrpcAnswer.qml
        resource/qml/home/GrpcRequest.qml
        resource/qml/home/GraphqlRequest.qml
        resource/qml/home/GraphqlAnswer.qml
        resource/qml/home/Answer.qml
        resource/qml/home/Request.qml
        resource/qml/home/Routes.qml
        resource/qml/home/WsRequest.qml
        resource/qml/home/components/RoutesFolderNode.qml
        resource/qml/home/components/RoutesQueryNode.qml

        # Pins
        resource/qml/home/components/Pins.qml

        # GraphQL
        resource/qml/home/components/request/GraphqlQueryBody.qml
        resource/qml/home/components/request/GraphqlQueryVariables.qml
        resource/qml/home/components/answer/GraphqlAnswerBody.qml
        resource/qml/home/components/answer/GraphqlAnswerHeaders.qml
        resource/qml/home/components/answer/GraphqlAnswerCookies.qml

        # gRPC
        resource/qml/home/components/request/GrpcEmpty.qml
        resource/qml/home/components/request/GrpcQueryBody.qml
        resource/qml/home/components/request/GrpcQueryMeta.qml
        resource/qml/home/components/request/GrpcQueryTextBody.qml
        resource/qml/home/components/answer/GrpcAnswerBody.qml

        # HTTP
        resource/qml/home/components/answer/AnswerBigBody.qml
        resource/qml/home/components/answer/AnswerBody.qml
        resource/qml/home/components/answer/AnswerCookies.qml
        resource/qml/home/components/answer/AnswerError.qml
        resource/qml/home/components/answer/AnswerHeaders.qml
        resource/qml/home/components/answer/AnswerPreview.qml
        resource/qml/home/components/answer/AnswerWait.qml
        resource/qml/home/components/request/QueryBody.qml
        resource/qml/home/components/request/QueryFormBody.qml
        resource/qml/home/components/request/QueryHeaders.qml
        resource/qml/home/components/request/QueryParams.qml
        resource/qml/home/components/request/QueryTextBody.qml

        # Workspace
        resource/qml/workspace/WorkspaceList.qml
        resource/qml/workspace/WorkspaceVariables.qml

        # Settings
        resource/qml/settings/Settings.qml

    SOURCES
        ${PROJECT_SOURCES}

    RESOURCES
        "resource/images/add.svg"
        "resource/images/arrow-down-s.svg"
        "resource/images/arrow-up-s.svg"
        "resource/images/arrow-up-down.svg"
        "resource/images/close.svg"
        "resource/images/copy.svg"
        "resource/images/download.svg"
        "resource/images/exchange-dollar.svg"
        "resource/images/file-upload.svg"
        "resource/images/folder.svg"
        "resource/images/folder-add.svg"
        "resource/images/folder-empty.svg"
        "resource/images/folder-open.svg"
        "resource/images/github-fill.svg"
        "resource/images/magic.svg"
        "resource/images/more-line.svg"
        "resource/images/pencil.svg"
        "resource/images/pushpin-fill.svg"
        "resource/images/repeat-line.svg"
        "resource/images/rotate-loop.svg"
        "resource/images/send.svg"
        "resource/images/sound-module-line.svg"
        "resource/images/upload.svg"
        "resource/images/indent-increase.svg"

    DEPENDENCIES
        QtQuick
        QtQuick.Controls.Imagine 6.0
    # ENABLE_TYPE_COMPILER
    IMPORT_PATH ${CMAKE_CURRENT_SOURCE_DIR}/resource/qml
)


# file(GLOB application_qml_files
#     resource/qml/home/components/request/*.qml
# )

# qt6_add_qml_module(${application_name}
#     URI QmltcExample
#     QML_FILES ${application_qml_files}

#     # Compile qml files (listed in QML_FILES) to C++ using qmltc and add these
#     # files to the application binary:
#     ENABLE_TYPE_COMPILER
# )

##################################################################
# Target
##################################################################
target_link_libraries(rester
    PRIVATE Qt6::Core
    PRIVATE Qt6::Quick
    PRIVATE Qt6::Qml
    PRIVATE Qt6::QuickControls2
    PRIVATE Qt6::Gui
    PRIVATE Qt6::WebSockets
    PRIVATE Qt6::Concurrent
    PRIVATE ZLIB::ZLIB
    PRIVATE grpc::grpc
    PRIVATE yaml-cpp::yaml-cpp
    PRIVATE brotli::brotli
)


##################################################################
# Flags
##################################################################
set(COMPILER_FLAGS)
set(LINKER_FLAGS)

if (CMAKE_BUILD_TYPE STREQUAL "Release")
    if (CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64")
        list(APPEND COMPILER_FLAGS "-msse2")
        list(APPEND COMPILER_FLAGS "-floop-strip-mine")
        list(APPEND COMPILER_FLAGS "-ftree-parallelize-loops=4")

        # not for old and weak CPU
        list(APPEND COMPILER_FLAGS "-march=native")
        list(APPEND COMPILER_FLAGS "-mavx")
        list(APPEND COMPILER_FLAGS "-mavx2")
        list(APPEND COMPILER_FLAGS "-mavx512f")
        list(APPEND COMPILER_FLAGS "-mavx512dq")
        list(APPEND COMPILER_FLAGS "-mavx512bw")
    endif ()

    if (CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64")
        list(APPEND COMPILER_FLAGS "-mtune=cortex-a53")
    endif ()

    list(APPEND COMPILER_FLAGS "-O2")
    list(APPEND COMPILER_FLAGS "-ftree-vectorize")
    list(APPEND COMPILER_FLAGS "-ftree-slp-vectorize")
    list(APPEND COMPILER_FLAGS "-fstrict-aliasing")
    list(APPEND COMPILER_FLAGS "-fomit-frame-pointer")
    list(APPEND COMPILER_FLAGS "-freorder-blocks")
    list(APPEND COMPILER_FLAGS "-frename-registers")
    list(APPEND COMPILER_FLAGS "-funswitch-loops")
    list(APPEND COMPILER_FLAGS "-fpeel-loops")
    list(APPEND COMPILER_FLAGS "-funroll-loops")
    list(APPEND COMPILER_FLAGS "-floop-parallelize-all")
    list(APPEND COMPILER_FLAGS "-ffast-math")
    list(APPEND COMPILER_FLAGS "-ffunction-sections")
    list(APPEND COMPILER_FLAGS "-fdata-sections")

    list(APPEND LINKER_FLAGS "-Wl,--gc-sections")
    list(APPEND LINKER_FLAGS "-Wl,-s")

    set_target_properties(rester PROPERTIES INTERPROCEDURAL_OPTIMIZATION TRUE) # LTO

elseif (CMAKE_BUILD_TYPE STREQUAL "Debug")
    list(APPEND COMPILER_FLAGS "-O0")
    list(APPEND COMPILER_FLAGS "-g3")
    list(APPEND COMPILER_FLAGS "-Wall")
    list(APPEND COMPILER_FLAGS "-Wpedantic")

    target_compile_definitions(rester PRIVATE QT_QML_DEBUG)
endif ()

target_compile_options(rester PRIVATE ${COMPILER_FLAGS})
target_link_options(rester PRIVATE ${LINKER_FLAGS})

set_target_properties(rester PROPERTIES
    MACOSX_BUNDLE_GUI_IDENTIFIER rester.io
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

install(TARGETS rester
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)


##################################################################
# CPack
##################################################################
set(CPACK_PROJECT_NAME "Rester")
set(CPACK_PACKAGE_VENDOR "Rester")
set(CPACK_PACKAGE_DESCRIPTION "Tool for create and testing HTTP applications")
set(CPACK_PACKAGE_VERSION "1.0.0")
set(CPACK_PACKAGE_FILE_NAME "${CPACK_PROJECT_NAME}-${CPACK_PACKAGE_VERSION}")

include(CPack)

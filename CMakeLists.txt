cmake_minimum_required(VERSION 3.16)

project(rester VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -fsanitize=address,undefined")
# set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -fno-sanitize-recover")

find_package(Qt6 REQUIRED COMPONENTS Core Quick QuickControls2 Gui WebSockets)
find_package(ZLIB)

qt_standard_project_setup(REQUIRES 6.10)

file(GLOB PROJECT_SOURCES
    *.cpp
    *.h
    models/*.h
    models/*.cpp
    libs/import-lib/*.h
    app_data/*.h
    app_data/*.cpp
    app_data/insomnia/*.h
    app_data/insomnia/*.cpp
    app_data/postman/*.h
    app_data/postman/*.cpp
    app_data/settings/*.h
    app_data/settings/*.cpp
    app_data/har/*.h
    app_data/har/*.cpp
    highliters/*.h
    highliters/*.cpp
    parsers/*.h
    parsers/*.cpp
    clients/*.h
    clients/*.cpp
    qml.qrc
)

qt_add_executable(rester
    ${PROJECT_SOURCES}
)

qt_add_qml_module(rester
    URI io.rester
    QML_FILES
        Main.qml
        resource/qml/Constants.qml
        resource/qml/colors/Colors.qml
        resource/qml/common/components/DropdownButton.qml
        resource/qml/common/components/FlickableEdit.qml
        resource/qml/home/Answer.qml
        resource/qml/home/Request.qml
        resource/qml/home/Routes.qml
        resource/qml/home/WsRequest.qml
        resource/qml/home/components/RoutesFolderNode.qml
        resource/qml/home/components/RoutesQueryNode.qml
        resource/qml/home/components/Pins.qml
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
        resource/qml/home/modal/CreateRequestDialog.qml
        resource/qml/home/modal/InputDialog.qml
        resource/qml/home/modal/UpdateNodeDialog.qml
        resource/qml/settings/Settings.qml
        resource/qml/workspace/Workspace.qml
        resource/qml/workspace/WorkspaceVariables.qml
    # SOURCES
    #     app.h
    #     app.h
    #     models/pin_model.h
    #     models/pin_model.cpp
    #     models/routesmodel.h
    #     models/routesmodel.cpp
    #     models/worspace_model.h
    #     models/worspace_model.cpp
    #     app_data/workspace.h
    #     app_data/workspace.cpp
    #     app_data/query.h
    #     app_data/query.cpp
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

target_link_libraries(rester
    PRIVATE Qt6::Core
    PRIVATE Qt6::Quick
    PRIVATE Qt6::QuickControls2
    PRIVATE Qt6::Gui
    PRIVATE Qt6::WebSockets
    ${CMAKE_SOURCE_DIR}/libs/import-lib/libimport.a
    ZLIB::ZLIB
)

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


# CPack
set(CPACK_PROJECT_NAME "Rester")
set(CPACK_PACKAGE_VENDOR "Rester")
set(CPACK_PACKAGE_DESCRIPTION "Tool for create and testing HTTP applications")
set(CPACK_PACKAGE_VERSION "1.0.0")
set(CPACK_PACKAGE_FILE_NAME "${CPACK_PROJECT_NAME}-${CPACK_PACKAGE_VERSION}")

include(CPack)

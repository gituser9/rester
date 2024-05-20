cmake_minimum_required(VERSION 3.14)

project(rester VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -fsanitize=address,undefined")
# set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -fno-sanitize-recover")

find_package(QT NAMES Qt6 REQUIRED COMPONENTS Core Quick QuickControls2 Gui WebSockets)
find_package(Qt${QT_VERSION_MAJOR} REQUIRED COMPONENTS Core Quick QuickControls2 Gui WebSockets)
find_package(ZLIB)

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

if (${QT_VERSION_MAJOR} GREATER_EQUAL 6)
    qt_add_executable(rester
        MANUAL_FINALIZATION
        ${PROJECT_SOURCES}
    )
    # Define target properties for Android with Qt 6 as:
    #    set_property(TARGET rester APPEND PROPERTY QT_ANDROID_PACKAGE_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/android)
    # For more information, see https://doc.qt.io/qt-6/qt-add-executable.html#target-creation
else ()
    if (ANDROID)
        add_library(rester SHARED
            ${PROJECT_SOURCES}
        )
        # Define properties for Android with Qt 5 after find_package() calls as:
        #    set(ANDROID_PACKAGE_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/android")
    else ()
        add_executable(rester
            ${PROJECT_SOURCES}
        )
    endif ()
endif ()

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
    PRIVATE
    Qt${QT_VERSION_MAJOR}::Core
    Qt${QT_VERSION_MAJOR}::Quick
    Qt${QT_VERSION_MAJOR}::QuickControls2
    Qt${QT_VERSION_MAJOR}::Gui
    Qt${QT_VERSION_MAJOR}::WebSockets
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
)

if (QT_VERSION_MAJOR EQUAL 6)
    qt_import_qml_plugins(rester)
    qt_finalize_executable(rester)
endif ()


# CPack
set(CPACK_PROJECT_NAME "Rester")
set(CPACK_PACKAGE_VENDOR "Rester")
set(CPACK_PACKAGE_DESCRIPTION "Tool for create and testing HTTP applications")
set(CPACK_PACKAGE_VERSION "1.0.0")
set(CPACK_PACKAGE_FILE_NAME "${CPACK_PROJECT_NAME}-${CPACK_PACKAGE_VERSION}")

include(CPack)

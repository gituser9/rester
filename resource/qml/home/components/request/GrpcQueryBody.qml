pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable
pragma FunctionSignatureBehavior: Enforced

import QtCore
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Dialogs

import io.rester
import core.app 1.0
import Util

import "../../../../qml"

Item {
    id: queryBodyView

    property Constants consts: Constants {}

    signal clear
    signal copy

    ColumnLayout {
        anchors.fill: parent

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Loader {
                id: loader
                Layout.topMargin: 10
                Layout.bottomMargin: 20
                asynchronous: true
                anchors.fill: parent
                sourceComponent: textBody
            }
        }

        // buttons
        RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: 8

            spacing: 8

            Button {
                Layout.fillWidth: true
                implicitHeight: queryBodyView.consts.bottomButtonHeight
                icon.source: "qrc:/resource/images/upload.svg"
                flat: true
                text: qsTr("Upload")
                icon.width: 18
                icon.height: 18
                onClicked: {
                    fileDialog.open();
                }
            }
            Button {
                Layout.fillWidth: true
                implicitHeight: queryBodyView.consts.bottomButtonHeight
                icon.source: "qrc:/resource/images/close.svg"
                flat: true
                text: qsTr("Clear")
                onClicked: {
                    queryBodyView.clear();
                }
            }
            Button {
                Layout.fillWidth: true
                implicitHeight: queryBodyView.consts.bottomButtonHeight
                text: qsTr("Copy")
                icon.source: "qrc:/resource/images/copy.svg"
                flat: true
                onClicked: {
                    queryBodyView.copy();
                }
            }
            Button {
                Layout.fillWidth: true
                implicitHeight: queryBodyView.consts.bottomButtonHeight
                text: qsTr("Beautify")
                icon.source: "qrc:/resource/images/sound-module-line.svg"
                flat: true
                onClicked: {
                    App.grpcQuery.body = Util.beautify(App.grpcQuery.body, 1);
                }
            }
        }
    }

    Component {
        id: textBody

        GrpcQueryTextBody {
            id: tb

            Component.onCompleted: {
                queryBodyView.clear.connect(tb.clear);
                queryBodyView.copy.connect(tb.copy);
            }
        }
    }

    FileDialog {
        id: fileDialog
        currentFolder: StandardPaths.standardLocations(StandardPaths.HomeLocation)[0]
        nameFilters: ["Proto files (*.proto)"]
        onAccepted: () => {
            let path = selectedFile.toString().replace("file://", "");
            App.loadProto(path);
        }
    }
}

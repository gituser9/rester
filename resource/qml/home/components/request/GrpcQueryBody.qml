pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable
pragma FunctionSignatureBehavior: Enforced

import QtCore
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Imagine
import QtQuick.Dialogs

import io.rester

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
            Layout.bottomMargin: queryBodyView.consts.space

            spacing: queryBodyView.consts.space

            RstButton {
                implicitHeight: queryBodyView.consts.bottomButtonHeight
                icon: "qrc:/qt/qml/io/rester/resource/images/upload.svg"
                text: qsTr("Upload")
                onClicked: {
                    fileDialog.open();
                }

                Layout.fillWidth: true
            }
            RstButton {
                implicitHeight: queryBodyView.consts.bottomButtonHeight
                icon: "qrc:/qt/qml/io/rester/resource/images/close.svg"
                text: qsTr("Clear")
                onClicked: {
                    queryBodyView.clear();
                }

                Layout.fillWidth: true
            }
            RstButton {
                implicitHeight: queryBodyView.consts.bottomButtonHeight
                text: qsTr("Copy")
                icon: "qrc:/qt/qml/io/rester/resource/images/copy.svg"
                onClicked: {
                    queryBodyView.copy();
                }

                Layout.fillWidth: true
            }
            RstButton {
                implicitHeight: queryBodyView.consts.bottomButtonHeight
                text: qsTr("Beautify")
                icon: "qrc:/qt/qml/io/rester/resource/images/indent-increase.svg"
                onClicked: {
                    App.grpcQuery.body = Util.beautify(App.grpcQuery.body, 1);
                }

                Layout.fillWidth: true
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

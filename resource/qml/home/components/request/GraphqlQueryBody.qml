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
    id: graphqlBodyView

    property Constants consts: Constants {}

    signal clear
    signal copy

    ColumnLayout {
        anchors.fill: parent

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ScrollView {
                anchors.fill: parent

                TextArea {
                    id: taQueryBody
                    verticalAlignment: TextEdit.AlignTop
                    font.family: "Monospace"
                    tabStopDistance: 32
                    text: App.graphqlQuery?.body
                    onEditingFinished: {
                        App.graphqlQuery.body = taQueryBody.text;
                    }

                    Component.onCompleted: {
                        graphqlSyntaxHighlighter.setDocument(taQueryBody.textDocument);
                    }
                }
            }
        }

        // buttons
        RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: graphqlBodyView.consts.space

            spacing: graphqlBodyView.consts.space

            Button {
                Layout.fillWidth: true

                visible: false
                implicitHeight: graphqlBodyView.consts.bottomButtonHeight
                icon.source: "qrc:/qt/qml/io/rester/resource/images/upload.svg"
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
                implicitHeight: graphqlBodyView.consts.bottomButtonHeight
                icon.source: "qrc:/qt/qml/io/rester/resource/images/close.svg"
                flat: true
                text: qsTr("Clear")
                onClicked: {
                    taQueryBody.clear();
                }
            }
            Button {
                Layout.fillWidth: true
                implicitHeight: graphqlBodyView.consts.bottomButtonHeight
                text: qsTr("Copy")
                icon.source: "qrc:/qt/qml/io/rester/resource/images/copy.svg"
                flat: true
                onClicked: {
                    taQueryBody.selectAll();
                    taQueryBody.copy();
                }
            }
            Button {
                Layout.fillWidth: true
                implicitHeight: graphqlBodyView.consts.bottomButtonHeight
                text: qsTr("Beautify")
                icon.source: "qrc:/qt/qml/io/rester/resource/images/indent-increase.svg"
                flat: true
                onClicked: {
                    App.graphqlQuery.body = Util.beautify(App.graphqlQuery.body, RstEnums.BodyType.GRAPHQL);
                }
            }
        }
    }

    FileDialog {
        id: fileDialog
        currentFolder: StandardPaths.standardLocations(StandardPaths.HomeLocation)[0]
        nameFilters: ["Proto files (*.graphql)"]
        onAccepted: () => {
            let path = selectedFile.toString().replace("file://", "");
        // App.loadProto(path);
        }
    }

    GraphqlSyntaxHighlighter {
        id: graphqlSyntaxHighlighter
    }
}

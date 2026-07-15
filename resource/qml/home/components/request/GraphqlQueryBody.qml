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

            RstButton {
                visible: false
                implicitHeight: graphqlBodyView.consts.bottomButtonHeight
                size: RstButton.ButtonSize.Small
                text: qsTr("Upload")
                icon: "qrc:/qt/qml/io/rester/resource/images/download.svg"
                onClicked: {
                    fileDialog.open();
                }

                Layout.fillWidth: true
            }
            RstButton {
                implicitHeight: graphqlBodyView.consts.bottomButtonHeight
                text: qsTr("Clear")
                icon: "qrc:/qt/qml/io/rester/resource/images/close.svg"
                onClicked: {
                    taQueryBody.clear();
                }

                Layout.fillWidth: true
            }
            RstButton {
                implicitHeight: graphqlBodyView.consts.bottomButtonHeight
                text: qsTr("Copy")
                icon: "qrc:/qt/qml/io/rester/resource/images/copy.svg"
                onClicked: {
                    taQueryBody.selectAll();
                    taQueryBody.copy();
                }

                Layout.fillWidth: true
            }
            RstButton {
                implicitHeight: graphqlBodyView.consts.bottomButtonHeight
                text: qsTr("Beautify")
                icon: "qrc:/qt/qml/io/rester/resource/images/indent-increase.svg"
                onClicked: {
                    App.graphqlQuery.body = Util.beautify(App.graphqlQuery.body, RstEnums.BodyType.GRAPHQL);
                }

                Layout.fillWidth: true
            }
        }
    }

    FileDialog {
        id: fileDialog
        currentFolder: StandardPaths.standardLocations(StandardPaths.HomeLocation)[0]
        nameFilters: ["Proto files (*.graphql)"]
        onAccepted: () => {
            let path = selectedFile.toString().replace("file://", "");
        }
    }

    GraphqlSyntaxHighlighter {
        id: graphqlSyntaxHighlighter
    }
}

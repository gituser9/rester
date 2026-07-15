pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable
pragma FunctionSignatureBehavior: Enforced

import QtCore
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Imagine
import QtQuick.Dialogs

import io.rester

import "./../"
import "../common/components"

Item {
    id: graphqlView

    property Constants consts: Constants {}
    property int currentIndex: 0

    Component.onCompleted: {
        graphqlView.setSource(graphqlView.currentIndex);
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: graphqlView.consts.space

        RowLayout {
            Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
            Layout.topMargin: graphqlView.consts.space
            Layout.bottomMargin: 5
            Layout.preferredWidth: parent.width

            spacing: graphqlView.consts.space

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: graphqlView.consts.space
                Layout.preferredHeight: graphqlView.consts.bottomButtonHeight

                border.width: 1
                border.color: 'lightgrey'
                radius: 4

                FlickableEdit {
                    id: tfUrl

                    Component.onCompleted: {
                        varHilighter.setDocument(tfUrl.textDocument);
                    }

                    anchors.fill: parent
                    value: App.graphqlQuery ? App.graphqlQuery.url : ''
                    onEditingFinish: txt => {
                        App.graphqlQuery.url = txt;
                    }
                }
            }
            Rectangle {
                Layout.rightMargin: graphqlView.consts.space
                Layout.preferredWidth: 80
                Layout.preferredHeight: graphqlView.consts.bottomButtonHeight

                Button {
                    anchors.fill: parent
                    height: graphqlView.consts.bottomButtonHeight
                    text: qsTr("SEND")
                    onClicked: {
                        App.sendGraphql();
                    }
                }
            }
        }
        RstDivider {
            Layout.fillWidth: true
        }

        ButtonGroup {
            id: tabGroup
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.rightMargin: graphqlView.consts.space
            Layout.leftMargin: graphqlView.consts.space

            visible: false

            Button {
                Layout.fillWidth: true
                Layout.preferredWidth: graphqlView.width / 2

                checkable: true
                checked: graphqlView.currentIndex == 0
                flat: true
                text: qsTr("Body")
                onClicked: {
                    graphqlView.setSource(0);
                }

                ButtonGroup.group: tabGroup
            }
            Button {
                Layout.fillWidth: true
                Layout.preferredWidth: graphqlView.width / 2

                checkable: true
                checked: graphqlView.currentIndex == 1
                flat: true
                text: qsTr("Variables")
                onClicked: {
                    graphqlView.setSource(1);
                }

                ButtonGroup.group: tabGroup
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.rightMargin: graphqlView.consts.space
            Layout.leftMargin: graphqlView.consts.space

            Loader {
                id: loader
                asynchronous: true
                anchors.fill: parent
            }
        }
    }

    // Types
    VarSyntaxHighlighter {
        id: varHilighter
    }

    // Funcs
    function setSource(idx: int): void {
        currentIndex = idx;
        let path = "./components/request/";

        switch (idx) {
        case 0:
            path += "GraphqlQueryBody.qml";
            break;
        case 1:
            path += "GraphqlQueryVariables.qml";
            break;
        default:
            path += "GraphqlQueryBody.qml";
        }

        loader.setSource(path);
    }
}

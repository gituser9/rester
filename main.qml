import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

import core.app 1.0
import RoutesModel

import "./resource/qml/home"
import 'resource/qml/workspace'
import 'resource/qml/common/components'
import 'resource/qml/colors'

Window {
    id: root
    width: 1600
    height: 800
    visible: true
    title: "Rester"


    Component.onCompleted: {
        if (App.workspace.env === '') {
            dbEnvs.currentEnv = 'No Env'
        } else {
            dbEnvs.currentEnv = App.workspace.env
            dbEnvs.setEnvs(App.workspace.getEnvNames())
        }
    }


    ColumnLayout {
        anchors.fill: parent

        Rectangle {
            Layout.fillWidth: true

            height: 50

            RowLayout {
                anchors.fill: parent
                spacing: 8

                Text {
                    Layout.leftMargin: 8
                    Layout.rightMargin: 8

                    id: txtWsName
                    text: App.workspace.name === '' ? "Workspace name" : App.workspace.name
                    font.weight: Font.Bold
                    font.pointSize: 18
                }
                DropdownButton {
                    Layout.rightMargin: 16
                    Layout.alignment: Qt.AlignVCenter
                    Layout.minimumWidth: 60
                    Layout.maximumWidth:  200

                    id: dbEnvs
                    height: 50
                    implicitWidth: 50
                    currentEnv: App.workspace.env
                }
                Button {
                    Layout.rightMargin: 8

                    flat: true
                    icon.source: "/resource/images/repeat-line.svg"
                    icon.width: 24
                    icon.height: 24
                    icon.color: 'black'
                    onClicked: {
                        popWorkspaces.open()

                        wsLoader.setSource("./resource/qml/workspace/Workspace.qml")
                    }
                }
                Item {
                    Layout.fillWidth: true

                    height: parent.height

                    Text {
                        anchors.centerIn: parent
                        text: App.query ? App.workspace.nodeFullPath(App.query.uuid) : ""
                        font.pointSize: 16
                        font.family: "Monospace"
                    }
                }
                Button {
                    Layout.rightMargin: 8

                    text: qsTr("Env")
                    flat: true
                    icon.source: "/resource/images/exchange-dollar.svg"
                    icon.width: 24
                    icon.height: 24
                    icon.color: 'black'
                    onClicked: {
                        popWorkspaces.open()

                        wsLoader.sourceComponent = envVars
                    }
                }
                // Button {
                //     Layout.rightMargin: 8

                //     text: qsTr("Settings")
                //     flat: true
                //     icon.source: "/resource/images/sound-module-line.svg"
                //     icon.width: 24
                //     icon.height: 24
                //     icon.color: 'black'
                //     onClicked: {
                //         popSettings.open()

                //         settsLoader.setSource("./resource/qml/settings/Settings.qml")
                //     }
                // }
            }
        }

        MenuSeparator {
            width: parent.width
            contentItem: Rectangle {
                implicitWidth: parent.width
                implicitHeight: 1
                color: "#1E000000"
            }
        }

        SplitView {
            Layout.fillHeight: true
            Layout.fillWidth: true

            Routes {
                implicitWidth: 350
            }

            Loader {
                visible: App.query
                sourceComponent: App.query && App.query.queryType !== 6 ? restRequest : wsRequest
            }

            // Request {
            //     id: requestView
            //     visible: App.query
            //     implicitWidth: root.width / 3
            // }

            Rectangle {
                visible: !App.query
                implicitWidth: root.width / 3
            }

            Answer {
                id: answerView
                visible: App.query && App.query.queryType !== 6
            }
        }
    }


    Component {
        id: restRequest

        Request {
            implicitWidth: root.width / 3
        }
    }

    Component {
        id: wsRequest

        WsRequest {
            implicitWidth: root.width / 3
        }
    }


    Connections {
        target: App.workspace

        function onNameChanged() {
            txtWsName.text = App.workspace.name
        }
    }




    Component {
        id: envVars

        WorkspaceVariables {
            Component.onDestruction: {
                // RoutesModel.reloadWorkspaceVariables()
            }

            env: App.workspace.env
        }
    }

    Popup {
        id: popWorkspaces
        anchors.centerIn: parent
        height: parent.height / 1.5
        width: parent.width / 2
        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        onClosed: {
            wsLoader.active = false
        }
        onOpened: {
            wsLoader.active = true
        }

        Loader {
            id: wsLoader
            asynchronous: true
            anchors.fill: parent
        }
    }

    Popup {
        id: popSettings
        anchors.centerIn: parent
        height: parent.height / 1.5
        width: parent.width / 2
        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        onClosed: {
            // wsLoader.active = false
        }
        onOpened: {
            // wsLoader.active = true
        }

        Loader {
            id: settsLoader
            asynchronous: true
            anchors.fill: parent
        }
    }

}

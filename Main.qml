import QtQuick
import QtQuick.Window
import QtQuick.Controls.Imagine
import QtQuick.Layouts

import io.rester
import core.app 1.0
import RoutesModel
import Util

import "./resource/qml/home"
import "resource/qml/workspace"
import "resource/qml/common/components"
import "resource/qml/colors"

Window {
    id: root
    width: 1600
    height: 800
    visible: true
    title: "Rester"

    property string currentQueryView: ''
    property string currentAnswerView: ''

    Component.onCompleted: {
        if (App.workspace.env === '') {
            dbEnvs.currentEnv = 'No Env';
        } else {
            dbEnvs.currentEnv = App.workspace.env;
            dbEnvs.setEnvs(App.workspace.getEnvNames());
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
                    id: txtWsName
                    text: App.workspace.name === '' ? "Workspace name" : App.workspace.name
                    font.weight: Font.Bold
                    font.pointSize: 18

                    Layout.leftMargin: 8
                    Layout.rightMargin: 8
                }
                DropdownButton {
                    id: dbEnvs
                    height: 50
                    // implicitWidth: 50
                    currentEnv: App.workspace.env

                    Layout.rightMargin: 16
                    Layout.alignment: Qt.AlignVCenter
                    Layout.minimumWidth: 60
                    Layout.maximumWidth: 200
                }
                Button {
                    flat: true
                    icon.source: "qrc:/qt/qml/io/rester/resource/images/repeat-line.svg"
                    icon.width: 24
                    icon.height: 24
                    icon.color: 'black'
                    onClicked: {
                        popWorkspaces.open();

                        wsLoader.setSource("./resource/qml/workspace/WorkspaceList.qml");
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
                    icon.source: "qrc:/qt/qml/io/rester/resource/images/exchange-dollar.svg"
                    icon.width: 24
                    icon.height: 24
                    icon.color: 'black'
                    onClicked: {
                        popWorkspaces.open();

                        wsLoader.sourceComponent = envVars;
                    }
                }
                // Button {
                //     Layout.rightMargin: 8

                //     text: qsTr("Settings")
                //     flat: true
                //     icon.source: "qrc:/qt/qml/io/rester/resource/images/sound-module-line.svg"
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

            Rectangle {
                implicitWidth: root.width / 3
                visible: App.query || App.grpcQuery

                Loader {
                    id: ldrQuery
                    anchors.fill: parent
                    asynchronous: true
                }
            }

            Rectangle {
                visible: !App.query && !App.grpcQuery
                implicitWidth: root.width / 3
            }

            Rectangle {
                visible: root.isAnswerVisible()

                Loader {
                    id: ldrAnswer
                    anchors.fill: parent
                    asynchronous: true
                }
            }
        }
    }

    Connections {
        target: App

        function onQueryChanged(): void {
            if (!App.query) {
                return;
            }

            root.setSource(App.query.queryType);
            root.setAnswerSource(App.query.queryType);
        }

        function onGrpcQueryChanged(): void {
            if (!App.grpcQuery) {
                return;
            }

            root.setSource(App.grpcQuery.queryType);
            root.setAnswerSource(App.grpcQuery.queryType);
        }

        function onShowError(txt): void {
            toastManager.show(txt);
        }
    }

    // Types
    Component {
        id: envVars

        WorkspaceVariables {
            env: App.workspace.env
        }
    }

    ToastManager {
        id: toastManager
    }

    Popup {
        id: popWorkspaces
        anchors.centerIn: parent
        height: parent.height / 1.5
        width: parent.width / 2
        modal: true
        popupType: Popup.Item
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        onClosed: {
            wsLoader.active = false;
        }
        onOpened: {
            wsLoader.active = true;
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

    function setSource(typ): void {
        let path = "./resource/qml/home/";
        let typStr = Util.getQueryTypeString(typ);
        let view = '';

        switch (typStr) {
        case 'WS':
            view = 'WsRequest.qml';
            break;
        case 'GRPC':
            view = 'GrpcRequest.qml';
            break;
        default:
            view = 'Request.qml';
        }

        if (view === root.currentQueryView) {
            return;
        }

        root.currentQueryView = view;

        ldrQuery.setSource(path + view);
    }

    function setAnswerSource(typ): void {
        let path = "./resource/qml/home/";
        let typStr = Util.getQueryTypeString(typ);
        let view = '';

        switch (typStr) {
        case 'WS':
            view = 'Answer.qml';
            break;
        case 'GRPC':
            view = 'GrpcAnswer.qml';
            break;
        default:
            view = 'Answer.qml';
        }

        if (view === root.currentAnswerView) {
            return;
        }

        root.currentAnswerView = view;

        ldrAnswer.setSource(path + view);
    }

    function isAnswerVisible(): bool {
        if (!App.query && !App.grpcQuery) {
            return false;
        }

        if (App.grpcQuery) {
            return true;
        }

        let typStr = '';

        if (App.query) {
            typStr = Util.getQueryTypeString(App.query.queryType);
        }

        return typStr !== 'WS';
    }
}

pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable

import QtCore
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Dialogs

import io.rester
import core.app
import VarSyntaxHighlighter

import "./../"
import "../common/components"

Item {
    id: grpcView

    property Constants consts: Constants {}
    property int currentIndex: 0

    Component.onCompleted: {
        if (isEmptyQuery()) {
            grpcView.currentIndex = -1;
        }

        grpcView.setSource(grpcView.currentIndex);
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        RowLayout {
            Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
            Layout.topMargin: 8
            Layout.bottomMargin: 5
            Layout.preferredWidth: parent.width

            spacing: 8

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 8 // TODO: to const
                Layout.preferredHeight: grpcView.consts.bottomButtonHeight

                border.width: 1
                border.color: 'lightgrey'
                radius: 4

                FlickableEdit {
                    id: tfUrl

                    Component.onCompleted: {
                        varHilighter.setDocument(tfUrl.textDocument);
                    }

                    anchors.fill: parent
                    value: App.grpcQuery ? App.grpcQuery.url : ''
                    onEditingFinish: txt => {
                        App.grpcQuery.url = txt;
                    }
                }
            }
            Rectangle {
                Layout.rightMargin: 8
                Layout.preferredWidth: 80
                Layout.preferredHeight: grpcView.consts.bottomButtonHeight

                Button {
                    anchors.fill: parent
                    height: grpcView.consts.bottomButtonHeight
                    text: qsTr("SEND")
                    onClicked: {
                        App.callGrpc();
                    }
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: grpcView.consts.bottomButtonHeight

            spacing: 8

            // upload btn
            Button {
                Layout.leftMargin: 8
                Layout.preferredHeight: grpcView.consts.bottomButtonHeight

                ToolTip.text: qsTr("Reload from filesystem")
                ToolTip.visible: hovered

                flat: true
                icon.source: "/resource/images/rotate-loop.svg"
                icon.width: 18
                icon.height: 18
                onClicked: {
                    App.reloadProto();
                }
            }

            // list of srv
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredWidth: parent.width / 2
                Layout.preferredHeight: grpcView.consts.bottomButtonHeight

                ComboBox {
                    id: cbSrv
                    anchors.fill: parent
                    height: grpcView.consts.bottomButtonHeight
                    model: App.grpcQuery.availableSrv
                    currentValue: App.grpcQuery.srv
                    onActivated: {
                        App.grpcQuery.srv = cbSrv.currentText;
                    }
                }
            }

            // list of rpc
            Rectangle {
                Layout.fillWidth: true
                Layout.rightMargin: 8
                Layout.preferredWidth: parent.width / 2
                Layout.preferredHeight: grpcView.consts.bottomButtonHeight

                ComboBox {
                    id: cbRpc
                    anchors.fill: parent
                    height: grpcView.consts.bottomButtonHeight
                    model: App.grpcQuery.availableRpc
                    currentValue: App.grpcQuery.rpc
                    onActivated: {
                        App.grpcQuery.rpc = cbRpc.currentText;
                    }
                }
            }
        }
        MenuSeparator {
            Layout.preferredWidth: parent.width

            contentItem: Rectangle {
                implicitWidth: parent.width
                implicitHeight: 1
                color: "#1E000000"
            }
        }

        ButtonGroup {
            id: tabGroup
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.rightMargin: 8
            Layout.leftMargin: 8

            Button {
                Layout.fillWidth: true
                Layout.preferredWidth: grpcView.width / 2

                checkable: true
                checked: grpcView.currentIndex == 0
                flat: true
                text: qsTr("Body")
                onClicked: {
                    grpcView.setSource(0);
                }

                ButtonGroup.group: tabGroup
            }
            Button {
                Layout.fillWidth: true
                Layout.preferredWidth: grpcView.width / 2

                checkable: true
                checked: grpcView.currentIndex == 1
                flat: true
                text: qsTr("Meta")
                onClicked: {
                    grpcView.setSource(1);
                }

                ButtonGroup.group: tabGroup
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.rightMargin: 8
            Layout.leftMargin: 8

            Loader {
                id: loader
                asynchronous: true
                anchors.fill: parent
            }
        }
    }

    // Connections

    Connections {
        target: App.grpcQuery

        function onDataChanged() {
            if (grpcView.currentIndex === -1) {
                grpcView.currentIndex = grpcView.isEmptyQuery() ? -1 : 0;
                grpcView.setSource(grpcView.currentIndex);
            }
        }
    }

    // Types
    VarSyntaxHighlighter {
        id: varHilighter
    }

    // Funcs
    function setSource(idx) {
        currentIndex = idx;
        let path = "./components/request/";

        switch (idx) {
        case -1:
            path += 'GrpcEmpty.qml';
            break;
        case 0:
            path += "GrpcQueryBody.qml";
            break;
        case 1:
            path += "GrpcQueryMeta.qml";
            break;
        default:
            path += "GrpcQueryBody.qml";
        }

        loader.setSource(path);
    }

    function isEmptyQuery() {
        let srv = App.grpcQuery.availableSrv;
        let rpc = App.grpcQuery.availableRpc;

        if (srv.length === 0 && rpc.length === 0) {
            return true;
        }

        return false;
    }
}

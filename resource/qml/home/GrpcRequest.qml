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
            Layout.topMargin: grpcView.consts.space
            Layout.bottomMargin: 5
            Layout.preferredWidth: parent.width

            spacing: 8

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: grpcView.consts.space
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
                Layout.rightMargin: grpcView.consts.space
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
            Layout.leftMargin: grpcView.consts.space
            Layout.rightMargin: grpcView.consts.space

            spacing: grpcView.consts.space

            // upload btn
            RstButton {
                implicitHeight: grpcView.consts.bottomButtonHeight
                size: RstButton.ButtonSize.Small
                tooltip: qsTr("Reload from filesystem")
                tooltipAfter: qsTr("Reloaded")
                icon: "qrc:/qt/qml/io/rester/resource/images/rotate-loop.svg"
                onClicked: {
                    App.reloadProto();
                }
            }

            // list of srv
            RstDropdown {
                id: cbSrv
                model: App.grpcQuery.availableSrv
                placeholder: qsTr("Service")
                currentText: App.grpcQuery.srv
                onItemSelected: (idx, value) => {
                    App.grpcQuery.srv = value;
                }

                Layout.fillWidth: true
                Layout.preferredWidth: parent.width / 2
                Layout.preferredHeight: grpcView.consts.bottomButtonHeight
            }

            // list of rpc
            RstDropdown {
                id: cbRpc
                model: App.grpcQuery.availableRpc
                placeholder: qsTr("RPC")
                currentText: App.grpcQuery.rpc
                onItemSelected: (idx, value) => {
                    App.grpcQuery.rpc = value;
                }

                Layout.fillWidth: true
                Layout.preferredWidth: parent.width / 2
                Layout.preferredHeight: grpcView.consts.bottomButtonHeight
            }
        }
        RstDivider {
            Layout.fillWidth: true
        }

        RstTabGroup {
            id: tabs
            texts: [qsTr("Body"), qsTr("Meta")]
            onClicked: idx => {
                grpcView.setSource(idx);
            }

            Layout.fillWidth: true
            Layout.rightMargin: 8
            Layout.leftMargin: 8
            Layout.preferredHeight: grpcView.consts.bottomButtonHeight
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.rightMargin: grpcView.consts.space
            Layout.leftMargin: grpcView.consts.space

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

        function onDataChanged(): void {
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
    function setSource(idx: int): void {
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

    function isEmptyQuery(): bool {
        let srv = App.grpcQuery.availableSrv;
        let rpc = App.grpcQuery.availableRpc;

        if (srv.length === 0 && rpc.length === 0) {
            return true;
        }

        return false;
    }
}

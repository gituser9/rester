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
    id: root

    property Constants consts: Constants {}
    property int currentIndex: 0

    Component.onCompleted: {
        if (isEmptyQuery()) {
            root.currentIndex = -1;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: root.consts.space

        RowLayout {
            Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
            Layout.topMargin: root.consts.space
            Layout.bottomMargin: 5
            Layout.preferredWidth: parent.width

            spacing: root.consts.space

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: root.consts.space
                Layout.preferredHeight: root.consts.bottomButtonHeight

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
                Layout.rightMargin: root.consts.space
                Layout.preferredWidth: 80
                Layout.preferredHeight: root.consts.bottomButtonHeight

                Button {
                    anchors.fill: parent
                    height: root.consts.bottomButtonHeight
                    text: qsTr("SEND")
                    onClicked: {
                        App.callGrpc();
                    }
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: root.consts.bottomButtonHeight
            Layout.leftMargin: root.consts.space
            Layout.rightMargin: root.consts.space

            visible: root.currentIndex !== -1
            spacing: root.consts.space

            // upload btn
            RstButton {
                implicitHeight: root.consts.bottomButtonHeight
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
                Layout.preferredHeight: root.consts.bottomButtonHeight
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
                Layout.preferredHeight: root.consts.bottomButtonHeight
            }
        }
        RstDivider {
            Layout.fillWidth: true
        }

        RstTabGroup {
            id: tabs
            visible: root.currentIndex !== -1
            texts: [qsTr("Body"), qsTr("Meta")]
            onClicked: idx => {
                if (idx === 0 && root.isEmptyQuery()) {
                    root.currentIndex = -1;
                    return;
                }
                root.currentIndex = idx;
            }

            Layout.fillWidth: true
            Layout.rightMargin: root.consts.space
            Layout.leftMargin: root.consts.space
            Layout.preferredHeight: root.consts.bottomButtonHeight
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.rightMargin: root.consts.space
            Layout.leftMargin: root.consts.space

            Loader {
                id: loader
                asynchronous: true
                anchors.fill: parent
                sourceComponent: {
                    switch (root.currentIndex) {
                    case 0:
                        return queryBody;
                    case 1:
                        return meta;
                    case -1:
                        return emptyQuery;
                    default:
                        return queryBody;
                    }
                }
            }
        }
    }

    // Components
    Component {
        id: meta

        QueryParamList {
            params: App.grpcQuery.meta
            onAddParam: {
                App.grpcQuery.addMetaItem('', '');
            }
            onRemoveParam: idx => {
                App.grpcQuery.removeMetaItem(idx);
            }
            onSetParam: (idx, name, val, enabled) => {
                App.grpcQuery.setMetaItem(idx, name, val, enabled);
            }
        }
    }
    Component {
        id: queryBody

        QueryBody {
            body: App.grpcQuery.body
            bodyType: RstEnums.BodyType.JSON
            onEditingFinished: txt => {
                App.grpcQuery.body = txt;
            }
            onClear: {
                App.grpcQuery.body = '';
            }
        }
    }
    Component {
        id: emptyQuery

        GrpcEmpty {}
    }

    // Connections
    Connections {
        target: App.grpcQuery

        function onDataChanged(): void {
            if (root.currentIndex === -1) {
                root.currentIndex = root.isEmptyQuery() ? -1 : 0;
            }
        }
    }

    // Types
    VarSyntaxHighlighter {
        id: varHilighter
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

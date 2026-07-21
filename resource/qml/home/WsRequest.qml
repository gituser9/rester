pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable
pragma FunctionSignatureBehavior: Enforced

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Imagine

import io.rester

import "./../"
import "../common/components"

Item {
    id: wsView

    property Constants consts: Constants {}

    Component.onDestruction: {
        App.disconnectSocket();
    }

    ColumnLayout {
        anchors.fill: parent

        RowLayout {
            Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
            Layout.topMargin: 8
            Layout.bottomMargin: 5
            Layout.preferredWidth: parent.width

            spacing: 8

            Rectangle {
                Layout.leftMargin: 8
                Layout.topMargin: 8
                Layout.preferredWidth: 20
                Layout.preferredHeight: wsView.consts.bottomButtonHeight

                Text {
                    text: "WS"
                    color: '#FFA500'
                    font.bold: true
                    font.pointSize: 16
                }
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 20

                Layout.preferredWidth: 80
                Layout.preferredHeight: wsView.consts.bottomButtonHeight
                border.width: 1
                border.color: 'lightgrey'
                radius: 4

                FlickableEdit {
                    id: tfUrl
                    Layout.rightMargin: 8

                    Component.onCompleted: {
                        varHilighter.setDocument(tfUrl.textDocument);
                    }
                    anchors.fill: parent
                    value: App.query ? App.query.url : ''
                    onEditingFinish: txt => {
                        App.query.url = txt;
                    }
                }
            }
            Rectangle {
                Layout.rightMargin: 8

                Layout.preferredWidth: 180
                Layout.preferredHeight: wsView.consts.bottomButtonHeight

                Button {
                    anchors.fill: parent
                    height: wsView.consts.bottomButtonHeight
                    text: App.isActiveSocketConnect ? qsTr("DISCONNECT") : qsTr("CONNECT")
                    onClicked: {
                        if (App.isActiveSocketConnect) {
                            App.disconnectSocket();
                        } else {
                            App.connectToSocket();
                        }
                    }
                }
            }
        }
        ListView {
            id: msgList
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            clip: true
            model: msgModel
            delegate: Item {
                id: wsMsgDelegate
                height: txtWsMsg.height + 8

                required property string message
                required property string type

                Layout.fillWidth: true

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: txtWsMsg.height

                    spacing: 8

                    Text {
                        Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                        Layout.topMargin: 8

                        font.family: "Monospace"
                        font.bold: true
                        text: wsMsgDelegate.type + ":"
                        color: wsView.getColorForMessageType(wsMsgDelegate.type)
                    }
                    Text {
                        id: txtWsMsg
                        Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                        Layout.topMargin: 8
                        font.family: "Monospace"
                        text: wsMsgDelegate.message
                    }
                    // if JSON
                    RstButton {
                        id: btnBeautify
                        size: RstButton.ButtonSize.Small
                        tooltip: qsTr("Beautify")
                        visible: mouse.hovered && wsView.isJSON(txtWsMsg.text)
                        icon: "qrc:/qt/qml/io/rester/resource/images/pencil.svg"
                        onClicked: {
                            txtWsMsg.text = wsView.beautifyJSON(txtWsMsg.text);
                        }

                        Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                    }
                    RstButton {
                        id: copyBtn
                        visible: mouse.hovered
                        size: RstButton.ButtonSize.Small
                        tooltip: qsTr("Copy Message")
                        tooltipAfter: qsTr("Copied")
                        icon: "qrc:/qt/qml/io/rester/resource/images/copy.svg"
                        onClicked: {
                            teCopy.text = txtWsMsg.text;
                            teCopy.selectAll();
                            teCopy.copy();
                            teCopy.clear();
                        }

                        Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                    }

                    HoverHandler {
                        id: mouse
                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                        cursorShape: Qt.PointingHandCursor
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            Layout.bottomMargin: 8

            visible: App.isActiveSocketConnect

            ColumnLayout {
                Layout.fillWidth: true

                TextField {
                    id: tfMsg
                    text: ''
                    placeholderText: qsTr("Message")

                    Layout.fillWidth: true
                }
            }

            Button {
                Layout.leftMargin: 8
                Layout.preferredHeight: wsView.consts.bottomButtonHeight

                text: qsTr("SEND")
                onClicked: {
                    if (!tfMsg.text) {
                        return;
                    }

                    msgModel.append({
                        message: tfMsg.text,
                        type: 'sended'
                    });
                    App.sendToSocket(tfMsg.text);
                    tfMsg.text = '';
                }
            }
        }
    }

    TextEdit {
        id: teCopy
        visible: false
    }

    ListModel {
        id: msgModel
    }

    VarSyntaxHighlighter {
        id: varHilighter
    }

    Connections {
        target: App

        function onSocketReceived(msg: string): void {
            msgModel.append({
                "message": msg,
                "type": 'received'
            });
        }

        function onSocketError(msg: string): void {
            msgModel.append({
                "message": msg,
                "type": 'error'
            });
        }
    }

    function isJSON(str: string): bool {
        try {
            JSON.parse(str);

            return true;
        } catch (error) {
            return false;
        }
    }

    function beautifyJSON(str: string): string {
        try {
            const jsonObj = JSON.parse(str);
            return JSON.stringify(jsonObj, null, 4);
        } catch (error) {
            return str;
        }
    }

    function getColorForMessageType(type: string): string {
        if (type === 'received') {
            return '#008200';
        }

        if (type === 'sended') {
            return '#5555ff';
        }

        if (type === 'error') {
            return '#ff0000';
        }
    }
}

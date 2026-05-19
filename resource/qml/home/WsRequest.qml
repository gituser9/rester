pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import io.rester
import core.app
import VarSyntaxHighlighter

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

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.rightMargin: 8

            visible: App.isActiveSocketConnect

            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 22

                FlickableEdit {
                    id: tfMsg
                    Layout.fillWidth: true
                    Layout.preferredHeight: 20
                    value: ''
                }
                MenuSeparator {
                    Layout.fillWidth: true

                    contentItem: Rectangle {
                        implicitWidth: parent.width
                        implicitHeight: 1
                        color: "#1E000000"
                    }
                }
            }

            Button {
                Layout.leftMargin: 8
                Layout.preferredHeight: wsView.consts.bottomButtonHeight

                text: qsTr("SEND")
                onClicked: {
                    if (!tfMsg.value) {
                        return;
                    }

                    msgModel.append({
                        message: tfMsg.value,
                        type: 'sended'
                    });
                    App.sendToSocket(tfMsg.value);
                    tfMsg.value = '';
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
                    Button {
                        id: btnBeautify
                        Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                        ToolTip.text: qsTr("Beautify")
                        ToolTip.visible: hovered
                        visible: mouse.hovered && wsView.isJSON(txtWsMsg.text)
                        flat: true
                        icon.source: "/resource/images/pencil.svg"
                        icon.width: 18
                        icon.height: 18
                        icon.color: 'black'
                        onClicked: {
                            txtWsMsg.text = wsView.beautifyJSON(txtWsMsg.text);
                        }
                    }
                    Button {
                        id: copyBtn
                        property string tooltipText: qsTr("Copy value")

                        Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                        ToolTip.text: tooltipText
                        ToolTip.visible: hovered
                        ToolTip.toolTip.onVisibleChanged: {
                            if (!hovered) {
                                tooltipText = qsTr("Copy Message");
                            }
                        }
                        visible: mouse.hovered
                        flat: true
                        icon.source: "/resource/images/copy.svg"
                        icon.width: 18
                        icon.height: 18
                        icon.color: 'black'
                        onClicked: {
                            teCopy.text = txtWsMsg.text;
                            teCopy.selectAll();
                            teCopy.copy();
                            teCopy.clear();

                            copyBtn.tooltipText = qsTr("Copied");
                        }
                    }

                    HoverHandler {
                        id: mouse
                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                        cursorShape: Qt.PointingHandCursor
                    }
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

        function onSocketReceived(msg) {
            msgModel.append({
                message: msg,
                type: 'received'
            });
        }

        function onSocketError(msg) {
            msgModel.append({
                message: msg,
                type: 'error'
            });
        }
    }

    function isJSON(str) {
        try {
            JSON.parse(str);

            return true;
        } catch (error) {
            return false;
        }
    }

    function beautifyJSON(str) {
        try {
            const jsonObj = JSON.parse(str);
            return JSON.stringify(jsonObj, null, 4);
        } catch (error) {
            return str;
        }
    }

    function getColorForMessageType(type) {
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

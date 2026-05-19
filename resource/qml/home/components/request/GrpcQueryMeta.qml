pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import io.rester
import core.app 1.0
import VarSyntaxHighlighter

import "../../../common/components"

Rectangle {
    id: winHeader

    signal changeHeader(int index)

    Component.onCompleted: {
        winHeader.fillData();
    }
    anchors.fill: parent

    ListView {
        id: headerList
        width: parent.width
        height: parent.height - 50
        clip: true
        model: headerModel
        delegate: Rectangle {
            id: metaDelegate
            height: 60
            width: winHeader.width

            required property bool isEnabled
            required property int index
            required property string name
            required property string value

            RowLayout {
                spacing: 16
                anchors.fill: parent

                CheckBox {
                    id: cbEnabled
                    checked: metaDelegate.isEnabled
                    onClicked: {
                        headerModel.setProperty(metaDelegate.index, "isEnabled", cbEnabled.checkState === Qt.Checked);
                        winHeader.changeHeader(metaDelegate.index);
                    }
                }
                Column {
                    Layout.fillWidth: true

                    FlickableEdit {
                        id: tfHeaderName
                        width: headerList.width / 3
                        height: 20
                        isEnabled: cbEnabled.checkState === Qt.Checked
                        value: metaDelegate.name
                        onEditingFinish: txt => {
                            let header = headerModel.get(metaDelegate.index);

                            App.grpcQuery.setMetaItem(metaDelegate.index, header.name, header.value, header.isEnabled);
                        }
                        onTextChange: txt => {
                            headerModel.setProperty(metaDelegate.index, "name", txt);
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
                }
                Column {
                    Layout.fillWidth: true
                    Layout.leftMargin: 16

                    FlickableEdit {
                        id: tfHeaderValue
                        width: parent.width
                        height: 20
                        isEnabled: cbEnabled.checkState === Qt.Checked
                        value: metaDelegate.value
                        onEditingFinish: txt => {
                            let header = headerModel.get(metaDelegate.index);

                            App.grpcQuery.setMetaItem(metaDelegate.index, header.name, header.value, header.isEnabled);
                        }
                        onTextChange: txt => {
                            headerModel.setProperty(metaDelegate.index, "value", txt);
                        }

                        Component.onCompleted: {
                            varHilighter.setDocument(tfHeaderValue.textDocument);
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
                }
                Button {
                    flat: true
                    icon.source: "qrc:/resource/images/close.svg"
                    icon.width: 22
                    icon.height: 22
                    icon.color: 'black'
                    onClicked: {
                        App.grpcQuery.removeMetaItem(metaDelegate.index);
                        headerModel.remove(metaDelegate.index);
                    }
                }
            }
        }
    }
    RowLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignRight

        spacing: 8
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 8
        anchors.right: parent.right

        Button {
            text: qsTr("Add")
            flat: true
            icon.source: "qrc:/resource/images/add.svg"
            icon.width: 22
            icon.height: 22
            icon.color: 'black'
            onClicked: {
                headerModel.append({
                    "name": '',
                    "value": '',
                    "isEnabled": true
                });
                App.grpcQuery.addMetaItem('', '');
            }
        }
    }

    ListModel {
        id: headerModel
    }

    Connections {
        target: App.grpcQuery

        function onMetaChanged() {
            headerModel.clear();
            winHeader.fillData();
        }
    }

    Connections {
        target: winHeader

        function onChangeHeader(idx) {
            winHeader.sync(idx);
        }
    }

    Timer {
        id: syncTimer
        interval: 500
        running: true
        repeat: false
    }

    VarSyntaxHighlighter {
        id: varHilighter
    }

    function sync(idx) {
        syncTimer.triggered.connect(function () {
            let param = headerModel.get(idx);

            App.grpcQuery.setMetaItem(idx, param.name, param.value, param.isEnabled);
        });
        syncTimer.start();
    }

    function fillData() {
        for (let h of App.grpcQuery.meta) {
            headerModel.append({
                "name": h.name,
                "value": h.value,
                "isEnabled": h.isEnabled
            });
        }
    }
}

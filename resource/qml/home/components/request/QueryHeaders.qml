import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import core.app 1.0

import '../../../common/components'


Rectangle {

    signal changeHeader(int index)

    Component.onCompleted: {
        fillData()
    }

    id: winHeader
    anchors.fill: parent

    ListView {
        id: headerList
        width: parent.width
        height: parent.height - 50
        clip: true
        model: headerModel
        delegate: Rectangle {
            height: 60
            width: parent.width

            RowLayout {
                spacing: 16
                anchors.fill: parent

                CheckBox {
                    id: cbEnabled
                    checked: model.isEnabled
                    onClicked: {
                        headerModel.setProperty(index, "isEnabled", cbEnabled.checkState === Qt.Checked)
                        changeHeader(index)
                    }
                }
                Column {
                    Layout.fillWidth: true

                    FlickableEdit {
                        id: tfHeaderName
                        width: headerList.width / 3
                        height: 20
                        isEnabled: cbEnabled.checkState === Qt.Checked
                        value: model.name
                        onEditingFinish: txt => {
                            let header = headerModel.get(index)

                            App.query.setHeader(index, header.name, header.value, header.isEnabled)
                        }
                        onTextChange: txt => {
                            headerModel.setProperty(index, "name", txt)
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
                        value: model.value.toString()
                        onEditingFinish: txt => {
                             let header = headerModel.get(index)

                             App.query.setHeader(index, header.name, header.value, header.isEnabled)
                        }
                        onTextChange: txt => {
                            headerModel.setProperty(index, "value", txt)
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
                    icon.source: "/resource/images/close.svg"
                    icon.width: 22
                    icon.height: 22
                    icon.color: 'black'
                    onClicked: {
                        App.query.removeHeader(index)
                        headerModel.remove(index)
                    }
                }
            }
        }
    }
    RowLayout {
        spacing: 8
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 8
        anchors.right: parent.right
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignRight

        Button {
            text: qsTr("Add")
            flat: true
            icon.source: "/resource/images/add.svg"
            icon.width: 22
            icon.height: 22
            icon.color: 'black'
            onClicked: {
                headerModel.append({
                                       "name": '',
                                       "value": '',
                                       "isEnabled": true
                                   })
                App.query.addHeader('', '')
            }
        }
    }

    ListModel {
        id: headerModel
    }

    Connections {
        target: App

        function onQueryChanged() {
            headerModel.clear()

            fillData()
        }
    }

    Connections {
        target: winHeader

        function onChangeHeader(idx) {
            sync(idx)
        }
    }

    Timer {
        id: syncTimer
        interval: 500;
        running: true;
        repeat: false
    }

    function sync(idx) {
        syncTimer.triggered.connect(function () {
            let param = headerModel.get(idx)

            App.query.setHeader(idx, param.name, param.value, param.isEnabled)
        });
        syncTimer.start()
    }

    function fillData() {
        for (let h of App.query.headers) {
            headerModel.append({
                                   "name": h.name,
                                   "value": h.value,
                                   "isEnabled": h.isEnabled
                               })
        }
    }
}

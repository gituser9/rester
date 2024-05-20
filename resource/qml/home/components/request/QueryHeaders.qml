import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import core.app 1.0

import '../../../common/components'


Rectangle {

    anchors.fill: parent

    Component.onCompleted: {
        fillData()
    }

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

                Column {
                    Layout.fillWidth: true

                    FlickableEdit {
                        id: tfHeaderName
                        width: headerList.width / 3
                        height: 20
                        value: model.name
                        onEditingFinish: txt => {
                             let idx = 0

                             for (var i = 0; i < headerModel.count; ++i) {
                                 let item = headerModel.get(i)

                                 if (item.name === model.name) {
                                     idx = i
                                 }
                             }

                             let headers = App.query.headers
                             headers[txt] = tfHeaderValue.value
                             delete headers[model.name]

                             App.query.headers = headers
                             headerModel.set(idx, {
                                 "name": txt,
                                 "value": tfHeaderValue.value
                             })
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
                        value: model.value.toString()
                        onEditingFinish: txt => {
                            let headers = App.query.headers
                            headers[tfHeaderName.value] = txt
                            App.query.headers = headers
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
                        headerModel.remove(index)

                        let headers = {}

                        for (var i = 0; i < headerModel.count; ++i) {
                            const header = headerModel.get(i)
                            headers[header.name] = header.value
                        }

                        App.query.headers = headers
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
                                       "value": ''
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


    function fillData() {
        for (let key in App.query.headers) {
            headerModel.append({
                                   "name": key,
                                   "value": App.query.headers[key]
                               })
        }
    }
}

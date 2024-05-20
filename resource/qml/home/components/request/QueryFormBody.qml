import QtCore
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Dialogs

import core.app 1.0

import '../../../common/components'


Item {

    property bool isMultipart: true
    property string fileFieldName
    property int fileIndex: -1

    id: queryFormBody
    anchors.fill: parent

    Component.onCompleted: {
        checkIsMultipart()
        fillData()
    }

    ListView {
        id: formDataList
        width: parent.width
        height: parent.height - 50
        clip: true
        model: formDataModel
        delegate: Rectangle {
            height: 60
            width: formDataList.width

            RowLayout {
                id: itemRow
                spacing: 16
                anchors.fill: parent

                Column {
                    Layout.fillWidth: true

                    FlickableEdit {
                        id: tfFormDataName
                        width: itemRow.width / 3
                        height: 20
                        value: model.name
                        onEditingFinish: txt => {
                            tfFormDataName.value = txt
                            App.query.setFormDataItem(index, txt, tfFormDataValue.value, true)
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
                    id: colVal
                    Layout.fillWidth: true

                    FlickableEdit {
                        id: tfFormDataValue
                        visible: model.value.indexOf("file://") === -1
                        width: colVal.width
                        height: 20
                        value: model.value
                        onEditingFinish: txt => {
                            tfFormDataValue.value = txt
                            App.query.setFormDataItem(index, tfFormDataName.value, txt, true)
                        }
                    }
                    Rectangle {
                        visible: model.value.indexOf("file://") !== -1
                        height: 30
                        width: parent.width
                        color: 'lightgrey'
                        radius: 4

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                Layout.maximumWidth: colVal.width - 30

                                clip: true
                                text: extractFileName(model.value)
                            }
                            Image {
                                sourceSize.width: 14
                                sourceSize.height: 14
                                source: "/resource/images/close.svg"

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        tfFormDataValue.value = ''
                                        App.query.setFormDataItem(index, tfFormDataName.value, '', true)
                                        formDataModel.setProperty(index, "value", '')
                                    }
                                }
                            }
                        }

                    }

                    MenuSeparator {
                        visible: model.value.indexOf("file://") === -1
                        width: parent.width
                        contentItem: Rectangle {
                            implicitWidth: parent.width
                            implicitHeight: 1
                            color: "#1E000000"
                        }
                    }
                }
                // file button
                Row {
                    Button {
                        visible: isMultipart
                        flat: true
                        icon.source: "/resource/images/file-upload.svg"
                        icon.width: 18
                        icon.height: 18
                        icon.color: 'black'
                        onClicked: {
                            fileIndex = index
                            fileFieldName = tfFormDataName.value
                            fileDialog.open()
                        }
                    }
                    Button {
                        flat: true
                        icon.source: "/resource/images/close.svg"
                        icon.width: 18
                        icon.height: 18
                        icon.color: 'black'
                        onClicked: {
                            App.query.removeFormDateItem(index)
                            formDataModel.remove(index)
                        }
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
            icon.source: "/resource/images/add.svg"
            icon.width: 22
            icon.height: 22
            icon.color: 'black'
            onClicked: {
                formDataModel.append({
                    "name": '',
                    "value": '',
                    "isEnabled": true
                })
                App.query.addFormData('', '')
            }
        }
    }

    ListModel {
        id: formDataModel
    }


    FileDialog {
        id: fileDialog
        currentFolder: StandardPaths.standardLocations(StandardPaths.HomeLocation)[0]
        onAccepted:() => {
            formDataModel.set(fileIndex, {
                "name": fileFieldName,
                "value": selectedFile.toString(),
                "isEnabled": true
            })
            App.query.setFormDataItem(fileIndex, fileFieldName, selectedFile.toString(), true)

           fileFieldName = ''
           fileIndex = -1
        }
    }

    TextEdit{
        id: teCopy
        visible: false
    }


    Connections {
        target: App

        function onQueryChanged() {
            checkIsMultipart()

            if (isMultipart) {
                fillData()
            }
        }
    }


    function fillData() {
        formDataModel.clear()

        for (let fd of App.query.formData) {
            formDataModel.append({
                "name": fd.name,
                "value": fd.value
            })
        }
    }

    function checkIsMultipart() {
        if (App.query !== null) {
            isMultipart = App.query.bodyType === 2
        } else {
            isMultipart = false
        }
    }

    function clear() {
        formDataModel.clear()
        App.query.formData = []
    }

    function copy() {
        let copyStr = ""

        for (let key in App.query.formData) {
            copyStr += `${key}=${RoutesModel.query.formData[key]}\n`
        }

        teCopy.text = copyStr
        teCopy.selectAll()
        teCopy.copy()
        teCopy.clear()
    }

    function extractFileName(filePath) {
        let windowsRegex = /[^\\]*$/    // for Windows
        let unixRegex = /[^\/]*$/       // for UNIX

        let isWindows = filePath.includes('\\')
        let regexToUse = isWindows ? windowsRegex : unixRegex

        let fileName = filePath.match(regexToUse)[0]

        return fileName
    }
}

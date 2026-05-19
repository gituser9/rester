pragma ComponentBehavior: Bound

import QtCore
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Dialogs

import io.rester
import core.app 1.0

import "../../../common/components"

Item {
    id: queryFormBody
    anchors.fill: parent

    property bool isMultipart: true
    property string fileFieldName
    property int fileIndex: -1

    signal changeFormValue(int index)

    Component.onCompleted: {
        queryFormBody.checkIsMultipart();
        queryFormBody.fillData();
    }

    ListView {
        id: formDataList
        width: parent.width
        height: parent.height - 50
        clip: true
        model: formDataModel
        delegate: Rectangle {
            id: formDelegate
            height: 60
            width: formDataList.width

            required property bool isEnabled
            required property int index
            required property string name
            required property string value

            RowLayout {
                id: itemRow
                spacing: 16
                anchors.fill: parent

                CheckBox {
                    id: cbEnabled
                    checked: formDelegate.isEnabled
                    onClicked: {
                        formDataModel.setProperty(formDelegate.index, "isEnabled", cbEnabled.checkState === Qt.Checked);
                        queryFormBody.changeFormValue(formDelegate.index);
                    }
                }

                Column {
                    Layout.fillWidth: true

                    FlickableEdit {
                        id: tfFormDataName
                        width: itemRow.width / 3
                        height: 20
                        isEnabled: cbEnabled.checkState === Qt.Checked
                        value: formDelegate.name
                        onEditingFinish: txt => {
                            tfFormDataName.value = txt;
                            App.query.setFormDataItem(formDelegate.index, txt, tfFormDataValue.value, true);
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
                        visible: formDelegate.value.indexOf("file://") === -1
                        width: colVal.width
                        height: 20
                        isEnabled: cbEnabled.checkState === Qt.Checked
                        value: formDelegate.value
                        onEditingFinish: txt => {
                            tfFormDataValue.value = txt;
                            App.query.setFormDataItem(formDelegate.index, tfFormDataName.value, txt, true);
                        }
                    }
                    Rectangle {
                        visible: formDelegate.value.indexOf("file://") !== -1
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
                                text: queryFormBody.extractFileName(formDelegate.value)
                            }
                            Image {
                                sourceSize.width: 14
                                sourceSize.height: 14
                                source: "/resource/images/close.svg"

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        tfFormDataValue.value = '';
                                        App.query.setFormDataItem(formDelegate.index, tfFormDataName.value, '', true);
                                        formDataModel.setProperty(formDelegate.index, "value", '');
                                    }
                                }
                            }
                        }
                    }

                    MenuSeparator {
                        visible: formDelegate.value.indexOf("file://") === -1
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
                            fileIndex = formDelegate.index;
                            fileFieldName = tfFormDataName.value;
                            fileDialog.open();
                        }
                    }
                    Button {
                        flat: true
                        icon.source: "/resource/images/close.svg"
                        icon.width: 18
                        icon.height: 18
                        icon.color: 'black'
                        onClicked: {
                            App.query.removeFormDateItem(formDelegate.index);
                            formDataModel.remove(formDelegate.index);
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
                });
                App.query.addFormData('', '');
            }
        }
    }

    ListModel {
        id: formDataModel
    }

    FileDialog {
        id: fileDialog
        currentFolder: StandardPaths.standardLocations(StandardPaths.HomeLocation)[0]
        onAccepted: () => {
            formDataModel.set(fileIndex, {
                "name": fileFieldName,
                "value": selectedFile.toString(),
                "isEnabled": true
            });
            App.query.setFormDataItem(fileIndex, fileFieldName, selectedFile.toString(), true);

            fileFieldName = '';
            fileIndex = -1;
        }
    }

    TextEdit {
        id: teCopy
        visible: false
    }

    Connections {
        target: App

        function onQueryChanged() {
            queryFormBody.checkIsMultipart();

            if (isMultipart) {
                queryFormBody.fillData();
            }
        }
    }

    Connections {
        target: queryFormBody

        function changeFormValue(idx) {
            queryFormBody.sync(idx);
        }
    }

    Timer {
        id: syncTimer
        interval: 500
        running: true
        repeat: false
    }

    function sync(idx) {
        syncTimer.triggered.connect(function () {
            let param = headerModel.get(idx);

            App.query.setFormDataItem(idx, param.name, param.value, param.isEnabled);
        });
        syncTimer.start();
    }

    function fillData() {
        formDataModel.clear();

        for (let fd of App.query.formData) {
            formDataModel.append({
                "isEnabled": fd.isEnabled,
                "name": fd.name,
                "value": fd.value
            });
        }
    }

    function checkIsMultipart() {
        if (App.query !== null) {
            isMultipart = App.query.bodyType === 2;
        } else {
            isMultipart = false;
        }
    }

    function clear() {
        formDataModel.clear();
        App.query.formData = [];
    }

    function copy() {
        let copyStr = "";

        for (let param of App.query.formData) {
            copyStr += `${param.name}=${param.value}\n`;
        }

        teCopy.text = copyStr;
        teCopy.selectAll();
        teCopy.copy();
        teCopy.clear();
    }

    function extractFileName(filePath) {
        let windowsRegex = /[^\\]*$/;    // for Windows
        let unixRegex = /[^\/]*$/;       // for UNIX

        let isWindows = filePath.includes('\\');
        let regexToUse = isWindows ? windowsRegex : unixRegex;

        let fileName = filePath.match(regexToUse)[0];

        return fileName;
    }
}

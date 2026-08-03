pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable
pragma FunctionSignatureBehavior: Enforced

import QtCore
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Imagine
import QtQuick.Dialogs

import io.rester

import "../../../common/components"

Item {
    id: root
    anchors.fill: parent

    required property int bodyType
    property string fileFieldName
    property int fileIndex: -1
    readonly property Constants consts: Constants {}

    signal changeFormValue(int index)

    onBodyTypeChanged: {
        root.fillData();
    }

    Component.onCompleted: {
        root.fillData();
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
                        root.changeFormValue(formDelegate.index);
                    }
                }

                RstInput {
                    id: tfFormDataName
                    isEnabled: cbEnabled.checkState === Qt.Checked
                    tfWidth: itemRow.width / 3
                    value: formDelegate.name
                    onTextChanged: txt => {
                        tfFormDataName.value = txt;
                        formDataModel.setProperty(formDelegate.index, "name", txt);
                        App.query.setFormDataItem(formDelegate.index, txt, tfFormDataValue.value, true);
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
                            spacing: root.consts.space

                            Text {
                                Layout.maximumWidth: colVal.width - 30

                                clip: true
                                text: root.extractFileName(formDelegate.value)
                            }
                            Image {
                                sourceSize.width: 14
                                sourceSize.height: 14
                                source: "qrc:/qt/qml/io/rester/resource/images/close.svg"

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

                    RstDivider {
                        width: colVal.width
                        visible: formDelegate.value.indexOf("file://") === -1
                    }
                }
                // file button
                Row {
                    RstButton {
                        visible: App.query.queryType === RstEnums.BodyType.MULTIPART_FORM
                        size: RstButton.ButtonSize.Tool
                        icon: "qrc:/qt/qml/io/rester/resource/images/file-upload.svg"
                        onClicked: {
                            fileIndex = formDelegate.index;
                            fileFieldName = tfFormDataName.value;
                            fileDialog.open();
                        }
                    }
                    RstButton {
                        size: RstButton.ButtonSize.Tool
                        icon: "qrc:/qt/qml/io/rester/resource/images/close.svg"
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

        spacing: root.consts.space
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.consts.space
        anchors.right: parent.right

        RstButton {
            size: RstButton.ButtonSize.Tool
            text: qsTr("Add")
            icon: "qrc:/qt/qml/io/rester/resource/images/add.svg"
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

        function onQueryChanged(): void {
            root.fillData();
        }
    }

    Connections {
        target: root

        function changeFormValue(idx: int): void {
            root.sync(idx);
        }
    }

    Timer {
        id: syncTimer
        interval: 300
        running: true
        repeat: false
    }

    function sync(idx: int): void {
        syncTimer.triggered.connect(function (): void {
            let param = headerModel.get(idx);

            App.query.setFormDataItem(idx, param.name, param.value, param.isEnabled);
        });
        syncTimer.start();
    }

    function fillData(): void {
        formDataModel.clear();

        for (let fd of App.query.formData) {
            formDataModel.append({
                "isEnabled": fd.isEnabled,
                "name": fd.name,
                "value": fd.value
            });
        }
    }

    function clear(): void {
        formDataModel.clear();
        App.query.formData = [];
    }

    function copy(): void {
        let copyStr = "";

        for (let param of App.query.formData) {
            copyStr += `${param.name}=${param.value}\n`;
        }

        teCopy.text = copyStr;
        teCopy.selectAll();
        teCopy.copy();
        teCopy.clear();
    }

    function extractFileName(filePath: string): string {
        let windowsRegex = /[^\\]*$/;    // for Windows
        let unixRegex = /[^\/]*$/;       // for UNIX

        let isWindows = filePath.includes('\\');
        let regexToUse = isWindows ? windowsRegex : unixRegex;

        let fileName = filePath.match(regexToUse)[0];

        return fileName;
    }
}

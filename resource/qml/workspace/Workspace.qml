import QtCore
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Dialogs

import WorkspaceModel
import core.app 1.0

import "../home/modal"

Rectangle {

    property string _currentUuid: ''
    property string folderDialogMode: ''
    property int currentIndex: -1
    property bool isLoading: true

    id: ws
    anchors.fill: parent
    color: 'white'

    HoverHandler {
        id: mouse
        acceptedDevices: PointerDevice.Mouse
        cursorShape: Qt.PointingHandCursor
    }

    ColumnLayout {
        anchors.fill: parent

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: qsTr("Workspaces")
                font.bold: true
                font.pointSize: 15
            }
            Item {
                Layout.fillWidth: true
            }
            Button {
                Layout.rightMargin: 8

                flat: true
                text: qsTr("Open Folder")
                icon.source: "/resource/images/folder.svg"
                icon.width: 24
                icon.height: 24
                icon.color: 'black'
                onClicked: {
                    let path = StandardPaths.standardLocations(StandardPaths.ConfigLocation)[0]
                    path += '/rester/workspaces'
                    Qt.openUrlExternally(path)
                }
            }
            Button {
                Layout.rightMargin: 8

                flat: true
                text: qsTr("Add")
                icon.source: "/resource/images/add.svg"
                icon.width: 24
                icon.height: 24
                icon.color: 'black'
                onClicked: {
                    mdlAddWorkspace.open()
                }
            }
            Button {
                Layout.rightMargin: 8

                flat: true
                text: qsTr("Download")
                icon.source: "/resource/images/download.svg"
                icon.width: 24
                icon.height: 24
                icon.color: 'black'
                onClicked: {
                    ws.folderDialogMode = 'export'
                    folderDialog.open()
                }
            }
            Button {
                Layout.rightMargin: 8

                flat: true
                text: qsTr("Upload")
                icon.source: "/resource/images/upload.svg"
                icon.width: 24
                icon.height: 24
                icon.color: 'black'
                onClicked: {
                    dlgImport.open()
                }
            }
        }

        Rectangle {
            Layout.fillHeight: true
            Layout.fillWidth: true

            // visible: ws.isLoading
            visible: ws.isLoading
            // enabled: ws.isLoading

            Image {
                id: imgLoad
                anchors.centerIn: parent
                source: "/resource/images/rotate-loop.svg"
                sourceSize.width: 50
                sourceSize.height: 50
                states: State {
                    name: "rotated"
                    when: ws.isLoading

                    PropertyChanges {
                        target: imgLoad
                        rotation: 360
                    }
                }
                transitions: Transition {
                    RotationAnimation {
                        id: animLoad
                        loops: Animation.Infinite
                        duration: 500
                        direction: RotationAnimation.Clockwise
                    }
                }
            }
        }

        ScrollView {
            Layout.fillHeight: true
            Layout.fillWidth: true

            Component.onCompleted: {
                WorkspaceModel.setup()
                showLoader()
            }

            Component.onDestruction: {
                WorkspaceModel.clean()
            }

            id: scroller
            clip : true
            visible: !ws.isLoading
            contentHeight: grid.rows * 290
            contentWidth: ws.width

            GridLayout {
                readonly property int elementWidth: 230

                id: grid
                anchors.fill: parent
                columns: Math.max(Math.floor(parent.width / elementWidth), 1)
                rows: Math.max(Math.ceil(children.length / columns), 1)
                rowSpacing: 16
                columnSpacing: 16

                Repeater {
                    id: repeater
                    model: WorkspaceModel

                    ColumnLayout {
                        id: wsCol
                        width: grid.elementWidth
                        height: grid.elementWidth + 60

                        Rectangle {
                            id: wsRect
                            width: grid.elementWidth
                            height: grid.elementWidth
                            border.color: App.workspace.uuid === model.uuid ? 'blue' : 'lightgrey'
                            radius: 4

                            Text {
                                anchors.centerIn: parent
                                text: model.name
                                font.bold: true
                                font.pointSize: 16
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: (mouse) => {
                                   if (mouse.button === Qt.LeftButton) {
                                       WorkspaceModel.setWorkspace(index)
                                   }

                                   if (mouse.button === Qt.RightButton) {
                                       currentIndex = index
                                       contextMenu.popup()
                                   }
                                }

                                Menu {
                                    id: contextMenu

                                    MenuItem {
                                        enabled: App.workspace.uuid !== model.uuid
                                        text: qsTr("Choose")
                                        onTriggered: {
                                            WorkspaceModel.setWorkspace(index)
                                        }
                                    }
                                    MenuItem {
                                        text: qsTr("Export")
                                        onTriggered: {
                                            dlgExport.open()
                                        }
                                    }
                                    MenuItem {
                                        text: qsTr("Edit")
                                        onTriggered: {
                                            currentIndex = index
                                            mdlUpdWorkspace.open()
                                        }
                                    }
                                    MenuItem {
                                        enabled: App.workspace.uuid !== model.uuid
                                        text: qsTr("Delete")
                                        onTriggered: {
                                            currentIndex = index
                                            dlgRemoveWs.open()
                                        }
                                    }
                                }
                            }
                        }
                        RowLayout {
                            // Layout.fillWidth: true
                            Layout.topMargin: 4
                            Layout.preferredWidth: wsRect.width

                            height: 40

                            Button {
                                flat: true
                                icon.source: "/resource/images/pencil.svg"
                                icon.width: 16
                                icon.height: 16
                                icon.color: 'black'
                                onClicked: {
                                    currentIndex = index
                                    mdlUpdWorkspace.currentText = model.name
                                    mdlUpdWorkspace.open()
                                }
                            }
                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 30

                                Column {
                                    anchors.fill: parent

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        font.pointSize: 10
                                        text: qsTr("Last Usage At")
                                        color: 'lightgrey'
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        font.pointSize: 10
                                        text: model.lastUsageAt === 0 ? qsTr("Never") : getLastUsageString(model.lastUsageAt)
                                        color: 'lightgrey'
                                    }
                                }
                            }
                            Item {
                                Layout.preferredWidth: 50

                                visible: App.workspace.uuid === model.uuid
                            }
                            Button {
                                visible: App.workspace.uuid !== model.uuid
                                flat: true
                                icon.source: "/resource/images/close.svg"
                                icon.width: 16
                                icon.height: 16
                                icon.color: 'black'
                                onClicked: {
                                    currentIndex = index
                                    dlgRemoveWs.open()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Popup {
        id: dlgExport
        anchors.centerIn: parent
        width: parent.width / 2
        height: parent.height / 2
        modal: Qt.ApplicationModal

        ColumnLayout {
            anchors.fill: parent

            Text {
                text: qsTr("Export workspace")
                font.pointSize: 16
                font.bold: true
            }
            RowLayout {
                Layout.fillWidth: true

                TextField {
                    Layout.fillWidth: true
                    Layout.rightMargin: 10

                    id: tfExportInput
                    // width: parent.width
                    placeholderText: qsTr("Path to exported folder")
                }
                Button {
                    flat: true
                    icon.source: "/resource/images/folder.svg"
                    icon.width: 22
                    icon.height: 22
                    icon.color: 'black'
                    onClicked: {
                        ws.folderDialogMode = 'export_collection'
                        folderDialog.open()
                    }
                }
            }
            Text {
                text: qsTr("set path for export's file")
            }
            ComboBox {
                Layout.fillWidth: true

                id: cbExportType
                model: ["Rester", "Insomnia (v4)", "Postman"]
            }

            Button {
                Layout.fillWidth: true
                Layout.preferredHeight: 40

                text: qsTr("Export")
                onClicked: {
                    if (tfExportInput.text === '') {
                        return
                    }

                    WorkspaceModel.exportCollection(tfExportInput.text, currentIndex, cbExportType.currentIndex)
                    dlgExport.close()
                }
            }
        }
    }

    Popup {
        id: dlgImport
        anchors.centerIn: parent
        width: parent.width / 2
        height: parent.height / 2
        modal: Qt.ApplicationModal

        ColumnLayout {
            anchors.fill: parent

            Text {
                text: qsTr("Import from other client")
                font.pointSize: 16
                font.bold: true
            }
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 30

                TextField {
                    Layout.fillWidth: true
                    Layout.rightMargin: 10

                    id: tfInput
                    placeholderText: qsTr("Path to exported config")
                }
                Button {
                    flat: true
                    icon.source: "/resource/images/file-upload.svg"
                    icon.width: 22
                    icon.height: 22
                    icon.color: 'black'
                    onClicked: {
                        switch (cbImportType.currentIndex) {
                        case 0:
                        case 2:
                            ws.folderDialogMode = 'import'
                            folderDialog.open()
                            break;
                        default:
                            fileDialog.open()
                        }
                    }
                }
            }
            Text {
                text: getInfoStringForImport()
            }
            ComboBox {
                Layout.fillWidth: true

                id: cbImportType
                model: ["Rester", "Insomnia (v4)", "Postman"]
            }

            Button {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredHeight: 30

                text: qsTr("Import")
                onClicked: {
                    if (tfInput.text === '') {
                        return
                    }

                    WorkspaceModel.importFrom(tfInput.text, cbImportType.currentIndex)
                    dlgImport.close()
                }
            }
        }
    }

    InputDialog {
        id: mdlUpdWorkspace
        anchors.centerIn: parent
        title: qsTr("Update Workspace")
        placeholder: qsTr("Workspace Name")
        onOk: wsName => {
            WorkspaceModel.update(currentIndex, wsName)
        }
    }

    InputDialog {
        id: mdlAddWorkspace
        anchors.centerIn: parent
        title: qsTr("Create Workspace")
        placeholder: qsTr("Workspace Name")
        onOk: wsName => {
            WorkspaceModel.create(wsName)
        }
    }

    MessageDialog {
        id: dlgRemoveWs
        title: "Accept Remove"
        text: "Remove Workspace?"
        buttons: MessageDialog.Ok | MessageDialog.Cancel
        modality: Qt.ApplicationModal
        onAccepted: {
            WorkspaceModel.removeRows(currentIndex, 1)
        }
    }

    FileDialog {
        id: fileDialog
        currentFolder: StandardPaths.standardLocations(StandardPaths.HomeLocation)[0]
        nameFilters: ["JSON files (*.json)"]
        onAccepted: () => {
                        let path = selectedFile.toString().replace("file://", "")
                        tfInput.text = path
                    }
    }

    FolderDialog {
        id: folderDialog
        currentFolder: StandardPaths.standardLocations(StandardPaths.HomeLocation)[0]
        onAccepted: {
            let path = selectedFolder.toString().replace("file://", "")
            folderDialogAccept(path)
        }
    }

    Timer {
        id: loaderTimer
        interval: 1;
        running: true;
        repeat: false
    }

    Timer {
        id: loadTimer
        interval: 100;
        running: true;
        repeat: false
    }


    function getLastUsageString(msecs) {
        let date = new Date(msecs)
        let str = `${date.getDate()}.${date.getMonth()+1}.${date.getFullYear()} ${date.getHours()}:${date.getMinutes()}`

        return str
    }

    function getInfoStringForImport() {
        switch (cbImportType.currentIndex) {
        case 0:
            return qsTr(`set path to "workspaces" folder`)
        case 1:
            return qsTr(`set path to Insomnia workspace file`)
        case 2:
            return qsTr(`set path to Postman collection file`)
        }
    }

    function folderDialogAccept(path) {
        if (folderDialogMode === 'import') {
            tfInput.text = path
        }

        if (folderDialogMode === 'export') {
            WorkspaceModel.exportTo(path)
        }

        if (folderDialogMode === 'export_collection') {
            tfExportInput.text = path
        }
    }

    function showLoader() {
        loadTimer.triggered.connect(function () {
            isLoading = true
        });
        loadTimer.start()

        loaderTimer.triggered.connect(function () {
            WorkspaceModel.loadWorkspaces()
            isLoading = false
            loadTimer.stop()
        });
        loaderTimer.start();
    }
}

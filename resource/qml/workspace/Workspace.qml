pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable

import QtCore
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Dialogs
// import Qt.labs.platform

import io.rester
import WorkspaceModel
import core.app 1.0

import "../home/modal"
import "../common/components"

Rectangle {
    id: ws

    property string _currentUuid: ''
    property string folderDialogMode: ''
    property int currentIndex: -1
    property bool isLoading: true
    anchors.fill: parent
    // color: 'white'

    HoverHandler {
        id: mouse
        acceptedDevices: PointerDevice.Mouse
        cursorShape: Qt.PointingHandCursor
    }

    ColumnLayout {
        anchors.fill: parent

        // Control Buttons
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
                icon.width: 20
                icon.height: 20
                icon.color: 'black'
                onClicked: {
                    let path = StandardPaths.standardLocations(StandardPaths.ConfigLocation)[0];
                    path += '/rester/workspaces';
                    Qt.openUrlExternally(path);
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
                    mdlAddWorkspace.open();
                }
            }
            Button {
                Layout.rightMargin: 8

                flat: true
                text: qsTr("Download")
                icon.source: "/resource/images/download.svg"
                icon.width: 20
                icon.height: 20
                icon.color: 'black'
                onClicked: {
                    ws.folderDialogMode = 'export';
                    folderDialog.open();
                }
            }
            Button {
                Layout.rightMargin: 8

                flat: true
                text: qsTr("Upload")
                icon.source: "/resource/images/upload.svg"
                icon.width: 20
                icon.height: 20
                icon.color: 'black'
                onClicked: {
                    dlgImport.open();
                }
            }
        }

        // load widget
        Rectangle {
            Layout.fillHeight: true
            Layout.fillWidth: true

            visible: ws.isLoading

            Image {
                id: imgLoad
                y: (ws.height / 2) - 25
                x: (ws.width / 2) - 25

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

        // Search field
        FlickableEdit {
            id: searchField
            isEnabled: true
            placeholder: "Search"
            height: 20
            value: ""
            onTextChange: txt => {
                WorkspaceModel.filter(txt);
            }

            Layout.fillWidth: true
            Layout.topMargin: 8
        }
        MenuSeparator {
            Layout.fillWidth: true

            contentItem: Rectangle {
                implicitWidth: parent.width
                implicitHeight: 1
                color: "#1E000000"
            }
        }

        // WS
        ScrollView {
            id: scroller
            clip: true
            contentHeight: grid.rows * 290
            contentWidth: ws.width

            Layout.fillHeight: true
            Layout.fillWidth: true

            Component.onCompleted: {
                ws.showLoader();
            }

            Component.onDestruction: {
                WorkspaceModel.clean();
            }

            GridLayout {
                id: grid
                anchors.fill: parent
                columns: Math.max(Math.floor(parent.width / elementWidth), 1)
                rows: Math.max(Math.ceil(children.length / columns), 1)
                rowSpacing: 16
                columnSpacing: 16

                readonly property int elementWidth: 230

                Repeater {
                    id: repeater
                    model: WorkspaceModel

                    ColumnLayout {
                        id: wsCol
                        width: grid.elementWidth
                        height: grid.elementWidth + 60

                        required property string uuid
                        required property string name
                        required property int index
                        required property int lastUsageAt

                        Rectangle {
                            id: wsRect
                            width: grid.elementWidth
                            height: grid.elementWidth
                            border.color: App.workspace.uuid === wsCol.uuid ? 'blue' : 'lightgrey'
                            radius: 4

                            Text {
                                anchors.centerIn: parent
                                text: wsCol.name
                                font.bold: true
                                font.pointSize: 16
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: mouse => {
                                    if (mouse.button === Qt.LeftButton) {
                                        WorkspaceModel.setWorkspace(wsCol.index);
                                    }

                                    if (mouse.button === Qt.RightButton) {
                                        ws.currentIndex = wsCol.index;
                                        contextMenu.popup();
                                    }
                                }

                                Menu {
                                    id: contextMenu

                                    MenuItem {
                                        enabled: App.workspace.uuid !== wsCol.uuid
                                        text: qsTr("Choose")
                                        onTriggered: {
                                            WorkspaceModel.setWorkspace(wsCol.index);
                                        }
                                    }
                                    MenuItem {
                                        text: qsTr("Export")
                                        onTriggered: {
                                            dlgExport.open();
                                        }
                                    }
                                    MenuItem {
                                        text: qsTr("Edit")
                                        onTriggered: {
                                            ws.currentIndex = wsCol.index;
                                            mdlUpdWorkspace.open();
                                        }
                                    }
                                    MenuItem {
                                        enabled: App.workspace.uuid !== wsCol.uuid
                                        text: qsTr("Delete")
                                        onTriggered: {
                                            ws.currentIndex = wsCol.index;
                                            dlgRemoveWs.open();
                                        }
                                    }
                                }
                            }
                        }

                        // WS Buttons
                        RowLayout {
                            Layout.topMargin: 4
                            Layout.maximumWidth: grid.elementWidth + 20
                            Layout.preferredHeight: 30

                            Button {
                                flat: true
                                icon.source: "/resource/images/pencil.svg"
                                icon.width: 16
                                icon.height: 16
                                icon.color: 'black'
                                onClicked: {
                                    ws.currentIndex = wsCol.index;
                                    mdlUpdWorkspace.currentText = wsCol.name;
                                    mdlUpdWorkspace.open();
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
                                        text: wsCol.lastUsageAt === 0 ? qsTr("Never") : ws.getLastUsageString(wsCol.lastUsageAt)
                                        color: 'lightgrey'
                                    }
                                }
                            }
                            Item {
                                Layout.preferredWidth: 50

                                visible: App.workspace.uuid === wsCol.uuid
                            }
                            Button {
                                Layout.rightMargin: 17

                                visible: App.workspace.uuid !== wsCol.uuid
                                flat: true
                                icon.source: "/resource/images/close.svg"
                                icon.width: 16
                                icon.height: 16
                                icon.color: 'black'
                                onClicked: {
                                    ws.currentIndex = wsCol.index;
                                    dlgRemoveWs.open();
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
                    id: tfExportInput
                    placeholderText: qsTr("Path to exported folder")

                    Layout.fillWidth: true
                    Layout.rightMargin: 10
                }
                Button {
                    flat: true
                    icon.source: "/resource/images/folder.svg"
                    icon.width: 22
                    icon.height: 22
                    icon.color: 'black'
                    onClicked: {
                        ws.folderDialogMode = 'export_collection';
                        folderDialog.open();
                    }
                }
            }
            Text {
                text: qsTr("set path for export's file")
            }
            ComboBox {
                id: cbExportType
                Layout.fillWidth: true
                model: ["Rester", "Postman", "Insomnia (v5)", "HAR"]
            }

            Button {
                Layout.fillWidth: true
                Layout.preferredHeight: 40

                text: qsTr("Export")
                onClicked: {
                    if (tfExportInput.text === '') {
                        return;
                    }

                    let importType = ws.getImportType(cbExportType.currentText);
                    WorkspaceModel.exportCollection(tfExportInput.text, ws.currentIndex, importType);
                    dlgExport.close();
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
                    id: tfInput
                    placeholderText: qsTr("Path to exported config")

                    Layout.fillWidth: true
                    Layout.rightMargin: 10
                }
                Button {
                    flat: true
                    icon.source: "/resource/images/file-upload.svg"
                    icon.width: 22
                    icon.height: 22
                    icon.color: 'black'
                    onClicked: {
                        fileDialog.open();
                    }
                }
            }
            Text {
                text: qsTr(`set path to file`)
            }
            ComboBox {
                id: cbImportType
                Layout.fillWidth: true
                model: ["Rester", "Postman", "Insomnia (v5)", "Swagger | OpenAPI", "HAR"]
            }

            Button {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredHeight: 30

                text: qsTr("Import")
                onClicked: {
                    if (tfInput.text === '') {
                        return;
                    }

                    let importType = ws.getImportType(cbImportType.currentText);
                    WorkspaceModel.importFrom(tfInput.text, importType);
                    dlgImport.close();
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
            WorkspaceModel.update(ws.currentIndex, wsName);
        }
    }

    InputDialog {
        id: mdlAddWorkspace
        anchors.centerIn: parent
        title: qsTr("Create Workspace")
        placeholder: qsTr("Workspace Name")
        onOk: wsName => {
            WorkspaceModel.create(wsName);
        }
    }

    MessageDialog {
        id: dlgRemoveWs
        title: "Accept Remove"
        text: "Remove Workspace?"
        buttons: MessageDialog.Ok | MessageDialog.Cancel
        modality: Qt.ApplicationModal
        onAccepted: {
            WorkspaceModel.removeRows(ws.currentIndex, 1);
        }
    }

    FileDialog {
        id: fileDialog
        currentFolder: StandardPaths.standardLocations(StandardPaths.HomeLocation)[0]
        nameFilters: ["JSON files (*.json)"]
        onAccepted: () => {
            let path = selectedFile.toString().replace("file://", "");
            tfInput.text = path;
        }
    }

    FolderDialog {
        id: folderDialog
        currentFolder: StandardPaths.standardLocations(StandardPaths.HomeLocation)[0]
        onAccepted: {
            let path = selectedFolder.toString().replace("file://", "");
            ws.folderDialogAccept(path);
        }
    }

    Timer {
        id: loaderTimer
        interval: 1
        running: true
        repeat: false
    }

    Timer {
        id: loadTimer
        interval: 150
        running: true
        repeat: false
    }

    function getLastUsageString(msecs) {
        let date = new Date(msecs);
        let str = `${date.getDate()}.${date.getMonth() + 1}.${date.getFullYear()} ${date.getHours()}:${date.getMinutes()}`;

        return str;
    }

    function folderDialogAccept(path) {
        if (folderDialogMode === 'import') {
            tfInput.text = path;
        }

        if (folderDialogMode === 'export') {
            WorkspaceModel.exportTo(path);
        }

        if (folderDialogMode === 'export_collection') {
            tfExportInput.text = path;
        }
    }

    function showLoader() {
        loadTimer.triggered.connect(function () {
            ws.isLoading = true;
        });
        loadTimer.start();

        loaderTimer.triggered.connect(function () {
            WorkspaceModel.loadWorkspaces();
            ws.isLoading = false;
            loadTimer.stop();
        });
        loaderTimer.start();
    }

    function getImportType(typeStr) {
        if (typeStr === "Rester") {
            return 0;
        }

        if (typeStr === "Postman") {
            return 1;
        }

        if (typeStr === "Insomnia (v5)") {
            return 2;
        }

        if (typeStr === "Swagger") {
            return 3;
        }

        if (typeStr === "HAR") {
            return 4;
        }
    }
}

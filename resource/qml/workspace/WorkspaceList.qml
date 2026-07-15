pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable
pragma FunctionSignatureBehavior: Enforced

import QtCore
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Imagine
import QtQuick.Dialogs

import io.rester

import "../home/modal"
import "../common/components"

Item {
    id: ws
    anchors.fill: parent

    property string _currentUuid: ''
    property string folderDialogMode: ''
    property int currentIndex: -1
    property bool isLoading: true
    property Constants consts: Constants {}

    ColumnLayout {
        anchors.fill: parent

        // Control Buttons
        RowLayout {
            spacing: ws.consts.space

            Layout.fillWidth: true

            Text {
                text: qsTr("Workspaces")
                font.bold: true
                font.pointSize: 15
            }
            Item {
                Layout.fillWidth: true
            }
            RstButton {
                size: RstButton.ButtonSize.Tool
                text: qsTr("Open Folder")
                icon: "qrc:/qt/qml/io/rester/resource/images/folder.svg"
                onClicked: {
                    let path = StandardPaths.standardLocations(StandardPaths.ConfigLocation)[0];
                    path += '/rester/workspaces';
                    Qt.openUrlExternally(path);
                }
            }
            RstButton {
                size: RstButton.ButtonSize.Big
                text: qsTr("Add")
                icon: "qrc:/qt/qml/io/rester/resource/images/add.svg"
                onClicked: {
                    mdlAddWorkspace.open();
                }
            }
            RstButton {
                size: RstButton.ButtonSize.Tool
                text: qsTr("Download")
                icon: "qrc:/qt/qml/io/rester/resource/images/download.svg"
                onClicked: {
                    ws.folderDialogMode = 'export';
                    folderDialog.open();
                }
            }
            RstButton {
                size: RstButton.ButtonSize.Tool
                text: qsTr("Upload")
                icon: "qrc:/qt/qml/io/rester/resource/images/upload.svg"
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

                source: "qrc:/qt/qml/io/rester/resource/images/rotate-loop.svg"
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
                App.workspaceModel.filter(txt);
            }

            Layout.fillWidth: true
            Layout.topMargin: 8
        }
        RstDivider {
            Layout.fillWidth: true
        }

        // WS
        ScrollView {
            id: scroller
            // clip: true
            contentHeight: grid.rows * 290
            contentWidth: ws.width

            Layout.fillHeight: true
            Layout.fillWidth: true

            Component.onCompleted: {
                ws.showLoader();
            }

            Component.onDestruction: {
                App.workspaceModel.clean();
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
                    model: App.workspaceModel

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
                            radius: 4
                            border.color: App.workspace.uuid === wsCol.uuid ? '#6366F1' : '#E0E0E0'
                            border.width: App.workspace.uuid === wsCol.uuid ? 2 : 1

                            Rectangle {
                                anchors.fill: parent
                                color: 'transparent'
                                visible: App.workspace.uuid === wsCol.uuid
                                radius: parent.radius

                                Rectangle {
                                    anchors.fill: parent
                                    color: '#6366F1'
                                    opacity: 0.08
                                    radius: parent.radius
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: wsCol.name
                                font.bold: true
                                font.pointSize: 16
                            }
                            Button {
                                id: menuBtn
                                z: 2
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.topMargin: 4
                                anchors.rightMargin: 4
                                visible: true
                                flat: true
                                icon.source: "qrc:/qt/qml/io/rester/resource/images/more-line.svg"
                                icon.width: 18
                                icon.height: 18
                                icon.color: 'black'
                                onClicked: {
                                    ws.currentIndex = wsCol.index;
                                    contextMenu.popup();
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: mouse => {
                                    if (mouse.button === Qt.LeftButton) {
                                        if (App.workspace.uuid === wsCol.uuid) {
                                            return;
                                        }

                                        App.workspaceModel.setWorkspace(wsCol.index);
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
                                            App.workspaceModel.setWorkspace(wsCol.index);
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
                                            mdlUpdWorkspace.currentText = wsCol.name;
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

                            RstButton {
                                size: RstButton.ButtonSize.Mini
                                icon: "qrc:/qt/qml/io/rester/resource/images/pencil.svg"
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
                            RstButton {
                                Layout.rightMargin: 17

                                visible: App.workspace.uuid !== wsCol.uuid
                                size: RstButton.ButtonSize.Mini
                                icon: "qrc:/qt/qml/io/rester/resource/images/close.svg"
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

    // Modals
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
                RstButton {
                    icon: "qrc:/qt/qml/io/rester/resource/images/folder.svg"
                    onClicked: {
                        ws.folderDialogMode = 'export_collection';
                        folderDialog.open();
                    }
                }
            }
            Text {
                text: qsTr("set path for export's file")
            }
            RstDropdown {
                id: cbExportType
                placeholder: qsTr("Export Type")
                currentText: mdlExport.get(cbExportType.index).text
                model: mdlExport
                itemDelegate: Component {
                    Item {
                        id: exportDelegateLayout

                        property var itemData: null
                        property int itemIndex: 0

                        Text {
                            text: exportDelegateLayout.itemData.text
                        }
                    }
                }

                Layout.fillWidth: true
                Layout.preferredHeight: ws.consts.bottomButtonHeight
            }

            Button {
                Layout.fillWidth: true
                Layout.preferredHeight: 40

                text: qsTr("Export")
                onClicked: {
                    if (tfExportInput.text === '') {
                        return;
                    }

                    let exportType = mdlExport.get(cbExportType.index);
                    App.workspaceModel.exportCollection(tfExportInput.text, ws.currentIndex, exportType);
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
                    icon.source: "qrc:/qt/qml/io/rester/resource/images/file-upload.svg"
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
            RstDropdown {
                id: cbImportType
                placeholder: qsTr("Import Type")
                currentText: mdlImport.get(cbImportType.index).text
                model: mdlImport
                itemDelegate: Component {
                    id: importDelegate

                    Item {
                        id: delegateLayout

                        property var itemData: null
                        property int itemIndex: 0

                        Text {
                            text: delegateLayout.itemData.text
                        }
                    }
                }

                Layout.fillWidth: true
                Layout.preferredHeight: ws.consts.bottomButtonHeight
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

                    let importType = mdlImport.get(cbImportType.index).value;
                    App.workspaceModel.importFrom(tfInput.text, importType);
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
            App.workspaceModel.update(ws.currentIndex, wsName);
        }
    }

    InputDialog {
        id: mdlAddWorkspace
        anchors.centerIn: parent
        title: qsTr("Create Workspace")
        placeholder: qsTr("Workspace Name")
        onOk: wsName => {
            App.workspaceModel.create(wsName);
        }
    }

    MessageDialog {
        id: dlgRemoveWs
        title: "Accept Remove"
        text: "Remove Workspace?"
        buttons: MessageDialog.Ok | MessageDialog.Cancel
        modality: Qt.ApplicationModal
        onAccepted: {
            App.workspaceModel.removeRows(ws.currentIndex, 1);
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

    // Types
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

    ListModel {
        id: mdlImport

        Component.onCompleted: {
            append({
                text: "Rester",
                value: RstEnums.ImportType.Rester
            });
            append({
                text: "Postman",
                value: RstEnums.ImportType.Postman
            });
            append({
                text: "Insomnia v5",
                value: RstEnums.ImportType.InsomniaV5
            });
            append({
                text: "Swagger | OpenAPI",
                value: RstEnums.ImportType.Swagger
            });
            append({
                text: "HAR",
                value: RstEnums.ImportType.Har
            });
        }
    }

    ListModel {
        id: mdlExport

        Component.onCompleted: {
            append({
                text: "Rester",
                value: RstEnums.ImportType.Rester
            });
            append({
                text: "Postman",
                value: RstEnums.ImportType.Postman
            });
            append({
                text: "Insomnia v5",
                value: RstEnums.ImportType.InsomniaV5
            });
            append({
                text: "HAR",
                value: RstEnums.ImportType.Har
            });
        }
    }

    // Funcs
    function getLastUsageString(msecs: int): string {
        let date = new Date(msecs);
        let str = `${date.getDate()}.${date.getMonth() + 1}.${date.getFullYear()} ${date.getHours()}:${date.getMinutes()}`;

        return str;
    }

    function folderDialogAccept(path: string): void {
        if (folderDialogMode === 'import') {
            tfInput.text = path;
        }

        if (folderDialogMode === 'export') {
            App.workspaceModel.exportTo(path);
        }

        if (folderDialogMode === 'export_collection') {
            tfExportInput.text = path;
        }
    }

    function showLoader(): void {
        loadTimer.triggered.connect(() => {
            ws.isLoading = true;
        });
        loadTimer.start();

        loaderTimer.triggered.connect(() => {
            App.workspaceModel.loadWorkspaces();
            ws.isLoading = false;
            loadTimer.stop();
        });
        loaderTimer.start();
    }
}

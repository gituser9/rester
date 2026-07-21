pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable
pragma FunctionSignatureBehavior: Enforced

import QtQuick
import QtQuick.Controls.Imagine
import QtQuick.Layouts
import QtQuick.Dialogs

import io.rester

import "./components"
import "./modal"

// TODO: consts
Item {
    id: routesItem

    property var currentIndex
    property int currentRow: -1
    property var moveIndex
    property string removeUuid

    ColumnLayout {
        anchors.fill: parent

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 48

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                anchors.topMargin: 12

                RstButton {
                    size: RstButton.ButtonSize.Big
                    icon: "qrc:/qt/qml/io/rester/resource/images/folder-add.svg"
                    text: qsTr("Add Folder")
                    onClicked: {
                        mdlAddFolder.open();
                    }

                    Layout.fillWidth: true
                }
                RstButton {
                    size: RstButton.ButtonSize.Big
                    icon: "qrc:/qt/qml/io/rester/resource/images/arrow-up-down.svg"
                    text: qsTr("Add Request")
                    onClicked: {
                        mdlAddQuery.open();
                    }

                    Layout.fillWidth: true
                }
            }
        }
        Item {
            Layout.preferredHeight: 3
        }
        RstDivider {
            Layout.fillWidth: true
        }

        // pins
        Pins {
            Layout.fillWidth: true
            Layout.preferredHeight: App.workspace.pins.length * 40

            onSetQuery: uuid => {
                routesItem.currentRow = -1;
                App.setQueryByUuid(uuid);
            }
        }
        RstDivider {
            visible: App.workspace.pins.length > 0
            Layout.fillWidth: true
        }

        // routes
        TreeView {
            id: treeViewItem
            clip: true
            model: App.routesFilterModel
            reuseItems: false

            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.topMargin: 8

            delegate: ItemDelegate {
                id: root
                implicitHeight: rowHeight
                implicitWidth: treeViewItem.width

                required property bool current
                required property int depth
                required property int row
                required property int column
                required property bool expanded
                required property bool hasChildren
                readonly property real indent: 20
                required property bool isTreeNode
                required property TreeView treeView

                required property int nodeType
                required property string nodeUuid
                required property string parentUuid
                required property string nodeName
                required property string nodeQueryType
                required property bool isFolderExpanded

                readonly property int rowHeight: 45

                DropArea {
                    id: dropArea
                    anchors.fill: parent
                    implicitHeight: 45
                    implicitWidth: treeViewItem.width

                    onDropped: drag => {
                        dragContainer.color = "transparent";
                        App.routesFilterModel.moveRows(routesItem.moveIndex.parent, routesItem.moveIndex.row, 1, root.treeView.index(root.row, root.column), root.row);
                    }
                    onEntered: drag => {
                        dragContainer.color = "lightblue";
                    }
                    onExited: {
                        dragContainer.color = "transparent";
                    }
                }
                Rectangle {
                    id: dragContainer
                    color: 'transparent'
                    implicitHeight: 45
                    implicitWidth: treeViewItem.width

                    Loader {
                        id: nodeLoader
                        sourceComponent: root.nodeType === RstEnums.NodeType.FolderNode ? folderComponent : queryComponent
                    }
                }
                Component {
                    id: folderComponent

                    RoutesFolderNode {
                        id: folderNode
                        hasChildren: root.hasChildren
                        dragParent: treeViewItem
                        height: root.height
                        imgPadding: (root.depth * root.indent)
                        isExpanded: root.expanded
                        name: root.nodeName
                        parentUuid: parentUuid
                        width: root.width - (root.isTreeNode ? (root.depth + 1) * root.indent : 0) - 8
                        x: root.isTreeNode ? (root.depth + 1) * root.indent : 0

                        Component.onCompleted: {
                            if (root.isFolderExpanded) {
                                root.treeView.expand(root.row);
                            } else if (!root.isFolderExpanded) {
                                root.treeView.collapse(root.row);
                            }
                        }

                        onCreateDir: dirName => {
                            let parentIdx = root.treeView.index(root.row, root.column);
                            App.routesFilterModel.addFolder(dirName, parentIdx);
                        }
                        onCreateQuery: (name, type) => {
                            let idx = root.treeView.index(root.row, root.column);
                            App.routesFilterModel.addQuery(name, type, idx);
                        }
                        onImportHar: path => {
                            let folderIdx = root.treeView.index(root.row, root.column);
                            App.routesFilterModel.importFromHar(folderIdx, path);
                        }
                        onRemoveDir: {
                            routesItem.currentIndex = root.treeView.index(root.row, root.column);
                            dlgRemoveFolder.open();
                        }
                        onStartDrag: {
                            routesItem.moveIndex = root.treeView.index(root.row, root.column);
                        }
                        onToggleExpand: {
                            root.treeView.toggleExpanded(root.row);
                            let idx = root.treeView.index(root.row, root.column);
                            App.routesFilterModel.toggleFolderExpanded(idx);
                        }
                        onUpdateDir: (newDirName, parentUuid) => {
                            root.nodeName = newDirName;
                            root.parentUuid = parentUuid;

                            let idx = routesItem.currentIndex = root.treeView.index(root.row, root.column);
                            App.routesFilterModel.updateFolder(idx, newDirName, 257); // TODO: fix magic number
                        }
                    }
                }
                Component {
                    id: queryComponent

                    RoutesQueryNode {
                        id: queryNode
                        height: root.rowHeight
                        width: treeViewItem.width - 16
                        x: root.x + 8

                        name: root.nodeName
                        parentUuid: parentUuid
                        queryType: root.nodeQueryType
                        uuid: root.nodeUuid
                        nodePadding: root.padding + (root.isTreeNode ? (root.depth + 1) * root.indent : 0)

                        onCopyCurl: {
                            let idx = root.treeView.index(root.row, root.column);
                            let curlCommand = App.routesFilterModel.copyAsCurl(idx);
                            teCopy.text = curlCommand;
                            teCopy.selectAll();
                            teCopy.copy();
                            teCopy.clear();
                        }
                        onRemoveQuery: {
                            routesItem.currentIndex = root.treeView.index(root.row, root.column);
                            routesItem.removeUuid = root.nodeUuid;

                            dlgRemoveQuery.open();
                        }
                        onSetPin: {
                            App.pinModel.addPin(queryNode.uuid);
                        }
                        onSetQuery: {
                            App.routesFilterModel.setCurrentQuery(root.treeView.index(root.row, root.column));

                            routesItem.currentRow = root.row;
                        }
                        onStartDrag: {
                            routesItem.moveIndex = root.treeView.index(root.row, root.column);
                        }
                        onUpdateQuery: (newQueryName, parentUuid) => {
                            root.nodeName = newQueryName;
                            parentUuid = parentUuid;

                            let idx = root.treeView.index(root.row, root.column);

                            App.routesFilterModel.updateQuery(idx, newQueryName, 0);
                        }
                    }
                }
            }
        }
        TextField {
            id: tfFilter
            text: ""
            selectByMouse: true
            placeholderText: qsTr("Filter by name, URL")
            rightPadding: clearBtn.width + 8
            font.pixelSize: 13
            onTextChanged: {
                App.routesFilterModel.setFilterText(tfFilter.text);
            }

            Layout.fillWidth: true
            Layout.bottomMargin: 8
            Layout.leftMargin: 8
            Layout.rightMargin: 8

            RstPlacementButton {
                id: clearBtn
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                visible: tfFilter.text !== ""
                onClicked: {
                    tfFilter.clear();
                    tfFilter.forceActiveFocus();
                }
            }
        }
    }
    TextEdit {
        id: teCopy
        visible: false
    }

    // Dialogs
    InputDialog {
        id: mdlAddFolder
        placeholder: qsTr("Folder Name")
        title: qsTr("Add Folder")

        onOk: dirName => {
            let parentIdx = treeViewItem.index(-1, -1);
            App.routesFilterModel.addFolder(dirName, parentIdx);
        }
    }

    CreateRequestDialog {
        id: mdlAddQuery

        onOk: (queryName, queryType) => {
            let parentIdx = treeViewItem.index(-1, -1);
            App.routesFilterModel.addQuery(queryName, queryType, parentIdx);
        }
    }

    MessageDialog {
        id: dlgRemoveFolder
        buttons: MessageDialog.Ok | MessageDialog.Cancel
        modality: Qt.ApplicationModal
        text: "Remove folder?"
        title: "Accept Remove"

        onButtonClicked: (button, role) => {
            switch (button) {
            case MessageDialog.Ok:
                App.routesFilterModel.removeRows(routesItem.currentIndex.row, 1, routesItem.currentIndex.parent);
                dlgRemoveFolder.close();
                break;
            }
        }
    }

    MessageDialog {
        id: dlgRemoveQuery
        buttons: MessageDialog.Ok | MessageDialog.Cancel
        modality: Qt.ApplicationModal
        text: "Remove Request?"
        title: "Accept Remove"

        onButtonClicked: (button, role) => {
            switch (button) {
            case MessageDialog.Ok:
                App.routesFilterModel.removeRows(routesItem.currentIndex.row, 1, routesItem.currentIndex.parent);
                dlgRemoveQuery.close();

                break;
            }
        }
    }
}

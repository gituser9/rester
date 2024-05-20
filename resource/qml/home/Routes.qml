pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import core.app
import RoutesModel
import PinModel
import Util

import "./components"
import "./modal"



Item {
    id: routesItem

    property var currentIndex
    property int currentRow: -1
    property var moveIndex


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

                Button {
                    Layout.fillWidth: true
                    flat: true
                    icon.color: 'black'
                    icon.height: 24
                    icon.source: "/resource/images/folder-add.svg"
                    icon.width: 24
                    text: qsTr("Add Folder")

                    onClicked: {
                        mdlAddFolder.open();
                    }
                }
                Button {
                    Layout.fillWidth: true
                    flat: true
                    icon.color: 'black'
                    icon.height: 24
                    icon.source: "/resource/images/arrow-up-down.svg"
                    icon.width: 24
                    text: qsTr("Add Request")

                    onClicked: {
                        mdlAddQuery.open();
                    }
                }
            }
        }
        Item {
            Layout.preferredHeight: 3
        }
        MenuSeparator {
            // width: parent.width
            Layout.fillWidth: true

            contentItem: Rectangle {
                color: "#1E000000"
                implicitHeight: 1
                implicitWidth: parent.width
            }
        }
        Pins {
            Layout.fillWidth: true
            Layout.preferredHeight: App.workspace.pins.length * 40

            onSetQuery: uuid => {
                routesItem.currentRow = -1;
                App.setQueryByUuid(uuid);
            }
        }
        MenuSeparator {
            Layout.fillWidth: true
            visible: App.workspace.pins.length !== 0

            contentItem: Rectangle {
                color: "#1E000000"
                implicitHeight: 1
                implicitWidth: parent.width
            }
        }
        TreeView {
            id: treeViewItem

            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.topMargin: 8
            clip: true
            model: RoutesModel

            delegate: ItemDelegate {
                id: root

                required property bool current
                required property int depth
                required property int row
                required property int column
                required property bool expanded
                required property int hasChildren
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

                highlighted: row === routesItem.currentRow
                implicitHeight: rowHeight
                implicitWidth: treeViewItem.width
                width: treeViewItem.width

                DropArea {
                    id: dropArea

                    anchors.fill: parent
                    implicitHeight: 45
                    implicitWidth: treeViewItem.width

                    onDropped: drag => {
                        dragContainer.color = "transparent";
                        RoutesModel.moveRows(moveIndex.parent, moveIndex.row, 1, treeView.index(row, column), row);
                    }
                    onEntered: drag => {
                        // if (model.nodeType === 0) {
                        dragContainer.color = "lightblue";
                        // }
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
                        sourceComponent: root.nodeType === 0 ? folderComponent : queryComponent
                    }
                }
                Component {
                    id: folderComponent

                    RoutesFolderNode {
                        id: folderNode

                        childrenCount: root.hasChildren
                        dragParent: treeViewItem
                        height: root.height
                        // imgPadding: (root.depth * root.indent) - 10
                        imgPadding: (root.depth * root.indent)
                        isExpanded: root.treeView.isExpanded(root.row)
                        name: root.nodeName
                        parentUuid: parentUuid
                        width: root.width - (root.isTreeNode ? (root.depth + 1) * root.indent : 0) - 8
                        x: root.isTreeNode ? (root.depth + 1) * root.indent : 0

                        Component.onCompleted: {
                            if (root.isFolderExpanded) {
                                root.treeView.expand(root.row);
                            }
                        }
                        onCreateDir: dirName => {
                            let parentIdx = root.treeView.index(root.row, root.column);
                            RoutesModel.addFolder(dirName, parentIdx);
                        }
                        onCreateQuery: function(name, type) {
                            let idx = root.treeView.index(root.row, root.column);
                            RoutesModel.addQuery(name, type, idx);
                        }
                        onImportHar: path => {
                            let folderIdx = root.treeView.index(root.row, root.column);
                            RoutesModel.importFromHar(folderIdx, path);
                        }
                        onRemoveDir: {
                            currentIndex = root.treeView.index(root.row, root.column);
                            dlgRemoveFolder.open();
                        }
                        onStartDrag: {
                            moveIndex = root.treeView.index(root.row, root.column);
                        }
                        onToggleExpand: {
                            root.treeView.toggleExpanded(root.row);
                            RoutesModel.toggleFolderExpanded(treeView.index(root.row, root.column));
                        }
                        onUpdateDir: (newDirName, parentUuid) => {
                            root.nodeName = newDirName;
                            root.parentUuid = parentUuid;
                        }
                    }
                }
                Component {
                    id: queryComponent

                    RoutesQueryNode {
                        id: queryNode
                        height: root.rowHeight
                        name: root.nodeName
                        parentUuid: parentUuid
                        queryType: root.nodeQueryType
                        uuid: root.nodeUuid
                        width: treeViewItem.width
                        x: root.padding + (root.isTreeNode ? (root.depth + 1) * root.indent : 0)

                        onCopyCurl: {
                            let idx = root.treeView.index(row, column);
                            let curlCommand = RoutesModel.copyAsCurl(idx);
                            teCopy.text = curlCommand;
                            teCopy.selectAll();
                            teCopy.copy();
                            teCopy.clear();
                        }
                        onRemoveQuery: {
                            // currentIndex = treeView.index(row, column);
                            // dlgRemoveQuery.open();
                            // let idx = treeView.index(row, column);
                            // RoutesModel.removeRows(idx.row, 1, idx.parent);


                            routesItem.currentIndex = root.treeView.index(root.row, root.column);
                            dlgRemoveQuery.open();
                        }
                        onSetPin: {
                            PinModel.addPin(root.nodeUuid);
                        }
                        onSetQuery: {
                            RoutesModel.setCurrentQuery(treeView.index(root.row, root.column));
                            currentRow = root.row;
                        }
                        onStartDrag: {
                            moveIndex = root.treeView.index(root.row, root.column);
                        }
                        onUpdateQuery: (newQueryName, parentUuid) => {
                            root.nodeName = newQueryName;
                            parentUuid = parentUuid;

                            let idx = root.treeView.index(root.row, root.column)

                            RoutesModel.updateQuery(idx, newQueryName, 0)
                            // App.query.name = newQueryName
                        }
                    }
                }
            }
        }
    }
    TextEdit {
        id: teCopy

        visible: false
    }
    InputDialog {
        id: mdlAddFolder

        placeholder: qsTr("Folder Name")
        title: qsTr("Add Folder")

        onOk: dirName => {
            let parentIdx = treeViewItem.index(-1, -1);
            RoutesModel.addFolder(dirName, parentIdx);
        }
    }
    CreateRequestDialog {
        id: mdlAddQuery

        onOk: function (queryName, queryType) {
            let parentIdx = treeViewItem.index(-1, -1);
            RoutesModel.addQuery(queryName, queryType, parentIdx);
        }
    }

    MessageDialog {
        id: dlgRemoveFolder
        buttons: MessageDialog.Ok | MessageDialog.Cancel
        modality: Qt.ApplicationModal
        text: "Remove folder?"
        title: "Accept Remove"
        onButtonClicked: function (button, role) {
                 switch (button) {
                 case MessageDialog.Ok:
                     RoutesModel.removeRows(currentIndex.row, 1, currentIndex.parent);
                     dlgRemoveFolder.close()
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
        onButtonClicked: function (button, role) {
                 switch (button) {
                 case MessageDialog.Ok:
                     RoutesModel.removeRows(routesItem.currentIndex.row, 1, routesItem.currentIndex.parent);
                    dlgRemoveQuery.close()
                     break;
                 }
             }
    }
}

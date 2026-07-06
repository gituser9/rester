pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable
pragma FunctionSignatureBehavior: Enforced

import QtCore
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Imagine
import QtQuick.Dialogs

import io.rester

import "../modal"
import "../../colors"

Rectangle {
    id: folderNode

    required property string name
    required property string parentUuid
    required property int imgPadding
    required property bool isExpanded
    required property bool hasChildren
    required property Item dragParent

    property bool isHover: false

    signal createDir(string dirName)
    signal updateDir(string newDirName, string parentUuid)
    signal removeDir
    signal toggleExpand
    signal released
    signal startDrag
    signal createQuery(string name, string type)
    signal importHar(string path)
    color: 'transparent'

    RowLayout {
        anchors.fill: parent
        spacing: 8

        Image {
            id: imgFolder
            Layout.preferredWidth: 22
            Layout.preferredHeight: 22
            x: folderNode.imgPadding
            source: folderNode.getIcon()
        }
        Text {
            id: label
            clip: true
            text: folderNode.name
        }
        Item {
            Layout.fillWidth: true
        }
        // Button {
        //     z: 999
        //     visible: folderNode.isHover
        //     flat: true
        //     icon.source: "qrc:/qt/qml/io/rester/resource/images/more-line.svg"
        //     icon.width: 20
        //     icon.height: 20
        //     icon.color: 'black'
        //     onClicked: {
        //         contextMenu.popup();
        //     }
        // }
        Menu {
            id: contextMenu

            MenuItem {
                text: qsTr("Add Request")
                onTriggered: {
                    popAddQuery.open();
                }
            }
            MenuItem {
                text: qsTr("Add Folder")
                onTriggered: {
                    popAddFolder.open();
                }
            }
            MenuItem {
                text: qsTr("Import from HAR")
                onTriggered: {
                    fileDialog.open();
                }
            }
            MenuItem {
                text: qsTr("Edit")
                onTriggered: {
                    popUpdate.open();
                }
            }
            MenuItem {
                text: qsTr("Delete")
                onTriggered: {
                    folderNode.removeDir();
                }
            }
        }
    }
    MouseArea {
        id: mouseRegion
        anchors.fill: parent
        acceptedButtons: Qt.RightButton | Qt.LeftButton
        hoverEnabled: true
        drag.target: folderNode
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                contextMenu.popup();
            }

            if (mouse.button === Qt.LeftButton) {
                folderNode.toggleExpand();
            }
        }
        onEntered: {
            folderNode.isHover = true;
        }
        onExited: {
            folderNode.isHover = false;
        }
        onReleased: {
            parent.Drag.drop();
            folderNode.released();
        }
        onPressed: {
            folderNode.startDrag();
        }
    }

    Drag.active: mouseRegion.drag.active
    Drag.source: folderNode
    Drag.hotSpot.x: folderNode.width / 2
    Drag.hotSpot.y: folderNode.height / 2

    // AddFolder
    InputDialog {
        id: popAddFolder
        name: qsTr("Add Folder")
        placeholder: qsTr("Folder Name")
        implicitWidth: 200
        onOk: folderName => {
            folderNode.createDir(folderName);
        }
    }

    // move to root (создается на каждый запрос)
    UpdateNodeDialog {
        id: popUpdate
        itemName: folderNode.name
        itemParentUuid: folderNode.parentUuid
        onOk: (name, uuid) => {
            folderNode.updateDir(name, uuid);
            popUpdate.close();
        }
    }

    // Add Request
    CreateRequestDialog {
        id: popAddQuery

        onOk: function (queryName, queryType) {
            folderNode.createQuery(queryName, queryType);
        }
    }

    FileDialog {
        id: fileDialog
        currentFolder: StandardPaths.standardLocations(StandardPaths.HomeLocation)[0]
        nameFilters: ["HAR files (*.har)"]
        onAccepted: () => {
            let path = selectedFile.toString().replace("file://", "");
            folderNode.importHar(path);
        }
    }

    function getIcon(): string {
        if (!folderNode.hasChildren) {
            return "qrc:/qt/qml/io/rester/resource/images/folder-empty.svg";
        }

        if (folderNode.isExpanded) {
            return 'qrc:/qt/qml/io/rester/resource/images/folder-open.svg';
        }

        return 'qrc:/qt/qml/io/rester/resource/images/folder.svg';
    }
}

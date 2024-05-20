import QtCore
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Dialogs

import core.app 1.0
import RoutesModel

import "../modal"
import '../../colors'

Rectangle {

    required property string name
    required property string parentUuid
    required property int imgPadding
    required property bool isExpanded
    required property bool childrenCount
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

    id: folderNode
    color: 'transparent'

    RowLayout {
        anchors.fill: parent
        spacing: 8

        Image {
            // Layout.leftMargin: imgPadding
            Layout.preferredWidth: 22
            Layout.preferredHeight: 22

            id: imgFolder
            x: imgPadding
            source: folderNode.getIcon()
        }
        Text {
            id: label
            clip: true
            text: name
        }
        Item {
            Layout.fillWidth: true
        }
        // Button {
        //     visible: isHover
        //     flat: true
        //     icon.source: "/resource/images/more-line.svg"
        //     icon.width: 20
        //     icon.height: 20
        //     icon.color: 'black'
        //     onClicked: {
        //         contextMenu.popup()
        //     }
        // }
        Menu {
            id: contextMenu

            MenuItem {
                text: qsTr("Add Folder")
                onTriggered: {
                    popAddFolder.open()
                }
            }
            MenuItem {
                text: qsTr("Add Request")
                onTriggered: {
                    popAddQuery.open()
                }
            }
            MenuItem {
                text: qsTr("Import from HAR")
                onTriggered: {
                    fileDialog.open()
                }
            }
            // MenuItem {
            //     text: qsTr("Import from cURL")
            //     onTriggered: {
            //         fileDialog.open()
            //     }
            // }
            MenuItem {
                text: qsTr("Edit")
                onTriggered: {
                    let folders = RoutesModel.getFolders()
                    popUpdate.fillFolders(folders)
                    popUpdate.open()
                }
            }
            MenuItem {
                text: qsTr("Delete")
                onTriggered: {
                    removeDir()
                }
            }
        }
    }
    MouseArea {
        id: mouseRegion
        anchors.fill: parent;
        acceptedButtons: Qt.RightButton | Qt.LeftButton
        hoverEnabled: true
        drag.target: folderNode
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                contextMenu.popup()
            }

            if (mouse.button === Qt.LeftButton) {
                toggleExpand()
            }
        }
        onEntered: {
            isHover = true
        }
        onExited: {
            isHover = false
        }
        onReleased: {
            parent.Drag.drop()
            folderNode.released()
        }
        onPressed: {
            startDrag()
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
            createDir(folderName)
        }
    }

    // move to root (создается на каждый запрос)
    UpdateNodeDialog {
        id: popUpdate
        itemName: name
        itemParentUuid: parentUuid
        onOk: (name, uuid) => {
            updateDir(name, uuid)
            popUpdate.close()
        }
    }

    // Add Request
    // InputDialog {
    //     id: popAddQuery
    //     name: qsTr("Add Request")
    //     placeholder: qsTr("Request Name")
    //     implicitWidth: 200
    //     onOk: name => {
    //         createQuery(name)
    //     }
    // }
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
            let path = selectedFile.toString().replace("file://", "")
            importHar(path)
        }
    }


    function getIcon() {
        if (!childrenCount) {
            return "/resource/images/folder-empty.svg"
        }

        if (isExpanded) {
            return '/resource/images/folder-open.svg'
        }

        return '/resource/images/folder.svg'
    }
}

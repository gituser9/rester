import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import core.app 1.0
import RoutesModel
import Util

import "../modal"
import '../../colors'


Item {

    required property string name
    required property string uuid
    required property string parentUuid
    required property string queryType

    property bool isHovered: false

    signal removeQuery
    signal copyCurl
    signal released
    signal setQuery
    signal startDrag
    signal setPin
    signal updateQuery(string newQueryName, string parentUuid)

    id: requestNode


    RowLayout {
        anchors.fill: parent
        spacing: 8

        Text {
            id: txtQueryType
            clip: true
            text: queryType
            font.bold: true
            color: getTypeColor(queryType)
        }
        Text {
            Layout.maximumWidth: parent.width / 2.2

            id: txtName
            clip: true
            wrapMode: Text.WordWrap
            text: name
        }
        Item {
            width: 8
        }
        // Image {
        //     id: imgEdit
        //     sourceSize.width: 16
        //     sourceSize.height: 16
        //     source: "/resource/images/pencil.svg"
        //     visible: isHovered

        //     MouseArea {
        //         id: areaEdit
        //         anchors.fill: parent
        //         acceptedButtons: Qt.LeftButton
        //         onClicked: {
        //             let folders = RoutesModel.getFolders()
        //             popUpdate.fillFolders(folders)
        //             popUpdate.open()
        //         }
        //     }
        // }
        // Image {
        //     id: imgDelete
        //     sourceSize.width: 16
        //     sourceSize.height: 16
        //     source: "/resource/images/close.svg"
        //     visible: isHovered

        //     MouseArea {
        //         z: 100
        //         anchors.fill: parent
        //         onClicked: {
        //             removeQuery()
        //         }
        //     }
        // }
        Item {
            Layout.fillWidth: true
        }
    }

    MouseArea {
        id: mouseRegion
        anchors.fill: parent;
        acceptedButtons: Qt.RightButton | Qt.LeftButton
        hoverEnabled: true
        drag.target: requestNode
        drag.axis: Drag.YAxis
        drag.filterChildren: true
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                contextMenu.popup()
            }

            if (mouse.button === Qt.LeftButton) {
                setQuery()
            }
        }
        onEntered: {
            isHovered = true
        }
        onExited: {
            isHovered = false
        }
        onReleased: {
            parent.Drag.drop()
            requestNode.released()
        }
        onPressed: {
            startDrag()
        }

        Menu {
            id: contextMenu

            MenuItem {
                text: qsTr("Edit")
                onTriggered: {
                    let folders = RoutesModel.getFolders()
                    popUpdate.open()
                }
            }
            MenuItem {
                text: qsTr("Pin")
                onTriggered: {
                    setPin()
                }
            }
            MenuItem {
                text: qsTr("Delete")
                onTriggered: {
                    removeQuery()
                }
            }
            MenuSeparator { }
            MenuItem {
                text: qsTr("Copy as cURL")
                onTriggered: {
                    copyCurl()
                }
            }
        }
    }

    Drag.active: mouseRegion.drag.active
    Drag.source: requestNode
    Drag.hotSpot.x: requestNode.width / 2
    Drag.hotSpot.y: requestNode.height / 2
    Drag.dragType: Drag.Internal


    // move to root (создается на каждый запрос)
    UpdateNodeDialog {
        id: popUpdate
        itemName: name
        itemParentUuid: parentUuid
        onOk: (name, uuid) => {
            updateQuery(name, uuid)
            popUpdate.close()
        }
    }


    Connections {
        target: App.query

        function onQueryTypeChanged() {
            if (App.query.uuid === uuid) {
                queryType = Util.getQueryTypeString(App.query.queryType)
            }
        }
    }


    function getTypeColor(qType) {
        switch (qType) {
        case 'GET':
            return '#5100cb'
        case 'POST':
            return '#007c00'
        case 'PUT':
            return '#5500ff'
        case 'PATCH':
            return '#36a1a1'
        case 'DELETE':
            return '#ff0000'
        case 'WS':
            return '#FFA500'
        default:
            return '#000000'
        }
    }
}

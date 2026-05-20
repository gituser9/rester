pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable
pragma FunctionSignatureBehavior: Enforced

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Imagine

import io.rester

import "../modal"
import "../../colors"

Item {
    id: requestNode

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

    RowLayout {
        anchors.fill: parent
        spacing: 8

        Text {
            id: txtQueryType
            clip: true
            text: requestNode.queryType
            font.bold: true
            color: requestNode.getTypeColor(requestNode.queryType)
        }
        Text {
            id: txtName
            Layout.maximumWidth: parent.width / 2.2
            clip: true
            wrapMode: Text.WordWrap
            text: requestNode.name
        }
        Item {
            width: 8
        }
        Item {
            Layout.fillWidth: true
        }
    }

    MouseArea {
        id: mouseRegion
        anchors.fill: parent
        acceptedButtons: Qt.RightButton | Qt.LeftButton
        hoverEnabled: true
        drag.target: requestNode
        drag.axis: Drag.YAxis
        drag.filterChildren: true
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                contextMenu.popup();
            }

            if (mouse.button === Qt.LeftButton) {
                requestNode.setQuery();
            }
        }
        onEntered: {
            requestNode.isHovered = true;
        }
        onExited: {
            requestNode.isHovered = false;
        }
        onReleased: {
            parent.Drag.drop();
            requestNode.released();
        }
        onPressed: {
            requestNode.startDrag();
        }

        Menu {
            id: contextMenu

            MenuItem {
                text: qsTr("Rename")
                onTriggered: {
                    popUpdate.open();
                }
            }
            MenuItem {
                text: qsTr("Pin")
                onTriggered: {
                    requestNode.setPin();
                }
            }
            MenuItem {
                text: qsTr("Delete")
                onTriggered: {
                    requestNode.removeQuery();
                }
            }
            // TODO: duplicate
            MenuSeparator {}
            MenuItem {
                enabled: requestNode.queryType !== 'GRPC' && requestNode.queryType !== 'WS'
                text: qsTr("Copy as cURL")
                onTriggered: {
                    requestNode.copyCurl();
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
        itemName: requestNode.name
        itemParentUuid: requestNode.parentUuid
        onOk: (name, uuid) => {
            requestNode.updateQuery(name, uuid);
            popUpdate.close();
        }
    }

    Connections {
        target: App.query

        function onQueryTypeChanged(): void {
            if (App.query.uuid === requestNode.uuid) {
                requestNode.queryType = Util.getQueryTypeString(App.query.queryType);
            }
        }
    }

    function getTypeColor(qType: string): string {
        switch (qType) {
        case 'GET':
            return '#5100cb';
        case 'POST':
            return '#007c00';
        case 'PUT':
            return '#5500ff';
        case 'PATCH':
            return '#36a1a1';
        case 'DELETE':
            return '#ff0000';
        case 'HEAD':
            return '#5100cb';
        case 'WS':
            return '#FFA500';
        case 'GRPC':
            return '#a855ff';
        default:
            return '#000000';
        }
    }
}

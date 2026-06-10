pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable
pragma FunctionSignatureBehavior: Enforced

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Imagine

import io.rester

import "../modal"
import "../../colors"

Rectangle {
    id: requestNode
    radius: 8
    border.width: 0
    border.color: "transparent"
    clip: true

    states: [
        State {
            name: "selected"
            PropertyChanges {
                target: requestNode
                color: "#DBEAFE"
                border.color: "transparent"
                border.width: 0
            }
            PropertyChanges {
                target: leftIndicator
                visible: true
            }
        },
        State {
            name: "hovered"
            PropertyChanges {
                target: requestNode
                color: "#E2E8F0"
                border.color: "#E2E8F0"
                border.width: 0
            }
            PropertyChanges {
                target: leftIndicator
                visible: false
            }
        }
    ]
    transitions: Transition {
        from: "*"
        to: "*"
        ParallelAnimation {
            ColorAnimation {
                properties: "color"
                duration: 160
                easing.type: Easing.OutQuad
            }
        }
    }
    onUuidChanged: {
        if (App.query) {
            setState(App.query.uuid);
        }

        if (App.grpcQuery) {
            setState(App.grpcQuery.uuid);
        }

        if (App.graphqlQuery) {
            setState(App.graphqlQuery.uuid);
        }
    }

    required property string name
    required property string uuid
    required property string parentUuid
    required property string queryType
    required property double nodePadding

    property bool isHovered: false

    signal removeQuery
    signal copyCurl
    signal released
    signal setQuery
    signal startDrag
    signal setPin
    signal updateQuery(string newQueryName, string parentUuid)

    Behavior on color {
        ColorAnimation {
            duration: 160
        }
    }
    Behavior on border.color {
        ColorAnimation {
            duration: 160
        }
    }

    Rectangle {
        id: leftIndicator
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 3
        color: "#2563EB"
        radius: width / 2
        visible: false
        anchors.margins: 4
    }

    RowLayout {
        anchors.fill: parent
        spacing: 8

        Text {
            id: txtQueryType
            clip: true
            text: requestNode.queryType
            font.bold: true
            color: requestNode.getTypeColor(requestNode.queryType)

            Layout.leftMargin: requestNode.nodePadding
        }
        Text {
            id: txtName
            clip: true
            wrapMode: Text.WordWrap
            text: requestNode.name

            Layout.maximumWidth: parent.width - txtQueryType.width - requestNode.nodePadding - 16
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
            if (requestNode.state !== "selected") {
                requestNode.state = "hovered";
            }

            requestNode.isHovered = true;
        }
        onExited: {
            if (requestNode.state !== "selected") {
                requestNode.state = "";
            }

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

    // TODO: move to root (создается на каждый запрос)
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

    Connections {
        target: App.routesModel

        function onSetQuery(qry: Query): void {
            requestNode.setState(qry.uuid);
        }

        function onSetGrpcQuery(qry: GrpcQuery): void {
            requestNode.setState(qry.uuid);
        }

        function onSetGraphqlQuery(qry: var): void {
            requestNode.setState(qry.uuid);
        }
    }

    Connections {
        target: App

        function onQueryChanged(): void {
            requestNode.setState(App.query.uuid);
        }

        function onGrpcQueryChanged(): void {
            requestNode.setState(App.grpcQuery.uuid);
        }

        function onGraphqlQueryChanged(): void {
            requestNode.setState(App.graphqlQuery.uuid);
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
        case 'GRAPHQL':
            return '#E10098';
        default:
            return '#000000';
        }
    }

    function setState(uuid: string): void {
        let newState = "";

        if (uuid === requestNode.uuid) {
            newState = "selected";
        } else {
            newState = "";
        }

        if (requestNode.state === newState) {
            return;
        }

        requestNode.state = newState;
    }
}

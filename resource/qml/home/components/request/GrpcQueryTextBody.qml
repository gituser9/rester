pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import io.rester
import core.app 1.0
import JsonSyntaxHighlighter
import GrpcClient

import "../../../"

Item {
    id: root
    anchors.fill: parent

    property bool isQueryExists: false

    Component.onCompleted: {
        if (App.grpcQuery === null) {
            return;
        }

        jsonHilighter.setDocument(taQueryBody.textDocument);
        taQueryBody.text = App.grpcQuery.body;
    }

    Button {
        z: 100
        visible: taQueryBody.text.length === 0
        anchors.right: root.right
        anchors.top: root.top
        anchors.topMargin: 8
        anchors.rightMargin: 8
        text: qsTr("Generate")
        icon.source: "/resource/images/magic.svg"
        flat: true
        onClicked: {
            let emptyBoby = GrpcClient.generateBody(App.grpcQuery);
            App.grpcQuery.body = emptyBoby;
        }
    }

    ScrollView {
        anchors.fill: parent

        TextArea {
            id: taQueryBody
            verticalAlignment: TextEdit.AlignTop
            font.family: "Monospace"
            tabStopDistance: 32
            onEditingFinished: {
                App.grpcQuery.body = taQueryBody.text;
            }
        }
    }

    Connections {
        target: App

        function onGrpcQueryChanged() {
            if (!App.grpcQuery) {
                return;
            }

            if (!App.grpcQuery.body) {
                return;
            }

            jsonHilighter.setDocument(taQueryBody.textDocument);
            taQueryBody.text = App.grpcQuery.body;
        }
    }

    Connections {
        target: App.grpcQuery

        function onBodyChanged() {
            taQueryBody.text = App.grpcQuery.body;
        }
    }

    JsonSyntaxHighlighter {
        id: jsonHilighter
    }

    function clear() {
        App.grpcQuery.body = '';
    }

    function copy() {
        taQueryBody.selectAll();
        taQueryBody.copy();
    }
}

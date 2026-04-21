import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import io.rester
import core.app 1.0
import HtmlSyntaxHighlighter
import JsonSyntaxHighlighter

import "../../../"

Item {

    property bool isQueryExists: false

    anchors.fill: parent

    Component.onCompleted: {
        if (App.grpcQuery === null) {
            return;
        }

        jsonHilighter.setDocument(taQueryBody.textDocument);
        taQueryBody.text = App.grpcQuery.body;
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
            if (App.grpcQuery === null) {
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

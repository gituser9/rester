pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable
pragma FunctionSignatureBehavior: Enforced

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Imagine

import io.rester

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

    RstButton {
        z: 100
        visible: taQueryBody.text.length === 0
        anchors.right: root.right
        anchors.top: root.top
        anchors.topMargin: 8
        anchors.rightMargin: 8
        text: qsTr("Generate")
        icon: "qrc:/qt/qml/io/rester/resource/images/magic.svg"
        onClicked: {
            let emptyBoby = App.grpcClient.generateBody(App.grpcQuery);
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

        function onGrpcQueryChanged(): void {
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

        function onBodyChanged(): void {
            taQueryBody.text = App.grpcQuery.body;
        }
    }

    JsonSyntaxHighlighter {
        id: jsonHilighter
    }

    function clear(): void {
        App.grpcQuery.body = '';
    }

    function copy(): void {
        taQueryBody.selectAll();
        taQueryBody.copy();
    }
}

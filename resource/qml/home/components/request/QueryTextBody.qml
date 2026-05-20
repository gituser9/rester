pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable
pragma FunctionSignatureBehavior: Enforced

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Imagine

import io.rester

import "../../../"

Item {
    id: txtBodyView
    anchors.fill: parent

    property bool isQueryExists: false

    Component.onCompleted: {
        if (App.query === null) {
            return;
        }

        txtBodyView.setHighlighter();
        taQueryBody.text = App.query.body;
    }

    HtmlSyntaxHighlighter {
        id: htmlHilighter
    }

    JsonSyntaxHighlighter {
        id: jsonHilighter
    }

    ScrollView {
        anchors.fill: parent

        TextArea {
            id: taQueryBody
            verticalAlignment: TextEdit.AlignTop
            font.family: "Monospace"
            tabStopDistance: 32
            onEditingFinished: {
                App.query.body = taQueryBody.text;
            }
        }
    }

    Connections {
        target: App

        function onQueryChanged(): void {
            if (App.query === null) {
                return;
            }

            txtBodyView.setHighlighter();
            taQueryBody.text = App.query.body;
        }
    }

    Connections {
        target: App.query

        function onBodyChanged(): void {
            taQueryBody.text = App.query.body;
        }

        function onBodyTypeChanged(): void {
            txtBodyView.setHighlighter();
        }
    }

    function clear(): void {
        App.query.body = '';
    }

    function copy(): void {
        taQueryBody.selectAll();
        taQueryBody.copy();
    }

    function setHighlighter(): void {
        let bodyType = getBodyType();

        switch (bodyType) {
        case 'json':
            jsonHilighter.setDocument(taQueryBody.textDocument);
            break;
        case 'html':
        case 'xml':
            htmlHilighter.setDocument(taQueryBody.textDocument);
        }
    }

    function getBodyType(): string {
        switch (App.query.bodyType) {
        case 1:
            return 'json';
        case 4:
            return 'xml';
        case 5:
            return 'html';
        default:
            return '';
        }
    }
}

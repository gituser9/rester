import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import core.app 1.0
import HtmlSyntaxHighlighter
import JsonSyntaxHighlighter

import "../../../"

Item {

    property bool isQueryExists: false

    anchors.fill: parent

    Component.onCompleted: {
        if (App.query === null) {
            return
        }

        setHighlighter()
        taQueryBody.text = App.query.body
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
                App.query.body = taQueryBody.text
            }
        }
    }


    Connections {
        target: App

        function onQueryChanged() {
            if (App.query === null) {
                return
            }

            setHighlighter()
            taQueryBody.text = App.query.body
        }
    }

    Connections {
        target: App.query

        function onBodyChanged() {
            taQueryBody.text = App.query.body
        }

        function onBodyTypeChanged() {
            setHighlighter()
        }
    }


    function clear() {
        App.query.body = ''
    }

    function copy() {
        taQueryBody.selectAll()
        taQueryBody.copy()
    }

    function setHighlighter() {
        let bodyType = getBodyType()

        switch (bodyType) {
        case 'json':
            jsonHilighter.setDocument(taQueryBody.textDocument)
            break
        case 'html':
        case 'xml':
            htmlHilighter.setDocument(taQueryBody.textDocument)
        }
    }

    function getBodyType() {
        switch (App.query.bodyType) {
        case 1:
            return 'json'
        case 4:
            return 'xml'
        case 5:
            return 'html'
        default:
            return ''
        }
    }

}

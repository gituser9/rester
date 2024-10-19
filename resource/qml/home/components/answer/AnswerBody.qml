import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import core.app 1.0
import HtmlSyntaxHighlighter
import JsonSyntaxHighlighter
import SearchEngine
import Util

import "../../../../qml"

Item {


    property Constants consts: Constants {}
    property int btnWidth: 100
    property variant stringList: []
    property bool isBig: false


    Component.onCompleted: {
        let canSet = App.query !== null && App.query.lastAnswer !== null

        if (canSet) {
            setJson(App.query.lastAnswer)
        }
    }

    id: answerBodyView


    ColumnLayout {
        anchors.fill: parent

        // for small answer
        ScrollView {
            Layout.fillHeight: true
            Layout.fillWidth: true

            visible: !answerBodyView.isBig

            TextArea {
                Layout.fillHeight: true
                Layout.fillWidth: true

                id: txtAnswerBody
                font.family: "Monospace"
                readOnly: true
                selectByMouse: true
                verticalAlignment: TextEdit.AlignTop
            }
        }


        // for big answer
        ListView {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.bottomMargin: 20
            Layout.topMargin: 10

            id: idContentListView
            visible: answerBodyView.isBig
            model: answerBodyView.stringList
            delegate: Row {
                Layout.fillHeight: true
                Layout.fillWidth: true

                Text {
                    text: `${index+1} `
                    color: 'lightgrey'
                }
                TextEdit {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    JsonSyntaxHighlighter {
                        id: jsonHilighter2
                    }
                    Component.onCompleted: {
                        jsonHilighter2.setDocument(teBigRow.textDocument)
                    }


                    id: teBigRow
                    font.family: "Monospace"
                    readOnly: true
                    selectByMouse: true
                    text: model.modelData
                }
            }

            ScrollBar.vertical: ScrollBar {}
        }

        MenuSeparator {
            width: parent.width
            contentItem: Rectangle {
                color: "#1E000000"
                implicitHeight: 1
                implicitWidth: parent.width
            }
        }

        // Filter big text row
        RowLayout {
            visible: App.query?.lastAnswer?.body !== undefined && answerBodyView.isBig
            spacing: answerBodyView.consts.defaultSpacing

            TextField {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                Layout.bottomMargin: 7

                id: tfFilter
                onTextEdited: {
                    if (tfFilter.text.length === 0) {
                        answerBodyView.stringList = App.query.lastAnswer.body.split("\n")
                    } else {
                        answerBodyView.stringList = Util.filterBigBody(App.query.lastAnswer.body, tfFilter.text)
                    }
                }

                Text {
                    anchors.fill: parent
                    text: qsTr('Filter')
                    visible: tfFilter.text.length === 0 && !tfFilter.activeFocus
                    leftPadding: 10
                    rightPadding: 10
                    verticalAlignment: TextEdit.AlignVCenter
                    color: 'grey'
                }
            }

            Button {
                Layout.bottomMargin: 7

                visible: tfFilter.text.length !== 0
                flat: true
                icon.source: "/resource/images/close.svg"
                icon.width: 18
                icon.height: 18
                icon.color: 'black'
                onClicked: {
                    tfFilter.text = ''
                    answerBodyView.stringList = App.query.lastAnswer.body.split("\n")
                }

                ToolTip.text: qsTr("Clear")
                ToolTip.visible: hovered
            }
        }

        // Search row
        RowLayout {
            visible: App.query?.lastAnswer?.body !== undefined && !answerBodyView.isBig
            spacing: answerBodyView.consts.defaultSpacing

            TextField {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                Layout.bottomMargin: 7

                id: searchTextInput
                text: ""
                leftPadding: 10
                rightPadding: 10
                selectByMouse: true
                placeholderText: "Search (plain, regex)"
                onTextEdited: {
                    searchEngine.searchString = text
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: (containsMouse ? Qt.IBeamCursor : Qt.ArrowCursor)
                    onClicked: function (mouse) {
                        parent.focus = true
                        mouse.accepted = false
                    }
                    onPressed: function (mouse) {
                        parent.focus = true
                        mouse.accepted = false
                    }
                    onDoubleClicked: function (mouse) {
                        parent.focus = true
                        parent.selectAll()
                        mouse.accepted = false
                    }
                }
            }
            Button {
                Layout.bottomMargin: 7

                visible: searchEngine.size > 0
                flat: true
                icon.source: "/resource/images/close.svg"
                icon.width: 18
                icon.height: 18
                icon.color: 'black'
                onClicked: {
                    searchTextInput.clear()
                    searchEngine.searchString = ''
                }

                ToolTip.text: qsTr("Clear")
                ToolTip.visible: hovered
            }
            TextInput {
                Layout.bottomMargin: 7

                id: indexTextInput
                visible: searchEngine.size > 0
                text: "0"
                verticalAlignment: TextEdit.AlignVCenter
                topPadding: 0
                bottomPadding: 0
                leftPadding: 0
                rightPadding: 0
                validator: IntValidator {
                    bottom: searchEngine.size > 0 ? 1 : 0
                    top: searchEngine.size
                }
                onFocusChanged: {
                    if (focus) {
                        selectAll()
                    }
                }
                onTextEdited: {
                    if (acceptableInput) {
                        searchEngine.highlightIndex = parseInt(text)
                    } else {
                        indexTextInput.text = parseInt(searchEngine.highlightIndex)

                        selectAll()
                    }
                }

                MouseArea {
                    anchors.fill: indexTextInput
                    hoverEnabled: true
                    cursorShape: (containsMouse ? Qt.IBeamCursor : Qt.ArrowCursor)
                    onClicked: function (mouse) {
                        indexTextInput.focus = true
                        mouse.accepted = false
                    }
                }

                Keys.onUpPressed: {
                    backButton.highlightPrev()
                }

                Keys.onDownPressed: {
                    forwardButton.highlightNext()
                }
            }
            Label {
                Layout.bottomMargin: 7

                id: sizeLabel
                visible: searchEngine.size > 0
                text: "/ " + parseInt(searchEngine.size)
                rightPadding: 10
                verticalAlignment: TextEdit.AlignVCenter
            }
            Button {
                Layout.bottomMargin: 7

                id: backButton
                visible: searchEngine.size > 1
                flat: true
                icon.source: "/resource/images/arrow-up-s.svg"
                icon.width: 18
                icon.height: 18
                icon.color: 'black'
                onPressed: {
                    answerBodyView.highlightPrev()
                }

                ToolTip.text: qsTr("Previous Match")
                ToolTip.visible: hovered
            }
            Button {
                Layout.bottomMargin: 7

                id: forwardButton
                visible: searchEngine.size > 1
                flat: true
                icon.source: "/resource/images/arrow-down-s.svg"
                icon.width: 18
                icon.height: 18
                icon.color: 'black'
                onPressed: {
                    answerBodyView.highlightNext()
                }

                ToolTip.text: qsTr("Next Match")
                ToolTip.visible: hovered
            }
            Item {
                Layout.fillWidth: true
            }
            Button {
                Layout.bottomMargin: answerBodyView.consts.defaultSpacing

                implicitWidth: answerBodyView.btnWidth
                implicitHeight: answerBodyView.consts.bottomButtonHeight
                text: qsTr("Clear")
                onClicked: {
                    // for txt
                    if (!answerBodyView.isBig) {
                        txtAnswerBody.text = ''
                    }

                    // for list
                    if (answerBodyView.isBig) {
                        for (const prop in answerBodyView.stringList) {
                            if (stringList.hasOwnProperty(prop)) {
                                delete stringList[prop];
                            }
                        }

                        stringList = null
                    }

                    // for all
                    if (App.query && App.query.lastAnswer) {
                        App.query.lastAnswer.body = ''
                    }
                }
            }
            Button {
                Layout.alignment: Qt.AlignRight
                Layout.bottomMargin: answerBodyView.consts.defaultSpacing

                implicitWidth: answerBodyView.btnWidth
                implicitHeight: answerBodyView.consts.bottomButtonHeight
                text: qsTr("Copy")
                onClicked: {
                    if (answerBodyView.isBig) {
                        // for list
                        teCopy.text = App.query.lastAnswer.body
                        teCopy.selectAll()
                        teCopy.copy()
                        teCopy.clear()
                    } else {
                        // for txt
                        txtAnswerBody.selectAll()
                        txtAnswerBody.copy()
                    }
                }
            }
        }
    }


    TextEdit {
        id: teCopy
        visible: false
    }

    HtmlSyntaxHighlighter {
        id: htmlHilighter
    }

    JsonSyntaxHighlighter {
        id: jsonHilighter
    }

    SearchEngine {
        id: searchEngine
        objectName: "searchEngine"
        textDocumentObj: txtAnswerBody.textDocument
        onHighlightIndexChanged: {
            indexTextInput.text = parseInt(searchEngine.highlightIndex)
        }
        onCursorPositionChanged: {
            txtAnswerBody.cursorPosition = searchEngine.cursorPosition
        }
        onNoSearch: {
            answerBodyView.setSyntaxHighlighter()
        }
    }


    Connections {
        target: App

        function onQueryChanged() {
            if (!App.query?.lastAnswer) {
                txtAnswerBody.text = ''

                return
            }

            setJson(App.query.lastAnswer)
        }
    }


    function setJson(answer) {
        let size = Util.getAnswerSize(answer.byteCount)
        answerBodyView.isBig = size.label === "Mb" && size.size > 1

        if (isBig) {
            // for big
            let bodyType = getAnswerBodyType(App.query.lastAnswer)
            answerBodyView.stringList = answer.body.split("\n")
        } else {
            // for small
            setSyntaxHighlighter()
            txtAnswerBody.text = answer.body
        }
    }

    function getAnswerBodyType(answer) {
        let ct = ''

        if (answer.headers['Content-Type']) {
            ct = answer.headers['Content-Type']
        }

        if (ct === '' && answer.headers['content-type']) {
            ct = answer.headers['content-type']
        }

        if (!ct) {
            return ''
        }

        if (ct.includes('json')) {
            return 'json'
        }

        if (ct.includes('html')) {
            return 'html'
        }

        if (ct.includes('xml')) {
            return 'xml'
        }
    }

    function setSyntaxHighlighter() {
        if (!App.query?.lastAnswer) {
            return
        }

        let bodyType = getAnswerBodyType(App.query.lastAnswer)

        switch (bodyType) {
        case 'json':
            jsonHilighter.setDocument(txtAnswerBody.textDocument)
            break
        case 'html':
        case 'xml':
            htmlHilighter.setDocument(txtAnswerBody.textDocument)
        }
    }

    function highlightNext() {
        searchEngine.onNextHighlightChanged()

        indexTextInput.text = parseInt(searchEngine.highlightIndex)
    }

    function highlightPrev() {
        searchEngine.onPrevHighlightChanged()

        indexTextInput.text = parseInt(searchEngine.highlightIndex)
    }
}

pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable
pragma FunctionSignatureBehavior: Enforced

import QtQuick
import QtQuick.Controls.Imagine
import QtQuick.Layouts

import io.rester
import core.app 1.0
import HtmlSyntaxHighlighter
import JsonSyntaxHighlighter
import SearchEngine
import Util

import "../../../../qml"

Item {
    id: answerBodyView

    property Constants consts: Constants {}
    property int btnWidth: 100
    property variant stringList: []
    property bool isBig: false

    Component.onCompleted: {
        let canSet = App.grpcQuery !== null && App.grpcQuery.lastAnswer !== null;

        if (canSet) {
            answerBodyView.setJson(App.grpcQuery.lastAnswer);
        }
    }

    ColumnLayout {
        anchors.fill: parent

        // for small answer
        ScrollView {
            Layout.fillHeight: true
            Layout.fillWidth: true

            visible: !answerBodyView.isBig

            TextArea {
                id: txtAnswerBody

                Layout.fillHeight: true
                Layout.fillWidth: true

                font.family: "Monospace"
                readOnly: true
                selectByMouse: true
                verticalAlignment: TextEdit.AlignTop
            }
        }

        // for big answer
        ListView {
            id: idContentListView

            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.bottomMargin: 20
            Layout.topMargin: 10

            visible: answerBodyView.isBig
            model: answerBodyView.stringList
            delegate: Row {
                id: listDelegate

                required property int index
                required property string modelData

                Layout.fillHeight: true
                Layout.fillWidth: true

                Text {
                    text: `${listDelegate.index + 1} `
                    color: 'lightgrey'
                }
                TextEdit {
                    id: teBigRow

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    JsonSyntaxHighlighter {
                        id: jsonHilighter2
                    }
                    Component.onCompleted: {
                        jsonHilighter2.setDocument(teBigRow.textDocument);
                    }
                    font.family: "Monospace"
                    readOnly: true
                    selectByMouse: true
                    text: listDelegate.modelData
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
            visible: App.grpcQuery?.lastAnswer?.body !== undefined && answerBodyView.isBig
            spacing: answerBodyView.consts.defaultSpacing

            TextField {
                id: tfFilter

                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                Layout.bottomMargin: 7

                onTextEdited: {
                    if (tfFilter.text.length === 0) {
                        answerBodyView.stringList = App.grpcQuery.lastAnswer.body.split("\n");
                    } else {
                        answerBodyView.stringList = Util.filterBigBody(App.grpcQuery.lastAnswer.body, tfFilter.text);
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
                icon.source: "qrc:/qt/qml/io/rester/resource/images/close.svg"
                icon.width: 18
                icon.height: 18
                icon.color: 'black'
                onClicked: {
                    tfFilter.text = '';
                    answerBodyView.stringList = App.grpcQuery.lastAnswer.body.split("\n");
                }

                ToolTip.text: qsTr("Clear")
                ToolTip.visible: hovered
            }
        }

        // Search row
        RowLayout {
            visible: App.grpcQuery?.lastAnswer?.body !== undefined && !answerBodyView.isBig
            spacing: answerBodyView.consts.defaultSpacing

            TextField {
                id: searchTextInput

                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                Layout.bottomMargin: 7

                text: ""
                leftPadding: 10
                rightPadding: 10
                selectByMouse: true
                placeholderText: "Search (plain, regex)"
                onTextEdited: {
                    searchEngine.searchString = text;
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: (containsMouse ? Qt.IBeamCursor : Qt.ArrowCursor)
                    onClicked: function (mouse: MouseEvent) {
                        parent.focus = true;
                        mouse.accepted = false;
                    }
                    onPressed: function (mouse: MouseEvent) {
                        parent.focus = true;
                        mouse.accepted = false;
                    }
                    onDoubleClicked: function (mouse: MouseEvent) {
                        parent.focus = true;
                        parent.selectAll();
                        mouse.accepted = false;
                    }
                }
            }
            Button {
                Layout.bottomMargin: 7

                visible: searchEngine.size > 0
                flat: true
                icon.source: "qrc:/qt/qml/io/rester/resource/images/close.svg"
                icon.width: 18
                icon.height: 18
                icon.color: 'black'
                onClicked: {
                    searchTextInput.clear();
                    searchEngine.searchString = '';
                }

                ToolTip.text: qsTr("Clear")
                ToolTip.visible: hovered
            }
            TextInput {
                id: indexTextInput

                Layout.bottomMargin: 7

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
                        selectAll();
                    }
                }
                onTextEdited: {
                    if (acceptableInput) {
                        searchEngine.highlightIndex = parseInt(text);
                    } else {
                        indexTextInput.text = parseInt(searchEngine.highlightIndex);

                        selectAll();
                    }
                }

                MouseArea {
                    anchors.fill: indexTextInput
                    hoverEnabled: true
                    cursorShape: (containsMouse ? Qt.IBeamCursor : Qt.ArrowCursor)
                    onClicked: function (mouse: MouseEvent) {
                        indexTextInput.focus = true;
                        mouse.accepted = false;
                    }
                }

                Keys.onUpPressed: {
                    backButton.highlightPrev();
                }

                Keys.onDownPressed: {
                    forwardButton.highlightNext();
                }
            }
            Label {
                id: sizeLabel

                Layout.bottomMargin: 7

                visible: searchEngine.size > 0
                text: "/ " + parseInt(searchEngine.size)
                rightPadding: 10
                verticalAlignment: TextEdit.AlignVCenter
            }
            Button {
                id: backButton

                Layout.bottomMargin: 7

                visible: searchEngine.size > 1
                flat: true
                icon.source: "qrc:/qt/qml/io/rester/resource/images/arrow-up-s.svg"
                icon.width: 18
                icon.height: 18
                icon.color: 'black'
                onPressed: {
                    answerBodyView.highlightPrev();
                }

                ToolTip.text: qsTr("Previous Match")
                ToolTip.visible: hovered
            }
            Button {
                id: forwardButton

                Layout.bottomMargin: 7

                visible: searchEngine.size > 1
                flat: true
                icon.source: "qrc:/qt/qml/io/rester/resource/images/arrow-down-s.svg"
                icon.width: 18
                icon.height: 18
                icon.color: 'black'
                onPressed: {
                    answerBodyView.highlightNext();
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
                icon.source: "qrc:/qt/qml/io/rester/resource/images/close.svg"
                flat: true
                onClicked: {
                    // for txt
                    if (!answerBodyView.isBig) {
                        txtAnswerBody.text = '';
                    }

                    // for list
                    if (answerBodyView.isBig) {
                        for (const prop in answerBodyView.stringList) {
                            if (answerBodyView.stringList.hasOwnProperty(prop)) {
                                delete answerBodyView.stringList[prop];
                            }
                        }

                        answerBodyView.stringList = null;
                    }

                    // for all
                    if (App.grpcQuery && App.grpcQuery.lastAnswer) {
                        App.grpcQuery.lastAnswer.body = '';
                    }
                }
            }
            Button {
                Layout.alignment: Qt.AlignRight
                Layout.bottomMargin: answerBodyView.consts.defaultSpacing

                implicitWidth: answerBodyView.btnWidth
                implicitHeight: answerBodyView.consts.bottomButtonHeight
                text: qsTr("Copy")
                icon.source: "qrc:/qt/qml/io/rester/resource/images/copy.svg"
                flat: true
                onClicked: {
                    if (answerBodyView.isBig) {
                        // for list
                        teCopy.text = App.grpcQuery.lastAnswer.body;
                        teCopy.selectAll();
                        teCopy.copy();
                        teCopy.clear();
                    } else {
                        // for txt
                        txtAnswerBody.selectAll();
                        txtAnswerBody.copy();
                    }
                }
            }
        }
    }

    TextEdit {
        id: teCopy
        visible: false
    }

    JsonSyntaxHighlighter {
        id: jsonHilighter
    }

    SearchEngine {
        id: searchEngine
        objectName: "searchEngine"
        textDocumentObj: txtAnswerBody.textDocument
        onHighlightIndexChanged: {
            indexTextInput.text = parseInt(searchEngine.highlightIndex);
        }
        onCursorPositionChanged: {
            txtAnswerBody.cursorPosition = searchEngine.cursorPosition;
        }
        onNoSearch: {
            answerBodyView.setSyntaxHighlighter();
        }
    }

    Connections {
        target: App.grpcQuery

        function onLastAnswerChanged(): void {
            if (!App.grpcQuery?.lastAnswer) {
                txtAnswerBody.text = '';

                return;
            }

            answerBodyView.setJson(App.grpcQuery.lastAnswer);
        }
    }

    // TODO: type
    function setJson(answer: var): void {
        let size = Util.getAnswerSize(answer.byteCount);
        answerBodyView.isBig = size.label === "Mb" && size.size > 1;

        if (isBig) {
            // for big
            answerBodyView.stringList = answer.body.split("\n");
        } else {
            // for small
            setSyntaxHighlighter();
            txtAnswerBody.text = answer.body;
        }
    }

    function setSyntaxHighlighter(): void {
        if (!App.grpcQuery?.lastAnswer) {
            return;
        }

        jsonHilighter.setDocument(txtAnswerBody.textDocument);
    }

    function highlightNext(): void {
        searchEngine.onNextHighlightChanged();

        indexTextInput.text = parseInt(searchEngine.highlightIndex);
    }

    function highlightPrev(): void {
        searchEngine.onPrevHighlightChanged();

        indexTextInput.text = parseInt(searchEngine.highlightIndex);
    }
}

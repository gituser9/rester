pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable
pragma FunctionSignatureBehavior: Enforced

import QtQuick
import QtQuick.Controls.Imagine
import QtQuick.Layouts

import io.rester

import "../../../../qml"

Item {
    id: answerBodyView

    property Constants consts: Constants {}
    property int btnWidth: 100
    property int mode: GraphqlAnswerBody.BodyMode.Text

    Component.onCompleted: {
        let canSet = App.graphqlQuery !== null && App.graphqlQuery.lastAnswer !== null;

        if (canSet) {
            answerBodyView.setJson(App.graphqlQuery.lastAnswer);
        }
    }

    RstButton {
        z: 100
        anchors.right: answerBodyView.right
        anchors.top: answerBodyView.top
        anchors.topMargin: answerBodyView.consts.space
        anchors.rightMargin: answerBodyView.consts.space
        size: RstButton.ButtonSize.Small
        icon: answerBodyView.getModeIconBtn(answerBodyView.mode)
        tooltip: answerBodyView.getModeTooltip(answerBodyView.mode)
        onClicked: {
            if (answerBodyView.mode === GraphqlAnswerBody.BodyMode.Text) {
                answerBodyView.mode = GraphqlAnswerBody.BodyMode.JsonTree;
            } else {
                answerBodyView.mode = GraphqlAnswerBody.BodyMode.Text;
            }
        }
    }
    Loader {
        id: loader
        anchors.fill: parent
        sourceComponent: answerBodyView.getView(answerBodyView.mode)
    }

    TextEdit {
        id: teCopy
        visible: false
    }

    // Types
    HtmlSyntaxHighlighter {
        id: htmlHilighter
    }

    JsonSyntaxHighlighter {
        id: jsonHilighter
    }

    Component {
        id: jsonTree

        AnswerJsonTree {
            jsonText: App.graphqlQuery?.lastAnswer?.body ?? '{}'
        }
    }
    Component {
        id: smallAnswer

        ColumnLayout {
            id: answerCol

            ScrollView {
                Layout.fillHeight: true
                Layout.fillWidth: true

                Component.onCompleted: {
                    answerBodyView.setSyntaxHighlighter(txtAnswerBody.textDocument);
                }

                TextArea {
                    id: txtAnswerBody
                    font.family: "Monospace"
                    readOnly: true
                    selectByMouse: true
                    verticalAlignment: TextEdit.AlignTop
                    text: App.graphqlQuery?.lastAnswer?.body ?? ''

                    Layout.fillHeight: true
                    Layout.fillWidth: true
                }
            }
            RowLayout {
                spacing: answerBodyView.consts.defaultSpacing

                TextField {
                    id: searchTextInput
                    text: ""
                    leftPadding: 10
                    rightPadding: 10
                    selectByMouse: true
                    font.pixelSize: 13
                    placeholderText: "Search (plain, regex)"

                    Layout.alignment: Qt.AlignVCenter
                    Layout.fillWidth: true

                    onTextEdited: {
                        searchEngine.searchString = text;
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: (containsMouse ? Qt.IBeamCursor : Qt.ArrowCursor)
                        onClicked: mouse => {
                            parent.focus = true;
                            mouse.accepted = false;
                        }
                        onPressed: mouse => {
                            parent.focus = true;
                            mouse.accepted = false;
                        }
                        onDoubleClicked: mouse => {
                            parent.focus = true;
                            parent.selectAll();
                            mouse.accepted = false;
                        }
                    }
                }
                RstButton {
                    Layout.bottomMargin: 7

                    visible: searchTextInput.length > 0
                    icon: "qrc:/qt/qml/io/rester/resource/images/close.svg"
                    tooltip: qsTr("Clear")
                    onClicked: {
                        searchTextInput.clear();
                        searchEngine.searchString = '';
                    }
                }
                TextInput {
                    id: indexTextInput

                    Layout.bottomMargin: 7

                    visible: searchTextInput.length > 0
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
                        onClicked: mouse => {
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

                    visible: searchTextInput.length > 0
                    text: "/ " + parseInt(searchEngine.size)
                    rightPadding: 10
                    verticalAlignment: TextEdit.AlignVCenter
                }
                RstButton {
                    id: backButton
                    visible: searchEngine.size > 1
                    icon: "qrc:/qt/qml/io/rester/resource/images/arrow-up-s.svg"
                    tooltip: qsTr("Previous Match")
                    onClicked: {
                        answerCol.highlightPrev();
                    }

                    Layout.bottomMargin: 7
                }
                RstButton {
                    id: forwardButton
                    visible: searchEngine.size > 1
                    icon: "qrc:/qt/qml/io/rester/resource/images/arrow-down-s.svg"
                    tooltip: qsTr("Next Match")
                    onClicked: {
                        answerCol.highlightNext();
                    }

                    Layout.bottomMargin: 7
                }
                Item {
                    Layout.fillWidth: true
                }
                RstButton {
                    Layout.bottomMargin: answerBodyView.consts.defaultSpacing

                    implicitWidth: answerBodyView.btnWidth
                    implicitHeight: answerBodyView.consts.bottomButtonHeight
                    text: qsTr("Clear")
                    icon: "qrc:/qt/qml/io/rester/resource/images/close.svg"
                    onClicked: {
                        if (App.graphqlQuery && App.graphqlQuery.lastAnswer) {
                            App.graphqlQuery.lastAnswer.body = '';
                        }
                    }
                }
                RstButton {
                    Layout.alignment: Qt.AlignRight
                    Layout.bottomMargin: answerBodyView.consts.defaultSpacing

                    implicitWidth: answerBodyView.btnWidth
                    implicitHeight: answerBodyView.consts.bottomButtonHeight
                    text: qsTr("Copy")
                    icon: "qrc:/qt/qml/io/rester/resource/images/copy.svg"
                    onClicked: {
                        txtAnswerBody.selectAll();
                        txtAnswerBody.copy();
                    }
                }
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
                    answerBodyView.setSyntaxHighlighter(txtAnswerBody.textDocument);
                }
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
    }
    Component {
        id: bigAnswer

        ColumnLayout {
            ListView {
                id: idContentListView

                property list<string> stringList: []

                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.bottomMargin: 20
                Layout.topMargin: 10

                Component.onCompleted: {
                    idContentListView.stringList = App.graphqlQuery.lastAnswer.body.split("\n");
                }

                model: idContentListView.stringList
                delegate: Row {
                    id: bigBodyDelegate

                    required property int index
                    required property string modelData

                    Layout.fillHeight: true
                    Layout.fillWidth: true

                    Text {
                        text: `${bigBodyDelegate.index + 1} `
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
                        text: bigBodyDelegate.modelData
                    }
                }

                ScrollBar.vertical: ScrollBar {}
            }
            // Filter big text row
            RowLayout {
                visible: App.graphqlQuery?.lastAnswer?.body !== undefined
                spacing: answerBodyView.consts.defaultSpacing

                TextField {
                    id: tfFilter

                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    Layout.bottomMargin: 7

                    onTextEdited: {
                        if (tfFilter.text.length === 0) {
                            idContentListView.stringList = App.graphqlQuery.lastAnswer.body.split("\n");
                        } else {
                            idContentListView.stringList = Util.filterBigBody(App.graphqlQuery.lastAnswer.body, tfFilter.text);
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

                RstButton {
                    Layout.bottomMargin: 7

                    visible: tfFilter.text.length !== 0
                    icon: "qrc:/qt/qml/io/rester/resource/images/close.svg"
                    tooltip: qsTr("Clear")
                    onClicked: {
                        idContentListView.stringList = [];

                        if (App.graphqlQuery && App.graphqlQuery.lastAnswer) {
                            App.graphqlQuery.lastAnswer.body = '';
                        }
                    }
                }
            }
        }
    }

    enum BodyMode {
        Big,
        JsonTree,
        Text
    }

    // Connections
    Connections {
        target: App

        function onGraphqlQueryChanged(): void {
            if (!App.graphqlQuery?.lastAnswer) {
                return;
            }

            answerBodyView.setJson(App.graphqlQuery.lastAnswer);
        }
    }

    // Functions
    // TODO: answer type
    function setJson(answer: var): void {
        let size = Util.getAnswerSize(answer.byteCount);
        answerBodyView.isBig = size.label === "Mb" && size.size > 1;

        if (isBig) {
            // for big
            answerBodyView.mode = GraphqlAnswerBody.BodyMode.Big;
        }
    }

    function setSyntaxHighlighter(textDocument: var): void {
        if (!App.graphqlQuery?.lastAnswer) {
            return;
        }

        jsonHilighter.setDocument(textDocument);
    }

    function getView(bodyMode: int): Component {
        if (bodyMode === GraphqlAnswerBody.BodyMode.Text) {
            return smallAnswer;
        }

        if (bodyMode === GraphqlAnswerBody.BodyMode.Big) {
            return bigAnswer;
        }

        if (bodyMode === GraphqlAnswerBody.BodyMode.JsonTree) {
            return jsonTree;
        }

        return smallAnswer;
    }

    function getModeIconBtn(bodyMode: int): string {
        if (bodyMode === GraphqlAnswerBody.BodyMode.Text) {
            return "qrc:/qt/qml/io/rester/resource/images/node-tree.svg";
        }

        if (bodyMode === GraphqlAnswerBody.BodyMode.JsonTree) {
            return "qrc:/qt/qml/io/rester/resource/images/text.svg";
        }

        return '';
    }

    function getModeTooltip(bodyMode: int): string {
        if (bodyMode === GraphqlAnswerBody.BodyMode.Text) {
            return qsTr('Tree Mode');
        }

        if (bodyMode === GraphqlAnswerBody.BodyMode.JsonTree) {
            return qsTr('Text Mode');
        }

        return '';
    }
}

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
    property int mode: GrpcAnswerBody.BodyMode.Text
    property variant stringList: []
    property bool isBig: false

    Component.onCompleted: {
        let canSet = App.grpcQuery !== null && App.grpcQuery.lastAnswer !== null;

        if (canSet) {
            answerBodyView.setJson(App.grpcQuery.lastAnswer);
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
            if (answerBodyView.mode === GrpcAnswerBody.BodyMode.Text) {
                answerBodyView.mode = GrpcAnswerBody.BodyMode.JsonTree;
            } else {
                answerBodyView.mode = GrpcAnswerBody.BodyMode.Text;
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

    JsonSyntaxHighlighter {
        id: jsonHilighter
    }

    Component {
        id: jsonTree

        AnswerJsonTree {
            jsonText: App.grpcQuery?.lastAnswer?.body ?? '{}'
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
                    text: App.grpcQuery?.lastAnswer?.body ?? ''

                    Layout.fillHeight: true
                    Layout.fillWidth: true
                }
            }

            // Search row
            RowLayout {
                spacing: answerBodyView.consts.defaultSpacing

                TextField {
                    id: searchTextInput
                    text: ""
                    leftPadding: 10
                    rightPadding: 10
                    selectByMouse: true
                    placeholderText: "Search (plain, regex)"
                    onTextEdited: {
                        searchEngine.searchString = text;
                    }

                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    Layout.bottomMargin: 7

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
                RstButton {
                    size: RstButton.ButtonSize.Small
                    visible: searchEngine.size > 0
                    icon: "qrc:/qt/qml/io/rester/resource/images/close.svg"
                    tooltip: qsTr("Clear")
                    onClicked: {
                        searchTextInput.clear();
                        searchEngine.searchString = '';
                    }

                    Layout.bottomMargin: 7
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
                    visible: searchEngine.size > 0
                    text: "/ " + parseInt(searchEngine.size)
                    rightPadding: 10
                    verticalAlignment: TextEdit.AlignVCenter

                    Layout.bottomMargin: 7
                }
                RstButton {
                    id: backButton
                    size: RstButton.ButtonSize.Small
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
                    size: RstButton.ButtonSize.Small
                    tooltip: qsTr("Next Match")
                    visible: searchEngine.size > 1
                    icon: "qrc:/qt/qml/io/rester/resource/images/arrow-down-s.svg"
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
                        if (App.grpcQuery && App.grpcQuery.lastAnswer) {
                            App.grpcQuery.lastAnswer.body = '';
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
                    idContentListView.stringList = App.grpcQuery.lastAnswer.body.split("\n");
                }

                model: idContentListView.stringList
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

            // Filter big text row
            RowLayout {
                visible: App.grpcQuery?.lastAnswer?.body !== undefined
                spacing: answerBodyView.consts.defaultSpacing

                TextField {
                    id: tfFilter

                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    Layout.bottomMargin: 7

                    onTextEdited: {
                        if (tfFilter.text.length === 0) {
                            idContentListView.stringList = App.grpcQuery.lastAnswer.body.split("\n");
                        } else {
                            idContentListView.stringList = Util.filterBigBody(App.grpcQuery.lastAnswer.body, tfFilter.text);
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
                    size: RstButton.ButtonSize.Small
                    visible: tfFilter.text.length !== 0
                    icon: "qrc:/qt/qml/io/rester/resource/images/close.svg"
                    tooltip: qsTr("Clear")
                    onClicked: {
                        idContentListView.stringList = [];

                        if (App.grpcQuery && App.grpcQuery.lastAnswer) {
                            App.grpcQuery.lastAnswer.body = '';
                        }
                    }

                    Layout.bottomMargin: 7
                }
            }
        }
    }

    enum BodyMode {
        Big,
        JsonTree,
        Text
    }

    Connections {
        target: App.grpcQuery

        function onLastAnswerChanged(): void {
            if (!App.grpcQuery?.lastAnswer) {
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
            answerBodyView.mode = GrpcAnswerBody.BodyMode.Big;
        }
    }

    function setSyntaxHighlighter(textDocument: var): void {
        if (!App.grpcQuery?.lastAnswer) {
            return;
        }

        jsonHilighter.setDocument(textDocument);
    }

    function getView(bodyMode: int): Component {
        if (bodyMode === GrpcAnswerBody.BodyMode.Text) {
            return smallAnswer;
        }

        if (bodyMode === GrpcAnswerBody.BodyMode.Big) {
            return bigAnswer;
        }

        if (bodyMode === GrpcAnswerBody.BodyMode.JsonTree) {
            return jsonTree;
        }

        return smallAnswer;
    }

    function getModeIconBtn(bodyMode: int): string {
        if (bodyMode === GrpcAnswerBody.BodyMode.Text) {
            return "qrc:/qt/qml/io/rester/resource/images/node-tree.svg";
        }

        if (bodyMode === GrpcAnswerBody.BodyMode.JsonTree) {
            return "qrc:/qt/qml/io/rester/resource/images/text.svg";
        }

        return '';
    }

    function getModeTooltip(bodyMode: int): string {
        if (bodyMode === GrpcAnswerBody.BodyMode.Text) {
            return qsTr('Tree Mode');
        }

        if (bodyMode === GrpcAnswerBody.BodyMode.JsonTree) {
            return qsTr('Text Mode');
        }

        return '';
    }
}

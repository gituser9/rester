pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable
pragma FunctionSignatureBehavior: Enforced

import QtQuick
import QtQuick.Controls.Imagine
import QtQuick.Layouts

import io.rester

import "../../../../qml"

Item {
    id: root

    required property HttpAnswer answer
    required property int queryType

    readonly property Constants consts: Constants {}
    readonly property int btnWidth: 100
    property int mode: AnswerBody.BodyMode.Text
    property int bodyType: AnswerBody.AnswerType.Other

    onAnswerChanged: {
        root.bodyType = root.getAnswerBodyType(root.answer);
    }
    onQueryTypeChanged: {
        root.bodyType = root.getAnswerBodyType(root.answer);
    }

    RstButton {
        z: 100
        anchors.right: root.right
        anchors.top: root.top
        anchors.topMargin: root.consts.space
        anchors.rightMargin: root.consts.space
        visible: root.bodyType === AnswerBody.AnswerType.Json || root.bodyType === AnswerBody.AnswerType.Xml
        size: RstButton.ButtonSize.Small
        icon: root.getModeIconBtn(root.mode)
        tooltip: root.getModeTooltip(root.mode)
        onClicked: {
            switch (root.bodyType) {
            case AnswerBody.AnswerType.Json:
                if (root.mode === AnswerBody.BodyMode.Text) {
                    root.mode = AnswerBody.BodyMode.JsonTree;
                } else {
                    root.mode = AnswerBody.BodyMode.Text;
                }
                break;
            case AnswerBody.AnswerType.Xml:
                if (root.mode === AnswerBody.BodyMode.Text) {
                    root.mode = AnswerBody.BodyMode.XmlTree;
                } else {
                    root.mode = AnswerBody.BodyMode.Text;
                }
                break;
            }
        }
    }
    Loader {
        id: loader
        anchors.fill: parent
        sourceComponent: {
            switch (root.mode) {
            case AnswerBody.BodyMode.Text:
                return smallAnswerComponent;
            case AnswerBody.BodyMode.Big:
                return bigAnswerComponent;
            case AnswerBody.BodyMode.JsonTree:
                return jsonTreeComponent;
            case AnswerBody.BodyMode.XmlTree:
                return xmlTreeComponent;
            default:
                return smallAnswerComponent;
            }
        }
    }

    TextEdit {
        id: teCopy
        visible: false
    }

    // Components
    Component {
        id: smallAnswerComponent

        ColumnLayout {
            id: answerCol

            ScrollView {
                Layout.fillHeight: true
                Layout.fillWidth: true

                Component.onCompleted: {
                    root.setSyntaxHighlighter(txtAnswerBody.textDocument);
                }

                TextArea {
                    id: txtAnswerBody
                    font.family: "Monospace"
                    readOnly: true
                    selectByMouse: true
                    verticalAlignment: TextEdit.AlignTop
                    text: root.answer?.body ?? ''

                    Layout.fillHeight: true
                    Layout.fillWidth: true
                }
            }

            // Search row
            RowLayout {
                spacing: root.consts.defaultSpacing

                TextField {
                    id: searchTextInput
                    text: ""
                    leftPadding: 10
                    rightPadding: 10
                    selectByMouse: true
                    font.pixelSize: 13
                    placeholderText: "Search (plain, regex)"

                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter

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
                    size: RstButton.ButtonSize.Small
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
                    visible: searchEngine.size > 1
                    flat: true
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
                    Layout.bottomMargin: root.consts.defaultSpacing

                    implicitWidth: root.btnWidth
                    implicitHeight: root.consts.bottomButtonHeight
                    text: qsTr("Clear")
                    icon: "qrc:/qt/qml/io/rester/resource/images/close.svg"
                    onClicked: {
                        if (root.answer) {
                            root.answer.body = '';
                        }
                    }
                }
                RstButton {
                    Layout.alignment: Qt.AlignRight
                    Layout.bottomMargin: root.consts.defaultSpacing

                    implicitWidth: root.btnWidth
                    implicitHeight: root.consts.bottomButtonHeight
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
                    root.setSyntaxHighlighter(txtAnswerBody.textDocument);
                }
            }

            Connections {
                target: App

                function onQueryChanged(): void {
                    root.setSyntaxHighlighter(txtAnswerBody.textDocument);
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
        id: bigAnswerComponent

        ColumnLayout {
            ListView {
                id: idContentListView

                property list<string> stringList: []

                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.bottomMargin: 20
                Layout.topMargin: 10

                Component.onCompleted: {
                    idContentListView.stringList = root.answer.body.split("\n");
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

            // Search row
            RowLayout {
                visible: root.mode === AnswerBody.BodyMode.Big
                spacing: root.consts.defaultSpacing

                TextField {
                    id: tfFilter

                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    Layout.bottomMargin: 7

                    onTextEdited: {
                        if (tfFilter.text.length === 0) {
                            idContentListView.stringList = root.answer.body.split("\n");
                        } else {
                            idContentListView.stringList = Util.filterBigBody(root.answer.body, tfFilter.text);
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

                        if (root.answer) {
                            root.answer.body = '';
                        }
                    }
                }
            }
        }
    }
    Component {
        id: jsonTreeComponent

        AnswerJsonTree {
            jsonText: root.answer?.body ?? '{}'
        }
    }
    Component {
        id: xmlTreeComponent

        AnswerXmlTree {
            xmlText: root.answer?.body ?? ''
        }
    }

    // Types
    HtmlSyntaxHighlighter {
        id: htmlHilighter
    }

    JsonSyntaxHighlighter {
        id: jsonHilighter
    }

    enum BodyMode {
        Big,
        JsonTree,
        XmlTree,
        Text
    }
    enum AnswerType {
        Other,
        Json,
        Html,
        Xml
    }

    // Connections
    Connections {
        target: App

        function onQueryChanged(): void {
            root.updateHighlighter();
        }

        function onGrpcQueryChanged(): void {
            root.updateHighlighter();
        }

        function onGraphqlQueryChanged(): void {
            root.updateHighlighter();
        }
    }

    // Functions
    function setJson(answer: HttpAnswer): void {
        let size = Util.getAnswerSize(answer.byteCount);
        let isBig = size.label === "Mb" && size.size > 1;

        if (isBig) {
            root.mode = AnswerBody.BodyMode.Big;
        } else {
            if (root.bodyType !== AnswerBody.AnswerType.Json) {
                if (root.mode !== AnswerBody.BodyMode.Text) {
                    root.mode = AnswerBody.BodyMode.Text;
                }
            }
        }
    }

    function getAnswerBodyType(answer: HttpAnswer): int {
        if (root.queryType === RstEnums.QueryType.GRPC) {
            return AnswerBody.AnswerType.Json;
        }

        if (root.queryType === RstEnums.QueryType.GRAPHQL) {
            return AnswerBody.AnswerType.Json;
        }

        if (!answer || !answer.headers) {
            return AnswerBody.AnswerType.Other;
        }

        let ct = '';

        if (answer.headers['Content-Type']) {
            ct = answer.headers['Content-Type'];
        }

        if (ct === '' && answer.headers['content-type']) {
            ct = answer.headers['content-type'];
        }

        if (!ct) {
            return AnswerBody.AnswerType.Other;
        }

        if (ct.includes('json')) {
            return AnswerBody.AnswerType.Json;
        }

        if (ct.includes('html')) {
            return AnswerBody.AnswerType.Html;
        }

        if (ct.includes('xml')) {
            return AnswerBody.AnswerType.Xml;
        }

        return AnswerBody.AnswerType.Other;
    }

    function setSyntaxHighlighter(textDocument: var): void {
        if (!root.answer) {
            return;
        }

        switch (root.bodyType) {
        case AnswerBody.AnswerType.Json:
            jsonHilighter.setDocument(textDocument);
            break;
        case AnswerBody.AnswerType.Html:
        case AnswerBody.AnswerType.Xml:
            htmlHilighter.setDocument(textDocument);
        }
    }

    function updateHighlighter() {
        if (!root.answer) {
            return;
        }

        root.bodyType = root.getAnswerBodyType(root.answer);
        root.setJson(root.answer);
    }

    function getModeIconBtn(bodyMode: int): string {
        if (bodyMode === AnswerBody.BodyMode.Text) {
            return "qrc:/qt/qml/io/rester/resource/images/node-tree.svg";
        }

        if (bodyMode === AnswerBody.BodyMode.JsonTree) {
            return "qrc:/qt/qml/io/rester/resource/images/text.svg";
        }

        if (bodyMode === AnswerBody.BodyMode.XmlTree) {
            return "qrc:/qt/qml/io/rester/resource/images/text.svg";
        }

        return '';
    }

    function getModeTooltip(bodyMode: int): string {
        if (bodyMode === AnswerBody.BodyMode.Text) {
            return qsTr('Tree Mode');
        }

        if (bodyMode === AnswerBody.BodyMode.JsonTree) {
            return qsTr('Text Mode');
        }

        if (bodyMode === AnswerBody.BodyMode.XmlTree) {
            return qsTr('Text Mode');
        }

        return '';
    }
}

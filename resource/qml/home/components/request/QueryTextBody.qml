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

    required property int bodyType
    required property string body

    signal editingFinished(string txt)

    onBodyTypeChanged: {
        root.setHighlighter();
    }

    RstButton {
        z: 100
        visible: App.grpcQuery && taQueryBody.text.length === 0
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
            text: root.body
            tabStopDistance: 32
            onEditingFinished: {
                root.editingFinished(taQueryBody.text);
            }
        }
    }

    // Types
    HtmlSyntaxHighlighter {
        id: htmlHilighter
    }

    JsonSyntaxHighlighter {
        id: jsonHilighter
    }

    GraphqlSyntaxHighlighter {
        id: graphqlSyntaxHighlighter
    }

    // Funcs
    function copy(): void {
        taQueryBody.selectAll();
        taQueryBody.copy();
    }

    function setHighlighter(): void {
        switch (root.bodyType) {
        case RstEnums.BodyType.JSON:
            jsonHilighter.setDocument(taQueryBody.textDocument);
            break;
        case RstEnums.BodyType.GRAPHQL:
            graphqlSyntaxHighlighter.setDocument(taQueryBody.textDocument);
            break;
        case RstEnums.BodyType.HTML:
        case RstEnums.BodyType.XML:
            htmlHilighter.setDocument(taQueryBody.textDocument);
        }
    }
}

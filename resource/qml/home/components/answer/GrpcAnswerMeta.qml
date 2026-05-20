pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable
pragma FunctionSignatureBehavior: Enforced

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Imagine

import io.rester
import GrpcClient
import core.app 1.0

// import "../../../common/components"

Rectangle {
    id: grpcAnswerMeta

    property int rowHeight: 40

    Component.onCompleted: {
        if (App.grpcQuery?.lastAnswer) {
            grpcAnswerMeta.fillHeaders(App.grpcQuery.lastAnswer.headers);
        }
    }

    ListView {
        id: headersList
        anchors.fill: parent
        clip: true
        model: answerHeadersModel
        delegate: Rectangle {
            id: metaDelegate
            height: grpcAnswerMeta.rowHeight
            width: parent.width

            required property bool isEnabled
            required property int index
            required property string name
            required property string value

            RowLayout {
                anchors.fill: parent

                Rectangle {
                    Layout.fillWidth: true

                    height: grpcAnswerMeta.rowHeight

                    TextEdit {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        text: metaDelegate.name
                        font.family: "Monospace"
                        readOnly: true
                        selectByMouse: true
                    }
                }
                Rectangle {
                    Layout.fillWidth: true

                    height: grpcAnswerMeta.rowHeight

                    Flickable {
                        id: flick
                        anchors.fill: parent
                        clip: true

                        function ensureVisible(r: rect): void {
                            if (contentX >= r.x)
                                contentX = r.x;
                            else if (contentX + width <= r.x + r.width)
                                contentX = r.x + r.width - width;
                            if (contentY >= r.y)
                                contentY = r.y;
                            else if (contentY + height <= r.y + r.height)
                                contentY = r.y + r.height - height;
                        }

                        TextEdit {
                            width: flick.width
                            anchors.verticalCenter: parent.verticalCenter
                            text: metaDelegate.value
                            font.family: "Monospace"
                            onCursorRectangleChanged: flick.ensureVisible(cursorRectangle)
                        }
                    }
                }
                Button {
                    id: copybtn

                    property string tooltipText: qsTr("Copy value")

                    flat: true
                    icon.source: "qrc:/qt/qml/io/rester/resource/images/copy.svg"
                    icon.width: 18
                    icon.height: 18
                    icon.color: 'black'
                    onClicked: {
                        teCopy.text = metaDelegate.value;
                        teCopy.selectAll();
                        teCopy.copy();
                        teCopy.clear();

                        copybtn.tooltipText = qsTr("Copied");
                    }

                    ToolTip.text: tooltipText
                    ToolTip.visible: hovered
                    ToolTip.toolTip.onVisibleChanged: {
                        if (!hovered) {
                            tooltipText = qsTr("Copy value");
                        }
                    }
                }
            }
        }
    }

    ListModel {
        id: answerHeadersModel
    }

    TextEdit {
        id: teCopy
        visible: false
    }

    Connections {
        target: GrpcClient

        // TODO: type
        function onRequestFinished(answer: var): void {
            grpcAnswerMeta.fillHeaders(answer.headers);
        }
    }

    Connections {
        target: App.grpcQuery

        function onLastAnswerChanged(): void {
            if (!App.grpcQuery.lastAnswer) {
                return;
            }

            grpcAnswerMeta.fillHeaders(App.grpcQuery.lastAnswer.headers);
        }
    }

    function fillHeaders(headers: var): void {
        answerHeadersModel.clear();

        for (let key in headers) {
            let data = {
                "name": key,
                "value": headers[key]
            };
            answerHeadersModel.append(data);
        }
    }
}

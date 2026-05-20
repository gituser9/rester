pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable
pragma FunctionSignatureBehavior: Enforced

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import io.rester
import HttpClient
import core.app 1.0

import "../../../common/components"

Rectangle {
    id: answerHeadersView

    property int rowHeight: 40

    Component.onCompleted: {
        if (App.query?.lastAnswer) {
            answerHeadersView.fillHeaders(App.query.lastAnswer.headers);
        }
    }

    ListView {
        id: headersList
        anchors.fill: parent
        clip: true
        model: answerHeadersModel
        delegate: Rectangle {
            id: headerDelegate
            height: answerHeadersView.rowHeight
            width: headersList.width

            required property string name
            required property string value

            RowLayout {
                anchors.fill: parent

                Rectangle {
                    height: answerHeadersView.rowHeight

                    Layout.fillWidth: true

                    TextEdit {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        text: headerDelegate.name
                        font.family: "Monospace"
                        readOnly: true
                        selectByMouse: true
                    }
                }
                Rectangle {
                    height: answerHeadersView.rowHeight

                    Layout.fillWidth: true

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
                            text: headerDelegate.value
                            font.family: "Monospace"
                            onCursorRectangleChanged: flick.ensureVisible(cursorRectangle)
                        }
                    }
                }
                Button {
                    id: copybtn

                    property string tooltipText: qsTr("Copy value")
                    flat: true
                    icon.source: "/resource/images/copy.svg"
                    icon.width: 18
                    icon.height: 18
                    icon.color: 'black'
                    onClicked: {
                        teCopy.text = headerDelegate.value;
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
        target: HttpClient

        // TODO: type
        function onFinished(answer: var): void {
            answerHeadersView.fillHeaders(answer.headers);
        }
    }

    Connections {
        target: App

        function onQueryChanged(): void {
            if (App.query?.lastAnswer) {
                answerHeadersView.fillHeaders(App.query.lastAnswer.headers);
            }
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

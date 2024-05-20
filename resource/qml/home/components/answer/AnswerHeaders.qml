import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import HttpClient
import core.app 1.0

import '../../../common/components'


Rectangle {

    property int rowHeight: 40


    Component.onCompleted: {
        if (App.query?.lastAnswer) {
            fillHeaders(App.query.lastAnswer.headers)
        }
    }


    ListView {
        id: headersList
        anchors.fill: parent
        clip: true
        model: answerHeadersModel
        delegate: Rectangle {
            height: rowHeight
            width: parent.width

            RowLayout {
                // height: rowHeight
                anchors.fill: parent

                Rectangle {
                    height: rowHeight
                    // implicitWidth: headersList.width / 2
                    Layout.fillWidth: true

                    TextEdit {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        text: model.name
                        font.family: "Monospace"
                        readOnly: true
                        selectByMouse: true
                    }
                }
                Rectangle {
                    height: rowHeight
                    // implicitWidth: headersList.width / 2
                    Layout.fillWidth: true

                    Flickable {
                         id: flick
                         anchors.fill: parent
                         clip: true

                         function ensureVisible(r) {
                             if (contentX >= r.x)
                                 contentX = r.x;
                             else if (contentX+width <= r.x+r.width)
                                 contentX = r.x+r.width-width;
                             if (contentY >= r.y)
                                 contentY = r.y;
                             else if (contentY+height <= r.y+r.height)
                                 contentY = r.y+r.height-height;
                         }

                         TextEdit {
                             // anchors.fill: parent
                             width: flick.width
                             anchors.verticalCenter: parent.verticalCenter
                             text: model.value
                             font.family: "Monospace"
                             onCursorRectangleChanged: flick.ensureVisible(cursorRectangle)
                         }
                    }
                }
                Button {

                    property string tooltipText: qsTr("Copy value")

                    id: copybtn
                    flat: true
                    icon.source: "/resource/images/copy.svg"
                    icon.width: 18
                    icon.height: 18
                    icon.color: 'black'
                    onClicked: {
                        teCopy.text = model.value
                        teCopy.selectAll()
                        teCopy.copy()
                        teCopy.clear()

                        copybtn.tooltipText = qsTr("Copied")
                    }

                    ToolTip.text: tooltipText
                    ToolTip.visible: hovered
                    ToolTip.toolTip.onVisibleChanged: {
                        if (!hovered) {
                            tooltipText = qsTr("Copy value")
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

        function onFinished(answer) {
            fillHeaders(answer.headers)
        }
    }

    Connections {
        target: App

        function onQueryChanged() {
            if (App.query?.lastAnswer) {
                fillHeaders(App.query.lastAnswer.headers)
            }
        }
    }



    function fillHeaders(headers) {
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

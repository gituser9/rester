import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import core.app 1.0
import RoutesModel
import VarSyntaxHighlighter

import "./../"
import "../common/components"

Item {

    property Constants consts: Constants {}
    property int currentIndex: 0

    id: requestView

    Component.onCompleted: {
        setSource(0)


        if (App.query) {
            cbQueryType.currentIndex = App.query.queryType
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        RowLayout {
            Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
            Layout.topMargin: 8
            Layout.bottomMargin: 5
            Layout.preferredWidth: parent.width

            // width: parent.width
            spacing: 8

            Rectangle {
                Layout.leftMargin: 8
                Layout.preferredWidth: 100
                Layout.preferredHeight: requestView.consts.bottomButtonHeight

                ComboBox {
                    id: cbQueryType
                    height: requestView.consts.bottomButtonHeight
                    model: ["GET", "POST", "PUT", "PATCH", "DELETE"]
                    onActivated: {
                        App.query.queryType = cbQueryType.currentIndex
                    }
                }
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 20

                Layout.preferredWidth: 80
                Layout.preferredHeight: requestView.consts.bottomButtonHeight
                border.width: 1
                border.color: 'lightgrey'
                radius: 4

                FlickableEdit {

                    Component.onCompleted: {
                        varHilighter.setDocument(tfUrl.textDocument)
                    }

                    id: tfUrl
                    anchors.fill: parent
                    value: App.query ? App.query.url : ''
                    onEditingFinish: txt => {
                        App.query.url = txt
                    }
                }
            }
            Rectangle {
                Layout.rightMargin: 8

                Layout.preferredWidth: 80
                Layout.preferredHeight: requestView.consts.bottomButtonHeight

                Button {
                    anchors.fill: parent
                    height: requestView.consts.bottomButtonHeight
                    text: qsTr("SEND")
                    onClicked: {
                        if (tfUrl.text.indexOf('curl ') !== -1) {
                            App.setFromCurl(tfUrl.text)
                        }

                        App.send()
                    }
                }
            }
        }
        MenuSeparator {
            Layout.preferredWidth: parent.width
            contentItem: Rectangle {
                implicitWidth: parent.width
                implicitHeight: 1
                color: "#1E000000"
            }
        }

        ButtonGroup {
            id: tabGroup
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.rightMargin: 8
            Layout.leftMargin: 8

            Button {
                Layout.fillWidth: true
                Layout.preferredWidth: parent.width / 3

                checkable: true
                checked: requestView.currentIndex == 0
                flat: true
                text: qsTr("Body")
                onClicked: {
                    requestView.setSource(0)
                }

                ButtonGroup.group: tabGroup
            }
            Button {
                Layout.fillWidth: true
                Layout.preferredWidth: parent.width / 3

                checkable: true
                checked: requestView.currentIndex == 1
                flat: true
                text: qsTr("Query")
                onClicked: {
                    requestView.setSource(1)
                }

                ButtonGroup.group: tabGroup
            }
            Button {
                Layout.fillWidth: true
                Layout.preferredWidth: parent.width / 3

                checkable: true
                checked: requestView.currentIndex == 2
                flat: true
                text: qsTr("Headers")
                onClicked: {
                    requestView.setSource(2)
                }

                ButtonGroup.group: tabGroup
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.rightMargin: 8
            Layout.leftMargin: 8

            Loader {
                id: loader
                asynchronous: true
                anchors.fill: parent
            }
        }
    }


    Connections {
        target: App

        function onQueryChanged() {
            cbQueryType.currentIndex = App.query?.queryType ?? 0
            tfUrl.value = App.query ? App.query.url : ''
        }
    }

    Connections {
        target: App.query

        function onQueryTypeChanged() {
            cbQueryType.currentIndex = App.query.queryType
        }
    }

    VarSyntaxHighlighter {
        id: varHilighter
    }



    function setSource(idx) {
        currentIndex = idx
        let path = "./components/request/"

        switch (idx) {
        case 0:
            path += "QueryBody.qml"
            break
        case 1:
            path += "QueryParams.qml"
            break
        case 2:
            path += "QueryHeaders.qml"
            break
        default:
            path += "QueryBody.qml"
        }

        loader.setSource(path)

        return path
    }

}

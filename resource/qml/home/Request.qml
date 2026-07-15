pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable
pragma FunctionSignatureBehavior: Enforced

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Imagine

import io.rester

import "./../"
import "../common/components"
import "../common/components/uikit"

Item {
    id: requestView

    property Constants consts: Constants {}
    property int currentIndex: 0

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        RowLayout {
            Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
            Layout.topMargin: 8
            Layout.bottomMargin: 5
            Layout.preferredWidth: parent.width

            spacing: 8

            RstDropdown {
                id: cbQueryType
                currentText: Util.getQueryTypeString(App.query.queryType)
                model: ["GET", "POST", "PUT", "PATCH", "DELETE", "HEAD"]

                Layout.leftMargin: 8
                Layout.preferredWidth: 100
                Layout.preferredHeight: requestView.consts.bottomButtonHeight

                onItemSelected: (idx, value) => {
                    App.query.queryType = Util.getQueryType(value);
                }
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredWidth: 80
                Layout.preferredHeight: requestView.consts.bottomButtonHeight

                border.width: 1
                border.color: 'lightgrey'
                radius: 4

                FlickableEdit {
                    id: tfUrl
                    anchors.fill: parent
                    value: App.query?.url ?? ''
                    onEditingFinish: txt => {
                        App.query.url = txt;
                    }

                    Component.onCompleted: {
                        varHilighter.setDocument(tfUrl.textDocument);
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
                            App.setFromCurl(tfUrl.text);
                        }

                        App.send();
                    }
                }
            }
        }
        RstDivider {
            Layout.fillWidth: true
        }

        RstTabGroup {
            id: tabs
            texts: [qsTr("Body"), qsTr("Query"), qsTr("Headers")]
            onClicked: idx => {
                requestView.setSource(idx);
            }

            Layout.fillWidth: true
            Layout.rightMargin: 8
            Layout.leftMargin: 8
            Layout.preferredHeight: requestView.consts.bottomButtonHeight
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

    // Connections
    Connections {
        target: App

        function onQueryChanged(): void {
            tfUrl.value = App.query ? App.query.url : '';
        }
    }

    // Types
    VarSyntaxHighlighter {
        id: varHilighter
    }

    // Funcs
    function setSource(idx: int): string {
        currentIndex = idx;
        let path = "./components/request/";

        switch (idx) {
        case 0:
            path += "QueryBody.qml";
            break;
        case 1:
            path += "QueryParams.qml";
            break;
        case 2:
            path += "QueryHeaders.qml";
            break;
        default:
            path += "QueryBody.qml";
        }

        loader.setSource(path);

        return path;
    }
}

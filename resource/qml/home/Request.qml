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
    id: root

    property Constants consts: Constants {}
    property int currentIndex: 0

    ColumnLayout {
        anchors.fill: parent
        spacing: root.consts.space

        RowLayout {
            Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
            Layout.topMargin: 8
            Layout.bottomMargin: 5
            Layout.preferredWidth: parent.width

            spacing: 8

            RstDropdown {
                id: cbQueryType
                currentText: Util.getQueryTypeString(App.query?.queryType ?? RstEnums.QueryType.GET)
                model: ["GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS"]

                Layout.leftMargin: 8
                Layout.preferredWidth: 110
                Layout.preferredHeight: root.consts.bottomButtonHeight

                onItemSelected: (idx, value) => {
                    App.query.queryType = Util.getQueryType(value);
                }
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredWidth: 80
                Layout.preferredHeight: root.consts.bottomButtonHeight

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
                Layout.preferredHeight: root.consts.bottomButtonHeight

                Button {
                    anchors.fill: parent
                    height: root.consts.bottomButtonHeight
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

            Layout.fillWidth: true
            Layout.rightMargin: root.consts.space
            Layout.leftMargin: root.consts.space
            Layout.preferredHeight: root.consts.bottomButtonHeight
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.rightMargin: root.consts.space
            Layout.leftMargin: root.consts.space

            Loader {
                id: loader
                asynchronous: true
                anchors.fill: parent
                sourceComponent: {
                    switch (tabs.currentIdx) {
                    case 0:
                        return bodyComponent;
                    case 1:
                        return paramsComponent;
                    case 2:
                        return headersComponent;
                    default:
                        return bodyComponent;
                    }
                }
            }
        }
    }

    // Components
    Component {
        id: paramsComponent

        QueryParams {
            params: App.query.params
        }
    }
    Component {
        id: headersComponent

        QueryParamList {
            params: App.query.headers
            onAddParam: {
                App.query.addHeader('', '');
            }
            onRemoveParam: idx => {
                App.query.removeHeader(idx);
            }
            onSetParam: (idx, name, val, enabled) => {
                App.query.setHeader(idx, name, val, enabled);
            }
        }
    }
    Component {
        id: bodyComponent

        QueryBody {
            body: App.query.body
            bodyType: App.query.bodyType
            onEditingFinished: txt => {
                App.query.body = txt;
            }
            onSetBodyType: typ => {
                App.query.bodyType = typ;
                root.setContentTypeHeader(typ);
            }
            onClear: {
                App.query.body = '';
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
    function setContentTypeHeader(bodyType: int): void {
        if (!App.query) {
            return;
        }

        let headers = App.query.headers;

        switch (bodyType) {
        case RstEnums.BodyType.JSON:
            App.query.setHeader("Content-Type", "application/json; charset=UTF-8");
            break;
        case RstEnums.BodyType.XML:
            App.query.setHeader("Content-Type", "application/xml");
            break;
        case RstEnums.BodyType.MULTIPART_FORM:
            App.query.setHeader("Content-Type", "multipart/form-data");
            break;
        case RstEnums.BodyType.URL_ENCODED_FORM:
            App.query.setHeader("Content-Type", "application/x-www-form-urlencoded");
            break;
        case RstEnums.BodyType.NONE:
            App.query.removeHeader("Content-Type");
            break;
        }
    }
}

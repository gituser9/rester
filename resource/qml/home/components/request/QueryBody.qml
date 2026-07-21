pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable
pragma FunctionSignatureBehavior: Enforced

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Imagine

import io.rester

import "../../../../qml"
import "../../../common/components/uikit"

Item {
    id: queryBodyView

    property Constants consts: Constants {}
    property bool isForm: false

    signal clear
    signal copy

    Component.onCompleted: {
        queryBodyView.checkIsForm();
    }

    ColumnLayout {
        anchors.fill: parent

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Loader {
                id: loader
                asynchronous: true
                anchors.fill: parent
                sourceComponent: queryBodyView.isForm ? formBody : textBody

                Layout.topMargin: 10
                Layout.bottomMargin: 20
            }
        }

        // buttons
        RowLayout {
            spacing: 8

            Layout.fillWidth: true

            RstDropdown {
                id: cbBodyType
                currentText: Util.getHumanBodyTypeString(App.query?.bodyType ?? "None")
                model: lstBodytype

                Layout.preferredWidth: 180
                Layout.preferredHeight: 40
                Layout.bottomMargin: 8

                onItemSelected: (idx, bodyType) => {
                    App.query.bodyType = bodyType.value;
                    queryBodyView.checkIsForm();
                    queryBodyView.setContentTypeHeader(bodyType.value);
                }
            }

            RstButton {
                text: qsTr("Clear")
                icon: "qrc:/qt/qml/io/rester/resource/images/close.svg"
                onClicked: {
                    queryBodyView.clear();
                }

                Layout.fillWidth: true
                Layout.bottomMargin: 8
            }

            RstButton {
                text: qsTr("Copy")
                icon: "qrc:/qt/qml/io/rester/resource/images/copy.svg"
                onClicked: {
                    queryBodyView.copy();
                }

                Layout.fillWidth: true
                Layout.bottomMargin: 8
            }

            RstButton {
                text: qsTr("Beautify")
                icon: "qrc:/qt/qml/io/rester/resource/images/indent-increase.svg"
                onClicked: {
                    App.query.beautify();
                }

                Layout.fillWidth: true
                Layout.bottomMargin: 8
            }
        }
    }

    ListModel {
        id: lstBodytype

        Component.onCompleted: {
            append({
                name: "None",
                value: RstEnums.BodyType.NONE
            });
            append({
                name: "JSON",
                value: RstEnums.BodyType.JSON
            });
            append({
                name: "Multipart Form",
                value: RstEnums.BodyType.MULTIPART_FORM
            });
            append({
                name: "Form URL Encoded",
                value: RstEnums.BodyType.URL_ENCODED_FORM
            });
            append({
                name: "XML",
                value: RstEnums.BodyType.XML
            });
        }
    }

    Connections {
        target: App

        function onQueryChanged(): void {
            if (App.query === null) {
                return;
            }

            queryBodyView.checkIsForm();
        }
    }

    Component {
        id: textBody

        QueryTextBody {
            id: tb
            Component.onCompleted: {
                queryBodyView.clear.connect(tb.clear);
                queryBodyView.copy.connect(tb.copy);
            }
            Component.onDestruction: {
                queryBodyView.clear.disconnect(textBody.tb.clear);
                queryBodyView.clear.disconnect(textBody.tb.copy);
            }
            visible: !queryBodyView.isForm
        }
    }

    Component {
        id: formBody

        QueryFormBody {
            id: tf
            Component.onCompleted: {
                queryBodyView.clear.connect(tf.clear);
                queryBodyView.copy.connect(tf.copy);
            }
            Component.onDestruction: {
                queryBodyView.clear.disconnect(tf.clear);
                queryBodyView.copy.disconnect(tf.copy);
            }
        }
    }

    function setContentTypeHeader(bodyType: int): void {
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

    function checkIsForm(): void {
        if (App.query === null) {
            return;
        }

        switch (App.query.bodyType) {
        case 2:
        case 3:
            queryBodyView.isForm = true;
            break;
        default:
            queryBodyView.isForm = false;
        }
    }
}

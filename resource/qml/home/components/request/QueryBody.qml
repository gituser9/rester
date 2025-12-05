import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import core.app 1.0

import "../../../../qml"

Item {

    property Constants consts: Constants {}
    property bool isForm: false

    signal clear
    signal copy


    Component.onCompleted: {
        if (App.query) {
            cbBodyType.currentIndex = App.query.bodyType
        }


        checkIsForm()
    }


    id: queryBodyView

    ColumnLayout {
        anchors.fill: parent

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Loader {
                Layout.topMargin: 10
                Layout.bottomMargin: 20

                id: loader
                asynchronous: true
                anchors.fill: parent
                sourceComponent: queryBodyView.isForm ? formBody : textBody
            }
        }

        // buttons
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignRight

            ComboBox {
                Layout.bottomMargin: 8
                Layout.rightMargin: 8
                Layout.fillWidth: true
                Layout.preferredWidth: 80

                id: cbBodyType
                implicitHeight: queryBodyView.consts.bottomButtonHeight
                model: ["None", "JSON", "Multipart Form", "Form URL Encoded", "XML"]
                onActivated: {
                    App.query.bodyType = cbBodyType.currentIndex

                    checkIsForm()
                    setContentTypeHeader(cbBodyType.currentValue)
                }
            }

            Button {
                Layout.bottomMargin: 8
                Layout.rightMargin: 8

                implicitWidth: 100
                implicitHeight: queryBodyView.consts.bottomButtonHeight
                icon.source: "/resource/images/close.svg"
                flat: true
                text: qsTr("Clear")
                onClicked: {
                    queryBodyView.clear()
                }
            }

            Button {
                Layout.bottomMargin: 8
                Layout.rightMargin: 8

                implicitWidth: 100
                implicitHeight: queryBodyView.consts.bottomButtonHeight
                text: qsTr("Copy")
                icon.source: "/resource/images/copy.svg"
                flat: true
                // visible: !queryBodyView.isForm
                onClicked: {
                    queryBodyView.copy()
                }
            }

            Button {
                Layout.bottomMargin: 8
                Layout.alignment: Qt.AlignRight

                visible: !queryBodyView.isForm
                implicitWidth: 100
                implicitHeight: queryBodyView.consts.bottomButtonHeight
                text: qsTr("Beautify")
                icon.source: "/resource/images/sound-module-line.svg"
                flat: true
                onClicked: {
                    App.query.beautify()
                }
            }
        }
    }


    Connections {
        target: App

        function onQueryChanged() {
            if (App.query === null) {
                return
            }

            cbBodyType.currentIndex = App.query.bodyType
            checkIsForm()
        }
    }


    Component {
        id: textBody

        QueryTextBody {
            Component.onCompleted: {
                queryBodyView.clear.connect(tb.clear)
                queryBodyView.copy.connect(tb.copy)
            }
            Component.onDestruction: {
                queryBodyView.clear.disconnect(textBody.tb.clear)
                queryBodyView.clear.disconnect(textBody.tb.copy)
            }

            id: tb
            visible: !queryBodyView.isForm
        }
    }

    Component {
        id: formBody

        QueryFormBody {
            Component.onCompleted: {
                queryBodyView.clear.connect(tf.clear)
                queryBodyView.copy.connect(tf.copy)
            }
            Component.onDestruction: {
                queryBodyView.clear.disconnect(tf.clear)
                queryBodyView.copy.disconnect(tf.copy)
            }

            id: tf
        }
    }

    function setContentTypeHeader(contentType) {
        let headers = App.query.headers

        switch(contentType) {
        case "JSON":
            App.query.setHeader("Content-Type", "application/json; charset=UTF-8");

            break
        case "XML":
            App.query.setHeader("Content-Type", "application/xml");

            break
        case "Multipart Form":
            App.query.setHeader("Content-Type", "multipart/form-data");

            break
        case "Form URL Encoded":
            App.query.setHeader("Content-Type", "application/x-www-form-urlencoded");

            break
        case "None":
            App.query.removeHeader("Content-Type")

            break
        }
    }

    function checkIsForm() {
        if (App.query === null) {
            return
        }

        switch (App.query.bodyType) {
        case 2:
        case 3:
            queryBodyView.isForm = true
            break
        default:
            queryBodyView.isForm = false
        }
    }

}

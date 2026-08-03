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
    id: root

    required property int bodyType
    required property string body
    readonly property Constants consts: Constants {}

    signal clear
    signal copy
    signal setBodyType(int typ)
    signal editingFinished(string txt)

    ColumnLayout {
        anchors.fill: parent

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Loader {
                id: loader
                asynchronous: true
                anchors.fill: parent
                sourceComponent: {
                    switch (root.bodyType) {
                    case RstEnums.BodyType.URL_ENCODED_FORM:
                    case RstEnums.BodyType.MULTIPART_FORM:
                        return formBody;
                    case RstEnums.BodyType.NONE:
                        return noBody;
                    default:
                        return textBody;
                    }
                }

                Layout.topMargin: 10
                Layout.bottomMargin: 20
            }
        }

        // buttons
        RowLayout {
            spacing: root.consts.space

            Layout.fillWidth: true

            RstDropdown {
                id: cbBodyType
                visible: root.isShowQueryType()
                currentText: Util.getHumanBodyTypeString(root.bodyType)
                model: lstBodytype

                Layout.preferredWidth: 180
                Layout.preferredHeight: root.consts.bottomButtonHeight
                Layout.bottomMargin: root.consts.space

                onItemSelected: (idx, bodyType) => {
                    root.setBodyType(bodyType.value);
                }
            }

            RstButton {
                text: qsTr("Clear")
                icon: "qrc:/qt/qml/io/rester/resource/images/close.svg"
                onClicked: {
                    root.clear();
                }

                Layout.fillWidth: true
                Layout.preferredHeight: root.consts.bottomButtonHeight
                Layout.bottomMargin: root.consts.space
            }

            RstButton {
                text: qsTr("Copy")
                icon: "qrc:/qt/qml/io/rester/resource/images/copy.svg"
                onClicked: {
                    root.copy();
                }

                Layout.fillWidth: true
                Layout.preferredHeight: root.consts.bottomButtonHeight
                Layout.bottomMargin: root.consts.space
            }

            RstButton {
                text: qsTr("Beautify")
                icon: "qrc:/qt/qml/io/rester/resource/images/indent-increase.svg"
                onClicked: {
                    App.query.beautify();
                }

                Layout.fillWidth: true
                Layout.preferredHeight: root.consts.bottomButtonHeight
                Layout.bottomMargin: root.consts.space
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

    Component {
        id: textBody

        QueryTextBody {
            id: tb
            bodyType: root.bodyType
            body: root.body
            onEditingFinished: txt => {
                root.editingFinished(txt);
            }

            Component.onCompleted: {
                root.copy.connect(tb.copy);
            }
            Component.onDestruction: {
                root.copy.disconnect(tb.copy);
            }
        }
    }
    Component {
        id: formBody

        QueryFormBody {
            id: tf
            bodyType: root.bodyType

            Component.onCompleted: {
                root.clear.connect(tf.clear);
                root.copy.connect(tf.copy);
            }
            Component.onDestruction: {
                root.clear.disconnect(tf.clear);
                root.copy.disconnect(tf.copy);
            }
        }
    }
    Component {
        id: noBody

        Item {}
    }

    function isShowQueryType(): bool {
        if (App.query) {
            return true;
        }

        return false;
    }
}

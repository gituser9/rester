pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable
pragma FunctionSignatureBehavior: Enforced

import QtQuick
import QtQuick.Controls.Imagine
import QtQuick.Layouts

Popup {
    id: updPopup

    required property string itemName
    required property string itemParentUuid

    signal ok(string folderName, string parentUuid)
    parent: Overlay.overlay
    x: Math.round((parent.width - width) / 2)
    y: Math.round((parent.height - height) / 2)
    width: 200
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    ColumnLayout {
        anchors.fill: parent
        spacing: 16

        TextField {
            id: tfName
            Layout.fillWidth: true
            text: updPopup.itemName
            width: parent.width
        }
        RowLayout {
            Layout.fillWidth: true

            height: 40
            spacing: 8

            Button {
                Layout.fillWidth: true

                text: "Ok"
                onClicked: {
                    updPopup.ok(tfName.text, tfName.text);
                }
            }
            Button {
                Layout.fillWidth: true

                text: qsTr("Close")
                onClicked: {
                    updPopup.close();
                }
            }
        }
    }
}

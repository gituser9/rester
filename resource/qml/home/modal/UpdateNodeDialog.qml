import QtQuick
import QtQuick.Controls
import QtQuick.Layouts


Popup {

    required property string itemName
    required property string itemParentUuid

    signal ok(string folderName, string parentUuid)

    id: popup
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
            Layout.fillWidth: true

            id: tfName
            text: itemName
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
                    ok(tfName.text, tfName.text)
                }
            }
            Button {
                Layout.fillWidth: true

                text: qsTr("Close")
                onClicked: {
                    popup.close()
                }
            }
        }
    }


    function getCurrentIndex() {
        for (let i = 0; i < cbModel.count; ++i) {
            if (cbModel.get(i).value === itemParentUuid) {
                return i
            }
        }

        return 0
    }
}

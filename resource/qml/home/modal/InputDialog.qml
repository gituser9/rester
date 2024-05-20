import QtQuick
import QtQuick.Controls


Dialog {

    property string name
    property string placeholder: ''
    property string currentText: ''

    signal accept
    signal ok(string folderName)

    id: dialog
    parent: Overlay.overlay
    x: Math.round((parent.width - width) / 2)
    y: Math.round((parent.height - height) / 2)
    width: 200
    title: name
    modal: true
    standardButtons: Dialog.Ok | Dialog.Cancel
    onAccepted: {
        if (tfInput.text.length !== 0) {
            ok(tfInput.text)
        }

        tfInput.clear()
        dialog.close()
    }
    onRejected: {
        tfInput.clear()
        dialog.close()
    }

    TextField {
        id: tfInput
        text: currentText
        width: parent.width
        placeholderText: placeholder

        Text {
            anchors.fill: parent
            text: tfInput.placeholderText
            visible: !tfInput.text && !tfInput.activeFocus
            leftPadding: 10
            rightPadding: 10
            verticalAlignment: TextEdit.AlignVCenter
            color: 'grey'
        }
    }
}

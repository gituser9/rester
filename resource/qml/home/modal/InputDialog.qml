pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable

import QtQuick
import QtQuick.Controls

Dialog {
    id: dialog

    property string name
    property string placeholder: ''
    property string currentText: ''

    signal accept
    signal ok(string folderName)

    parent: Overlay.overlay
    x: Math.round((parent.width - width) / 2)
    y: Math.round((parent.height - height) / 2)
    width: 200
    title: name
    modal: true
    standardButtons: Dialog.Ok | Dialog.Cancel
    onAccepted: {
        if (tfInput.text.length !== 0) {
            ok(tfInput.text);
        }

        tfInput.clear();
        dialog.close();
    }
    onRejected: {
        tfInput.clear();
        dialog.close();
    }

    TextField {
        id: tfInput
        text: dialog.currentText
        width: parent.width
        placeholderText: dialog.placeholder
    }
}

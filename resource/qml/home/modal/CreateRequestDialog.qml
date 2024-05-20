import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import '../../common/components'

Popup {

    signal ok(string queryName, string queryType)

    id: createRequestDialog
    parent: Overlay.overlay
    x: Math.round((parent.width - width) / 2)
    y: Math.round((parent.height - height) / 2)
    width: 400
    height: 200
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    ColumnLayout {
        anchors.fill: parent

        Text {
            text: qsTr("Create New Request")
            font.bold: true
            font.pointSize: 16
        }
        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 22

            FlickableEdit {
                Layout.fillWidth: true
                Layout.preferredHeight: 20

                id: tfName
                placeholder: qsTr("Request Name")
                value: ''
            }
            MenuSeparator {
                Layout.fillWidth: true

                contentItem: Rectangle {
                    implicitWidth: parent.width
                    implicitHeight: 1
                    color: "#1E000000"
                }
            }
        }
        ComboBox {
            Layout.fillWidth: true

            id: cbQueryType
            model: ["GET", "POST", "PUT", "PATCH", "DELETE", "WS"]
        }
        RowLayout {
            Layout.fillWidth: true

            spacing: 8

            Button {
                Layout.fillWidth: true
                Layout.preferredWidth: parent.width / 2

                flat: true
                text: qsTr("OK")
                onClicked: {
                    createRequestDialog.ok(tfName.value, cbQueryType.currentText)
                    createRequestDialog.close()
                    tfName.value = ''
                }

            }
            Button {
                Layout.fillWidth: true
                Layout.preferredWidth: parent.width / 2

                flat: true
                text: qsTr("Cancel")
                onClicked: {
                    createRequestDialog.close()
                    tfName.value = ''
                }

            }
        }
    }
}

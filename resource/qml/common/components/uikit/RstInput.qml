pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable
pragma FunctionSignatureBehavior: Enforced

import QtQuick
import QtQuick.Controls.Imagine
import QtQuick.Layouts

import "../"

Item {
    id: root

    required property int tfWidth
    property int tfHeight: 20
    property string value: ""
    property string placeholder: ""
    property bool isEnabled: true

    property alias textDocument: tfHeaderName.textDocument

    signal textChanged(string txt)
    signal editingFinished(string txt)

    width: root.tfWidth
    height: root.tfHeight

    ColumnLayout {
        anchors.fill: parent

        FlickableEdit {
            id: tfHeaderName
            isEnabled: root.isEnabled
            placeholder: root.placeholder
            value: root.value
            onEditingFinish: txt => {
                root.editingFinished(txt);
            }
            onTextChange: txt => {
                root.textChanged(txt);
            }

            Layout.fillWidth: true
            Layout.fillHeight: true
        }
        RstDivider {
            Layout.fillWidth: true
        }
    }
}

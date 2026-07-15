pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable
pragma FunctionSignatureBehavior: Enforced

import QtQuick
import QtQuick.Controls.Imagine
import QtQuick.Layouts

import io.rester

Item {
    id: root

    required property ListModel propertyModel
    property bool withCheckbox: true
    property bool withVariables: true

    signal nameChanged(int index, string value)
    signal valueChanged(int index, string value)
    signal checkBoxClicked(int index)
    signal removed(int index)

    ListView {
        id: propertyList
        anchors.fill: parent
        clip: true
        model: root.propertyModel
        delegate: Rectangle {
            id: propertyDelegate
            height: 60
            width: propertyList.width

            required property int index
            required property bool isEnabled
            required property string name
            required property string value

            VarSyntaxHighlighter {
                id: varHilighter
            }

            RowLayout {
                spacing: 16
                anchors.fill: parent

                CheckBox {
                    id: cbEnabled
                    visible: root.withCheckbox
                    enabled: root.withCheckbox
                    checked: propertyDelegate.isEnabled
                    onClicked: {
                        root.propertyModel.setProperty(propertyDelegate.index, "isEnabled", cbEnabled.checkState === Qt.Checked);
                        root.checkBoxClicked(propertyDelegate.index);

                        varHilighter.enabled = cbEnabled.checked;
                    }
                }
                RstInput {
                    isEnabled: cbEnabled.checkState === Qt.Checked
                    tfWidth: propertyList.width / 3
                    value: propertyDelegate.name

                    Layout.fillWidth: true

                    onTextChanged: txt => {
                        root.propertyModel.setProperty(propertyDelegate.index, "name", txt);
                        root.nameChanged(propertyDelegate.index, txt);
                    }
                    onEditingFinished: txt => {
                        root.propertyModel.setProperty(propertyDelegate.index, "name", txt);
                        root.nameChanged(propertyDelegate.index, txt);
                    }
                }
                RstInput {
                    id: inpValue
                    isEnabled: cbEnabled.checkState === Qt.Checked
                    tfWidth: propertyList.width / 3
                    value: propertyDelegate.value

                    Layout.fillWidth: true

                    onTextChanged: txt => {
                        root.propertyModel.setProperty(propertyDelegate.index, "value", txt);
                        root.valueChanged(propertyDelegate.index, txt);
                    }
                    onEditingFinished: txt => {
                        root.propertyModel.setProperty(propertyDelegate.index, "value", txt);
                        root.valueChanged(propertyDelegate.index, txt);
                    }

                    Component.onCompleted: {
                        if (root.withVariables) {
                            varHilighter.setDocument(inpValue.textDocument);
                            varHilighter.enabled = cbEnabled.checked;
                        }
                    }
                }
                RstButton {
                    icon: "qrc:/qt/qml/io/rester/resource/images/close.svg"
                    onClicked: {
                        root.removed(propertyDelegate.index);
                        root.propertyModel.remove(propertyDelegate.index);
                    }
                }
            }
        }
    }
}

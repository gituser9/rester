pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable
pragma FunctionSignatureBehavior: Enforced

import QtQuick
import QtQuick.Controls.Imagine
import QtQuick.Layouts

Item {
    id: root

    required property list<string> texts
    property int currentIdx: 0

    signal clicked(int idx)

    Component.onCompleted: {
        root.clicked(0);
    }

    ButtonGroup {
        id: tabGroup
    }

    RowLayout {
        anchors.fill: parent
        spacing: 8

        Repeater {
            id: repeater
            model: root.texts

            Button {
                id: tabDelegate

                required property int index
                required property var model

                Layout.fillWidth: true
                Layout.preferredWidth: root.width / root.texts.length
                width: root.width / root.texts.length

                checkable: true
                checked: root.currentIdx === tabDelegate.index
                flat: true
                text: root.texts[tabDelegate.index]
                onClicked: {
                    root.clicked(tabDelegate.index);
                }

                ButtonGroup.group: tabGroup
            }

            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}

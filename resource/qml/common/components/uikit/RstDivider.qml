pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable
pragma FunctionSignatureBehavior: Enforced

import QtQuick
import QtQuick.Controls.Imagine

Item {
    implicitHeight: 1

    MenuSeparator {
        anchors.fill: parent
        contentItem: Rectangle {
            color: "#1E000000"
            implicitHeight: 1
            implicitWidth: parent.width
        }
    }
}

pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable
pragma FunctionSignatureBehavior: Enforced

import QtQuick

Item {
    id: errView

    required property string errString

    Text {
        anchors.centerIn: parent
        text: errView.errString
    }
}

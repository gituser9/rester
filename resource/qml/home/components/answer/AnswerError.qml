pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: errView

    required property string errString

    Text {
        anchors.centerIn: parent
        text: errView.errString
    }
}

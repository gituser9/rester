import QtQuick

Item {

    required property string errString

    Text {
        anchors.centerIn: parent
        text: errString
    }
}

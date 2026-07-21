import QtQuick

Item {
    id: root
    implicitHeight: placeButton.height
    implicitWidth: placeButton.width

    property string text: "x"
    property double btnHeight: 20
    property double btnWidth: 20
    property double radius: btnWidth / 2
    property int textSize: 10
    property string backgroundColor: "#f0f0f0"
    property string hoverColor: "#e5e5e5"
    property string textColor: "#777777"
    property string hoverTextColor: "#333333"

    signal clicked

    Rectangle {
        id: placeButton
        anchors.fill: parent
        width: root.btnWidth
        height: root.btnHeight
        radius: root.radius
        color: mouseArea.containsMouse ? root.hoverColor : root.backgroundColor

        Text {
            text: root.text
            font.pixelSize: root.textSize
            font.bold: true
            color: mouseArea.containsMouse ? root.hoverTextColor : root.textColor
            anchors.centerIn: parent
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.clicked();
            }
        }

        Behavior on color {
            ColorAnimation {
                duration: 100
            }
        }
    }
}

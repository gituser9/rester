import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import HttpClient

import "../../../../qml"


Item {

    property Constants consts: Constants {}

    anchors.fill: parent

    ColumnLayout {
        anchors.centerIn: parent

        Image {
            Layout.alignment: Qt.AlignHCenter

            id: imgLoad
            source: "/resource/images/rotate-loop.svg"
            sourceSize.width: 50
            sourceSize.height: 50
            states: State {
                name: "rotated"
                when: true

                PropertyChanges {
                    target: imgLoad
                    rotation: 360
                }
            }
            transitions: Transition {
                RotationAnimation {
                    id: animLoad
                    loops: Animation.Infinite
                    duration: 500
                    direction: RotationAnimation.Clockwise
                }
            }
        }
        Item {
            height: 20
        }
        Button {
            Layout.alignment: Qt.AlignHCenter

            height: consts.bottomButtonHeight
            text: qsTr("Cancel")
            onClicked: {
                HttpClient.abortReply()
            }
        }
    }

}

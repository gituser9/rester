pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import io.rester
import HttpClient

import "../../../../qml"

Item {
    id: waitView
    anchors.fill: parent

    property Constants consts: Constants {}

    ColumnLayout {
        anchors.centerIn: parent

        Image {
            id: imgLoad
            Layout.alignment: Qt.AlignHCenter
            source: "qrc:/resource/images/rotate-loop.svg"
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

            height: waitView.consts.bottomButtonHeight
            text: qsTr("Cancel")
            onClicked: {
                HttpClient.abortReply();
            }
        }
    }
}

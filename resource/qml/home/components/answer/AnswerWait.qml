pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable
pragma FunctionSignatureBehavior: Enforced

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Imagine

import io.rester

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
            source: "qrc:/qt/qml/io/rester/resource/images/rotate-loop.svg"
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
        RstButton {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: waitView.consts.bottomButtonHeight

            text: qsTr("Cancel")
            onClicked: {
                if (App.query) {
                    App.httpClient.abortReply();
                }

                if (App.graphqlQuery) {
                    App.graphqlClient.abortReply();
                }
            }
        }
    }
}

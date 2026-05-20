pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable
pragma FunctionSignatureBehavior: Enforced

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

// import PinModel 1.0
// import models.pins 1.0
import core.app 1.0

Item {
    id: pinItem

    signal setQuery(string uuid)

    ListView {
        id: pinList
        anchors.fill: parent
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: PinModel
        delegate: ItemDelegate {
            id: pinDelegate
            height: 40
            width: ListView.view.width
            onClicked: pinItem.setQuery(pinDelegate.uuid)

            required property string uuid
            required property string name
            required property int index

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8

                Image {
                    sourceSize.width: 18
                    sourceSize.height: 18
                    source: "qrc:/resource/images/pushpin-fill.svg"
                }
                Text {
                    Layout.fillWidth: true
                    Layout.leftMargin: 8

                    text: pinDelegate.name
                }
                Button {
                    flat: true
                    icon {
                        source: "qrc:/resource/images/close.svg"
                        width: 18
                        height: 18
                        color: "black"
                    }
                    onClicked: {
                        PinModel.removeRows(pinDelegate.index, 1);
                    }
                }
            }
        }
    }
}

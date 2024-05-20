import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import core.app 1.0
import PinModel


Item {

    id: pinItem

    signal setQuery(string uuid)

    ListView {
        id: pinList
        anchors.fill: parent
        clip: true
        model: PinModel
        delegate: ItemDelegate {
            height: 40
            width: pinList.width
            onClicked: {
                setQuery(model.uuid)
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8

                Image {
                    sourceSize.width: 18
                    sourceSize.height: 18
                    source: "/resource/images/pushpin-fill.svg"
                }
                Text {
                    Layout.fillWidth: true
                    Layout.leftMargin: 8
                    text: model.name
                }
                Button {
                    flat: true
                    icon.source: "/resource/images/close.svg"
                    icon.width: 18
                    icon.height: 18
                    icon.color: 'black'
                    onClicked: {
                        PinModel.removeRows(index, 1)
                    }
                }
            }
        }
    }

    // ListModel {
    //     id: pinModel
    // }

    // function fillModel() {
    //     // for (let i = 0; i < 3; ++i) {
    //     for (let i = 0; i < 3; ++i) {
    //         pinModel.append({"name": "my name " + i})
    //     }
    // }

    // Connections {
    //     target: App.workspace

    //     function onPinsChanged() {
    //         pinItem.height = PinModel.rowCount() * 40
    //     }
    // }
}

pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable
pragma FunctionSignatureBehavior: Enforced

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Imagine

import io.rester
import "../components"

Item {
    id: pinItem

    signal setQuery(string uuid)

    ListView {
        id: pinList
        anchors.fill: parent
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: App.pinModel
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
                    source: "qrc:/qt/qml/io/rester/resource/images/pushpin-fill.svg"
                }
                Text {
                    Layout.fillWidth: true
                    Layout.leftMargin: 8

                    text: pinDelegate.name
                }
                RstButton {
                    size: RstButton.ButtonSize.Small
                    icon: "qrc:/qt/qml/io/rester/resource/images/close.svg"
                    onClicked: {
                        App.pinModel.removeRows(pinDelegate.index, 1);
                    }
                }
            }
        }
    }
}

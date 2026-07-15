pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable
pragma FunctionSignatureBehavior: Enforced

import QtQuick
import QtQuick.Controls.Imagine
import QtQuick.Layouts

Rectangle {
    id: root
    implicitWidth: mainButton.implicitWidth
    implicitHeight: mainButton.implicitHeight
    border.width: 1
    border.color: '#D3D3D3'
    radius: 6

    property int index: 0
    property string currentText: ""
    property string placeholder: ""
    property url arrowIcon: "qrc:/qt/qml/io/rester/resource/images/arrow-down-s.svg"
    property Component itemDelegate: null
    property alias model: repeater.model

    signal itemSelected(int index, var modelData)

    Button {
        id: mainButton
        anchors.fill: parent
        flat: true
        onClicked: dropdown.visible = !dropdown.visible

        contentItem: RowLayout {
            spacing: 6

            Text {
                text: root.currentText.length > 0 ? root.currentText : root.placeholder
                color: root.currentText.length === 0 ? '#727070' : "black"
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter

                Layout.fillWidth: true
            }

            Image {
                id: arrow
                source: root.arrowIcon
                sourceSize.width: 18
                sourceSize.height: 18
                rotation: dropdown.visible ? 180 : 0

                Layout.alignment: Qt.AlignVCenter

                Behavior on rotation {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.InOutQuad
                    }
                }
            }
        }
    }

    Menu {
        id: dropdown
        y: mainButton.height
        width: Math.max(mainButton.width, dropdown.implicitWidth)
        visible: false

        enter: Transition {
            ParallelAnimation {
                NumberAnimation {
                    property: "opacity"
                    from: 0.0
                    to: 1.0
                    duration: 150
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    property: "y"
                    from: mainButton.height - 8
                    to: mainButton.height
                    duration: 150
                    easing.type: Easing.OutCubic
                }
            }
        }
        exit: Transition {
            ParallelAnimation {
                NumberAnimation {
                    property: "opacity"
                    from: 1.0
                    to: 0.0
                    duration: 120
                    easing.type: Easing.InCubic
                }
                NumberAnimation {
                    property: "y"
                    from: mainButton.height
                    to: mainButton.height - 8
                    duration: 120
                    easing.type: Easing.InCubic
                }
            }
        }

        Repeater {
            id: repeater

            delegate: MenuItem {
                id: menuDelegate

                required property int index
                required property var model

                onClicked: {
                    let data = (typeof menuDelegate.model.modelData !== "undefined") ? menuDelegate.model.modelData : menuDelegate.model;

                    root.index = menuDelegate.index;
                    root.itemSelected(menuDelegate.index, data);
                    dropdown.visible = false;
                }

                contentItem: Loader {
                    id: itemLoader
                    sourceComponent: root.itemDelegate ? root.itemDelegate : defaultDelegate

                    Binding {
                        target: itemLoader.item
                        property: "itemData"
                        value: (typeof menuDelegate.model.modelData !== "undefined") ? menuDelegate.model.modelData : menuDelegate.model
                        when: itemLoader.item !== null
                    }

                    Binding {
                        target: itemLoader.item
                        property: "itemIndex"
                        value: menuDelegate.index
                        when: itemLoader.item !== null
                    }
                }
            }
        }
    }

    Component {
        id: defaultDelegate
        Text {
            id: defaultText
            text: (defaultText.itemData && defaultText.itemData.name !== undefined) ? defaultText.itemData.name : (defaultText.itemData ? defaultText.itemData : "")
            color: "black"
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight

            property var itemData: null
            property int itemIndex: 0
        }
    }
}

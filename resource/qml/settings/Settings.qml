import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    ColumnLayout {
        Layout.alignment: Qt.AlignTop

        anchors.fill: parent

        // font
        Text {
            text: qsTr("Font")
            font.pointSize: 16
        }
        RowLayout {
            spacing: 16

            Text {
                text: qsTr("Interface")
            }
            ComboBox {
                //
            }
            ComboBox {
                model: getSizes()
                // Set the initial currentIndex to the value stored in the backend.
                Component.onCompleted: currentIndex = indexOfValue(12)
            }
        }
        RowLayout {
            spacing: 16

            Text {
                text: qsTr("Monospace")
            }
            ComboBox {
                //
            }
            ComboBox {
                model: getSizes()
                // Set the initial currentIndex to the value stored in the backend.
                Component.onCompleted: currentIndex = indexOfValue(12)
            }
        }
        Item {
            height: 40
        }

        // colors
        Text {
            text: qsTr("Colors")
            font.pointSize: 16
        }
        RowLayout {
            spacing: 16

            Text {
                text: qsTr("JSON field")
            }
            TextField {
                id: tfColorJsonField
            }
            Rectangle {
                height: 24
                width: 48
                radius: 4
                color: 'red'
            }
        }
        RowLayout {
            spacing: 16

            Text {
                text: qsTr("JSON string")
            }
            TextField {
                id: tfColorJsonString
            }
            Rectangle {
                height: 24
                width: 48
                radius: 4
                color: 'red'
            }
        }
        RowLayout {
            spacing: 16

            Text {
                text: qsTr("JSON number")
            }
            TextField {
                id: tfColorJsonNum
            }
            Rectangle {
                height: 24
                width: 48
                radius: 4
                color: 'red'
            }
        }
        RowLayout {
            spacing: 16

            Text {
                text: qsTr("JSON figure brackets")
            }
            TextField {
                id: tfColorJsonFig
            }
            Rectangle {
                height: 24
                width: 48
                radius: 4
                color: 'red'
            }
        }
        RowLayout {
            spacing: 16

            Text {
                text: qsTr("JSON square brackets")
            }
            TextField {
                id: tfColorJsonSqr
            }
            Rectangle {
                height: 24
                width: 48
                radius: 4
                color: 'red'
            }
        }
        RowLayout {
            spacing: 16

            Text {
                text: qsTr("XML/HTML tag")
            }
            TextField {
                id: tfColorXmlTag
            }
            Rectangle {
                height: 24
                width: 48
                radius: 4
                color: 'red'
            }
        }
        RowLayout {
            spacing: 16

            Text {
                text: qsTr("XML/HTML attribute")
            }
            TextField {
                id: tfColorXmlAttr
            }
            Rectangle {
                height: 24
                width: 48
                radius: 4
                color: 'red'
            }
        }
        RowLayout {
            spacing: 16

            Text {
                text: qsTr("XML/HTML attribute value")
            }
            TextField {
                id: tfColorXmlAttrVal
            }
            Rectangle {
                height: 24
                width: 48
                radius: 4
                color: 'red'
            }
        }
    }


    function getSizes() {
        let sizes = [];

        for (let i = 2; i < 100; i += 2) {
            sizes.push(i)
        }

        return sizes
    }
}

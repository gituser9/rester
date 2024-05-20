import QtQuick
import QtQuick.Layouts
import QtQuick.Controls


Item {

    signal download
    signal show
    signal clear

    anchors.fill: parent

    ColumnLayout {
        anchors.centerIn: parent

        Text {
            Layout.alignment: Qt.AlignHCenter

            text: qsTr("Response over 1MB hidden for performance reasons")
        }

        Button {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter

            text: qsTr("Show Anyway")
            onClicked: {
                show()
            }
        }

        Button {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter

            text: qsTr("Download In File")
            onClicked: {
                download()
            }
        }

        Button {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter

            text: qsTr("Clear Answer Body")
            onClicked: {
                clear()
            }
        }
    }
}

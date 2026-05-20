pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable
pragma FunctionSignatureBehavior: Enforced

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Imagine

Item {
    id: bigBodyVew
    anchors.fill: parent

    signal download
    signal show
    signal clear

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
                bigBodyVew.show();
            }
        }

        Button {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter

            text: qsTr("Download In File")
            onClicked: {
                bigBodyVew.download();
            }
        }

        Button {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter

            text: qsTr("Clear Answer Body")
            onClicked: {
                bigBodyVew.clear();
            }
        }
    }
}

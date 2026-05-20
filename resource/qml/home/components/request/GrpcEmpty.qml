pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable
pragma FunctionSignatureBehavior: Enforced

import QtCore
import QtQuick
import QtQuick.Controls.Imagine
import QtQuick.Dialogs

import io.rester
import core.app 1.0

Item {
    id: emptyBodyView

    Rectangle {
        anchors.fill: parent

        Button {
            anchors.centerIn: parent
            checkable: true
            flat: true
            text: qsTr("Upload Proto")
            icon.source: "qrc:/qt/qml/io/rester/resource/images/upload.svg"
            icon.width: 20
            icon.height: 20
            icon.color: 'black'
            onClicked: {
                fileDialog.open();
            }
        }
    }

    FileDialog {
        id: fileDialog
        currentFolder: StandardPaths.standardLocations(StandardPaths.HomeLocation)[0]
        nameFilters: ["Proto files (*.proto)"]
        onAccepted: () => {
            let path = selectedFile.toString().replace("file://", "");
            App.loadProto(path, App.grpcQuery.uuid);
        }
    }
}

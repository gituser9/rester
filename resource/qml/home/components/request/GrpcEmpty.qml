pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable
pragma FunctionSignatureBehavior: Enforced

import QtCore
import QtQuick
import QtQuick.Controls.Imagine
import QtQuick.Dialogs

import io.rester

Item {
    id: emptyBodyView

    Rectangle {
        anchors.fill: parent

        RstButton {
            anchors.centerIn: parent
            size: RstButton.ButtonSize.Tool
            text: qsTr("Upload Proto")
            icon: "qrc:/qt/qml/io/rester/resource/images/upload.svg"
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

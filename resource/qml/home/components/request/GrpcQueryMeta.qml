pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable
pragma FunctionSignatureBehavior: Enforced

import QtQuick
import QtQuick.Controls.Imagine
import QtQuick.Layouts

import io.rester

import "../../../common/components"
import "../../../common/components/uikit"

Rectangle {
    id: winHeader
    anchors.fill: parent

    signal changeHeader(int index)

    Component.onCompleted: {
        winHeader.fillData();
    }

    RstPropertyList {
        id: lstProps
        width: parent.width
        height: parent.height - 50
        propertyModel: headerModel

        onCheckBoxClicked: idx => {
            winHeader.changeHeader(idx);
        }
        onNameChanged: (idx, value) => {
            let header = headerModel.get(idx);
            App.grpcQuery.setMetaItem(idx, value, header.value, header.isEnabled);
        }
        onValueChanged: (idx, value) => {
            let header = headerModel.get(idx);
            App.grpcQuery.setMetaItem(idx, header.name, value, header.isEnabled);
        }
        onRemoved: idx => {
            App.grpcQuery.removeMetaItem(idx);
        }
    }
    RowLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignRight

        spacing: 8
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 8
        anchors.right: parent.right

        RstButton {
            text: qsTr("Add")
            icon: "qrc:/qt/qml/io/rester/resource/images/add.svg"
            onClicked: {
                headerModel.append({
                    "name": '',
                    "value": '',
                    "isEnabled": true
                });
                App.grpcQuery.addMetaItem('', '');
            }
        }
    }

    ListModel {
        id: headerModel
    }

    Connections {
        target: winHeader

        function onChangeHeader(idx: int): void {
            winHeader.sync(idx);
        }
    }

    Timer {
        id: syncTimer
        interval: 500
        running: true
        repeat: false
    }

    VarSyntaxHighlighter {
        id: varHilighter
    }

    function sync(idx: int): void {
        syncTimer.triggered.connect(function (): void {
            let param = headerModel.get(idx);

            App.grpcQuery.setMetaItem(idx, param.name, param.value, param.isEnabled);
        });
        syncTimer.start();
    }

    function fillData(): void {
        for (let h of App.grpcQuery.meta) {
            headerModel.append({
                "name": h.name,
                "value": h.value,
                "isEnabled": h.isEnabled
            });
        }
    }
}

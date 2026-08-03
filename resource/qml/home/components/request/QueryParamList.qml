pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable
pragma FunctionSignatureBehavior: Enforced

import QtQuick
import QtQuick.Layouts

import io.rester

import "../../../common/components"
import "../../../common/components/uikit"

Rectangle {
    id: root

    required property var params
    readonly property Constants consts: Constants {}

    signal changeHeader(int index)
    signal setParam(int idx, string name, string val, bool enabled)
    signal removeParam(int idx)
    signal addParam

    onParamsChanged: {
        root.fillData();
    }

    RstPropertyList {
        id: lstProps
        width: parent.width
        height: parent.height - 50
        propertyModel: paramModel

        onCheckBoxClicked: idx => {
            root.changeHeader(idx);
        }
        onNameChanged: (idx, value) => {
            let param = paramModel.get(idx);
            let exists = root.params[idx];

            if (param.name === exists.name) {
                return;
            }

            root.setParam(idx, value, param.value, param.isEnabled);
        }
        onValueChanged: (idx, value) => {
            let param = paramModel.get(idx);
            let exists = root.params[idx];

            if (param.value === exists.value) {
                return;
            }

            root.setParam(idx, param.name, value, param.isEnabled);
        }
        onRemoved: idx => {
            root.removeParam(idx);
        }
    }
    RowLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignRight

        spacing: root.consts.space
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.consts.space
        anchors.right: parent.right

        RstButton {
            text: qsTr("Add")
            icon: "qrc:/qt/qml/io/rester/resource/images/add.svg"
            onClicked: {
                root.addParam();
            }
        }
    }

    ListModel {
        id: paramModel
    }

    Connections {
        target: root

        function onChangeHeader(idx: int): void {
            root.sync(idx);
        }
    }

    Timer {
        id: syncTimer
        interval: 300
        running: true
        repeat: false
    }

    function sync(idx: int): void {
        syncTimer.triggered.connect(() => {
            let param = paramModel.get(idx);

            root.setParam(idx, param.name, param.value, param.isEnabled);
        });
        syncTimer.start();
    }

    function fillData(): void {
        if (!root.params) {
            paramModel.clear();
            return;
        }

        if (paramModel.count === root.params.length) {
            for (let i = 0; i < root.params.length; i++) {
                let m = paramModel.get(i);
                let p = root.params[i];

                if (m.name !== p.name) {
                    paramModel.setProperty(i, "name", p.name);
                }
                if (m.value !== p.value) {
                    paramModel.setProperty(i, "value", p.value);
                }
                if (m.isEnabled !== p.isEnabled) {
                    paramModel.setProperty(i, "isEnabled", p.isEnabled);
                }
            }

            return;
        }

        paramModel.clear();

        for (let h of root.params) {
            paramModel.append({
                "name": h.name,
                "value": h.value,
                "isEnabled": h.isEnabled
            });
        }
    }
}

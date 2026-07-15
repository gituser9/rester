pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable
pragma FunctionSignatureBehavior: Enforced

import QtQuick
import QtQuick.Controls.Imagine
import QtQuick.Layouts

import io.rester

import "../home/modal"
import "../common/components"
import "../common/components/uikit"

Item {
    id: wsVars
    anchors.fill: parent

    property var vars: ({})
    property int envIndex: -1
    property string env: ''
    property Constants consts: Constants {}

    Component.onCompleted: {
        wsVars.fillData();
    }

    ColumnLayout {
        anchors.fill: parent

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: App.workspace.name + ' ' + qsTr("variables")
                font.bold: true
                font.pointSize: 15
            }
            Item {
                Layout.fillWidth: true
            }
            RstButton {
                text: qsTr("Add Environment")
                icon: "qrc:/qt/qml/io/rester/resource/images/add.svg"
                onClicked: {
                    mdlAddEnv.open();
                }
            }
        }

        ListView {
            Layout.fillWidth: true
            Layout.preferredHeight: 60

            spacing: wsVars.consts.space
            orientation: ListView.Horizontal
            model: modeModel
            delegate: Button {
                id: envDelefate

                required property string name
                required property int index

                text: envDelefate.name
                flat: true
                width: 100
                down: envDelefate.name === wsVars.env
                onClicked: {
                    wsVars.env = envDelefate.name;
                    wsVars.envIndex = envDelefate.index;

                    wsVars.fillVars(envDelefate.name);
                    App.workspaceModel.setVars(App.workspace.uuid, App.workspace.name, wsVars.vars);
                }

                Component.onCompleted: {
                    if (envDelefate.name === wsVars.env) {
                        wsVars.envIndex = index;
                    }
                }
            }
        }

        ListView {
            id: varList
            Layout.preferredWidth: wsVars.width
            Layout.preferredHeight: wsVars.height - 50
            clip: true
            model: varModel
            delegate: Rectangle {
                id: varDeleagate
                height: 60
                width: wsVars.width

                required property string name
                required property string value
                required property int index

                RowLayout {
                    spacing: 16
                    anchors.fill: parent

                    RstInput {
                        tfWidth: varList.width / 2
                        value: varDeleagate.name
                        placeholder: qsTr("Name")

                        Layout.fillWidth: true

                        onTextChanged: txt => {
                            let varr = wsVars.vars[wsVars.env][varDeleagate.index];
                            wsVars.vars[wsVars.env][varDeleagate.index] = {
                                "name": txt,
                                "value": varr.value
                            };
                            App.workspaceModel.setVars(App.workspace.uuid, App.workspace.name, wsVars.vars);
                        }
                    }
                    RstInput {
                        tfWidth: varList.width / 2
                        value: varDeleagate.value
                        placeholder: qsTr("Value")

                        Layout.fillWidth: true

                        onTextChanged: txt => {
                            let varr = wsVars.vars[wsVars.env][varDeleagate.index];
                            wsVars.vars[wsVars.env][varDeleagate.index] = {
                                "name": varr.name,
                                "value": txt
                            };
                            App.workspaceModel.setVars(App.workspace.uuid, App.workspace.name, wsVars.vars);
                        }
                    }
                    RstButton {
                        icon: "qrc:/qt/qml/io/rester/resource/images/close.svg"
                        onClicked: {
                            wsVars.vars[wsVars.env].splice(varDeleagate.index, 1);
                            varModel.remove(varDeleagate.index);

                            App.workspaceModel.setVars(App.workspace.uuid, App.workspace.name, wsVars.vars);
                        }
                    }
                }
            }
        }
    }

    RowLayout {
        spacing: wsVars.consts.space
        anchors.bottom: parent.bottom
        anchors.bottomMargin: wsVars.consts.space
        anchors.right: parent.right
        anchors.left: parent.left
        visible: wsVars.envIndex !== -1

        RstButton {
            text: qsTr("Delete Environment")
            icon: "qrc:/qt/qml/io/rester/resource/images/close.svg"
            onClicked: {
                delete wsVars.vars[wsVars.env];

                modeModel.remove(wsVars.envIndex);
                wsVars.env = '';
                wsVars.envIndex = -1;
                varModel.clear();

                App.workspaceModel.setVars(App.workspace.uuid, App.workspace.name, wsVars.vars);
            }
        }
        Item {
            Layout.fillWidth: true
        }
        RstButton {
            text: qsTr("Add Variable")
            icon: "qrc:/qt/qml/io/rester/resource/images/add.svg"
            onClicked: {
                let data = {
                    "name": '',
                    "value": ''
                };
                wsVars.vars[wsVars.env].push(data);
                varModel.append(data);

                App.workspaceModel.setVars(App.workspace.uuid, App.workspace.name, wsVars.vars);
            }
        }
    }

    ListModel {
        id: varModel
    }

    ListModel {
        id: modeModel
    }

    InputDialog {
        id: mdlAddEnv
        anchors.centerIn: parent
        title: qsTr("Create Environment")
        placeholder: qsTr("Environment Name")
        onOk: envName => {
            if (wsVars.vars["env"] === undefined) {
                wsVars.vars = {};
                wsVars.vars.env = envName;
            }

            wsVars.vars[envName] = [];
            modeModel.append({
                "name": envName
            });

            App.workspaceModel.setVars(App.workspace.uuid, App.workspace.name, wsVars.vars);
        }
    }

    function fillData(): void {
        vars = App.workspace.variables;

        if (Object.keys(vars).length === 0) {
            return;
        }

        for (let key in vars) {
            if (key === 'env') {
                continue;
            }

            modeModel.append({
                "name": key
            });
        }

        wsVars.fillVars();
    }

    function fillVars(): void {
        varModel.clear();

        if (env === '') {
            return;
        }

        for (let item of wsVars.vars[wsVars.env]) {
            varModel.append({
                "name": item.name,
                "value": item.value
            });
        }
    }
}

pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable
pragma FunctionSignatureBehavior: Enforced

import QtQuick
import QtQuick.Controls.Imagine
import QtQuick.Layouts

import io.rester

import "../home/modal"
import "../common/components"

Item {
    id: wsVars

    property var vars: ({})
    property int envIndex: -1
    property string env: ''

    Component.onCompleted: {
        wsVars.fillData();
    }
    anchors.fill: parent

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
            Button {
                text: qsTr("Add Environment")
                flat: true
                icon.source: "qrc:/qt/qml/io/rester/resource/images/add.svg"
                icon.width: 22
                icon.height: 22
                icon.color: 'black'
                onClicked: {
                    mdlAddEnv.open();
                }
            }
        }

        ListView {
            Layout.fillWidth: true
            Layout.preferredHeight: 60

            spacing: 8
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

                    Column {
                        Layout.fillWidth: true

                        FlickableEdit {
                            id: tfVarName
                            height: 20
                            width: varList.width / 2
                            value: varDeleagate.name
                            onEditingFinish: txt => {
                                wsVars.vars[wsVars.env][varDeleagate.index] = {
                                    "name": txt,
                                    "value": tfVarValue.text
                                };
                                App.workspaceModel.setVars(App.workspace.uuid, App.workspace.name, wsVars.vars);
                            }
                        }
                        MenuSeparator {
                            width: parent.width
                            contentItem: Rectangle {
                                implicitWidth: parent.width
                                implicitHeight: 1
                                color: "#1E000000"
                            }
                        }
                    }
                    Column {
                        Layout.fillWidth: true

                        FlickableEdit {
                            id: tfVarValue
                            height: 20
                            width: varList.width / 2
                            value: varDeleagate.value
                            onEditingFinish: txt => {
                                wsVars.vars[wsVars.env][varDeleagate.index] = {
                                    "name": tfVarName.text,
                                    "value": txt
                                };
                                App.workspaceModel.setVars(App.workspace.uuid, App.workspace.name, wsVars.vars);
                            }
                        }
                        MenuSeparator {
                            width: parent.width
                            contentItem: Rectangle {
                                implicitWidth: parent.width
                                implicitHeight: 1
                                color: "#1E000000"
                            }
                        }
                    }
                    Button {
                        flat: true
                        icon.source: "qrc:/qt/qml/io/rester/resource/images/close.svg"
                        icon.width: 18
                        icon.height: 18
                        icon.color: 'black'
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
        spacing: 8
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 8
        anchors.right: parent.right
        anchors.left: parent.left
        visible: wsVars.envIndex !== -1

        Button {
            text: qsTr("Delete Environment")
            flat: true
            icon.source: "qrc:/qt/qml/io/rester/resource/images/close.svg"
            icon.width: 22
            icon.height: 22
            icon.color: 'black'
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
        Button {
            text: qsTr("Add Variable")
            flat: true
            icon.source: "qrc:/qt/qml/io/rester/resource/images/add.svg"
            icon.width: 22
            icon.height: 22
            icon.color: 'black'
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

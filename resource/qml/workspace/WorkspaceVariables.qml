import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import WorkspaceModel
import core.app 1.0

import "../home/modal"
import "../common/components"


Item {

    property var vars: ({})
    property int envIndex: -1
    property string env: ''

    Component.onCompleted: {
        fillData()
    }

    id: wsVars
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
                icon.source: "/resource/images/add.svg"
                icon.width: 22
                icon.height: 22
                icon.color: 'black'
                onClicked: {
                    mdlAddEnv.open()
                }
            }
        }


        ListView {
            Layout.fillWidth: true

            spacing: 8
            height: 60
            orientation: ListView.Horizontal
            model: modeModel
            delegate: Button {
                Component.onCompleted: {
                    if (model.name === env) {
                        envIndex = index
                    }
                }

                text: model.name
                flat: true
                width: 100
                down: model.name === env
                onClicked: {
                    env = model.name
                    envIndex = index

                    fillVars(model.name)
                    WorkspaceModel.setVars(App.workspace.uuid, App.workspace.name, vars)
                }
            }
        }

        ListView {
            // Layout.fillWidth: true
            // Layout.preferredHeight: parent.height - 50


            id: varList
            width: parent.width
            height: parent.height - 50
            clip: true
            model: varModel
            delegate: Rectangle {
                height: 60
                width: parent.width
                // Layout.fillWidth: true

                RowLayout {
                    spacing: 16
                    anchors.fill: parent

                    Column {
                        Layout.fillWidth: true

                        FlickableEdit {
                            id: tfVarName
                            height: 20
                            width: varList.width / 2
                            value: model.name
                            onEditingFinish: txt => {
                                 vars[env][index] = {
                                     "name": txt,
                                     "value": tfVarValue.text
                                 }
                                 WorkspaceModel.setVars(App.workspace.uuid, App.workspace.name, vars)
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
                            value: model.value
                            onEditingFinish: txt => {
                                 vars[env][index] = {
                                     "name": tfVarName.text,
                                     "value": txt
                                 }
                                 WorkspaceModel.setVars(App.workspace.uuid, App.workspace.name, vars)
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
                        icon.source: "/resource/images/close.svg"
                        icon.width: 18
                        icon.height: 18
                        icon.color: 'black'
                        onClicked: {
                            vars[env].splice(index, 1)
                            varModel.remove(index)

                            WorkspaceModel.setVars(App.workspace.uuid, App.workspace.name, vars)
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
        visible: envIndex !== -1

        Button {
            text: qsTr("Delete Environment")
            flat: true
            icon.source: "/resource/images/close.svg"
            icon.width: 22
            icon.height: 22
            icon.color: 'black'
            onClicked: {
                delete vars[env]

                modeModel.remove(envIndex)
                env = ''
                envIndex = -1
                varModel.clear()

                WorkspaceModel.setVars(App.workspace.uuid, App.workspace.name, vars)
            }
        }
        Item {
            Layout.fillWidth: true
        }
        Button {
            text: qsTr("Add Variable")
            flat: true
            icon.source: "/resource/images/add.svg"
            icon.width: 22
            icon.height: 22
            icon.color: 'black'
            onClicked: {
                let data = {
                    "name": '',
                    "value": ''
                }
                vars[env].push(data)
                varModel.append(data)

                WorkspaceModel.setVars(App.workspace.uuid, App.workspace.name, vars)
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
            if (vars["env"] === undefined) {
                vars = {}
                vars.env = envName
            }

            vars[envName] = []
            modeModel.append({"name": envName})

            WorkspaceModel.setVars(App.workspace.uuid, App.workspace.name, vars)
        }
    }


    Connections {
        target: App.workspace

        function onVariablesChanged() {
            // fillData()
        }
    }


    function fillData() {
        vars = App.workspace.variables

        if (Object.keys(vars).length === 0) {
            return
        }

        for (let key in vars) {
            if (key === 'env') {
                continue
            }

            modeModel.append({"name": key})
        }

        fillVars()
    }

    function fillVars() {
        varModel.clear()

        if (env === '') {
            return
        }

        for (let item of vars[env]) {
            varModel.append({
                "name": item.name,
                "value": item.value
            })
        }
    }

}

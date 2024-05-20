import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import core.app 1.0
import RoutesModel

// import '../../colors'


Rectangle {

    property string currentEnv


    Component.onCompleted: {
        if (App.workspace.env === '') {
            currentEnv = 'No Env'
        } else {
            currentEnv = App.workspace.env
        }

        setEnvs(App.workspace.getEnvNames())
    }

    id: dropDownView


    RowLayout {
        anchors.fill: parent

        Button {
            id: mainButton
            flat: true
            text: dropDownView.currentEnv + "   " + "\u25BE"
            onClicked: dropdown.visible = !dropdown.visible
        }

        Menu {
            id: dropdown
            y: mainButton.height
            visible: false

            Repeater {
                anchors.fill: parent
                model: envModel
                delegate: MenuItem {
                    text: model.text
                    visible: true
                    onClicked: {
                        if (App.workspace.env !== model.text) {
                            // App.workspace.env = model.text
                            App.setEnv(model.text)
                        }

                        dropdown.visible = false
                    }
                }
            }
        }
    }


    Connections {
        target: App

        function onWorkspaceChanged() {
            if (App.workspace.env === '') {
                currentEnv = 'No Env'
            } else {
                currentEnv = App.workspace.env
            }

            setEnvs(App.workspace.getEnvNames())
        }
    }

    Connections {
        target: App.workspace

        function onEnvChanged() {
            if (App.workspace.env === '') {
                currentEnv = 'No Env'
            } else {
                currentEnv = App.workspace.env
            }
        }
    }


    ListModel {
        id: envModel
    }


    function setEnvs(envs) {
        envModel.clear()

        for (let envName of envs) {
            envModel.append({ text: envName })
        }
    }
}

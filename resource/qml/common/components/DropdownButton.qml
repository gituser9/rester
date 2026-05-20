pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable
pragma FunctionSignatureBehavior: Enforced

import QtQuick
import QtQuick.Controls.Imagine
import QtQuick.Layouts

import io.rester
import core.app 1.0
import RoutesModel

// import '../../colors'

Rectangle {
    id: dropDownView

    property string currentEnv

    Component.onCompleted: {
        if (App.workspace.env === '') {
            dropDownView.currentEnv = 'No Env';
        } else {
            dropDownView.currentEnv = App.workspace.env;
        }

        setEnvs(App.workspace.getEnvNames());
    }

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
                    id: menuDelegate

                    required property string name

                    text: menuDelegate.name
                    visible: true
                    onClicked: {
                        if (App.workspace.env !== menuDelegate.name) {
                            App.setEnv(menuDelegate.name);
                        }

                        dropdown.visible = false;
                    }
                }
            }
        }
    }

    Connections {
        target: App

        function onWorkspaceChanged(): void {
            if (App.workspace.env === '') {
                dropDownView.currentEnv = 'No Env';
            } else {
                dropDownView.currentEnv = App.workspace.env;
            }

            dropDownView.setEnvs(App.workspace.getEnvNames());
        }
    }

    Connections {
        target: App.workspace

        function onEnvChanged(): void {
            if (App.workspace.env === '') {
                dropDownView.currentEnv = 'No Env';
            } else {
                dropDownView.currentEnv = App.workspace.env;
            }
        }

        function onVariablesChanged(): void {
            dropDownView.setEnvs(App.workspace.getEnvNames());
        }
    }

    ListModel {
        id: envModel
    }

    function setEnvs(envs: list<string>): void {
        envModel.clear();

        for (let envName of envs) {
            envModel.append({
                "name": envName
            });
        }
    }
}

pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable
pragma FunctionSignatureBehavior: Enforced

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import io.rester

ColumnLayout {
    id: root
    spacing: 0

    property string jsonText: ""
    property int fontSize: 11
    readonly property Constants consts: Constants {}

    JsonTreeModel {
        id: jsonModel
        jsonText: root.jsonText
        filterText: searchField.text
    }

    // Мгновенный скролл и ноль лагов благодаря переиспользованию элементов
    ListView {
        id: listView
        clip: true
        model: jsonModel

        Layout.fillWidth: true
        Layout.fillHeight: true

        // Плавное появление дочерних строк
        add: Transition {
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: 150
            }
        }

        // Плавное удаление дочерних строк
        remove: Transition {
            NumberAnimation {
                property: "opacity"
                from: 1
                to: 0
                duration: 150
            }
        }

        // Анимация смещения остальных элементов при вставке/удалении
        displaced: Transition {
            NumberAnimation {
                properties: "y"
                duration: 150
            }
        }

        delegate: RowLayout {
            id: delegateRoot
            width: listView.width
            height: 24
            spacing: 4

            required property int index
            required property int nodeDepth
            required property bool nodeIsContainer
            required property bool nodeExpanded
            required property bool nodeIsClosing
            required property string nodeKey
            required property string nodeDisplayValue

            // 1. Отступ дерева
            Item {
                Layout.preferredWidth: delegateRoot.nodeDepth * 16
                Layout.fillHeight: true
            }

            // 2. Место под стрелочку (24px для ровного выравнивания)
            Item {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                Layout.alignment: Qt.AlignVCenter

                Rectangle {
                    anchors.fill: parent
                    color: '#e5e5e5'
                    radius: 4
                    opacity: imgMouseArea.containsMouse ? 1.0 : 0.0
                    visible: delegateRoot.nodeIsContainer && !delegateRoot.nodeIsClosing

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 150
                        }
                    }
                }

                Image {
                    source: "qrc:/qt/qml/io/rester/resource/images/arrow-right.svg"
                    sourceSize.width: 18
                    sourceSize.height: 18
                    rotation: delegateRoot.nodeExpanded ? 90 : 0
                    anchors.centerIn: parent
                    visible: delegateRoot.nodeIsContainer && !delegateRoot.nodeIsClosing

                    Behavior on rotation {
                        NumberAnimation {
                            duration: 200
                        }
                    }
                }

                MouseArea {
                    id: imgMouseArea
                    anchors.fill: parent
                    enabled: delegateRoot.nodeIsContainer && !delegateRoot.nodeIsClosing
                    hoverEnabled: delegateRoot.nodeIsContainer && !delegateRoot.nodeIsClosing
                    cursorShape: delegateRoot.nodeIsContainer ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: jsonModel.toggleExpand(delegateRoot.index)
                }
            }

            // 3. Ключ (скрыт на закрывающих скобках)
            TextEdit {
                readOnly: true
                selectByMouse: true
                text: delegateRoot.nodeKey ? `"${delegateRoot.nodeKey}": ` : ""
                font.family: "monospace"
                font.pointSize: root.fontSize
                font.bold: true
                color: "#8B008B"
                visible: !delegateRoot.nodeIsClosing && delegateRoot.nodeKey !== ""
                Layout.alignment: Qt.AlignVCenter
            }

            // 4. Значение (для nodeIsClosing это будет "}" или "]")
            TextEdit {
                readOnly: true
                selectByMouse: true
                text: delegateRoot.nodeDisplayValue
                font.family: "monospace"
                font.pointSize: root.fontSize
                Layout.alignment: Qt.AlignVCenter

                color: {
                    if (delegateRoot.nodeIsClosing || delegateRoot.nodeIsContainer)
                        return "#333333";
                    if (delegateRoot.nodeDisplayValue === "null")
                        return "#777777";
                    if (delegateRoot.nodeDisplayValue.startsWith("\""))
                        return "#006400";
                    if (delegateRoot.nodeDisplayValue === "true" || delegateRoot.nodeDisplayValue === "false")
                        return "#00008B";
                    return "#8B0000";
                }
            }

            // 5. Распорка
            Item {
                Layout.fillWidth: true
            }
        }
    }

    RowLayout {
        spacing: root.consts.space

        Layout.fillWidth: true
        Layout.topMargin: root.consts.space
        Layout.bottomMargin: root.consts.space / 2

        TextField {
            id: searchField
            placeholderText: qsTr("Filter by key, value")
            selectByMouse: true
            font.pointSize: 10
            rightPadding: clearButton.visible ? clearButton.width + 18 : 12

            Layout.fillWidth: true

            RstPlacementButton {
                id: clearButton
                anchors.right: parent.right
                anchors.rightMargin: root.consts.space
                anchors.verticalCenter: parent.verticalCenter
                visible: searchField.text !== ""
                onClicked: {
                    searchField.clear();
                    searchField.forceActiveFocus();
                }
            }
        }
        RstButton {
            implicitHeight: root.consts.bottomButtonHeight
            text: qsTr("Clear")
            icon: "qrc:/qt/qml/io/rester/resource/images/close.svg"
            onClicked: {
                if (App.query && App.query.lastAnswer) {
                    App.query.lastAnswer.body = '';
                }
            }
        }
        RstButton {
            implicitHeight: root.consts.bottomButtonHeight
            text: qsTr("Copy")
            icon: "qrc:/qt/qml/io/rester/resource/images/copy.svg"
            onClicked: {
                teCopy.text = App.query.lastAnswer.body;
                teCopy.selectAll();
                teCopy.copy();
                teCopy.clear();
            }
        }
    }
    TextEdit {
        id: teCopy
        visible: false
    }
}

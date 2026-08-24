pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable
pragma FunctionSignatureBehavior: Enforced

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    spacing: 0

    property string xmlText: ""
    property int fontSize: 11
    readonly property Constants consts: Constants {}

    XmlTreeModel {
        id: xmlModel
        xmlText: root.xmlText
        filterText: searchField.text
    }

    ListView {
        id: listView
        clip: true
        model: xmlModel

        Layout.fillWidth: true
        Layout.fillHeight: true

        flickableDirection: Flickable.AutoFlickIfNeeded
        contentWidth: contentItem.childrenRect.width

        ScrollBar.vertical: ScrollBar {}
        ScrollBar.horizontal: ScrollBar {}

        add: Transition {
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: 150
            }
        }
        remove: Transition {
            NumberAnimation {
                property: "opacity"
                from: 1
                to: 0
                duration: 150
            }
        }
        displaced: Transition {
            NumberAnimation {
                properties: "y"
                duration: 150
            }
        }

        delegate: RowLayout {
            id: delegateRoot
            spacing: 4
            implicitWidth: indentItem.implicitWidth + iconItem.implicitWidth + xmlTextEdit.implicitWidth + 20

            required property int index
            required property int nodeDepth
            required property bool nodeIsContainer
            required property bool nodeExpanded
            required property bool nodeIsClosing
            required property string nodeRichText

            // 1. Отступ дерева
            Item {
                id: indentItem
                implicitWidth: delegateRoot.nodeDepth * 16
                Layout.fillHeight: true
            }

            // 2. Иконка стрелочки
            Item {
                id: iconItem
                implicitWidth: 24
                implicitHeight: 24
                Layout.alignment: Qt.AlignTop

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
                    onClicked: xmlModel.toggleExpand(delegateRoot.index)
                }
            }

            // 3. Форматированный XML/HTML текст
            TextEdit {
                id: xmlTextEdit
                readOnly: true
                selectByMouse: true
                textFormat: TextEdit.RichText
                text: delegateRoot.nodeRichText
                font.family: "monospace"
                font.pointSize: root.fontSize
                Layout.alignment: Qt.AlignTop
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

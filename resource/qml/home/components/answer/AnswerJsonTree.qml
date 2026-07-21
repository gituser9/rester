pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable
pragma FunctionSignatureBehavior: Enforced

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    anchors.fill: parent
    spacing: 0

    required property string jsonText
    property int fontSize: 16
    readonly property Constants consts: Constants {}

    ScrollView {
        id: jsonViewer
        clip: true

        Layout.fillWidth: true
        Layout.fillHeight: true

        readonly property string filterText: searchField.text

        property var jsonObj: {
            try {
                return JSON.parse(root.jsonText);
            } catch (e) {
                return {
                    "error": "Невалидный JSON",
                    "details": e.toString()
                };
            }
        }

        // ХЕЛПЕР: Пуленепробиваемое определение массива в QML
        function checkIsArray(val): bool {
            return val !== null && typeof val === 'object' && (Array.isArray(val) || typeof val.forEach === 'function');
        }

        // Рекурсивный поиск с учетом фикса массивов
        function itemContainsQuery(val, query): bool {
            if (!query)
                return true;
            let q = query.toLowerCase();

            if (val === null)
                return "null".includes(q);

            if (typeof val !== 'object') {
                return String(val).toLowerCase().includes(q);
            }

            if (jsonViewer.checkIsArray(val)) {
                for (let i = 0; i < val.length; i++) {
                    if (itemContainsQuery(val[i], query))
                        return true;
                }
                return false;
            }

            let keys = Object.keys(val);
            for (let i = 0; i < keys.length; i++) {
                if (keys[i].toLowerCase().includes(q))
                    return true;
                if (itemContainsQuery(val[keys[i]], query))
                    return true;
            }
            return false;
        }

        // Формирование модели с учетом фикса массивов
        function getFilteredModel(val, query) {
            if (val === null || typeof val !== 'object')
                return [];
            let q = query.toLowerCase();
            let result = [];

            // Используем надежную проверку
            if (jsonViewer.checkIsArray(val)) {
                for (let i = 0; i < val.length; i++) {
                    if (!q || itemContainsQuery(val[i], query)) {
                        result.push({
                            "key": "",
                            "value": val[i]
                        }); // Для массивов ключ пустой
                    }
                }
            } else {
                let keys = Object.keys(val);
                for (let i = 0; i < keys.length; i++) {
                    let k = keys[i];
                    if (!q || k.toLowerCase().includes(q) || itemContainsQuery(val[k], query)) {
                        result.push({
                            "key": k,
                            "value": val[k]
                        });
                    }
                }
            }
            return result;
        }

        // Шаблон одного узла дерева
        Component {
            id: jsonNodeComponent

            Column {
                id: internalNode

                readonly property string apiKey: parent && parent.jsonKey !== undefined ? parent.jsonKey : ""
                readonly property var apiValue: parent && parent.jsonValue !== undefined ? parent.jsonValue : null
                readonly property int depth: parent && parent.jsonDepth !== undefined ? parent.jsonDepth : 0

                // Обновленная логика типов данных на базе хелпера
                readonly property bool isArray: jsonViewer.checkIsArray(apiValue)
                readonly property bool isObject: apiValue !== null && typeof apiValue === 'object' && !isArray
                readonly property bool isContainer: isObject || isArray
                property bool expanded: true

                Connections {
                    target: jsonViewer
                    function onFilterTextChanged() {
                        if (jsonViewer.filterText !== "") {
                            internalNode.expanded = true;
                        }
                    }
                }

                RowLayout {
                    spacing: 6

                    Item {
                        Layout.leftMargin: (internalNode.depth * 16) + 16
                    }

                    // icon
                    Item {
                        visible: internalNode.isContainer

                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredHeight: 24
                        Layout.preferredWidth: 24

                        Rectangle {
                            anchors.fill: parent
                            color: '#e5e5e5'
                            radius: 4
                            opacity: imgMouseArea.containsMouse ? 1.0 : 0.0

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 150
                                }
                            }
                        }
                        Image {
                            id: arrow
                            source: "qrc:/qt/qml/io/rester/resource/images/arrow-right.svg"
                            sourceSize.width: 18
                            sourceSize.height: 18
                            rotation: internalNode.expanded ? 90 : 0
                            anchors.centerIn: parent

                            Behavior on rotation {
                                NumberAnimation {
                                    duration: 200
                                    easing.type: Easing.InOutQuad
                                }
                            }
                        }
                        MouseArea {
                            id: imgMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: internalNode.expanded = !internalNode.expanded
                        }
                    }
                    // key
                    TextEdit {
                        readOnly: true
                        selectByMouse: true
                        text: internalNode.apiKey ? `"${internalNode.apiKey}": ` : ""
                        font.family: "monospace"
                        font.pixelSize: root.fontSize
                        font.bold: true
                        color: "#8B008B"
                        visible: internalNode.apiKey !== ""

                        Layout.leftMargin: internalNode.isContainer ? 0 : 16
                    }
                    // value
                    TextEdit {
                        readOnly: true
                        selectByMouse: true
                        text: {
                            if (internalNode.isObject)
                                return internalNode.expanded ? "{" : "{...}";
                            if (internalNode.isArray)
                                return internalNode.expanded ? "[" : "[...]";
                            if (internalNode.apiValue === null)
                                return "null";
                            if (typeof internalNode.apiValue === "string")
                                return `"${internalNode.apiValue}"`;
                            return String(internalNode.apiValue);
                        }
                        font.family: "monospace"
                        font.pixelSize: root.fontSize
                        color: {
                            if (internalNode.isContainer)
                                return "#333333";
                            if (internalNode.apiValue === null)
                                return "#777777";
                            if (typeof internalNode.apiValue === "string")
                                return "#006400";
                            if (typeof internalNode.apiValue === "number")
                                return "#8B0000";
                            if (typeof internalNode.apiValue === "boolean")
                                return "#00008B";
                            return "#333333";
                        }
                    }
                }
                // end
                Column {
                    id: nestedContainer
                    clip: true
                    visible: internalNode.isContainer
                    height: implicitHeight
                    opacity: 1.0
                    states: [
                        State {
                            name: "collapsed"
                            when: !internalNode.expanded
                            PropertyChanges {
                                target: nestedContainer
                                height: 0
                                opacity: 0.0
                            }
                        }
                    ]
                    transitions: [
                        Transition {
                            from: "*"
                            to: "*"
                            NumberAnimation {
                                properties: "height,opacity"
                                duration: 200
                                easing.type: Easing.InOutQuad
                            }
                        }
                    ]

                    Repeater {
                        model: jsonViewer.getFilteredModel(internalNode.apiValue, jsonViewer.filterText)

                        delegate: Loader {
                            id: childLoader

                            required property var modelData
                            required property int index

                            property string jsonKey: modelData.key
                            property var jsonValue: modelData.value
                            property int jsonDepth: internalNode.depth + 1

                            sourceComponent: jsonNodeComponent
                        }
                    }

                    Text {
                        text: internalNode.isObject ? "}" : "]"
                        font.family: "monospace"
                        font.pixelSize: root.fontSize
                        color: "#333333"
                        leftPadding: (internalNode.depth * 16) + 24
                        visible: internalNode.isContainer
                    }
                }
            }
        }

        Loader {
            id: rootLoader
            property string jsonKey: ""
            property var jsonValue: jsonViewer.jsonObj
            property int jsonDepth: 0
            sourceComponent: jsonNodeComponent
        }
    }
    RowLayout {
        spacing: root.consts.space

        Layout.fillWidth: true
        Layout.topMargin: root.consts.space
        Layout.bottomMargin: root.consts.space

        TextField {
            id: searchField
            placeholderText: qsTr("Filter by key, value")
            selectByMouse: true
            font.pixelSize: 13
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

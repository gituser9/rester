pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable
pragma FunctionSignatureBehavior: Enforced

import QtQuick

Item {
    id: flickableEdit

    required property string value

    property alias text: teMain.text
    property alias textDocument: teMain.textDocument

    property bool isEnabled: true
    property bool isFocused: false
    property string prevValue: ''
    property string placeholder: ''

    signal editingFinish(string txt)
    signal textChange(string txt)

    Component.onCompleted: {
        prevValue = value;
        startTimer();
    }

    Flickable {
        id: flick
        anchors.fill: parent
        clip: true

        function ensureVisible(r: rect): void {
            if (contentX >= r.x)
                contentX = r.x;
            else if (contentX + width <= r.x + r.width)
                contentX = r.x + r.width - width;

            if (contentY >= r.y)
                contentY = r.y;
            else if (contentY + height <= r.y + r.height)
                contentY = r.y + r.height - height;
        }

        TextEdit {
            id: teMain
            enabled: flickableEdit.isEnabled
            color: flickableEdit.isEnabled ? 'black' : 'grey'
            anchors.verticalCenter: parent.verticalCenter
            width: flick.width
            leftPadding: 8
            text: flickableEdit.value
            font.family: "Monospace"
            focus: flickableEdit.isFocused
            onEditingFinished: {
                flickableEdit.editingFinish(teMain.text);
            }
            onTextChanged: {
                flickableEdit.value = teMain.text;
                flickableEdit.textChange(teMain.text);

                if (!syncTimer.running) {
                    syncTimer.start();
                }
            }
            onCursorRectangleChanged: flick.ensureVisible(cursorRectangle)

            Text {
                anchors.fill: parent
                visible: !teMain.text && !teMain.activeFocus
                text: flickableEdit.placeholder
                leftPadding: 10
                rightPadding: 10
                verticalAlignment: TextEdit.AlignVCenter
                color: 'grey'
            }
        }
    }

    Timer {
        id: syncTimer
        interval: 300
        running: true
        repeat: false
    }

    function startTimer(): void {
        syncTimer.triggered.connect(() => {
            if (prevValue !== teMain.text) {
                prevValue = teMain.text;
                editingFinish(teMain.text);
            }
        });
        syncTimer.start();
    }
}

import QtQuick

Item {

    required property string value

    property alias text: teMain.text
    property alias textDocument: teMain.textDocument

    property bool isEnabled: true
    property string prevValue: ''
    property string placeholder: ''

    signal editingFinish(string txt)
    signal textChange(string txt)


    Component.onCompleted: {
        prevValue = value
        startTimer()
    }

    id: flickableEdit

    Flickable {
         id: flick
         anchors.fill: parent
         clip: true

         function ensureVisible(r) {
             if (contentX >= r.x)
                 contentX = r.x;
             else if (contentX+width <= r.x+r.width)
                 contentX = r.x+r.width-width;

             if (contentY >= r.y)
                 contentY = r.y;
             else if (contentY+height <= r.y+r.height)
                 contentY = r.y+r.height-height;
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
             onEditingFinished: {
                 // editingFinish(teMain.text)
             }
             onTextChanged: {
                value = teMain.text
                textChange(teMain.text)

                if (!syncTimer.running) {
                   syncTimer.start()
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
        interval: 500;
        running: true;
        repeat: false
    }

    function startTimer() {
        syncTimer.triggered.connect(() => {
            if (prevValue !== teMain.text) {
                prevValue = teMain.text
                editingFinish(teMain.text)
            }
        })
        syncTimer.start()
    }
}

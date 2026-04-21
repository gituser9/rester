import QtQuick

// source
// https://gist.github.com/jonmcclung/bae669101d17b103e94790341301c129

/**
* @brief Android-like timed message text in a box that self-destroys when finished
* @note Adapted from https://gist.github.com/jonmcclung/bae669101d17b103e94790341301c129
* with fixes for memory leaks and errors.
*/
Rectangle {
    id: root

    /**
    * @brief Shows this Toast
    * @param {string} text Text to show
    * @param {real} duration Duration to show in milliseconds, defaults to 3000
    */
    function show(text, duration) {
        message.text = text;
        if (typeof duration !== "undefined") {
            time = Math.max(duration, 2 * fadeTime);
        } else {
            time = defaultTime;
        }
        animation.start();
    }

    // === PRIVATE ===
    readonly property real defaultTime: 3000
    property real time: defaultTime
    readonly property real fadeTime: 300
    property real margin: 10

    anchors {
        left: (parent != null) ? parent.left : undefined
        right: (parent != null) ? parent.right : undefined
        margins: margin
    }

    height: message.height + margin
    radius: margin
    opacity: 0
    color: "#222222"

    Text {
        id: message
        color: "white"
        wrapMode: Text.Wrap
        horizontalAlignment: Text.AlignHCenter
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: root.margin / 2
        }
    }

    SequentialAnimation on opacity {
        id: animation
        running: false

        NumberAnimation {
            to: .9
            duration: root.fadeTime
        }

        PauseAnimation {
            duration: root.time - 2 * root.fadeTime
        }

        NumberAnimation {
            to: 0
            duration: root.fadeTime
        }

        onRunningChanged: {
            if (!running) {
                if (typeof _toastManager !== "undefined" && _toastManager !== null) {
                    _toastManager.model.remove(index);
                }
            }
        }
    }
}

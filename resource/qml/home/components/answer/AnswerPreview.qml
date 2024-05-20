import QtQuick

import core.app 1.0


Item {

    required property string mimeType


    Component.onCompleted: {
        // image
        if (mimeType.startsWith("image")) {
            loader.sourceComponent = previewImg
        }

        // pdf

        // csv

        // html?
    }

    Loader {
        id: loader
        anchors.fill: parent
    }


    Component {
        id: previewImg

        Image {
            id: image
            // source: "data:image/png;base64," + Base64.encode(App.query.lastAnswer.body)
            source: "data:" + mimeType + ";base64," + Base64.encode(App.query.lastAnswer.body)

            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
        }
    }
}

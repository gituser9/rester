pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable

import QtQuick

import io.rester
import core.app 1.0

Item {
    id: previewView

    required property string mimeType

    Component.onCompleted: {
        // image
        if (mimeType.startsWith("image")) {
            loader.sourceComponent = previewImg;
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
            source: "data:" + previewView.mimeType + ";base64," + Base64.encode(App.query.lastAnswer.body)

            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
        }
    }
}

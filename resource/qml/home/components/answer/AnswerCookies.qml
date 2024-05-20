import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import core.app 1.0


Item {
    id: cookiePage
    anchors.fill: parent

    Component.onCompleted: {
        fillModel()
    }

    ListView {
        id: lvCookies
        anchors.fill: parent
        clip: true
        model: lmCookies
        delegate: Rectangle {

            required property string name
            required property string expires
            required property string maxAge
            required property string domain
            required property string path
            required property string samesite
            required property string value
            required property bool httpOnly
            required property bool secure

            id: cookieDelegate
            height: clCookie.height + 20
            width: parent.width

            ColumnLayout {
                id: clCookie
                width: parent.width

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30

                    Text {
                        Layout.fillWidth: true


                        text: cookieDelegate.name
                        font.pointSize: 14
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                    Button {

                        property string tooltipText: qsTr("Copy value")

                        id: copybtn
                        flat: true
                        icon.source: "/resource/images/copy.svg"
                        icon.width: 18
                        icon.height: 18
                        icon.color: 'black'
                        onClicked: {
                            teCopy.text = cookieDelegate.value
                            teCopy.selectAll()
                            teCopy.copy()
                            teCopy.clear()

                            copybtn.tooltipText = qsTr("Copied")
                        }

                        ToolTip.text: tooltipText
                        ToolTip.visible: hovered
                        ToolTip.toolTip.onVisibleChanged: {
                            if (!hovered) {
                                tooltipText = qsTr("Copy value")
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 20

                    visible: cookieDelegate.expires !== ""

                    Text {
                        Layout.minimumWidth: 100

                        text: 'Expires'
                        font.bold: true
                    }
                    TextEdit {
                        readOnly: true
                        selectByMouse: true
                        text: cookieDelegate.expires
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 20

                    visible: cookieDelegate.maxAge

                    Text {
                        Layout.minimumWidth: 100

                        text: 'Max-Age'
                        font.bold: true
                    }
                    TextEdit {
                        readOnly: true
                        selectByMouse: true
                        text: cookieDelegate.maxAge
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 20

                    Text {
                        Layout.minimumWidth: 100

                        text: 'HttpOnly'
                        font.bold: true
                    }
                    TextEdit {
                        readOnly: true
                        selectByMouse: true
                        text: cookieDelegate.httpOnly.toString()
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 20

                    visible: cookieDelegate.domain

                    Text {
                        Layout.minimumWidth: 100

                        text: 'Domain'
                        font.bold: true
                    }
                    TextEdit {
                        readOnly: true
                        selectByMouse: true
                        text: cookieDelegate.domain
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 20

                    visible: cookieDelegate.path

                    Text {
                        Layout.minimumWidth: 100

                        text: 'Path'
                        font.bold: true
                    }
                    TextEdit {
                        readOnly: true
                        selectByMouse: true
                        text: cookieDelegate.path
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 20

                    visible: cookieDelegate.samesite

                    Text {
                        Layout.minimumWidth: 100

                        text: 'SameSite'
                        font.bold: true
                    }
                    TextEdit {
                        readOnly: true
                        selectByMouse: true
                        text: cookieDelegate.samesite
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 20

                    Text {
                        Layout.minimumWidth: 100

                        text: 'Secure'
                        font.bold: true
                    }
                    TextEdit {
                        readOnly: true
                        selectByMouse: true
                        text: cookieDelegate.secure.toString()
                    }
                }
                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        Layout.alignment: Qt.AlignTop
                        Layout.minimumWidth: 100

                        text: 'Value'
                        font.bold: true
                    }
                    TextEdit {
                        Layout.fillWidth: true

                        id: teCookieValue
                        readOnly: true
                        selectByMouse: true
                        text: cookieDelegate.value
                        wrapMode: TextEdit.WrapAnywhere
                    }
                }
                MenuSeparator {
                    Layout.fillWidth: true

                    contentItem: Rectangle {
                        implicitWidth: parent.width
                        implicitHeight: 1
                        color: "#1E000000"
                    }
                }
            }
        }
    }


    TextEdit {
        id: teCopy
        visible: false
    }

    ListModel {
        id: lmCookies
    }


    Connections {
        target: App.query

        function onLastAnswerChanged() {
            cookiePage.fillModel()
        }

    }

    Connections {
        target: App

        function onQueryChanged() {
            cookiePage.fillModel()
        }
    }


    function fillModel() {
        lmCookies.clear()

        // if (!App.query?.lastAnswer) {
        //     return
        // }

        for (let cookie of App.query.lastAnswer.cookies) {
            let cookObj = {
                "name": cookie["name"] ?? "",
                "expires": cookie["expires"] ?? "",
                "maxAge": cookie["max-age"] ?? "",
                "httpOnly": cookie["httponly"] !== undefined,
                "secure": cookie["secure"] !== undefined,
                "samesite": cookie["samesite"] ?? "",
                "domain": cookie["domain"] ?? "",
                "path": cookie["path"] ?? "",
                "value": cookie.value ?? ""
            }

            lmCookies.append(cookObj)
        }
    }
}

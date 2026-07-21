pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable
pragma FunctionSignatureBehavior: Enforced

import QtCore
import QtQuick
import QtQuick.Controls.Imagine
import QtQuick.Layouts
import QtQuick.Dialogs

import io.rester

import "../../qml"
import "./components/answer"
import "../common/components/uikit"

Item {
    id: answerView

    property bool isBig: false
    property int currentIndex: -1
    property Constants consts: Constants {}

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: 5
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            Layout.topMargin: 8

            spacing: 8

            Rectangle {
                id: statusContainer
                Layout.preferredHeight: 40
                Layout.preferredWidth: 100
                color: answerView.getStatusColor(App.query?.lastAnswer?.status ?? 0)
                radius: 4

                Text {
                    id: txtStatus
                    anchors.centerIn: parent
                    color: "white"
                    font.pointSize: 12
                    font.weight: 700
                    text: App.query?.lastAnswer?.status ?? '0'
                }
            }
            Rectangle {
                Layout.preferredWidth: 100
                Layout.preferredHeight: 40

                color: "lightgrey"
                radius: 4

                Text {
                    id: txtSize
                    anchors.centerIn: parent
                    font.pointSize: 12
                    font.weight: 700
                    padding: 8
                    text: Util.getAnswerSizeString(App.query?.lastAnswer?.byteCount ?? 0)
                }
            }
            Rectangle {
                Layout.preferredHeight: 40
                Layout.preferredWidth: 100

                color: "lightgrey"
                radius: 4

                Text {
                    id: txtTime
                    anchors.centerIn: parent
                    font.pointSize: 12
                    font.weight: 700
                    padding: 8
                    text: answerView.getDurationString(App.query?.lastAnswer?.duration ?? 0)
                }
            }
            Item {
                Layout.fillWidth: true

                visible: answerView.isBig
            }
            RstButton {
                visible: answerView.isBig
                icon: "qrc:/qt/qml/io/rester/resource/images/download.svg"
                onClicked: {
                    folderDialog.open();
                }
            }
        }
        RstDivider {
            Layout.fillWidth: true
        }

        RstTabGroup {
            id: tabs
            texts: [qsTr("Body"), qsTr("Headers"), qsTr("Cookies")]
            onClicked: idx => {
                if (idx === 0) {
                    let size = Util.getAnswerSize(App.query?.lastAnswer?.byteCount ?? 0);

                    if (size.label === "Mb" && size.size > 1) {
                        loader.sourceComponent = bigBody;
                        return;
                    }
                }

                answerView.setSource(idx);
            }

            Layout.fillWidth: true
            Layout.rightMargin: 8
            Layout.leftMargin: 8
            Layout.preferredHeight: answerView.consts.bottomButtonHeight
        }
        Rectangle {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.rightMargin: 8

            Loader {
                id: loader
                anchors.fill: parent
                asynchronous: true
            }
        }
    }

    Connections {
        target: App.httpClient

        function onIsRequestWorkChanged(): void {
            if (App.httpClient.isRequestWork) {
                answerView.showLoader();

                return;
            }

            if (loaderTimer.running) {
                loaderTimer.stop();
            }

            let size = Util.getAnswerSize(App.query.lastAnswer.byteCount);

            if (size.label === "Mb" && size.size > 1) {
                loader.sourceComponent = bigBody;
                isBig = true;
            } else {
                answerView.setSource(currentIndex);
                isBig = false;
            }
        }

        function onHttpError(errorString: string): void {
            if (loaderTimer.running) {
                loaderTimer.stop();
            }

            let path = "./components/answer/AnswerError.qml";
            loader.setSource(path, {
                "errString": errorString
            });
        }
    }

    Timer {
        id: loaderTimer
        interval: 300
        running: true
        repeat: false
    }

    Component {
        id: bigBody

        AnswerBigBody {
            onShow: {
                let path = "./components/answer/AnswerBody.qml";
                loader.setSource(path);
            }
            onDownload: {
                folderDialog.open();
            }
            onClear: {
                App.query.lastAnswer.body = '';
            }
        }
    }

    FolderDialog {
        id: folderDialog
        currentFolder: StandardPaths.standardLocations(StandardPaths.HomeLocation)[0]
        onAccepted: {
            let path = selectedFolder.toString().replace("file://", "");
            App.routesModel.downloadBigAnswer(path, App.query);
        }
    }

    function getDurationString(ms: int): string {
        if (ms < 1000) {
            return ms + ' ms';
        }

        let secs = ms / 1000;
        if (secs < 60) {
            return Util.round2digits(secs) + ' sec';
        }

        let mins = secs / 60;
        if (mins < 60) {
            return Util.round2digits(mins) + ' min';
        }

        let hours = mins / 60;

        return Util.round2digits(hours) + ' h';
    }

    function getStatusColor(statusCode: int): string {
        if (statusCode >= 200 && statusCode <= 299) {
            return '#73965b';
        }

        if (statusCode >= 300 && statusCode <= 399) {
            return '#e5da25';
        }

        if (statusCode >= 400 && statusCode <= 499) {
            return '#d19a66';
        }

        if (statusCode >= 500 && statusCode <= 599) {
            return '#d86a6f';
        }

        return 'lightgrey';
    }

    function setSource(idx: int): void {
        currentIndex = idx;
        let path = "./components/answer/";

        switch (idx) {
        case 0:
            path += "AnswerBody.qml";
            break;
        case 1:
            path += "AnswerHeaders.qml";
            break;
        case 2:
            path += "AnswerCookies.qml";
            break;
        default:
            path += "AnswerBody.qml";
        }

        loader.setSource(path);
    }

    function showLoader(): void {
        loaderTimer.triggered.connect(() => {
            if (App.httpClient.isRequestWork) {
                let path = "./components/answer/AnswerWait.qml";
                loader.setSource(path);
            }
        });
        loaderTimer.start();
    }
}

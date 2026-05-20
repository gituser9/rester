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

Item {
    id: answerView

    property bool isBig: false
    property int currentIndex: 0

    Component.onCompleted: {
        answerView.setSource(0);
    }

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
                color: answerView.getStatusColor(App.grpcQuery)
                radius: 4

                Layout.preferredHeight: 40
                Layout.preferredWidth: 100

                Text {
                    id: txtStatus
                    anchors.centerIn: parent
                    color: "white"
                    font.pointSize: 12
                    font.weight: 700
                    text: App.grpcQuery?.lastAnswer?.status ?? '0'
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
                    text: Util.getAnswerSizeString(App.grpcQuery.lastAnswer.byteCount)
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
                    text: answerView.getDurationString(App.grpcQuery.lastAnswer.duration)
                }
            }
            Item {
                Layout.fillWidth: true

                visible: answerView.isBig
            }
            Button {
                visible: answerView.isBig
                flat: true
                icon.source: "qrc:/qt/qml/io/rester/resource/images/download.svg"
                icon.width: 22
                icon.height: 22
                icon.color: 'black'
                onClicked: {
                    folderDialog.open();
                }
            }
        }
        MenuSeparator {
            Layout.preferredWidth: parent.width

            contentItem: Rectangle {
                color: "#1E000000"
                implicitHeight: 1
                implicitWidth: parent.width
            }
        }

        ButtonGroup {
            id: tabGroup
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.rightMargin: 8
            Layout.leftMargin: 8

            Button {
                Layout.fillWidth: true
                Layout.preferredWidth: answerView.width / 2

                checkable: true
                checked: answerView.currentIndex == 0
                flat: true
                text: qsTr("Body")
                onClicked: {
                    let size = Util.getAnswerSize(App.grpcQuery.lastAnswer.byteCount);

                    if (size.label === "Mb" && size.size > 1) {
                        loader.sourceComponent = bigBody;
                    } else {
                        answerView.setSource(0);
                    }
                }

                ButtonGroup.group: tabGroup
            }
            Button {
                Layout.fillWidth: true
                Layout.preferredWidth: answerView.width / 2

                checkable: true
                checked: answerView.currentIndex == 1
                flat: true
                text: qsTr("Meta")
                onClicked: {
                    answerView.setSource(1);
                }

                ButtonGroup.group: tabGroup
            }
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
        target: App.grpcQuery

        function onLastAnswerChanged() {
            statusContainer.color = answerView.getStatusColor(App.grpcQuery);
            txtSize.text = Util.getAnswerSizeString(App.grpcQuery.lastAnswer?.byteCount ?? 0);
        }
    }

    Connections {
        target: App.grpcClient

        function onIsRequestWorkChanged(): void {
            if (App.grpcClient.isRequestWork) {
                answerView.showLoader();

                return;
            }

            if (loaderTimer.running) {
                loaderTimer.stop();
            }

            let size = Util.getAnswerSize(App.grpcQuery.lastAnswer.byteCount);

            if (size.label === "Mb" && size.size > 1) {
                loader.sourceComponent = bigBody;
                isBig = true;
            } else {
                answerView.setSource(currentIndex);
                isBig = false;
            }
        }

        function onRequestError(errorString: string): void {
            if (loaderTimer.running) {
                loaderTimer.stop();
            }

            let path = "./components/answer/AnswerError.qml";
            loader.setSource(path, {
                "errString": errorString
            });

            txtStatus.text = '0';
            txtTime.text = '0';
            txtSize.text = '0';
        }
    }

    Timer {
        id: loaderTimer
        interval: 500
        running: true
        repeat: false
    }

    Component {
        id: bigBody

        AnswerBigBody {
            onShow: {
                let path = "./components/answer/GrpcAnswerBody.qml";
                loader.setSource(path);
            }
            onDownload: {
                folderDialog.open();
            }
            onClear: {
                App.grpcQuery.lastAnswer.body = '';
            }
        }
    }

    FolderDialog {
        id: folderDialog
        currentFolder: StandardPaths.standardLocations(StandardPaths.HomeLocation)[0]
        onAccepted: {
            let path = selectedFolder.toString().replace("file://", "");
            App.routesModel.downloadBigAnswer(path, App.grpcQuery);
        }
    }

    function getDurationString(ms: int): string { // todo: from C++
        if (ms < 1000) {
            return ms + ' ms';
        }

        if ((ms / 1000) < 60) {
            let secs = (ms / 1000);

            return Util.round2digits(secs) + ' sec';
        }

        return ((ms / 1000) / 60) + 'm';
    }

    function getStatusColor(query: GrpcQuery): string {
        if (!query || !query.lastAnswer) {
            return 'lightgrey';
        }

        let statusCode = query.lastAnswer.status;

        if (statusCode === 0) {
            return '#73965b';
        }

        if (statusCode >= 1 && statusCode <= 11 || statusCode === 16) {
            return '#d19a66';
        }

        if (statusCode === 4) {
            return '#e5da25';
        }

        return '#d86a6f'; // Server errors
    }

    function setSource(idx: int): void {
        currentIndex = idx;
        let path = "./components/answer/";

        switch (idx) {
        case 0:
            path += "GrpcAnswerBody.qml";
            break;
        case 1:
            path += "AnswerHeaders.qml";
            break;
        default:
            path += "GrpcAnswerBody.qml";
        }

        loader.setSource(path);
    }

    function showLoader(): void {
        loaderTimer.triggered.connect(() => {
            if (App.grpcClient.isRequestWork) {
                let path = "./components/answer/AnswerWait.qml";
                loader.setSource(path);
            }
        });
        loaderTimer.start();
    }
}

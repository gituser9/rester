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
                Layout.preferredHeight: 40
                Layout.preferredWidth: 100
                color: answerView.getStatusColor(App.graphqlQuery)
                radius: 4

                Text {
                    id: txtStatus
                    anchors.centerIn: parent
                    color: "white"
                    font.pointSize: 12
                    font.weight: 700
                    text: App.graphqlQuery?.lastAnswer?.status ?? '0'
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
                    text: Util.getAnswerSizeString(App.graphqlQuery?.lastAnswer?.byteCount ?? 0)
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
                    text: App.graphqlQuery && App.graphqlQuery?.lastAnswer ? answerView.getDurationString(App.graphqlQuery.lastAnswer.duration) : "0 ms"
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
                Layout.preferredWidth: answerView.width / 3

                checkable: true
                checked: answerView.currentIndex == 0
                flat: true
                text: qsTr("Body")
                onClicked: {
                    let size = Util.getAnswerSize(App.graphqlQuery.lastAnswer.byteCount);

                    if (size.label === "Mb" && size.size > 1) {
                        loader.sourceComponent = bigBody;
                    } else {
                        setSource(0);
                    }
                }

                ButtonGroup.group: tabGroup
            }
            Button {
                Layout.fillWidth: true
                Layout.preferredWidth: answerView.width / 3

                checkable: true
                checked: answerView.currentIndex == 1
                flat: true
                text: qsTr("Headers")
                onClicked: {
                    answerView.setSource(1);
                }

                ButtonGroup.group: tabGroup
            }
            Button {
                Layout.fillWidth: true
                Layout.preferredWidth: answerView.width / 3

                checkable: true
                checked: answerView.currentIndex == 2
                flat: true
                text: qsTr("Cookies")
                onClicked: {
                    answerView.setSource(2);
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
        target: App.graphqlQuery

        function onLastAnswerChanged() {
            statusContainer.color = answerView.getStatusColor(App.graphqlQuery);
            txtSize.text = Util.getAnswerSizeString(App.graphqlQuery.lastAnswer?.byteCount ?? 0);
        }
    }

    Connections {
        target: App.graphqlClient

        function onIsRequestWorkChanged(): void {
            if (App.graphqlClient.isRequestWork) {
                answerView.showLoader();

                return;
            }

            if (loaderTimer.running) {
                loaderTimer.stop();
            }

            let size = Util.getAnswerSize(App.graphqlQuery.lastAnswer.byteCount);

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
        interval: 500
        running: true
        repeat: false
    }

    Component {
        id: bigBody

        AnswerBigBody {
            onShow: {
                let path = "./components/answer/GraphqlAnswerBody.qml";
                loader.setSource(path);
            }
            onDownload: {
                folderDialog.open();
            }
            onClear: {
                App.graphqlQuery.lastAnswer.body = '';
            }
        }
    }

    FolderDialog {
        id: folderDialog
        currentFolder: StandardPaths.standardLocations(StandardPaths.HomeLocation)[0]
        onAccepted: {
            let path = selectedFolder.toString().replace("file://", "");
            App.routesModel.downloadBigAnswer(path, App.graphqlQuery);
        }
    }

    function getDurationString(ms: int): string {
        if (ms < 1000) {
            return ms + ' ms';
        }

        if ((ms / 1000) < 60) {
            let secs = (ms / 1000);

            return Util.round2digits(secs) + ' sec';
        }

        return ((ms / 1000) / 60) + 'm';
    }

    function getStatusColor(query: var): string { // TODO: type
        if (!query || !query.lastAnswer) {
            return 'lightgrey';
        }

        let statusCode = query.lastAnswer.status;

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
            path += "GraphqlAnswerBody.qml";
            break;
        case 1:
            path += "GraphqlAnswerHeaders.qml";
            break;
        case 2:
            path += "GraphqlAnswerCookies.qml";
            break;
        default:
            path += "GraphqlAnswerBody.qml";
        }

        loader.setSource(path);
    }

    function showLoader(): void {
        loaderTimer.triggered.connect(() => {
            if (App.graphqlClient.isRequestWork) {
                let path = "./components/answer/AnswerWait.qml";
                loader.setSource(path);
            }
        });
        loaderTimer.start();
    }
}

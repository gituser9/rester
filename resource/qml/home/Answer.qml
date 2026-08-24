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
    id: root

    readonly property Constants consts: Constants {}
    property int currentIndex: -1
    property int queryType: RstEnums.QueryType.GET
    property int viewState: Answer.ViewState.Reg
    property HttpAnswer answer
    property string lastError: ''

    Component.onCompleted: {
        if (App.query) {
            root.queryType = App.query.queryType;
            root.answer = App.query.lastAnswer;
        }

        if (App.grpcQuery) {
            root.queryType = RstEnums.QueryType.GRPC;
            root.answer = App.grpcQuery.lastAnswer;
        }

        if (App.graphqlQuery) {
            root.queryType = RstEnums.QueryType.GRAPHQL;
            root.answer = App.graphqlQuery.lastAnswer;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: root.consts.space

        RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: 5
            Layout.leftMargin: root.consts.space
            Layout.rightMargin: root.consts.space
            Layout.topMargin: root.consts.space

            spacing: root.consts.space

            Rectangle {
                id: statusContainer
                Layout.preferredHeight: 40
                Layout.preferredWidth: 100
                color: root.getStatusColor(root.answer?.status ?? 0)
                radius: 4

                Text {
                    id: txtStatus
                    anchors.centerIn: parent
                    color: "white"
                    font.pointSize: 12
                    font.weight: 700
                    text: root.answer?.status ?? '0'
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
                    padding: root.consts.space
                    text: Util.getAnswerSizeString(root.answer?.byteCount ?? 0)
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
                    padding: root.consts.space
                    text: root.getDurationString(root.answer?.duration ?? 0)
                }
            }
            Item {
                Layout.fillWidth: true

                visible: root.viewState === Answer.ViewState.Big
            }
            RstButton {
                visible: root.viewState === Answer.ViewState.Big
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
            texts: root.getTabs(root.queryType)
            onClicked: idx => {
                if (idx === 0) {
                    let size = Util.getAnswerSize(root.answer?.byteCount ?? 0);

                    if (size.label === "Mb" && size.size > 1) {
                        loader.sourceComponent = bigBodyComponent;
                        root.viewState = Answer.ViewState.Big;
                        return;
                    }
                }
            }

            Layout.fillWidth: true
            Layout.rightMargin: root.consts.space
            Layout.leftMargin: root.consts.space
            Layout.preferredHeight: root.consts.bottomButtonHeight
        }
        Rectangle {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.leftMargin: root.consts.space
            Layout.rightMargin: root.consts.space

            Loader {
                id: loader
                anchors.fill: parent
                asynchronous: true
                sourceComponent: {
                    switch (tabs.currentIdx) {
                    case 0:
                        return smallQueryComponent;
                    case 1:
                        return headerListComponent;
                    case 2:
                        return cookieListComponent;
                    default:
                        return smallQueryComponent;
                    }
                }
            }
        }
    }

    // Types
    Timer {
        id: loaderTimer
        interval: 300
        running: true
        repeat: false
    }

    enum ViewState {
        Reg,
        Big,
        Wait,
        Error
    }

    // Components
    Component {
        id: bigBodyComponent

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
    Component {
        id: smallQueryComponent

        Loader {
            anchors.fill: parent
            asynchronous: true
            sourceComponent: {
                switch (root.viewState) {
                case Answer.ViewState.Reg:
                    return regAnswerComponent;
                case Answer.ViewState.Error:
                    return errorComponent;
                case Answer.ViewState.Wait:
                    return waitComponent;
                case Answer.ViewState.Big:
                    return bigBodyComponent;
                default:
                    return regAnswerComponent;
                }
            }
        }
    }
    Component {
        id: headerListComponent

        AnswerHeaders {
            headers: root.answer?.headers
        }
    }
    Component {
        id: cookieListComponent

        AnswerCookies {
            cookies: root.answer?.cookies
        }
    }

    Component {
        id: regAnswerComponent

        AnswerBody {
            answer: root.answer
            queryType: root.queryType
        }
    }
    Component {
        id: waitComponent

        AnswerWait {}
    }
    Component {
        id: errorComponent

        AnswerError {
            id: answErr
            errString: root.lastError
        }
    }

    FolderDialog {
        id: folderDialog
        currentFolder: StandardPaths.standardLocations(StandardPaths.HomeLocation)[0]
        onAccepted: {
            let path = selectedFolder.toString().replace("file://", "");
            // App.routesModel.downloadBigAnswer(path, App.query);
        }
    }

    // Connections
    Connections {
        target: App

        function onQueryChanged() {
            root.queryType = App.query.queryType;
            root.setClientAnswer(false, App.query.lastAnswer);
        }

        function onGrpcQueryChanged() {
            root.queryType = RstEnums.QueryType.GRPC;
            root.setClientAnswer(false, App.grpcQuery.lastAnswer);
        }

        function onGraphqlQueryChanged() {
            root.queryType = RstEnums.QueryType.GRAPHQL;
            root.setClientAnswer(false, App.graphqlQuery.lastAnswer);
        }
    }
    Connections {
        target: App.httpClient

        function onIsRequestWorkChanged(): void {
            root.setClientAnswer(App.httpClient.isRequestWork, App.query.lastAnswer);
        }

        function onHttpError(errorString: string): void {
            root.setError(errorString);
        }
    }
    Connections {
        target: App.graphqlClient

        function onIsRequestWorkChanged(): void {
            root.setClientAnswer(App.graphqlClient.isRequestWork, App.graphqlQuery.lastAnswer);
        }

        function onHttpError(errorString: string): void {
            root.setError(errorString);
        }
    }
    Connections {
        target: App.grpcClient

        function onIsRequestWorkChanged(): void {
            root.setClientAnswer(App.grpcClient.isRequestWork, App.grpcQuery.lastAnswer);
        }

        function onHttpError(errorString: string): void {
            root.setError(errorString);
        }
    }

    // Functions
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
        if (App.grpcQuery) {
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

    function showLoader(): void {
        loaderTimer.triggered.connect(() => {
            root.viewState = Answer.ViewState.Wait;
        });
        loaderTimer.start();
    }

    function setError(errorString: string): void {
        if (loaderTimer.running) {
            loaderTimer.stop();
        }

        root.viewState = Answer.ViewState.Error;
        root.lastError = errorString;
    }

    function setClientAnswer(isWork: bool, answ: HttpAnswer): void {
        if (!loaderTimer.running) {
            root.showLoader();
        }

        if (isWork) {
            return;
        }

        root.answer = answ;
        root.lastError = '';

        if (loaderTimer.running) {
            loaderTimer.stop();
        }

        let size = Util.getAnswerSize(answ?.byteCount ?? 0);

        if (size.label === "Mb" && size.size > 1) {
            loader.sourceComponent = bigBodyComponent;
            root.viewState = Answer.ViewState.Big;

            return;
        }

        if (root.viewState !== Answer.ViewState.Reg) {
            root.viewState = Answer.ViewState.Reg;
        }
    }

    function getTabs(queryType: int): list<string> {
        if (queryType === RstEnums.QueryType.GRPC) {
            return [qsTr("Body"), qsTr("Meta")];
        }

        return [qsTr("Body"), qsTr("Headers"), qsTr("Cookies")];
    }
}

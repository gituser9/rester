pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable
pragma FunctionSignatureBehavior: Enforced

import QtQuick
import QtQuick.Controls.Imagine
import QtQuick.Layouts

import io.rester

import "../../modal"
import "../../../common/components"
import "../../../common/components/uikit"

Rectangle {
    id: root

    required property var params
    property string fullUrl: ""

    signal changeParam(int index)

    onParamsChanged: {
        root.fillUrl();
    }

    Component.onCompleted: {
        root.fillData();
    }

    ColumnLayout {
        anchors.fill: parent

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 16
            Layout.bottomMargin: 8

            Text {
                text: qsTr("URL Preview")

                Layout.fillWidth: true
            }
            Item {
                Layout.fillWidth: true
            }
            RstButton {
                size: RstButton.ButtonSize.Small
                text: qsTr("Import from cURL")
                icon: "qrc:/qt/qml/io/rester/resource/images/upload.svg"
                onClicked: {
                    mdlImportQuery.open();
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true

            TextEdit {
                id: tfFullUrl
                text: root.fullUrl
                readOnly: true
                font.family: "Monospace"
                wrapMode: Text.Wrap

                Layout.fillWidth: true

                Component.onCompleted: {
                    urlHilighter.setDocument(tfFullUrl.textDocument);
                }
            }
            RstButton {
                id: copybtn
                icon: "qrc:/qt/qml/io/rester/resource/images/copy.svg"
                tooltip: qsTr("Copy value")
                tooltipAfter: qsTr("Copied")
                onClicked: {
                    teCopy.text = tfFullUrl.text;
                    teCopy.selectAll();
                    teCopy.copy();
                    teCopy.clear();
                }
            }
        }
        Item {
            Layout.preferredHeight: 16
        }
        RowLayout {
            Text {
                text: qsTr("Query Parameters")

                Layout.fillWidth: true
            }
            Item {
                Layout.fillWidth: true
            }
            RstButton {
                visible: App.query.url.trim().length > 0 && App.query.url.includes("?")
                size: RstButton.ButtonSize.Small
                text: qsTr("From URL")
                icon: "qrc:/qt/qml/io/rester/resource/images/download.svg"
                onClicked: {
                    App.query.paramsFromUrl();
                }
            }
        }

        QueryParamList {
            params: root.params
            onAddParam: {
                App.query.addParam('', '');
            }
            onRemoveParam: idx => {
                App.query.removeParam(idx);
            }
            onSetParam: (idx, name, val, enabled) => {
                App.query.setParam(idx, name, val, enabled);
            }

            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }

    // Types
    UrlHighlighter {
        id: urlHilighter
    }

    TextEdit {
        id: teCopy
        visible: false
    }

    Connections {
        target: App

        function onQueryChanged(): void {
            root.fullUrl = "";

            root.fillData();
        }
    }

    Connections {
        target: App.query

        function onUrlChanged(): void {
            root.rebuildUrl();
        }
    }

    Connections {
        target: App.workspace

        function onEnvChanged(): void {
            root.rebuildUrl();
        }
    }

    InputDialog {
        id: mdlImportQuery
        anchors.centerIn: parent
        title: qsTr("Import Request")
        placeholder: qsTr("cUrl string")
        onOk: cUrlString => {
            if (!cUrlString) {
                return;
            }

            App.setFromCurl(cUrlString);
        }
    }

    function fillData(): void {
        // url
        let newUrl = App.query.url;
        let vars = App.workspace.variables[App.workspace.env];

        if (vars) {
            newUrl = Util.fillVars(App.query.url, vars);
        }

        if (Object.keys(App.query.params).length != 0) {
            newUrl += "?";
        }

        // params
        for (let p of App.query.params) {
            let pValue = p.value;

            if (vars) {
                pValue = Util.fillVars(p.value, vars);
            }

            newUrl += p.name + '=' + pValue + '&';
        }

        // set full url
        if (newUrl.slice(-1) === '&') {
            root.fullUrl = newUrl.substring(0, newUrl.length - 1);
        } else {
            root.fullUrl = newUrl;
        }
    }

    function fillUrl(): void {
        let url = root.fullUrl;
        let urlArr = url.split("?");
        let vars = [];

        if (App.workspace.env !== '') {
            vars = App.workspace.variables[App.workspace.env];
            urlArr[0] = Util.fillVars(urlArr[0], vars);
        }

        url = urlArr[0] + '?';

        for (let param of App.query.params) {
            if (!param.isEnabled) {
                continue;
            }

            let pValue = param.value;

            if (vars) {
                pValue = Util.fillVars(param.value, vars);
            }

            url += param.name + '=' + pValue + '&';
        }

        if (url.slice(-1) === '&') {
            root.fullUrl = url.substring(0, url.length - 1);
        } else {
            root.fullUrl = url;
        }
    }

    function rebuildUrl(): void {
        // url
        let vars = App.workspace.variables[App.workspace.env];
        let newUrl = Util.fillVars(App.query.url, vars);

        if (Object.keys(App.query.params).length != 0) {
            newUrl += "?";
        }

        // params
        for (let p of App.query.params) {
            if (!p.isEnabled) {
                continue;
            }

            let pValue = p.value;

            if (vars) {
                pValue = Util.fillVars(p.value, vars);
            }

            newUrl += p.name + '=' + pValue + '&';
        }

        // set full url
        if (newUrl.slice(-1) === '&') {
            root.fullUrl = newUrl.substring(0, newUrl.length - 1);
        } else {
            root.fullUrl = newUrl;
        }
    }
}

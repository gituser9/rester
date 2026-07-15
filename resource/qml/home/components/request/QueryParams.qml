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
    id: winParam
    property string fullUrl: ""

    signal changeParam(int index)

    Component.onCompleted: {
        winParam.fillData();
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
                width: parent.width
                text: fullUrl
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
                size: RstButton.ButtonSize.Small
                text: qsTr("From URL")
                icon: "qrc:/qt/qml/io/rester/resource/images/download.svg"
                onClicked: {
                    winParam.fromUrl();
                }
            }
        }

        RstPropertyList {
            id: lstProps
            propertyModel: paramModel

            Layout.fillWidth: true
            Layout.fillHeight: true

            onCheckBoxClicked: idx => {
                winParam.fillUrl();
                winParam.changeParam(idx);
            }
            onNameChanged: (idx, value) => {
                let param = paramModel.get(idx);
                App.query.setParam(idx, value, param.value, param.isEnabled);
                winParam.fillUrl();
            }
            onValueChanged: (idx, value) => {
                let param = paramModel.get(idx);
                App.query.setParam(idx, param.name, value, param.isEnabled);
                winParam.fillUrl();
            }
            onRemoved: idx => {
                App.query.removeParam(idx);
                winParam.fillUrl();
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignRight | Qt.AlignBottom
            Layout.bottomMargin: 8

            spacing: 8

            RstButton {
                visible: paramModel.count > 0
                text: qsTr("Clear")
                icon: "qrc:/qt/qml/io/rester/resource/images/close.svg"
                onClicked: {
                    paramModel.clear();
                    App.query.params = [];
                }
            }
            Item {
                Layout.fillWidth: true
            }
            RstButton {
                text: qsTr("Add")
                icon: "qrc:/qt/qml/io/rester/resource/images/add.svg"
                onClicked: {
                    paramModel.append({
                        "name": '',
                        "value": '',
                        "isEnabled": true
                    });
                    App.query.addParam('', '');
                }
            }
        }

        ListModel {
            id: paramModel
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

    Timer {
        id: syncTimer
        interval: 500
        running: true
        repeat: false
    }

    Connections {
        target: App

        function onQueryChanged(): void {
            paramModel.clear();
            winParam.fullUrl = "";

            winParam.fillData();
        }
    }

    Connections {
        target: winParam

        function onChangeParam(idx: int): void {
            winParam.sync(idx);
        }
    }

    Connections {
        target: App.query

        function onUrlChanged(): void {
            winParam.rebuildUrl();
        }
    }

    Connections {
        target: App.workspace

        function onEnvChanged(): void {
            winParam.rebuildUrl();
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

    function sync(idx: int): void {
        syncTimer.triggered.connect(function () {
            let param = paramModel.get(idx);

            App.query.setParam(idx, param.name, param.value, param.isEnabled);
        });
        syncTimer.start();
    }

    function fillData(): void {
        // url
        let newUrl = App.query.url;
        let vars = App.workspace.variables[App.workspace.env];

        if (vars) {
            for (let varr of vars) {
                newUrl = winParam.replaceVariables(newUrl, varr);
            }
        }

        if (Object.keys(App.query.params).length != 0) {
            newUrl += "?";
        }

        // params
        paramModel.clear();

        for (let p of App.query.params) {
            paramModel.append({
                "name": p.name,
                "value": p.value,
                "isEnabled": p.isEnabled
            });

            let pValue = p.value;

            if (vars) {
                for (let varr of vars) {
                    pValue = winParam.replaceVariables(pValue, varr);
                }
            }

            newUrl += p.name + '=' + pValue + '&';
        }

        // set full url
        if (newUrl.slice(-1) === '&') {
            winParam.fullUrl = newUrl.substring(0, newUrl.length - 1);
        } else {
            winParam.fullUrl = newUrl;
        }
    }

    function fillUrl(): void {
        let url = winParam.fullUrl;
        let urlArr = url.split("?");

        let vars = [];

        if (App.workspace.env !== '') {
            vars = App.workspace.variables[App.workspace.env];

            for (let varr of vars) {
                urlArr[0] = winParam.replaceVariables(urlArr[0], varr);
            }
        }

        url = urlArr[0] + '?';

        for (let i = 0; i < paramModel.count; ++i) {
            const param = paramModel.get(i);

            if (!param.isEnabled) {
                continue;
            }

            let pValue = param.value;

            if (vars) {
                for (let varr of vars) {
                    pValue = winParam.replaceVariables(pValue, varr);
                }
            }

            url += param.name + '=' + pValue + '&';
        }

        if (url.slice(-1) === '&') {
            winParam.fullUrl = url.substring(0, url.length - 1);
        } else {
            winParam.fullUrl = url;
        }
    }

    function fromUrl(): void {
        if (App.query.url === '') {
            return;
        }

        // get all params
        let url = App.query.url;
        const paramArr = url.slice(url.indexOf('?') + 1).split('&');
        const params = {};
        paramArr.map(param => {
            const arr = param.split('=');
            params[arr[0]] = decodeURIComponent(arr[1]);
        });

        if (params.length <= 1) {
            return;
        }

        // get url without params
        let urlArr = App.query.url.split('?');
        let route = urlArr[0];

        // fill model from params
        paramModel.clear();

        for (let key in params) {
            paramModel.append({
                "name": key,
                "value": params[key],
                "isEnabled": true
            });
            App.query.addParam(key, params[key]);
        }

        // set new data in query objecrt
        App.query.url = route;

        // set full url preview
        winParam.fillUrl();
    }

    // TODO: type
    function replaceVariables(inputString: string, varr: var): string {
        let regex = new RegExp(`{{\s*(${varr.name})\s*}}`);
        let replacedString = inputString.replace(regex, varr.value);

        return replacedString;
    }

    function rebuildUrl(): void {
        // url
        let newUrl = App.query.url;
        let vars = App.workspace.variables[App.workspace.env];

        if (vars) {
            for (let varr of vars) {
                newUrl = winParam.replaceVariables(newUrl, varr);
            }
        }

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
                for (let varr of vars) {
                    pValue = winParam.replaceVariables(pValue, varr);
                }
            }

            // newUrl += p.name + '=' + p.value + '&';
            newUrl += p.name + '=' + pValue + '&';
        }

        // set full url
        if (newUrl.slice(-1) === '&') {
            winParam.fullUrl = newUrl.substring(0, newUrl.length - 1);
        } else {
            winParam.fullUrl = newUrl;
        }
    }
}

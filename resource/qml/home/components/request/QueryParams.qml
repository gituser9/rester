pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable
pragma FunctionSignatureBehavior: Enforced

import QtQuick
import QtQuick.Controls.Imagine
import QtQuick.Layouts

import io.rester

import "../../modal"
import "../../../common/components"

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
                width: parent.width
                text: qsTr("URL Preview")
            }
            Item {
                Layout.fillWidth: true
            }
            Button {
                text: qsTr("Import from cURL")
                flat: true
                icon.source: "qrc:/qt/qml/io/rester/resource/images/upload.svg"
                icon.width: 18
                icon.height: 18
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
            Button {
                id: copybtn
                flat: true
                icon.source: "qrc:/qt/qml/io/rester/resource/images/copy.svg"
                icon.width: 22
                icon.height: 22
                icon.color: 'black'
                onClicked: {
                    teCopy.text = tfFullUrl.text;
                    teCopy.selectAll();
                    teCopy.copy();
                    teCopy.clear();

                    copybtn.tooltipText = qsTr("Copied");
                }

                property string tooltipText: qsTr("Copy value")

                ToolTip.text: tooltipText
                ToolTip.visible: hovered
                ToolTip.toolTip.onVisibleChanged: {
                    if (!hovered) {
                        tooltipText = qsTr("Copy value");
                    }
                }
            }
        }

        Item {
            height: 16
        }
        RowLayout {
            Text {
                width: parent.width
                text: qsTr("Query Parameters")
            }
            Item {
                Layout.fillWidth: true
            }
            Button {
                flat: true
                text: qsTr("From URL")
                icon.source: "qrc:/qt/qml/io/rester/resource/images/download.svg"
                icon.width: 18
                icon.height: 18
                onClicked: {
                    winParam.fromUrl();
                }
            }
        }

        ListView {
            id: paramList
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: paramModel
            clip: true
            delegate: Rectangle {
                id: paramDelegate
                height: 50
                width: winParam.width

                required property bool isEnabled
                required property int index
                required property string name
                required property string value

                VarSyntaxHighlighter {
                    id: varHighlighter
                }

                RowLayout {
                    spacing: 8
                    anchors.fill: parent

                    CheckBox {
                        id: cbEnabled
                        checked: paramDelegate.isEnabled
                        onClicked: {
                            paramModel.setProperty(paramDelegate.index, "isEnabled", cbEnabled.checkState === Qt.Checked);
                            winParam.fillUrl();
                            winParam.changeParam(paramDelegate.index);

                            varHighlighter.enabled = cbEnabled.checked;
                        }
                    }
                    Column {
                        Layout.fillWidth: true

                        FlickableEdit {
                            id: paramName
                            isEnabled: cbEnabled.checkState === Qt.Checked
                            width: paramList.width / 3
                            height: 20
                            value: paramDelegate.name
                            onEditingFinish: txt => {
                                let param = paramModel.get(paramDelegate.index);

                                App.query.setParam(paramDelegate.index, param.name, param.value, param.isEnabled);
                            }
                            onTextChange: txt => {
                                paramModel.setProperty(paramDelegate.index, "name", txt);
                                winParam.fillUrl();
                            }
                        }
                        MenuSeparator {
                            width: parent.width
                            contentItem: Rectangle {
                                implicitWidth: parent.width
                                implicitHeight: 1
                                color: "#1E000000"
                            }
                        }
                    }
                    Column {
                        Layout.fillWidth: true
                        Layout.leftMargin: 16

                        FlickableEdit {
                            id: paramValue
                            isEnabled: cbEnabled.checkState === Qt.Checked
                            width: paramList.width / 3
                            height: 20
                            value: paramDelegate.value
                            onEditingFinish: txt => {
                                let param = paramModel.get(paramDelegate.index);

                                App.query.setParam(paramDelegate.index, param.name, param.value, param.isEnabled);
                            }
                            onTextChange: txt => {
                                paramModel.setProperty(paramDelegate.index, "value", txt);
                                winParam.fillUrl();
                            }

                            Component.onCompleted: {
                                varHighlighter.setDocument(paramValue.textDocument);
                                varHighlighter.enabled = cbEnabled.checked;
                            }
                        }
                        MenuSeparator {
                            width: parent.width
                            contentItem: Rectangle {
                                implicitWidth: parent.width
                                implicitHeight: 1
                                color: "#1E000000"
                            }
                        }
                    }
                    Button {
                        flat: true
                        icon.source: "qrc:/qt/qml/io/rester/resource/images/close.svg"
                        icon.width: 18
                        icon.height: 18
                        icon.color: 'black'
                        onClicked: {
                            App.query.removeParam(index);
                            paramModel.remove(index);

                            winParam.fillUrl();
                        }
                    }
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignRight | Qt.AlignBottom
            Layout.bottomMargin: 8

            spacing: 8

            Button {
                visible: paramModel.count > 0
                text: qsTr("Clear")
                flat: true
                icon.source: "qrc:/qt/qml/io/rester/resource/images/close.svg"
                icon.width: 22
                icon.height: 22
                icon.color: 'black'
                onClicked: {
                    paramModel.clear();
                    App.query.params = [];
                }
            }
            Item {
                Layout.fillWidth: true
            }
            Button {
                text: qsTr("Add")
                flat: true
                icon.source: "qrc:/qt/qml/io/rester/resource/images/add.svg"
                icon.width: 22
                icon.height: 22
                icon.color: 'black'
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

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import core.app 1.0

import '../../modal'
import '../../../common/components'


Rectangle {
    property string fullUrl: ""

    signal changeParam(int index)

    Component.onCompleted: {
        fillData()
    }

    id: winParam

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
                icon.source: "/resource/images/upload.svg"
                icon.width: 18
                icon.height: 18
                onClicked: {
                    mdlImportQuery.open()
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true

            TextField {
                Layout.fillWidth: true

                id: tfFullUrl
                width: parent.width
                readOnly: true
                text: fullUrl
                font.family: "Monospace"
            }
            Button {
                flat: true
                icon.source: "/resource/images/copy.svg"
                icon.width: 22
                icon.height: 22
                icon.color: 'black'
                onClicked: {
                    tfFullUrl.selectAll()
                    tfFullUrl.copy()
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
                icon.source: "/resource/images/download.svg"
                icon.width: 18
                icon.height: 18
                onClicked: {
                    fromUrl()
                }
            }
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true

            id: paramList
            model: paramModel
            clip: true
            delegate: Rectangle {
                height: 50
                width: parent.width

                RowLayout {
                    spacing: 8
                    anchors.fill: parent

                    CheckBox {
                        id: cbEnabled
                        checked: model.isEnabled
                        onClicked: {
                            paramModel.setProperty(index, "isEnabled", cbEnabled.checkState === Qt.Checked)
                            fillUrl()
                            changeParam(index)
                        }
                    }
                    Column {
                        Layout.fillWidth: true

                        FlickableEdit {
                            id: paramName
                            isEnabled: cbEnabled.checkState === Qt.Checked
                            width: paramList.width / 3
                            height: 20
                            value: model.name
                            onEditingFinish: txt => {
                                let param = paramModel.get(index)

                                App.query.setParam(index, param.name, param.value, param.isEnabled)
                            }
                            onTextChange: txt => {
                                paramModel.setProperty(index, "name", txt)
                                fillUrl()
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
                            value: model.value
                            onEditingFinish: txt => {
                                 let param = paramModel.get(index)

                                 App.query.setParam(index, param.name, param.value, param.isEnabled)
                            }
                            onTextChange: txt => {
                                paramModel.setProperty(index, "value", txt)
                                fillUrl()
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
                        icon.source: "/resource/images/close.svg"
                        icon.width: 18
                        icon.height: 18
                        icon.color: 'black'
                        onClicked: {
                            App.query.removeParam(index)
                            paramModel.remove(index)

                            fillUrl()
                        }
                    }
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignRight

            spacing: 8
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 8
            anchors.right: parent.right

            Button {
                visible: paramModel.count > 0
                text: qsTr("Clear")
                flat: true
                icon.source: "/resource/images/close.svg"
                icon.width: 22
                icon.height: 22
                icon.color: 'black'
                onClicked: {
                    paramModel.clear()
                    App.query.params = []
                }
            }
            Item {
                Layout.fillWidth: true
            }
            Button {
                text: qsTr("Add")
                flat: true
                icon.source: "/resource/images/add.svg"
                icon.width: 22
                icon.height: 22
                icon.color: 'black'
                onClicked: {
                    paramModel.append({
                                          "name": '',
                                          "value": '',
                                          "isEnabled": true
                                      })
                    App.query.addParam('', '')
                }
            }
        }

        ListModel {
            id: paramModel
        }
    }


    Timer {
        id: syncTimer
        interval: 500;
        running: true;
        repeat: false
    }


    Connections {
        target: App

        function onQueryChanged() {
            paramModel.clear()
            fullUrl = ""

            fillData()
        }
    }

    Connections {
        target: winParam

        function onChangeParam(idx) {
            sync(idx)
        }
    }

    Connections {
        target: App.query

        function onUrlChanged() {
            rebuildUrl()
        }
    }

    Connections {
        target: App.workspace

        function onEnvChanged() {
            rebuildUrl()
        }
    }


    InputDialog {
        id: mdlImportQuery
        anchors.centerIn: parent
        title: qsTr("Import Request")
        placeholder: qsTr("cUrl string")
        onOk: cUrlString => {
                  if (!cUrlString) {
                      return
                  }

                  App.setFromCurl(cUrlString)
              }
    }


    function sync(idx) {
        syncTimer.triggered.connect(function () {
            let param = paramModel.get(idx)

            App.query.setParam(idx, param.name, param.value, param.isEnabled)
        });
        syncTimer.start()
    }

    function fillData() {
        // url
        let newUrl = App.query.url
        let vars = App.workspace.variables[App.workspace.env]

        if (vars) {
            for (let varr of vars) {
                newUrl = replaceVariables(newUrl, varr)
            }
        }


        if (Object.keys(App.query.params).length != 0) {
            newUrl += "?"
        }

        // params
        paramModel.clear()

        for (let p of App.query.params) {
            paramModel.append({
                                  "name": p.name,
                                  "value": p.value,
                                  "isEnabled": p.isEnabled
                              })
            newUrl += p.name + '=' + p.value + '&'
        }

        // set full url
        if (newUrl.slice(-1) === '&') {
            fullUrl = newUrl.substring(0, newUrl.length - 1)
        } else {
            fullUrl = newUrl
        }
    }

    function fillUrl() {
        let url = fullUrl
        let urlArr = url.split("?")

        if (App.workspace.env !== '') {
            let vars = App.workspace.variables[App.workspace.env]

            for (let varr of vars) {
                urlArr[0] = replaceVariables(urlArr[0], varr)
            }
        }


        url = urlArr[0] + '?'

        for (let i = 0; i < paramModel.count; ++i) {
            const param = paramModel.get(i)

            if (!param.isEnabled) {
                continue
            }

            url += param.name + '=' + param.value + '&'
        }

        if (url.slice(-1) === '&') {
            fullUrl = url.substring(0, url.length - 1)
        } else {
            fullUrl = url
        }
    }

    function fromUrl() {
        if (App.query.url === '') {
            return
        }

        // get all params
        let url = App.query.url
        const paramArr = url.slice(url.indexOf('?') + 1).split('&')
        const params = {}
        paramArr.map(param => {
                         const arr = param.split('=')
                         params[arr[0]] = decodeURIComponent(arr[1])
                     })

        if (params.length <= 1) {
            return
        }

        // get url without params
        let urlArr = App.query.url.split('?')
        let route = urlArr[0]

        // fill model from params
        paramModel.clear()

        for (let key in params) {
            paramModel.append({
                "name": key,
                "value": params[key],
                "isEnabled": true
            })
            App.query.addParam(key, params[key])
        }

        // set new data in query objecrt
        App.query.url = route

        // set full url preview
        fillUrl()
    }

    function replaceVariables(inputString, varr) {
        let regex = new RegExp(`{{\s*(${varr.name})\s*}}`);
        let replacedString = inputString.replace(regex, varr.value)

        return replacedString;
    }

    function rebuildUrl() {
        // url
        let newUrl = App.query.url
        let vars = App.workspace.variables[App.workspace.env]

        if (vars) {
            for (let varr of vars) {
                newUrl = replaceVariables(newUrl, varr)
            }
        }

        if (Object.keys(App.query.params).length != 0) {
            newUrl += "?"
        }

        // params
        for (let p of App.query.params) {
            if (!p.isEnabled) {
                continue
            }

            newUrl += p.name + '=' + p.value + '&'
        }

        // set full url
        if (newUrl.slice(-1) === '&') {
            fullUrl = newUrl.substring(0, newUrl.length - 1)
        } else {
            fullUrl = newUrl
        }
    }
}

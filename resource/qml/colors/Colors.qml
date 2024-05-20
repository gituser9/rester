pragma Singleton

import QtQuick


Item {
    readonly property string background: currentTheme[0]
    readonly property string font: currentTheme[1]
    readonly property string icon: currentTheme[1]
    readonly property string action: currentTheme[2]
    readonly property string secondaryBackground: currentTheme[3]

    property var currentTheme: themes.light
    property alias themes: themes


    QtObject{
        id: themes

        readonly property var light: ['#F9F7F7','#112D4E','#3F72AF','#DBE2EF']
        readonly property var dark: ['#222831','#EEEEEE','#00ADB5','#393E46']

    }
}

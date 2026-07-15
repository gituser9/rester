pragma ComponentBehavior: Bound
pragma ValueTypeBehavior: Addressable
pragma FunctionSignatureBehavior: Enforced

import QtQuick
import QtQuick.Controls.Imagine

Item {
    id: root
    implicitHeight: btn.height
    implicitWidth: btn.width

    property int size: RstButton.ButtonSize.Medium
    property string text: ''
    property string icon: ''
    property string tooltip: ''
    property string tooltipAfter: ''
    property string iconColor: 'black'
    property bool flat: true

    signal clicked

    Button {
        id: btn
        anchors.fill: parent
        flat: root.flat
        text: root.text
        icon.source: root.icon
        icon.width: root.getSize()
        icon.height: root.getSize()
        icon.color: root.iconColor
        onClicked: {
            root.clicked();

            if (root.tooltipAfter) {
                btn.tooltipText = root.tooltipAfter;
            }
        }

        property string tooltipText: root.tooltip

        ToolTip.text: tooltipText
        ToolTip.visible: root.tooltip && hovered
        ToolTip.toolTip.onVisibleChanged: {
            if (!hovered) {
                tooltipText = root.tooltip;
            }
        }
    }

    enum ButtonSize {
        Big,
        Medium,
        Small,
        Tool,
        Mini
    }

    function getSize() {
        switch (root.size) {
        case RstButton.ButtonSize.Mini:
            return 16;
        case RstButton.ButtonSize.Small:
            return 18;
        case RstButton.ButtonSize.Medium:
            return 22;
        case RstButton.ButtonSize.Tool:
            return 20;
        case RstButton.ButtonSize.Big:
            return 24;
        }
    }
}

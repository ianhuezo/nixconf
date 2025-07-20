import QtQuick
import "root:/config"
import "root:/services"

Rectangle {
    id: carouselItem

    // Public properties - inputs to the component
    property string appName: ""
    property string iconLocation: ""
    property bool mipmap: true
    property bool isSelected: false
    property int itemIndex: 0
    property int selectedIndex: 1
    property real unfocusedScale: 0.8
    property color textColor: Color.palette.base07
    property color underlineColor: Color.palette.base08
    property string fontFamily: "JetBrains Mono Nerd Font"
    property int fontSize: 18
    property int fontWeight: 500

    color: 'transparent'

    // Private properties - internal calculations
    property int relativePosition: itemIndex - selectedIndex
    property real targetScale: isSelected ? 1.0 : unfocusedScale
    property real targetYOffset: isSelected ? 0 : height * 0.1
    property real targetXOffset: {
        if (isSelected)
            return 0;
        return relativePosition < 0 ? -width * 0.05 : width * 0.05;
    }

    transform: [
        Scale {
            id: scaleTransform
            origin.x: carouselItem.width / 2
            origin.y: carouselItem.height / 2
            xScale: carouselItem.targetScale
            yScale: carouselItem.targetScale

            Behavior on xScale {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on yScale {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutCubic
                }
            }
        },
        Translate {
            id: translateTransform
            x: carouselItem.targetXOffset
            y: carouselItem.targetYOffset

            Behavior on x {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on y {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutCubic
                }
            }
        }
    ]

    // Opacity fade for non-selected items
    opacity: isSelected ? 1.0 : 0.7

    Behavior on opacity {
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        id: appIcon
        width: parent.width
        height: parent.height * 0.75
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        color: 'transparent'

        Image {
            anchors.centerIn: parent
            source: carouselItem.iconLocation
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            antialiasing: true
            mipmap: carouselItem.mipmap
            sourceSize.width: width
            sourceSize.height: height
        }
    }

    Rectangle {
        id: appTextContainer
        property var underlineMargin: 2
        width: parent.width
        height: parent.height * 0.25
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        color: 'transparent'

        Text {
            id: appText
            anchors.centerIn: parent
            text: carouselItem.appName
            font.family: carouselItem.fontFamily
            font.weight: carouselItem.fontWeight
            font.pixelSize: carouselItem.fontSize
            color: carouselItem.textColor
        }

        Rectangle {
            id: appUnderliner
            width: appText.width * 0.75
            x: appText.x + 0.15 * width
            height: 5
            y: appText.y + appText.height + appTextContainer.underlineMargin
            radius: 3
            color: carouselItem.isSelected ? carouselItem.underlineColor : 'transparent'

            Behavior on color {
                ColorAnimation {
                    duration: 300
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
}

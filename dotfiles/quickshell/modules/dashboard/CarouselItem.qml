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
    property int totalItems: 3
    property real unfocusedScale: 0.8
    property real carouselRadius: 200 // Radius of the circular path
    property color textColor: Color.palette.base07
    property color underlineColor: Color.palette.base08
    property string fontFamily: "JetBrains Mono Nerd Font"
    property int fontSize: 18
    property int fontWeight: 500

    color: 'transparent'

    // Private properties - circular carousel calculations
    property int relativePosition: {
        let diff = itemIndex - selectedIndex;
        let halfTotal = totalItems / 2;
        // Wrap around for circular behavior
        if (diff > halfTotal)
            diff -= totalItems;
        else if (diff < -halfTotal)
            diff += totalItems;
        return diff;
    }

    property real angle: (relativePosition / totalItems) * 2 * Math.PI
    property real normalizedDistance: Math.abs(relativePosition) / (totalItems / 2)

    property real targetScale: {
        if (isSelected)
            return 1.0;
        // Scale decreases with distance, using cosine for smooth falloff
        return unfocusedScale + (1.0 - unfocusedScale) * Math.cos(Math.abs(angle));
    }

    property real targetXOffset: {
        if (totalItems <= 1)
            return 0;
        // Sinusoidal horizontal positioning
        return Math.sin(angle) * carouselRadius * 0.3;
    }

    property real targetYOffset: {
        if (isSelected)
            return 0;
        // Slight vertical arc effect
        return Math.abs(Math.sin(angle)) * height * 0.15;
    }

    property real targetOpacity: {
        if (isSelected)
            return 1.0;
        // Opacity fades with distance using cosine curve
        return 0.3 + 0.7 * Math.max(0, Math.cos(Math.abs(angle)));
    }

    // Use z property for depth layering instead of transform
    z: 100 - Math.abs(relativePosition) * 10

    transform: [
        Scale {
            id: scaleTransform
            origin.x: carouselItem.width / 2
            origin.y: carouselItem.height / 2
            xScale: carouselItem.targetScale
            yScale: carouselItem.targetScale

            Behavior on xScale {
                NumberAnimation {
                    duration: 400
                    easing.type: Easing.InOutQuart
                }
            }

            Behavior on yScale {
                NumberAnimation {
                    duration: 400
                    easing.type: Easing.InOutQuart
                }
            }
        },
        Translate {
            id: translateTransform
            x: carouselItem.targetXOffset
            y: carouselItem.targetYOffset

            Behavior on x {
                NumberAnimation {
                    duration: 400
                    easing.type: Easing.InOutQuart
                }
            }

            Behavior on y {
                NumberAnimation {
                    duration: 400
                    easing.type: Easing.InOutQuart
                }
            }
        }
    ]

    // Sinusoidal opacity fade
    opacity: targetOpacity

    Behavior on opacity {
        NumberAnimation {
            duration: 400
            easing.type: Easing.InOutQuart
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
            text: carouselItem.isSelected ? carouselItem.appName : ''
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

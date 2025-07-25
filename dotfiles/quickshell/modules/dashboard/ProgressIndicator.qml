import QtQuick

Item {
    id: root
    
    // Public properties
    property bool visible: false
    property real progress: 0  // 0-100
    property string title: "Processing..."
    property string progressColor: "#4CAF50"
    property string backgroundColor: "#2a2a2a"
    property string overlayColor: "#80000000"
    property bool showPercentage: true
    property bool enablePulseAnimation: true
    property real containerWidth: parent ? parent.width * 0.7 : 300
    property real containerHeight: 120
    
    // Signals
    signal clicked()
    signal progressComplete()
    
    // Auto-emit completion signal when progress reaches 100
    onProgressChanged: {
        if (progress >= 100) {
            progressComplete();
        }
    }
    
    anchors.fill: parent
    visible: root.visible
    
    // Semi-transparent background overlay
    Rectangle {
        anchors.fill: parent
        color: root.overlayColor
        
        MouseArea {
            anchors.fill: parent
            onClicked: root.clicked()
        }
    }
    
    // Progress container
    Rectangle {
        id: progressContainer
        width: root.containerWidth
        height: root.containerHeight
        anchors.centerIn: parent
        color: root.backgroundColor
        radius: 12
        border.color: Qt.lighter(root.backgroundColor, 1.5)
        border.width: 1
        
        Column {
            anchors.centerIn: parent
            spacing: 15
            width: parent.width - 40
            
            // Title text
            Text {
                id: titleText
                text: root.title
                color: "#ffffff"
                font.pixelSize: 16
                font.weight: Font.Medium
                width: parent.width
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                maximumLineCount: 2
                elide: Text.ElideRight
            }
            
            // Progress bar background
            Rectangle {
                id: progressBarBg
                width: parent.width
                height: 8
                color: Qt.darker(root.backgroundColor, 1.5)
                radius: 4
                border.color: Qt.lighter(root.backgroundColor, 1.2)
                border.width: 1
                
                // Progress bar fill
                Rectangle {
                    id: progressBarFill
                    width: parent.width * Math.max(0, Math.min(100, root.progress)) / 100
                    height: parent.height
                    color: root.progressColor
                    radius: parent.radius
                    
                    Behavior on width {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutQuad
                        }
                    }
                    
                    // Subtle glow effect
                    Rectangle {
                        anchors.fill: parent
                        color: Qt.lighter(root.progressColor, 1.2)
                        radius: parent.radius
                        opacity: 0.5
                    }
                }
            }
            
            // Percentage text
            Text {
                text: Math.round(Math.max(0, Math.min(100, root.progress))) + "%"
                color: "#cccccc"
                font.pixelSize: 14
                anchors.horizontalCenter: parent.horizontalCenter
                visible: root.showPercentage
            }
        }
        
        // Pulsing animation
        SequentialAnimation {
            running: root.visible && root.enablePulseAnimation
            loops: Animation.Infinite
            
            PropertyAnimation {
                target: progressContainer
                property: "opacity"
                from: 0.9
                to: 1.0
                duration: 1000
                easing.type: Easing.InOutQuad
            }
            PropertyAnimation {
                target: progressContainer
                property: "opacity"
                from: 1.0
                to: 0.9
                duration: 1000
                easing.type: Easing.InOutQuad
            }
        }
    }
    
    // Convenience functions
    function show(initialTitle) {
        if (initialTitle !== undefined) {
            root.title = initialTitle;
        }
        root.visible = true;
        root.progress = 0;
    }
    
    function hide() {
        root.visible = false;
    }
    
    function updateProgress(newProgress, newTitle) {
        root.progress = newProgress;
        if (newTitle !== undefined) {
            root.title = newTitle;
        }
    }
    
    function reset() {
        root.progress = 0;
        root.title = "Processing...";
        root.visible = false;
    }
}

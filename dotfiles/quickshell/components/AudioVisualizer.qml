import QtQuick
import Quickshell.Io
import qs.services
import qs.config

Item {
    id: root

    // Common properties
    property var cavaValues: []
    property color visualizerColor: 'white'
    property bool mirrored: true
    property real sensitivity: 1.0

    // Mode selection: "wave", "bars", or "title"
    property string mode: "wave"
    property var modes: ["wave", "bars", "title"]

    // Wave-specific properties
    property int lineWidth: 1

    // Bar-specific properties
    property int barWidth: 6
    property int barSpacing: 2
    property int barRadius: 2

    // Title-specific properties
    property string title: ""
    property int titlePauseDuration: 1500
    property real titleScrollPixelsPerSecond: 18
    property int titleScrollMinDuration: 4500
    // Symmetric ease with cp1y/cp2y pulled inward from {0,1}. Pure {0,1} on the
    // y-axis pins the velocity to 0 at the endpoints, which produces a long
    // crawl into the stop and forces the middle to peak high (1.82x avg) to
    // make up the area. Pulling to {0.1, 0.9} drops the middle peak to ~1.5x
    // and roughly doubles the velocity near t=1, so the text stops decisively.
    readonly property var titleScrollCurve: [0.4, 0.1, 0.6, 0.9, 1, 1]

    Loader {
        id: visualizerLoader
        anchors.fill: parent
        sourceComponent: {
            switch (root.mode) {
            case "wave":
                return waveComponent;
            case "bars":
                return barsComponent;
            case "title":
                return titleComponent;
            }
        }
    }

    Component {
        id: titleComponent
        Item {
            id: scrollingTitle
            anchors.fill: parent
            clip: true

            // text x = start - delta; increasing delta scrolls left, revealing
            // the right side of the text. Capped at maxDelta so the right side
            // never retracts past `end`.
            property real start: 0
            property real end: width
            property real delta: 0
            property real maxDelta: Math.max(0, titleText.implicitWidth - (end - start))
            property bool needsScroll: titleText.implicitWidth > (end - start) && root.title.length > 0
            // Constant px/sec keeps long titles from feeling rushed; min duration
            // prevents flashes for tiny overflows.
            property int scrollDuration: Math.max(root.titleScrollMinDuration, Math.round(maxDelta / root.titleScrollPixelsPerSecond * 1000))

            Text {
                id: titleText
                text: root.title
                color: root.visualizerColor
                font.family: AppearanceConfig.font.mono
                font.pixelSize: AppearanceConfig.font.size.sm
                font.weight: AppearanceConfig.font.weight.medium
                x: scrollingTitle.start - scrollingTitle.delta
                anchors.verticalCenter: parent.verticalCenter
            }

            Connections {
                target: root
                function onTitleChanged() {
                    scrollingTitle.delta = 0;
                }
            }

            onNeedsScrollChanged: if (!needsScroll) delta = 0

            SequentialAnimation on delta {
                running: scrollingTitle.needsScroll
                loops: Animation.Infinite
                alwaysRunToEnd: false

                PauseAnimation {
                    duration: root.titlePauseDuration
                }
                NumberAnimation {
                    from: 0
                    to: scrollingTitle.maxDelta
                    duration: scrollingTitle.scrollDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: root.titleScrollCurve
                }
                PauseAnimation {
                    duration: root.titlePauseDuration
                }
                NumberAnimation {
                    from: scrollingTitle.maxDelta
                    to: 0
                    duration: scrollingTitle.scrollDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: root.titleScrollCurve
                }
            }
        }
    }

    Component {
        id: waveComponent
        Canvas {
            id: wave
            anchors.fill: parent

            onPaint: {
                const ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                if (root.cavaValues.length < 2)
                    return;

                // 1. Define minimum vertical scale to ensure 2px height
                const minMaxValue = 15;
                const rawMax = Math.max(...root.cavaValues);
                const maxValue = Math.max(minMaxValue, rawMax);

                // 2. Calculate dimensions
                const drawHeight = root.mirrored ? height / 2 : height;
                const stepX = width / (root.cavaValues.length - 1);
                const baseY = root.mirrored ? drawHeight : height;

                ctx.strokeStyle = root.visualizerColor;
                ctx.lineWidth = root.lineWidth;
                ctx.fillStyle = root.visualizerColor;
                ctx.lineCap = 'round';
                ctx.lineJoin = 'round';

                // 3. Draw top wave (or full wave if not mirrored)
                ctx.beginPath();
                ctx.moveTo(0, baseY);

                // Smooth transition at the start
                const firstScaledValue = root.cavaValues[0] * root.sensitivity;
                const firstY = baseY - (firstScaledValue / maxValue * (baseY - 2));
                ctx.quadraticCurveTo(0, firstY, stepX * 0.5, baseY - ((root.cavaValues[0] * root.sensitivity + (root.cavaValues.length > 1 ? root.cavaValues[1] * root.sensitivity : root.cavaValues[0] * root.sensitivity)) / 2 / maxValue * (baseY - 2)));

                for (let i = 0; i < root.cavaValues.length; i++) {
                    const x = i * stepX;
                    const scaledValue = root.cavaValues[i] * root.sensitivity;
                    const y = baseY - (scaledValue / maxValue * (baseY - 2));
                    if (i === 0) {
                        continue; // Already handled above
                    } else {
                        const prevScaledValue = root.cavaValues[i - 1] * root.sensitivity;
                        const prevY = baseY - (prevScaledValue / maxValue * (baseY - 2));
                        const cp1x = x - stepX / 2;
                        const cp1y = prevY;
                        const cp2x = x - stepX / 2;
                        const cp2y = y;
                        ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, x, y);
                    }
                }

                // Smooth transition at the end
                const lastScaledValue = root.cavaValues[root.cavaValues.length - 1] * root.sensitivity;
                const lastY = baseY - (lastScaledValue / maxValue * (baseY - 2));
                ctx.quadraticCurveTo(width, lastY, width, baseY);

                ctx.closePath();
                ctx.fill();
                ctx.stroke();

                // 4. Draw mirrored bottom wave if enabled
                if (root.mirrored) {
                    ctx.beginPath();
                    ctx.moveTo(0, drawHeight);

                    // Smooth transition at the start
                    const firstScaledValueBottom = root.cavaValues[0] * root.sensitivity;
                    const firstYBottom = drawHeight + (firstScaledValueBottom / maxValue * (drawHeight - 2));
                    ctx.quadraticCurveTo(0, firstYBottom, stepX * 0.5, drawHeight + ((root.cavaValues[0] * root.sensitivity + (root.cavaValues.length > 1 ? root.cavaValues[1] * root.sensitivity : root.cavaValues[0] * root.sensitivity)) / 2 / maxValue * (drawHeight - 2)));

                    for (let i = 0; i < root.cavaValues.length; i++) {
                        const x = i * stepX;
                        const scaledValue = root.cavaValues[i] * root.sensitivity;
                        const y = drawHeight + (scaledValue / maxValue * (drawHeight - 2));
                        if (i === 0) {
                            continue; // Already handled above
                        } else {
                            const prevScaledValue = root.cavaValues[i - 1] * root.sensitivity;
                            const prevY = drawHeight + (prevScaledValue / maxValue * (drawHeight - 2));
                            const cp1x = x - stepX / 2;
                            const cp1y = prevY;
                            const cp2x = x - stepX / 2;
                            const cp2y = y;
                            ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, x, y);
                        }
                    }

                    // Smooth transition at the end
                    const lastScaledValueBottom = root.cavaValues[root.cavaValues.length - 1] * root.sensitivity;
                    const lastYBottom = drawHeight + (lastScaledValueBottom / maxValue * (drawHeight - 2));
                    ctx.quadraticCurveTo(width, lastYBottom, width, drawHeight);

                    ctx.closePath();
                    ctx.fill();
                    ctx.stroke();
                }
            }

            Timer {
                interval: 16
                running: true
                repeat: true
                onTriggered: wave.requestPaint()
            }
        }
    }

    Component {
        id: barsComponent
        Item {
            id: bars
            anchors.fill: parent

            Row {
                id: topRow
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: root.mirrored ? parent.verticalCenter : parent.bottom
                spacing: root.barSpacing

                Repeater {
                    model: root.cavaValues
                    delegate: Rectangle {
                        width: root.barWidth
                        height: Math.min(root.mirrored ? bars.height / 2 : bars.height, Math.max(2, modelData * root.sensitivity))
                        color: root.visualizerColor
                        radius: root.barRadius
                        topLeftRadius: root.barRadius
                        topRightRadius: root.barRadius
                        bottomLeftRadius: root.mirrored ? 0 : root.barRadius
                        bottomRightRadius: root.mirrored ? 0 : root.barRadius
                        anchors.bottom: parent.bottom

                        Behavior on height {
                            NumberAnimation {
                                duration: 100
                                easing.type: Easing.OutQuad
                            }
                        }
                    }
                }
            }

            Row {
                id: bottomRow
                visible: root.mirrored
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.verticalCenter
                spacing: root.barSpacing

                Repeater {
                    model: root.cavaValues
                    delegate: Rectangle {
                        width: root.barWidth
                        height: Math.min(bars.height / 2, Math.max(2, modelData * root.sensitivity))
                        color: root.visualizerColor
                        radius: root.barRadius
                        topLeftRadius: root.mirrored ? 0 : root.barRadius
                        topRightRadius: root.mirrored ? 0 : root.barRadius
                        bottomLeftRadius: root.barRadius
                        bottomRightRadius: root.barRadius
                        anchors.top: parent.top

                        Behavior on height {
                            NumberAnimation {
                                duration: 100
                                easing.type: Easing.OutQuad
                            }
                        }
                    }
                }
            }
        }
    }
}

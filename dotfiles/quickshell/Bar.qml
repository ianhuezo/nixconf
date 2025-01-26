import Quickshell
import Quickshell.Io
import QtQuick
import Quickshell.Services.Mpris

Scope {
    id: root  // Added root identifier for proper scoping
    property var cavaValues: []
    property string albumArtUrl: ""

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: panel  // Identifier for panel
            property var modelData
            screen: modelData
            height: 32

            anchors {
                top: true
                left: true
                right: true
            }

            // Visualizer container
            Rectangle {
                id: visualizerContainer
                anchors {
                    fill: parent
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 2
                    height: 32
                    width: 632

                    Image {
                        source: Mpris.players.values.map(value => value.trackArtUrl)[0] ?? ""
                        fillMode: Image.PreserveAspectFit
                        width: 32
                        height: 32
                        mipmap: true
                        layer.enabled: true
                        layer.textureSize: Qt.size(32, 32)
                        layer.smooth: false // Disable layer smoothing
                        Rectangle {
                            anchors.fill: parent
                            color: "gray"
                            visible: parent.status !== Image.Ready
                        }
                    }

                    Repeater {
                        model: root.cavaValues  // Explicit scoping using root
                        delegate: Rectangle {
                            width: 6
                            height: Math.min(parent.height, Math.max(2, modelData * 1))
                            color: "#7da6ff"
                            radius: 2
                            anchors.bottom: parent.bottom  // Anchor to bottom
                        }
                    }
                    Canvas {
                        id: waveCanvas
                        width: 300
                        height: 32
                        onPaint: {
                            const ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);

                            if (root.cavaValues.length < 2)
                                return;

                            // 1. Define minimum vertical scale to ensure 2px height
                            const minMaxValue = 30; // Adjust this to control sensitivity
                            const rawMax = Math.max(...root.cavaValues);
                            const maxValue = Math.max(minMaxValue, rawMax); // Enforce minimum scale

                            // 2. Calculate dimensions
                            const stepX = width / (root.cavaValues.length - 1);
                            const baseY = height; // Bottom padding

                            ctx.beginPath();
                            ctx.strokeStyle = root.waveColor;
                            ctx.lineWidth = root.lineWidth;
                            ctx.fillStyle = Qt.rgba(0.5, 0.5, 1, 0.2);

                            // 3. Draw filled path
                            ctx.moveTo(0, baseY);

                            for (let i = 0; i < root.cavaValues.length; i++) {
                                const x = i * stepX;
                                // 4. Ensure values scale to at least 2px height
                                const y = baseY - (root.cavaValues[i] / maxValue * (baseY - 2));

                                if (i === 0) {
                                    ctx.lineTo(x, y);
                                } else {
                                    const prevY = baseY - (root.cavaValues[i - 1] / maxValue * (baseY - 2));
                                    const cp1x = x - stepX / 2;
                                    const cp1y = prevY;
                                    const cp2x = x - stepX / 2;
                                    const cp2y = y;
                                    ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, x, y);
                                }
                            }

                            // 5. Close and render
                            ctx.lineTo(width, baseY);
                            ctx.closePath();
                            ctx.fill();
                            ctx.stroke();
                        }
                    }

                    Timer {
                        interval: 16
                        running: true
                        repeat: true
                        onTriggered: {
                            waveCanvas.requestPaint();
                            // Debug current values
                            // console.log("Current values:", JSON.parse(JSON.stringify(root.cavaValues)))
                        }
                    }
                }
            }
        }
    }

    Process {
        id: cavaProc
        command: ["sh", "../scripts/cava_startup.sh"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                const newValues = data.trim().split(';').map(v => {
                    const num = parseInt(v, 10);
                    return Math.min(40, Math.max(0, isNaN(num) ? 0 : num));
                });

                // Apply exponential smoothing
                if (root.cavaValues.length === 0) {
                    root.cavaValues = newValues;
                } else {
                    root.cavaValues = root.cavaValues.map((oldVal, index) => {
                        return 0.3 * oldVal + 0.7 * (newValues[index] || 0);
                    });
                }
            }
        }
    }
}

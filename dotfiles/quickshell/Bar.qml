import Quickshell
import Quickshell.Io
import QtQuick
import Quickshell.Services.Mpris
import QtQuick.Controls
import QtQuick.Layouts

Scope {
    id: root  // Added root identifier for proper scoping
    property var cavaValues: []
    property string albumArtUrl: ""
    property var lineWidth: 3
    property var waveColor: '#FF9E64'
    property var fullBarColor: '#171D23'
    property var useCanvasVisualization: true

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
                id: bar
                anchors {
                    fill: parent
                }
                color: fullBarColor

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.useCanvasVisualization = !root.useCanvasVisualization;
                    }
                }

                Row {
                    anchors.centerIn: parent
                    visible: true
                    spacing: 2
                    z: 0
                    height: 32
                    width: 232

                    Image {
                        source: {
                            //first prefer spotify no matter what. unless it does not exist
                            var players = Mpris.players.values.filter(player => {
                                return player.identity == "Spotify";
                            });
                            return players[0].trackArtUrl ?? Mpris.players.values.map(value => value.trackArtUrl)[0] ?? "";
                        }
                        fillMode: Image.PreserveAspectFit
                        width: parent.height
                        height: parent.height
                        sourceSize.width: parent.height
                        cache: false //disable this as memory will climb each song change
                        sourceSize.height: parent.height
                        mipmap: true
                        layer.smooth: true // Disable layer smoothing
                        Rectangle {
                            anchors.fill: parent
                            color: "gray"
                            visible: parent.status !== Image.Ready
                        }
                    }

                    Repeater {
                        id: repeater
                        model: root.cavaValues  // Explicit scoping using root
                        delegate: Rectangle {
                            width: 6
                            visible: !root.useCanvasVisualization
                            height: Math.min(parent.height, Math.max(2, modelData * 1))
                            color: root.waveColor
                            radius: 2
                            anchors.bottom: parent.bottom  // Anchor to bottom
                        }
                        Behavior on height {
                            NumberAnimation {
                                duration: 100
                                easing.type: Easing.OutQuad
                            }
                        }
                    }
                    Canvas {
                        id: waveCanvas
                        visible: root.useCanvasVisualization
                        z: 1
                        width: 166
                        height: 32
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 200
                            }
                        }
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
                            ctx.fillStyle = root.waveColor;

                            // 3. Draw filled path
                            ctx.moveTo(0, baseY);

                            for (let i = 0; i < root.cavaValues.length; i++) {
                                const x = i * stepX;
                                // 4. Ensure values scale to at least 2px height
                                const y = baseY - (root.cavaValues[i] / maxValue * (baseY - 2));

                                if (i === 0 || i === root.cavaValues.length - 1) {
                                    continue;
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
                const newValues = data.trim().split(';').filter(v => v != '').map(v => {
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

import QtQuick
import QtQuick.Effects
import qs.config
import qs.services

Rectangle {
    id: leftSection
    color: "transparent"

    Row {
        id: leftContent
        anchors.verticalCenter: parent.verticalCenter
        anchors.centerIn: parent
        spacing: 24

        Rectangle {
            id: nixosRect
            width: 20
            height: 20
            radius: 10
            color: 'transparent'
            
            Image {
                id: nixosIcon
                sourceSize.width: parent.width
                sourceSize.height: parent.height
                fillMode: Image.PreserveAspectFit
                source: FileConfig.icons.nix
                layer.enabled: true
                layer.effect: MultiEffect {
                    colorization: 0.8
                    colorizationColor: Color.palette.base0D
                    shadowEnabled: true
                    shadowColor: Color.palette.base0C
                    shadowVerticalOffset: 0
                    shadowHorizontalOffset: 0
                    shadowBlur: 1.5
                    shadowOpacity: 0.9
                }
            }
            
            // Focused glow effect using icon color
            Rectangle {
                id: flowOverlay
                anchors.centerIn: nixosIcon  // Center on the actual icon, not the container
                width: nixosIcon.paintedWidth * 1.8  // Use painted dimensions
                height: nixosIcon.paintedHeight * 1.8
                radius: width / 2
                color: "transparent"
                
                Canvas {
                    id: flowCanvas
                    anchors.fill: parent
                    property real flowOffset: 0
                    
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        
                        var centerX = width / 2;
                        var centerY = height / 2;
                        var baseRadius = Math.min(width, height) / 2;
                        
                        // Use same color as icon for consistency
                        var iconColor = Color.palette.base0D;
                        
                        var animatedOffset = flowOffset % 1.0;
                        var pulseIntensity = Math.sin(animatedOffset * Math.PI * 2) * 0.4 + 0.6;
                        
                        // Create organic flowing shape with splines
                        ctx.beginPath();
                        
                        var numPoints = 8; // Back to fewer points for cleaner look
                        var points = [];
                        
                        // Generate organic control points with smooth animation
                        for (var i = 0; i < numPoints; i++) {
                            var angle = (i / numPoints) * Math.PI * 2;
                            var radiusVariation = Math.sin(angle * 3 + animatedOffset * Math.PI * 4) * 0.3 + 1.0;
                            var radius = baseRadius * 0.9 * radiusVariation; // Slightly larger base size
                            
                            points.push({
                                x: centerX + Math.cos(angle) * radius,
                                y: centerY + Math.sin(angle) * radius
                            });
                        }
                        
                        // Start the path
                        ctx.moveTo(points[0].x, points[0].y);
                        
                        // Create smooth curves between points using quadratic curves
                        for (var i = 0; i < numPoints; i++) {
                            var current = points[i];
                            var next = points[(i + 1) % numPoints];
                            var nextNext = points[(i + 2) % numPoints];
                            
                            // Control point is the midpoint between current and next-next
                            var cpX = (current.x + next.x) / 2;
                            var cpY = (current.y + next.y) / 2;
                            
                            ctx.quadraticCurveTo(cpX, cpY, next.x, next.y);
                        }
                        
                        ctx.closePath();
                        
                        // Create radial gradient for the organic shape
                        var gradient = ctx.createRadialGradient(centerX, centerY, 0, centerX, centerY, baseRadius);
                        gradient.addColorStop(0, Qt.rgba(0, 0, 0, 0));
                        gradient.addColorStop(0.3, Qt.rgba(0, 0, 0, 0));
                        gradient.addColorStop(0.6, Qt.rgba(iconColor.r, iconColor.g, iconColor.b, pulseIntensity * 0.3));
                        gradient.addColorStop(0.8, Qt.rgba(iconColor.r, iconColor.g, iconColor.b, pulseIntensity * 0.5));
                        gradient.addColorStop(1, Qt.rgba(iconColor.r, iconColor.g, iconColor.b, 0));
                        
                        ctx.fillStyle = gradient;
                        ctx.fill();
                    }
                    
                    NumberAnimation on flowOffset {
                        running: true
                        from: 0
                        to: 1
                        duration: 3000
                        loops: Animation.Infinite
                        easing.type: Easing.Linear
                        onRunningChanged: flowCanvas.requestPaint()
                    }
                    
                    onFlowOffsetChanged: requestPaint()
                }
            }
        }
        Rectangle {
            id: hyprlandRect
            width: 28 * 5 - 8
            height: parent.height
            radius: 10
            color: 'transparent'
            HyprlandWorkspaces {}
        }
    }
}

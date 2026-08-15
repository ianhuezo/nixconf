import QtQuick
import qs.services

// One pane of the bar's glass: denser than the filler it floats on, with edges
// that dissolve into that filler instead of ending on a hard line.
Item {
    id: pane

    property color tint: Color.palette.base01
    property real fillOpacity: 0.72      // final on-screen opacity of the core
    property real underlayOpacity: 0.45  // what the filler already contributes
    property real fadeWidth: 26          // px each edge takes to dissolve
    property real cornerRadius: 0        // only used when there is nothing to fade into

    // Panes paint on top of the filler, so the two alphas compound. Solve for
    // the alpha that lands the composite on fillOpacity rather than stacking
    // past it into a solid slab.
    readonly property real coreAlpha: underlayOpacity >= 1 ? 1 : Math.max(0, Math.min(1, (fillOpacity - underlayOpacity) / (1 - underlayOpacity)))

    // Smoothstep: a linear ramp still reads as an edge because the eye catches
    // the kink where it meets the filler. Easing both ends hides the seam.
    function ramp(t) {
        const eased = t * t * (3 - 2 * t);
        return Qt.rgba(tint.r, tint.g, tint.b, coreAlpha * eased);
    }

    Rectangle {
        id: core
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
            right: parent.right
            leftMargin: pane.fadeWidth
            rightMargin: pane.fadeWidth
        }
        color: pane.ramp(1)
        radius: pane.cornerRadius
    }

    // Leading dissolve
    Rectangle {
        anchors {
            top: parent.top
            bottom: parent.bottom
            right: core.left
        }
        width: pane.fadeWidth
        visible: pane.fadeWidth > 0

        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop {
                position: 0.0
                color: pane.ramp(0.0)
            }
            GradientStop {
                position: 0.25
                color: pane.ramp(0.25)
            }
            GradientStop {
                position: 0.5
                color: pane.ramp(0.5)
            }
            GradientStop {
                position: 0.75
                color: pane.ramp(0.75)
            }
            GradientStop {
                position: 1.0
                color: pane.ramp(1.0)
            }
        }
    }

    // Trailing dissolve
    Rectangle {
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: core.right
        }
        width: pane.fadeWidth
        visible: pane.fadeWidth > 0

        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop {
                position: 0.0
                color: pane.ramp(1.0)
            }
            GradientStop {
                position: 0.25
                color: pane.ramp(0.75)
            }
            GradientStop {
                position: 0.5
                color: pane.ramp(0.5)
            }
            GradientStop {
                position: 0.75
                color: pane.ramp(0.25)
            }
            GradientStop {
                position: 1.0
                color: pane.ramp(0.0)
            }
        }
    }
}

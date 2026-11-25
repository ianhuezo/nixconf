import QtQuick
import QtQuick.Shapes

Shape {
    id: root

    property string edge: "top"
    property real reveal: 1
    property real span: 0
    property real depth: 0
    property real radius: 12
    property real smoothing: 0.6
    property color fillColor: "black"

    readonly property real reach: Math.round((1 + smoothing) * radius)
    readonly property real length: span + reach * 2
    readonly property bool vertical: edge === "left" || edge === "right"

    readonly property string outline: {
        const v = Math.max(0, Math.min(1, reveal)) * depth;
        if (v <= 0 || span <= 0)
            return "";
        const k = Math.min(1, v / (reach + radius));
        const pf = reach * k;
        const rf = pf / (1 + smoothing);
        const rc = radius * k;
        const x0 = reach;
        const x1 = reach + span;
        return `M ${point(x0 - pf, 0)} ${corner(x0 - pf, 0, [1, 0], [0, 1], rf, smoothing)}`
            + ` L ${point(x0, v - rc)} ${corner(x0, v - rc, [0, 1], [1, 0], rc, 0)}`
            + ` L ${point(x1 - rc, v)} ${corner(x1 - rc, v, [1, 0], [0, -1], rc, 0)}`
            + ` L ${point(x1, pf)} ${corner(x1, pf, [0, -1], [1, 0], rf, smoothing)} Z`;
    }

    function point(u, w) {
        let xy;
        switch (edge) {
        case "right":
            xy = [depth - w, u];
            break;
        case "bottom":
            xy = [length - u, depth - w];
            break;
        case "left":
            xy = [w, length - u];
            break;
        default:
            xy = [u, w];
        }
        return `${xy[0].toFixed(2)} ${xy[1].toFixed(2)}`;
    }

    function corner(u, w, d1, d2, r, s) {
        const p = (1 + s) * r;
        const arcAngle = Math.PI / 2 * (1 - s);
        const arcLen = Math.sin(arcAngle / 2) * r * Math.SQRT2;
        const c = r * Math.tan(Math.PI / 8 * s) * Math.cos(Math.PI / 4 * s);
        const d = c * Math.tan(Math.PI / 4 * s);
        const b = (p - arcLen - c - d) / 3;
        const a = 2 * b;
        const at = (du, dw) => point(u + du * d1[0] + dw * d2[0], w + du * d1[1] + dw * d2[1]);
        const sweep = d1[0] * d2[1] - d1[1] * d2[0] > 0 ? 1 : 0;
        const arc = `A ${r.toFixed(2)} ${r.toFixed(2)} 0 0 ${sweep} ${at(p - d, d + arcLen)}`;
        if (s <= 0)
            return arc;
        return `C ${at(a, 0)} ${at(a + b, 0)} ${at(a + b + c, d)} ${arc} C ${at(p, d + arcLen + c)} ${at(p, d + arcLen + b + c)} ${at(p, p)}`;
    }

    implicitWidth: vertical ? depth : length
    implicitHeight: vertical ? length : depth
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        fillColor: root.fillColor
        strokeColor: "transparent"

        PathSvg {
            path: root.outline
        }
    }
}

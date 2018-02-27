import QtQuick.Scene3D 2.0
import QtQuick 2.2 as QQ2
import QtQuick.Window 2.13

import Qt3D.Core 2.0
import Qt3D.Render 2.0
import Qt3D.Input 2.0
import Qt3D.Logic 2.0
import Qt3D.Extras 2.0
import Qt3D.Animation 2.9

Entity {
    id: root
    property string color: "#ff6"
    property bool visible: false
    property var axes: [0, 1]
    readonly property bool x: axes[0] === 0 || axes[1] === 0
    readonly property bool y: axes[0] === 1 || axes[1] === 1
    readonly property bool z: axes[0] === 2 || axes[1] === 2
    property var gizmo
    readonly property int mode: gizmo.mode
    readonly property real size: gizmo.size
    readonly property real beamRadius: gizmo.beamRadius
    property bool dragging: false

    signal dragStart()
    signal drag(real dx, real dy)
    signal dragEnd()

    components: [
        CuboidMesh {
            id: cuboid
            readonly property real squareSize: size * 0.3
            readonly property real squareThickness: beamRadius * 0.5
            enabled: visible
            xExtent: x ? squareSize : squareThickness
            yExtent: y ? squareSize : squareThickness
            zExtent: z ? squareSize : squareThickness
        },
        Transform {
            readonly property real margin: size * 0.025
            readonly property real d: beamRadius + margin + cuboid.squareSize / 2
            translation: Qt.vector3d(x ? d : 0, y ? d : 0, z ? d : 0)
        },
        PhongMaterial {
            ambient: dragging || picker.containsMouse ? Qt.lighter(color, 1.44) : color
        },
        ObjectPicker {
            id: picker
            hoverEnabled: true
            dragEnabled: true
            onPressed: { dragging = true; root.dragStart() }
            MouseDevice {
                id: mouseDev
            }
            MouseHandler {
                id: mouseHandler
                sourceDevice: mouseDev
                property point lastPos
                onPressed: lastPos = Qt.point(mouse.x, mouse.y)
                onPositionChanged: { if(dragging) root.drag(mouse.x - lastPos.x, mouse.y - lastPos.y); lastPos = Qt.point(mouse.x, mouse.y) }
                onReleased: { if(dragging) { dragging = false; root.dragEnd() } }
            }
        }
    ]
}

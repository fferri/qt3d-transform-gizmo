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
    property string color: "#999"
    property bool visible: false
    property var gizmo
    readonly property int mode: gizmo.mode
    readonly property real size: gizmo.size
    readonly property real beamRadius: gizmo.beamRadius
    property bool dragging: false

    signal dragStart()
    signal drag(real dx, real dy)
    signal dragEnd()

    components: [ObjectPicker {
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
    }]

    PhongMaterial {
        id: material
        ambient: dragging || picker.containsMouse ? Qt.lighter(root.color, 1.44) : root.color
    }

    Entity {
        id: lineEntity

        CylinderMesh {
            id: lineMesh
            enabled: visible
            radius: beamRadius
            length: size * 0.8
        }

        Transform {
            id: lineTransform
            translation: Qt.vector3d(0, lineMesh.length / 2, 0)
        }

        components: [lineMesh, lineTransform, material]
    }

    Entity {
        id: translateEntity

        ConeMesh {
            id: translateMesh
            enabled: visible && mode === TransformGizmo.Mode.Translation
            bottomRadius: beamRadius * 1.5
            topRadius: 0
            length: size * 0.2
        }

        Transform {
            id: translateTransform
            translation: Qt.vector3d(0, lineMesh.length + translateMesh.length / 2, 0)
        }

        components: [translateMesh, translateTransform, material]
    }

    Entity {
        id: rotateEntity

        CylinderMesh {
            id: rotateMesh
            enabled: visible && mode === TransformGizmo.Mode.Rotation
            radius: beamRadius * 2
            length: beamRadius * 2
        }

        Transform {
            id: rotateTransform
            translation: Qt.vector3d(0, lineMesh.length + rotateMesh.length / 2, 0)
        }

        components: [rotateMesh, rotateTransform, material]
    }

    Entity {
        id: scaleEntity

        CuboidMesh {
            id: scaleMesh
            enabled: visible && mode === TransformGizmo.Mode.Scale
            xExtent: beamRadius * 3
            yExtent: beamRadius * 3
            zExtent: beamRadius * 3
        }

        Transform {
            id: scaleTransform
            translation: Qt.vector3d(0, lineMesh.length + scaleMesh.xExtent / 2, 0)
        }

        components: [scaleMesh, scaleTransform, material]
    }
}

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
    property real size: 1
    readonly property real beamRadius: size * 0.035
    property var layer
    property var cameraController
    property var targetTransform
    property var targetEntity
    property real linearSpeed: 0.01
    property real angularSpeed: 2.0
    property bool visible: false
    property vector3d absolutePosition: Qt.vector3d(0, 0, 0)

    enum Mode {
        Translation,
        Rotation,
        Scale
    }

    property int mode: TransformGizmo.Mode.Translation
    property bool canTranslate: true
    property bool canRotate: true
    property bool canScale: false
    property var modes: [
        ...(canTranslate ? [TransformGizmo.Mode.Translation] : []),
        ...(canRotate ? [TransformGizmo.Mode.Rotation] : []),
        ...(canScale ? [TransformGizmo.Mode.Scale] : []),
    ]

    Transform {
        id: ownTransform
    }

    components: [ownTransform, layer]

    function getMatrix(entity) {
        var t = getTransform(entity)
        if(t) return t.matrix
        return Qt.matrix4x4(1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1)
    }

    function getAbsoluteMatrix() {
        var entity = root
        var m = Qt.matrix4x4(1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1)
        while(entity) {
            m = getMatrix(entity).times(m)
            entity = entity.parent
        }
        return m
    }

    function fixOwnTransform() {
        // cancel rotation component of parent's (target) transform
        var t = targetTransform.matrix
        var i = t.inverted()
        i = i.times(Qt.matrix4x4(1,0,0,t.m14,0,1,0,t.m24,0,0,1,t.m34,0,0,0,1))
        ownTransform.matrix = i

        // compute absolute position to expose as a property
        var m = getAbsoluteMatrix()
        absolutePosition = Qt.vector3d(m.m14, m.m24, m.m34)
    }

    QQ2.Loader {
        active: !!targetTransform
        sourceComponent: QQ2.Connections {
            target: targetTransform
            onMatrixChanged: fixOwnTransform()
        }
    }

    function qmlInstanceOf(obj, className) {
        return obj.toString().indexOf(className + "(") === 0;
    }

    function getTransform(entity) {
        if(entity instanceof Entity)
            for(var i = 0; i < entity.components.length; i++)
                if(qmlInstanceOf(entity.components[i], "Qt3DCore::QTransform"))
                    return entity.components[i]
    }

    function attachTo(entity) {
        var t = getTransform(entity)
        if(t) {
            targetEntity = entity
            targetTransform = t
            root.parent = entity
            fixOwnTransform()
            visible = true
        }
    }

    function angleAxisToQuat(angle, x, y, z) {
        var a = angle * Math.PI / 180.0;
        var s = Math.sin(a * 0.5);
        var c = Math.cos(a * 0.5);
        return Qt.quaternion(c, x * s, y * s, z * s);
    }

    function multiplyQuaternion(q1, q2) {
        return Qt.quaternion(q1.scalar * q2.scalar - q1.x * q2.x - q1.y * q2.y - q1.z * q2.z,
                             q1.scalar * q2.x + q1.x * q2.scalar + q1.y * q2.z - q1.z * q2.y,
                             q1.scalar * q2.y + q1.y * q2.scalar + q1.z * q2.x - q1.x * q2.z,
                             q1.scalar * q2.z + q1.z * q2.scalar + q1.x * q2.y - q1.y * q2.x);
    }

    function translate(dx, dy, dz) {
        if(!targetTransform) return
        targetTransform.translation.x += dx
        targetTransform.translation.y += dy
        targetTransform.translation.z += dz
    }

    function rotate(dx, dy, dz) {
        if(!targetTransform) return
        targetTransform.rotation = multiplyQuaternion(angleAxisToQuat(dx, 1, 0, 0), targetTransform.rotation)
        targetTransform.rotation = multiplyQuaternion(angleAxisToQuat(dy, 0, 1, 0), targetTransform.rotation)
        targetTransform.rotation = multiplyQuaternion(angleAxisToQuat(dz, 0, 0, 1), targetTransform.rotation)
    }

    function scale(dx, dy, dz) {
        if(!targetTransform) return
        targetTransform.scale3D.x += dx
        targetTransform.scale3D.y += dy
        targetTransform.scale3D.z += dz
    }

    Entity {
        id: modeSwitcher
        components: [
            SphereMesh {
                id: modeSwitcherSphere
                radius: beamRadius * 2
                enabled: visible
            },
            PhongMaterial {
                diffuse: "#999"
            },
            ObjectPicker {
                onClicked: mode = (modes.indexOf(mode) + 1) % modes.length
            }
        ]
    }

    NodeInstantiator {
        id: beams
        model: [
            {rx:  0, ry: 0, rz: -90, x: 1, y: 0, z: 0, color: "#f33"},
            {rx:  0, ry: 0, rz:   0, x: 0, y: 1, z: 0, color: "#3f3"},
            {rx: 90, ry: 0, rz:   0, x: 0, y: 0, z: 1, color: "#33f"}
        ]
        delegate: Entity {
            components: [
                Transform {
                    translation: Qt.vector3d(modelData.x, modelData.y, modelData.z).times(modeSwitcherSphere.radius * 1.1)
                    rotationX: modelData.rx
                    rotationY: modelData.ry
                    rotationZ: modelData.rz
                }
            ]
            TransformGizmoBeam {
                visible: root.visible
                gizmo: root
                color: modelData.color
                onDragStart: cameraController.enabled = false
                onDrag: {
                    switch(mode) {
                    case TransformGizmo.Mode.Translation: translate(modelData.x * linearSpeed * dy, modelData.y * linearSpeed * dy, modelData.z * linearSpeed * dy); break
                    case TransformGizmo.Mode.Rotation: rotate(modelData.x * angularSpeed * dy, modelData.y * angularSpeed * dy, modelData.z * angularSpeed * dy); break
                    case TransformGizmo.Mode.Scale: scale(modelData.x * linearSpeed * dy, modelData.y * linearSpeed * dy, modelData.z * linearSpeed * dy); break
                    }
                }
                onDragEnd: cameraController.enabled = true
            }
        }
    }

    NodeInstantiator {
        id: planes
        model: [
            {x: 1, y: 1, z: 0, axes: [0, 1]},
            {x: 1, y: 0, z: 1, axes: [0, 2]},
            {x: 0, y: 1, z: 1, axes: [1, 2]},
        ]
        delegate: TransformGizmoPlane {
            visible: root.visible
            gizmo: root
            axes: modelData.axes
            onDragStart: cameraController.enabled = false
            onDrag: translate(modelData.x * linearSpeed * dx, modelData.y * linearSpeed * (modelData.axes[1] === 1 ? dy : dx), modelData.z * linearSpeed * dy)
            onDragEnd: cameraController.enabled = true
        }
    }
}

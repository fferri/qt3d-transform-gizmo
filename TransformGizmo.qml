import QtQuick.Scene3D 2.0
import QtQuick 2.2 as QQ2

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
    property Layer layer
    property var cameraController
    property Transform targetTransform
    property Entity targetEntity
    property real linearSpeed: 0.01
    property real angularSpeed: 2.0
    property bool visible: false
    property vector3d absolutePosition: Qt.vector3d(0, 0, 0)
    property real hoverHilightFactor: 1.44
    property real hoverZoomFactor: 1.5
    property int mode: TransformGizmo.Mode.Translation
    property bool canTranslate: true
    property bool canRotate: true
    property bool canScale: false
    property var hoverElements: new Set()
    property var hoverElement: TransformGizmo.UIElement.None
    property var activeElement: TransformGizmo.UIElement.None
    components: [ownTransform, layer]

    enum Mode {
        Translation,
        Rotation,
        Scale
    }

    enum UIElement {
        None,
        ModeSwitcher,
        BeamX,
        BeamY,
        BeamZ,
        PlaneXY,
        PlaneXZ,
        PlaneYZ
    }

    // called by ObjectPickers of individual UI elements:
    function trackUIElement(element, active) {
        if(active) hoverElements.add(element)
        else hoverElements.delete(element)

        var newHoverElement = TransformGizmo.UIElement.None
        for(var x of [TransformGizmo.UIElement.ModeSwitcher, TransformGizmo.UIElement.BeamX, TransformGizmo.UIElement.BeamY, TransformGizmo.UIElement.BeamZ, TransformGizmo.UIElement.PlaneXY, TransformGizmo.UIElement.PlaneXZ, TransformGizmo.UIElement.PlaneYZ])
            if(newHoverElement === TransformGizmo.UIElement.None && hoverElements.has(x))
                newHoverElement = x
        hoverElement = newHoverElement
    }

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

    function switchMode() {
        var modes = [
            ...(canTranslate ? [TransformGizmo.Mode.Translation] : []),
            ...(canRotate ? [TransformGizmo.Mode.Rotation] : []),
            ...(canScale ? [TransformGizmo.Mode.Scale] : []),
        ]
        mode = (modes.indexOf(mode) + 1) % modes.length
    }

    function translate(dx, dy, dz) {
        if(!targetTransform) return
        targetTransform.translation.x += linearSpeed * dx
        targetTransform.translation.y += linearSpeed * dy
        targetTransform.translation.z += linearSpeed * dz
    }

    function rotate(dx, dy, dz) {
        if(!targetTransform) return
        targetTransform.rotation = multiplyQuaternion(angleAxisToQuat(angularSpeed * dx, 1, 0, 0), targetTransform.rotation)
        targetTransform.rotation = multiplyQuaternion(angleAxisToQuat(angularSpeed * dy, 0, 1, 0), targetTransform.rotation)
        targetTransform.rotation = multiplyQuaternion(angleAxisToQuat(angularSpeed * dz, 0, 0, 1), targetTransform.rotation)
    }

    function scale(dx, dy, dz) {
        if(!targetTransform) return
        targetTransform.scale3D.x += linearSpeed * dx
        targetTransform.scale3D.y += linearSpeed * dy
        targetTransform.scale3D.z += linearSpeed * dz
    }

    Transform {
        id: ownTransform
    }

    MouseDevice {
        id: mouseDev
    }

    MouseHandler {
        sourceDevice: mouseDev
        property point lastPos
        onPressed: {
            if(hoverElement === TransformGizmo.UIElement.None) return
            lastPos = Qt.point(mouse.x, mouse.y)
            if(cameraController) cameraController.enabled = false
            activeElement = hoverElement
        }
        onPositionChanged: {
            if(activeElement === TransformGizmo.UIElement.None) return
            var dx = mouse.x - lastPos.x
            var dy = mouse.y - lastPos.y
            switch(activeElement) {
            case TransformGizmo.UIElement.BeamX:
            case TransformGizmo.UIElement.BeamY:
            case TransformGizmo.UIElement.BeamZ:
                var x = activeElement === TransformGizmo.UIElement.BeamX
                var y = activeElement === TransformGizmo.UIElement.BeamY
                var z = activeElement === TransformGizmo.UIElement.BeamZ
                switch(mode) {
                case TransformGizmo.Mode.Translation: translate(x * dy, y * dy, z * dy); break
                case TransformGizmo.Mode.Rotation: rotate(x * dy, y * dy, z * dy); break
                case TransformGizmo.Mode.Scale: scale(x * dy, y * dy, z * dy); break
                }
                break;
            case TransformGizmo.UIElement.PlaneXY: translate(dx, dy, 0); break
            case TransformGizmo.UIElement.PlaneXZ: translate(dx, 0, dy); break
            case TransformGizmo.UIElement.PlaneYZ: translate(0, dx, dy); break
            }
            lastPos = Qt.point(mouse.x, mouse.y)
        }
        onReleased: {
            if(activeElement === TransformGizmo.UIElement.None) return
            if(cameraController) cameraController.enabled = true
            activeElement = TransformGizmo.UIElement.None
        }
    }

    QQ2.Loader {
        active: !!targetTransform
        sourceComponent: QQ2.Connections {
            target: targetTransform
            onMatrixChanged: fixOwnTransform()
        }
    }

    Entity {
        id: modeSwitcher
        readonly property color color: "#333"
        readonly property bool hover: root.hoverElement === TransformGizmo.UIElement.ModeSwitcher
        readonly property bool active: root.activeElement === TransformGizmo.UIElement.ModeSwitcher
        readonly property bool hilighted: active || (root.activeElement === TransformGizmo.UIElement.None && hover)
        components: [modeSwitcherSphere, modeSwitcherMaterial, modeSwitcherPicker]

        SphereMesh {
            id: modeSwitcherSphere
            readonly property real radius0: beamRadius * 2
            readonly property real radius1: root.hoverZoomFactor * radius0
            radius: modeSwitcher.hilighted ? radius1 : radius0
            enabled: root.visible
        }

        PhongMaterial {
            id: modeSwitcherMaterial
            ambient: modeSwitcher.hilighted ? Qt.lighter(modeSwitcher.color, root.hoverHilightFactor) : modeSwitcher.color
        }

        ObjectPicker {
            id: modeSwitcherPicker
            hoverEnabled: true
            onClicked: root.switchMode()
            onEntered: root.trackUIElement(TransformGizmo.UIElement.ModeSwitcher, true)
            onExited: root.trackUIElement(TransformGizmo.UIElement.ModeSwitcher, false)
        }
    }

    NodeInstantiator {
        id: beams
        model: [
            {r: Qt.vector3d( 0, 0, -90), v: Qt.vector3d(1, 0, 0), color: "#f33", element: TransformGizmo.UIElement.BeamX},
            {r: Qt.vector3d( 0, 0,   0), v: Qt.vector3d(0, 1, 0), color: "#3f3", element: TransformGizmo.UIElement.BeamY},
            {r: Qt.vector3d(90, 0,   0), v: Qt.vector3d(0, 0, 1), color: "#33f", element: TransformGizmo.UIElement.BeamZ}
        ]
        delegate: Entity {
            components: [beamTransform]

            Transform {
                id: beamTransform
                translation: modelData.v.times(modeSwitcherSphere.radius0 * 1.1)
                rotationX: modelData.r.x
                rotationY: modelData.r.y
                rotationZ: modelData.r.z
            }

            Entity {
                id: beam
                readonly property bool hover: root.hoverElement === modelData.element
                readonly property bool active: root.activeElement === modelData.element
                readonly property bool hilighted: active || (root.activeElement === TransformGizmo.UIElement.None && hover)
                readonly property color color: modelData.color
                components: [beamPicker]

                ObjectPicker {
                    id: beamPicker
                    hoverEnabled: true
                    onEntered: root.trackUIElement(modelData.element, true)
                    onExited: root.trackUIElement(modelData.element, false)
                }

                PhongMaterial {
                    id: beamMaterial
                    ambient: beam.hilighted ? Qt.lighter(beam.color, root.hoverHilightFactor) : beam.color
                }

                Entity {
                    components: [lineMesh, lineTransform, beamMaterial]

                    CylinderMesh {
                        id: lineMesh
                        enabled: root.visible
                        radius: root.beamRadius
                        length: root.size * 0.8
                    }

                    Transform {
                        id: lineTransform
                        translation: Qt.vector3d(0, lineMesh.length / 2, 0)
                    }
                }

                Entity {
                    components: [translateMesh, translateTransform, beamMaterial]

                    ConeMesh {
                        id: translateMesh
                        enabled: root.visible && root.mode === TransformGizmo.Mode.Translation
                        bottomRadius: root.beamRadius * 2
                        topRadius: 0
                        length: root.size * 0.2
                    }

                    Transform {
                        id: translateTransform
                        translation: Qt.vector3d(0, lineMesh.length + translateMesh.length / 2, 0)
                    }
                }

                Entity {
                    components: [rotateMesh, rotateTransform, beamMaterial]

                    CylinderMesh {
                        id: rotateMesh
                        enabled: root.visible && root.mode === TransformGizmo.Mode.Rotation
                        radius: root.beamRadius * 2
                        length: root.beamRadius * 2
                    }

                    Transform {
                        id: rotateTransform
                        translation: Qt.vector3d(0, lineMesh.length + rotateMesh.length / 2, 0)
                    }
                }

                Entity {
                    components: [scaleMesh, scaleTransform, beamMaterial]

                    CuboidMesh {
                        id: scaleMesh
                        enabled: root.visible && root.mode === TransformGizmo.Mode.Scale
                        xExtent: root.beamRadius * 3
                        yExtent: root.beamRadius * 3
                        zExtent: root.beamRadius * 3
                    }

                    Transform {
                        id: scaleTransform
                        translation: Qt.vector3d(0, lineMesh.length + scaleMesh.xExtent / 2, 0)
                    }
                }
            }
        }
    }

    NodeInstantiator {
        id: planes
        model: [
            {v: Qt.vector3d(1, 1, 0), element: TransformGizmo.UIElement.PlaneXY},
            {v: Qt.vector3d(1, 0, 1), element: TransformGizmo.UIElement.PlaneXZ},
            {v: Qt.vector3d(0, 1, 1), element: TransformGizmo.UIElement.PlaneYZ},
        ]
        delegate: Entity {
            id: plane
            readonly property bool hover: root.hoverElement === modelData.element
            readonly property bool active: root.activeElement === modelData.element
            readonly property bool hilighted: active || (root.activeElement === TransformGizmo.UIElement.None && hover)
            readonly property color color: "#dd6"
            components: [cuboid, planeTransform, planeMaterial, planePicker]

            CuboidMesh {
                id: cuboid
                readonly property real squareSize: root.size * 0.3
                readonly property real squareThickness: root.beamRadius * 0.5
                enabled: root.visible
                xExtent: modelData.v.x ? squareSize : squareThickness
                yExtent: modelData.v.y ? squareSize : squareThickness
                zExtent: modelData.v.z ? squareSize : squareThickness
            }

            Transform {
                id: planeTransform
                translation: modelData.v.times(root.beamRadius + root.size * 0.025 + cuboid.squareSize / 2)
            }

            PhongMaterial {
                id: planeMaterial
                ambient: plane.hilighted ? Qt.lighter(plane.color, root.hoverHilightFactor) : plane.color
            }

            ObjectPicker {
                id: planePicker
                hoverEnabled: true
                onEntered: root.trackUIElement(modelData.element, true)
                onExited: root.trackUIElement(modelData.element, false)
            }
        }
    }
}

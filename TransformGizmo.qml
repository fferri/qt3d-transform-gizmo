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
    property real hoverHilightFactor: 1.44
    property real hoverZoomFactor: 1.5

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

    MouseDevice {
        id: mouseDev
    }

    MouseHandler {
        sourceDevice: mouseDev
        property point lastPos
        onPressed: {
            if(hoverElement === "") return
            lastPos = Qt.point(mouse.x, mouse.y)
            cameraController.enabled = false
            activeElement = hoverElement
        }
        onPositionChanged: {
            if(activeElement === "") return
            var dx = mouse.x - lastPos.x
            var dy = mouse.y - lastPos.y
            switch(activeElement) {
            case "beamX":
            case "beamY":
            case "beamZ":
                var x = activeElement === "beamX"
                var y = activeElement === "beamY"
                var z = activeElement === "beamZ"
                switch(mode) {
                case TransformGizmo.Mode.Translation: translate(x * dy, y * dy, z * dy); break
                case TransformGizmo.Mode.Rotation: rotate(x * dy, y * dy, z * dy); break
                case TransformGizmo.Mode.Scale: scale(x * dy, y * dy, z * dy); break
                }
                break;
            case "planeXY": translate(dx, dy, 0); break
            case "planeXZ": translate(dx, 0, dy); break
            case "planeYZ": translate(0, dx, dy); break
            }
            lastPos = Qt.point(mouse.x, mouse.y)
        }
        onReleased: {
            if(activeElement === "") return
            cameraController.enabled = true
            activeElement = ""
        }
    }

    components: [ownTransform, layer]

    property var hoverElements: new Set()
    property var hoverElement: ""
    property var activeElement: ""

    function trackUIElement(elementName, active) {
        if(active) hoverElements.add(elementName)
        else hoverElements.delete(elementName)

        var newHoverElement = ""
        for(var x of ["modeSwitcher", "beamX", "beamY", "beamZ", "planeXY", "planeXZ", "planeYZ"])
            if(newHoverElement === "" && hoverElements.has(x))
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

    Entity {
        id: modeSwitcher
        objectName: "modeSwitcher"
        readonly property color color: "#333"
        readonly property bool hover: root.hoverElement == objectName
        readonly property bool active: root.activeElement === objectName
        readonly property bool hilighted: active || (root.activeElement === "" && hover)
        components: [
            SphereMesh {
                id: modeSwitcherSphere
                readonly property real radius0: beamRadius * 2
                readonly property real radius1: root.hoverZoomFactor * radius0
                radius: modeSwitcher.hilighted ? radius1 : radius0
                enabled: root.visible
            },
            PhongMaterial {
                ambient: modeSwitcher.hilighted ? Qt.lighter(modeSwitcher.color, root.hoverHilightFactor) : modeSwitcher.color
            },
            ObjectPicker {
                id: modeSwitcherPicker
                hoverEnabled: true
                onClicked: mode = (modes.indexOf(mode) + 1) % modes.length
                onEntered: root.trackUIElement(modeSwitcher.objectName, true)
                onExited: root.trackUIElement(modeSwitcher.objectName, false)
            }
        ]
    }

    NodeInstantiator {
        id: beams
        model: [
            {rx:  0, ry: 0, rz: -90, x: 1, y: 0, z: 0, color: "#f33", name: "beamX"},
            {rx:  0, ry: 0, rz:   0, x: 0, y: 1, z: 0, color: "#3f3", name: "beamY"},
            {rx: 90, ry: 0, rz:   0, x: 0, y: 0, z: 1, color: "#33f", name: "beamZ"}
        ]
        delegate: Entity {
            components: [
                Transform {
                    translation: Qt.vector3d(modelData.x, modelData.y, modelData.z).times(modeSwitcherSphere.radius0 * 1.1)
                    rotationX: modelData.rx
                    rotationY: modelData.ry
                    rotationZ: modelData.rz
                }
            ]

            Entity {
                id: beam
                readonly property bool hover: root.hoverElement === modelData.name
                readonly property bool active: root.activeElement === modelData.name
                readonly property bool hilighted: active || (root.activeElement === "" && hover)
                readonly property color color: modelData.color
                property bool dragging: false

                components: [beamPicker]

                ObjectPicker {
                    id: beamPicker
                    hoverEnabled: true
                    onEntered: root.trackUIElement(modelData.name, true)
                    onExited: root.trackUIElement(modelData.name, false)
                }

                PhongMaterial {
                    id: beamMaterial
                    ambient: beam.hilighted ? Qt.lighter(beam.color, root.hoverHilightFactor) : beam.color
                }

                Entity {
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

                    components: [lineMesh, lineTransform, beamMaterial]
                }

                Entity {
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

                    components: [translateMesh, translateTransform, beamMaterial]
                }

                Entity {
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

                    components: [rotateMesh, rotateTransform, beamMaterial]
                }

                Entity {
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

                    components: [scaleMesh, scaleTransform, beamMaterial]
                }
            }
        }
    }

    NodeInstantiator {
        id: planes
        model: [
            {x: 1, y: 1, z: 0, name: "planeXY"},
            {x: 1, y: 0, z: 1, name: "planeXZ"},
            {x: 0, y: 1, z: 1, name: "planeYZ"},
        ]
        delegate: Entity {
            id: plane
            readonly property bool hover: root.hoverElement === modelData.name
            readonly property bool active: root.activeElement === modelData.name
            readonly property bool hilighted: active || (root.activeElement === "" && hover)
            readonly property color color: "#dd6"
            readonly property bool x: modelData.x
            readonly property bool y: modelData.y
            readonly property bool z: modelData.z
            readonly property var axes: [...(x ? [0] : []), ...(y ? [1] : []), ...(z ? [2] : [])]
            property bool dragging: false

            components: [
                CuboidMesh {
                    id: cuboid
                    readonly property real squareSize: root.size * 0.3
                    readonly property real squareThickness: root.beamRadius * 0.5
                    enabled: root.visible
                    xExtent: plane.x ? squareSize : squareThickness
                    yExtent: plane.y ? squareSize : squareThickness
                    zExtent: plane.z ? squareSize : squareThickness
                },
                Transform {
                    readonly property real margin: root.size * 0.025
                    readonly property real d: root.beamRadius + margin + cuboid.squareSize / 2
                    translation: Qt.vector3d(plane.x ? d : 0, plane.y ? d : 0, plane.z ? d : 0)
                },
                PhongMaterial {
                    ambient: plane.hilighted ? Qt.lighter(plane.color, root.hoverHilightFactor) : plane.color
                },
                ObjectPicker {
                    id: planePicker
                    hoverEnabled: true
                    onEntered: root.trackUIElement(modelData.name, true)
                    onExited: root.trackUIElement(modelData.name, false)
                }
            ]
        }
    }
}

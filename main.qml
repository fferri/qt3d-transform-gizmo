import QtQuick.Scene3D 2.0
import QtQuick 2.2 as QQ2
import QtQuick.Window 2.13

import Qt3D.Core 2.0
import Qt3D.Render 2.0
import Qt3D.Input 2.0
import Qt3D.Logic 2.0
import Qt3D.Extras 2.0
import Qt3D.Animation 2.9

Scene3D {
    id: scene3d
    anchors.fill: parent
    aspects: ["render", "logic", "input"]
    hoverEnabled: true // needed for ObjectPickers to handle hover events

    Entity {
        id: root
        components: [
            RenderSettings {
                /*activeFrameGraph: ForwardRenderer {
                    id: renderer
                    camera: mainCamera
                }*/
                Viewport {
                    normalizedRect: Qt.rect(0.0, 0.0, 1.0, 1.0)
                    RenderSurfaceSelector {
                        CameraSelector {
                            id: cameraSelector
                            camera: mainCamera
                            FrustumCulling {
                                ClearBuffers {
                                    buffers: ClearBuffers.AllBuffers
                                    clearColor: "#ddd"
                                    NoDraw {}
                                }
                                LayerFilter {
                                    objectName: "firstLayerFilter"
                                    id: firstLayerFilter
                                    layers: [firstLayer]
                                }
                                LayerFilter {
                                    id: secondLayerFilter
                                    objectName: "secondLayerFilter"
                                    layers: [secondLayer]
                                    ClearBuffers {
                                        buffers: ClearBuffers.DepthBuffer
                                        clearColor: "#ddd"
                                    }
                                }
                            }
                        }
                    }
                }
                pickingSettings.pickMethod: PickingSettings.TrianglePicking
                pickingSettings.pickResultMode: PickingSettings.AllPicks
                pickingSettings.faceOrientationPickingMode: PickingSettings.FrontAndBackFace
            },
            InputSettings {}
        ]

        Camera {
            id: mainCamera
            projectionType: CameraLens.PerspectiveProjection
            fieldOfView: 45
            aspectRatio: 16/9
            nearPlane : 0.1
            farPlane : 1000.0
            position: Qt.vector3d(-3.46902, 4.49373, -3.78577)
            upVector: Qt.vector3d(0.41477, 0.789346, 0.452641)
            viewCenter: Qt.vector3d(0.0, 0.5, 0.0)
        }

        SOrbitCameraController {
            id: mainCameraController
            camera: mainCamera
        }

        Entity {
            components: [Layer {
                id: secondLayer
                objectName: "secondLayer"
                recursive: true
            }]

            TransformGizmo {
                id: tg
                layer: secondLayer
                cameraController: mainCameraController
                size: 0.125 * absolutePosition.minus(mainCamera.position).length()
            }
        }

        Entity {
            components: [Layer {
                objectName: "firstLayer"
                id : firstLayer
                recursive: true
            }]

            Floor {components: [Transform {rotationX: 90; translation: "0,-.5,0"}]}

            Entity {
                id: cube1Entity
                components: [
                    CuboidMesh {
                        xExtent: 1
                        yExtent: 1
                        zExtent: 1
                    },
                    PhongMaterial {
                        diffuse: "#aaa"
                    },
                    Transform {
                        rotationX: -45
                        rotationY: 45
                        translation: Qt.vector3d(0.5, 0.5, 0.5)
                    },
                    ObjectPicker {
                        onClicked: tg.attachTo(cube1Entity)
                    }
                ]
            }

            Entity {
                id: cube2Entity
                components: [
                    CuboidMesh {
                        xExtent: 1
                        yExtent: 1
                        zExtent: 1
                    },
                    PhongMaterial {
                        diffuse: "#6cc"
                    },
                    Transform {
                        id: t
                        translation: Qt.vector3d(-0.5, 0, 0.5)
                    },
                    ObjectPicker {
                        onClicked: tg.attachTo(cube2Entity)
                    }
                ]
                Entity {
                    id: cube3Entity
                    components: [
                        CuboidMesh {
                            xExtent: 0.5
                            yExtent: 0.5
                            zExtent: 0.5
                        },
                        PhongMaterial {
                            diffuse: "#c6c"
                        },
                        Transform {
                            id: t2
                            translation: Qt.vector3d(-0.5, 0, 0.5)
                        },
                        ObjectPicker {
                            onClicked: tg.attachTo(cube3Entity)
                        }
                    ]
                }
            }

            Entity {
                components: [
                    PointLight {
                        color: "white"
                        intensity: 0.9
                        constantAttenuation: 1.0
                        linearAttenuation: 0.0
                        quadraticAttenuation: 0.0025
                    },
                    Transform {
                        translation: Qt.vector3d(1.0, 3.0, -2.0)
                    }
                ]
            }
        }
    }
}

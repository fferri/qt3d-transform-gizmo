/*
qt3d-transform-gizmo
Copyright (C) 2020  Federico Ferri

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

import QtQuick.Scene3D 2.0
import QtQuick 2.2 as QtQuick
import QtQuick.Controls 2.2 as QtQuick
import QtQuick.Window 2.2 as QtQuick

import Qt3D.Core 2.0
import Qt3D.Render 2.0
import Qt3D.Input 2.0
import Qt3D.Logic 2.0
import Qt3D.Extras 2.0
import Qt3D.Animation 2.9

QtQuick.ApplicationWindow {
    id: mainWindow
    visible: true
    width: 500
    height: 500
    title: "Qt3D Transform Gizmo"

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
                                        filterMode: LayerFilter.DiscardAnyMatchingLayers
                                        layers: [topLayer]
                                    }
                                    LayerFilter {
                                        filterMode: LayerFilter.AcceptAnyMatchingLayers
                                        layers: [topLayer]
                                        ClearBuffers {
                                            buffers: ClearBuffers.DepthBuffer
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

            Layer {
                id: topLayer
                recursive: true
            }

            TransformGizmo {
                id: tg
                layer: topLayer
                cameraController: mainCameraController
                camera: mainCamera
                scene3d: scene3d
                size: 0.125 * absolutePosition.minus(mainCamera.position).length()
            }

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

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
    property real thickness: 0.1
    property real tileSize: 0.5
    property int rows: 16
    property int columns: 16
    property color color1: "#ddd"
    property color color2: "#eee"

    NodeInstantiator {
        model: columns
        delegate: NodeInstantiator {
            readonly property int columnIndex: index
            model: rows
            delegate: Entity {
                readonly property int rowIndex: index
                components: [
                    CuboidMesh {
                        xExtent: tileSize
                        yExtent: tileSize
                        zExtent: thickness
                    },
                    Transform {
                        translation: Qt.vector3d((rowIndex - rows / 2) * tileSize, (columnIndex - columns / 2) * tileSize, 0)
                    },
                    PhongMaterial {
                        readonly property bool evenRow: rowIndex % 2 == 0
                        readonly property bool evenColumn: columnIndex % 2 == 0
                        diffuse: evenRow ^ evenColumn ? color1 : color2
                    }
                ]
            }
        }
    }
}

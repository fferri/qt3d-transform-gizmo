# qt3d-transform-gizmo

A gizmo for graphical interactive (mnouse-based) translation and rotation of objects in a Qt3D scene.

![screenshot](screenshot.png)

# Building

```shell
qmake && make
```

# Run

```shell
/qt3d-transform-gizmo
```

Or with Python:

```shell
# install dependencies:
python -m pip install poetry
python -m poetry install

poetry run qt3d-transform-gizmo
```

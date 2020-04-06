import sys
import os
from PyQt5.QtGui import QGuiApplication
from PyQt5.QtQuick import QQuickView
from PyQt5.QtCore import QUrl

def main():
    app = QGuiApplication(sys.argv)
    view = QQuickView()
    view.setResizeMode(QQuickView.SizeRootObjectToView)

    qmlFile = os.path.join(os.path.dirname(__file__), 'main.qml')
    view.setSource(QUrl.fromLocalFile(os.path.abspath(qmlFile)))
    if view.status() == QQuickView.Error:
        sys.exit(-1)
    view.show()

    app.exec_()
    # Deleting the view before it goes out of scope is required to make
    # sure all child QML instances are destroyed in the correct order.
    del view

if __name__ == '__main__':
    main()

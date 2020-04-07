#!/usr/bin/env python
# -*- conding: utf-8 -*-

import os, sys
from PyQt5.QtWidgets import QApplication
from PyQt5.QtQml import QQmlApplicationEngine


class App():

    def __init__(self, qapp):

        self.engine = QQmlApplicationEngine()
        self.engine.load('main.qml')
        try:
            qmlroot = self.engine.rootObjects()[0]
        except:
            print('Failed to load QML')
            sys.exit()

def main():

    #Set up the application window
    qapp = QApplication(sys.argv)

    #Create the App
    app = App(qapp)

    #execute and cleanup
    sys.exit(qapp.exec_())


if __name__ == '__main__':
    main()

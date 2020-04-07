#!/usr/bin/env python
# -*- conding: utf-8 -*-
#
# qt3d-transform-gizmo
# Copyright (C) 2020  Federico Ferri
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


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
    qapp.setOrganizationName("fferri")
    qapp.setOrganizationDomain("3D")
    qapp.setApplicationName("Qt3D Transform Gizmo")

    #Create the App
    app = App(qapp)

    #execute and cleanup
    sys.exit(qapp.exec_())


if __name__ == '__main__':
    main()

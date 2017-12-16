/*
 *  Kaidan - A user-friendly XMPP client for every device!
 *
 *  Copyright (C) 2017 JBBgameich <jbb.mail@gmx.de>
 *
 *  Kaidan is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  Kaidan is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with Kaidan. If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.9
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.2 as Controls
import org.kde.kirigami 2.0 as Kirigami

Kirigami.Page {
	id: aboutPage
	title: qsTr("About")

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

		Image {
            source: kaidan.getResourcePath("icons/kaidan.svg")
            Layout.preferredHeight: aboutPage.height * 0.3
            Layout.maximumHeight: 300
			fillMode: Image.PreserveAspectFit
            Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
            mipmap: true
            sourceSize: Qt.size(width, height)
		}

		Kirigami.Heading {
			text: "Kaidan " + kaidan.getVersionString()
            Layout.fillWidth: true
            horizontalAlignment: Qt.AlignHCenter
		}

        Controls.Label {
			text: qsTr("A simple, user-friendly Jabber/XMPP client")
            Layout.fillWidth: true
            horizontalAlignment: Qt.AlignHCenter
		}

        Controls.Label {
			text: qsTr("License:") + " GPLv3+ / CC BY-SA 4.0"
            Layout.fillWidth: true
            horizontalAlignment: Qt.AlignHCenter
		}

        Controls.Label {
			text: "Copyright (C) 2016-2017 Kaidan developers and contributors"
            Layout.fillWidth: true
            horizontalAlignment: Qt.AlignHCenter
		}

		Controls.ToolButton {
            text: qsTr("Source code on Github")
			onClicked: Qt.openUrlExternally("https://github.com/KaidanIM/Kaidan")
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
		}

		Controls.Button {
			id: closeButton
			text: qsTr("Close")
            Layout.alignment: Qt.AlignHCenter
			onClicked: {
				closeButton.enabled = false;
				pageStack.pop();
			}
		}
	}
}

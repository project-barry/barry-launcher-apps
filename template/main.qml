// A starting point for a Barry Launcher app: copy this folder, change the
// id, name and icon in barry-app.json, and build from here.
//
// The root item fills the bottom screen. Barry Launcher hands it `barry`:
//   barry.scale     1 at the AYN Thor's bottom screen (1240 x 1080); size
//                   everything as N * barry.scale
//   barry.dataDirUrl  a folder of your own to save things in (it survives
//                   updates; removing the app deletes it)
//   barry.close()   quit the app
pragma ComponentBehavior: Bound
import QtQuick
import QtCore

Rectangle {
    id: app
    required property var barry
    readonly property real s: barry.scale
    color: "black"

    // Remembered between runs.
    Settings {
        id: saved
        location: app.barry.dataDirUrl + "settings.ini"
        property int taps: 0
    }

    Column {
        anchors.centerIn: parent
        spacing: 40 * app.s

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Hello, Barry!"
            color: "#eef0f4"
            font { family: "Noto Sans"; pixelSize: 72 * app.s; weight: Font.Bold }
        }

        // A big button: fingers need room (90 pixels or more).
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 460 * app.s
            height: 130 * app.s
            radius: 40 * app.s
            color: tap.pressed ? "#4a4f60" : "#6b2fb3"
            Text {
                anchors.centerIn: parent
                text: "Tapped " + saved.taps + (saved.taps === 1 ? " time" : " times")
                color: "#eef0f4"
                font { family: "Noto Sans"; pixelSize: 40 * app.s; weight: Font.DemiBold }
            }
            TapHandler {
                id: tap
                onTapped: saved.taps++
            }
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 300 * app.s
            height: 96 * app.s
            radius: 24 * app.s
            color: closeTap.pressed ? "#4a4f60" : "#1b1d24"
            border.color: "#3a3e4d"
            border.width: 2 * app.s
            Text {
                anchors.centerIn: parent
                text: "Close"
                color: "#eef0f4"
                font { family: "Noto Sans"; pixelSize: 34 * app.s; weight: Font.DemiBold }
            }
            TapHandler {
                id: closeTap
                onTapped: app.barry.close()
            }
        }
    }
}

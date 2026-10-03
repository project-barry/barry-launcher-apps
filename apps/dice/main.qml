// Dice: an example Barry Launcher app. Pick a die (d4 to d20) and how many
// (1 to 6), then roll; tap one die to roll it alone. The dice and the last
// rolls are saved in the app's data folder, so they are there next time.
//
// What it shows about making a Barry Launcher app:
// - the root item fills the bottom screen, and everything is sized by
//   barry.scale (1 at the AYN Thor's 1240 x 1080 bottom screen)
// - settings saved with QtCore's Settings, in barry.dataDirUrl
// - touch with TapHandler, and big targets (at least 90 pixels)
// - barry.close() for a close button
pragma ComponentBehavior: Bound
import QtQuick
import QtCore

Rectangle {
    id: app
    required property var barry  // from Barry Launcher (AppHost.qml)
    readonly property real s: barry.scale

    color: "black"

    // Saved between runs, in the app's own data folder.
    Settings {
        id: saved
        location: app.barry.dataDirUrl + "dice.ini"
        property int sides: 6
        property int count: 2
        property string history: ""  // the last totals, newest first, comma separated
    }

    readonly property var kinds: [4, 6, 8, 10, 12, 20]
    property var values: []
    readonly property bool rolling: {
        for (let i = 0; i < dice.count; i++)
            if ((dice.itemAt(i) as Die)?.rolling)
                return true
        return false
    }
    readonly property int total: values.slice(0, saved.count).reduce((a, b) => a + b, 0)
    readonly property var history: saved.history ? saved.history.split(",") : []

    function randomValue() {
        return 1 + Math.floor(Math.random() * saved.sides)
    }

    function rollAll() {
        const v = []
        for (let i = 0; i < saved.count; i++) {
            v.push(randomValue())
            const die = dice.itemAt(i) as Die
            die.roll(v[i], i * 70)
        }
        values = v
        // Into the history once the last die lands, not before.
        remember.interval = (saved.count - 1) * 70 + 600
        remember.restart()
    }

    Timer {
        id: remember
        onTriggered: saved.history = [String(app.total)].concat(app.history).slice(0, 8).join(",")
    }

    function rollOne(i) {
        const v = values.slice()
        v[i] = randomValue()
        const die = dice.itemAt(i) as Die
        die.roll(v[i], 0)
        values = v
    }

    Component.onCompleted: {
        const v = []
        for (let i = 0; i < 6; i++)
            v.push(1 + Math.floor(Math.random() * saved.sides))
        values = v
    }

    // A rounded button with a label.
    component Button: Rectangle {
        id: btn
        property string label
        property bool active: false
        property real fontSize: 34
        signal clicked()
        radius: 24 * app.s
        color: press.pressed ? "#4a4f60" : active ? "#6b2fb3" : "#1b1d24"
        border.color: active ? "#8a5cf0" : "#3a3e4d"
        border.width: 2 * app.s
        Text {
            anchors.centerIn: parent
            text: btn.label
            color: "#eef0f4"
            font { family: "Noto Sans"; pixelSize: btn.fontSize * app.s; weight: Font.DemiBold }
        }
        TapHandler {
            id: press
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: btn.clicked()
        }
    }

    // Title, the total, close.
    Item {
        id: header
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 40 * app.s }
        height: 100 * app.s
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "Dice"
            color: "#eef0f4"
            font { family: "Noto Sans"; pixelSize: 60 * app.s; weight: Font.Bold }
        }
        Text {
            anchors.centerIn: parent
            text: app.rolling ? "…" : "Total  " + app.total
            color: "#cfe0ff"
            font { family: "Noto Sans"; pixelSize: 56 * app.s; weight: Font.DemiBold }
        }
        Button {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            width: 96 * app.s
            height: 96 * app.s
            label: "✕"
            onClicked: app.barry.close()
        }
    }

    // Which die, and how many.
    Row {
        id: choices
        anchors { horizontalCenter: parent.horizontalCenter; top: header.bottom; topMargin: 30 * app.s }
        spacing: 14 * app.s
        Repeater {
            model: app.kinds
            delegate: Button {
                required property int modelData
                width: 120 * app.s
                height: 96 * app.s
                label: "d" + modelData
                active: saved.sides === modelData
                onClicked: {
                    saved.sides = modelData
                    app.rollAll()
                }
            }
        }
        Item { width: 30 * app.s; height: 1 }
        Button {
            width: 96 * app.s
            height: 96 * app.s
            label: "−"
            fontSize: 48
            onClicked: saved.count = Math.max(1, saved.count - 1)
        }
        Text {
            width: 80 * app.s
            height: 96 * app.s
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: saved.count
            color: "#eef0f4"
            font { family: "Noto Sans"; pixelSize: 48 * app.s; weight: Font.Bold }
        }
        Button {
            width: 96 * app.s
            height: 96 * app.s
            label: "+"
            fontSize: 48
            onClicked: saved.count = Math.min(6, saved.count + 1)
        }
    }

    // The dice, in the space between the choices and Roll: tap one to roll
    // it alone.
    Item {
        anchors { left: parent.left; right: parent.right; top: choices.bottom; bottom: rollButton.top }
        Grid {
            anchors.centerIn: parent
            columns: saved.count === 4 ? 2 : Math.min(3, saved.count)
            spacing: 40 * app.s
            Repeater {
                id: dice
                model: 6
                delegate: Die {
                    required property int index
                    visible: index < saved.count
                    s: app.s
                    sides: saved.sides
                    value: app.values[index] || 1
                    onTapped: app.rollOne(index)
                }
            }
        }
    }

    // Roll, and the last totals.
    Button {
        id: rollButton
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 110 * app.s }
        width: 520 * app.s
        height: 130 * app.s
        radius: 40 * app.s
        label: "Roll"
        fontSize: 52
        active: true
        onClicked: app.rollAll()
    }
    Text {
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 40 * app.s }
        visible: app.history.length > 0
        text: "Last rolls:  " + app.history.join("  ·  ")
        color: "#eef0f4"
        opacity: 0.5
        font { family: "Noto Sans"; pixelSize: 28 * app.s }
    }
}

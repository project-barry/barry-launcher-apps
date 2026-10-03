// One die. A d6 shows pips; the others show their number, with the kind of
// die under it. roll() tumbles it and lands it on a new value.
pragma ComponentBehavior: Bound
import QtQuick

Item {
    id: die
    property int sides: 6
    property int value: 1         // where it lands
    property real s: 1            // the app's scale (barry.scale)
    readonly property bool rolling: tumble.running
    property int shown: value     // what the face shows, flickering while it rolls
    signal tapped()

    width: 220 * s
    height: 220 * s

    // Tumble for a moment, then land on newValue. delay staggers the dice.
    function roll(newValue, delay) {
        tumble.stop()
        const before = shown
        value = newValue
        shown = before  // the face keeps its old value until it lands
        pause.duration = delay
        spin.to = (Math.random() < 0.5 ? -1 : 1) * 360  // a whole turn: it lands square
        tumble.start()
    }

    Rectangle {
        id: face
        anchors.fill: parent
        radius: 40 * die.s
        color: tap.pressed ? "#2a2140" : "#1b1d24"
        border.color: die.rolling ? "#8a5cf0" : "#3a3e4d"
        border.width: 4 * die.s

        // Pips of a d6, on a 3 x 3 grid.
        Repeater {
            model: die.sides === 6 ? 9 : 0
            delegate: Rectangle {
                required property int index
                readonly property var lit: [[4], [0, 8], [0, 4, 8], [0, 2, 6, 8], [0, 2, 4, 6, 8], [0, 2, 3, 5, 6, 8]]
                visible: lit[Math.max(0, Math.min(5, die.shown - 1))].indexOf(index) >= 0
                width: 40 * die.s
                height: width
                radius: width / 2
                color: "#eef0f4"
                // Three columns 60 apart, centred: (220 - 2 * 60 - 40) / 2 = 30.
                x: (30 + (index % 3) * 60) * die.s
                y: (30 + Math.floor(index / 3) * 60) * die.s
            }
        }

        Text {
            visible: die.sides !== 6
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -12 * die.s
            text: die.shown
            color: "#eef0f4"
            font { family: "Noto Sans"; pixelSize: 100 * die.s; weight: Font.Bold }
        }
        Text {
            visible: die.sides !== 6
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 18 * die.s
            text: "d" + die.sides
            color: "#8a5cf0"
            font { family: "Noto Sans"; pixelSize: 30 * die.s; weight: Font.DemiBold }
        }
    }

    TapHandler {
        id: tap
        onTapped: die.tapped()
    }

    // While it tumbles, the face shows random values.
    Timer {
        id: flicker
        interval: 55
        repeat: true
        onTriggered: die.shown = 1 + Math.floor(Math.random() * die.sides)
    }

    SequentialAnimation {
        id: tumble
        PauseAnimation { id: pause; duration: 0 }
        ScriptAction { script: flicker.start() }
        ParallelAnimation {
            RotationAnimation { id: spin; target: face; property: "rotation"; from: 0; duration: 560; easing.type: Easing.OutCubic }
            SequentialAnimation {
                NumberAnimation { target: face; property: "scale"; to: 0.8; duration: 140; easing.type: Easing.InQuad }
                // The landing: a bounce past full size and back.
                NumberAnimation { target: face; property: "scale"; to: 1; duration: 420; easing.type: Easing.OutBack; easing.overshoot: 3 }
            }
        }
        ScriptAction {
            script: {
                flicker.stop()
                face.rotation = 0
                die.shown = die.value
            }
        }
    }
}

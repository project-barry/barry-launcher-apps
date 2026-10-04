// Barry Simulator's window: the apps it found (like Barry Launcher's home
// screen), and for the selected one: open, restart, stand-in games, its
// data and its log. The apps open in windows of their own. `sim` is sim.py.
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Dialogs
import QtQuick.Layouts

ApplicationWindow {
    id: win
    width: 1180
    height: 760
    minimumWidth: 900
    minimumHeight: 560
    visible: true
    title: "Barry Simulator"
    color: "black"

    // Barry Launcher's palette.
    readonly property color panel: "#1b1d24"
    readonly property color line: "#3a3e4d"
    readonly property color pressedColor: "#4a4f60"
    readonly property color accent: "#6b2fb3"
    readonly property color accentLight: "#8a5cf0"
    readonly property color text: "#eef0f4"
    readonly property color soft: "#9aa0b0"
    readonly property color good: "#4fc46b"
    readonly property color bad: "#ff6b6b"
    readonly property string family: "Noto Sans"
    readonly property var app: sim.apps.find(a => a.key === sim.selected) || null

    component Btn: Button {
        id: b
        property bool primary: false
        property bool danger: false
        implicitHeight: 38
        leftPadding: 16
        rightPadding: 16
        font { family: win.family; pixelSize: 14; weight: Font.DemiBold }
        contentItem: Text {
            text: b.text
            font: b.font
            color: b.enabled ? win.text : win.soft
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
        background: Rectangle {
            radius: 10
            color: b.down ? win.pressedColor : b.primary ? win.accent : b.danger ? "#3a1d24" : win.panel
            border.color: b.primary ? win.accentLight : b.danger ? "#8a3a48" : win.line
            border.width: 1
            opacity: b.enabled ? 1 : 0.5
        }
    }

    component Caption: Text {
        color: win.soft
        font { family: win.family; pixelSize: 12; weight: Font.DemiBold; capitalization: Font.AllUppercase }
    }

    FolderDialog {
        id: folderDialog
        title: "An app folder, or a folder to search for apps"
        onAccepted: sim.addFolder(selectedFolder.toString())
    }
    FileDialog {
        id: zipDialog
        title: "Install a Barry Launcher app"
        nameFilters: ["Barry Launcher apps (*.zip *.tar.gz *.tgz *.tar.xz)", "All files (*)"]
        onAccepted: sim.install(selectedFile.toString())
    }

    header: Rectangle {
        height: 64
        color: win.panel
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: win.line }
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 16
            spacing: 10
            Column {
                Text {
                    text: "Barry Simulator"
                    color: win.text
                    font { family: win.family; pixelSize: 20; weight: Font.Bold }
                }
                Text {
                    text: "Barry Launcher apps in windows shaped like the AYN Thor's bottom screen"
                    color: win.soft
                    font { family: win.family; pixelSize: 12 }
                }
            }
            Item { Layout.fillWidth: true }
            Btn { text: "Add folder…"; onClicked: folderDialog.open() }
            Btn { text: "Install .zip…"; onClicked: zipDialog.open() }
            Btn { text: "Rescan"; onClicked: sim.rescan() }
        }
    }

    footer: Rectangle {
        height: 52
        color: win.panel
        Rectangle { width: parent.width; height: 1; color: win.line }
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 16
            spacing: 12
            Text {
                text: "Window size"
                color: win.text
                font { family: win.family; pixelSize: 14; weight: Font.DemiBold }
            }
            Repeater {
                model: [0.5, 0.6, 0.75, 0.9, 1]
                Btn {
                    required property real modelData
                    text: Math.round(modelData * 100) + "%"
                    primary: Math.abs(sim.scale - modelData) < 0.001
                    implicitHeight: 32
                    onClicked: sim.scale = modelData
                }
            }
            Text {
                text: Math.round(1240 * sim.scale) + " × " + Math.round(1080 * sim.scale)
                      + (sim.scale === 1 ? "  (the Thor's pixels)" : "")
                color: win.soft
                font { family: win.family; pixelSize: 13 }
            }
            Item { Layout.fillWidth: true }
            CheckBox {
                id: reload
                checked: sim.autoReload
                onToggled: sim.autoReload = checked
                text: "Restart an open app when its files change"
                contentItem: Text {
                    leftPadding: reload.indicator.width + 8
                    text: reload.text
                    color: win.text
                    verticalAlignment: Text.AlignVCenter
                    font { family: win.family; pixelSize: 13 }
                }
            }
            Text {
                text: sim.message
                color: win.soft
                font { family: win.family; pixelSize: 13 }
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        // The apps, as tiles. Click: select. Double-click: open.
        ColumnLayout {
            Layout.fillHeight: true
            Layout.fillWidth: false
            Layout.preferredWidth: (parent.width - 16) * 0.48
            spacing: 8
            Caption { text: "Apps" }
            GridView {
                id: grid
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                cellWidth: width / Math.max(1, Math.floor(width / 150))
                cellHeight: 170
                model: sim.apps
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar {}
                delegate: Item {
                    id: tile
                    required property var modelData
                    readonly property bool chosen: modelData.key === sim.selected
                    width: grid.cellWidth
                    height: grid.cellHeight
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 5
                        radius: 16
                        color: tileMouse.pressed ? win.pressedColor : tile.chosen ? "#26203a" : win.panel
                        border.color: tile.chosen ? win.accentLight : win.line
                        border.width: tile.chosen ? 2 : 1
                        Column {
                            anchors.centerIn: parent
                            width: parent.width - 16
                            spacing: 6
                            Item {
                                width: 72
                                height: 72
                                anchors.horizontalCenter: parent.horizontalCenter
                                Image {
                                    anchors.fill: parent
                                    source: tile.modelData.icon
                                    sourceSize: Qt.size(144, 144)
                                    visible: status === Image.Ready
                                }
                                Rectangle {
                                    anchors.fill: parent
                                    radius: 16
                                    visible: !tile.modelData.icon
                                    color: tile.modelData.error ? "#3a1d24" : win.accent
                                    Text {
                                        anchors.centerIn: parent
                                        text: tile.modelData.error ? "!" : tile.modelData.name.charAt(0)
                                        color: win.text
                                        font { family: win.family; pixelSize: 34; weight: Font.Bold }
                                    }
                                }
                                Rectangle {
                                    visible: tile.modelData.running
                                    anchors { right: parent.right; top: parent.top; margins: -4 }
                                    width: 18; height: 18; radius: 9
                                    color: win.good
                                    border { color: "black"; width: 3 }
                                }
                            }
                            Text {
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                text: tile.modelData.name
                                color: win.text
                                elide: Text.ElideRight
                                font { family: win.family; pixelSize: 15; weight: Font.DemiBold }
                            }
                            Text {
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                text: tile.modelData.error ? "won't install"
                                    : tile.modelData.source === "installed" ? "installed " + tile.modelData.version
                                    : tile.modelData.version + " · " + tile.modelData.source
                                color: tile.modelData.error ? win.bad : win.soft
                                elide: Text.ElideRight
                                font { family: win.family; pixelSize: 11 }
                            }
                        }
                        MouseArea {
                            id: tileMouse
                            anchors.fill: parent
                            onClicked: sim.select(tile.modelData.key)
                            onDoubleClicked: sim.launch(tile.modelData.key)
                        }
                    }
                }
                Text {
                    anchors.centerIn: parent
                    width: parent.width * 0.8
                    visible: grid.count === 0
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                    text: "No apps found. Add a folder that has app folders in it (each with a barry-app.json), "
                        + "or install a .zip."
                    color: win.soft
                    font { family: win.family; pixelSize: 15 }
                }
            }
            Text {
                Layout.fillWidth: true
                text: "Searching: " + (sim.searched.length ? sim.searched.join(", ") : "nothing yet")
                      + "   ·   Installed apps and app data: " + sim.supportFolder
                color: win.soft
                elide: Text.ElideMiddle
                font { family: win.family; pixelSize: 11 }
            }
        }

        // The selected app.
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 18
            color: win.panel
            border.color: win.line
            Text {
                anchors.centerIn: parent
                visible: !win.app
                text: "Select an app"
                color: win.soft
                font { family: win.family; pixelSize: 16 }
            }
            ColumnLayout {
                visible: !!win.app
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12

                RowLayout {
                    spacing: 14
                    Image {
                        Layout.preferredWidth: 56
                        Layout.preferredHeight: 56
                        source: win.app ? win.app.icon : ""
                        sourceSize: Qt.size(112, 112)
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            Layout.fillWidth: true
                            text: win.app ? win.app.name + "  " + win.app.version : ""
                            color: win.text
                            elide: Text.ElideRight
                            font { family: win.family; pixelSize: 20; weight: Font.Bold }
                        }
                        Text {
                            Layout.fillWidth: true
                            text: win.app ? (win.app.id || "") + (win.app.service ? "  ·  with a service" : "")
                                            + (win.app.type === "web" ? "  ·  web app (opens in Firefox)" : "") : ""
                            color: win.soft
                            elide: Text.ElideRight
                            font { family: win.family; pixelSize: 12 }
                        }
                        Text {
                            Layout.fillWidth: true
                            text: win.app ? win.app.path : ""
                            color: win.soft
                            elide: Text.ElideMiddle
                            font { family: win.family; pixelSize: 12 }
                        }
                    }
                }
                Text {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: win.app ? (win.app.error || win.app.description) : ""
                    color: win.app && win.app.error ? win.bad : win.text
                    wrapMode: Text.Wrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                    font { family: win.family; pixelSize: 13 }
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: 8
                    Btn {
                        text: win.app && win.app.running ? "Close" : "Open"
                        primary: !(win.app && win.app.running)
                        enabled: !!win.app && !win.app.error
                        onClicked: win.app.running ? sim.stop(win.app.key) : sim.launch(win.app.key)
                    }
                    Btn {
                        text: "Restart"
                        enabled: !!win.app && win.app.running
                        onClicked: sim.restart(win.app.key)
                    }
                    Btn { text: "Show folder"; onClicked: sim.showFolder(win.app.key) }
                    Btn { text: "Show data"; enabled: !!win.app && !win.app.error; onClicked: sim.showData(win.app.key) }
                    Btn {
                        id: clearBtn
                        text: confirmClear ? "Really clear it?" : "Clear data"
                        property bool confirmClear: false
                        danger: confirmClear
                        enabled: !!win.app && !win.app.error
                        onClicked: {
                            if (confirmClear) { sim.clearData(win.app.key); confirmClear = false }
                            else confirmClear = true
                        }
                        Connections {
                            target: sim
                            function onSelectedChanged() { clearBtn.confirmClear = false }
                        }
                    }
                    Btn {
                        visible: !!win.app && win.app.source === "installed"
                        text: "Uninstall"
                        danger: true
                        onClicked: sim.uninstall(win.app.key)
                    }
                }

                // Stand-in games from the app's repository (tools/fake_*.py).
                ColumnLayout {
                    Layout.fillWidth: true
                    visible: !!win.app && win.app.helpers.length > 0
                    spacing: 6
                    Caption { text: "Stand-in games" }
                    Repeater {
                        model: win.app ? win.app.helpers : []
                        RowLayout {
                            id: helperRow
                            required property string modelData
                            required property int index
                            readonly property bool on: win.app && win.app.helpersRunning[index]
                            spacing: 10
                            Rectangle { width: 10; height: 10; radius: 5; color: helperRow.on ? win.good : win.line }
                            Text {
                                Layout.fillWidth: true
                                text: helperRow.modelData.split(/[\\/]/).pop()
                                color: win.text
                                font { family: win.family; pixelSize: 14 }
                            }
                            Btn {
                                text: helperRow.on ? "Stop" : "Start"
                                implicitHeight: 32
                                onClicked: sim.toggleHelper(win.app.key, helperRow.modelData)
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Caption { text: "Log (the app, its service and stand-ins)"; Layout.fillWidth: true }
                    Btn { text: "Copy"; implicitHeight: 28; onClicked: sim.copyLog("") }
                    Btn { text: "Clear"; implicitHeight: 28; onClicked: sim.clearLog() }
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 10
                    color: "#0b0c10"
                    border.color: win.line
                    ScrollView {
                        id: logScroll
                        anchors.fill: parent
                        anchors.margins: 8
                        TextArea {
                            id: logText
                            readOnly: true
                            selectByMouse: true
                            wrapMode: TextEdit.WrapAnywhere
                            text: sim.log
                            color: "#cfd3dc"
                            font { family: Qt.platform.os === "windows" ? "Consolas" : "Menlo"; pixelSize: 12 }
                            background: null
                            placeholderText: "Nothing yet. Open the app to see what it prints, and any QML errors."
                            placeholderTextColor: win.soft
                            onTextChanged: cursorPosition = length
                        }
                    }
                }
            }
        }
    }
}

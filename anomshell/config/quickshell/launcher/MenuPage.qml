import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property var    items:       []
    property var    theme:       ({})
    property string title:       ""
    property string searchText:  ""

    signal itemActivated(var item)
    signal backRequested

    property var filteredItems: []
    property int selectedIdx:   0

    onItemsChanged:      Qt.callLater(applyFilter)
    onSearchTextChanged: Qt.callLater(applyFilter)

    function applyFilter() {
        var q = searchText.trim().toLowerCase()
        var out = []
        for (var i = 0; i < items.length; i++) {
            if (q === "" || items[i].label.toLowerCase().indexOf(q) !== -1)
                out.push(items[i])
        }
        filteredItems = out
        selectedIdx = 0
        listView.positionViewAtIndex(0, ListView.Beginning)
    }

    function moveDown() {
        if (selectedIdx < filteredItems.length - 1) {
            selectedIdx++
            listView.positionViewAtIndex(selectedIdx, ListView.Contain)
        }
    }

    function moveUp() {
        if (selectedIdx > 0) {
            selectedIdx--
            listView.positionViewAtIndex(selectedIdx, ListView.Contain)
        }
    }

    function activateSelected() {
        if (filteredItems.length > 0)
            root.itemActivated(filteredItems[selectedIdx])
    }

    ListView {
        id:           listView
        anchors.fill: parent
        model:        root.filteredItems
        spacing:      2
        clip:         true

        delegate: Item {
            id:     delegateRoot
            width:  listView.width
            height: 32

            property bool isSelected: index === root.selectedIdx
            property var  mitem:      root.filteredItems[index] || {}

            // fade + slide in on appear
            opacity: 0
            transform: Translate { id: delegateTx; x: -6 }

            Component.onCompleted: {
                appearDelay.interval = index * 18
                appearDelay.start()
            }

            Timer {
                id:       appearDelay
                repeat:   false
                onTriggered: appearAnim.start()
            }

            ParallelAnimation {
                id: appearAnim
                NumberAnimation {
                    target:   delegateRoot
                    property: "opacity"
                    from:     0; to: 1
                    duration: 160
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target:   delegateTx
                    property: "x"
                    from:     -6; to: 0
                    duration: 160
                    easing.type: Easing.OutCubic
                }
            }

            Rectangle {
                id:              itemBg
                anchors.fill:    parent
                anchors.margins: 1
                radius:          7
                color: isSelected
                    ? Qt.alpha(theme.accent || "#89b4fa", 0.18)
                    : "transparent"

                Behavior on color {
                    ColorAnimation { duration: 120; easing.type: Easing.OutCubic }
                }

                // left accent bar
                Rectangle {
                    width:   2
                    height:  isSelected ? 16 : 0
                    radius:  1
                    color:   theme.accent || "#89b4fa"
                    anchors.left:           parent.left
                    anchors.leftMargin:     3
                    anchors.verticalCenter: parent.verticalCenter

                    Behavior on height {
                        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                    }
                    Behavior on opacity {
                        NumberAnimation { duration: 150 }
                    }
                }

                Row {
                    anchors.fill:       parent
                    anchors.leftMargin: 14
                    spacing:            10

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text:           mitem.icon || ""
                        color:          isSelected
                            ? (theme.accent || "#89b4fa")
                            : Qt.alpha(theme.fg || "#cdd6f4", 0.55)
                        font.pixelSize: 13
                        font.family:    "JetBrainsMono Nerd Font", "Omarchy"
                        width:          20

                        Behavior on color {
                            ColorAnimation { duration: 120 }
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text:           mitem.label || ""
                        color:          isSelected
                            ? (theme.fg || "#cdd6f4")
                            : Qt.alpha(theme.fg || "#cdd6f4", 0.75)
                        font.pixelSize: 12
                        font.family:    "JetBrainsMono Nerd Font"
                        font.weight:    isSelected ? Font.Medium : Font.Normal

                        Behavior on color {
                            ColorAnimation { duration: 120 }
                        }
                    }
                }

                // chevron for submenus
                Text {
                    anchors.right:          parent.right
                    anchors.rightMargin:    10
                    anchors.verticalCenter: parent.verticalCenter
                    visible:                mitem.children !== undefined
                    text:                   ""
                    color:                  Qt.alpha(theme.muted || "#585b70", isSelected ? 0.8 : 0.4)
                    font.pixelSize:         10
                    font.family:            "JetBrainsMono Nerd Font"

                    Behavior on color {
                        ColorAnimation { duration: 120 }
                    }

                    // nudge right on select
                    transform: Translate {
                        x: isSelected ? 2 : 0
                        Behavior on x {
                            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                        }
                    }
                }

                // terminal indicator
                Text {
                    anchors.right:          parent.right
                    anchors.rightMargin:    10
                    anchors.verticalCenter: parent.verticalCenter
                    visible:                mitem.terminal !== undefined && mitem.children === undefined
                    text:                   "󰆍"
                    color:                  Qt.alpha(theme.muted || "#585b70", isSelected ? 0.6 : 0.3)
                    font.pixelSize:         10
                    font.family:            "JetBrainsMono Nerd Font"

                    Behavior on color {
                        ColorAnimation { duration: 120 }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape:  Qt.PointingHandCursor
                onEntered:    root.selectedIdx = index
                onClicked:    root.itemActivated(mitem)
            }
        }

        Behavior on contentY {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }
    }
}
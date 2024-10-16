import QtQuick 2.7
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3

Dialog {
    id: dialog
    signal doAction()

    Rectangle {
        anchors.fill: parent
        color: "white"  // Background color for visibility
        border.color: "gray"

        Column {
            spacing: units.gu(1)
            anchors.fill: parent
            anchors.horizontalCenter: parent.horizontalCenter

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: i18n.tr("Are you sure you want to proceed?")
            }

            Row {
                spacing: units.gu(1)
                anchors.horizontalCenter: parent.horizontalCenter

                Button {
                    text: i18n.tr("OK")
                    color: theme.palette.normal.negative
                    onClicked: {
                        doAction(); // Emit the signal before closing
                        PopupUtils.close(dialog);
                    }
                }

                Button {
                    text: i18n.tr("Cancel")
                    onClicked: PopupUtils.close(dialog);
                }
            }
        }
    }

    // Here is the handler for the signal, outside the Row
    onDoAction: {
        shoppinglistModel.removeSelectedItems();  // Call function to remove selected items
        root.selectionMode = false;  // Exit selection mode after action
    }
}


/*
 * Copyright (C) 2024  Samarth Bahey
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * shoppinglist is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
import QtQuick 2.7
import Lomiri.Components 1.3
import QtQuick.Layouts 1.3
import Ubuntu.Components 1.3
import QtQuick.LocalStorage 2.7
import QtQuick.Dialogs 1.2
import Ubuntu.Components.Popups 1.3

MainView {
    id: root
    objectName: 'mainView'
    applicationName: 'shoppinglist.samarthbahey'
    automaticOrientation: true
    property bool isLoggedIn: false  // Property to track login status

    // Model for shopping list items, moved outside to ensure it's initialized properly
    ListModel {
        id: shoppinglistModel
    }

    // Loader to switch between login page and shopping list page
    Loader {
        id: pageLoader
        anchors.fill: parent
        sourceComponent: isLoggedIn ? shoppingListPage : loginPage  // Switch based on login status
    }

    // Function to initialize the shopping list from the database
    function initializeShoppingList() {
        var db = LocalStorage.openDatabaseSync("ShoppingListDB", "1.0", "Shopping List Database", 1000000);
        db.transaction(function(tx) {
            tx.executeSql("CREATE TABLE IF NOT EXISTS items (id INTEGER PRIMARY KEY, name TEXT, selected INTEGER, price TEXT)");
            tx.executeSql("SELECT * FROM items", [], function(tx, results) {
                for (var i = 0; i < results.rows.length; i++) {
                    shoppinglistModel.append({ name: results.rows.item(i).name, selected: results.rows.item(i).selected === 1, price: results.rows.item(i).price });
                }
            });
        });
    }

    // Function to add an item to the database
    function addItemToDatabase(name, selected, price) {
        var db = LocalStorage.openDatabaseSync("ShoppingListDB", "1.0", "Shopping List Database", 1000000);
        db.transaction(function(tx) {
            tx.executeSql("INSERT INTO items (name, selected, price) VALUES (?, ?, ?)", [name, selected ? 1 : 0, price]);
        });
    }

    // Function to update the selected state in the database
    function updateItemSelection(name, selected) {
        var db = LocalStorage.openDatabaseSync("ShoppingListDB", "1.0", "Shopping List Database", 1000000);
        db.transaction(function(tx) {
            tx.executeSql("UPDATE items SET selected = ? WHERE name = ?", [selected ? 1 : 0, name]);
        });
    }

    // Function to delete an item from the database
    function deleteItemFromDatabase(name) {
        var db = LocalStorage.openDatabaseSync("ShoppingListDB", "1.0", "Shopping List Database", 1000000);
        db.transaction(function(tx) {
            tx.executeSql("DELETE FROM items WHERE name = ?", [name]);
        });
    }

    // Login Page
    Component {
        id: loginPage
        Rectangle {
            width: parent.width
            height: parent.height
            color: "lightgray"
            Column {
                anchors.centerIn: parent
                spacing: units.gu(2)

                Text {
                    text: "Welcome to Shopping List"
                    font.pixelSize: units.gu(4)
                }

                TextField {
                    id: usernameField
                    placeholderText: "Username"
                }

                TextField {
                    id: passwordField
                    placeholderText: "Password"
                    echoMode: TextInput.Password
                }

                Button {
                    text: "Login"
                    onClicked: {
                        if (usernameField.text.length > 0 && passwordField.text.length > 0) {
                            isLoggedIn = true;  // Switch to the shopping list page on login
                        } else {
                            console.log("Please enter valid credentials");
                        }
                    }
                }
            }
        }
    }

    // Shopping List Page
    Component {
        id: shoppingListPage
        Page {
            anchors.fill: parent
            Component.onCompleted: initializeShoppingList()  // Initialize the shopping list from the database

            header: PageHeader {
                id: pageHeader
                title: i18n.tr('Shopping List')
                subtitle: i18n.tr('Never forget what to buy')
                ActionBar {
                    anchors {
                        top: parent.top
                        right: parent.right
                        topMargin: units.gu(1)
                        rightMargin: units.gu(1)
                    }
                    numberOfSlots: 2
                    actions: [
                        Action {
                            iconName: "settings"
                            text: i18n.tr("Settings")
                        },
                        Action {
                            iconName: "info"
                            text: i18n.tr("About")
                            onTriggered: PopupUtils.open(aboutDialog)  // Open the about dialog using PopupUtils
                        }
                    ]
                }
                StyleHints {
                    foregroundColor: UbuntuColors.orange
                }
            }

            TextField {
                id: textFieldInput
                anchors {
                    top: pageHeader.bottom
                    left: parent.left
                    topMargin: units.gu(2)
                    leftMargin: units.gu(2)
                }
                placeholderText: i18n.tr('Shopping list item')
            }

            Button {
                id: buttonAdd
                anchors {
                    top: pageHeader.bottom
                    right: parent.right
                    topMargin: units.gu(2)
                    rightMargin: units.gu(2)
                }
                text: i18n.tr('Add')
                onClicked: {
                    if (textFieldInput.text.length > 0) {
                        shoppinglistModel.append({ name: textFieldInput.text, selected: false, price: "0.00" });
                        addItemToDatabase(textFieldInput.text, false, "0.00");  // Add to the database
                        textFieldInput.text = "";  // Clear the input after adding
                    }
                }
            }

            ListView {
                id: shoppinglistView
                anchors {
                    top: textFieldInput.bottom
                    bottom: parent.bottom
                    left: parent.left
                    right: parent.right
                    topMargin: units.gu(2)
                }
                model: shoppinglistModel
                delegate: ListItem {
                    width: parent.width
                    height: units.gu(3)

                    Rectangle {
                        anchors.fill: parent
                        color: index % 2 ? theme.palette.normal.selection : theme.palette.normal.background

                        CheckBox {
                            id: itemCheckbox
                            visible: true
                            checked: shoppinglistModel.get(index).selected
                            anchors {
                                left: parent.left
                                leftMargin: units.gu(2)
                                verticalCenter: parent.verticalCenter
                            }
                            onClicked: {
                                shoppinglistModel.get(index).selected = !shoppinglistModel.get(index).selected;
                                updateItemSelection(shoppinglistModel.get(index).name, shoppinglistModel.get(index).selected);
                            }
                        }

                        Text {
                            id: itemText
                            text: shoppinglistModel.get(index).name
                            anchors {
                                left: itemCheckbox.right
                                leftMargin: units.gu(1)
                                verticalCenter: parent.verticalCenter
                            }
                        }

                        Text {
                            text: shoppinglistModel.get(index).price + " $"
                            anchors {
                                right: parent.right
                                rightMargin: units.gu(2)
                                verticalCenter: parent.verticalCenter
                            }
                        }
                    }

                    leadingActions: ListItemActions {
                        actions: [
                            Action {
                                iconName: "delete"
                                onTriggered: {
                                    deleteItemFromDatabase(shoppinglistModel.get(index).name);
                                    shoppinglistModel.remove(index);  // Remove the item
                                }
                            }
                        ]
                    }
                }
            }

            // Buttons for removing selected items, removing all items, and checkout
            Row {
                anchors {
                    bottom: parent.bottom
                    left: parent.left
                    bottomMargin: units.gu(2)
                    leftMargin: units.gu(2)
                }
                spacing: units.gu(2)

                Button {
                    text: "Remove"
                    onClicked: {
                        for (var i = shoppinglistModel.count - 1; i >= 0; i--) {
                            if (shoppinglistModel.get(i).selected) {
                                deleteItemFromDatabase(shoppinglistModel.get(i).name);
                                shoppinglistModel.remove(i);
                            }
                        }
                    }
                }

                Button {
                    text: "Remove All"
                    onClicked: {
                        shoppinglistModel.clear();  // Clear the model
                        var db = LocalStorage.openDatabaseSync("ShoppingListDB", "1.0", "Shopping List Database", 1000000);
                        db.transaction(function(tx) {
                            tx.executeSql("DELETE FROM items");  // Clear all items from the database
                        });
                    }
                }

                Button {
                    text: "Checkout to Cart"
                    onClicked: {
                        console.log("Checked out to cart!");  // Simple checkout action
                    }
                }
            }
        }
    }

    Component {
        id: aboutDialog
        AboutDialog {
            title: "About Shopping List"
            text: "This app was developed by Samarth Bahey."
        }
    }

    // PopupUtils to handle dialog operations
    QtObject {
        id: popuputils

        // Function to open any given popup component
        function open(popup) {
            if (popup) {
                popup.open();
            }
        }

        function close(popup) {
            if (popup) {
                popup.close();
            }
        }
    }
}

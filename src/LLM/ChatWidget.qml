import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Basic

import QGroundControl
import QGroundControl.Controls
import QGC

Rectangle {
    id: root

    property var activeVehicle: null

    color: qgcPal.window
    radius: 4
    border.color: qgcPal.text
    border.width: 1

    width: 400
    height: 300

    property real minWidth: 300
    property real minHeight: 200

    QGCPalette { id: qgcPal; colorGroupEnabled: true }

    LLMClient {
        id: llmClient
        apiKey: QGroundControl.settingsManager.appSettings.llmApiKey.value
        onResponseReceived: (response) => {
            chatModel.append({ "role": "assistant", "content": response })
        }
        onErrorOccurred: (error) => {
            chatModel.append({ "role": "system", "content": "Error: " + error })
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 5

        ListView {
            id: chatView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: ListModel { id: chatModel }

            delegate: Rectangle {
                width: ListView.view.width
                height: msgText.paintedHeight + 10
                color: "transparent"

                Text {
                    id: msgText
                    width: parent.width
                    text: (model.role === "user" ? "You: " : (model.role === "assistant" ? "AI: " : "")) + model.content
                    color: model.role === "system" ? "red" : qgcPal.text
                    wrapMode: Text.Wrap
                    font.pointSize: 10
                }
            }

            onCountChanged: chatView.positionViewAtEnd()
        }

        RowLayout {
            Layout.fillWidth: true

            TextField {
                id: inputField
                Layout.fillWidth: true
                placeholderText: qsTr("Ask about vehicle status...")
                color: qgcPal.text
                background: Rectangle {
                    color: qgcPal.windowShade
                    border.color: qgcPal.text
                }
                onAccepted: sendButton.clicked()
            }

            Button {
                id: sendButton
                text: qsTr("Send")
                onClicked: {
                    if (inputField.text.trim() === "") return;

                    var prompt = inputField.text;
                    chatModel.append({ "role": "user", "content": prompt });
                    inputField.text = "";

                    var context = buildContext();
                    llmClient.sendMessage(prompt, context);
                }
            }
        }
    }

    function buildContext() {
        if (!activeVehicle) return "No active vehicle.";

        var ctx = "Vehicle Context:\n";
        ctx += "ID: " + activeVehicle.id + "\n";
        ctx += "Flight Mode: " + activeVehicle.flightMode + "\n";
        ctx += "Armed: " + activeVehicle.armed + "\n";

        // Add more fields as needed, e.g., battery, location, altitude
        // Note: These properties must be available on the Vehicle QML object

    }

    MouseArea {
        id: resizeHandle
        width: 20
        height: 20
        anchors.right: parent.right
        anchors.top: parent.top
        cursorShape: Qt.SizeBDiagCursor
        z: 100

        property point lastGlobalPos

        onPressed: (mouse) => {
            lastGlobalPos = mapToGlobal(mouse.x, mouse.y)
        }

        onPositionChanged: (mouse) => {
            if (pressed) {
                var currentGlobalPos = mapToGlobal(mouse.x, mouse.y)
                var deltaX = currentGlobalPos.x - lastGlobalPos.x
                var deltaY = currentGlobalPos.y - lastGlobalPos.y

                var newWidth = root.width + deltaX
                var newHeight = root.height - deltaY // Dragging UP (negative deltaY) increases height

                if (newWidth >= minWidth) {
                    root.width = newWidth
                }
                if (newHeight >= minHeight) {
                    root.height = newHeight
                }
                lastGlobalPos = currentGlobalPos
            }
        }

        Rectangle {
            anchors.fill: parent
            color: qgcPal.button
            opacity: 0.5
            radius: 2

            // Draw a diagonal resize indicator
            Canvas {
                anchors.fill: parent
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.strokeStyle = qgcPal.buttonText
                    ctx.lineWidth = 2
                    ctx.beginPath()
                    ctx.moveTo(width * 0.2, height * 0.8)
                    ctx.lineTo(width * 0.8, height * 0.2)
                    ctx.stroke()
                }
            }
        }
    }
}

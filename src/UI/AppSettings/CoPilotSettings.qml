import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.FactControls
import QGroundControl.Controls

SettingsPage {
    property var    _settingsManager:   QGroundControl.settingsManager
    property var    _appSettings:       _settingsManager.appSettings
    property Fact   _llmApiKey:         _appSettings.llmApiKey

    SettingsGroupLayout {
        Layout.fillWidth: true
        heading: qsTr("Co-pilot Settings")

        LabelledFactTextField {
            Layout.fillWidth:   true
            label:              qsTr("LLM API Key")
            fact:               _llmApiKey
            visible:            _llmApiKey.visible
        }

        QGCLabel {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: qsTr("Enter your OpenAI API Key here to enable the LLM Chat feature in Fly View.")
            font.pointSize: ScreenTools.smallFontPointSize
        }
    }
}

Function init()
  m.focusControlLayoutGroup = m.top.findNode("focusControlLayoutGroup")

  m.ipAddressButton = m.top.findNode("ipAddressButton")
  m.ipAddressButton.observeFieldScoped("buttonSelected", "onIpAddressButtonSelected")

  m.portButton = m.top.findNode("portButton")
  m.portButton.observeFieldScoped("buttonSelected", "onPortButtonSelected")

  m.enabledButton = m.top.findNode("enabledButton")
  m.enabledButton.observeFieldScoped("buttonSelected", "onEnabledButtonSelected")

	m.settingsOverride = regReadAll(m.global.constants.registrySectionIDs.settingsOverride)

  updateUI()
End Function


Function updateUI()
  if m.settingsOverride.charlesProxyIp <> invalid then
    m.portButton.visible = true
    m.enabledButton.visible = true

    m.ipAddressButton.text = "IP Address: " + m.settingsOverride.charlesProxyIp

    if m.settingsOverride.charlesProxyEnabled = "true" then
      m.enabledButton.text = "Enabled"
    else
      m.enabledButton.text = "Disabled"
    end if

    if m.settingsOverride.charlesProxyPort <> invalid then
      m.portButton.text = "Port: " + m.settingsOverride.charlesProxyPort
    end if
  else
    m.portButton.visible = false
    m.enabledButton.visible = false

    m.ipAddressButton.text = "IP Address: Not Set"
  end if
End Function

Function onIpAddressButtonSelected()
  dialog = createObject("roSgNode", "StandardKeyboardDialog")
  dialog.title = "IP Address"
  dialog.message = ["Enter the IP Address of the computer Charles is running on"]
  dialog.buttons = ["Save"]
  dialog.observeFieldScoped("buttonSelected", "onIpAddressSaveButtonSelected")

  if m.settingsOverride.charlesProxyIp <> invalid then
    dialog.textEditBox.text = m.settingsOverride.charlesProxyIp
  end if

  m.top.getScene().dialog = dialog
End Function


Function onIpAddressSaveButtonSelected(msg)
  dialog = msg.getRoSgNode()

  if m.settingsOverride.charlesProxyEnabled = invalid then
    updateField("charlesProxyEnabled", "true")
  end if

  if m.settingsOverride.charlesProxyPort = invalid then
    updateField("charlesProxyPort", "8888")
  end if

  if m.settingsOverride.charlesProxyUrl <> invalid then
    ' If charlesProxyUrl exist we want to remove it as we are storing separate now
    updateField("charlesProxyUrl", invalid)
  end if

  updateField("charlesProxyIp", dialog.textEditBox.text)

  updateUI()

  m.top.getScene().dialog = invalid
End Function


Function onPortButtonSelected()
  dialog = createObject("roSgNode", "StandardKeyboardDialog")
  dialog.title = "Port"
  dialog.message = ["Enter the port that Charles is running on"]
  dialog.buttons = ["Save"]
  dialog.observeFieldScoped("buttonSelected", "onPortSaveButtonSelected")
  if m.settingsOverride.charlesProxyPort <> invalid then
    dialog.textEditBox.text = m.settingsOverride.charlesProxyPort
  end if

  m.top.getScene().dialog = dialog
End Function


Function onPortSaveButtonSelected(msg)
  dialog = msg.getRoSgNode()

  updateField("charlesProxyPort", dialog.textEditBox.text)

  updateUI()

  m.top.getScene().dialog = invalid
End Function


Function onEnabledButtonSelected()
  if m.enabledButton.text = "Enabled" then
    updateField("charlesProxyEnabled", "false")
  else
    updateField("charlesProxyEnabled", "true")
  end if

  updateUI()
End Function


Function updateField(fieldName, fieldValue)
  if fieldValue = invalid then
    RegDelete(fieldName, m.global.constants.registrySectionIDs.settingsOverride)
    m.settingsOverride.delete(fieldName)
  else
    RegWrite(fieldName, fieldValue, m.global.constants.registrySectionIDs.settingsOverride)
    m.settingsOverride[fieldName] = fieldValue
  end if

  RegWrite("applicationRestartRequired", "true", m.global.constants.registrySectionIDs.settingsOverride)
End Function

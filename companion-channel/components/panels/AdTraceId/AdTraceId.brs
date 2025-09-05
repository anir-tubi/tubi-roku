Function init()
  m.focusControlLayoutGroup = m.top.findNode("focusControlLayoutGroup")

  m.currentAdTraceIdLabel = m.top.findNode("currentAdTraceIdLabel")

  m.setAdTraceIdButton = m.top.findNode("setAdTraceIdButton")
  m.setAdTraceIdButton.observeFieldScoped("buttonSelected", "onSetAdTraceIdButtonSelected")

  m.clearAdTraceIdButton = m.top.findNode("clearAdTraceIdButton")
  m.clearAdTraceIdButton.observeFieldScoped("buttonSelected", "onClearAdTraceIdButtonSelected")

  m.settingsOverride = regReadAll(m.global.constants.registrySectionIDs.settingsOverride)

  updateUI()
End Function


Function updateUI()
  if m.settingsOverride.foxVideoPlayerAdTraceId <> invalid then
    m.currentAdTraceIdLabel.text = "Current Ad Trace ID: " + m.settingsOverride.foxVideoPlayerAdTraceId
  else
    m.currentAdTraceIdLabel.text = "Current Ad Trace ID: Not Set"
  end if
End Function


Function onSetAdTraceIdButtonSelected()
  dialog = createObject("roSgNode", "StandardKeyboardDialog")
  dialog.title = "Set Ad Trace ID"
  dialog.message = ["Enter a unique id without special characters for Ad Trace use"]
  dialog.buttons = ["Save"]
  dialog.observeFieldScoped("buttonSelected", "onAdTraceIdSaveButtonSelected")

  if m.settingsOverride.foxVideoPlayerAdTraceId <> invalid then
    dialog.textEditBox.text = m.settingsOverride.foxVideoPlayerAdTraceId
    dialog.textEditBox.cursorPosition = len(dialog.textEditBox.text)
  end if

  m.top.getScene().dialog = dialog
End Function


Function onAdTraceIdSaveButtonSelected(msg)
  dialog = msg.getRoSgNode()

  updateField("foxVideoPlayerAdTraceId", dialog.textEditBox.text)

  updateUI()

  m.top.getScene().dialog = invalid
End Function


Function onClearAdTraceIdButtonSelected()
  updateField("foxVideoPlayerAdTraceId", invalid)

  updateUI()
End Function

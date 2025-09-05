' Base panel currently just used to provide focus management
Function init()
  m.top.observeFieldScoped("focusedChild", "onFocusedChildChange")

  m.settingsOverride = {}
End Function


Function onFocusedChildChange(msg)
  if m.top.hasFocus() = true then
    if m.focusControlLayoutGroup <> invalid then
      m.focusControlLayoutGroup.setFocus(true)
    else if m.lastFocusedNode <> invalid then
      m.lastFocusedNode.setFocus(true)
    end if
  end if
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

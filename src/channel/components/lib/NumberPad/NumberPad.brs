Function init()
  m.constants = getConstantsFromGlobal()
  theme = getThemeFromGlobal()

  m.keyboard = m.top.findNode("keyboard")
  textEditBox = m.keyboard.textEditBox
  textEditBox.visible = false
  textEditBox.voiceEntryType = "numeric"

  keyGrid = m.keyboard.keyGrid
  keyGrid.keyDefinitionUri = "pkg:/components/data/NumberPadKDF.json"

  palette = createObject("roSGNode", "RSGPalette")
  palette.colors = {
    "FocusColor": theme.focused
    "FocusItemColor": m.constants.ui.colors.keyboardFocusedText
  }
  keyGrid.palette = palette

  m.top.observeFieldScoped("focusedChild", "onFocusedChildChange")
  m.top.observeFieldScoped("moveFocusToDelete", "onMoveFocusToDelete")
End Function


Function onFocusedChildChange()
  if m.top.hasFocus()
    m.keyboard.textEditBox.voiceEnabled = true
    m.keyboard.keyGrid.setFocus(true)
  else if m.top.isInFocusChain() = false
    m.keyboard.textEditBox.voiceEnabled = false
  else if m.keyboard.textEditBox.hasFocus()
    ' Don't allow textEditBox to take focus since we're not showing it
    m.keyboard.keyGrid.setFocus(true)
  end if
End Function


Function onMoveFocusToDelete()
  if m.top.moveFocusToDelete = true
    m.keyboard.keyGrid.jumpToKey = [0, 3, 1]
  end if
End Function

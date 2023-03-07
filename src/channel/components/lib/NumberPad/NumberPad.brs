Function init()
  m.constants = getConstantsFromGlobal()
  theme = getThemeFromGlobal()

  m.keyboard = m.top.findNode("keyboard")
  textEditBox = m.keyboard.textEditBox
  textEditBox.visible = false
  textEditBox.voiceEntryType = "generic" ' numeric seems like it would be a better fit but if a user says two thousand thirteen it comes through as 213 with numeric

  keyGrid = m.keyboard.keyGrid
  keyGrid.keyDefinitionUri = "pkg:/components/data/NumberPadKDF.json"

  if theme <> invalid
    palette = createObject("roSGNode", "RSGPalette")
    palette.colors = {
      "FocusColor": theme.focusedColor
      "FocusItemColor": theme.keyboardFocusedTextColor
    }
    keyGrid.palette = palette
  end if

  m.top.observeFieldScoped("focusedChild", "onTopFocusedChildChange")
  ' Need to observe textEditBox focusedChild as well to avoid voice input bug where voice input does not work properly after we have setFocus in the callback from m.top.focusedChild. m.keyboard.textEditBox.focusedChild gets called later which seems to fix it.
  m.keyboard.textEditBox.observeFieldScoped("focusedChild", "onTextEditBoxFocusedChildChange")
  m.top.observeFieldScoped("moveFocusToDelete", "onMoveFocusToDelete")
  m.top.observeFieldScoped("text", "onTextChange")
End Function


Function onTopFocusedChildChange()
  if m.top.hasFocus()
    m.keyboard.textEditBox.voiceEnabled = true
    m.keyboard.keyGrid.setFocus(true)
  else if m.top.isInFocusChain() = false
    m.keyboard.textEditBox.voiceEnabled = false
  end if
End Function

Function onTextEditBoxFocusedChildChange()
  ' Don't allow textEditBox to take focus since we're not showing it
  if m.keyboard.textEditBox.hasFocus()
    m.keyboard.keyGrid.setFocus(true)
  end if
End Function


Function onMoveFocusToDelete()
  if m.top.moveFocusToDelete = true
    m.keyboard.keyGrid.jumpToKey = [0, 3, 1]
  end if
End Function

Function onTextChange()
  ' Since we steal focus away once the user puts in a correct year,
  ' the keyGrid doesn't set its opacity back to 1 after dictation finishes so we set it any time the text changes
  m.keyboard.keyGrid.opacity = 1
End Function

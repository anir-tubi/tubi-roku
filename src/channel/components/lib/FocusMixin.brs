Function focusState(node As Object) As String
  if type(node) = "roSGNode" then
    return "id: " + node.id + " chain: " + node.isInFocusChain().toStr() + " self: " + node.hasFocus().toStr()
  else
    return ""
  end if
End Function


'setting the keyboard key focus colors
Function handleKeyboardColors()
  theme = getThemeFromGlobal()
  keyboardPalette = createObject("roSGNode", "RSGPalette")
  if theme <> invalid
    keyboardPalette.colors = {
      "FocusColor": theme.focused,
      "FocusItemColor": m.constants.ui.colors.keyboardFocusedText
    }
  end if
  return keyboardPalette
End Function

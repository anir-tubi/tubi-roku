Function focusState(node as Object) as String
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
      "FocusColor": theme.focusedColor,
      "FocusItemColor": theme.keyboardFocusedTextColor
    }
  end if
  return keyboardPalette
End Function

Function init()
  tubiLog("KeyboardGroup.init")

  m.SymbolMenu = m.top.findNode("SymbolMenu")
  m.SymbolMenu.observeField("itemFocused", "onKeyboardChange")
  m.UppercaseKeyboard = m.top.findNode("UppercaseKeyboard")
  m.UppercaseKeyboard.observeField("itemSelected", "onKeySelected")
  m.LowercaseKeyboard = m.top.findNode("LowercaseKeyboard")
  m.LowercaseKeyboard.observeField("itemSelected", "onKeySelected")
  m.NumericKeyboard = m.top.findNode("NumericKeyboard")
  m.NumericKeyboard.observeField("itemSelected", "onKeySelected")
  m.Symbolic1Keyboard = m.top.findNode("Symbolic1Keyboard")
  m.Symbolic1Keyboard.observeField("itemSelected", "onKeySelected")
  m.Symbolic2Keyboard = m.top.findNode("Symbolic2Keyboard")
  m.Symbolic2Keyboard.observeField("itemSelected", "onKeySelected")
  m.CurrentKeyboard = m.UppercaseKeyboard
  m.top.observeField("focusedChild", "onKeyboardFocusChange")

  m.SymbolMenu.setFocus(true)
  m.lastFocusedItem = m.SymbolMenu

  m.BACKSPACE = Chr(&h7F)
End Function


''''''''''''''''''''''''
' onKeySelected
'
' A keyboard key has been selected by user pressing 'OK' on the remote
Function onKeySelected()
  tubiLog("KeyboardGroup.onKeySelected")
  key = m.CurrentKeyboard.content.getChild(m.CurrentKeyboard.itemSelected)
  if key.title = m.BACKSPACE 
    if m.top.text.len() > 0 then m.top.text = Left(m.top.text, m.top.text.len()-1)
  else if m.top.text.len() < m.top.maxLength then
    m.top.text = m.top.text + key.title
  end if
End Function


'''''''''''''''''''''''
' onKeyboardFocusChange
'
' If focus is set to the keyboard, move it to the last focused child
Function onKeyboardFocusChange()
  if m.top.hasFocus() then m.lastFocusedItem.setFocus(true)
End Function


'''''''''''''''''''''''
' onKeyboardChange
'
' Make the appropriate keyboard visible based on symbol menu selection
Function onKeyboardChange()
  keyboard = m.SymbolMenu.content.getChild(m.SymbolMenu.itemFocused)
  if keyboard <> invalid then
    newKeyboard = m.top.findNode(keyboard.id + "Keyboard")
    m.CurrentKeyboard.visible = false
    newKeyboard.visible = true
    m.CurrentKeyboard = newKeyboard
    ' special case, there are 2 symbolic keyboards
    if newKeyboard.id = m.Symbolic1Keyboard.id then
      m.Symbolic2Keyboard.visible = true
    else
      m.Symbolic2Keyboard.visible = false
    end if
  end if
End Function


'''''''''''''''''''''''
' onKeyEvent
'
' Handle remote button presses
Function onKeyEvent(key As String, press As Boolean) As Boolean
  tubiLog("KeyboardGroup.onKeyEvent")
  if press then
    if key = "down" then
      if m.SymbolMenu.hasFocus() then
        m.CurrentKeyboard.setFocus(true)
        m.lastFocusedItem = m.CurrentKeyboard
        return true
      else if m.CurrentKeyboard.hasFocus() then
        if m.CurrentKeyboard.id = m.Symbolic1Keyboard.id then
          m.Symbolic2Keyboard.setFocus(true)
          m.CurrentKeyboard = m.Symbolic2Keyboard
          m.lastFocusedItem = m.CurrentKeyboard
          return true
        end if
      end if
    else if key = "up" then
      if m.CurrentKeyboard.hasFocus() then
        if m.Symbolic2Keyboard.hasFocus() then
          m.Symbolic1Keyboard.setFocus(true)
          m.CurrentKeyboard = m.Symbolic1Keyboard
          m.lastFocusedItem = m.CurrentKeyboard
          return true
        else
          m.SymbolMenu.setFocus(true)
          m.lastFocusedItem = m.SymbolMenu
          return true
        end if
        return true
      end if
    else if key = "rewind" or key = "right" then
      if m.CurrentKeyboard.hasFocus() then
        m.CurrentKeyboard.animateToItem = 0
      end if
    else if key = "fastforward" or key = "left" then
      if m.CurrentKeyboard.hasFocus() then
        m.CurrentKeyboard.animateToItem = m.CurrentKeyboard.content.getChildCount() - 1
      end if
    end if
  end if
  return false
End Function

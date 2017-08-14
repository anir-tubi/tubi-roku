Function init()
  tubiLog("KeyboardGroup.init")

  m.SymbolMenu = m.top.findNode("SymbolMenu")
  m.SymbolMenu.observeField("itemFocused", "onKeyboardChange")
  m.SymbolMenu.observeField("preItemFocused", "onKeyboardPreChange")

  m.UppercaseKeyboard = m.top.findNode("UppercaseKeyboard")
  m.UppercaseKeyboard.observeField("itemSelected", "onKeySelected")
  m.UppercaseKeyboard.observeField("preItemFocused", "onPreItemFocused")

  m.LowercaseKeyboard = m.top.findNode("LowercaseKeyboard")
  m.LowercaseKeyboard.observeField("itemSelected", "onKeySelected")
  m.LowercaseKeyboard.observeField("preItemFocused", "onPreItemFocused")

  m.NumericKeyboard = m.top.findNode("NumericKeyboard")
  m.NumericKeyboard.observeField("itemSelected", "onKeySelected")
  m.NumericKeyboard.observeField("preItemFocused", "onPreItemFocused")

  m.Symbolic1Keyboard = m.top.findNode("Symbolic1Keyboard")
  m.Symbolic1Keyboard.observeField("itemSelected", "onKeySelected")
  m.Symbolic1Keyboard.observeField("preItemFocused", "onPreItemFocused")

  m.Symbolic2Keyboard = m.top.findNode("Symbolic2Keyboard")
  m.Symbolic2Keyboard.observeField("itemSelected", "onKeySelected")
  m.Symbolic2Keyboard.observeField("preItemFocused", "onPreItemFocused")

  m.CurrentKeyboard = m.UppercaseKeyboard
  m.top.observeField("focusedChild", "onKeyboardFocusChange")

  m.lastFocusedItem = m.SymbolMenu

  m.BACKSPACE = Chr(&h7F)

  m.lastFocusedKeyIndex = 0
  m.lastFocusedKeyboardIndex = 0
  m.primaryTextColor = m.global.constants.ui.colors.primaryText
  m.focusedTextColor = m.global.constants.ui.colors.focusedText
  m.highlightedTexColor = m.global.constants.ui.colors.highlightedText

  m.SymbolMenu.findNode("Items").getChild(0).color = m.focusedTextColor
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


''''''''''''''''''''''''
' onPreItemFocused
'
' A keyboard key has been focused upon by a user pressing left/right
Function onPreItemFocused()
  tubiLog("KeyboardGroup.onPreItemFocused")
  keyLosingFocus = m.CurrentKeyboard.findNode("Items").getChild(m.lastFocusedKeyIndex) 'use an internal store to account for press and hold
  keyGainingFocus = m.CurrentKeyboard.findNode("Items").getChild(m.CurrentKeyboard.preItemFocused)

  colorChange(keyLosingFocus.findNode("Text"), m.primaryTextColor, m.CurrentKeyboard.focusChangeDuration, 0.0)
  colorChange(keyGainingFocus.findNode("Text"), m.focusedTextColor, m.CurrentKeyboard.focusChangeDuration, 0.0)

  m.lastFocusedKeyIndex = m.CurrentKeyboard.preItemFocused
End Function


'''''''''''''''''''''''
' onKeyboardFocusChange
'
' If focus is set to the keyboard, move it to the last focused child
Function onKeyboardFocusChange()
  if m.top.hasFocus() then m.lastFocusedItem.setFocus(true)
End Function


'''''''''''''''''''''''
' onKeyboardPreChange
'
' The highlighted keyboard title is changing
Function onKeyboardPreChange()
  keyboardLosingFocus = m.SymbolMenu.findNode("Items").getChild(m.lastFocusedKeyboardIndex)
  keyboardGainingFocus = m.SymbolMenu.findNode("Items").getChild(m.SymbolMenu.preItemFocused)

  colorChange(keyboardLosingFocus, m.primaryTextColor, m.CurrentKeyboard.focusChangeDuration, 0.0)
  colorChange(keyboardGainingFocus, m.focusedTextColor, m.CurrentKeyboard.focusChangeDuration, 0.0)

  m.lastFocusedKeyboardIndex = m.SymbolMenu.preItemFocused
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
        'don't allow changing focus from keyboard selector to keys selector until keyboard selector animation is complete
        if m.SymbolMenu.preItemFocused = m.SymbolMenu.itemFocused
          focusedKeyboard = m.SymbolMenu.findNode("Items").getChild(m.SymbolMenu.preItemFocused)
          finishAnimation(focusedKeyboard)
          focusedKeyboard.color = m.highlightedTexColor

          focusedKey = m.CurrentKeyboard.findNode("Items").getChild(m.CurrentKeyboard.itemFocused)
          focusedKey.findNode("Text").color = m.focusedTextColor
          m.lastFocusedKeyIndex = m.CurrentKeyboard.itemFocused

          m.CurrentKeyboard.setFocus(true)
          m.lastFocusedItem = m.CurrentKeyboard
        end if
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
          focusedKey = m.CurrentKeyboard.findNode("Items").getChild(m.CurrentKeyboard.preItemFocused)
          finishAnimation(focusedKey.findNode("Text"))
          focusedKey.findNode("Text").color = m.primaryTextColor

          focusedKeyboard = m.SymbolMenu.findNode("Items").getChild(m.SymbolMenu.itemFocused)
          focusedKeyboard.color = m.focusedTextColor
          m.lastFocusedKeyboardIndex = m.SymbolMenu.itemFocused

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

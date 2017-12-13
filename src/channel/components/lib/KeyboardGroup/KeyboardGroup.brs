Function init()
  tubiLog("KeyboardGroup.init")
  m.Menu = m.top.findNode("Menu")
  m.Menu.observeField("itemFocused", "onKeyboardChange")
  m.Keyboard = m.top.findNode("Keyboard")
  m.Keyboard.observeField("itemSelected", "onKeySelected")
  m.Symbolic2Keyboard = m.top.findNode("Symbolic2Keyboard")
  m.Symbolic2Keyboard.observeField("itemSelected", "onKeySelected")
  m.Overlay = m.top.findNode("KeyboardOverlay")
  m.top.observeField("focusedChild", "onKeyboardFocusChange")
  m.lastFocusedItem = m.Menu
  m.BACKSPACE = Chr(&h7F)

  ' grid content hidden behind overlay images
  m.keyboards = [
  { ' lowercase
    columnSpacings: [2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,16,21]
    translation: [66,82]
    content: m.top.findNode("LowercaseContent")
  }
  { ' uppercase
    columnSpacings: [2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,17,21]
    translation: [66,82]
    content: m.top.findNode("UppercaseContent")
  }
  { ' numeric
    columnSpacings: [2,2,2,2,2,2,2,2,2,18,21]
    translation: [588,82]
    content: m.top.findNode("NumericContent")
  }
  { ' symbol1
    columnSpacings: [0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,17,21]
    translation: [70,82]
    content: m.top.findNode("SymbolicContent1")
  }
  ]
  ' Keyboard iamges
  m.overlays = [
  { ' lowercase
    uri: "pkg:/images/keyboard-lowercase.png"
    width: 1748
    height: 40
    translation: [85,99]
  }
  { ' uppercase
    uri: "pkg:/images/keyboard-uppercase.png"
    width: 1751
    height: 40
    translation: [83,99]
  }
  { ' numeric
    uri: "pkg:/images/keyboard-numbers.png"
    width: 756
    height: 40
    translation: [609,99]
  }
  { ' symbol1
    uri: "pkg:/images/keyboard-symbols.png"
    width: 1750
    height: 111
    translation: [84,99]
  }
  ]

  m.Keyboard.setFields(m.keyboards[0])
  m.Overlay.setFields(m.overlays[0])

  if m.global.constants.deviceInfo.scaledUi = true then
    m.Symbolic2Keyboard.focusedBitmapUri = "pkg:/images/menu-focus-hd.9.png"
    m.Keyboard.focusedBitmapUri = "pkg:/images/menu-focus-hd.9.png"
  end if
End Function


''''''''''''''''''''''''
' onKeySelected
'
' A keyboard key has been selected by user pressing 'OK' on the remote
Function onKeySelected(message)
  tubiLog("KeyboardGroup.onKeySelected")
  ' GetNode() will return m.Keyboard or m.Sybolic2Keyboard
  keyboard = message.getRoSGNode()
  key = keyboard.content.getChild(keyboard.itemSelected)
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
  m.Keyboard.setFields(m.keyboards[m.Menu.itemFocused])
  m.Overlay.setFields(m.overlays[m.Menu.itemFocused])
  ' special case, there are 2 symbolic keyboards
  if m.Menu.itemFocused = 3 then
    m.Symbolic2Keyboard.visible = true
  else
    m.Symbolic2Keyboard.visible = false
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
      if m.Menu.hasFocus() then
        if m.Menu.currFocusColumn = m.Menu.itemFocused
          m.Keyboard.setFocus(true)
          m.lastFocusedItem = m.Keyboard
        end if
        return true
      else if m.Keyboard.hasFocus() then
        if m.Symbolic2Keyboard.visible then
          m.Symbolic2Keyboard.setFocus(true)
          m.lastFocusedItem = m.Symbolic2Keyboard
          return true
        end if
      end if
    else if key = "up" then
      if m.Keyboard.hasFocus() then
        m.Menu.setFocus(true)
        m.lastFocusedItem = m.Menu
        return true
      else if m.Symbolic2Keyboard.hasFocus() then
        m.Keyboard.setFocus(true)
        m.lastFocusedItem = m.Keyboard
        return true
      end if
    else if key = "fastforward" or key = "right" then
      if m.Keyboard.hasFocus() then
        m.Keyboard.jumpToItem = 0
      end if
    else if key = "rewind" or key = "left" then
      if m.Keyboard.hasFocus() then
        m.Keyboard.jumpToItem = m.Keyboard.content.getChildCount() - 1
      end if
    end if
  end if
  return false
End Function

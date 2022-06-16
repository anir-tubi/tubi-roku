Function init()
    m.constants = m.global.constants
    m.theme = m.global.theme
    m.passwordMode = true
    m.back = m.top.findNode("back")
    m.back.text = getTranslation("linearVideoPlayer_buttonBack")
    m.back.observeFieldScoped("selected", "onButtonSelected")

    m.showHidePassword = m.top.findNode("showHidePassword")
    m.showHidePassword.text = getTranslation("screenSettings_parentalPassword_button_show")
    m.showHidePassword.observeFieldScoped("selected", "onButtonSelected")

    m.continue = m.top.findNode("continue")
    m.continue.text = getTranslation("dialog_button_continue")
    m.continue.observeFieldScoped("selected", "onButtonSelected")

    m.keyboard = m.top.findNode("Keyboard")
    m.keyboard.domain = "password"
    m.keyboard.textEditBox.visible = false
    m.keyboard.palette = handleKeyboardColors()

    m.keyboard.textEditBox.observeFieldScoped("focusedChild", "onTextEditBoxFocusedChildChange")
End Function


Function onKeyEvent(key As String, press As Boolean) as Boolean
  handled = true
  if press

    if key = "down"
      if m.keyboard.isInFocusChain() = true 
        m.continue.setFocus(true)
      end if  
    
    else if key = "up"
      if m.continue.hasFocus() = true
        m.keyboard.setFocus(true)
      else if m.showHidePassword.hasFocus() = true
        m.keyboard.setFocus(true)
      else if m.back.hasFocus() = true
        m.keyboard.setFocus(true)
      else if m.top.isInFocusChain() = true
        m.top.buttonSelected = "up"
      end if
      
    else if key = "right"
    
      if m.back.hasFocus() = true
        m.continue.setFocus(true)
      else if m.continue.hasFocus() = true
        m.showHidePassword.setFocus(true)
      end if
      
    else if key = "left"
    
      if m.continue.hasFocus() = true
        m.back.setFocus(true)
      else if m.showHidePassword.hasFocus() = true
        m.continue.setFocus(true)    
      end if    
    else if key = "back"
        handled = false
    end if
    
    return handled
  end if
  
End Function


Function onButtonSelected(evt)

    buttonSelected = evt.getRoSGNode()
    if buttonSelected.id = "showHidePassword"
        if m.passwordMode = true
            m.showHidePassword.text = getTranslation("screenSettings_parentalPassword_button_hide")
            m.passwordMode = false
          else
            m.showHidePassword.text = getTranslation("screenSettings_parentalPassword_button_show")
            m.passwordMode = true
          end if
    end if
    m.top.buttonSelected = buttonSelected.id
        
End Function


Function onTextEditBoxFocusedChildChange()
  ' Don't allow textEditBox to take focus since we're not showing it
  if m.keyboard.textEditBox.hasFocus() = true
    m.keyboard.keyGrid.setFocus(true)
  end if
End Function

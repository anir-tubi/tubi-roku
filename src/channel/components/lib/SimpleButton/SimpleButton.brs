Function init()

  m.buttonBG = m.top.findNode("buttonBG")
  m.label = m.top.findNode("label")
  m.buttonBG.opacity = m.top.unfocusedBackgroundOpacity
  
  m.top.observeField("focusedChild", "onScreenFocusChange")
  m.top.observeField("unfocusedBackgroundOpacity", "onOpacityChanged")

  m.top.observeField("text", "onTextChanged")
  
End Function


Function onTextChanged()

  m.label.text = m.top.text
  
  if m.top.width = 0
    width = m.label.boundingRect().width + 20
    m.buttonBG.width = width
    m.label.width = width
  else
    m.label.width = m.top.width
    m.buttonBG.width = m.top.width
  end if

End Function


Function onScreenFocusChange()
  tubiLog("SimpleButton.onScreenFocusChange")
  
  if m.top.hasFocus() then
    m.buttonBG.blendColor = m.global.theme.focused
    m.buttonBG.opacity = 1.0
  else
    m.buttonBG.blendColor = m.top.color
    m.buttonBG.opacity = m.top.unfocusedBackgroundOpacity
  end if
  
End Function


Function onOpacityChanged()
 
  if m.top.hasFocus() = false
    m.buttonBG.opacity = m.top.unfocusedBackgroundOpacity
  end if
  
End Function


Function onKeyEvent(key As String, press As Boolean) as Boolean

  tubiLog("SimpleButton.onKeyEvent key = " + key)
  if press then
    if key = "OK"
      m.top.selected = true
      return true
    end if
  end if

  return false
End Function
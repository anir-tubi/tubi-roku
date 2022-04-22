Function init()
  m.buttonBG = m.top.findNode("buttonBG")
  m.label = m.top.findNode("label")
  m.buttonBG.opacity = m.top.unfocusedBackgroundOpacity

  m.top.observeField("focusedChild", "onScreenFocusChange")
  m.top.observeField("unfocusedBackgroundOpacity", "onOpacityChanged")

  m.top.observeField("text", "onTextChanged")
End Function



Function onTextChanged()

  ' m.label.width should be reset to 0 before the new text is set so the boundingRect().width
  ' calculation is accurate. Otherwise, boundingRect().width will be the previously set
  ' m.label.width value
  if m.top.width = 0
    m.label.width = 0
    m.label.text = m.top.text
    width = m.label.boundingRect().width + 60
    m.buttonBG.width = width
    m.label.width = width
  else
    m.label.text = m.top.text
  end if

  if m.top.height = 0
    height = m.label.boundingRect().height + 60
    m.buttonBG.height = height
    m.label.height = height
  else
    m.label.height = m.top.height
    m.buttonBG.height = m.top.height
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

  if press then
    tubiLog("SimpleButton.onKeyEvent key = " + key)
    if key = "OK"
      m.top.selected = true
      return true
    end if
  end if

  return false
End Function

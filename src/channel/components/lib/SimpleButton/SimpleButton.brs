Function init()
  m.buttonBG = m.top.findNode("buttonBG")
  m.label = m.top.findNode("label")
  m.originalColor = ""  '//the default color based on the theme if no color is passed into the component via the m.top.color field
  m.buttonBG.opacity = m.top.unfocusedBackgroundOpacity

  m.top.observeFieldScoped("focusedChild", "onScreenFocusChange")
  m.top.observeFieldScoped("unfocusedBackgroundOpacity", "onOpacityChanged")

  m.top.observeFieldScoped("width", "onWidthChanged")
  m.top.observeFieldScoped("text", "onTextChanged")

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
  onThemeChange()
End Function


Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.theme = theme
    m.label.color = theme.primaryTextColor
    m.originalColor = theme.neutralColor
  end if
End Function


Function onWidthChanged(msg)
  ' not using an alias so updates to label.width and buttonBG.width don't feed back to overwrite m.top.width
  ' which is used in onTextChanged() to determine if the button should be auto resized or not
  width = msg.getData()
  m.label.width = width
  m.buttonBG.width = width
End Function


Function onTextChanged()
  ' m.label.width should be reset to 0 before the new text is set so the boundingRect().width
  ' calculation is accurate. Otherwise, boundingRect().width will be the previously set
  ' m.label.width value
  if m.top.width = 0 'indicates the button should auto resize
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
    if m.theme <> invalid
      m.buttonBG.blendColor = m.theme.focusedColor
      m.label.color = m.theme.focusedTextColor
    end if
    m.buttonBG.opacity = 1.0
  else
    if isNonEmptyString(m.top.color) = true
      '//if the color was set from the outside then use that color
      m.buttonBG.blendColor = m.top.color
    else
      m.buttonBG.blendColor = m.originalColor
    end if

    if m.theme <> invalid
      m.label.color = m.theme.primaryTextColor
    end if

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

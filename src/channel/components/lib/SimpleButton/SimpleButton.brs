Function init()
  m.focus9Patch = m.top.findNode("focus9Patch")
  m.label = m.top.findNode("label")
  'This is used to add a background when the button is not filled so that text
  'can be seen if the button is placed over an image with a light background.
  'The skipIntro button is an example of how this is used.
  m.notFilledBackground = m.top.findNode("notFilledBackground")

  m.originalColor = "" '//the default color based on the theme if no color is passed into the component via the m.top.color field
  m.focus9Patch.opacity = m.top.unfocusedBackgroundOpacity

  m.top.observeFieldScoped("focusedChild", "onScreenFocusChange")
  m.top.observeFieldScoped("unfocusedBackgroundOpacity", "onOpacityChanged")

  m.top.observeFieldScoped("width", "onWidthChanged")
  m.top.observeFieldScoped("text", "onTextChanged")
  m.top.observeFieldScoped("isFilled", "onIsFilledChange")
  m.top.observeFieldScoped("itemHasFocus", "onItemHasFocusChange")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.label, typographyConstants.ids.bodyMediumStrong)

  m.top.focusable = true

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
    m.focusedColor = theme.focusedColor
    m.primaryTextColor = theme.primaryTextColor
    m.label.color = theme.primaryTextColor
    m.originalColor = theme.unfocusedColor
    m.focusedTextColor = theme.focusedTextColor
  end if
End Function


Function onWidthChanged(msg)
  ' not using an alias so updates to label.width and focus9Patch.width don't feed back to overwrite m.top.width
  ' which is used in onTextChanged() to determine if the button should be auto resized or not
  width = msg.getData()
  m.label.width = width
  m.focus9Patch.width = width
  m.notFilledBackground.width = width
End Function


Function onTextChanged()
  ' m.label.width should be reset to 0 before the new text is set so the boundingRect().width
  ' calculation is accurate. Otherwise, boundingRect().width will be the previously set
  ' m.label.width value
  if m.top.width = 0 'indicates the button should auto resize
    m.label.width = 0
    m.label.text = m.top.text
    width = m.label.boundingRect().width + 60
    m.focus9Patch.width = width
    m.notFilledBackground.width = width
    m.label.width = width
  else
    m.label.text = m.top.text
  end if

  if m.top.height = 0
    height = m.label.boundingRect().height + 60
    m.focus9Patch.height = height
    m.notFilledBackground.height = height
    m.label.height = height
  else
    m.label.height = m.top.height
    m.focus9Patch.height = m.top.height
    m.notFilledBackground.height = m.top.height
  end if
End Function


Function onIsFilledChange(msg)
  isFilled = msg.getData()

  if isFilled = false
    m.notFilledBackground.visible = true
  else
    m.notFilledBackground.visible = false
  end if
End Function


Function onScreenFocusChange()
  tubiLog("SimpleButton.onScreenFocusChange")
  updateFocusState(m.top.hasFocus())
End Function


Function onOpacityChanged()
  if m.top.isFilled = false
    m.focus9Patch.opacity = 1.0
  else if m.top.hasFocus() = false
    m.focus9Patch.opacity = m.top.unfocusedBackgroundOpacity
  end if
End Function

' Allows us to override the background color when the
Function onItemHasFocusChange(msg)
  itemHasFocus = msg.getData()
  updateFocusState(itemHasFocus)
End Function


Function updateFocusState(isFocused = false)
  if isFocused = true then
    if m.theme <> invalid
      m.focus9Patch.blendColor = m.focusedColor
      if m.top.isFilled = false
        m.label.color = m.primaryTextColor
      else
        m.label.color = m.focusedTextColor
      end if
    end if
    m.focus9Patch.opacity = 1.0
  else
    if isNonEmptyString(m.top.color) = true
      '//if the color was set from the outside then use that color
      m.focus9Patch.blendColor = m.top.color
    else
      m.focus9Patch.blendColor = m.originalColor
    end if

    m.label.color = m.primaryTextColor

    if m.top.isFilled = false
      m.focus9Patch.opacity = 1.0
    else
      m.focus9Patch.opacity = m.top.unfocusedBackgroundOpacity
    end if
  end if
End Function


Function onKeyEvent(key as String, press as Boolean) as Boolean

  if press then
    tubiLog("SimpleButton.onKeyEvent key = " + key)
    if key = "OK"
      m.top.selected = true
      return true
    end if
  end if

  return false
End Function
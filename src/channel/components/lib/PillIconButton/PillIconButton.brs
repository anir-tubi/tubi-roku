Function init()
  m.Icon = m.top.findNode("Icon")
  m.Title = m.top.findNode("Title")
  m.Background = m.top.findNode("Background")
  m.OverlayGroup = m.top.findNode("OverlayGroup")

  m.top.observeField("icon", "onIconChange")
  m.top.observeField("text", "onTextChange")

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
    m.Background.blendColor = theme.neutralColor2
    m.Title.color = theme.primaryTextColor
  end if
End Function


Function onIconChange()
  if m.top.icon <> invalid
    sIconID = LCase(m.top.icon)

    '//reset the default translation and item order
    m.OverlayGroup.appendChild(m.Title)
    m.OverlayGroup.translation = [m.OverlayGroup.translation[1], m.OverlayGroup.translation[1]]

    if sIconID = "left"
      m.Icon.uri = "pkg:/images/icon-arrow-left.png"
    else if sIconID = "right"
      m.Icon.uri = "pkg:/images/icon-arrow-right.png"
      m.OverlayGroup.appendChild(m.Icon) '//The icon should be to the right of the title

      '//The text should have more space on the left side when text is not left most element
      m.OverlayGroup.translation = [m.OverlayGroup.translation[1] + 4, m.OverlayGroup.translation[1]]
    else if sIconID = "up"
      m.Icon.uri = "pkg:/images/icon-arrow-up.png"
    else if sIconID = "down"
      m.Icon.uri = "pkg:/images/icon-arrow-down.png"
    else if sIconID = "checkmark"
      m.Icon.uri = "pkg:/images/icon-checkmark.png"
    else if sIconID = "about"
      m.Icon.uri = "pkg:/images/icon-about.webp"
    end if
  end if
End Function


Function onTextChange()
  '//Change the label and the width of the background
  sText = ""
  if m.top.text <> invalid
    sText = m.top.text
  end if
  m.Title.text = sText
  m.Background.width =  m.OverlayGroup.translation[0] + m.Icon.width + m.Title.boundingRect().width + m.OverlayGroup.itemSpacings[0]*2
End Function

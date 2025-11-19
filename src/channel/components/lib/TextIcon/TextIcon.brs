Function init()

  m.Icon = m.top.findNode("Icon")

  m.textLabel = m.top.findNode("textLabel")
  m.textLabel.observeFieldScoped("text", "onTextChange")

  m.textBackground = m.top.findNode("textBackground")
  m.top.observeFieldScoped("uri", "onUriChange")
  m.top.observeFieldScoped("iconUri", "onIconUriChange")
End Function

Function onTextChange()
  moveUIElements()
End Function


Function moveUIElements()
  ' If we don't reset back to 0 before our boundRect our y position won't be correct
  m.textLabel.translation = [0, 0]
  textBoundingRect = m.textLabel.boundingRect()
  textWidth = textBoundingRect.width
  textHeight = textBoundingRect.height

  bIconVisible = false
  if m.Icon.uri <> ""
    bIconVisible = true
  end if
  m.Icon.visible = bIconVisible

  padding = m.top.padding
  xPadding = padding[0]
  yPadding = padding[1]

  m.textBackground.height = textHeight + yPadding * 2

  if m.top.iconTextSpacing < 0
    nIconSpacing = textHeight / 2
  else
    nIconSpacing = m.top.iconTextSpacing
  end if

  if bIconVisible = true
    m.textBackground.width = m.Icon.width + nIconSpacing + textWidth + (xPadding * 2)

    nTextLabelX = xPadding + m.Icon.width + nIconSpacing
    m.textLabel.horizOrigin = "left"
    m.Icon.translation = [xPadding, (m.textBackground.height - m.Icon.height) / 2]
  else
    m.textBackground.width = textWidth + xPadding * 2

    nTextLabelX = m.textBackground.width / 2
    m.textLabel.horizOrigin = "center"
  end if

  ' The y translation assumes that m.textLabel.vertOrigin = "center" and that an extra pixel is needed to take into account
  '    that the roku firmware not doing a good job with text. The 1 pixel adjustment is found by trial and error.
  m.textLabel.translation = [nTextLabelX, (m.textBackground.height / 2) + 1]

End Function


Function onUriChange(msg)
  uri = msg.getData()

  ' Allows not having to setup uri in brs just to be able to switch between hd and fhd or to have to use two uris
  m.textBackground.uri = setImageUriSize(uri)
End Function


Function onIconUriChange(msg)
  uri = msg.getData()

  m.Icon.uri = setImageUriSize(uri)
  '//reset the UI elements when the icon has been added or removed
  moveUIElements()
End Function

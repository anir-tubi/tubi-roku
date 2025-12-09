Function init()
  m.badgeInfoLayout = m.top.findNode("BadgeInfoLayout")
  m.badgeIcon = m.top.findNode("BadgeIcon")
  m.badgeText = m.top.findNode("BadgeText")
  m.badgeBackground = m.top.findNode("BadgeBackground")
  m.badgeBorder = m.top.findNode("badgeBorder")
  m.top.observeFieldScoped("iconUri", "onIconChanged")
  m.top.observeFieldScoped("text", "onTextChanged")
  m.top.observeFieldScoped("badgeTextFont", "onSetTypography")
  m.top.observeFieldScoped("maxWidth", "onMaxWidthChanged")

  m.typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.badgeText, m.typographyConstants.ids.bodyExtraSmallStrong)
End Function

Function onMaxWidthChanged()
  adjustBadgeSize()
End Function


Function onIconChanged(msg)
  iconUri = msg.getData()
  if isNonEmptyString(iconUri)
    m.badgeIcon.width = 24
    m.badgeIcon.uri = iconUri
    m.badgeInfoLayout.itemSpacings = [8]
    m.badgeIcon.scale = [1, 1]
  else
    m.badgeIcon.scale = [0, 0]
    m.badgeInfoLayout.itemSpacings = [0]
  end if
  adjustBadgeSize()
End Function


Function onTextChanged()
  m.badgeText.text = m.top.text
  adjustBadgeSize()
End Function


Function adjustBadgeSize()
  badgeInfoLayoutWidth = m.badgeInfoLayout.boundingRect().width
  maxWidthValue = m.top.maxWidth
  height = m.badgeText.boundingRect().height
  m.badgeIcon.height = height

  ' Apply maxWidth constraint if set
  if maxWidthValue > 0 AND badgeInfoLayoutWidth > maxWidthValue
    ' Adjust badge text width to fit within maxWidth
    iconWidth = 0
    if m.badgeIcon.width > 0
      iconWidth = m.badgeIcon.width + 8 ' icon width + spacing
    end if

    availableTextWidth = maxWidthValue - iconWidth - 24 ' subtract padding
    if availableTextWidth > 0
      m.badgeText.width = availableTextWidth
    end if

    ' Recalculate width after constraining text
    badgeInfoLayoutWidth = m.badgeInfoLayout.boundingRect().width
  end if

  xAxis = 0
  if m.top.showBackground = true
    targetWidth = badgeInfoLayoutWidth + 24

    ' Apply maxWidth to background if set
    if maxWidthValue > 0 AND targetWidth > maxWidthValue
      targetWidth = maxWidthValue
    end if

    if targetWidth >= m.badgeBackground.width
      m.badgeBackground.width = targetWidth
    end if

    ' Set border width and height to be larger than background for proper edge display
    borderWidth = m.badgeBackground.width + 2
    borderHeight = m.badgeBackground.height + 2
    m.badgeBorder.width = borderWidth
    m.badgeBorder.height = borderHeight

    ' Center the border over the background
    ' Border is 4px larger, so offset by 2px to center it (2px on each side)
    m.badgeBorder.translation = [-1, -1]

    xAxis = (m.badgeBackground.width - badgeInfoLayoutWidth) / 2
  end if

  m.badgeInfoLayout.translation = [xAxis, (36 - height) / 2]
End Function


Function onSetTypography(msg)
  fontSize = msg.getData()

  if isString(fontSize) = true AND m.typographyConstants.ids[fontSize] <> invalid
    fontSize = m.typographyConstants.ids[fontSize]
    setTypographyOfLabel(m.badgeText, fontSize)
  else
    setTypographyOfLabel(m.badgeText, m.typographyConstants.ids.bodySmallStrong)
  end if

End Function
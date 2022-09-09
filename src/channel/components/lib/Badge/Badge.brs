Function init()
  m.badgeInfoLayout = m.top.findNode("BadgeInfoLayout")
  m.badgeIcon = m.top.findNode("BadgeIcon")
  m.badgeText = m.top.findNode("BadgeText")
  m.badgeBackground = m.top.findNode("BadgeBackground")
  m.top.observeFieldScoped("iconUri", "onIconChanged")
  m.top.observeFieldScoped("text", "onTextChanged")
End Function


Function onIconChanged()
  m.badgeIcon.width = 24
  m.badgeIcon.uri = m.top.iconUri
  m.badgeInfoLayout.itemSpacings = [8]
  adjustBadgeSize()
End Function


Function onTextChanged()
  m.badgeText.text = m.top.text
  adjustBadgeSize()
End Function


Function adjustBadgeSize()
  badgeInfoLayoutWidth = m.badgeInfoLayout.boundingRect().width

  if badgeInfoLayoutWidth >= m.badgeBackground.width
    m.badgeBackground.width = badgeInfoLayoutWidth + 24
  end if

  m.badgeInfoLayout.translation = [12, 18]
End Function
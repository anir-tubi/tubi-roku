Function init()
  m.poster = m.top.findNode("Poster")
  m.badgeGroup = m.top.findNode("badgeGroup")
  m.top.observeField("itemContent", "onContentChange")

  setThemeColors()
End Function


Function setThemeColors()
  theme = getThemeFromGlobal()

  if theme <> invalid
    m.focusedTextColor = theme.focusedTextColor
  end if
End Function


Function onContentChange(msg)
  itemContent = msg.getData()

  if itemContent <> invalid
    removeRottenTomatoScoreBadge()
    m.poster.uri = itemContent.hdgridposterurl

    if itemContent.userStarRating > 0
      setRottenTomatoScoreBadge(itemContent.userStarRating)
    end if
  end if
End Function


'@badgeText - string, Indicating text on the badge
Function setRottenTomatoScoreBadge(badgeText)
  m.badge = m.badgeGroup.createChild("Badge")
  m.badge.textColor = m.focusedTextColor
  m.badge.iconUri = "pkg:/images/certified-fresh.png"
  m.badge.text = badgeText.tostr() + "%"

  m.badgeGroup.translation = [9, 9]

End Function


Function removeRottenTomatoScoreBadge()
  m.badgeGroup.removeChild(m.badge)
End Function

Function init()
  m.Background = m.top.findNode("NumberPadGridItemBg")
  m.ForegroundLabel = m.top.findNode("NumberPadGridItemFgLabel")
  m.ForegroundPoster = m.top.findNode("NumberPadGridItemFgPoster")

  m.top.observeField("itemContent", "onItemContentChange")
  m.top.observeField("itemHasFocus", "onItemFocusChange")

  theme = getThemeFromGlobal()
  if theme <> invalid
    m.ForegroundLabel.color = theme.primaryTextColor
    m.Background.color = theme.neutralColor2
  end if
End Function


Function onItemContentChange(msg)
  itemContent = msg.getData()
  if itemContent <> invalid
    m.ForegroundLabel.text = itemContent.title
  end if

  if itemContent.id = "back" or itemContent.id = "0"
    m.Background.width = 240
    m.ForegroundLabel.width = 240
  end if

  if itemContent.title <> ""
    m.Background.visible = false
  else
    m.ForegroundLabel.visible = true
  end if

  if itemContent.id = "back"
    m.ForegroundLabel.visible = false
    m.ForegroundPoster.visible = true
  end if
End Function


Function onItemFocusChange(msg)
  itemHasFocus = msg.getData()
  if itemHasFocus = true
    m.Background.opacity = 0
  end if
End Function

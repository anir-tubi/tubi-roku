Function init()
  m.poster = m.top.findNode("ChannelPoster")
  m.posterBg = m.top.findNode("channelPosterBG")
  m.top.observeFieldscoped("itemContent", "onContentChange")
  m.top.observeFieldscoped("focusPercent", "onFocusPercentChange")
  m.top.observeFieldscoped("itemHasFocus", "onItemHasFocus")
  m.emptyStar = m.top.findNode("emptyStar")
  m.filledStar = m.top.findNode("filledStar")


  theme = getThemeFromGlobal()
  if theme <> invalid
    m.posterBg.blendColor = theme.backgroundColor
    m.focusedColor = theme.focusedColor
    m.backgroundcolorlight = theme.backgroundcolorlight
  end if
  m.favoritesExp = (getExperimentResource("roku_linear_favorites", "roku_linear_favorites_v1", false).enabled = true)

End Function


Function onContentChange()
  item = m.top.itemContent
  if item <> invalid
    m.poster.uri = item.HDSMALLICONURL
    if m.favoritesExp = true
      if item.selected = true
        m.filledStar.visible = true
      else
        m.filledStar.visible = false
      end if
    end if
  end if
End Function


Function onFocusPercentChange()
  if m.top.focusPercent > 0.5
    m.poster.opacity = 1
    m.posterBg.opacity = 0
    if m.favoritesExp = true
      m.emptyStar.visible = true
    end if
  else
    m.poster.opacity = 0.45
    m.posterBg.opacity = 1
    if m.favoritesExp = true
      m.emptyStar.visible = false
    end if
  end if
End Function


Function onItemHasFocus()
  if m.top.itemHasFocus = true
    m.emptyStar.blendColor = m.focusedColor
    m.filledStar.blendColor = m.focusedColor
  else
    m.emptyStar.blendColor = m.backgroundcolorlight
    m.filledStar.blendColor = m.backgroundcolorlight
  end if

End Function

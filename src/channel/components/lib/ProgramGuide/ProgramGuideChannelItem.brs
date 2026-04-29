Function init()
  m.poster = m.top.findNode("ChannelPoster")
  m.posterBg = m.top.findNode("channelPosterBG")
  m.starIcon = m.top.findNode("starIcon")
  m.isEpgFavoritesExperimentEnabled = getStatsigExperimentResource("roku_epg_favorites", "roku_epg_favorites_v1", false).enabled = true
  m.observedFavoriteContent = invalid
  m.top.observeFieldscoped("itemContent", "onContentChange")
  m.top.observeFieldscoped("focusPercent", "onFocusPercentChange")
  m.top.observeFieldScoped("itemHasFocus", "onItemHasFocusChange")

  theme = getThemeFromGlobal()
  if theme <> invalid
    m.posterBg.blendColor = theme.backgroundColor
  end if

End Function


Function onContentChange()
  item = m.top.itemContent
  if item <> invalid
    m.poster.uri = item.HDSMALLICONURL
    if m.observedFavoriteContent <> invalid
      m.observedFavoriteContent.unobserveFieldScoped("isFavorite")
      m.observedFavoriteContent = invalid
    end if
    if item.hasField("isFavorite") = false
      item.addField("isFavorite", "bool", false)
    end if
    item.observeFieldScoped("isFavorite", "onIsFavoriteChange")
    m.observedFavoriteContent = item
    updateStarIcon()
  else if m.observedFavoriteContent <> invalid
    m.observedFavoriteContent.unobserveFieldScoped("isFavorite")
    m.observedFavoriteContent = invalid
  end if
End Function


Function onIsFavoriteChange(msg)
  updateStarIcon()
End Function


' EPG channel favorites — Will remove if we don't graduate roku_epg_favorites_v1 experiment.
Function updateStarIcon()
  item = m.top.itemContent
  focusPercent = 0.0
  if m.top.focusPercent <> invalid
    focusPercent = m.top.focusPercent
  end if

  if focusPercent > 0.5 AND m.isEpgFavoritesExperimentEnabled = true
    m.starIcon.opacity = 1.0

    if item <> invalid AND item.isFavorite = true
      m.starIcon.uri = "pkg:/images/icon-star-filled.webp"
    else
      m.starIcon.uri = "pkg:/images/icon-empty-star.webp"
    end if
  else
    m.starIcon.opacity = 0.0
  end if
End Function


Function onFocusPercentChange()
  if m.top.focusPercent > 0.5
    m.poster.opacity = 1
    m.posterBg.opacity = 0
  else
    m.poster.opacity = 0.45
    m.posterBg.opacity = 1
  end if
  updateStarIcon()
End Function


Function onItemHasFocusChange(msg)
  updateStarIcon()
End Function

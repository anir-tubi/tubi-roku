Function init()
  m.poster = m.top.findNode("ChannelPoster")
  m.posterBg = m.top.findNode("channelPosterBG")
  m.top.observeField("itemContent", "onContentChange")
  m.top.observeField("focusPercent", "onFocusPercentChange")

  if getExperimentResource("roku_epg_channel_poster_bigger_size", "roku_epg_channel_poster_bigger_size_v1", false).enabled = true
    'TODO:/while graduating this experiment, please remove request.brs, experiments.brs and experimentsMixin also
    m.poster.height="84"
    m.poster.width="84"
    m.poster.loadheight="84"
    m.poster.loadwidth="84"
  end if

  
  theme = getThemeFromGlobal()
  if theme <> invalid
    m.posterBg.blendColor = theme.backgroundColor
  end if

End Function


Function onContentChange()
  item = m.top.itemContent
  if item <> invalid
    m.poster.uri = item.HDSMALLICONURL
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
End Function

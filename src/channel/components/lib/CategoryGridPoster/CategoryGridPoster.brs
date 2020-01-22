Function init()
  m._ = rodash()
  m.poster = m.top.findNode("Poster")
  m.resumeProgressBar = m.top.findNode("ResumeProgressBar")
  m.top.observeField("itemContent", "onContentChange")
  m.resumeMargin = 4  'inset of resume bar
  m.title = m.top.findNode("Title")
  m.gridItemTypes = {
    portrait: "portrait"
    landscape: "landscape"
    vitg_small: "vitg_small"
    vitg_large: "vitg_large"
  }
End Function


''''''''''''''''''
' onContentChange
'
' Update the title and background on 'content' being set
Function onContentChange()
  ' set some defaults
  m.title.visible = false

  ' next line shouldn't be necessary but is added in order to try and quell crashes as reported by roku crash logs
  if m.resumeProgressBar = invalid then m.resumeProgressBar = m.top.findNode("ResumeProgressBar")
  m.resumeProgressBar.visible = false

  if m.top.itemContent <> invalid then
    m.poster.uri = m.top.itemContent.hdgridposterurl
    categoryContent = m.top.itemContent.getParent()
    if categoryContent <> invalid then
      if m.top.itemContent.gridItemType = m.gridItemTypes.landscape
        m.title.visible = true
        m.title.text = m.top.itemContent.title
      else if isVitg(m.top.itemContent, m.gridItemTypes) = true
        setUpVitg()
      else if categoryContent.title = "Continue Watching"
        drawHistoryProgressBar()
      end if
    end if
  end if
End Function


Function drawHistoryProgressBar()
  history = invalid
  if m.top.itemContent <> invalid then
    historyIds = m.global.historyIds
    if historyIds <> invalid
      history = m.global.historyIds.findNode(m.top.itemContent.id)
    end if
  end if

  if m.top.itemContent <> invalid and history <> invalid and history.nowPos <> invalid and history.nowPos <> 0 and m.top.itemContent.length <> invalid and m.top.itemContent.length <> 0 then
    drawProgressBar(history.nowPos, m.top.itemContent.length)
  end if
End Function


Function drawProgressBar(nowPos, duration)
  if duration <= 0
    percentage = 0
  else
    percentage = nowPos / duration
  end if
  if percentage > 1.0 then percentage = 1.0
  if percentage < 0.0 then percentage = 0.0
  m.resumeProgressBar.width = (m.top.width - (2 * m.resumeMargin)) * percentage
  m.resumeProgressBar.translation = [m.resumeMargin, m.top.height - m.resumeProgressBar.height - m.resumeMargin]
  m.resumeProgressBar.color = m.global.theme.focused
  m.resumeProgressBar.visible = true
End Function


Function onItemFocus()
  handleLocalFocusChange(m.top.itemHasFocus)
End Function


' @localFocus: boolean, the state of focus for the itemComponent
Function handleLocalFocusChange(newLocalFocus)
  if m.localFocus = false and newLocalFocus = true
    ' item is gaining focus - create the video player
    if m.vitg = invalid
      m.vitg = createVitgVideo()
      if m.vitg <> invalid
        m.vitg.hasFocus = newLocalFocus
      end if
    end if
  else if m.localFocus = true and newLocalFocus = false
    ' item is losing focus - so fade the poster in (as necessary) and destroy the video player
    if m.poster.opacity < 1.0
      ' stop any fade out animations that might be running
      if m.fadeOutAnimation <> invalid
        m.fadeOutAnimation.control = "stop"
      end if

      ' fade in the poster, but if there is already a fade in animation running, let it run
      if m.fadeInAnimation = invalid or m.fadeInAnimation.state <> "running"
        m.fadeInAnimation = fade(m.poster, "in", m.posterFadeTime)
      end if
    end if

    ' destroy the video player
    if m.vitg <> invalid
      ' removing focus before destroying vitg lets finish_trailer events be fired from the vitg node
      m.vitg.hasFocus = newLocalFocus
      destroyVitgVideo()
    end if
  end if

  m.localFocus = newLocalFocus
End Function


Function onRowListHasFocus()
  ' fade the poster in when focusing side nav or leaving the page
  if isVitg(m.top.itemContent, m.gridItemTypes) = true
    if m.top.rowListHasFocus = false
      handleLocalFocusChange(false)
    end if
  end if
End Function


Function onFocusPercentChange()
  if m.top.focusPercent < 1.0 and m.localFocus = true
    handleLocalFocusChange(false)
  else if m.top.focusPercent = 1.0 and m.localFocus = false and m.top.rowListHasFocus = true
    handleLocalFocusChange(true)
  end if
End Function


Function onRowFocusPercentChange()
  if isVitg(m.top.itemContent, m.gridItemTypes) = true and m.localFocus <> true
    m.poster.opacity = m._.max(m.poster.opacity, 1 - m.top.rowFocusPercent)
  end if
End Function


Function setUpVitg()
  m.top.observeField("itemHasFocus", "onItemFocus")
  m.top.observeField("rowListHasFocus", "onRowListHasFocus")
  m.top.observeField("focusPercent", "onFocusPercentChange")
  m.top.observeField("rowFocusPercent", "onRowFocusPercentChange")
  m.posterFadeTime = 0.5

  ' On various models, and due to long press horizontal scrolling, we cannot always count on
  ' m.top.itemHasFocus and m.top.focusPercent to fire as expected. In order to get around these issues,
  ' we maintain our own internal state and update it when we get info from the item component interface.

  ' local focus state; becomes true when focusPercent = 1.0 or itemHasFocus = true
  ' becomes false when focusPercent < 1.0 or itemFocus = false
  if m.localFocus = invalid
    m.localFocus = false
  end if

  m.top.id = m.top.itemContent.title

  title = m.top.itemContent.title
  if m.top.itemContent.gridItemType = "vitg_large"
    m.title.translation = [0, 692]
    m.title.width = 1205
    title = title + " (" + m.top.itemContent.releaseDate + ") " + Chr(&hb7) + " " + formatLengthAsEnglish(m.top.itemContent.length)
  end if

  m.title.visible = true
  m.title.text = title
End Function


' returns a CategoryVideoPlayer node
Function createVitgVideo()
  vitg = invalid
  if m.top.itemContent.url <> ""
    vitg = CreateObject("roSGNode", "CategoryVideoPlayer")
    m.top.insertChild(vitg, 0)
    vitg.observeField("videoState", "onVideoStateChange")
    vitg.videoUrl = m.top.itemContent.url
    vitg.trailerId = m.top.itemContent.episodeNumber 'abusing content node by using episodeNumber to store the trailer id
    vitg.width = m.top.width
    vitg.height = m.top.height

    vitg.resumePos = m.top.itemContent.resumePos
    if m.top.itemContent.resumePos >= (m.top.itemContent.playDuration - 1)   ' playDuration holds the length of the trailer
      ' trailer has already been watched to completion, start it over again
      vitg.resumePos = 0
    end if

    drawProgressBar(m.top.itemContent.resumePos, m.top.itemContent.playDuration)
  end if

  return vitg
End Function


Function destroyVitgVideo()
  if m.vitg <> invalid
    m.vitg.control = "stop"
    m.vitg.unobserveField("videoState")
    m.top.removeChild(m.vitg)
    m.top.itemContent.resumePos = Int(m.vitg.nowPos / 1000)
    drawProgressBar(m.top.itemContent.resumePos, m.top.itemContent.playDuration)
    m.vitg = invalid
  end if
End Function


Function onVideoStateChange(msg)
  state = msg.getData()

  if state = "playing"
    if m.vitg <> invalid
      m.vitg.visible = true
    end if
    m.fadeOutAnimation = fade(m.poster, "out", m.posterFadeTime)
  else
    if m.vitg <> invalid
      m.vitg.visible = false
    end if

    if state = "stopped"
      vitgPosSeconds = m.vitg.nowPos / 1000
      m.top.itemContent.resumePos = vitgPosSeconds
      drawProgressBar(vitgPosSeconds, m.top.itemContent.playDuration)
      if m.localFocus = true
        'this only occurs when the video has played to completion
        if m.fadeInAnimation = invalid or m.fadeInAnimation.state <> "running"
          m.fadeInAnimation = fade(m.poster, "in", m.posterFadeTime)
        end if
      end if
    end if
  end if
End Function


Function isVitg(itemContent, gridItemTypes)
  isVitg = false
  if itemContent.gridItemType = gridItemTypes.vitg_small or itemContent.gridItemType = gridItemTypes.vitg_large
    isVitg = true
  end if
  return isVitg
End Function
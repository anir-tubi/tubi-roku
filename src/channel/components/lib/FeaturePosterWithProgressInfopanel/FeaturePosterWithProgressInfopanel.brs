Function init()
  m.progressBar = m.top.findNode("ProgressBar")
  m.episodePoster = m.top.findNode("EpisodePoster")
  m.infoPanel = m.top.findNode("InfoPanel")

  m.top.observeFieldScoped("itemContent", "onContentChange")
  m.top.observeFieldScoped("width", "onPosterSizeChange")
  m.top.observeFieldScoped("height", "onPosterSizeChange")

  theme = getThemeFromGlobal()
  if theme <> invalid
    m.progressBar.focusColor = theme.focusedcolor
    m.progressBar.trackColor = theme.neutralcolor
    m.progressBar.unfocusColor = theme.focusedcolor
  end if

  m.resumeMargin = 6  'inset of resume bar
End Function


Function onContentChange()
  tubiLog("FeaturePosterWithProgress.onContentChange")
  item = m.top.itemContent

  if item <> invalid then
    sURI = ""

    if item.landscape <> invalid then
      sURI = item.landscape
    else
      sURI = item.hdgridposterurl
    end if

    m.episodePoster.uri = sURI

    setupProgressBar()
    populateInfoPanel(item)

    removeLockIcon()
    if item.needsLogin = true
      setLockIcon()
    end if
  end if
End Function


Function setupProgressBar()

  history = invalid
  item = m.top.itemContent

  if item <> invalid
    history = getHistory(item.id)

    if history <> invalid AND history.nowPos <> invalid AND history.nowPos > 0 AND item.length <> invalid AND item.length > 0 then
      percentage = ( history.nowPos / item.length ) * 100
      m.progressBar.progress = percentage
      m.progressBar.visible = true
    else
      m.progressBar.visible = false
    end if
  end if
End Function


Function setLockIcon()
  if m.lockIcon = invalid
    m.lockIcon = m.top.createChild("Poster")
    m.lockIcon.opacity = 0.0
    m.lockIcon.width = 48
    m.lockIcon.height = 48
    m.lockIcon.uri = "pkg:/images/icon-lock.webp"
    m.lockIcon.translation = [m.top.width - 56, 8]
    m.top.observeFieldscoped("focusPercent", "onHandleFocus")
    m.top.observeFieldScoped("rowHasFocus", "onHandleFocus")
  end if
End Function


Function removeLockIcon()
  if m.lockIcon <> invalid
    m.top.removeChild(m.lockIcon)
    m.lockIcon = invalid
    m.top.unObserveFieldscoped("focusPercent")
    m.top.unObserveFieldScoped("rowHasFocus")
  end if
End Function


' This function combines the focus percentage and rowHasFocus to determine if the lock icon should be visible
' to avoid a bug where lock icon is shown on first column.
Function onHandleFocus()
  focusPercent = m.top.focusPercent

  if m.lockIcon <> invalid
    if focusPercent > 0.1 AND m.top.rowHasFocus = true
      m.lockIcon.opacity = focusPercent
    else
      m.lockIcon.opacity = 0.0
    end if
  end if
End Function


Function onPosterSizeChange()
  m.progressBar.width = (m.top.width - 32) ' 16 left + 16 right margin
  m.progressBar.height = 8
  translationY = m.top.height - 24
  m.progressBar.translation = [16, translationY]
End Function


Function populateInfoPanel(item)

  if item <> invalid
    m.infoPanel.mode = "item"
    m.infoPanel.translation = [0, 231]
    m.infoPanel.maxHeight = 200
    m.infoPanel.width = 510
    m.infoPanel.episodeTitle = item.title
    m.infoPanel.description = item.description

    lineOneData = {}
    lineOneData.length = item.length
    lineOneData.rating = item.rating
    lineOneData.hasCC = false
    lineOneData.hasAudioDescription = false

    if item.hasSubtitles = true OR (item.subtitleTracks <> invalid AND item.subtitleTracks.isEmpty() = false)
      lineOneData.hasCC = true
    end if

    if item.hasAudioDescription = true
      lineOneData.hasAudioDescription = true
    end if

    m.infoPanel.lineOneData = lineOneData
    m.infoPanel.lineTwoData = {}
  end if

End Function

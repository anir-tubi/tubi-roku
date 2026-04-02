Function init()
  m.poster = m.top.findNode("Poster")
  m.progressBar = m.top.findNode("progressBar")
  m.top.observeField("itemContent", "onContentChange")
  m.top.observeFieldScoped("height", "onPosterSizeChange")
  m.top.observeFieldScoped("width", "onPosterSizeChange")

  if m.global <> invalid
    m.global.observeFieldScoped("refreshLinearChannels", "onRefreshLinearChannels")
  end if

  setThemeColors()
End Function


Function onRefreshLinearChannels()
  itemContent = m.top.itemContent
  updateItemContent(itemContent)
End Function


Function setThemeColors()
  theme = getThemeFromGlobal()

  if theme <> invalid
    m.progressBar.focusColor = theme.focusedcolor
    m.progressBar.trackColor = theme.neutralcolor
    m.progressBar.unfocusColor = theme.focusedcolor
  end if
End Function


Function onContentChange(msg)
  itemContent = msg.getData()
  updateItemContent(itemContent)
End Function


Function updateItemContent(itemContent)
  sPosterURL = ""

  if itemContent <> invalid
    sPosterURL = itemContent.hdgridposterurl

    if itemContent.needsLogin = true
      setLockIcon()
    else
      removeLockIcon()
    end if

    currentProgram = getCurrentliveProgram(itemContent)

    if currentProgram <> invalid
      if isNonEmptyString(currentProgram.hdgridposterurl) = true
        sPosterURL = currentProgram.hdgridposterurl
      end if

      progress = getLinearProgramProgress(currentProgram)
      setProgressBar(progress)
    else
      m.progressBar.visible = false
    end if
  end if

  m.poster.uri = sPosterURL
End Function


Function setProgressBar(progress)
  m.progressBar.progress = progress
  m.progressBar.visible = true
End Function


Function onPosterSizeChange()
  m.progressBar.width = (m.top.width - 32) ' 16 left + 16 right margin
  m.progressBar.height = 8
  translationY = m.top.height - 24
  m.progressBar.translation = [16, translationY]
End Function


Function onHandleFocus()
  focusPercent = m.top.focusPercent
  if m.lockIcon <> invalid
    if focusPercent > 0.1 AND (m.top.rowHasFocus = true OR m.top.itemHasFocus = true)
      m.lockIcon.opacity = focusPercent
    else
      m.lockIcon.opacity = 0.0
    end if
  end if
End Function


Function setLockIcon()

  if m.lockIcon = invalid
    m.lockIcon = m.top.createChild("Poster")
    m.lockIcon.opacity = 0.0
    m.lockIcon.width = 48
    m.lockIcon.height = 48
    m.lockIcon.uri = "pkg:/images/account-icon.webp"
    m.lockIcon.translation = [m.top.width - 56, 8]
    m.top.observeFieldScoped("focusPercent", "onHandleFocus")
    m.top.observeFieldScoped("rowHasFocus", "onHandleFocus")
    m.top.observeFieldScoped("itemHasFocus", "onHandleFocus")
  end if
End Function


Function removeLockIcon()
  if m.lockIcon <> invalid
    m.top.removeChild(m.lockIcon)
    m.lockIcon = invalid
    m.top.unObserveFieldScoped("focusPercent")
    m.top.unObserveFieldScoped("rowHasFocus")
    m.top.unObserveFieldScoped("itemHasFocus")
  end if
End Function

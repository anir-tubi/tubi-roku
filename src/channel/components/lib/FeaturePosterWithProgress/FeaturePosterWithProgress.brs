Function init()
  m.progressBar = m.top.findNode("ProgressBar")
  m.top.observeField("itemContent", "onContentChange")
  m.top.observeField("width", "drawProgressBar")
  m.top.observeField("height", "drawProgressBar")

  theme = getThemeFromGlobal()
  if theme <> invalid
    m.progressBar.color = theme.focusedColor
  end if

  m.resumeMargin = 6  'inset of resume bar
  drawProgressBar()
End Function


''''''''''''''''''
' onContentChange
'
' Update the title and background on 'content' being set
Function onContentChange()
  tubiLog("FeaturePosterWithProgress.onContentChange")
  if m.top.itemContent <> invalid then
    drawProgressBar()

    removeLockIcon()
    if m.top.itemContent.needsLogin = true
      setLockIcon()
    end if
  end if
End Function


Function drawProgressBar()

  history = invalid
  if m.top.itemContent <> invalid
    history = getHistory(m.top.itemContent.id)
  end if

  if history <> invalid AND history.nowPos <> invalid AND history.nowPos <> 0 AND m.top.itemContent.length <> invalid AND m.top.itemContent.length <> 0 then
    percentage = history.nowPos / m.top.itemContent.length
    if percentage > 1.0 then percentage = 1.0
    if percentage < 0.0 then percentage = 0.0
    m.progressBar.width = (m.top.width - (2 * m.resumeMargin)) * percentage
    m.progressBar.translation = [m.resumeMargin, m.top.height - m.progressBar.height - m.resumeMargin]
    m.progressBar.visible = true
  else
    m.progressBar.visible = false
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
    m.top.observeField("rowHasFocus", "onHandleFocus")
  end if
End Function


Function removeLockIcon()
  if m.lockIcon <> invalid
    m.top.removeChild(m.lockIcon)
    m.lockIcon = invalid
    m.top.unObserveFieldscoped("focusPercent")
    m.top.unObserveField("rowHasFocus")
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
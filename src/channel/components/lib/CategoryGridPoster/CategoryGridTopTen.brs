Function init()
  m.poster = m.top.findNode("Poster")
  m.topTenNumbers = m.top.findNode("topTenNumbers")
  m.bgTopTenNumbers = m.top.findNode("bgTopTenNumbers")
  m.top.observeField("itemContent", "onContentChange")
  m.top.observeFieldScoped("focusPercent", "onHandleFocus")
  m.top.observeFieldScoped("rowHasFocus", "onHandleFocus")
  setThemeColors()
End Function


Function setThemeColors()
  theme = getThemeFromGlobal()

  if theme <> invalid
    m.primaryTextColor = theme.primarytextcolor
    m.focusedColor = theme.focusedcolor
    m.topTenNumbers.blendColor = m.primaryTextColor
    m.bgTopTenNumbers.blendcolor = m.focusedColor
  end if
End Function


Function onContentChange(msg)
  itemContent = msg.getData()


  if itemContent <> invalid AND m.top.index < 10

    if itemContent.needsLogin = true
      setLockIcon()
    else
      removeLockIcon()
    end if

    m.poster.uri = itemContent.hdgridposterurl
    m.topTenNumbers.height = m.top.height
    m.topTenNumbers.uri = "pkg:/images/" + toStr(m.top.index + 1) + ".webp"

    m.bgTopTenNumbers.height = m.top.height
    m.bgTopTenNumbers.uri = "pkg:/images/" + toStr(m.top.index + 1) + ".webp"
  end if
End Function


Function onHandleFocus()
  focusPercent = m.top.focusPercent
  m.bgTopTenNumbers.opacity = focusPercent

    if focusPercent > 0.1 AND m.top.rowHasFocus = true
      if m.lockIcon <> invalid then m.lockIcon.opacity = focusPercent
    else
      if m.lockIcon <> invalid then m.lockIcon.opacity = 0.0
      m.bgTopTenNumbers.opacity = 0.0
    end if
End Function


Function setLockIcon()
  if m.lockIcon = invalid
    m.lockIcon = createObject("roSGNode", "Poster")
    m.lockIcon.opacity = 0.0
    m.lockIcon.width = 48
    m.lockIcon.height = 48
    m.lockIcon.uri = "pkg:/images/icon-lock.webp"
    m.lockIcon.translation = [m.top.width - 56, 8]
    m.top.appendChild(m.lockIcon)
  end if
End Function


Function removeLockIcon()
  if m.lockIcon <> invalid
    m.top.removeChild(m.lockIcon)
    m.lockIcon = invalid
  end if
End Function
Function init()
  m.poster = m.top.findNode("Poster")
  m.topTenNumbers = m.top.findNode("topTenNumbers")
  m.bgTopTenNumbers = m.top.findNode("bgTopTenNumbers")
  m.top.observeField("itemContent", "onContentChange")
  m.top.observeFieldScoped("focusPercent", "onFocusPercentChange")
  m.top.observeFieldScoped("itemHasFocus", "onItemHasFocusChange")
  m.previousFocusPercent = 0
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
  removeLockIcon()

  if itemContent <> invalid AND m.top.index < 10

    if itemContent.needsLogin = true
      setLockIcon()
    end if

    m.poster.uri = itemContent.hdgridposterurl
    m.topTenNumbers.height = m.top.height
    m.topTenNumbers.uri = "pkg:/images/" + toStr(m.top.index + 1) + ".webp"

    m.bgTopTenNumbers.height = m.top.height
    m.bgTopTenNumbers.uri = "pkg:/images/" + toStr(m.top.index + 1) + ".webp"
  end if
End Function


Function onFocusPercentChange(msg)
  focusPercent = msg.getData()
  m.bgTopTenNumbers.opacity = focusPercent
End Function


Function onItemHasFocusChange(msg)
  itemFocus = msg.getData()

  if itemFocus = true
    m.bgTopTenNumbers.opacity = 1.0
  else
    m.bgTopTenNumbers.opacity = 0.0
  end if

  setLockIconOpacity()
End Function


Function setLockIconOpacity()
  if m.top.itemHasFocus = false
    if m.lockIcon <> invalid then m.lockIcon.opacity = 0.0
  else
    if m.lockIcon <> invalid then m.lockIcon.opacity = 1.0
  end if
End Function


Function setLockIcon()
  if m.lockIcon = invalid
    m.lockIcon = createObject("roSGNode", "Poster")
    m.lockIcon.opacity = 0.0
    m.lockIcon.width = 21
    m.lockIcon.height = 24
    m.lockIcon.uri = "pkg:/images/icon-lock.webp"
    m.lockIcon.translation = [m.top.width - 36, 15]
    m.top.appendChild(m.lockIcon)
  end if

  setLockIconOpacity()
End Function


Function removeLockIcon()
  if m.lockIcon <> invalid
    m.top.removeChild(m.lockIcon)
  end if
End Function
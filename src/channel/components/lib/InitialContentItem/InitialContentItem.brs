Function init()
  tubiLog("InitialContentItem.init")
' trying to access m.global can sometimes/rarely time out creating a run time error if we
  ' try to access m.global.theme directly, so use GlobalMixin.getThemeFromGlobal() which retries if issues arise.
  ' same reason for using GlobalMixin.getConstantsFromGlobal() which retries if issues arise.
  m.constants  = getConstantsFromGlobal()
  theme = getThemeFromGlobal()

  m.constants = m.global.constants
  m.top.observeField("itemContent", "onContentChange")
  m.top.observeField("focusPercent", "onFocusPercentChange")
  m.top.observeField("gridHasFocus", "onFocusPercentChange")
  m.ParentGroup = m.top.findNode("parentGroup")
  m.Title = m.top.findNode("Title")
  m.TitleFocused = m.top.findNode("TitleFocused")
  m.Icon = m.top.findNode("Icon")
  m.IconFocused = m.top.findNode("IconFocused")
  m.IconFocused.blendColor = theme.focused
  m.TitleFocused.color = theme.focused
End Function


Function onContentChange()
  title = m.top.itemContent.title
  m.Title.text = title
  m.TitleFocused.text = title
  m.Icon.uri = m.top.itemContent.hdgridposterurl
  m.IconFocused.uri = m.top.itemContent.hdgridposterurl
  if m.constants.deviceInfo.limitedUi = false
    delay = .2*m.top.index
    slideFade(m.ParentGroup, "above", "in", .5, delay, 60)
  else
    '//Only animate if this is not a low device
    m.ParentGroup.opacity = 1
  end if
End Function


Function onFocusPercentChange()
  focusPercent = 0
  if m.top.gridHasFocus = true
    focusPercent = m.top.focusPercent
  end if
  m.IconFocused.opacity = focusPercent
  m.TitleFocused.opacity = focusPercent

  if m.IconFocused.opacity >= 1
      m.Title.opacity = 0
      m.Icon.opacity = 0
    else
      m.Title.opacity = 1
      m.Icon.opacity = 1
  end if
End Function

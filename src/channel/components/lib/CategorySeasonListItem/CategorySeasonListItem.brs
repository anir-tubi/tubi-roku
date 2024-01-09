Function init()
  m.categoryText = m.top.findNode("categoryText")
  m.categoryCountGroup = m.top.findNode("categoryCountGroup")
  m.categoryCountText = m.top.findNode("categoryCountText")
  m.top.observeField("itemContent", "onItemContentChange")
  m.top.observeField("focusPercent", "onFocusPercentChange")
  m.top.observeField("listHasFocus", "onContainerHasFocus")
  m.top.observeField("gridHasFocus", "onContainerHasFocus")
  m.top.observeField("rowListHasFocus", "onContainerHasFocus")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.categoryText, typographyConstants.ids.bodyMediumStrong)
  setTypographyOfLabel(m.categoryCountText, typographyConstants.ids.bodySmallStrong)

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
  onThemeChange()
End Function


Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if
  
  if theme <> invalid
    m.categoryCountText.color = theme.focusedColor
    m.categoryText.color = theme.primaryTextColor
  end if
End Function


''''''''''''''''''''
' onItemContentChange
'
' Set the label text on receiving the category name
Function onItemContentChange()
  tubiLog("CategoryListItem.onItemContentChange")
  if m.top.itemContent <> invalid then
    m.categoryText.text = m.top.itemContent.title
    if m.top.itemContent.totalCount <> invalid AND m.top.itemContent.totalCount > 0 then
      m.categoryCountText.text = stri(m.top.itemContent.totalCount)
      m.categoryCountGroup.visible = true
    else
      m.categoryCountGroup.visible = false
    end if
  else
    m.categoryCountGroup.visible = false  ' hidden until some useful value
    m.categoryText.text = ""
  end if
End Function



''''''''''''''''''''
' onFocusPercentChange
'
' Update the opacity of the totalCountGroup as the focus percent changes
Function onFocusPercentChange(msg)
  tubiLog("CategoryListItem.onFocusPercentChange")
  percent = msg.getData()
  if m.top.listHasFocus = true or m.top.gridHasFocus = true or m.top.rowListHasFocus = true
    m.categoryCountGroup.opacity = percent^3
  end if
End Function



''''''''''''''''''''
' onContainerHasFocus
'
' Update the opacity of the totalCountGroup as the focus percent changes
Function onContainerHasFocus(msg)
  tubiLog("CategoryListItem.onContainerHasFocus")
  hasFocus = msg.getData()
  if hasFocus = true
    m.categoryCountGroup.opacity = m.top.focusPercent
  else
    m.categoryCountGroup.opacity = 0.0
  end if
End Function
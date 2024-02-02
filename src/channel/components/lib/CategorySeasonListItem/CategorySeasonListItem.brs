Function init()
  m.categoryText = m.top.findNode("categoryText")
  m.focusedCategoryText = m.top.findNode("focusedCategoryText")
  m.categoryCountGroup = m.top.findNode("categoryCountGroup")
  m.categoryCountText = m.top.findNode("categoryCountText")
  m.categoryCountBackground = m.top.findNode("categoryCountBackground")
  m.focusedCategoryText.opacity = 0
  m.top.observeField("itemContent", "onItemContentChange")
  m.top.observeField("focusPercent", "onFocusPercentChange")
  m.top.observeField("listHasFocus", "onContainerHasFocus")
  m.top.observeField("gridHasFocus", "onContainerHasFocus")
  m.top.observeField("rowListHasFocus", "onContainerHasFocus")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.categoryText, typographyConstants.ids.bodyMediumStrong)
  setTypographyOfLabel(m.focusedCategoryText, typographyConstants.ids.bodyMediumStrong)
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
    'TODO: Colors will be updated once the re-brand color updates done.
    m.categoryCountText.color = theme.primaryTextColor
    m.categoryText.color = theme.primaryTextColor
    m.focusedCategoryText.color = theme.focusedTextColor
    m.categoryCountBackground.blendColor = theme.backgroundColor
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
    m.focusedCategoryText.text = m.top.itemContent.title

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

  m.focusedCategoryText.opacity = percent
  m.categoryText.opacity = 1 - percent
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
    m.focusedCategoryText.opacity = 0
    m.categoryText.opacity = 0

    if m.top.itemHasFocus = true
      fade(m.focusedCategoryText, "in", .3)
    else
      fade(m.categoryText, "in", .3)
    end if
  else
    m.categoryCountGroup.opacity = 0.0
    m.focusedCategoryText.opacity = 0
    m.categoryText.opacity = 1.0
    fade(m.categoryText, "out", .3)
  end if
End Function

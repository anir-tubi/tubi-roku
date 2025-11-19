Function init()
  topRef = m.top
  topRef.observeFieldScoped("itemContent", "onItemContentChange")
  topRef.observeFieldScoped("gridHasFocus", "onGridHasFocus")
  topRef.observeFieldScoped("focusPercent", "onFocusPercentChange")
  m.constants = getConstantsFromGlobal()

  m.title = topRef.findNode("title")
  m.subtitle = topRef.findNode("subtitle")
  m.toggleText = topRef.findNode("toggleText")
  m.titleFocused = topRef.findNode("titleFocused")
  m.subtitleFocused = topRef.findNode("subtitleFocused")
  m.toggleTextFocused = topRef.findNode("toggleTextFocused")
  m.contentSection = topRef.findNode("contentSection")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.title, typographyConstants.ids.subheaderSmall)
  setTypographyOfLabel(m.subtitle, typographyConstants.ids.bodySmall)
  setTypographyOfLabel(m.toggleText, typographyConstants.ids.subheaderSmall)

  setTypographyOfLabel(m.titleFocused, typographyConstants.ids.subheaderSmall)
  setTypographyOfLabel(m.subtitleFocused, typographyConstants.ids.bodySmall)
  setTypographyOfLabel(m.toggleTextFocused, typographyConstants.ids.subheaderSmall)

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
  onThemeChange()
End Function


Function onGridHasFocus(msg)
  gridHasFocus = msg.getData()

  if gridHasFocus = true AND m.top.itemHasFocus = true
    setFocusedUIState()
  else
    setUnfocusedUIState()
  end if
End Function


Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  m.tertiaryTextColor = invalid

  if theme <> invalid
    m.tertiaryTextColor = theme.tertiaryTextColor
    m.title.color = theme.primaryTextColor
    m.titleFocused.color = theme.focusedTextColor
    m.subtitle.color = theme.secondaryTextColor
    m.subtitleFocused.color = theme.focusedTextColor
    m.toggleText.color = theme.primaryTextColor
    m.toggleTextFocused.color = theme.focusedTextColor
  end if
End Function


Function onItemContentChange(msg)
  tubiLog("ConsentPreferenceItem.onItemContentChange")
  item = msg.getData()

  if item <> invalid then
    m.title.text = item.title
    m.titleFocused.text = item.title
    m.subtitle.text = item.subTitle
    m.subtitleFocused.text = item.subTitle

    subHeaderWidth = item.subHeaderWidth
    m.subtitle.width = subHeaderWidth
    m.subtitleFocused.width = subHeaderWidth
    m.toggleText.width = (item.totalWidth - subHeaderWidth - 60)
    m.toggleTextFocused.width = (item.totalWidth - subHeaderWidth - 60)

    if item.isRequired = true
      if m.tertiaryTextColor <> invalid
        m.toggleText.color = m.tertiaryTextColor
      end if
      m.toggleText.text = getTranslation("privacy_preferences_required")
      m.toggleTextFocused.text = getTranslation("privacy_preferences_required")
    else
      if item.value = "opted_in"
        m.toggleText.text = getTranslation("privacy_preferences_on")
        m.toggleTextFocused.text = getTranslation("privacy_preferences_on")
      else
        m.toggleText.text = getTranslation("privacy_preferences_off")
        m.toggleTextFocused.text = getTranslation("privacy_preferences_off")
      end if
    end if
  end if

  ' Vertical center align the content section.
  height = m.top.height
  itemHeight = m.contentSection.boundingRect().height
  if height > 0 AND height <> itemHeight
    m.contentSection.translation = [30, (height - itemHeight) / 2]
  end if
End Function


Function onFocusPercentChange(msg)
  focusPercent = msg.getData()
  if m.top.gridHasFocus = false
    setUnfocusedUIState()
  else
    m.title.opacity = 1 - focusPercent
    m.titleFocused.opacity = focusPercent
    m.subtitle.opacity = 1 - focusPercent
    m.subtitleFocused.opacity = focusPercent
    m.toggleText.opacity = 1 - focusPercent
    m.toggleTextFocused.opacity = focusPercent
  end if
End Function


Function setUnfocusedUIState()
  m.title.opacity = 1
  m.titleFocused.opacity = 0
  m.subtitle.opacity = 1
  m.subtitleFocused.opacity = 0
  m.toggleText.opacity = 1
  m.toggleTextFocused.opacity = 0
End Function


Function setFocusedUIState()
  m.title.opacity = 0
  m.titleFocused.opacity = 1
  m.subtitle.opacity = 0
  m.subtitleFocused.opacity = 1
  m.toggleText.opacity = 0
  m.toggleTextFocused.opacity = 1
End Function

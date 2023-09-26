Function init()
  m.timeString = m.top.findNode("timeString")
  m.programString = m.top.findNode("programString")
  m.cellRect = m.top.findNode("cellRect")
  m.titleLockGroup = m.top.findNode("titleLockGroup")
  m.staticOverlay = m.top.findNode("staticOverlay")
  m.top.observeField("rowFocusPercent", "onRowFocusPercentChange")
  m.top.observeField("focusPercent", "onFocusPercentChange")
  m.top.observeField("itemContent", "onContentChange")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.timeString, typographyConstants.ids.bodySmall_Strong)
  setTypographyOfLabel(m.programString, typographyConstants.ids.bodyMedium_Strong)

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
  m.theme = theme

  if theme <> invalid
    m.staticOverlay.blendColor = theme.backgroundColorLight2
    m.cellRect.blendColor = theme.neutralColor2
    m.timeString.color = theme.secondaryTextColor
    m.programString.color = theme.primaryTextColor
    onFocusPercentChange()    '//This function also sets the color - but depending on the focus state
  end if
End Function


Function onContentChange()
  item = m.top.itemContent
  if item <> invalid
    itemAttributes = item.itemAttributes
    m.programString.text = item.title
    m.timeString.text = item.ShortDescriptionLine1
    m.cellRect.width = item.FHDItemWidth
    m.programString.width = item.FHDItemWidth - 24
    m.timeString.width = item.FHDItemWidth - 24
    if item.selected = true
      if itemAttributes <> invalid and itemAttributes.title <> invalid
        m.timeString.text = itemAttributes.title + item.ShortDescriptionLine1
        if m.theme <> invalid
          m.timeString.color = m.theme.cautionColor
        end if
      end if
    else
      if m.theme <> invalid
        m.timeString.color = m.theme.secondaryTextColor
      end if
    end if

    if itemAttributes <> invalid AND itemAttributes.EpisodeTitle_IsPreferred = true
      m.programString.text = item.epgProgramTitle
    end if

    if item.needsLogin = true
      if m.lockIcon = invalid
        m.lockIcon = createObject("roSGNode","Poster")
        m.lockIcon.id = "lockIcon"
        m.lockIcon.width = 21
        m.lockIcon.height = 24
        m.lockIcon.opacity = 1
        m.lockIcon.uri="pkg:/images/icon-lock.webp"
        m.titleLockGroup.insertChild(m.lockIcon, 0)
        m.programString.width = item.FHDItemWidth - m.lockIcon.width - 12
      end if
    else
      if m.lockIcon <> invalid
        m.lockIcon.opacity = 0
        m.titleLockGroup.removeChild(m.lockIcon)
        m.lockIcon = invalid
      end if
    end if
  end if
  if m.timeString.text = "" or m.timeString.text = invalid
    m.titleLockGroup.translation = [24,36]
  else
    m.titleLockGroup.translation = [24,54]
  end if


  if m.top.index = 0
    m.staticOverlay.opacity = 1
  else
    m.staticOverlay.opacity = 0
  end if
End Function


Function onFocusPercentChange()
  item = m.top.itemContent
  ' //TODO : Find better logic to avoid multiple executions of this logic because of focuspercent being float and triggered multiple times.
  if item <> invalid
    if m.top.focusPercent < 0.5
      if item.selected = true

        itemAttributes = item.itemAttributes

        if itemAttributes <> invalid
          m.timeString.text = strReplace(item.ShortDescriptionLine1, itemAttributes.title, "")
        end if

        if m.theme <> invalid
          m.timeString.color = m.theme.secondaryTextColor
        end if
        item.selected = false
      end if

      if m.theme <> invalid
        if m.top.rowFocusPercent > 0.9
          m.cellRect.blendColor = m.theme.backgroundColorLight2
        else
          m.cellRect.blendColor = m.theme.neutralColor2
        end if
      end if
    else
      if m.theme <> invalid
        m.cellRect.blendColor = m.theme.backgroundColor
      end if
    end if
  end if
End Function


Function onRowFocusPercentChange()
  if m.top.rowFocusPercent > 0.5
    m.programString.opacity = 1
    m.timeString.opacity = 1
    if m.theme <> invalid
      m.cellRect.blendColor = m.theme.backgroundColorLight2
    end if
  else
    m.programString.opacity = 0.45
    m.timeString.opacity = 0.45
    if m.theme <> invalid
      m.cellRect.blendColor = m.theme.neutralColor2
      m.timeString.color = m.theme.secondaryTextColor
    end if
  end if
End Function
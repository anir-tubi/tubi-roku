Function init()
  tubiLog("SideNavIconComponent.init() ")
  m.font = m.top.findNode("Font")
  m.focusedFont = m.top.findNode("focusedFont")
  m.Label = m.top.findNode("Label")
  m.Icon = m.top.findNode("Icon")
  m.focusedLabel = m.top.findNode("focusedLabel")
  m.focusedIcon = m.top.findNode("focusedIcon")
  m.focusedLabel.opacity = 0
  m.focusedIcon.opacity = 0
  m.subTxt = m.top.findNode("subTxt")
  m.sideIconParent = m.top.findNode("sideIconParent")
  m.top.observeFieldScoped("itemContent", "onContentChange")
  m.top.observeFieldScoped("height", "onHeightChange")
  m.top.observeFieldScoped("active", "onActiveChange")
  m.top.observeFieldScoped("focusPercent", "onFocusPercentChange")
  m.top.observeFieldScoped("gridHasFocus", "onGridHasFocusChange")
  m.sideIconLabel = invalid
  m.sideIconLabelFocused = invalid

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.subTxt, typographyConstants.ids.bodyExtraSmallStrong)
  setTypographyOfLabel(m.Label, typographyConstants.ids.bodyMediumStrong)
  setTypographyOfLabel(m.focusedLabel, typographyConstants.ids.bodyMediumStrong)

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
    m.subTxt.color = theme.backgroundColorLight2
    m.Label.color = theme.primaryTextColor
    m.Icon.blendColor = theme.primaryTextColor
    m.focusedLabel.color = theme.focusedTextColor
    m.focusedIcon.blendColor = theme.backgroundColor

    if m.sideIconLabel <> invalid AND m.sideIconLabelFocused <> invalid
      m.sideIconLabel.fontColor = theme.backgroundColor
      m.sideIconLabelFocused.fontColor = theme.primaryTextColor
    end if
  end if
End Function


''''''''''''''''''
' onContentChange
'
' Update the title and background on 'content' being set
Function onContentChange(data)
  tubiLog("SideNavIconComponent.onContentChange " + data.getField())
  item = m.top.itemContent
  if item <> invalid then
    m.Icon.uri = item.iconUrl
    m.focusedIcon.uri = item.iconUrl
    m.Label.text = item.title
    m.focusedLabel.text = item.title

    if item.shortDescriptionLine1 <> invalid
      m.subTxt.text = item.shortDescriptionLine1
      if m.subTxt.text <> ""
        'subTxt needs to be centered on the sideNav. Center position of the subtext calculated using the X Position of the icon + center point of the profile icon.
        subTxtCenterPt = (m.Icon.translation[0] + (m.Icon.boundingRect().width / 2)) - ( m.subTxt.boundingRect().width / 2 )
        m.subTxt.translation = [subTxtCenterPt, 57 ]
      end if

      'add free icon next to Label when sideNav is open
      if item.shortDescriptionLine2 <> invalid
        if item.shortDescriptionLine2 <> ""
          if m.sideIconLabel = invalid AND m.sideIconLabelFocused = invalid
            createSideIconLabels(item.shortDescriptionLine2)
          end if
        else if item.shortDescriptionLine2 = "" AND m.sideIconLabel <> invalid AND m.sideIconLabelFocused <> invalid
          m.sideIconParent.removeChild(m.sideIconLabel)
          m.sideIconLabel = invalid
          m.sideIconParent.removeChild(m.sideIconLabelFocused)
          m.sideIconLabelFocused = invalid
        end if
      else if m.sideIconLabel <> invalid AND m.sideIconLabelFocused <> invalid
        m.sideIconParent.removeChild(m.sideIconLabel)
        m.sideIconLabel = invalid
        m.sideIconParent.removeChild(m.sideIconLabelFocused)
        m.sideIconLabelFocused = invalid
      end if
    end if

    onActiveChange()
    onFocusPercentChange()
  end if
End Function


Function onGridHasFocusChange()
  gridHasFocus = m.top.gridHasFocus
  m.focusedIcon.visible = gridHasFocus
  m.focusedLabel.visible = gridHasFocus
  onFocusPercentChange()
End Function


Function onFocusPercentChange()
  itemContent = m.top.itemContent
  focusPercent = m.top.focusPercent
  gridHasFocus = m.top.gridHasFocus

  m.focusedLabel.opacity = focusPercent

  if m.sideIconLabel <> invalid
    m.sideIconLabelFocused.opacity = focusPercent
    m.sideIconLabel.opacity = 1 - focusPercent
  end if

  if itemContent <> invalid then
    if itemContent.turnedOn = true then
      if gridHasFocus = true then
        m.Icon.opacity = 1 - focusPercent
        m.focusedIcon.opacity = focusPercent
      else
        m.Icon.opacity = 1
      end if
    else
      m.focusedIcon.opacity = focusPercent
      m.Icon.opacity = .31
    end if

    if itemContent.selected = true then
      m.Icon.uri = itemContent.filledIconUrl
      m.focusedIcon.uri = itemContent.filledIconUrl
    else
      m.Icon.uri = itemContent.iconUrl
      m.focusedIcon.uri = itemContent.iconUrl
    end if
  end if
End Function


Function onActiveChange()
  theme = getThemeFromGlobal()
  if m.top.itemContent.active = true
    '//is the side nav open/active?
    if m.top.itemContent.turnedOn <> false
      '//Is the button item available/turned on?

      m.Icon.opacity = 1
      fade(m.subTxt, "out", .3)
      if m.sideIconLabel <> invalid
        if theme <> invalid
          m.sideIconLabelFocused.fontColor = theme.primaryTextColor
          m.sideIconLabelFocused.blendColor = theme.focusedTextColor
        end if
        fade(m.sideIconLabel, "in", .3)
      end if

      fade(m.Label, "in", .3)
    else
      '// if the item is not enabled/available, then still don't bring up the opacity

      m.Icon.opacity = .31
      fade(m.subTxt, "out", .3)
      if m.sideIconLabel <> invalid
        if theme <> invalid
          m.sideIconLabelFocused.fontColor = theme.primaryTextColor
          m.sideIconLabelFocused.blendColor = theme.focusedTextColor
        end if
        fade(m.sideIconLabel, "in", .3, 0, .31)
      end if

      fade(m.Label, "in", .3, 0, .31)
    end if

    if m.top.itemContent.selected = true
      if m.top.gridHasFocus = true
        m.focusedIcon.uri = m.top.itemContent.filledIconUrl
      else
        m.Icon.uri = m.top.itemContent.filledIconUrl
      end if
    else
      m.Icon.uri = m.top.itemContent.iconUrl
      m.focusedIcon.uri = m.top.itemContent.iconUrl
    end if

  else
    '//when the side nav is minimized.
    fade(m.Label, "out", .3)
    m.focusedLabel.opacity = 0
    m.focusedIcon.opacity = 0
    m.Icon.opacity = 1

    if m.sideIconLabel <> invalid AND m.sideIconLabelFocused <> invalid
      fade(m.sideIconLabel, "out", .3)
      fade(m.sideIconLabelFocused, "out", .3)
    end if

    if m.top.itemContent.selected = true
      m.Icon.uri = m.top.itemContent.filledIconUrl
      fade(m.subTxt, "out", .3)
    else
      m.Icon.uri = m.top.itemContent.iconUrl
      fade(m.subTxt, "in", .3)
    end if
  end if
End Function


Function onHeightChange()
  nHeight = m.top.height
  nIconY = (nHeight - m.Icon.height)/2
  m.Icon.translation = [m.Icon.translation[0], nIconY]
  m.focusedIcon.translation = [m.Icon.translation[0], nIconY]
  m.Label.height = nHeight
  m.focusedLabel.height = nHeight
End Function


'@sideIconLabelText: String, this is the shortDescriptionLine2 text on the item.
Function createSideIconLabels(sideIconLabelText)
  theme = getThemeFromGlobal()
  m.sideIconLabel = m.sideIconParent.createChild("TextIcon")
  m.sideIconLabel.id = "SideIconLabel"

  m.sideIconLabel.padding = [12, 9]
  m.sideIconLabel.uri = "pkg:/images/tag-rounded-rectangle-background-pull-$$RES$$.9.png"
  m.sideIconLabel.opacity = 0
  m.sideIconLabel.translation = [0, 15]

  m.sideIconLabelFocused = m.sideIconParent.createChild("TextIcon")
  m.sideIconLabelFocused.id = "SideIconLabel"

  m.sideIconLabelFocused.padding = [12, 9]
  m.sideIconLabelFocused.uri = "pkg:/images/tag-rounded-rectangle-background-pull-$$RES$$.9.png"
  m.sideIconLabelFocused.opacity = 0
  m.sideIconLabelFocused.translation = [0, 15]

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.sideIconLabel, typographyConstants.ids.bodyExtraSmallStrong)
  setTypographyOfLabel(m.sideIconLabelFocused, typographyConstants.ids.bodyExtraSmallStrong)

  'Set the text after setting the Typography label so that it will not return the wrong width for label.
  m.sideIconLabel.text = sideIconLabelText
  m.sideIconLabelFocused.text = sideIconLabelText

  if theme <> invalid
    m.sideIconLabel.fontColor = theme.backgroundColor
    m.sideIconLabelFocused.fontColor = theme.primaryTextColor
  end if

End Function

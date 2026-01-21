Function init()
  tubiLog("SideNavIconComponent.init() ")
  m.font = m.top.findNode("Font")
  m.focusedFont = m.top.findNode("focusedFont")
  m.label = m.top.findNode("Label")
  m.Icon = m.top.findNode("Icon")
  m.focusedLabel = m.top.findNode("focusedLabel")
  m.focusedIcon = m.top.findNode("focusedIcon")
  m.iconParent = m.top.findNode("IconParent")
  m.focusedLabel.opacity = 0
  m.focusedIcon.opacity = 0
  m.subTxt = m.top.findNode("subTxt")
  m.bottomTxt = m.top.findNode("bottomTxt")
  m.labelParent = m.top.findNode("LabelParent")
  m.focusedBottomTxt = m.top.findNode("focusedBottomTxt")
  m.bottomTextGroup = m.top.findNode("bottomTextGroup")
  m.focusedBottomTxt.opacity = 0
  m.bottomTxt.opacity = 0
  m.textGroup = m.top.findNode("TextGroup")
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
  setTypographyOfLabel(m.label, typographyConstants.ids.bodyMediumStrong)
  setTypographyOfLabel(m.focusedLabel, typographyConstants.ids.bodyMediumStrong)
  setTypographyOfLabel(m.bottomTxt, typographyConstants.ids.bodyExtraSmall)
  setTypographyOfLabel(m.focusedBottomTxt, typographyConstants.ids.bodyExtraSmall)
  m.menuItemTextFont = typographyConstants.ids.bodyMediumStrong
  m.bodyExtraSmallStrong = typographyConstants.ids.bodyExtraSmallStrong

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
    m.primaryTextColor = theme.primaryTextColor
    m.backgroundColor = theme.backgroundColor
    m.subTxt.color = theme.backgroundColorLight2
    m.label.color = theme.primaryTextColor
    m.Icon.blendColor = theme.primaryTextColor
    m.focusedLabel.color = theme.focusedTextColor
    m.focusedIcon.blendColor = theme.backgroundColor
    m.bottomTxt.color = theme.primaryTextColor
    m.focusedBottomTxt.color = theme.focusedTextColor

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
    m.label.text = item.title
    m.focusedLabel.text = item.title

    if item.secondaryTitle <> invalid AND item.secondaryTitle <> "" 'secondaryTitle is the profile Initial
      m.focusedIcon.blendColor = m.primaryTextColor
      if m.menuItemText = invalid
        m.menuItemText = createObject("roSGNode", "Label")
        font = CreateObject("roSGNode", "Font")
        m.menuItemText.font = font
        m.menuItemText.horizAlign = "center"
        m.menuItemText.vertAlign = "center"
        setTypographyOfLabel(m.menuItemText, m.menuItemTextFont)
        m.menuItemText.id = "menuItemText"
        m.menuItemText.color = m.primaryTextColor
        m.menuItemText.width = 56
        m.menuItemText.height = 56
        menuBoundingRect = m.menuItemText.boundingRect()
        xTrans = m.icon.translation[0] + ((m.icon.width - menuBoundingRect.width) / 2)
        yTrans = m.icon.translation[1] + ((m.icon.height - menuBoundingRect.height) / 2)
        m.menuItemText.translation = [xTrans, yTrans]
        m.iconParent.appendChild(m.menuItemText)
      end if
      m.menuItemText.text = item.secondaryTitle
    else
      m.focusedIcon.blendColor = m.backgroundColor
      if m.menuItemText <> invalid
        m.iconParent.removeChild(m.menuItemText)
        m.menuItemText = invalid
      end if
    end if

    ' Handle bottom text
    if item.bottomTxt <> invalid AND item.bottomTxt <> ""
      isBottomTxtPresent = (m.bottomTextGroup.getParent() <> invalid)
      if isBottomTxtPresent = false
        m.textGroup.appendChild(m.bottomTextGroup)
      end if
      m.bottomTxt.text = item.bottomTxt
      m.focusedBottomTxt.text = item.bottomTxt
      onHeightChange()
      transY = (m.top.height - m.textGroup.boundingRect().height) / 2
      transX = m.textGroup.translation[0]
      m.textGroup.translation = [transX, transY]
    else
      m.textGroup.removeChild(m.bottomTextGroup)
      transX = m.textGroup.translation[0]
      transY = (m.top.height - m.textGroup.boundingRect().height) / 2
      m.textGroup.translation = [transX, transY]
    end if

    if item.shortDescriptionLine1 <> invalid
      m.subTxt.text = item.shortDescriptionLine1
      if m.subTxt.text <> ""
        'subTxt needs to be centered on the sideNav. Center position of the subtext calculated using the X Position of the icon + center point of the profile icon.
        subTxtCenterPt = (m.Icon.translation[0] + (m.Icon.boundingRect().width / 2)) - (m.subTxt.boundingRect().width / 2)
        m.subTxt.translation = [subTxtCenterPt, 57]
      end if

      if item.sideIconUrl <> invalid AND item.sideIconUrl <> "" 'sideIconUrl is downArror or upArrow
        if m.sideIconLabel = invalid AND m.sideIconLabelFocused = invalid
          createSideIconLabels("", item.sideIconUrl)
        end if
        m.sideIconLabel.uri = item.sideIconUrl
        m.sideIconLabelFocused.uri = item.sideIconUrl
      else if item.sideIconUrl = "" AND item.sideIconUrl <> invalid
        if m.sideIconLabel <> invalid
          m.sideIconParent.removeChild(m.sideIconLabel)
          m.sideIconLabel = invalid
        end if

        if m.sideIconLabelFocused <> invalid
          m.sideIconParent.removeChild(m.sideIconLabelFocused)
          m.sideIconLabelFocused = invalid
        end if

        'add free icon next to Label when sideNav is open
        if item.shortDescriptionLine2 <> invalid
          if item.shortDescriptionLine2 <> ""
            if m.sideIconLabel = invalid AND m.sideIconLabelFocused = invalid
              sideUri = "pkg:/images/tag-rounded-rectangle-background-pull-$$RES$$.9.png"
              createSideIconLabels(item.shortDescriptionLine2, sideUri)
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
    end if
    onActiveChange()
    onFocusPercentChange()
  end if
End Function


Function onGridHasFocusChange()
  gridHasFocus = m.top.gridHasFocus
  m.focusedIcon.visible = gridHasFocus
  m.focusedLabel.visible = gridHasFocus
  m.focusedBottomTxt.visible = gridHasFocus
  onFocusPercentChange()
End Function


Function onFocusPercentChange()
  itemContent = m.top.itemContent
  focusPercent = m.top.focusPercent
  gridHasFocus = m.top.gridHasFocus

  m.focusedLabel.opacity = focusPercent
  m.focusedBottomTxt.opacity = focusPercent

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

      fade(m.label, "in", .3)
      fade(m.bottomTxt, "in", .3)

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

      fade(m.label, "in", .3, 0, .31)
      fade(m.bottomTxt, "in", .3, 0, .31)
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
    fade(m.label, "out", .3)
    m.focusedLabel.opacity = 0
    m.focusedIcon.opacity = 0
    m.Icon.opacity = 1

    fade(m.bottomTxt, "out", .3)
    m.focusedBottomTxt.opacity = 0

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
  nIconY = (nHeight - m.Icon.height) / 2
  m.Icon.translation = [m.Icon.translation[0], nIconY]
  m.focusedIcon.translation = [m.Icon.translation[0], nIconY]

  bottomTxtPresent = (m.bottomTextGroup.getParent() <> invalid)
  if bottomTxtPresent = true
    bottomTxtHeight = m.bottomTxt.boundingRect().height
    labelHeight = nHeight - bottomTxtHeight - 18 'padding
    m.label.height = labelHeight
    m.focusedLabel.height = labelHeight
  else
    m.label.height = nHeight
    m.focusedLabel.height = nHeight
  end if
End Function


'@sideIconLabelText: String, this is the shortDescriptionLine2 text on the item.
Function createSideIconLabels(sideIconLabelText, sideIconLabelUrl)
  theme = getThemeFromGlobal()
  m.sideIconLabel = m.sideIconParent.createChild("TextIcon")
  m.sideIconLabel.id = "SideIconLabel"

  m.sideIconLabel.padding = [12, 9]
  m.sideIconLabel.uri = sideIconLabelUrl
  m.sideIconLabel.opacity = 0
  m.sideIconLabel.translation = [0, 15]

  m.sideIconLabelFocused = m.sideIconParent.createChild("TextIcon")
  m.sideIconLabelFocused.id = "SideIconLabel"

  m.sideIconLabelFocused.padding = [12, 9]
  m.sideIconLabelFocused.uri = sideIconLabelUrl
  m.sideIconLabelFocused.opacity = 0
  m.sideIconLabelFocused.translation = [0, 15]

  if sideIconLabelText <> ""

    setTypographyOfLabel(m.sideIconLabel, m.bodyExtraSmallStrong)
    setTypographyOfLabel(m.sideIconLabelFocused, m.bodyExtraSmallStrong)

    'Set the text after setting the Typography label so that it will not return the wrong width for label.
    m.sideIconLabel.text = sideIconLabelText
    m.sideIconLabelFocused.text = sideIconLabelText
  end if

  if theme <> invalid
    m.sideIconLabel.fontColor = theme.backgroundColor
    m.sideIconLabelFocused.fontColor = theme.primaryTextColor
  end if

End Function

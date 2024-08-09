Function init()
  m.top.observeField("itemContent", "onItemContentChange")
  m.top.observeFieldScoped("width", "onWidthChange")
  m.top.observeFieldScoped("height", "onHeightChange")
  m.top.observeFieldScoped("itemHasFocus", "onItemHasFocus")
  m.top.observeFieldScoped("gridHasFocus", "onGridHasFocus")
  m.top.observeFieldScoped("focusPercent", "onFocusPercentChange")
  m.buttonBG = m.top.findNode("buttonBG")

  m.Icon = m.top.findNode("Icon")
  m.IconParent = m.top.findNode("IconParent")
  m.IconFocused = m.top.findNode("IconFocused")
  m.DetailsMenuTextParent = m.top.findNode("DetailsMenuTextParent")
  m.DetailsMenuText = m.top.findNode("DetailsMenuText")
  m.DetailsMenuTextFocused = m.top.findNode("DetailsMenuTextFocused")
  m.top.leftTextPadding = m.DetailsMenuTextParent.translation[0]
  m.Progress = m.top.findNode("ResumeProgressBar")
  m.Progress.opacity = 0
  m.DetailsMenuTextFocused.opacity = 0
  m.IconFocused.opacity = 0
  m.badgeLabel = m.top.findNode("badgeLabel")
  m.badgeLabel.padding = [12, 9]
  m.badgeLabelFocused = m.top.findNode("badgeLabelFocused")
  m.badgeLabelFocused.padding = [12, 9]
  m.badgeLabelFocused.opacity = 0

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.DetailsMenuText, typographyConstants.ids.bodyMediumStrong)
  setTypographyOfLabel(m.DetailsMenuTextFocused, typographyConstants.ids.bodyMediumStrong)
  setTypographyOfLabel(m.badgeLabel, typographyConstants.ids.bodyExtraSmallStrong)
  setTypographyOfLabel(m.badgeLabelFocused, typographyConstants.ids.bodyExtraSmallStrong)

  m.constants = getConstantsFromGlobal()
  if m.constants <> invalid
    m.top.color = m.constants.ui.colors.transparent
  end if

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
    m.Progress.color = theme.focusedTextColor
    m.buttonBG.blendColor = theme.neutralColor2
    m.DetailsMenuText.color = theme.primaryTextColor
    m.DetailsMenuTextFocused.color = theme.focusedTextColor
    m.badgeLabel.fontColor = theme.focusedTextColor
    m.badgeLabel.blendColor = theme.primaryTextColor
    m.badgeLabelFocused.fontColor = theme.primaryTextColor
    m.badgeLabelFocused.blendColor = theme.focusedTextColor
    m.Icon.blendcolor = theme.primaryTextColor
    m.IconFocused.blendcolor = theme.focusedTextColor
  end if
End Function


Function onWidthChange()
  m.buttonBG.width = m.top.width
  setUIBasedOnSetWidth()
End Function


' Set properties of some UI elements if the width had been set
Function setUIBasedOnSetWidth()
  '//Do not set the width until the content has been set
  item = m.top.itemContent
  nWidth = m.top.width
  if nWidth > 0 AND item <> invalid
    nRightPadding = m.IconParent.translation[0] * 1.5
    nLeftPadding = m.DetailsMenuText.translation[0]
    nTextWidth = nWidth - nLeftPadding - nRightPadding
    m.DetailsMenuTextFocused.width = nTextWidth
    m.DetailsMenuText.width = nTextWidth
    m.top.calculatedTextWidth = nTextWidth
  end if
End Function


Function onHeightChange()
  m.buttonBG.height = m.top.height
End Function


Function onItemContentChange()
  tubiLog("DetailMenuItem.onItemContentChange")
  if m.top.itemContent <> invalid then
    item = m.top.itemContent
    'If the button has title and BadgeText, calculated width will be width of both title and badgeText to avoid button crop. To get the
    'calculated width we are assigning the title and badgeText to the m.DetailsMenuText and get the calculated value
    'and after setting the calculatedWidth resetting m.DetailsMenuText.text to title.
    sTitle = item.title
    if item.badgeText <> invalid AND item.badgeText <> ""
      sTitle = sTitle + item.badgeText
    end if

    m.DetailsMenuText.text = sTitle
    m.DetailsMenuTextFocused.text = sTitle
    m.DetailsMenuText.horizAlign = "left"
    m.DetailsMenuTextFocused.horizAlign = "left"
    iconWidth = 0

    bVisibleImage = true
    bVisibleBadgeText = true
    'adding extra width for focus if icon is present
    if item.iconUrl <> invalid AND item.iconUrl <> ""
      m.Icon.uri = item.iconUrl
      m.IconFocused.uri = item.iconUrl
      m.DetailsMenuTextParent.translation = [72, 0]
    else
      'Move the translation of Button text to left when there is no image
      m.DetailsMenuTextParent.translation = [m.IconParent.translation[0], 0]
      bVisibleImage = false
    end if

    nDetailsMenuTextBoundingWidth = m.DetailsMenuText.boundingRect().width 
    m.top.calculatedTextWidth = nDetailsMenuTextBoundingWidth + iconWidth
    m.DetailsMenuText.text = item.title
    m.DetailsMenuTextFocused.text = item.title
    setUIBasedOnSetWidth()

    m.buttonBG.visible = item.isUnfocusedFootprintEnabled

    if item.playstart <> invalid AND item.playstart <> 0.0 AND item.length <> invalid AND item.length <> 0.0 then
      showProgressBar(m.top.itemContent.playstart / item.length)
    else
      m.Progress.visible = false
    end if

    m.top.calculatedWidth = m.top.calculatedTextWidth + m.DetailsMenuTextParent.translation[0]
    calculatedWidth = nDetailsMenuTextBoundingWidth + m.DetailsMenuTextParent.translation[0]

    if item.badgeText <> invalid AND item.badgeText <> ""
      m.badgeLabel.text = item.badgeText
      m.badgeLabel.visible = true
      m.badgeLabel.translation = [calculatedWidth + 20, 20]
      m.badgeLabelFocused.text = item.badgeText
      m.badgeLabelFocused.visible = true
      m.badgeLabelFocused.translation = [calculatedWidth + 20, 20]
    else
      m.badgeLabel.visible = false
      m.badgeLabelFocused.visible = false
      bVisibleBadgeText = false
    end if

    'This is for Continue Watching row in home screen. It has only one item and we can't focus inside the item, so making the
    'focused text visible so that it looks like the item is focused.
    if isNonEmptyString(item.contentItemType) = true AND item.contentItemType = "continueWatching"
      m.DetailsMenuText.opacity = 0
      m.DetailsMenuTextFocused.opacity = 1
    end if
    
    if bVisibleImage = false AND bVisibleBadgeText = false
      'Adjusting the DetailsMenuText text to center when there is no iconUrl and badge label text.
      if item.align = "center"
        xTranslation = (m.top.width - m.top.calculatedTextWidth) / 2
        m.DetailsMenuTextParent.translation = [xTranslation, 0]
        m.DetailsMenuText.horizAlign = item.align
        m.DetailsMenuTextFocused.horizAlign = item.align
      end if
    end if

  end if
End Function


Function showProgressBar(percentage As Double)
  tubiLog("DetailMenuItem.showProgressBar")
  if percentage > 1.0 then percentage = 1.0
  if percentage < 0.0 then percentage = 0.0
  ' width of menu item is 440, 4 pixel margin for progress bar
  m.Progress.width = (m.top.width - 8.0) * percentage
  m.Progress.visible = true
End Function


Function onItemHasFocus()
  theme = getThemeFromGlobal()
  if theme <> invalid
    if m.top.itemHasFocus = true AND m.top.focusPercent = 1
      '//Sometimes m.top.itemHasFocus is set to true when it should not: i.e. navigating really qucikly down a menu for some reason confuses the m.top.itemHasFocus setting.
      '// so verify that focusPercent is set to 1
      m.buttonBG.blendcolor = theme.focusedColor
    else
      m.buttonBG.blendcolor = theme.neutralColor
    end if
  end if

  '//Call setFocusUI() on the chance that a Menu Item's focusPercent does not get changed. For example, a list's jumpToItem is called which may bypass setting of focusPercent 
  setFocusUI()
End Function


Function onGridHasFocus(msg)
  gridHasFocus = msg.getData()
  if m.top.itemContent <> invalid
    '//do not change the menu item's focus UI until the itemContent has been set. this ensures that the look of the 1st item is set properly as the focus to the 1st item can be gained and lost even before the itemContent has been set
    '//Sometimes m.top.itemHasFocus is set to true when it should not: i.e. navigating really qucikly down a menu for some reason confuses the m.top.itemHasFocus setting.
    '// so verify that focusPercent is set to 1
    if gridHasFocus = true AND m.top.itemHasFocus = true AND m.top.focusPercent = 1
      m.DetailsMenuTextFocused.opacity = 1.0
      m.DetailsMenuText.opacity = 0
      m.IconFocused.opacity = 1.0
      m.Icon.opacity = 0
      m.badgeLabelFocused.opacity = 1.0
      m.badgeLabel.opacity = 0
    else
      m.DetailsMenuTextFocused.opacity = 0
      m.DetailsMenuText.opacity = 1.0
      m.IconFocused.opacity = 0
      m.Icon.opacity = 1.0
      m.badgeLabelFocused.opacity = 0
      m.badgeLabel.opacity = 1.0
    end if
  end if
End Function


Function onFocusPercentChange()
  setFocusUI()
End Function


Function setFocusUI()
  focusPercent = m.top.focusPercent
  if m.top.gridHasFocus = true
    m.DetailsMenuText.opacity = 1 - focusPercent
    m.DetailsMenuTextFocused.opacity = focusPercent
    m.Icon.opacity = 1 - focusPercent
    m.IconFocused.opacity = focusPercent
    m.badgeLabel.opacity = 1 - focusPercent
    m.badgeLabelFocused.opacity = focusPercent
  else
    m.DetailsMenuTextFocused.opacity = 0
    m.DetailsMenuText.opacity = 1.0
    m.IconFocused.opacity = 0
    m.Icon.opacity = 1.0
    m.badgeLabelFocused.opacity = 0
    m.badgeLabel.opacity = 1.0
  end if

  m.Progress.opacity = focusPercent
End Function

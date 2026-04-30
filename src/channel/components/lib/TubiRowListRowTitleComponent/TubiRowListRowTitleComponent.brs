Function init()
  m.exclusiveContentRow = m.top.findNode("exclusiveContentRow")
  m.titleLabel = m.top.findNode("titleLabel")

  m.enhancedButton = invalid
  m.exclusiveContentBadgeGroup = invalid

  m.top.observeFieldScoped("content", "onContentChange")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.titleLabel, typographyConstants.ids.subheaderMedium)

  m.global.observeFieldScoped("theme", "onThemeChange")
  onThemeChange()
End Function


Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.titleLabel.color = theme.primaryTextColor
  end if
End Function


Function onContentChange()
  content = m.top.content
  if content <> invalid then
    m.titleLabel.text = content.title

    if content.hasField("isRowFocused") then
      content.unobserveFieldScoped("isRowFocused")
      content.observeFieldScoped("isRowFocused", "onIsRowFocusedChange")

      if m.enhancedButton = invalid then
        m.enhancedButton = createObject("roSGNode", "EnhancedButton")
        m.enhancedButton.height = 72
        m.enhancedButton.padding = 24
        m.enhancedButton.backgroundUri = "pkg:/images/pill_button_72_$$RES$$.9.png"
      end if

      content.update({
        "isPrimaryButton": true
        "rightAlignedIcon": true
        "iconUrl": "pkg:/images/icon_chevron_right.png"
      }, true)

      m.enhancedButton.itemContent = content

      if m.enhancedButton.getParent() = invalid OR m.enhancedButton.getParent().id <> m.exclusiveContentRow.id then
        m.exclusiveContentRow.insertChild(m.enhancedButton, 0)
      end if

      m.exclusiveContentRow.visible = true

      m.titleLabel.scale = [0, 0]
      m.titleLabel.visible = false
    else if m.enhancedButton <> invalid then
      if m.enhancedButton.itemContent <> invalid then
        m.enhancedButton.itemContent.unobserveFieldScoped("isRowFocused")
      end if

      if m.enhancedButton.getParent() <> invalid AND m.enhancedButton.getParent().id = m.exclusiveContentRow.id then
        m.exclusiveContentRow.removeChild(m.enhancedButton)
      end if
      m.enhancedButton = invalid

      removeExclusiveContentBadgeGroupIfPresent()

      m.titleLabel.scale = [1, 1]
      m.titleLabel.visible = true
    end if

    updateOnlyOnTubiRowTitleUi(content)
  else
    if m.enhancedButton <> invalid AND m.enhancedButton.getParent() <> invalid AND m.enhancedButton.getParent().id = m.exclusiveContentRow.id then
      m.exclusiveContentRow.removeChild(m.enhancedButton)
    end if
    m.enhancedButton = invalid

    removeExclusiveContentBadgeGroupIfPresent()

    updateOnlyOnTubiRowTitleUi(invalid)
  end if
End Function


Function removeExclusiveContentBadgeGroupIfPresent() as Void
  if m.exclusiveContentBadgeGroup = invalid
    return
  end if

  m.exclusiveContentBadgeGroup.exclusiveContentInfo = invalid

  if m.exclusiveContentBadgeGroup.getParent() <> invalid AND m.exclusiveContentBadgeGroup.getParent().id = m.exclusiveContentRow.id then
    m.exclusiveContentRow.removeChild(m.exclusiveContentBadgeGroup)
  end if
  m.exclusiveContentBadgeGroup = invalid
End Function


Function updateOnlyOnTubiRowTitleUi(content) as Void
  if content = invalid OR m.exclusiveContentRow = invalid
    removeExclusiveContentBadgeGroupIfPresent()
    return
  end if

  useEnhancedRowTitle = content.hasField("isRowFocused") AND m.enhancedButton <> invalid
  showBadge = useEnhancedRowTitle AND content.hasField("showOnlyOnTubiRowTitle") AND content.showOnlyOnTubiRowTitle = true

  if showBadge = false
    removeExclusiveContentBadgeGroupIfPresent()
    return
  end if

  badgeType = ""
  if content.hasField("sotBadgeType") AND content.sotBadgeType <> invalid
    badgeType = content.sotBadgeType.toStr().trim()
  end if

  if isNonEmptyString(badgeType) = false
    removeExclusiveContentBadgeGroupIfPresent()
    return
  end if

  if m.enhancedButton = invalid OR m.enhancedButton.getParent() = invalid OR m.enhancedButton.getParent().id <> m.exclusiveContentRow.id
    if m.exclusiveContentBadgeGroup <> invalid
      m.exclusiveContentBadgeGroup.exclusiveContentInfo = invalid
    end if
    return
  end if

  if m.exclusiveContentBadgeGroup = invalid
    m.exclusiveContentBadgeGroup = createObject("roSGNode", "ExclusiveContentBadgeGroup")
    m.exclusiveContentBadgeGroup.id = "exclusiveContentBadgeGroup"
  end if

  m.exclusiveContentBadgeGroup.exclusiveContentInfo = {
    targetGroup: m.exclusiveContentRow
    exclusiveSignalsInsertIndex: 1
    linePromoData: invalid
    content: content
  }
End Function


Function onIsRowFocusedChange(msg)
  if m.enhancedButton <> invalid AND m.enhancedButton.getParent() <> invalid AND m.enhancedButton.getParent().id = m.exclusiveContentRow.id then
    m.enhancedButton.itemHasFocus = msg.getData()
  end if

  if m.top.content <> invalid
    updateOnlyOnTubiRowTitleUi(m.top.content)
  end if
End Function

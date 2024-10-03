Function init()
  topRef = m.top
  topRef.observeFieldScoped("itemContent", "onItemContentChange")
  topRef.observeFieldScoped("focusPercent", "onFocusPercentChange")
  topRef.observeFieldScoped("gridHasFocus", "onFocusPercentChange")

  m.icon = topRef.findNode("menuItemIcon")
  m.iconFocused = topRef.findNode("menuItemIconFocused")
  m.title = topRef.findNode("menuItemText")
  m.titleFocused = topRef.findNode("menuItemTextFocused")

  m.bottomItemText = topRef.findNode("bottomItemText")
  m.buttonBg = topRef.findNode("menuItemBg")
  m.buttonBgFocused = topRef.findNode("menuItemBgFocused")

  m.badge = topRef.findNode("badge")
  m.badgeBackground = topRef.findNode("badgeBackground")
  m.badgeText = topRef.findNode("badgeText")

  m.badgeFocused = topRef.findNode("badgeFocused")
  m.badgeBackgroundFocused = topRef.findNode("badgeBackgroundFocused")
  m.badgeTextFocused = topRef.findNode("badgeTextFocused")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.title, typographyConstants.ids.bodyMediumStrong)
  setTypographyOfLabel(m.titleFocused, typographyConstants.ids.bodyMediumStrong)

  setTypographyOfLabel(m.bottomItemText, typographyConstants.ids.bodySmallStrong)

  setTypographyOfLabel(m.badgeText, typographyConstants.ids.bodyExtraSmallStrong)
  setTypographyOfLabel(m.badgeTextFocused, typographyConstants.ids.bodyExtraSmallStrong)

  m.defaultTitleTranslation = m.title.translation

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
    m.focusedColor = theme.focusedColor
    m.primaryTextColor = theme.primaryTextColor
    m.bgColor = theme.backgroundcolor
    m.secondaryTextColor = theme.secondaryTextColor

    m.icon.blendcolor = theme.primaryTextColor
    m.iconFocused.blendcolor = theme.backgroundcolor

    m.titleFocused.color = theme.backgroundcolor
    m.title.color = theme.primaryTextColor

    m.badgeText.color = theme.backgroundcolor
    m.badgeBackground.blendcolor = theme.primaryTextColor

    m.badgeTextFocused.color = theme.primaryTextColor
    m.badgeBackgroundFocused.blendcolor = theme.backgroundcolor

    m.bottomItemText.color = theme.focusedColor
    m.buttonBgFocused.blendcolor = theme.focusedColor
    m.buttonBg.blendcolor = theme.neutralColor2
  end if
End Function


Function onItemContentChange()
  tubiLog("DetailMenuItem.onItemContentChange")
  if m.top.itemContent <> invalid then
    item = m.top.itemContent

    m.icon.uri = item.iconUrl
    m.iconFocused.uri = item.iconUrl

    padding = 32 ' This value represents the left and right padding for the button.
    itemSpacing = 16

    ' Hiding the values by default and only enabling if required.
    m.buttonBg.visible = false
    m.badge.visible = false
    m.badgeFocused.visible = false

    if item.isPrimaryButton = true
      m.title.text = item.title
      m.titleFocused.text = item.title

      m.bottomItemText.text = ""
      textWidth = m.title.boundingRect().width
      width = textWidth + 52 ' 36 icon size + 16 spacing between icon and text

      ' title translation x.
      titleTransX = m.defaultTitleTranslation[0]

      m.title.translation = m.defaultTitleTranslation
      m.titleFocused.translation = m.defaultTitleTranslation

      badgeWidth = 0
      if item.badgeText <> ""
        m.badgeText.text = item.badgeText
        m.badgeTextFocused.text = item.badgeText

        badgeTextWidth = m.badgeText.boundingRect().width
        badgeWidth = badgeTextWidth + (18 * 2) ' 18 is the padding around text.

        ' Setting the badge background width.
        m.badgeBackground.width = badgeWidth
        m.badgeBackgroundFocused.width = badgeWidth

        ' Centering aligning the text within background.
        badgeTextTransX = (badgeWidth / 2) - (badgeTextWidth / 2)
        m.badgeText.translation = [badgeTextTransX, 0]
        m.badgeTextFocused.translation = [badgeTextTransX, 0]

        ' Positing the badge.
        ' Center aligning to center of the button.
        transY = (m.top.height / 2) - (m.badgeBackground.height / 2)
        transX = titleTransX +  textWidth + itemSpacing
        m.badge.translation = [transX, transY]
        m.badgeFocused.translation = [transX, transY]

        m.badge.opacity = 1

        ' Using both visible and opacity so that we can control it for cases where we do not have badge.
        m.badge.visible = true
        m.badgeFocused.visible = true

        width += badgeWidth + itemSpacing
      end if

      m.top.calculatedTextWidth = width
      m.buttonBg.visible = true
      m.buttonBg.width = padding + width + padding
      m.buttonBgFocused.width = m.buttonBg.width

      if item.iconUrl = ""
        m.title.translation = [(m.buttonBg.width / 2) - (textWidth / 2), 32]
        m.titleFocused.translation = [(m.buttonBg.width / 2) - (textWidth / 2), 32]
      end if

    else
      m.bottomItemText.text = item.title
      m.title.text = ""
      m.titleFocused.text = ""
      m.top.calculatedTextWidth =  52
      m.buttonBg.visible = false
    end if

    if item.disabled = true
      m.title.color = m.secondaryTextColor
      m.titleFocused.color = m.secondaryTextColor
      m.buttonBgFocused.uri = "pkg:/images/large_pill_disabled_focus_$$RES$$.9.png"
    else
      m.buttonBgFocused.uri = "pkg:/images/pill_button_$$RES$$.9.png"
      m.titleFocused.color = m.bgColor
      m.title.color = m.primaryTextColor
    end if
  end if
End Function


Function onFocusPercentChange()
  focusPercent = m.top.focusPercent
  
  if m.top.gridHasFocus = true
    updateUnfocusedFraction(1 - focusPercent)
    updateFocusedFraction(focusPercent)
  else
    updateUnfocusedFraction(1)
    updateFocusedFraction(0)
  end if
End Function


Function updateUnfocusedFraction(opacity)
  m.title.opacity = opacity
  m.icon.opacity = opacity
  m.badge.opacity = opacity
End Function


Function updateFocusedFraction(opacity)
  m.titleFocused.opacity = opacity
  m.iconFocused.opacity = opacity
  m.badgeFocused.opacity = opacity
  m.bottomItemText.opacity = opacity
  m.buttonBgFocused.opacity = opacity
End Function

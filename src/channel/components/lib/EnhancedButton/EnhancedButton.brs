Function init()
  topRef = m.top
  topRef.observeFieldScoped("itemContent", "onItemContentChange")
  topRef.observeFieldScoped("focusedChild", "onFocusedChildChange")
  topRef.observeFieldScoped("itemHasFocus", "onItemHasFocusChange")

  m.icon = topRef.findNode("icon")
  m.iconFocused = topRef.findNode("iconFocused")
  m.label = topRef.findNode("label")
  m.labelFocused = topRef.findNode("labelFocused")
  m.iconGroup = topRef.findNode("iconGroup")

  m.buttonBackground = topRef.findNode("buttonBackground")
  m.buttonBackgroundFocused = topRef.findNode("buttonBackgroundFocused")

  m.badgeGroup = topRef.findNode("badgeGroup")
  m.badge = topRef.findNode("badge")
  m.badgeBackground = topRef.findNode("badgeBackground")
  m.badgeText = topRef.findNode("badgeText")

  m.badgeFocused = topRef.findNode("badgeFocused")
  m.badgeBackgroundFocused = topRef.findNode("badgeBackgroundFocused")
  m.badgeTextFocused = topRef.findNode("badgeTextFocused")

  m.elementsGroup = topRef.findNode("elementsGroup")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.label, typographyConstants.ids.bodyMediumStrong)
  setTypographyOfLabel(m.labelFocused, typographyConstants.ids.bodyMediumStrong)

  setTypographyOfLabel(m.badgeText, typographyConstants.ids.bodyExtraSmallStrong)
  setTypographyOfLabel(m.badgeTextFocused, typographyConstants.ids.bodyExtraSmallStrong)

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if

  topRef.focusable = true

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
    m.backgroundColor = theme.backgroundColor
    m.secondaryTextColor = theme.secondaryTextColor

    m.icon.blendColor = theme.primaryTextColor
    m.iconFocused.blendColor = theme.backgroundColor

    m.labelFocused.color = theme.backgroundColor
    m.label.color = theme.primaryTextColor

    m.badgeText.color = theme.backgroundColor
    m.badgeBackground.blendColor = theme.primaryTextColor

    m.badgeTextFocused.color = theme.primaryTextColor
    m.badgeBackgroundFocused.blendColor = theme.backgroundColor

    m.buttonBackgroundFocused.blendColor = theme.focusedColor
    m.buttonBackground.blendColor = theme.neutralColor2
  end if
End Function


Function onItemContentChange()
  if m.top.itemContent <> invalid then
    item = m.top.itemContent

    if isNonEmptyString(item.iconUrl)
      if m.iconGroup.getParent() = invalid
        m.elementsGroup.insertChild(m.iconGroup, 0)
      end if
      m.icon.uri = item.iconUrl
      m.iconFocused.uri = item.iconUrl
      m.iconGroup.visible = true
    else
      m.elementsGroup.removeChild(m.iconGroup)
    end if

    padding = 48 ' This value represents the left and right padding for the button.
    ' Hiding the values by default and only enabling if required.
    m.buttonBackground.visible = false
    m.badge.visible = false
    m.badgeFocused.visible = false

    if item.isPrimaryButton = true
      m.label.text = item.title
      m.labelFocused.text = item.title

      badgeWidth = 0
      if isNonEmptyString(item.badgeText)
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

        m.badge.opacity = 1

        ' Using both visible and opacity so that we can control it for cases where we do not have badge.
        m.badge.visible = true
        m.badgeFocused.visible = true
      else
        m.elementsGroup.removeChild(m.badgeGroup)
      end if
      m.buttonBackground.visible = true
      buttonContentWidth = m.elementsGroup.boundingRect().width
      m.top.calculatedTextWidth = buttonContentWidth
      m.buttonBackground.width = buttonContentWidth + (padding * 2)
      m.buttonBackgroundFocused.width = m.buttonBackground.width
      m.elementsGroup.translation = [48, m.top.height / 2]

    else
      m.label.text = ""
      m.labelFocused.text = ""
      m.top.calculatedTextWidth = 52
      m.buttonBackground.visible = false
    end if

    if item.disabled = true
      m.label.color = m.secondaryTextColor
      m.labelFocused.color = m.secondaryTextColor
      m.buttonBackgroundFocused.uri = "pkg:/images/large_pill_disabled_focus_$$RES$$.9.png"
    else
      m.buttonBackgroundFocused.uri = "pkg:/images/pill_button_$$RES$$.9.png"
      m.labelFocused.color = m.backgroundColor
      m.label.color = m.primaryTextColor
    end if
  end if
End Function


Function onFocusedChildChange()
  updateUIBasedOnFocus(m.top.hasFocus())
End Function


Function onItemHasFocusChange(msg)
  itemHasFocus = msg.getData()
  updateUIBasedOnFocus(itemHasFocus)
End Function


Function updateUIBasedOnFocus(itemHasFocus)
  if itemHasFocus = true
    updateUnfocusedFraction(0)
    updateFocusedFraction(1)
  else
    updateUnfocusedFraction(1)
    updateFocusedFraction(0)
  end if
End Function


Function updateUnfocusedFraction(opacity)
  m.label.opacity = opacity
  m.icon.opacity = opacity
  m.badge.opacity = opacity
End Function


Function updateFocusedFraction(opacity)
  m.labelFocused.opacity = opacity
  m.iconFocused.opacity = opacity
  m.badgeFocused.opacity = opacity
  m.buttonBackgroundFocused.opacity = opacity
End Function


Function onKeyEvent(key as String, press as Boolean) as Boolean
  if press = true AND (key = "OK" OR key = "play")
    m.top.wasSelected = true
    return true
  end if
  return false
End Function
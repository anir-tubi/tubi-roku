' Initializes the EnhancedButton component
' Sets up node references, observers, typography, and theme
Function init() as Void
  topRef = m.top
  topRef.observeFieldScoped("itemContent", "onItemContentChange")
  topRef.observeFieldScoped("focusedChild", "onFocusedChildChange")
  topRef.observeFieldScoped("itemHasFocus", "onItemHasFocusChange")
  topRef.observeFieldScoped("hideFocusFootprint", "onHideFocusFootprintChange")
  topRef.observeFieldScoped("backgroundUri", "onBackgroundUriChange")
  topRef.observeFieldScoped("backgroundBlendColor", "onBackgroundBlendColorChange")

  ' Cache all node references
  m.icon = topRef.findNode("icon")
  m.iconFocused = topRef.findNode("iconFocused")
  m.label = topRef.findNode("label")
  m.labelFocused = topRef.findNode("labelFocused")
  m.iconGroup = topRef.findNode("iconGroup")
  m.labelGroup = topRef.findNode("labelGroup")

  m.buttonBackground = topRef.findNode("buttonBackground")
  m.buttonBackgroundFocused = topRef.findNode("buttonBackgroundFocused")

  m.badgeGroup = topRef.findNode("badgeGroup")
  m.badge = topRef.findNode("badge")
  m.badgeBackground = topRef.findNode("badgeBackground")
  m.badgeText = topRef.findNode("badgeText")

  m.badgeFocused = topRef.findNode("badgeFocused")
  m.badgeBackgroundFocused = topRef.findNode("badgeBackgroundFocused")
  m.badgeTextFocused = topRef.findNode("badgeTextFocused")

  m.titleGroup = topRef.findNode("titleGroup")
  m.subtitle = topRef.findNode("subtitle")

  m.progressBar = topRef.findNode("progressBar")

  m.elementsGroup = topRef.findNode("elementsGroup")

  ' Set typography for all text elements
  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.label, typographyConstants.ids.bodyMediumStrong)
  setTypographyOfLabel(m.labelFocused, typographyConstants.ids.bodyMediumStrong)

  bodyExtraSmallStrongFont = typographyConstants.ids.bodyExtraSmallStrong
  setTypographyOfLabel(m.badgeText, bodyExtraSmallStrongFont)
  setTypographyOfLabel(m.badgeTextFocused, bodyExtraSmallStrongFont)
  setTypographyOfLabel(m.subtitle, bodyExtraSmallStrongFont)
  m.fonts = typographyConstants.ids

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if

  topRef.focusable = true
  topRef.enableRenderTracking = true

  onThemeChange()
End Function


' Handles theme changes and applies colors to all button elements
' Updates colors for focused/unfocused states, icons, labels, badges, and progress bar
' @param msg - Optional message object containing theme data
Function onThemeChange(msg = invalid) as Void
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

    ' Icon colors (skip when disableIconBlend is set, e.g. creator logos)
    if m.top.itemContent = invalid OR m.top.itemContent.disableIconBlend <> true
      m.icon.blendColor = theme.primaryTextColor
      m.iconFocused.blendColor = theme.backgroundColor
    end if

    ' Label colors
    m.label.color = theme.primaryTextColor
    m.labelFocused.color = theme.backgroundColor

    ' Badge colors (unfocused state)
    m.badgeText.color = theme.backgroundColor
    m.badgeBackground.blendColor = theme.primaryTextColor

    ' Badge colors (focused state)
    m.badgeTextFocused.color = theme.primaryTextColor
    m.badgeBackgroundFocused.blendColor = theme.backgroundColor

    ' Button background colors
    if isNonEmptyString(m.top.backgroundBlendColor)
      m.buttonBackground.blendColor = m.top.backgroundBlendColor
    else
      m.buttonBackground.blendColor = theme.neutralColor2
    end if
    m.buttonBackgroundFocused.blendColor = theme.focusedColor

    ' Subtitle color
    m.subtitle.color = theme.backgroundColor

    ' Progress bar colors
    m.progressBar.focusColor = theme.backgroundColor
    m.progressBar.trackColor = theme.shadeColor4
    m.progressBar.unFocusColor = theme.primaryTextColor
  end if
End Function


' Handles item content changes
' Renders the button and updates disabled state styling if needed
Function onItemContentChange() as Void
  if m.top.itemContent = invalid then return

  item = m.top.itemContent

  ' Allow backgroundUri override through itemContent
  if isNonEmptyString(item.backgroundUri)
    m.top.backgroundUri = item.backgroundUri
  end if

  ' Allow padding override through itemContent
  if isInteger(item.padding)
    m.top.padding = item.padding
  end if

  renderButton(item, item.isPrimaryButton, false)

  if item.disabled = true
    m.label.color = m.secondaryTextColor
    m.labelFocused.color = m.secondaryTextColor
    m.buttonBackgroundFocused.uri = "pkg:/images/large_pill_disabled_focus_$$RES$$.9.png"
  else
    m.buttonBackgroundFocused.uri = m.top.backgroundUri
    m.labelFocused.color = m.backgroundColor
    m.label.color = m.primaryTextColor
  end if
End Function


' Handles focused child changes
' Updates button state and propagates focus state to wasFocused field
Function onFocusedChildChange() as Void
  itemHasFocus = m.top.hasFocus()
  m.top.wasFocused = itemHasFocus
  updateButtonState(itemHasFocus)
End Function


' Handles itemHasFocus field changes from parent
' Updates button state and propagates focus state to wasFocused field
' @param msg - Message object containing focus state
Function onItemHasFocusChange(msg as Object) as Void
  itemHasFocus = msg.getData()
  m.top.wasFocused = itemHasFocus
  updateButtonState(itemHasFocus)
End Function


' Updates button state based on focus
' Re-renders button if needed and updates UI opacity for focused/unfocused states
' @param itemHasFocus - Boolean, whether button currently has focus
Function updateButtonState(itemHasFocus as Boolean) as Void
  item = m.top.itemContent
  if item = invalid then return

  if (item.isPrimaryButton <> true OR item.displayOnlyIconTileWhenNotFocused = true)
    if m.top.showFocusedLabelBelow = true
      isPrimaryButton = (item.isPrimaryButton = true)
    else
      isPrimaryButton = (itemHasFocus OR (item.isPrimaryButton = true))
    end if
    renderButton(item, isPrimaryButton, itemHasFocus)
  end if
  updateUIBasedOnFocus(itemHasFocus)

  if m.progressBar.getParent() <> invalid
    m.progressBar.isInFocusChain = itemHasFocus
  end if
End Function


' Updates UI element visibility based on focus state
' Shows focused elements when focused, shows unfocused elements when not focused
' @param itemHasFocus - Boolean, whether button currently has focus
Function updateUIBasedOnFocus(itemHasFocus as Boolean) as Void
  if itemHasFocus = true
    updateUnfocusedFraction(0)
    updateFocusedFraction(1)
  else
    updateUnfocusedFraction(1)
    updateFocusedFraction(0)
  end if
End Function


' Updates opacity for unfocused elements
' @param opacity - Float, opacity value (0-1)
Function updateUnfocusedFraction(opacity as Float) as Void
  m.label.opacity = opacity
  m.icon.opacity = opacity
  m.badge.opacity = opacity
End Function


' Updates opacity for focused elements
' @param opacity - Float, opacity value (0-1)
Function updateFocusedFraction(opacity as Float) as Void
  m.labelFocused.opacity = opacity
  m.iconFocused.opacity = opacity
  m.badgeFocused.opacity = opacity
  m.buttonBackgroundFocused.opacity = opacity
End Function


' Renders the button based on content and state
' Handles icon, label, badge, subtitle, and progress bar visibility and positioning
' Calculates button width dynamically based on content
' @param item - Object, button content data (title, iconUrl, badgeText, subtitle, progress, etc.)
' @param isPrimaryButton - Boolean, whether to render as primary button (full width) or icon-only
' @param itemHasFocus - Boolean, whether button currently has focus
Function renderButton(item as Object, isPrimaryButton as Dynamic, itemHasFocus as Boolean) as Void
  disableIconBlend = (item.disableIconBlend = true)

  if isNonEmptyString(item.iconUrl)
    if m.iconGroup.getParent() = invalid
      m.elementsGroup.insertChild(m.iconGroup, 0)
    end if
    m.icon.uri = item.iconUrl
    m.iconFocused.uri = item.iconUrl
    if item.iconWidth <> invalid AND item.iconHeight <> invalid
      m.icon.width = item.iconWidth
      m.icon.height = item.iconHeight
      m.iconFocused.width = item.iconWidth
      m.iconFocused.height = item.iconHeight
    end if
    if disableIconBlend = true
      m.icon.blendColor = "0xFFFFFFFF"
      m.iconFocused.blendColor = "0xFFFFFFFF"
    end if
    m.iconGroup.visible = true
  else
    m.elementsGroup.removeChild(m.iconGroup)
  end if

  m.titleGroup.removeChild(m.subtitle)

  m.titleGroup.removeChild(m.progressBar)

  padding = m.top.padding ' This value represents the left and right padding for the button.
  ' Hiding the values by default and only enabling if required.
  m.badge.visible = false
  m.badgeFocused.visible = false

  shouldShowSecondaryText = (itemHasFocus = true OR item.displayOnlyIconTileWhenNotFocused <> true)

  if isPrimaryButton = true

    if m.labelGroup.getParent() = invalid
      m.elementsGroup.appendChild(m.labelGroup)
    end if

    if m.badgeGroup.getParent() = invalid
      m.elementsGroup.appendChild(m.badgeGroup)
    end if


    m.label.text = item.title
    m.labelFocused.text = item.title

    if isNonEmptyString(item.subtitle) AND shouldShowSecondaryText
      if m.subtitle.getParent() = invalid
        m.titleGroup.appendChild(m.subtitle)
      end if
      m.subtitle.text = item.subtitle
    end if

    if isNumber(item.progress)
      m.progressBar.progress = item.progress
      if m.progressBar.getParent() = invalid
        m.progressBar.width = m.titleGroup.boundingRect().width
        m.titleGroup.appendChild(m.progressBar)
      end if
    end if

    badgeWidth = 0
    if isNonEmptyString(item.badgeText) AND shouldShowSecondaryText
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
    buttonContentWidth = m.elementsGroup.boundingRect().width
    m.top.calculatedTextWidth = buttonContentWidth
    m.buttonBackground.width = buttonContentWidth + (padding * 2)
    m.buttonBackgroundFocused.width = m.buttonBackground.width
    m.elementsGroup.translation = [padding, m.top.height / 2]

    if isNonEmptyString(item.iconUrl) = true
      if item.rightAlignedIcon = true
        m.iconGroup.reParent(m.elementsGroup, false)
      else
        m.elementsGroup.insertChild(m.iconGroup, 0)
      end if
    end if
  else
    m.buttonBackground.opacity = 0
    m.label.text = ""
    m.labelFocused.text = ""
    m.top.calculatedTextWidth = 52
    m.elementsGroup.removeChild(m.labelGroup)
    m.elementsGroup.removeChild(m.badgeGroup)

    iconWidth = m.icon.width
    if iconWidth = 0 then iconWidth = 36

    m.buttonBackground.width = 105
    m.buttonBackgroundFocused.width = m.buttonBackground.width

    iconPadding = Int((105 - iconWidth) / 2)
    m.elementsGroup.translation = [iconPadding, m.top.height / 2]
  end if
End Function


' Handles hideFocusFootprint field changes
' Shows or hides button background based on focus footprint setting
' @param msg - Message object containing hideFocusFootprint boolean
Function onHideFocusFootprintChange(msg as Object) as Void
  hideFocusFootprint = msg.getData()
  item = m.top.itemContent
  if hideFocusFootprint = true
    m.buttonBackground.uri = "pkg:/images/transparent.png"
  else if item <> invalid AND item.disabled = true
    m.buttonBackground.uri = "pkg:/images/large_pill_disabled_focus_$$RES$$.9.png"
  else
    m.buttonBackground.uri = m.top.backgroundUri
  end if
End Function


' Handles backgroundBlendColor field changes
' Updates button background blend color when backgroundBlendColor changes
' @param msg - Message object containing blend color string
Function onBackgroundBlendColorChange(msg as Object) as Void
  blendColor = msg.getData()
  if isNonEmptyString(blendColor)
    m.buttonBackground.blendColor = blendColor
  end if
End Function


' Handles backgroundUri field changes
' Updates button background image when backgroundUri changes
' Note: Not using alias due to it becoming bi-directional and since we update background uri
' within the component we would lose the original value
' @param msg - Message object containing background URI string
Function onBackgroundUriChange(msg as Object) as Void
  m.buttonBackground.uri = msg.getData()
End Function


' Handles key press events for button selection
' Triggers wasSelected when OK or play is pressed.
' @param key - String, the key that was pressed
' @param press - Boolean, true if key was pressed (not released)
' @return Boolean - True if event was handled, false otherwise
Function onKeyEvent(key as String, press as Boolean) as Boolean

  if press then
    m.top.pressedKey = key

    if key = "OK" OR key = "play" then
      m.top.wasSelected = true
      return true
    end if
  end if

  return false
End Function
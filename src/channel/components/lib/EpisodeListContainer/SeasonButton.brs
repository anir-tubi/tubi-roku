' Initializes the Season Button component
' Sets up node references, observers for content and focus changes
' Configures typography, theme, and finds parent ArrayGrid for focus tracking
Function init()
  topRef = m.top
  topRef.observeFieldScoped("itemContent", "onItemContentChange")
  topRef.observeFieldScoped("focusPercent", "onFocusPercentChange")
  topRef.observeFieldScoped("rowHasFocus", "onFocusPercentChange")

  m.label = topRef.findNode("label")
  m.labelFocused = topRef.findNode("labelFocused")
  m.labelGroup = topRef.findNode("labelGroup")
  m.buttonBackground = topRef.findNode("buttonBackground")
  m.buttonBackgroundFocused = topRef.findNode("buttonBackgroundFocused")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.label, typographyConstants.ids.bodyMediumStrong)
  setTypographyOfLabel(m.labelFocused, typographyConstants.ids.bodyMediumStrong)

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if

  ' Find parent ArrayGrid that contains the rowItemFocused field
  nodeHelpers = TubiNodeHelpers()
  m.parentArrayGrid = nodeHelpers.findParentWithField(topRef, "rowItemFocused")

  topRef.focusable = true
  onThemeChange()
End Function


' Handles theme changes and applies colors
' @param msg - Optional message containing theme data
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

    m.labelFocused.color = theme.backgroundColor
    m.label.color = theme.primaryTextColor
    m.buttonBackgroundFocused.blendColor = theme.focusedColor
    m.buttonBackground.blendColor = theme.neutralColor
  end if
End Function


' Handles item content changes and updates button labels
' Sets the season title text for both normal and focused label states
sub onItemContentChange()
  item = m.top.itemContent
  if item = invalid then return

  m.label.text = item.title
  m.labelFocused.text = item.title
end sub


' Handles focus percent changes and animates button focus state
' Smoothly transitions opacity between normal and focused states
' Triggers background update when focus animation completes
Function onFocusPercentChange()
  focusPercent = m.top.focusPercent
  rowHasFocus = m.top.rowHasFocus

  if rowHasFocus = true then
    ' Animate between normal and focused states
    m.buttonBackgroundFocused.opacity = focusPercent
    m.labelFocused.opacity = focusPercent
    m.buttonBackground.opacity = 1 - focusPercent
    m.label.opacity = 1 - focusPercent
  else
    ' Row doesn't have focus - show normal state
    m.buttonBackgroundFocused.opacity = 0
    m.labelFocused.opacity = 0
    m.buttonBackground.opacity = 1
    m.label.opacity = 1
  end if

  ' Update background when focus animation completes
  if focusPercent = 1 then
    updateButtonBackground()
  end if
End Function


' Updates the button background image based on focus state
' Shows a tab background image for the last focused item when row loses focus
' This maintains visual indication of the selected season
sub updateButtonBackground()
  if m.parentArrayGrid = invalid then
    m.buttonBackground.uri = "pkg:/images/transparent.png"
    return
  end if

  ' Try to get focused index from rowItemFocused first, fallback to jumpToRowItem
  ' Note: jumpToRowItem does not update rowItemFocused if the list hasn't gained focus yet,
  ' so we use it as a fallback to determine which button should show the selected state
  focusedIndex = invalid
  if isNonEmptyArray(m.parentArrayGrid.rowItemFocused) then
    focusedIndex = m.parentArrayGrid.rowItemFocused[1]
  else if isNonEmptyArray(m.parentArrayGrid.jumpToRowItem) then
    focusedIndex = m.parentArrayGrid.jumpToRowItem[1]
  end if

  ' If we still don't have a focused index, use transparent background
  if focusedIndex = invalid then
    m.buttonBackground.uri = "pkg:/images/transparent.png"
    return
  end if

  isLastFocusedItem = (m.top.index = focusedIndex)
  rowLostFocus = (m.top.rowHasFocus = false)

  ' Show selected background only for last focused item when row loses focus
  if rowLostFocus AND isLastFocusedItem then
    m.buttonBackground.uri = "pkg:/images/tabs-bg-$$RES$$.9.png"
  else
    m.buttonBackground.uri = "pkg:/images/transparent.png"
  end if
end sub

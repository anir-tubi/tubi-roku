' Initialize the GroupDetailItem component
'
' Sets up node references, observers, typography, and theme
' Configures focus and checkmark visibility
Function init() as Void
  topRef = m.top

  ' Cache node references
  m.label = topRef.findNode("label")
  m.labelFocused = topRef.findNode("labelFocused")
  m.background = topRef.findNode("background")
  m.checkIcon = topRef.findNode("checkIcon")
  m.checkIconFocused = topRef.findNode("checkIconFocused")

  ' Set up observers
  topRef.observeFieldScoped("itemContent", "onItemContentChange")
  topRef.observeFieldScoped("width", "onWidthChange")
  topRef.observeFieldScoped("gridHasFocus", "onGridHasFocusChange")
  topRef.observeFieldScoped("itemHasFocus", "onGridHasFocusChange")
  topRef.observeFieldScoped("focusPercent", "onFocusPercentChange")

  ' Set typography once
  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.label, typographyConstants.ids.bodySmallStrong)
  m.labelFocused.font = m.label.font

  ' Set up theme observer and apply initial theme
  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
  onThemeChange()
End Function


' Handle theme changes and update colors
'
' @param msg (optional) Message object containing the new theme, or invalid to fetch current theme
Function onThemeChange(msg = invalid) as Void
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.label.color = theme.primaryTextColor
    m.labelFocused.color = theme.focusedTextColor
    m.background.color = theme.focusedColor
    m.checkIcon.blendColor = theme.primaryTextColor
    m.checkIconFocused.blendColor = theme.focusedTextColor
  end if
End Function


' Handle item content changes
'
' Updates the label text and checkmark visibility based on the content
' Shows checkmark if this is the currently active experiment variant
'
' @param msg Message object containing the item content data
Function onItemContentChange(msg) as Void
  itemContent = msg.getData()
  if itemContent <> invalid then
    m.label.text = itemContent.title
    m.labelFocused.text = itemContent.title

    ' Show checkmark if this is the current variant
    isChecked = (itemContent.checked = true)
    m.checkIcon.visible = isChecked
    m.checkIconFocused.visible = isChecked
  end if
End Function


' Handle width changes
'
' Updates label widths and background width based on the item width
' Accounts for checkmark space (72px)
'
' @param msg Message object containing the new width
Function onWidthChange(msg) as Void
  width = msg.getData()
  labelWidth = width - 72
  m.label.width = labelWidth
  m.labelFocused.maxWidth = labelWidth
  m.background.width = width
End Function


' Handle focus percent changes for smooth focus animations
'
' Crossfades between normal and focused states (labels and checkmarks)
' Only animates when grid has focus
'
' @param msg Message object containing the focus percentage (0.0 to 1.0)
Function onFocusPercentChange(msg) as Void
  if m.top.gridHasFocus = true
    focusPercent = msg.getData()
    m.background.opacity = focusPercent
    m.label.opacity = 1 - focusPercent
    m.labelFocused.opacity = focusPercent
    m.checkIcon.opacity = 1 - focusPercent
    m.checkIconFocused.opacity = focusPercent
  else
    m.labelFocused.opacity = 0
    m.checkIconFocused.opacity = 0
  end if
End Function


' Handle grid focus changes
'
' Shows focused state when both grid has focus and item has focus
' Manages opacity for background, labels, and checkmark icons
'
' @param _msg Message object (unused, focus state read from m.top)
Function onGridHasFocusChange(_msg) as Void
  itemHasFocus = (m.top.gridHasFocus = true AND m.top.itemHasFocus = true)

  if itemHasFocus = true
    m.background.opacity = 1
    m.label.opacity = 0
    m.labelFocused.opacity = 1
    m.checkIcon.opacity = 0
    m.checkIconFocused.opacity = 1
  else
    m.background.opacity = 0
    m.label.opacity = 1
    m.labelFocused.opacity = 0
    m.checkIcon.opacity = 1
    m.checkIconFocused.opacity = 0
  end if
End Function

' PivotItem - A specialized EnhancedButton for pivot list items
' Extends EnhancedButton with pivot-specific behavior


' Initializes the PivotItem component
Function init() as Void
  topRef = m.top
  topRef.padding = 24
  ' Cache pivot-specific node references and insert as first child (behind all other elements)
  m.pivotBackground = topRef.findNode("pivotBackground")
  topRef.insertChild(m.pivotBackground, 0)

  ' Override button background URIs to use pivot-specific 9-patch
  pivotBgUri = "pkg:/images/pivot-background-$$RES$$.9.png"
  m.buttonBackground.uri = pivotBgUri
  m.buttonBackgroundFocused.uri = pivotBgUri
  topRef.backgroundUri = pivotBgUri

  ' Observe width/height to sync pivotBackground size
  topRef.observeFieldScoped("width", "onPivotItemSizeChange")
  topRef.observeFieldScoped("height", "onPivotItemSizeChange")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.label, typographyConstants.ids.bodySmallStrong)
  setTypographyOfLabel(m.labelFocused, typographyConstants.ids.bodySmallStrong)

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onPivotItemThemeChange")
  end if
  onPivotItemThemeChange()
End Function


' Applies pivot-specific theme colors
' Overrides button background to neutralColor and sets pivotBackground to shadeColor4
' @param msg - Optional message containing theme data
Function onPivotItemThemeChange(msg = invalid) as Void
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.buttonBackground.blendColor = theme.neutralColor
    m.pivotBackground.blendColor = theme.shadeColor4
  end if
End Function


' Syncs pivotBackground width and height with the button
Function onPivotItemSizeChange(msg = invalid) as Void
  topRef = m.top
  m.pivotBackground.width = topRef.width
  m.pivotBackground.height = topRef.height
End Function

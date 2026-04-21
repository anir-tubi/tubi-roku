' AppItem - Unified grid tile for app-type content.
' Handles both creator apps (gridItemType=appItem) and event hub tiles
' (gridItemType=eventHubTile). Displays a logo with the app/hub title below.


' Initializes component: caches nodes, sets up observers and theme
Function init() as Void
  topRef = m.top

  m.background = topRef.findNode("background")
  m.logo = topRef.findNode("logo")
  m.title = topRef.findNode("title")

  m.typographyConstants = getTypographyConstants()

  topRef.observeFieldScoped("itemContent", "onItemContentChange")
  topRef.observeFieldScoped("width", "onSizeChange")
  topRef.observeFieldScoped("height", "onSizeChange")

  m.constants = getConstantsFromGlobal()

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
  onThemeChange()
End Function


' Applies theme colors to the title label and background
' @param msg - Optional message containing theme data
Function onThemeChange(msg = invalid) as Void
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme = invalid then return

  m.title.color = theme.primaryTextColor
  m.background.blendColor = theme.neutralColor
End Function


' Populates the tile from itemContent. Resolves the logo URI from
' content.logo (creator apps) or content.hdGridPosterUrl (event hub tiles).
' Supports optional titleTypography override with bodyMediumStrong fallback.
Function onItemContentChange(msg = invalid) as Void
  itemContent = m.top.itemContent
  if itemContent = invalid then return

  if isNonEmptyString(itemContent.logo)
    m.logo.uri = itemContent.logo
  else if isNonEmptyString(itemContent.hdGridPosterUrl)
    m.logo.uri = itemContent.hdGridPosterUrl
  end if

  m.title.text = itemContent.title

  typographyOverrides = { lineSpacing: 2 }
  if isNonEmptyString(itemContent.titleTypography)
    setTypographyOfLabel(m.title, itemContent.titleTypography, typographyOverrides)
  else if itemContent.type = m.constants.ui.appTypes.explore
    setTypographyOfLabel(m.title, m.typographyConstants.ids.bodySmallStrong, typographyOverrides)
  else
    setTypographyOfLabel(m.title, m.typographyConstants.ids.bodyMediumStrong, typographyOverrides)
  end if

  updateLayout()
End Function


' Re-layouts when width or height change after initial content assignment
Function onSizeChange(msg = invalid) as Void
  if m.top.itemContent <> invalid then updateLayout()
End Function


' Calculates logo, background, and title sizes based on the component width and height
Function updateLayout() as Void
  tileWidth = m.top.width
  tileHeight = m.top.height
  if tileWidth <= 0 OR tileHeight <= 0 then return

  m.background.width = tileWidth
  m.background.height = tileHeight

  logoSize = tileWidth - 48
  m.logo.width = logoSize
  m.logo.height = logoSize
  m.title.width = tileWidth - 48
  m.title.translation = [24, tileHeight - 24 - m.title.boundingRect().height]
End Function

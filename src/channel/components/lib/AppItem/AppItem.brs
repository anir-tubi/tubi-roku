' AppItem - Grid tile for app-type content (e.g. creator apps in search results)
' Displays a circular logo on a solid background with the app name below


' Initializes component: caches nodes, sets typography in init and colors in onThemeChange
Function init() as Void
  topRef = m.top
  typographyConstants = getTypographyConstants()

  m.background = topRef.findNode("background")
  m.contentGroup = topRef.findNode("contentGroup")
  m.logo = m.contentGroup.findNode("logo")
  m.title = m.contentGroup.findNode("title")

  setTypographyOfLabel(m.title, typographyConstants.ids.bodyMediumStrong)

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
  onThemeChange()

  topRef.observeFieldScoped("itemContent", "onItemContentChange")
  topRef.observeFieldScoped("width", "onWidthChange")
End Function


' Applies theme colors to the title label and background
' @param msg - Optional message containing theme data
Function onThemeChange(msg = invalid) as Void
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.background.blendColor = theme.neutralSolidColor2
    m.title.color = theme.primaryTextColor
  end if
End Function


' Handles itemContent changes and populates the tile
' @param msg - Field change message
Function onItemContentChange(msg as Object) as Void
  content = m.top.itemContent
  if content = invalid then return

  m.title.text = content.title
  m.logo.uri = content.logo
End Function


' Handles width changes and updates the content group translation and title width
' @param msg - Field change message
Function onWidthChange(msg as Object) as Void
  width = msg.getData()
  m.contentGroup.translation = [width / 2, 0]
  m.title.width = width
End Function

' Initializes the MyStuffEmptyVideoTile component
' Sets up node references, observers, typography, and theme colors
' Used for displaying empty state messages in My Stuff screen when in video tiles experiment
Function init()
  topRef = m.top
  m.border = topRef.findNode("border")
  m.contentSection = topRef.findNode("contentSection")
  m.icon = topRef.findNode("icon")
  m.title = topRef.findNode("title")
  m.subtitle = topRef.findNode("subtitle")

  topRef.observeFieldScoped("itemContent", "onItemContentChange")
  topRef.observeFieldScoped("itemHasFocus", "onItemHasFocusChange")
  topRef.observeFieldScoped("rowHasFocus", "onItemHasFocusChange")
  topRef.observeFieldScoped("rowListHasFocus", "onItemHasFocusChange")
  topRef.observeFieldScoped("width", "adjustContentAlignment")
  topRef.observeFieldScoped("height", "adjustContentAlignment")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.title, typographyConstants.ids.subheaderMedium)
  setTypographyOfLabel(m.subtitle, typographyConstants.ids.bodyMedium)

  setThemeColors()
End Function


' Applies theme colors to the component elements
' Sets text colors for title and subtitle, and border colors for focus states
Function setThemeColors()
  theme = getThemeFromGlobal()

  if theme <> invalid
    m.title.color = theme.primaryTextColor
    m.subtitle.color = theme.primaryTextColor
    m.focusedColor = theme.focusedColor
    m.neutralColor2 = theme.neutralColor2
    m.border.blendColor = m.neutralColor2
  end if
End Function


' Handles content updates when itemContent field changes
' Populates icon, title, and subtitle from the content node
' Uses existing metadata field names: iconUrl, title, and description
Function onItemContentChange()
  itemContent = m.top.itemContent
  if itemContent <> invalid
    ' Use existing field names from metadata: iconUrl and description
    if isNonEmptyString(itemContent.iconUrl) = true
      m.icon.uri = itemContent.iconUrl
    end if
    if isNonEmptyString(itemContent.title) = true
      m.title.text = itemContent.title
    end if
    if isNonEmptyString(itemContent.description) = true
      m.subtitle.text = itemContent.description
    end if
  end if
End Function


' Adjusts content alignment based on tile dimensions
' Centers the icon horizontally and centers the content section vertically
' Called when width or height changes
Function adjustContentAlignment()
  if m.top.width > 0 AND m.top.height > 0
    contentHeight = m.contentSection.boundingRect().height
    m.icon.translation = [(m.top.width - m.icon.width) / 2, 0]
    m.contentSection.translation = [0, (m.top.height - contentHeight) / 2]
  end if
End Function


' Handles focus state changes for the tile
' Updates border color based on whether the item has focus
' Focus is determined by itemHasFocus, rowHasFocus, and rowListHasFocus
Function onItemHasFocusChange(_msg)
  itemHasFocus = ((m.top.rowHasFocus = true OR m.top.itemHasFocus = true) AND m.top.rowListHasFocus = true)
  if itemHasFocus = true
    m.border.blendColor = m.focusedColor
  else
    m.border.blendColor = m.neutralColor2
  end if
End Function

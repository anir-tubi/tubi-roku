Function init()
  m.Background = m.top.findNode("Background")
  m.Title = m.top.findNode("Title")
  m.top.observeField("itemContent", "onContentChange")
  m.top.observeField("width", "onWidthChange")
  m.top.observeField("height", "onHeightChange")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.Title, typographyConstants.ids.bodyMedium)

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
    m.Title.color = theme.primaryTextColor
    m.focusedTextColor = theme.focusedTextColor
  end if
End Function



''''''''''''''''''
' onContentChange
'
' Update the title and background on 'content' being set
Function onContentChange()
  tubiLog("FeaturePoster.onContentChange")
  itemContent = m.top.itemContent

  if itemContent <> invalid then
    ' If series content, we show a 16:9 poster, otherwise a DVD-aspect poster
    sURI = ""
    if itemContent.landscape <> invalid then
      sURI = itemContent.landscape
    else
      sURI = itemContent.hdgridposterurl
    end if

    m.Background.uri = sURI

    m.Title.text = itemContent.title

    'Adding the Badge info on the poster. Currently we are not adding the badge for linear content. It might be added in future.
    sotPosterLabels = itemContent.sotPosterLabels
    ' this is to avoid rowlist reusing the same badge without adjusting to the new text.
    if m.sotBadge <> invalid
      m.top.removeChild(m.sotBadge)
      m.sotBadge = invalid
    end if

    if itemContent.type <> "linear" AND isAA(sotPosterLabels) = true AND sotPosterLabels.count() > 0
      badgeUri = sotPosterLabels.sotIcon
      badgeText = sotPosterLabels.sotLabelText
      setSotBadge(badgeUri, badgeText)
    end if
  end if
End Function


Function setSotBadge(badgeUri, badgeText)
  if isNonEmptyString(badgeText) = true
    if m.sotBadge = invalid
      m.sotBadge = createObject("roSGNode", "Badge")
      m.sotBadge.id = "sotBadge"
      m.sotBadge.translation = [6, 6]
    end if

    m.sotBadge.textColor = m.focusedTextColor
    m.sotBadge.iconUri = badgeUri
    m.sotBadge.maxWidth = m.Background.width - 12
    m.sotBadge.text = badgeText
    m.sotBadge.visible = true
    m.top.appendChild(m.sotBadge)

  end if
End Function


Function onWidthChange()
  m.Title.width = m.top.width - 20
End Function


Function onHeightChange()
  m.Title.translation = [m.Title.translation[0], Int(m.top.height) + 15]
End Function

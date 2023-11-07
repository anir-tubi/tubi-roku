Function init()
  m.Background = m.top.findNode("Background")
  m.Title = m.top.findNode("Title")
  m.top.observeField("itemContent", "onContentChange")
  m.top.observeField("width", "onWidthChange")
  
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
  end if
End Function



''''''''''''''''''
' onContentChange
'
' Update the title and background on 'content' being set
Function onContentChange()
  tubiLog("FeaturePoster.onContentChange")
  if m.top.itemContent <> invalid then
    ' If series content, we show a 16:9 poster, otherwise a DVD-aspect poster
    sURI = ""
    if m.top.itemContent.landscape <> invalid then
      sURI = m.top.itemContent.landscape
    else
      sURI = m.top.itemContent.hdgridposterurl
    end if

    m.Background.uri = sURI

    m.Title.text = m.top.itemContent.title
  end if
End Function


Function onWidthChange()
  m.Title.width = m.top.width - 20
End Function

Function init()
  tubiLog("SideNavIconComponent.init() ")
  m.font = m.top.findNode("Font")
  m.Label = m.top.findNode("Label")
  m.Icon = m.top.findNode("Icon")
  m.top.observeField("itemContent", "onContentChange")
  m.top.observeField("height", "onHeightChange")
  m.top.observeField("active", "onActiveChange")

  if getExperimentResource("roku2", "roku_safe_area").enabled = true
    m.Icon.translation = [102, 0]
    m.Label.translation = [162, 4]
  end if
End Function

''''''''''''''''''
' onContentChange
'
' Update the title and background on 'content' being set
Function onContentChange(data)
  tubiLog("SideNavIconComponent.onContentChange " + data.getField())
  if m.top.itemContent <> invalid then
    m.Icon.uri = m.top.itemContent.iconUrl
    m.Label.text = m.top.itemContent.title
    m.font.size = m.top.itemContent.fontSize

    fontURI = "pkg:/fonts/Vaud-SemiBold.ttf"
    if m.top.itemContent.bold = false
        fontURI = "pkg:/fonts/Vaud-Medium.ttf"
    end if
    m.font.uri = fontURI
    
    onActiveChange()
  end if
End Function

Function onActiveChange()
  if m.top.itemContent.active = true
    if m.top.itemContent.turnedOn <> false
      m.Icon.opacity = 1
      fade(m.Label, "in", .1)
    else 
      '// if the item is not enabled, then still don't bring up the opacity 
      m.Icon.opacity = .31
      fade(m.Label, "in", .1, 0, .31)
    end if
  else
    fade(m.Label, "out", .1)

    '//The selected item should appear bolder
    if m.top.itemContent.selected = true
      m.Icon.opacity = 1
    else
      m.Icon.opacity = .31
    end if
  end if
End Function

Function onHeightChange()
  nHeight = m.top.height
  nIconY = (nHeight - m.Icon.height)/2
  m.Icon.translation = [m.Icon.translation[0], nIconY]
  m.Label.height = nHeight
End Function

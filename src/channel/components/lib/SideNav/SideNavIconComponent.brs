Function init()
  tubiLog("SideNavIconComponent.init() ")
  m.font = m.top.findNode("Font")
  m.Label = m.top.findNode("Label")
  m.Icon = m.top.findNode("Icon")
  m.subTxt = m.top.findNode("subTxt")
  m.labelParent = m.top.findNode("LabelParent")
  m.top.observeField("itemContent", "onContentChange")
  m.top.observeField("height", "onHeightChange")
  m.top.observeField("active", "onActiveChange")
  m.sideIconLabel = invalid
End Function

''''''''''''''''''
' onContentChange
'
' Update the title and background on 'content' being set
Function onContentChange(data)
  tubiLog("SideNavIconComponent.onContentChange " + data.getField())
  item = m.top.itemContent
  if item <> invalid then
    m.Icon.uri = item.iconUrl
    m.Label.text = item.title

    if item.shortDescriptionLine1 <> invalid
      m.subTxt.text = item.shortDescriptionLine1
      if m.subTxt.text <> ""
        'subTxt needs to be centered on the sideNav. Center position of the subtext calculated using safezone start point(114) + center point of the profile icon.
        subTxtCenterPt = (114 + (m.Icon.boundingRect().width / 2)) - ( m.subTxt.boundingRect().width / 2 )
        m.subTxt.translation = [subTxtCenterPt, 52]
      end if


      'add free icon next to Label when sideNav is open
      if item.shortDescriptionLine2 <> invalid
        if item.shortDescriptionLine2 <> ""
          if m.sideIconLabel = invalid
            m.sideIconLabel = m.labelParent.createChild("TextIcon")
            m.sideIconLabel.id = "SideIconLabel"
            m.sideIconLabel.fontSize = 18
            m.sideIconLabel.fontColor = "0x000000"
            m.sideIconLabel.fontUri = "pkg:/fonts/Vaud-Bold.ttf"
            m.sideIconLabel.padding = [12, 9]
            m.sideIconLabel.text = item.shortDescriptionLine2
            m.sideIconLabel.uri = "pkg:/images/tag-rounded-rectangle-background-pull-{size}.9.png"
            m.sideIconLabel.opacity = 0
            m.sideIconLabel.translation = [0, 10]
          end if
        else if item.shortDescriptionLine2 = "" and m.sideIconLabel <> invalid
          m.labelParent.removeChild(m.sideIconLabel)
          m.sideIconLabel = invalid
        end if
      else if m.sideIconLabel <> invalid
        m.labelParent.removeChild(m.sideIconLabel)
        m.sideIconLabel = invalid
      end if
    end if

    m.font.size = item.fontSize
    fontURI = "pkg:/fonts/Vaud-SemiBold.ttf"
    if item.bold = false
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

      m.subTxt.opacity = 0
      if m.sideIconLabel <> invalid
        m.sideIconLabel.opacity = 1
      end if

      fade(m.Label, "in", .1)
    else
      '// if the item is not enabled, then still don't bring up the opacity
      m.Icon.opacity = .31

      m.subTxt.opacity = 0.8
      if m.sideIconLabel <> invalid
        m.sideIconLabel.opacity = 1
      end if

      fade(m.Label, "in", .1, 0, .31)
    end if
  else
    fade(m.Label, "out", .1)

    '//The selected item should appear bolder
    if m.top.itemContent.selected = true
      m.Icon.opacity = 1
      m.subTxt.opacity = 0
      if m.sideIconLabel <> invalid
        m.sideIconLabel.opacity = 0
      end if
    else
      m.Icon.opacity = .31

      m.subTxt.opacity = 0.8
      if m.sideIconLabel <> invalid
        m.sideIconLabel.opacity = 0
      end if

    end if
  end if
End Function


Function onHeightChange()
  nHeight = m.top.height
  nIconY = (nHeight - m.Icon.height)/2
  m.Icon.translation = [m.Icon.translation[0], nIconY]
  m.Label.height = nHeight
End Function

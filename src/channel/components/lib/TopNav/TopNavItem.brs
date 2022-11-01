Function init()
  tubiLog("TopNavItem.init() ")
  m.Underline = m.top.findNode("Underline")

  ' TopLabel is the main label that is always visible but fades
  ' out to reveal the BottomLabel when scrolling away from the selected menu item.
  m.TopLabel = m.top.findNode("TopLabel")
  m.BottomLabel = m.top.findNode("BottomLabel")

  m.BottomLabel.color = "0x10141FFF"
  m.nLabelXSpacing = m.TopLabel.translation[0]
  m.handledInitialItemContent = false

  m.top.observeField("itemContent", "onItemContentChange")
  m.top.observeField("focusPercent", "onFocusPercentChange")
  m.top.observeField("gridHasFocus", "onGridHasFocusChange")
End Function


Function onGridHasFocusChange()
  itemContent = m.top.itemContent
  if itemContent <> invalid
    setItemUI(itemContent)
  end if
End Function


' @itemContent: roSGNode, TopNavContentNode used to create the list item
Function setItemUI(itemContent)
  if m.top.gridHasFocus = true
    m.TopLabel.color = "0xFFFFFFFF"
    m.TopLabel.opacity = 1.0
    m.Underline.opacity = 0
    m.BottomLabel.opacity = 0

    if itemContent.selected = true
      m.BottomLabel.color = itemContent.selectedItemColor
      m.BottomLabel.opacity = 1.0
      if m.iconSubtext <> invalid
        m.iconSubtext.fontColor = "0xFFFFFFFF"
      end if
    end if
  else
    m.TopLabel.color = "0xFFFFFFFF"
    m.TopLabel.opacity = 1.0
    m.BottomLabel.opacity = 0
    m.Underline.opacity = 0

    if itemContent.selected = true
      m.TopLabel.color = itemContent.selectedItemColor
      if m.iconSubtext <> invalid
        m.iconSubtext.fontColor = itemContent.selectedItemColor
      end if
    end if
  end if
End Function


Function onFocusPercentChange()
  itemContent = m.top.itemContent
  focusPercent = m.top.focusPercent

  if itemContent.selected = true
    m.TopLabel.opacity = focusPercent
    m.Underline.opacity = 1 - focusPercent
  end if
End Function


'//When the content of the item is changed.
Function onItemContentChange()
  itemContent = m.top.itemContent
  if itemContent <> invalid
    if itemContent.title <> m.TopLabel.text
      ' only handles setting text and width if the text has changed
      m.TopLabel.width = 0
      m.BottomLabel.width = 0
      m.TopLabel.text = itemContent.title
      m.BottomLabel.text = itemContent.title

      if itemContent.subText <> ""
        m.iconSubtext =  CreateObject("roSGNode","TextIcon")
        m.iconSubtext.id = "iconSubtext"
        m.iconSubtext.fontSize = 14
        m.iconSubtext.fontColor = "0xFFFFFFFF"
        m.iconSubtext.fontUri = "pkg:/fonts/Vaud-Bold.ttf"
        m.iconSubtext.padding = [12, 12]
        m.iconSubtext.blendColor = "0xEB9C00FF"
        m.iconSubtext.text = itemContent.subText
        m.iconSubtext.uri = "pkg:/images/new-frame.webp"
        m.iconSubtext.opacity = 1
       m.top.insertChild(m.iconSubtext, 2)
      else if m.iconSubtext <> invalid
        m.top.removeChild(m.iconSubtext)
      end if

      '//Ensure the width the button varies depending on the width of the label
      boundingRect = {}
      if itemContent.subText <> ""
        subtextTranslationX = m.TopLabel.boundingRect().width + 12 + m.nLabelXSpacing
        m.iconSubtext.translation = [subtextTranslationX, 10]
        boundingRect.width = m.TopLabel.boundingRect().width +  m.iconSubtext.boundingRect().width + (m.nLabelXSpacing * 2)
      else
        boundingRect.width = m.TopLabel.boundingRect().width + (m.nLabelXSpacing * 2)
      end if
      boundingRect.height = m.TopLabel.height
      m.TopLabel.width = boundingRect.width - m.nLabelXSpacing
      m.BottomLabel.width = m.TopLabel.width
      m.top.boundingRect = boundingRect
      m.underline.width = m.TopLabel.width - m.nLabelXSpacing
      if itemContent.subText <> ""
        m.underline.width = m.underline.width - m.iconSubtext.boundingRect().width
      end if
    end if

    ' setting the selectedItemColor is expected to occur every time the selectedItemColor is updated
    setItemUI(itemContent)
  end if
End Function
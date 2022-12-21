Function init()
  tubiLog("TopNavItem.init() ")
  m.Underline = m.top.findNode("Underline")

  ' TopLabel is the main label that is always visible but fades
  ' out to reveal the BottomLabel when scrolling away from the selected menu item.
  m.TopLabel = m.top.findNode("TopLabel")
  m.BottomLabel = m.top.findNode("BottomLabel")

  m.BottomLabel.color = "0x000000FF"
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

    if m.bottomIconSubtext <> invalid
      m.bottomIconSubtext.fontColor = "0xFFFFFFFF"
    end if

    if itemContent.selected = true
      m.BottomLabel.color = itemContent.selectedItemColor
      m.BottomLabel.opacity = 1.0

      if m.topIconSubtext <> invalid
        m.topIconSubtext.opacity = 1.0
      end if

      if m.bottomIconSubtext <> invalid
        m.bottomIconSubtext.opacity = 0
      end if
    end if
  else
    m.TopLabel.color = "0xFFFFFFFF"
    m.TopLabel.opacity = 1.0
    m.BottomLabel.opacity = 0
    m.Underline.opacity = 0

    if m.topIconSubtext <> invalid
      m.topIconSubtext.opacity = 0
    end if

    if m.bottomIconSubtext <> invalid
      m.bottomIconSubtext.opacity = 1.0
    end if

    if itemContent.selected = true
      m.TopLabel.color = itemContent.selectedItemColor

      if m.bottomIconSubtext <> invalid
        m.bottomIconSubtext.fontColor = itemContent.selectedItemColor
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

  if m.top.gridHasFocus = true
    ' m.top.focusPercent can be set to 1 for the item in the selected state
    ' when moving focus away from the top nav, triggering an unexpected call to onFocusPercentChange().
    ' We check so that we only update the values below if a user is navigating between items in the top nav.
    if m.bottomIconSubtext <> invalid
      m.bottomIconSubtext.opacity = 1 - focusPercent
    end if

    if m.topIconSubtext <> invalid
      m.topIconSubtext.opacity = focusPercent
    end if
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
        if m.topIconSubtext = invalid
          ' m.topIconSubtext fades out/in as the item gains/loses focus
          m.topIconSubtext = CreateObject("roSGNode","TextIcon")
          m.topIconSubtext.id = "topIconSubtext"
          m.topIconSubtext.fontSize = 14
          m.topIconSubtext.fontColor = "0xFFFFFFFF"
          m.topIconSubtext.fontUri = "pkg:/fonts/Vaud-Bold.ttf"
          m.topIconSubtext.padding = [12, 12]
          m.topIconSubtext.text = itemContent.subText
          m.topIconSubtext.uri = "pkg:/images/new-frame.webp"
          m.topIconSubtext.opacity = 0
        end if

        if m.bottomIconSubtext = invalid
          ' m.bottomIconSubtext fades in/out as the item gains/loses focus
          m.bottomIconSubtext = CreateObject("roSGNode","TextIcon")
          m.bottomIconSubtext.id = "bottomIconSubtext"
          m.bottomIconSubtext.fontSize = 14
          m.bottomIconSubtext.fontColor = "0xFFFFFFFF"
          m.bottomIconSubtext.fontUri = "pkg:/fonts/Vaud-Bold.ttf"
          m.bottomIconSubtext.padding = [12, 12]
          m.bottomIconSubtext.text = itemContent.subText
          m.bottomIconSubtext.uri = "pkg:/images/new-frame.webp"
          m.bottomIconSubtext.blendColor = "0xE13100FF"
          m.bottomIconSubtext.opacity = 1.0
        end if

        m.top.insertChild(m.bottomIconSubtext, 1)
        m.top.insertChild(m.topIconSubtext, 3)
      else if m.topIconSubtext <> invalid
        m.top.removeChild(m.topIconSubtext)
        m.top.removeChild(m.bottomIconSubtext)
      end if

      '//Ensure the width the button varies depending on the width of the label
      boundingRect = {}
      if itemContent.subText <> ""
        subtextTranslationX = m.TopLabel.boundingRect().width + 12 + m.nLabelXSpacing
        m.topIconSubtext.translation = [subtextTranslationX, 10]
        m.bottomIconSubtext.translation = [subtextTranslationX, 10]
        boundingRect.width = m.TopLabel.boundingRect().width +  m.topIconSubtext.boundingRect().width + (m.nLabelXSpacing * 2)
      else
        boundingRect.width = m.TopLabel.boundingRect().width + (m.nLabelXSpacing * 2)
      end if

      boundingRect.height = m.TopLabel.height
      m.TopLabel.width = boundingRect.width - m.nLabelXSpacing
      m.BottomLabel.width = m.TopLabel.width
      m.top.boundingRect = boundingRect
      m.underline.width = m.TopLabel.width - m.nLabelXSpacing

      if itemContent.subText <> ""
        m.underline.width = m.underline.width - m.topIconSubtext.boundingRect().width
      end if
    end if

    ' setting the selectedItemColor is expected to occur every time the selectedItemColor is updated
    setItemUI(itemContent)
  end if
End Function
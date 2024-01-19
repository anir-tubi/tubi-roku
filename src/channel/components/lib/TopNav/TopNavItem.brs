Function init()
  tubiLog("TopNavItem.init() ")
  m.Underline = m.top.findNode("Underline")

  ' TopLabel is the main label that is always visible but fades
  ' out to reveal the BottomLabel when scrolling away from the selected menu item.
  m.TopLabel = m.top.findNode("TopLabel")
  m.BottomLabel = m.top.findNode("BottomLabel")

  m.nLabelXSpacing = m.TopLabel.translation[0]

  m.top.observeField("itemContent", "onItemContentChange")
  m.top.observeField("focusPercent", "onFocusPercentChange")
  m.top.observeField("gridHasFocus", "onGridHasFocusChange")
  m.top.observeField("height", "onHeightChange")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.TopLabel, typographyConstants.ids.bodySmallStrong)
  setTypographyOfLabel(m.BottomLabel, typographyConstants.ids.bodySmallStrong)

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
    m.BottomLabel.color = theme.backgroundColor
    m.Underline.color = theme.focusedColor
  end if
End Function


Function onGridHasFocusChange()
  itemContent = m.top.itemContent
  if itemContent <> invalid
    setItemUI(itemContent)
  end if
End Function


' @itemContent: roSGNode, TopNavContentNode used to create the list item
Function setItemUI(itemContent)
  theme = getThemeFromGlobal()
  if m.top.gridHasFocus = true
    if theme <> invalid
      m.TopLabel.color = theme.primaryTextColor
    end if

    m.TopLabel.opacity = 1.0
    m.Underline.opacity = 0
    m.BottomLabel.opacity = 0

    if m.bottomIconSubtext <> invalid
      if theme <> invalid
        m.bottomIconSubtext.fontColor = theme.primaryTextColor
      end if
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
    if theme <> invalid
      m.TopLabel.color = theme.primaryTextColor
    end if
    
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
  theme = getThemeFromGlobal()
  if itemContent <> invalid
    if itemContent.title <> m.TopLabel.text
      ' only handles setting text and width if the text has changed
      m.TopLabel.width = 0
      m.BottomLabel.width = 0
      m.TopLabel.text = itemContent.title
      m.BottomLabel.text = itemContent.title

      if itemContent.subText <> ""
        typographyConstants = getTypographyConstants()
        if m.topIconSubtext = invalid
          ' m.topIconSubtext fades out/in as the item gains/loses focus
          m.topIconSubtext = CreateObject("roSGNode","TextIcon")
          m.topIconSubtext.id = "topIconSubtext"

          if theme <> invalid
            m.topIconSubtext.fontColor = theme.primaryTextColor
          end if

          m.topIconSubtext.padding = [2, 2]
          m.topIconSubtext.text = itemContent.subText
          m.topIconSubtext.uri = "pkg:/images/new-frame.webp"
          m.topIconSubtext.opacity = 0
          setTypographyOfLabel(m.topIconSubtext, typographyConstants.ids.bodyExtraSmallStrong)
        end if

        if m.bottomIconSubtext = invalid
          ' m.bottomIconSubtext fades in/out as the item gains/loses focus
          m.bottomIconSubtext = CreateObject("roSGNode","TextIcon")
          m.bottomIconSubtext.id = "bottomIconSubtext"
          m.bottomIconSubtext.padding = [2, 2]
          m.bottomIconSubtext.text = itemContent.subText
          m.bottomIconSubtext.uri = "pkg:/images/new-frame.webp"
          setTypographyOfLabel(m.bottomIconSubtext, typographyConstants.ids.bodyExtraSmallStrong)

          if theme <> invalid
            m.bottomIconSubtext.fontColor = theme.primaryTextColor
            m.bottomIconSubtext.blendColor = theme.focusedColor
          end if

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


Function onHeightChange()
  height = m.top.height
  nLabelY = (height - m.TopLabel.boundingRect().height)/2
  nUnderlineY = nLabelY + m.TopLabel.boundingRect().height

  '//vertically center the labels 
  m.TopLabel.translation = [m.TopLabel.translation[0], nLabelY]
  m.BottomLabel.translation = [m.BottomLabel.translation[0], nLabelY]
  m.Underline.translation = [m.Underline.translation[0], nUnderlineY]
End Function
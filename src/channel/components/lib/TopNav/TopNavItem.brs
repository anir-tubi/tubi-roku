Function init()
  tubiLog("TopNavItem.init() ")

  ' unfocusedTopLabel is the main label that is always visible but fades
  ' out to reveal the focusedBottomLabel when scrolling away from the selected menu item.
  m.unfocusedTopLabel = m.top.findNode("unfocusedTopLabel")
  m.focusedBottomLabel = m.top.findNode("focusedBottomLabel")
  m.selectedBackground = m.top.findNode("selectedBackground")

  m.nLabelXSpacing = m.unfocusedTopLabel.translation[0]

  m.top.observeField("itemContent", "onItemContentChange")
  m.top.observeField("focusPercent", "onFocusPercentChange")
  m.top.observeField("gridHasFocus", "onGridHasFocusChange")
  m.top.observeField("height", "onHeightChange")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.unfocusedTopLabel, typographyConstants.ids.bodySmallStrong)
  setTypographyOfLabel(m.focusedBottomLabel, typographyConstants.ids.bodySmallStrong)

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
  
  'TODO: Colors will be updated once the re-brand color updates done.
  if theme <> invalid
    m.focusedBottomLabel.color = theme.backgroundColor
    m.selectedBackground.blendColor = theme.neutralColor
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
      m.unfocusedTopLabel.color = theme.primaryTextColor
    end if

    m.unfocusedTopLabel.opacity = 1.0
    m.selectedBackground.opacity = 0

    if m.bottomIconSubtext <> invalid
      if theme <> invalid
        m.bottomIconSubtext.fontColor = theme.primaryTextColor
      end if
    end if

    if itemContent.selected = true
      m.focusedBottomLabel.opacity = 1.0
      m.unfocusedTopLabel.opacity = 0

      if m.topIconSubtext <> invalid
        m.topIconSubtext.opacity = 1.0
      end if

      if m.bottomIconSubtext <> invalid
        m.bottomIconSubtext.opacity = 0
      end if
    end if
  else
    if theme <> invalid
      m.unfocusedTopLabel.color = theme.primaryTextColor
    end if
    
    m.unfocusedTopLabel.opacity = 1.0
    m.focusedBottomLabel.opacity = 0

    if m.topIconSubtext <> invalid
      m.topIconSubtext.opacity = 0
    end if

    if m.bottomIconSubtext <> invalid
      m.bottomIconSubtext.opacity = 1.0
    end if

    if itemContent.selected = true
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
    m.selectedBackground.opacity = 1 - focusPercent
  end if

  if m.top.gridHasFocus = true
    m.focusedBottomLabel.opacity = focusPercent
    m.unfocusedTopLabel.opacity = 1 - focusPercent

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
    if itemContent.title <> m.unfocusedTopLabel.text
      ' only handles setting text and width if the text has changed
      m.unfocusedTopLabel.width = 0
      m.unfocusedTopLabel.text = itemContent.title
      m.focusedBottomLabel.text = itemContent.title

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
        subtextTranslationX = m.unfocusedTopLabel.boundingRect().width + 12 + m.nLabelXSpacing
        m.topIconSubtext.translation = [subtextTranslationX, 10]
        m.bottomIconSubtext.translation = [subtextTranslationX, 10]
        boundingRect.width = m.unfocusedTopLabel.boundingRect().width +  m.topIconSubtext.boundingRect().width + (m.nLabelXSpacing * 2)
      else
        boundingRect.width = m.unfocusedTopLabel.boundingRect().width + (m.nLabelXSpacing * 2)
      end if

      boundingRect.height = m.unfocusedTopLabel.height
      m.unfocusedTopLabel.width = boundingRect.width - m.nLabelXSpacing
      m.selectedBackground.width = boundingRect.width
      m.top.boundingRect = boundingRect
    end if

    ' setting the selectedItemColor is expected to occur every time the selectedItemColor is updated
    setItemUI(itemContent)
  end if
End Function


Function onHeightChange()
  height = m.top.height
  nLabelY = (height - m.unfocusedTopLabel.boundingRect().height)/2

  '//vertically center the labels 
  m.unfocusedTopLabel.translation = [m.unfocusedTopLabel.translation[0], nLabelY]
  m.focusedBottomLabel.translation = [m.focusedBottomLabel.translation[0], nLabelY]
End Function
Function init()
  m.buttonText = m.top.findNode("buttonText")
  m.buttonBg = m.top.findNode("buttonBg")
  m.buttonTextParent = m.top.findNode("buttonTextParent")
  m.top.observeFieldScoped("itemContent", "onItemContentChange")
  m.top.observeFieldScoped("focusPercent", "onFocusPercentChange")

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
    m.buttonText.color = theme.primaryTextColor
    m.buttonBg.blendColor = theme.neutralcolor2
  end if
End Function


Function onItemContentChange()
  itemContent = m.top.itemContent
  if itemContent <> invalid then

    if itemContent.fontSize <> invalid
      m.top.fontSize = itemContent.fontSize
    end if

    m.buttonText.text = itemContent.title

    nBoundingTextWidth = m.buttonText.boundingRect().width
    m.buttonText.width = nBoundingTextWidth
    m.buttonBg.width = nBoundingTextWidth
    ' Adjust the width of the menu if the text is too long for the default width
    ' Adding the left and right margin along with text width
    m.top.calculatedWidth = nBoundingTextWidth + (2 * m.buttonTextParent.translation[0]) 'left + right padding.
  end if
End Function


Function onFocusPercentChange(msg)
  m.buttonBg.opacity = 1 - msg.getData()
End Function
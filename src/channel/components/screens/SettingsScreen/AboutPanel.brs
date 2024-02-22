Function init()
  TitleOne = m.top.findNode("TitleOne")
  TextOne = m.top.findNode("TextOne")
  TitleTwo = m.top.findNode("TitleTwo")
  m.TextTwoGroup = m.top.findNode("TextTwoGroup")

  m.top.observeField("textTwoArray", "onTextArrayChange")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(TitleOne, typographyConstants.ids.headerSmall)
  setTypographyOfLabel(TextOne, typographyConstants.ids.bodyMedium)
  setTypographyOfLabel(TitleTwo, typographyConstants.ids.headerSmall)

  theme = getThemeFromGlobal()
  if theme <> invalid
    TitleOne.color = theme.primaryTextColor
    TextOne.color = theme.primaryTextColor
    TitleTwo.color = theme.primaryTextColor
  end if
End Function


Function onTextArrayChange()
  childCount = m.TextTwoGroup.getChildCount()
  if childCount > 0
    '//Remove any existing text in the group
    m.TextTwoGroup.removeChildrenIndex(childCount, 0)
  end if

  typographyConstants = getTypographyConstants()
  theme = getThemeFromGlobal()
  for i = 0 to m.top.textTwoArray.count() - 1
    '//Add new text to the TextTwoGroup based on the new array of text
    newLine = createObject("roSGNode", "Label")
    newLine.wrap = true
    newLine.width = "1026"
    newLine.text = m.top.textTwoArray[i]
    font = CreateObject("roSGNode", "Font")
    newLine.font = font
    m.TextTwoGroup.insertChild(newLine, i)
    setTypographyOfLabel(newLine, typographyConstants.ids.bodyMedium)

    if theme <> invalid
      newLine.color = theme.primaryTextColor
    end if
  end for
End Function
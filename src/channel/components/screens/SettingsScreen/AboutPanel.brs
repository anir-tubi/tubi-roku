Function init()
  TitleOne = m.top.findNode("TitleOne")
  TextOne = m.top.findNode("TextOne")
  TitleTwo = m.top.findNode("TitleTwo")
  TextTwo = m.top.findNode("TextTwo")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(TitleOne, typographyConstants.ids.headerSmall)
  setTypographyOfLabel(TextOne, typographyConstants.ids.bodyMedium)
  setTypographyOfLabel(TitleTwo, typographyConstants.ids.headerSmall)
  setTypographyOfLabel(TextTwo, typographyConstants.ids.bodyMedium)
End Function
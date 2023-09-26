Function init()
  m.header = m.top.findNode("title")
  m.subheader = m.top.findNode("subHeader")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.header, typographyConstants.ids.subheaderSmall)
  setTypographyOfLabel(m.subheader, typographyConstants.ids.bodySmall)
End Function
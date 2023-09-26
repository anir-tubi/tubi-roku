Function init()
  Title = m.top.findNode("Title")
  Name = m.top.findNode("Name")
  Email = m.top.findNode("Email")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(Title, typographyConstants.ids.headerSmall)
  setTypographyOfLabel(Name, typographyConstants.ids.subheaderMedium)
  setTypographyOfLabel(Email, typographyConstants.ids.bodyMedium)
End Function
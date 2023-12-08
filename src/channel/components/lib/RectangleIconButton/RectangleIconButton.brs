' This component is extended off of the SimpleButton component.
' See SimpleButton.xml and SimpleButton.brs for more information and functionality.

Function init()
  m.Icon = m.top.findNode("Icon")
  m.marginWidth = 36 'the space between the edge of the button and the icon
  m.iconSpacing = 9 'the space between the icon and the first word

  labelx = m.marginWidth + m.Icon.width + m.iconSpacing
  labely = m.label.translation[1]
  m.label.translation = [labelx, labely]

  ' replace the onTextChanged callback from SimpleButton.brs
  m.top.unobserveField("text")
  m.top.observeField("text", "onTextChangedWithIcon")

End Function


Function onTextChangedWithIcon()
  m.label.text = m.top.text
  width = m.top.width

  if m.top.width = 0
    width = m.label.boundingRect().width + (m.marginWidth * 2) + m.Icon.width + m.iconSpacing
  end if

  m.buttonBG.width = width
  m.label.width = width - (m.marginWidth * 2) - m.icon.width - m.iconSpacing
End Function
Function init()
  '// TODO: WHEN SCROLLABLE MULTISTYLE TEXT IS AVAILABLE, REMOVE SCROLLINGDIALOG FROM THE CODEBASE AND USE TUBI'S SHOWMODAL() WITH MULTISTYLE TEXT
  m.top.observeFieldScoped("buttonSelected", "onDialogClose")
  m.top.observeFieldScoped("focusedChild", "onFocusChange")
  m.buttonArea = m.top.findNode("buttonArea")
  textItem = m.top.findNode("textItem")

  '//Set the color & font style values within the drawingStyles AA before assigning the AA to the textItem.drawingStyles property
  drawingStyles = {
    "default": {}
    "subTitle": {}
    "header":{}
  }

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(drawingStyles.default, typographyConstants.ids.bodyLarge)
  setTypographyOfLabel(drawingStyles.header, typographyConstants.ids.headerSmall)
  setTypographyOfLabel(drawingStyles.subTitle, typographyConstants.ids.subheaderSmall)

  palette = createObject("roSGNode", "RSGPalette")

  theme = getThemeFromGlobal()
  if theme <> invalid
    palette.colors = {
      "DialogFocusColor": theme.highlightedTextColor
      "DialogFocusItemColor" : theme.primaryTextColor
      "DialogBackgroundColor" : theme.neutralSolidColor
    }
    drawingStyles.default.color = theme.primaryTextColor
    drawingStyles.header.color = theme.primaryTextColor
    drawingStyles.subTitle.color = theme.primaryTextColor
  end if

  textItem.drawingStyles = drawingStyles

  m.top.palette = palette
End Function


Function onDialogClose()
  m.top.close = true
End Function


Function onFocusChange()
  if m.top.hasFocus() = true
    m.buttonArea.setFocus(true)
  end if
End Function

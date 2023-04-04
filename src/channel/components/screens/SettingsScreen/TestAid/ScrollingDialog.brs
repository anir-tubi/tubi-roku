Function init()
  '// TODO: WHEN SCROLLABLE MULTISTYLE TEXT IS AVAILABLE, REMOVE SCROLLINGDIALOG FROM THE CODEBASE AND USE TUBI'S SHOWMODAL() WITH MULTISTYLE TEXT
  m.top.observeFieldScoped("buttonSelected", "onDialogClose")
  m.top.observeFieldScoped("focusedChild", "onFocusChange")
  m.buttonArea = m.top.findNode("buttonArea")
  textItem = m.top.findNode("textItem")

  textItem.drawingStyles = {
    "default": {
      "fontSize": {fhd:33,hd:22}
      "fontUri": "pkg:/fonts/Vaud-Medium.ttf"
    }
    "subTitle": {
      "fontSize": {fhd:27,hd:18}
      "fontUri": "pkg:/fonts/Vaud-Bold.ttf"
    }
    "header":{
      "fontSize": {fhd:40,hd:27}
      "fontUri": "pkg:/fonts/Vaud-Bold.ttf"
    }
  }

  palette = createObject("roSGNode", "RSGPalette")

  theme = getThemeFromGlobal()
  if theme <> invalid
    palette.colors = {
      "DialogFocusColor": theme.highlightedTextColor
      "DialogFocusItemColor" : theme.primaryTextColor
      "DialogBackgroundColor" : theme.neutralSolidColor
    }
    textItem.drawingStyles.default.color = theme.primaryTextColor
    textItem.drawingStyles.header.color = theme.primaryTextColor
    textItem.drawingStyles.subTitle.color = theme.primaryTextColor
  end if
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

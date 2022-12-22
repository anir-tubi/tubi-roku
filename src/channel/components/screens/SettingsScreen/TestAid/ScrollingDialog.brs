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
      "color": "#EFEFEFFF"
    }
    "subTitle": {
      "fontSize": {fhd:27,hd:18}
      "fontUri": "pkg:/fonts/Vaud-Bold.ttf"
      "color": "#FFFDD0FF"
    }
    "header":{
      "fontSize": {fhd:40,hd:27}
      "fontUri": "pkg:/fonts/Vaud-Bold.ttf"
      "color": "#EFEFEFFF"
    }
  }

  palette = createObject("roSGNode", "RSGPalette")
  palette.colors = {
    "DialogFocusColor": "0xFF501AFF"
    "DialogFocusItemColor" : "0xEFEFEFFF"
    "DialogBackgroundColor" : "0x2C2C2CFF"
  }
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

Function init()
  m.top.observeField("itemContent", "onItemContentChange")
  m.Icon = m.top.findNode("Icon")
  m.DetailsMenuText = m.top.findNode("DetailsMenuText")
  m.Progress = m.top.findNode("ResumeProgressBar")
  m.top.color = m.global.constants.ui.colors.transparent
  m.Progress.color = m.global.constants.ui.colors.focusedText
End Function

Function onItemContentChange()
  tubiLog("DetailMenuItem.onItemContentChange")
  if m.top.itemContent <> invalid then
    m.DetailsMenuText.text = m.top.itemContent.title
    m.Icon.uri = m.top.itemContent.iconUrl
    if m.top.itemContent.playstart <> invalid and m.top.itemContent.playstart <> 0.0 and m.top.itemContent.length <> invalid and m.top.itemContent.length <> 0.0 then
      showProgressBar(m.top.itemContent.playstart / m.top.itemContent.length)
    else
      m.Progress.visible = false
    end if
  end if
End Function

Function showProgressBar(percentage As Double)
  tubiLog("DetailMenuItem.showProgressBar")
  if percentage > 1.0 then percentage = 1.0
  if percentage < 0.0 then percentage = 0.0
  ' width of menu item is 440, 4 pixel margin for progress bar
  m.Progress.width = (m.top.width - 8.0) * percentage
  m.Progress.visible = true
End Function

Function init()
  m.top.observeField("content", "onContentChange")
  m.FocusedIcon = m.top.findNode("FocusedIcon")
  m.UnfocusedIcon = m.top.findNode("UnfocusedIcon")
  m.DetailsMenuText = m.top.findNode("DetailsMenuText")
  m.Progress = m.top.findNode("ResumeProgressBar")
  ' Force a static size, which ScrollingList will pick up since it internal uses LayoutGroup for spacing
  m.top.width = 440
  m.top.height = 80
  m.top.color = m.global.constants.ui.colors.transparent
  m.Progress.color = m.global.constants.ui.colors.focusedText
  m.top.observeField("focusPercent", "onFocusChange")
  m.top.observeField("listHasFocus", "onFocusChange")
End Function

Function onFocusChange()
  if m.FocusedIcon.uri <> m.UnfocusedIcon.uri
    m.FocusedIcon.opacity = m.top.focusPercent
    m.UnfocusedIcon.opacity = 1.0 - m.top.focusPercent
  end if
  'we can change the color of the menu item text if we want by using colorChange() from the animationMixin
  'on DetailsMenuText, but perhaps best to do it from DetailScreen.brs
End Function

Function onContentChange()
  tubiLog("DetailMenuItem.onContenChange")
  if m.top.content <> invalid then
    m.DetailsMenuText.text = m.top.content.title
    m.FocusedIcon.uri = m.top.content.focusIconUrl
    m.UnfocusedIcon.uri = m.top.content.unfocusIconUrl
    if m.top.content.playstart <> invalid and m.top.content.playstart <> 0.0 and m.top.content.length <> invalid and m.top.content.length <> 0.0 then
      showProgressBar(m.top.content.playstart / m.top.content.length)
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

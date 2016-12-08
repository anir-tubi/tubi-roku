Function init()
  m.poster = m.top.findNode("Poster")
  m.resumeProgressBar = m.top.findNode("ResumeProgressBar")
  m.top.observeField("itemContent", "onContentChange")
  m.top.observeField("width", "drawProgressBar")
  m.top.observeField("height", "drawProgressBar")
  m.resumeProgressBar.color = m.global.constants.ui.colors.focused
  m.resumeMargin = 4  'inset of resume bar
  drawProgressBar()
End Function


''''''''''''''''''
' onContentChange
'
' Update the title and background on 'content' being set
Function onContentChange()
  tubiLog("ResumePoster.onContentChange")
  if m.top.itemContent <> invalid then
    if m.top.itemContent.portrait <> invalid then
      m.poster.uri = m.top.itemContent.portrait
    else
      m.poster.uri = m.top.itemContent.hdgridposterurl
    end if
    drawProgressBar()
  end if
End Function


Function drawProgressBar()
  if m.top.itemContent <> invalid and m.top.itemContent.nowPos <> invalid and m.top.itemContent.nowPos <> 0 and m.top.itemContent.length <> invalid and m.top.itemContent.length <> 0 then
    percentage = m.top.itemContent.nowPos / m.top.itemContent.length
    if percentage > 1.0 then percentage = 1.0
    if percentage < 0.0 then percentage = 0.0
    m.resumeProgressBar.width = (m.top.width - (2 * m.resumeMargin)) * percentage
    m.resumeProgressBar.translation = [m.resumeMargin, m.top.height - m.resumeProgressBar.height - m.resumeMargin]
    m.resumeProgressBar.visible = true
  else
    m.resumeProgressBar.visible = false
  end if
End Function
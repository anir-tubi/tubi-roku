Function init()
  m.progressBar = m.top.findNode("ProgressBar")
  m.top.observeField("itemContent", "onContentChange")
  m.top.observeField("width", "drawProgressBar")
  m.top.observeField("height", "drawProgressBar")
  m.progressBar.color = m.global.constants.ui.colors.focused
  m.resumeMargin = 6  'inset of resume bar
  drawProgressBar()
End Function


''''''''''''''''''
' onContentChange
'
' Update the title and background on 'content' being set
Function onContentChange()
  tubiLog("FeaturePosterWithProgress.onContentChange")
  if m.top.itemContent <> invalid then
    drawProgressBar()
  end if
End Function


Function drawProgressBar()
  history = invalid
  if m.top.itemContent <> invalid then
    history = m.global.historyIds.findNode(m.top.itemContent.id)
  end if

  if m.top.itemContent <> invalid and history <> invalid and history.nowPos <> invalid and history.nowPos <> 0 and m.top.itemContent.length <> invalid and m.top.itemContent.length <> 0 then
    percentage = history.nowPos / m.top.itemContent.length
    if percentage > 1.0 then percentage = 1.0
    if percentage < 0.0 then percentage = 0.0
    m.progressBar.width = (m.top.width - (2 * m.resumeMargin)) * percentage
    m.progressBar.translation = [m.resumeMargin, m.top.height - m.progressBar.height - m.resumeMargin]
    m.progressBar.visible = true
  else
    m.progressBar.visible = false
  end if
End Function
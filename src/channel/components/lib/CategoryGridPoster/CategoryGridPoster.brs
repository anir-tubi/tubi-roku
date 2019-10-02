Function init()
  m.poster = m.top.findNode("Poster")
  m.resumeProgressBar = m.top.findNode("ResumeProgressBar")
  m.top.observeField("itemContent", "onContentChange")
  m.resumeMargin = 4  'inset of resume bar
  m.title = m.top.findNode("Title")
End Function


''''''''''''''''''
' onContentChange
'
' Update the title and background on 'content' being set
Function onContentChange(data)
  tubiLog("CategoryGridPoster.onContentChange " + data.getField())

  ' set some defaults
  m.title.visible = false

  ' next line shouldn't be necessary but is added in order to try and quell crashes as reported by roku crash logs
  if m.resumeProgressBar = invalid then m.resumeProgressBar = m.top.findNode("ResumeProgressBar")
  m.resumeProgressBar.visible = false

  if m.top.itemContent <> invalid then
    m.poster.uri = m.top.itemContent.hdgridposterurl
    categoryContent = m.top.itemContent.getParent()
    if categoryContent <> invalid then
      if m.top.itemContent.isLandscape = true
        m.title.visible = true
        m.title.text = m.top.itemContent.title
      else if categoryContent.title = "Continue Watching"
        drawProgressBar()
      end if
    end if
  end if
End Function


Function drawProgressBar()
  history = invalid
  if m.top.itemContent <> invalid then
    historyIds = m.global.historyIds
    if historyIds <> invalid
      history = m.global.historyIds.findNode(m.top.itemContent.id)
    end if
  end if

  if m.top.itemContent <> invalid and history <> invalid and history.nowPos <> invalid and history.nowPos <> 0 and m.top.itemContent.length <> invalid and m.top.itemContent.length <> 0 then
    percentage = history.nowPos / m.top.itemContent.length
    if percentage > 1.0 then percentage = 1.0
    if percentage < 0.0 then percentage = 0.0
    m.resumeProgressBar.width = (m.top.width - (2 * m.resumeMargin)) * percentage
    m.resumeProgressBar.translation = [m.resumeMargin, m.top.height - m.resumeProgressBar.height - m.resumeMargin]
    m.resumeProgressBar.color = m.global.theme.focused
    m.resumeProgressBar.visible = true
  end if
End Function
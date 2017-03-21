Function init()
  tubiLog("EPG.init")

  m.Channels = m.top.findNode("Channels")
  m.Poster = m.top.findNode("DVDPoster")
  m.Info = m.top.findNode("Info")

  ' Render times
  drawTimes()
  m.top.observeField("content", "onContentChange")
  m.top.observeField("focusedChild", "onComponentFocusChange")
End Function

Function onComponentFocusChange()
  if m.top.isInFocusChain() and m.top.hasFocus() then
    m.Channels.setFocus(true)
  end if
End Function

Function onContentChange()
  drawTimes()
  drawCurrentEpisode()
  m.Channels.content = invalid
  m.Channels.content = m.top.content
End Function

'''''''''''''''''''
' drawTimes
'
' Draw the EPG header and current location marker
Function drawTimes()
  tubiLog("EPG.drawTimes")
  datetime = CreateObject("roDateTime")
  datetime.ToLocalTime()
  now = datetime.GetHours()
  now = now MOD 12
  if now = 0 then now = 12
  hour1 = m.top.findNode("Hour1")
  hour1.text = stri(now) + ":00"
  now = (now + 1) MOD 12
  if now = 0 then now = 12
  hour2 = m.top.findNode("Hour2")
  hour2.text = stri(now) + ":00"
  now = (now + 1) MOD 12
  if now = 0 then now = 12
  m.top.findNode("Hour3").text = stri(now) + ":00"
  now = (now + 1) MOD 12
  if now = 0 then now = 12
  m.top.findNode("Hour4").text = stri(now) + ":00"
End Function


'''''''''''''''''''''''''''
' drawCurrentEpisode
'
'
'
Function drawCurrentEpisode() As Void
  tubiLog("EPG.drawCurrentEpisode")
  if m.top.content <> invalid then
    channel = m.top.content.getChild(m.top.content.liveTVCursor[0])
    if channel <> invalid then
      episode = channel.getChild(m.top.content.liveTVCursor[1])
      if episode <> invalid then
        m.Poster.uri = episode.hdgridposterurl
        m.Info.content = episode
        return
      end if
    end if
  end if
  m.Channels.animateToItem = m.top.content.liveTVCursor[0]
  m.Poster.uri = ""
  m.Info.content = invalid
End Function

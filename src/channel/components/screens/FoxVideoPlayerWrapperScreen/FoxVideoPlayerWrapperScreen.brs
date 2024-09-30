Function init()
  tubiLog("FoxVideoPlayerWrapperScreen.init")

  m.spinner = m.top.findNode("spinner")

  m.rpfPlaybackPage = invalid ' Stores a reference to the actual fox provided video player component

  ' We have to wait until we get our content ID and the component library is loaded before we can start playback
  m.top.observeFieldScoped("contentId", "playContentWithFoxVideoPlayer")
  m.top.observeFieldScoped("isFoxVideoPlayerAvailable", "playContentWithFoxVideoPlayer")

  m.top.observeFieldScoped("closePlayer", "onClosePlayerChanged")
End Function


Function onClosePlayerChanged()
  if m.RpfPlaybackPage <> invalid
    m.RpfPlaybackPage.close = true
  else
    m.top.isPlayerClosed = true
  end if
End Function


Function onRpfPlaybackPageWasClosed()
  m.top.isPlayerClosed = true
End Function


Function playContentWithFoxVideoPlayer()
  contentId = m.top.contentId
  ' Confirm all of our prerequisites are met before we start playback
  if m.top.isFoxVideoPlayerAvailable = true AND contentId <> "" then
    playerInfo = buildPlayerInfo(contentId)

    m.rpfPlaybackPage = createObject("roSGNode", "FoxVideoPlayer:RpfPlaybackPage")
    m.rpfPlaybackPage.observeFieldScoped("close", "onRpfPlaybackPageWasClosed")
    m.rpfPlaybackPage.context = playerInfo.context
    m.rpfPlaybackPage.video = playerInfo.node

    m.top.appendChild(m.rpfPlaybackPage)
    m.rpfPlaybackPage.attach = true
    m.spinner.visible = false
  end if
End Function


' Builds the player info object that is passed to the Fox player to start playback
'@contentId: The id of the content to play as returned by the Fox listing api
Function buildPlayerInfo(contentId)
  videoContentNode = CreateObject("roSGNode", "FoxVideoPlayer:RpfVideoContentNode")
  context = {}

  context = {
    "action": "play",
    "isautoplay": false,
    "isfola": true,
    "isliveplaybackstart": true,
    "isplayback4k": false,
    "playfrombeginning": false,
    "sourcename": "live",
    "sourcetype": "EPG",
    "streamcapabilities": "720p",
  }

  videoContentNode.setFields({
    "id": contentId,
    "streamType": "live",
    "displayBrand": "fox",
    "network": "fox",
  })

  videoContentNode.setFields({
    "customDimensions": {
      "video_is_universal_search": false,
    }
  })

  return {
    context: context,
    node: videoContentNode,
  }
End Function


Function onKeyEvent(key as String, press as Boolean) as Boolean
  if press = true AND key = "back" then
    ' If we call close on the fox player, it will clear out the playPosition which we don't want
    m.top.isPlayerClosed = true
    return true
  end if

  return false
End Function

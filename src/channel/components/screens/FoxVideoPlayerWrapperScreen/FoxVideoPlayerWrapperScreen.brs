Function init()
  tubiLog("FoxVideoPlayerWrapperScreen.init")
  constants = getConstantsFromGlobal()
  m.spinner = m.top.findNode("spinner")

  m.rpfPlaybackPage = invalid ' Stores a reference to the actual fox provided video player component

  ' We have to wait until we get our content ID and the component library is loaded before we can start playback
  m.top.observeFieldScoped("contentId", "playContentWithFoxVideoPlayer")
  m.top.observeFieldScoped("isFoxVideoPlayerAvailable", "playContentWithFoxVideoPlayer")
  m.top.observeFieldScoped("tubiContent", "onTubiContentChange")

  m.top.observeFieldScoped("closePlayer", "onClosePlayerChanged")

  m.top.screenLevel = constants.ui.screenLevels.foxVideoPlayerWrapperScreen

  trackingPageInfo = {
    pageType: "video_player_page"
    pageValues: {}
  }
  m.top.trackingPageInfo = trackingPageInfo
End Function


Function onClosePlayerChanged()
  ' Note we want this to be triggered first so we get the correct playback position before we close the player
  m.top.willPlayerClose = true
  if m.rpfPlaybackPage <> invalid
    m.rpfPlaybackPage.close = true
  end if
End Function


Function playContentWithFoxVideoPlayer()
  contentId = m.top.contentId
  isFoxVideoPlayerAvailable = m.top.isFoxVideoPlayerAvailable

  logString = "FoxVideoPlayerWrapperScreen.playContentWithFoxVideoPlayer "

  if isNonEmptyString(contentId) = true
    logString += "contentId: " + contentId + " "
  end if

  if isBoolean(isFoxVideoPlayerAvailable) = true
    logString += "isFoxVideoPlayerAvailable: " + isFoxVideoPlayerAvailable.toStr()
  end if

  tubiLog(logString)

  ' Confirm all of our prerequisites are met before we start playback
  if isFoxVideoPlayerAvailable = true AND contentId <> "" then
    playerInfo = buildPlayerInfo(contentId)

    m.rpfPlaybackPage = createObject("roSGNode", "FoxVideoPlayer:RpfPlaybackPage")
    if m.rpfPlaybackPage = invalid then
      tubiLog("FoxVideoPlayerWrapperScreen.playContentWithFoxVideoPlayer: Failed to create RpfPlaybackPage node")
      m.top.closePlayer = true
    else
      m.rpfPlaybackPage.context = playerInfo.context
      m.rpfPlaybackPage.video = playerInfo.node

      m.top.appendChild(m.rpfPlaybackPage)
      m.rpfPlaybackPage.attach = true
      m.spinner.visible = false
    end if

  end if
End Function


' Builds the player info object that is passed to the Fox player to start playback
'@contentId: The id of the content to play as returned by the Fox listing api
Function buildPlayerInfo(contentId)
  videoContentNode = CreateObject("roSGNode", "FoxVideoPlayer:RpfVideoContentNode")

  context = {
    "action": "play",
    "isautoplay": false,
    "isfola": true,
    "isliveplaybackstart": true,
    "isplayback4k": true,
    "playfrombeginning": false,
    "sourcename": "live",
    "sourcetype": "EPG",
    "streamcapabilities": "HDR",
  }

  videoContentNode.setFields({
    "id": contentId,
    "streamType": "live",
    "displayBrand": "fox",
    "network": "fox",
    "videoType": "live"
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


Function onTubiContentChange(msg)
  tubiLog("FoxVideoPlayerWrapperScreen.onTubiContentChange")

  content = msg.getData()

  if content <> invalid then
    'set page tracking values for analytics
    m.top.trackingPageInfo = {
      pageType: "video_player_page"
      pageValues: {
        video_id: content.id.toInt()
      }
    }
  end if
End Function


Function onKeyEvent(key as String, press as Boolean) as Boolean
  if press = true AND key = "back" then
    onClosePlayerChanged()
    return true
  end if

  return false
End Function

Function init()
  tubiLog("LineaerVideoPlayerScreen.init")

  ' handle BaseScreen functionality (see BaseScreen.xml)
  m.constants = getConstantsFromGlobal()
  m.metadataTranslate = TubiMetadataTranslate(m.constants)
  m.top.screenLevel = m.constants.ui.screenLevels.linearVideoPlayerScreen
  m.top.trackingPageInfo = {
    pageType: "video_player_page"
    pageValues: {}
  }
  m._ = rodash()
  m.NodeHelpers = TubiNodeHelpers()
  m.theme = m.global.theme
  m.Loading = m.top.findNode("Loading")
  m.LoadingProgressBar = m.top.findNode("LoadingProgressBar")
  m.LoadingMessage = m.top.findNode("LoadingMessage")
  m.Transport = m.top.findNode("Transport")
  m.AdsSSAITask = m.top.findNode("PlayerAdsSSAITask")
  m.AdsSSAITask.observeField("isPlayingAds", "onAdChange")
  m.ButtonsGroup = m.top.findNode("ButtonsGroup")
  '//Keep the state of the transport. Is the 1st trasnport page visible? 2nd page? 
  m.nTransportState = 0

  m.Video = m.top.findNode("VideoNode")  ' reference in case we change from extending Video to extending Group
  m.Video.observeField("position", "onVideoPositionChange")
  m.Video.observeField("state", "onVideoStateChange")
  m.Video.observeField("bufferingStatus", "onBufferingStatus")
  m.Video.observeField("globalCaptionMode", "onCaptionModeChange")
  m.Video.observeField("timedMetaData", "onId3")

  m.Video.timedMetaDataSelectionKeys = ["*"]
  
  m.top.observeField("fullscreen", "onFullScreenChange")
  m.top.observeField("updateContent", "onContentChange")
  m.top.observeField("control", "onControlChange")
  m.top.observeField("channelsContent", "onChannelGuideContentChanged")
  m.top.observeField("pollUrl","onPollUrlChange")
  m.top.observeField("closeTransport", "hideTransport")

  m.logo = m.top.findNode("tubiLogo")

  m.Overlay1stScreen = m.top.findNode("Overlay1stScreen")
  m.Overlay2ndScreen = m.top.findNode("Overlay2ndScreen")
  m.HUD = m.top.findNode("HUD")
  m.HUDIcon = m.top.findNode("HUDIcon")
  m.TransportGradient = m.top.findNode("TransportGradient")

  '//Channel Guide Nodes
  m.channelsGuideGroup = m.top.findNode("channelsGuideGroup")
  m.channelsGuideGroup.observeFieldScoped("navigateWithinPageInfo", "onChannelGuideNavigateWithChange")
  m.channelsGuideGroup.observeFieldScoped("itemFocused", "onChannelGuideContentFocused")
  m.channelsGuideGroup.observeFieldScoped("itemSelected", "onChannelGuideContentSelected")
  m.channelsGuideGroup.observeFieldScoped("trackingComponentInfo", "onChannelGuideAnalyticsChanged")
   
  '//Closed Captioning Nodes
  m.closedCaptioningGroup = m.top.findNode("closedCaptioningGroup")
  m.closedCaptioningButtonList = m.top.findNode("closedCaptioningButtonList")
  m.closedCaptioningButtonListBackground = m.top.findNode("closedCaptioningButtonListBackground")
  m.closedCaptioningCloseButton = m.top.findNode("cc_close_btn")
  m.closedCaptioningCloseButton.text = getTranslation("dialog_button_close")
  m.closedCaptioningButtonListBackground.observeFieldScoped("rowItemSelected", "onCCContentSelected")
  m.closedCaptioningButtonListBackground.observeFieldScoped("rowItemFocused", "onCCContentFocused")
  m.closedCaptioningButtonListBackground.focusBitmapBlendColor = m.global.theme.focused

  if m.constants.deviceInfo.scaledUi = true
    m.closedCaptioningButtonListBackground.focusBitmapUri = "pkg://images/menu-focus-hd.9.png"
  end if

  'm.VideoState is source of truth for the state of the video player for the UI
  'possible values are "play", "pause", "rew", "ffw", "stop", "refresh", "skip", "hop"
  m.VideoState = "stop"

  m.playerPosition = 0

  m.lastButtonPressPos = 0
  m.transportAutoHideTime = m.constants.player.transportAutoHideTime
  m.bufferingInfo = invalid

  m.GuideTitle = m.top.findNode("GuideTitle")
  m.ButtonClose = m.top.findNode("ButtonClose")

  'buttons
  m.TransportButtons = m.top.findNode("TransportButtons")
  m.ButtonBack = m.TransportButtons.findNode("ButtonBack")
  m.ButtonCaptions = m.TransportButtons.findNode("ButtonCaptions")
  m.ButtonChannels = m.TransportButtons.findNode("ButtonChannels")

  m.ButtonBack.text = getTranslation("linearVideoPlayer_buttonBack")
  m.ButtonCaptions.text = getTranslation("linearVideoPlayer_buttonCaptions")
  m.ButtonChannels.text = getTranslation("linearVideoPlayer_buttonGuide")
  m.GuideTitle.text = getTranslation("linearVideoPlayer_channelGuideTitle")
  m.ButtonClose.text = getTranslation("dialog_button_close")

  m.lastPingTime = 0

  m.analyticsInterval = m.constants.player.pingFrequency

  updateColors()

  if m.constants.deviceInfo.scaledUi = true then
    m.LoadingProgressBar.scaledUI = m.constants.deviceInfo.scaledUi
    m.TransportGradient.uri = "pkg:/images/playback-gradient-hd.9.png"
  end if

  ' m.didAdvanceDrm holds current state regarding if playback failed, and the player is going to try the
  ' the next video stream available
  m.didAdvanceDrm = false

  ' the video player screen should be false until placed upon the screen stack
  m.top.visible = false
End Function


Function playContent()
  tubiLog("LineaerVideoPlayerScreen.playContent")
  m.lastButtonPressPos = 0

  'start_live_video user event analytics
  hasSubtitles = false
  if m.Video.globalCaptionMode = "On" and m.Video.content.hasSubtitles = true and m.top.fullscreen = true
    hasSubtitles = true
  end if

  videoPlayerType = "DEFAULT"
  if m.top.fullscreen = false
    videoPlayerType = "BANNER"
  end if

  resourceType = "VIDEO_RESOURCE_TYPE_UNKNOWN"
  if m.top.content.drmType = m.constants.player.drmTypes.hlsv3
    resourceType = "VIDEO_RESOURCE_TYPE_HLSV3"
  end if

  trackEvent({
    type: "start_live_video"
    values: {
      video_id: m.Video.content.id.toInt()
      current_cdn: ""   'not possible for Roku client
      has_subtitles: hasSubtitles  'the video player will show subtitles at start
      video_resource_url: m.top.content.url
      video_resource_type: resourceType
      video_player: videoPlayerType
    }
  })

  m.VideoState = "play"
  m.Video.control = "play"
End Function


Function updateColors()
  m.focusedColor = m.theme.focused
  m.LoadingProgressBar.focusColor = m.focusedColor
  m.LoadingProgressBar.unfocusColor = m.focusedColor
End Function


Function onContentChange(msg) As Void
  tubiLog("LineaerVideoPlayerScreen.onContentChange")
  m.top.state = ""
  hideTransport()
  stopVideo()
 
  if m.top.content <> invalid
    'set page tracking values for analytics
    m.top.trackingPageInfo = {
      pageType: m.top.trackingPageInfo.pageType
      pageValues: {
        video_id: m.top.content.id.toInt()
      }
    }
  end if
End Function


' needed in case the pollUrl is set via the alias prior to the AdsSSAITask being in a "ready" state
Function onPollUrlChange()
  tubiLog("LineaerVideoPlayerScreen.onPollUrlChange")
  if m.AdsSSAITask.state <> "ready"
    m.AdsSSAITask.observeField("state", "onAdsSSAITaskStateChange")
  end if
End Function


' If an ad is playing then temporary stop showing captions
Function onAdChange(msg)
  tubiLog("LineaerVideoPlayerScreen.onAdChange")
  isPlayingAds = msg.getData()
  if isPlayingAds = true
    ' Send a play_progress event before we show ads to be most accurate in case the user exits during ad playback
    playProgressEvent = getPlayProgressEvent()
    if playProgressEvent <> invalid
      trackEvent(playProgressEvent)

      ' set m.lastPingTime here to prevent an extra playProgressEvent if a user backs out of the ads
      ' thereby triggering backButtonExit() which also sends a playProgressEvent.
      m.lastPingTime = m.playerPosition
    end if
  end if
  m.Video.suppressCaptions = isPlayingAds
  if isPlayingAds = false
    trackEvent({
      type: "resume_after_break"
      values: {
        video_id: m.Video.content.id.toInt()
        position: Int(m.playerPosition * 1000)    'without Int(), can return scientific notation, causing API error
      }
    })
  end if
End Function

Function onAdsSSAITaskStateChange(msg)
  state = msg.getData()
  if state = "ready"
    m.AdsSSAITask.pollUrl = m.top.pollUrl
    m.AdsSSAITask.unobserveField("state")
  end if
End Function


Function onControlChange()
  tubiLog("LineaerVideoPlayerScreen.onControlChange " + m.top.control)
  if m.top.control = "play"
    if m.top.content <> invalid
      prepareToStartVideo(m.top.content, 0)
      playContent()
    end if

  else if m.top.control = "stop" then
    m.AdsSSAITask.playbackStopped = true
    stopVideo()
  else if m.top.control = "pause" then
    pauseVideo(false, false)
  else if m.top.control = "resume" and m.Video.state = "paused" then
    resumeFromPause(false)
  else if m.top.control = "error"
    stopVideo()
    m.top.errorMsg = getTranslation("videoPlayer_error_playback_description")  'is used in error modal
    m.top.state = "error"
  end if
End Function


'Occurs when m.Video.state changes (not when m.top.state changes)
Function onVideoStateChange(msg)
  tubiLog("LineaerVideoPlayerScreen.onVideoStateChange, state = " + msg.GetData()) 
  state = msg.GetData()

  sPreviousState = m.top.state
  if state = "finished" and m.VideoState = "play"
    if m.didAdvanceDrm = true
      ' video player always changes state to "finished" after reaching a state of "error"
      ' so we wait until the "finished" state is reached to play the next available stream for the video
      ' in order to prevent race conditions due to video player state changing.
      m.didAdvanceDrm = false
      playContent()
    else
      ' the video reached the end
      if m.Video.content <> invalid
        ' the video has been stopped, send a final playProgressEvent
        playProgressEvent = getPlayProgressEvent()
        if playProgressEvent <> invalid
          trackEvent(playProgressEvent)
        end if
      end if

      m.top.state = state

    end if
  else if state = "error"
    content = m.Video.content
    errorInfo = getPlaybackErrorInfo(m.Video.position, m.Video.downloadedSegment, m.Video.streamingSegment, m.Video.streamingInfo,m.Video.errorCode, m.Video.errorMsg, content)
    tubiLog(FormatJSON(errorInfo), "error", "videoPlayback", "video-playback")
    m.top.sendYouboraError = true

    ' Set up the next DRM scheme. Playback of next DRM scheme is triggered when state = "finished",
    ' right after error state occurs.
    m.didAdvanceDrm = advanceDrmOnContent(content)
    if m.didAdvanceDrm <> true
      m.top.errorMsg = getTranslation("videoPlayer_error_playback_description")  'is used in error modal
      m.top.state = state   'triggers error modal in ContentController
    end if
  else if state = "stopped" and m.VideoState = "stop"
    ' player has stopped (not due to an ad break)
    if m.Video.content <> invalid
      ' the video has been stopped, send a final playProgressEvent
      playProgressEvent = getPlayProgressEvent()
      if playProgressEvent <> invalid
        trackEvent(playProgressEvent)
      end if
      m.top.state = state
    end if
  else if state = "playing" and m.VideoState <> "pause"
    ' reset the last ping time to the position at which video playback is starting or re-starting (after a seek)
    ' in order to avoid race conditions in which the video position might update while the handle logic is being completed.
    m.lastPingTime = m.Video.position
  end if

  ' Loading page visibility
  if state = "playing" or state = "paused"
    m.Loading.visible = false
    m.top.state = state
    if m.top.state = "playing" and (sPreviousState = "stopped" or sPreviousState = "") and m.top.fullscreen = true
      showTransport(true)
    end if
  else
    m.LoadingProgressBar.progress = 0
    m.Loading.visible = true
  end if
End Function


'''''''''''''''''''''''''
' onVideoPositionChange
'
' The notificationInterval and analyticsInterval are not necessarily equal or evenly divisible
' so we check the time passage before we send playProgress events
Function onVideoPositionChange()
  ' protects against video positions being updated after we've told the player to pause
  if m.VideoState = "play"
    m.playerPosition = m.Video.position
    m.AdsSSAITask.videoPosition = m.Video.position
  end if

  ' Auto hide transport
  if m.VideoState = "play" and m.nTransportState > 0 and m.playerPosition > m.lastButtonPressPos + m.transportAutoHideTime
    '//After some time has elapsed and the channel guide isn't currently visible and loading, then hide the transport
    hideTransport()
  end if


  ' Analytics
  if m.playerPosition >= m.lastPingTime + m.analyticsInterval
    playProgressEvent = getPlayProgressEvent()
    if playProgressEvent <> invalid
      m.lastPingTime = m.playerPosition
      trackEvent(playProgressEvent)
    end if
  end if

End Function


' id3 tags within the linear stream are used to signify when ads are playing
Function onId3(msg)
  id3 = msg.getData()
  m.AdsSSAITask.id3Tags = id3
End Function


Function onFullScreenChange()
  if m.top.fullscreen = true and m.top.state = "playing"
    '//Display transport when the playing video goes fullscreen
    showTransport(true)
  end if
  trackFullScreen(m.top.fullscreen)
End Function


Function trackFullScreen(bFullScreen)
  toggleState = "OFF"
  if bFullScreen = true
    toggleState = "ON"
  end if

  if m.top.content <> invalid
    trackEvent({
      type: "fullscreen_toggle"
      values: {
        video_id: m.top.content.id.toInt()
        toggle_state: toggleState  'ToggleState enum
      }
    })
  end if
End Function


Function onResumePointChange()
  tubiLog("DetailScreen.onResumePointChange")
  menuItems = m.Menu.content
  resumeIndex = m.NodeHelpers.getChildIndexById(menuItems, m.ResumeMenuItem.id)

  m.ResumeMenuItem.playstart = m.top.resumePoint
  if resumeIndex = -1 and m.top.resumePoint > 0
    menuItems.insertChild(m.ResumeMenuItem, 0)
  else if resumeIndex > -1 and m.top.resumePoint = 0
    menuItems.removeChildIndex(resumeIndex)
  end if
  m.Menu.content = menuItems
End Function


Function onCaptionModeChange()
  tubiLog("LineaerVideoPlayerScreen.onCaptionModeChange")
  
  hideTransport()
  '//update the closed captions UI. It may look the same but the enabled icon may be different
  createContentForClosedCaptioning()

  if m.Video.globalCaptionMode = "On"
    toggleState = "ON"
  else  'handles "Off", "Instant replay", and "When mute"
    toggleState = "OFF"
  end if

  if m.Video.content <> invalid then
    language = "UNKNOWN"
    for i=0 to m.Video.availableSubtitleTracks.count()-1
      trackInfo = m.Video.availableSubtitleTracks[i]
      if m.Video.subtitleTrack = trackInfo.TrackName
        if trackInfo.language = "eng"
          language = "EN"
        else if trackInfo.language = "spa"
          language = "ES"
        else if trackInfo.language = "fre"
          language = "FR"
        else if trackInfo.language = "fra"
          language = "FR"
        else if trackInfo.language = "kor"
          language = "KO"
        else if trackInfo.language = "cho"
          language = "ZH"
        else if trackInfo.language = "zhi"
          language = "ZH"
        end if
      end if
    end for
    trackEvent({
      type: "subtitles_toggle"
      values: {
        video_id: m.Video.content.id.toInt()
        toggle_state: toggleState  'ToggleState enum
        language_code: language  'LanguageCode enum
      }
    })
  end if
End Function


Function createContentForClosedCaptioning()
  tubiLog("LineaerVideoPlayerScreen.createContentForClosedCaptioning")
  bCaptionsAvailable = false
  availableSubtitleTracks = m.Video.availableSubtitleTracks
  if availableSubtitleTracks <> invalid and availableSubtitleTracks.Count() > 0
    bCaptionsAvailable = true
  end if


  if bCaptionsAvailable = true
    if m.NodeHelpers.getChildIndex(m.ButtonsGroup, m.ButtonCaptions) < 0
      '//add captions button if it had previously been removed
      m.ButtonsGroup.insertChild(m.ButtonCaptions, 1)
      m.ButtonCaptions.visible = true
    end if
    root = CreateObject("roSGNode", "ContentNode")
    row = root.createChild("ContentNode")
    
    bCaptionsOn = false
    if m.Video.globalCaptionMode = "On"
      bCaptionsOn = true
    end if
    content = createClosedCaptioningNode("off", (not bCaptionsOn))
    row.appendChild(content)
    usedLanguage = {} '//make sure only a single language subtitle is displayed and used
    for each track in availableSubtitleTracks
      if (track.language = "eng" or track.language = "spa") and usedLanguage[track.language] = invalid'//::TODO:: allow for multiple languages. When backend provides more captioning support, then this should be changed 
        bEnabled = false
        if bCaptionsOn = true
          if m.Video.subtitleTrack = track.trackname
          '//Get the enabled state of language
            bEnabled = true
          end if
        end if
        usedLanguage[track.language] = true
        content = createClosedCaptioningNode(track.language, bEnabled, track.trackname)
        row.appendChild(content)
      end if
    end for
    m.closedCaptioningButtonList.content = root

    backgroundCaptionsContent = root.clone(true)
    for i=0 to backgroundCaptionsContent.getChild(0).getChildCount()-1
      clonedCaptionNode = backgroundCaptionsContent.getChild(0).getChild(i)
      clonedCaptionNode.isForeground = false
    end for

    for i=0 to backgroundCaptionsContent.getChildCount()-1
      clonedCaptionNode = backgroundCaptionsContent.getChild(i)
    end for

    m.closedCaptioningButtonListBackground.content = backgroundCaptionsContent
    centerClosedCaptioning()
  else
    '//Remove the captions button since there are no captions
    m.ButtonCaptions.visible = false
    m.ButtonsGroup.removeChild(m.ButtonCaptions)
  end if
End Function



Function createClosedCaptioningNode(lang, bEnabled = false, trackname = invalid)
  content = CreateObject("roSGNode", "ClosedCaptioningContentNode")
  ' content = parent.createChild("ClosedCaptioningContentNode")
  if lang = "eng"
    language_label = "English"
  else if lang = "spa"
    language_label = "Español"
  else if lang = "off"
    language_label = getTranslation("dialog_button_off")
    trackname = "off"
  end if
  content.language_label = language_label
  content.language_id = lang
  content.trackname = trackname
  content.enabled = bEnabled
  content.isForeground = true

  return content
End Function


Function onBufferingStatus(msg)
  status = msg.GetData()
  m.LoadingMessage.text = ""
  if status <> invalid and status.percentage <> invalid
    m.LoadingProgressBar.progress = status.percentage
  end if
End Function


Function trackEvent(event As Object)
  m.global.trackingLoggingTask.trackEvent = event
End Function


'exit the video player due to back button while no transport displaying, or during ad break
Function backButtonExit()
  m.nTransportState = 0
  m.top.backButtonPressed = true
  animateTransport("out", 0, 0)
End Function


' Helper function that aggregates any tasks that need to be done before playing a new video
Function prepareToStartVideo(content, drmIndex)
  resetVideoPlayerState(content)
  setDrmOnContent(content, drmIndex)

  m.AdsSSAITask.content = content
  m.AdsSSAITask.updateContent = true

  m.top.content = content  'sends content to video node and makes current content available to contentController
  m.top.sendVideoTrackingStart = true
End Function


' Reset video player state to a state relevant to starting a video
' @content: TubiContentNode
Function resetVideoPlayerState(content = invalid)
  m.LoadingProgressBar.progress = 0
  m.LoadingMessage.text = ""
  if content <> invalid
    updateVideoPlayerState(content)
  end if
End Function


Function stopVideo()
  tubiLog("LineaerVideoPlayerScreen.stopVideo")
  m.VideoState = "stop"
  ' add check so that onVideoStateChange doesn't get called
  ' if the video is already in a non playing state.
  if m.Video.state <> "stopped" and m.Video.state <> "finished"
    m.Video.control = "stop"
  end if
End Function


' Set video player state based on passed in content
' @content: TubiContentNode
Function updateVideoPlayerState(content) as Void
  if type(content) <> "roSGNode" then return

  ' make the content available to the video node
  m.Video.content = content

  '//Update the channel icon here
  m.HUDIcon.uri = m.top.content.inlineLogoUri

  '//Update the closed captioning
  createContentForClosedCaptioning()
End Function


Function advanceDrmOnContent(contentNode)
  tubiLog("LineaerVideoPlayerScreen.advanceDrmOnContent")
  nextIndex = 0
  if contentNode.drmType <> ""
    for i=0 to contentNode.videoResources.count()-1
      resource = contentNode.videoResources[i]
      if contentNode.drmType = resource.type
        nextIndex = i + 1
        exit for
      end if
    end for
  end if

  if setDrmOnContent(contentNode, nextIndex) = true
    nextResource = contentNode.videoResources[nextIndex]

    fallbackInfo = {
      failed_url: removeExcessUrl(resource.url)
      failed_drm: resource.type
      fallback_url: removeExcessUrl(nextResource.url)
      fallback_drm: nextResource.type
      model: m.constants.deviceInfo.model
    }

    ' log that we fell back to the next playback option after playback failed due to DRM
    tubiLog(FormatJSON(fallbackInfo), "error", "videoLoad", "drm-fallback")
    return true
  else
    return false
  end if
End Function


' Updates the content node's url and httpHeaders fields with the videoResource info indicated by the index value
'
' @contentNode: roSGNode, a TubiContentNode
' @index: int, the index of the video resource we want to use for DRM
Function setDrmOnContent(contentNode, index)
  if contentNode.videoResources <> invalid and contentNode.videoResources.count() > 0 and contentNode.videoResources[index] <> invalid
    ' reset DRM fields
    contentNode.drmParams = {}
    contentNode.encodingType = ""
    contentNode.encodingKey = ""


    resource = contentNode.videoResources[index]

    ' set general fields related to DRM
    contentNode.httpHeaders = resource.drmHeaders
    contentNode.url = resource.url
    contentNode.length = resource.length
    contentNode.streamFormat = resource.streamFormat
    contentNode.drmType = resource.type

    ' set DRM scheme specific fields
    if resource.type = m.constants.player.drmTypes.dashWidevine
      contentNode.drmParams = resource.drmParams
    else if resource.type = m.constants.player.drmTypes.dashPlayready
      contentNode.encodingType = resource.encodingType
      contentNode.encodingKey = resource.encodingKey
    end if
    return true
  end if
  return false
End Function


Function getPlaybackErrorInfo(position, downloadedSegment, streamingSegment, streamInfo, errorCode, errorMsg, content)
  errorInfo = {
    video_id: ""
    video_url: ""
  }
  if errorCode = -3
    errorInfo.error_message = "Server did not respond with hls segment. Potential 504 or 404. Following segment likely has issue."
    ' Check for position to be > 0 in order to prevent segments from previous videos to populate
    ' the error messaging for the current video.
    if position > 0 and downloadedSegment <> invalid
      ' in the case of errorCode = -3, it likely means there was a 504 or 404 response from the server which ultimately was the source of the error.
      ' we get the last downloaded segment which is the last good segment instead of the current streaming segment, which may be several segments ahead of the bad segment.
      ' in this case, the segment causing the error is the segment AFTER the logged segment.
      errorInfo.segment_sequence = downloadedSegment.segSequence
      errorInfo.segment_url = removeExcessUrl(downloadedSegment.SegUrl)
      errorInfo.segment_bitrate = downloadedSegment.BitrateBps
    end if
  else if errorMsg <> invalid
    if errorCode = 0
      ' orignal network error message is to long:
      ' "Network error.  This could be caused by any of the following problems: (1) The server is down or unresponsive. (2) The server is unreachable. (3) There is a network setup issue on the client."
      errorInfo.error_message = "Network error"
    else
      errorInfo.error_message = errorMsg
    end if
    if position > 0 and streamingSegment <> invalid
      ' streamingSegment can be invalid when the server returns a 504, 404, etc.
      errorInfo.segment_url = removeExcessUrl(streamingSegment.segUrl)
      errorInfo.segment_start_time = streamingSegment.segStartTime
      errorInfo.segment_sequence = streamingSegment.segSequence
      errorInfo.segment_bitrate = streamingSegment.segBitrateBps
    end if
  end if
  errorInfo.error_code = errorCode

  if content <> invalid then errorInfo.video_id = content.id

  if position > 0 and streamInfo <> invalid
    errorInfo.video_url = removeExcessUrl(streamInfo.streamUrl)
  else if content <> invalid
    errorInfo.video_url = removeExcessUrl(content.url)
  end if

  return errorInfo
End Function


'Helper function that removes all characters after the ? in the url
Function removeExcessUrl(url)
  cutUrl = ""
  if type(url) = "roString" or type(url) = "String"
    position = url.Instr(Chr(63)) 'checks for the position of the "?" in the url string
    if position > -1
      cutUrl = url.Left(position)
    else
      cutUrl = url
    end if
  end if
  return cutUrl
End Function


' Play progress events should occur at the following instances
' a user watches for 10s
' an ad break starts
Function getPlayProgressEvent()
  playProgressEvent = invalid
  if m.playerPosition > m.lastPingTime
    videoPlayerType = "DEFAULT"
    if m.top.fullscreen = false
      videoPlayerType = "BANNER"
    end if
    playProgressEvent = {
      type: "live_play_progress"
      values: {
        video_id: m.Video.content.id.toInt()
        view_time: Int((m.playerPosition - m.lastPingTime) * 1000)   'ms
        video_player: videoPlayerType
      }
    }
  end if

  return playProgressEvent
End Function


'show transport
Function showTransport(bDelay = false)
  m.lastButtonPressPos = m.playerPosition
  if m.nTransportState = 0
    m.nTransportState = 1
  end if
  m.Transport.opacity = 1.0
  m.Transport.translation = [0,0]
  m.TransportGradient.opacity = 1.0
  nDelay = 0
  if bDelay = true
    nDelay = .5
  end if
  animateTransport("in", nDelay)
End Function


' Hide all transports and return to video
Function hideTransport()
  animateTransport("out")
  close2ndScreen()
  m.nTransportState = 0
End Function

  
'aggregates all the animation for showing/hiding the transport
'@direction: string, value may be "out" or "in"
Function animateTransport(direction, nDelay = 0, nDuration = 0.6)
  tubiLog("LineaerVideoPlayerScreen.AnimateTransport, direction = " + direction)
  slideFade(m.HUD, "below", direction, 0.6, nDelay)
  slideFade(m.HUDIcon, "above", direction, 0.6, nDelay)
  fade(m.Overlay1stScreen, direction, nDuration, nDelay)
End Function

  
'aggregates all the animation for showing/hiding the channel guide
'@direction: string, value may be "out" or "in"
Function animateGuide(direction, nDelay = 0, nDuration = 0.6)
  tubiLog("LineaerVideoPlayerScreen.animateGuide, direction = " + direction)
  slideFade(m.channelsGuideGroup, "left", direction, 0.6, nDelay)
  fade(m.Overlay2ndScreen, direction, nDuration, nDelay)
End Function
  

Function displayChannelGuide()
  animateGuide("in")

  if m.top.channelsContent = invalid or shouldRefresh(m.top.channelsContent.getChild(0)) = true
    m.top.refreshChannels = true
    m.channelsGuideGroup.display = false
  else
    displayChannelGuideList()
  end if
End Function


Function hideChannelGuide()
  m.top.displayingChannelGuide = false
  animateGuide("out")
End Function


Function displayClosedCaptioning()
  m.closedCaptioningButtonListBackground.setFocus(true)
  m.closedCaptioningButtonListBackground.setFocus(false) ' workaround for roku focus indicator bug
  m.closedCaptioningButtonListBackground.setFocus(true)  ' workaround for roku focus indicator bug

  ' preselect the caption option that the user currently has enabled
  nJumpTo = 0
  if m.closedCaptioningButtonListBackground.content <> invalid and m.closedCaptioningButtonListBackground.content.getChildCount() > 0
    captions = m.closedCaptioningButtonListBackground.content.getChild(0)
    for i = 0 to captions.getChildCount()-1
      caption = captions.getChild(i)
      if caption.enabled = true
        nJumpTo = i
      end if
    end for
    m.closedCaptioningButtonListBackground.jumpToRowItem = [0, nJumpTo]
  end if
  
  animateClosedCaptioning("in") 
End Function

  
'aggregates all the animation for showing/hiding the closed captioning
'@direction: string, value may be "out" or "in"
Function animateClosedCaptioning(direction, nDelay = 0, nDuration = 0.6)
  tubiLog("LineaerVideoPlayerScreen.animateClosedCaptioning, direction = " + direction)
  slideFade(m.closedCaptioningGroup, "below", direction, 0.6, nDelay)
  fade(m.Overlay2ndScreen, direction, nDuration, nDelay)
End Function


Function centerClosedCaptioning()
  nSpacing = m.closedCaptioningButtonList.rowItemSpacing[0][0]
  nItemWidth = m.closedCaptioningButtonList.rowItemSize[0][0]
  nItems = m.closedCaptioningButtonList.content.getChild(0).getChildCount()
  nListWidth = (nItems * nItemWidth) + ((nItems-1) * nSpacing) 

  nCenterPointX = (1920-nListWidth)/2
  m.closedCaptioningButtonList.translation = [nCenterPointX, m.closedCaptioningButtonList.translation[1]]
  m.closedCaptioningButtonListBackground.translation = [nCenterPointX, m.closedCaptioningButtonList.translation[1]]
End Function



Function onChannelGuideContentChanged()
  tubiLog("LinearVideoPlayerScreen.onChannelGuideContentChanged()")
  if m.nTransportState = 2 and m.channelsGuideGroup.opacity > 0
    if m.top.channelsContent <> invalid and m.top.channelsContent.getChildCount() > 0
      '//Display channel guide 
      displayChannelGuideList(m.top.channelsContent)
    end if
  end if
End Function


Function onCCContentFocused(msg)
  tubiLog("LinearVideoPlayerScreen.onCCContentFocused")
  '//When the closed captioning layer is focused, make sure to update lastButtonPressPos so the transport overlay does not automatically hide 
  m.lastButtonPressPos = m.playerPosition
End Function



Function onCCContentSelected(msg)
  tubiLog("LinearVideoPlayerScreen.onCCContentSelected")
  list = msg.getRoSGNode()
  item = msg.getData()

  hideTransport()
  itemContent = list.content.getChild(item[0]).getChild(item[1])
  '//::NOTE:: - When  m.Video.globalCaptionMode is changed, it triggers an observer which will change the enabled status of the closed captioning UI options
  if itemContent.trackname <> invalid and itemContent.trackname <> ""
    if itemContent.trackname = "off"
      m.Video.globalCaptionMode = "Off"
    else
      m.Video.subtitleTrack = itemContent.trackname
      m.Video.globalCaptionMode = "On"
    end if
  end if
End Function


Function onChannelGuideNavigateWithChange()
  m.top.navigateWithinPageInfo = m.channelsGuideGroup.navigateWithinPageInfo
End function


Function onChannelGuideContentFocused(msg)
  tubiLog("LinearVideoPlayerScreen.onChannelGuideContentFocused")
  '//When the guide is focused, make sure to update lastButtonPressPos so the transport overlay does not automatically hide 
  m.lastButtonPressPos = m.playerPosition
End Function


Function onChannelGuideContentSelected(msg)
  tubiLog("LinearVideoPlayerScreen.onChannelGuideContentSelected")
  channel = m.channelsGuideGroup.itemSelected

  hideTransport()
  if channel.id <> m.top.content.id 
    '//if user does not select the channel that is playing, then report the new channel. 
    '//Call getContentFromCategoryJson() to get full data
    channelUpdated = m.metadataTranslate.getContentFromCategoryJson(m.channelsGuideGroup.content, channel.id) ' can return invalid
    m.top.channelSelected = channelUpdated
  end if
End Function


Function onChannelGuideAnalyticsChanged()
  m.top.trackingComponentInfo = m.channelsGuideGroup.trackingComponentInfo
End Function


Function displayChannelGuideList(content = invalid)
  if content <> invalid
    m.channelsGuideGroup.content = content
    m.channelsGuideGroup.contentUpdated = true
  end if
  m.channelsGuideGroup.jumpToID = m.top.content.id
  m.channelsGuideGroup.display = true

  m.top.displayingChannelGuide = true
  m.top.userDisplayingChannelGuide = true
End Function


Function close2ndScreen() 
  if m.Overlay2ndScreen.opacity > 0
    '//hide all 2nd screens and put focus back on video player
    if m.top.fullscreen = true
      m.Video.setFocus(true)
    end if
    hideChannelGuide()
    animateClosedCaptioning("out") 
  end if
End Function


Function onKeyEvent(key As String, press As Boolean) as Boolean
  if press and m.top.fullscreen = true
    tubiLog("LinearVideoPlayerScreen.onKeyEvent key = " + key)
    m.lastButtonPressPos = m.playerPosition
    if m.nTransportState = 2
      '//2nd HUD screen is visible
      if key = "back" or (m.closedCaptioningGroup.opacity > 0 and key = "down") or (m.channelsGuideGroup.opacity > 0 and key = "left")
        if (m.top.displayingChannelGuide = true)
          '//Report that the user is purposely closing the channel guide
          m.top.userDisplayingChannelGuide = false
        end if
        '//Close the 2nd screen
        close2ndScreen()
        animateTransport("in")
        m.nTransportState = 1
      end if 
    else if m.nTransportState = 1
      '//root HUD screen is visible
      if key = "back"
        'close the transport
        animateTransport("out")
        m.nTransportState = 0
      else if key = "left"
        backButtonExit()
      else if key = "right"
        displayChannelGuide() 
        animateTransport("out")
        m.nTransportState = 2
      else if key = "up" and m.ButtonCaptions.visible = true
        '//If the closed captions option is available, then open that overlay
        displayClosedCaptioning() 
        animateTransport("out")
        m.nTransportState = 2
      end if
    else
      '//only the video player is visible
      if key = "back"
        backButtonExit()
      else if m.top.state = "playing"
        '// Any button should wake the overlays as long as the video is playing
        m.nTransportState = 1
        showTransport()
      end if
    end if

    ' Consume all key presses
    return true
  end if

  ' Allow unconsumed keypress to trickle up to ContentController, which is using
  ' keypresses to reset an inactivity timer
  return false
End Function
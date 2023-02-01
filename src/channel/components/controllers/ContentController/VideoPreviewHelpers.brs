' gets the video player state for content passed as param
' @content : TubiContentNode, which has the details about the title/video
' returns state : string, the state of videopreview
Function getVideoPreviewStateForThisContent(content=invalid)
  tubiLog("VideoPreviewHelpers.getVideoPreviewStateForThisContent")
  state = "none"
  videoPreview = m.top.findNode(m.constants.ui.componentIds.videoPreviewPlayer)
  if content <> invalid AND videoPreview <> invalid AND videoPreview.content <> invalid
    if videoPreview.content.id = content.id
      state = videoPreview.state
    end if
  end if

  return state
End Function


' gets the video player state
' returns state : string, the state of videopreview
Function getVideoPreviewState()
  tubiLog("VideoPreviewHelpers.getVideoPreviewState")
  state = "none"
  videoPreview = m.top.findNode(m.constants.ui.componentIds.videoPreviewPlayer)
  if videoPreview <> invalid
    state = videoPreview.state
  end if

  return state
End Function


Function onStopVideoPreview()
  tubiLog("VideoPreviewHelpers.onStopVideoPreview")
  stopVideoPreview()
End Function


' stopVideoPreview stops the video preview
' @node : roSGNode, a VideoPreviewPlayer node
Function stopVideoPreview(node=invalid)
  tubiLog("VideoPreviewHelpers.stopVideoPreview")
  if node = invalid
    node = m.top.findNode(m.constants.ui.componentIds.videoPreviewPlayer)
  end if

  if node <> invalid AND node.subType() = "VideoPreviewPlayer"
    node.control = "stop"
    node.visible = false
  end if
End Function


' stopVideoPreviewIfPlaying stops the video preview only if videopreview is playing or buffering.
' @node : roSGNode, a VideoPreviewPlayer node
Function stopVideoPreviewIfPlaying(node = invalid)
  tubiLog("VideoPreviewHelpers.stopVideoPreviewIfPlaying")
  if node = invalid
    node = m.top.findNode(m.constants.ui.componentIds.videoPreviewPlayer)
  end if

  if node <> invalid AND node.subType() = "VideoPreviewPlayer" AND (node.state = "buffering" or node.state = "playing" ) 'this means video preview not stopped/finished for previous content, so we need to stop it
    node.control = "stop"
    node.visible = false
  end if
End Function


Function onPauseVideoPreview()
  tubiLog("VideoPreviewHelpers.onPauseVideoPreview")
  pauseVideoPreview()
End Function


Function pauseVideoPreview()
  tubiLog("VideoPreviewHelpers.pauseVideoPreview")
  videoPreview = m.top.findNode(m.constants.ui.componentIds.videoPreviewPlayer)
  if videoPreview <> invalid
    videoPreview.control = "pause"
  end if
End Function


Function onVideoPreviewStateChanged(msg)
  tubiLog("VideoPreviewHelpers.onVideoPreviewStateChanged")
  videoPreview = msg.getRoSGNode()
  videoPreviewState = msg.getData()
  currentScreen = getCurrentScreen()

  if videoPreviewState = "playing" or videoPreviewState = "paused"
    if videoPreview <> invalid
      videoPreview.visible = true
    end if
    if currentScreen <> invalid
      ' updating backgroundUriList in order to change the backgroundType/gradient to EPG when video preview is playing/paused
      currentScreen.backgroundUriList = currentScreen.backgroundUriList
    end if
    m.backgroundGroup.posterVisible = false
  else if videoPreviewState = "error"
    ' unobserve the state if we have any error while playing mp4 video previews to avoid autostarting the focused content on autostart variant of experiment.
    videoPreview.unobserveFieldScoped("state")
  else
    if videoPreview <> invalid
      videoPreview.visible = false
    end if
    m.backgroundGroup.posterVisible = true
  end if

  if videoPreviewState = "finished"
    if currentScreen <> invalid
      isVideoPreviewAutoStartEnabled = getExperimentResource("roku_video_preview", "roku_video_preview_v2", false).autostart

      if isVideoPreviewAutoStartEnabled = true then
        isHdmiStatusOk = m.maintask.isHdmiStatusOk

        ' Only send exposure event if hdmi status was not ok and the user would have been effected
        sendEvent = (isHdmiStatusOk = false)
        if isHdmiPlaybackExperimentEnabled(sendEvent) = false then
          isHdmiStatusOk = true
        end if

        ' Don't want to continue playback if the user has their tv turned off
        if isHdmiStatusOk = true then
          if currentScreen.subType() = "HomeScreen"
            showDetailScreen(currentScreen.contentFocused, false, skipDetailScreen, invalid, "previews")
          else if currentScreen.subType() = "DetailScreen"
            if currentScreen.resumePoint > 0
              resumeVideoDetailScreen(currentScreen, "previews")
            else
              playVideoDetailScreen(currentScreen, "previews")
            end if
          end if
        end if
      else if getExperimentResource("roku_video_preview", "roku_video_preview_v2", false).enabled = true
        ' updating backgroundUriList in order to change the backgroundType/gradient to topright when video preview is finished
        currentScreen.backgroundUriList = currentScreen.backgroundUriList
      end if
    end if
  end if

End Function


' starts the video preview
' @content : TubiContentNode, it has all the required information to start the video preview
' @pageType : string, the type(video_page, series_detail_page, home_page) of page which is used in analytics event
Function startVideoPreview(content, pageType="home_page")
  tubiLog("VideoPreviewHelpers.startVideoPreview")
  if content <> invalid AND m.isAutoplayVideoPreviewOn = true
    videoPreview = m.top.findNode(m.constants.ui.componentIds.videoPreviewPlayer)
    if videoPreview = invalid
      videoPreview = CreateObject("roSGNode", "VideoPreviewPlayer")
      videoPreview.visible = false
      videoPreview.id = m.constants.ui.componentIds.videoPreviewPlayer
    end if
    ' unobserve field just in case previous state was errorsstart observing a fresh status.
    videoPreview.unobserveFieldScoped("state")
    videoPreview.observeFieldScoped("state", "onVideoPreviewStateChanged")
    videoPreview.pageTypeForAnalytics = pageType

    videoContent = createObject("RoSGNode", "ContentNode")
    videoContent.url = content.videoPreviewUrl
    videoContent.id = content.id
    videoContent.streamformat = "mp4" ' backend will return always as mp4

    videoPreview.content = videoContent
    videoPreview.updateContent = true
    videoPreview.control = "play"

    VideoPreviewParentGroup = m.VideoPreviewGroup
    VideoPreviewParentGroup.appendChild(videoPreview)

  end if

End Function


Function resumeVideoPreview()
  tubiLog("VideoPreviewHelpers.resumeVideoPreview")
  videoPreview = m.top.findNode(m.constants.ui.componentIds.videoPreviewPlayer)
  if videoPreview <> invalid
    videoPreview.control = "resume"
  end if

End Function


' setPageTypeForVideoPreview sets the pageType in video preview screen for analytics
' @pageType : string, the type(video_page, series_detail_page, home_page) of page which is used in analytics event
Function setPageTypeForVideoPreview(pageType)
  tubiLog("VideoPreviewHelpers.setPageTypeForVideoPreview")
  videoPreview = m.top.findNode(m.constants.ui.componentIds.videoPreviewPlayer)
  if videoPreview <> invalid
    videoPreview.pageTypeForAnalytics = pageType
  end if

End Function

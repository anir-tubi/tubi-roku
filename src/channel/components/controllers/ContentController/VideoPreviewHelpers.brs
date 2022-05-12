' gets the video player state for content passed as param
' @content : TubiContentNode, which has the details about the title/video
' returns state : string, the state of videopreview
Function getVideoPreviewStateForThisContent(content=invalid)
  tubiLog("VideoPreviewHelpers.getVideoPreviewStateForThisContent")
  state = "none"
  videoPreview = m.top.findNode(m.constants.ui.componentIds.videoPreviewPlayer)
  if content <> invalid and videoPreview <> invalid and videoPreview.content <> invalid
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
  if node <> invalid and node.subType() = "VideoPreviewPlayer"
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
  else
    if videoPreview <> invalid
      videoPreview.visible = false
    end if
    m.backgroundGroup.posterVisible = true
  end if

  if videoPreviewState = "finished"
    if currentScreen <> invalid
      if getExperimentResource("roku_video_preview", "roku_video_preview_v1", false).autostart = true
        if currentScreen.subType() = "HomeScreen"
          showDetailScreen(currentScreen.contentFocused, false, skipDetailScreen)
        else if currentScreen.subType() = "DetailScreen"
          if currentScreen.isHistory = true
            resumeVideoDetailScreen(currentScreen)
          else
            playVideoDetailScreen(currentScreen)
          end if
        end if
      else if getExperimentResource("roku_video_preview", "roku_video_preview_v1", false).enabled = true
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
  if content <> invalid and m.isAutoplayVideoPreviewOn = true
    videoPreview = m.top.findNode(m.constants.ui.componentIds.videoPreviewPlayer)
    if videoPreview = invalid
      videoPreview = CreateObject("roSGNode", "VideoPreviewPlayer")
      videoPreview.visible = false
      videoPreview.id = m.constants.ui.componentIds.videoPreviewPlayer
      videoPreview.observeField("state", "onVideoPreviewStateChanged")
    end if
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
' gets the video player state for content passed as param
' @content : TubiContentNode, which has the details about the title/video
' returns state : string, the state of videopreview
Function getVideoPreviewStateForThisContent(content = invalid)
  tubiLog("VideoPreviewHelpers.getVideoPreviewStateForThisContent")
  state = "none"
  videoPreview = m.videoPreviewPlayer
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
  videoPreview = m.videoPreviewPlayer
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
Function stopVideoPreview(node = invalid)
  tubiLog("VideoPreviewHelpers.stopVideoPreview")
  if node = invalid
    node = m.videoPreviewPlayer
  end if

  if node <> invalid AND node.subType() = "VideoPreviewPlayer"
    sendVideoPlayerCommand(node, "stop")
    node.visible = false
  end if
End Function


Function onPauseVideoPreview()
  tubiLog("VideoPreviewHelpers.onPauseVideoPreview")
  pauseVideoPreview()
End Function


Function pauseVideoPreview()
  tubiLog("VideoPreviewHelpers.pauseVideoPreview")
  videoPreview = m.videoPreviewPlayer
  if videoPreview <> invalid
    sendVideoPlayerCommand(videoPreview, "pause")
  end if
End Function


Function onVideoPreviewStateChanged(msg)
  tubiLog("VideoPreviewHelpers.onVideoPreviewStateChanged")
  videoPreview = msg.getRoSGNode()
  videoPreviewState = msg.getData()
  currentScreen = getCurrentScreen()

  if videoPreviewState = "playing" OR videoPreviewState = "paused"
    if videoPreview <> invalid
      videoPreview.visible = true
    end if

    m.backgroundGroup.posterVisible = false
  else if videoPreviewState = "error"
    ' unobserve the state if we have any error while playing mp4 video previews to avoid autostarting the focused content on autostart variant of experiment.
    videoPreview.unobserveFieldScoped("state")
    videoPreview.unobserveFieldScoped("position")
  else
    if videoPreview <> invalid
      videoPreview.visible = false
    end if
    m.backgroundGroup.posterVisible = true
  end if

  if videoPreviewState = "finished"
    if currentScreen <> invalid

      'Don't want to continue to full player from video preview if the user is in kidsmode, teen level for UK and NZ region as per GDPR guidelines.
      'Also dont auto start locked contents.
      item = currentScreen.contentFocused

      if currentScreen.subType() = "DetailScreen"
        item = currentScreen.content
      end if

      isReplay = false
      if item <> invalid AND item.gridItemType = m.constants.ui.gridItemTypes.skinAd
        isReplay = true
      end if

      isFullPlayerBlockedForUser = (isGDPR(m.constants) = true AND (isKidsUIOn() = true OR isParentalControlsAdultLevel() = false)) OR ( item <> invalid AND item.needsLogin = true AND isloggedInUser() = false)

      if isReplay = true
        '//Loop the video in this case
        if m.maintask.isHdmiStatusOk = true
          ' Don't want to continue playback if the user has their tv turned off
          sendVideoPlayerCommand(videoPreview, "play")
        end if
        m.backgroundGroup.posterVisible = true

      else if m.maintask.isHdmiStatusOk = true AND isFullPlayerBlockedForUser = false
        ' Don't want to continue playback if the user has their tv turned off
        if currentScreen.subType() = "DetailScreen"

          playbackSource = {
            "srcForAnalytic": "previews"
            "srcForAds": currentScreen.playbackSource.srcForAds
            "playbackContainer": currentScreen.playbackSource.playbackContainer
          }
          if currentScreen.resumePoint > 0
            resumeVideoDetailScreen(currentScreen, playbackSource)
          else
            playVideoDetailScreen(currentScreen, playbackSource)
          end if
        else
          '//by default open the detail screen
          playbackSource = {
            "srcForAnalytic": "previews"
            "srcForAds": m.constants.player.playbackOrigin.container
            "playbackContainer": currentScreen.currCategoryId
          }
          showDetailScreen(currentScreen.contentFocused, false, skipDetailScreen, invalid, playbackSource)
        end if
      else if isFullPlayerBlockedForUser = true
        'Updating backgroundUriList once video preview finished to show the background images instead of black backgroud.
        currentScreen.backgroundUriList = currentScreen.backgroundUriList
      end if
    end if
  end if

  trackVideoPlayerStoppingState(videoPreviewState)
End Function


' starts the video preview
' @content : TubiContentNode, it has all the required information to start the video preview
' @pageInfo: assocarray, value can be { pagetype: "home_page", pagevalues: {}}
Function startVideoPreview(content, pageInfo = {})
  tubiLog("VideoPreviewHelpers.startVideoPreview")


  if content <> invalid AND (isVideoPreviewOn() = true OR (content.gridItemType = m.constants.ui.gridItemTypes.skinAd AND m.constants.deviceInfo.IsAutoplayEnabled = true AND m.constants.deviceInfo.limitedUi = false))
    '//::NOTE:: if this is a skinAd content, the above conditional statement checks if the device auto play setting is on and that the device is not a limited UI device before playing the looping background video
    videoPreview = m.videoPreviewPlayer

    ' If the experiment is enabled and focused content is from featured row than expand preview to full screen.
    if content.gridItemType = m.constants.ui.gridItemTypes.skinAd
      ' Reducing 1px from both width and height since the player is in background and keeping full width causes roku to display closed captioning overlay.
      ' To avoid any other Roku OS level default behavior from kicking in reducing 1px to give a impression that player is not in full screen.
      updatePreviewPlayerToFullScreen()
      videoPreview.unObserveFieldScoped("position")
      videoPreview.observeFieldScoped("position", "onVideoPreviewPositionChanged")
    else
      updatePreviewPlayerToCondensedView()
    end if

    ' unObserve field just in case previous state was errorsstart observing a fresh status.
    videoPreview.unObserveFieldScoped("state")
    videoPreview.observeFieldScoped("state", "onVideoPreviewStateChanged")
    setPageInfoForVideoPreview(pageInfo)

    videoContent = createObject("RoSGNode", "ContentNode")
    videoContent.id = content.id

    trailerInfo = content.trailerInfo
    if  getExperimentResource("roku_trailer_vs_preview_nav", "roku_trailer_vs_preview_nav_v1", false).enabled = true AND isAA(trailerInfo) = true AND isNonEmptyString(content.videoPreviewUrl) = true
      videoContent.addField("trailerId", "string", false)
      videoContent.url = trailerInfo.url
      videoContent.trailerId = trailerInfo.id
      videoContent.streamformat = trailerInfo.streamFormat ' this is for trailers playing as preview for roku_trailer_vs_preview_nav_v1 experiment
    else
      if isNonEmptyString(content.previewId) = true
        videoContent.addField("previewId", "string", false)
        videoContent.previewId = content.previewId
      end if
      videoContent.url = content.videoPreviewUrl
      videoContent.streamformat = "mp4" ' backend will return always as mp4 for video previews
    end if

    videoPreview.content = videoContent
    videoPreview.updateContent = true
    sendVideoPlayerCommand(videoPreview, "play")
  end if

End Function


Function updatePreviewPlayerToCondensedView()
  resizeToLocation(m.videoPreviewPlayer, 1120, 630, [799, 0], 0)
End Function


Function updatePreviewPlayerToFullScreen()
  resizeToLocation(m.videoPreviewPlayer, 1919, 1079, [0, 0], 0)
End Function

Function resumeVideoPreview()
  tubiLog("VideoPreviewHelpers.resumeVideoPreview")
  videoPreview = m.videoPreviewPlayer
  if videoPreview <> invalid
    sendVideoPlayerCommand(videoPreview, "resume")
  end if

End Function


' setPageInfoForVideoPreview sets the pageType in video preview screen for analytics
' @pageInfo: assocarray, value can be { pagetype: "home_page", pagevalues: {}}
Function setPageInfoForVideoPreview(pageInfo = {})
  tubiLog("VideoPreviewHelpers.setPageTypeForVideoPreview")
  videoPreview = m.videoPreviewPlayer
  if videoPreview <> invalid
    videoPreview.pageInfoForAnalytics = pageInfo
  end if

End Function


' setVideoPreviewAfterFocus sets the proper state of the video preview video player when a video content has gained focus
' @param focusedContent, roSGNode - The TubiContentNode of the focused content
' @pageInfo: assocarray, value can be { pagetype: "home_page", pagevalues: {}}
Function setVideoPreviewAfterFocus(focusedContent, pageInfo = {})
  tubiLog("VideoPreviewHelpers.setVideoPreviewAfterFocus")
  if focusedContent <> invalid AND focusedContent.type <> invalid AND m.SideNav.opened <> true
    if isVideoPreviewOn() = true OR focusedContent.gridItemType = m.constants.ui.gridItemTypes.skinAd
      previewState = getVideoPreviewStateForThisContent(focusedContent)
      if previewState = "buffering" OR previewState = "playing"
        videoPreview = m.videoPreviewPlayer
        if videoPreview <> invalid
          setPageInfoForVideoPreview(pageInfo)
          if previewState = "buffering"
            resumeVideoPreview()
          end if

          if focusedContent.gridItemType = m.constants.ui.gridItemTypes.skinAd
            if isCurrentScreenHomeScreen() = true
              updatePreviewPlayerToFullScreen()
            end if
          end if
        end if
        m.backgroundGroup.posterVisible = false
      else if previewState = "paused"
        resumeVideoPreview()
      else
        ' this block is needed if user focuses to different content,
        ' it stops the preview of current content & starts the preview of new content
        stopVideoPreview()

        if isLinearPlayerPlayingThisContent(focusedContent) = false
          m.backgroundGroup.posterVisible = true
        end if

        if focusedContent.videoPreviewUrl <> ""
          startVideoPreview(focusedContent, pageInfo)
        end if

      end if
    else

      ' this block is needed if user focuses to different content that is not the skinAd,
      ' it ensures it stops the preview of the skinAd content if the skinAd content was the previous current content
      stopVideoPreview()
    end if

  end if
End Function


Function onVideoPreviewPositionChanged(msg)
  videoPreviewScreen = msg.getRoSGNode()
  position = msg.getData()
  duration = videoPreviewScreen.duration
  currentScreen = getCurrentScreen()

  contentFocused = currentScreen.contentFocused
  if contentFocused <> invalid AND contentFocused.gridItemType = m.constants.ui.gridItemTypes.skinAd
    if position >= (duration - 1)
      '//this is a loop video. Display the background poster while the video buffers to show again
      m.backgroundGroup.posterVisible = true
    end if
  end if
End Function

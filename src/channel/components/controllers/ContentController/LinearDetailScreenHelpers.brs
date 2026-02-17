' Show the linear detail screen for the selected content.
' @content, associative array, the content item to show.
' @playbackSource, associative array, the playback source for the content.
Function showLinearDetailScreen(content, playbackSource)
  showHideLogoBasedOnUiMode()

  if content <> invalid
    screen = CreateObject("roSGNode", "LinearDetailScreen")
    screen.observeFieldScoped("backgroundUriList", "onLinearDetailsBackgroundChange")
    screen.observeFieldScoped("componentInteractionInfo", "onComponentInteractionInfoChange")
    screen.observeFieldScoped("backButtonPressed", "onDetailBackButtonPressedChange")
    screen.observeFieldScoped("navigateWithinPageInfo", "onNavigateWithinPageInfoChange")
    screen.observeFieldScoped("selectedRelatedContentTrigger", "onLinearDetailSelectedRelatedContentTriggerChange")
    screen.observeFieldScoped("ctaButtonSelectedId", "onLinearDetailCtaButtonSelected")
    screen.id = m.constants.ui.screenIds.linearDetailScreen
    screen.shouldFocusWhenPushed = m.top.fadeInContentController
    screen.playbackSource = playbackSource
    ' we make changes to the content from this point forward. If we don't clone, changes will be propagated to the original content in home or search screen.
    screen.content = content.clone(true)
    contentId = content.id
    screen.trackingPageInfo = {
      pageType: "linear_details_page"
      pageValues: {
        video_id: contentId
      }
    }
    getLinearRelatedContent(content)
    pushScreen(screen, true, true)
  end if
End Function


Function onLinearDetailsBackgroundChange(msg)
  screen = msg.getRoSGNode()
  if screen.isInFocusChain() = true
    m.backgroundGroup.backgroundInfo = {
      type: m.constants.ui.backgroundTypes.spotlight
      uriList: screen.backgroundUriList
    }
  end if

  videoPreviewState = getVideoPreviewState()
  if arrayIncludes(["playing", "paused", "buffering"], videoPreviewState) OR isVideoPreviewPlayQueued() = true
    updatePreviewPlayerToFullScreen()
  end if
End Function


Function getLinearRelatedContent(content)
  if content <> invalid
    relatedRequestInfo = m.cmsApi.createRelatedContentReqInfo(content.id, shouldKidsModeBeSentToServer())
    requestType = m.constants.reqNames.getRelatedContent

    m.makeRequest({
      url: relatedRequestInfo.url
      requestType: requestType
      options: relatedRequestInfo.options
      successCallback: handleLinearRelatedResponse
      responseType: "node"
      silenceCallbackWarnings: true
      contentId: content.id
      isSignedInUser: isLoggedInUser()
    })
  end if
End Function


Function handleLinearRelatedResponse(relatedContent)
  if relatedContent <> invalid
    screen = getCurrentScreen()
    if screen.subtype() = "LinearDetailScreen" AND screen.content <> invalid AND screen.content.id = relatedContent.id
      ' Providing user friendly id to related content node to for analytics purposes.
      relatedContent.id = "you_may_also_like"
      screen.relatedContent = relatedContent
      screen.relatedContentUpdated = true
    end if
  end if
End Function


Function onLinearDetailSelectedRelatedContentTriggerChange(msg) as Void
  screen = msg.getRoSGNode()
  if screen <> invalid AND screen.id = m.constants.ui.screenIds.linearDetailScreen
    content = screen.selectedRelatedContent
    m.videoSponsorExposureId = ""

    playbackSource = {
      "srcForAnalytic": m.constants.player.playbackSource.unknown
      "srcForAds": m.constants.player.playbackOrigin.ymal
    }
    processUserContentSelection(content, screen, playbackSource)
  end if
End Function


Function updateLiveEventsContainerWithEpgListingInfo(scheduleId)
  m.makeRequest({
    url: m.constants.urls.content.epgListingEndpoint + "/" + scheduleId
    requestType: m.constants.reqNames.getEpgListing
    successCallback: updateHomeScreenContainersWithEpgListingInfo
    errorCallback: updateHomeScreenContainersWithEpgListingInfo
    responseType: "assocarray"
    retries: 0
  })
End Function


Function updateHomeScreenContainersWithEpgListingInfo(schedule)
  if isAA(schedule) = true AND isNonEmptyString(schedule.startTime) = true
    screen = getFromScreenCache(m.constants.ui.screenIds.homeScreen)
    if isNode(screen) = true
      if isNode(screen.content) = true
        content = screen.content
      else
        content = screen.content
      end if
      container = getLiveEventsContainer(content)
      if isNode(container) = true AND container.getChildCount() > 0
        child = container.getChild(0)
        child.scheduleData = schedule
        if isGreaterThanCurrentTime(schedule.endTime) = false
          content.removeChild(container)
          screen.contentUpdated = true
        end if
      end if
    end if
  end if
End Function


Function addOrRemoveReminderForEventContent(content)
  bookmark = getBookmark(content.id)
  didUserSetReminderForEventContent = (bookmark <> invalid)
  contentId = content.id
  contentType = content.type
  ' Backend does not support "video" type for reminders. Only "movie,series,sports_event" are supported.
  if contentType = m.constants.ui.contentTypes.video
    contentType = m.constants.ui.contentTypes.movie
  end if
  if didUserSetReminderForEventContent <> true
    addToQueueReq = m.userDeviceApi.addToQueueReqInfo(contentId, contentType, m.constants.userQueueType.remindMe)
    m.makeRequest({
      url: addToQueueReq.url
      requestType: m.constants.reqNames.postToQueue
      options: addToQueueReq.options
      successCallback: onSetReminderSuccess
      silenceCallbackWarnings: true
      responseType: "assocarray"
    })
  else
    removeFromQueueReq = m.userDeviceApi.removeFromQueueReqInfo(bookmark.bookmarkId, contentId, contentType)
    m.makeRequest({
      url: removeFromQueueReq.url
      requestType: m.constants.reqNames.deleteFromQueue
      options: removeFromQueueReq.options
      successCallback: onRemoveReminderSuccess
      silenceCallbackWarnings: true
      responseType: "assocarray"
    })
  end if
End Function


Function onSetReminderSuccess(response)
  if isAA(response) = true
    content = CreateObject("roSGNode", "BookmarkContentNode")
    content.id = response.content_id
    content.bookmarkId = response.id
    refreshReminderStatus(content, true)

    showToast({
      "selfDestructTimer": 5
      "headerText": getTranslation("reminder_set_toast_header")
      "message": getTranslation("reminder_set_toast_subheader")
      "imageUri": "pkg:/images/reminder-set-filled.webp"
    })
  end if
End Function


Function onRemoveReminderSuccess(response)
  content = getBookmark(response.content_id)
  refreshReminderStatus(content, false)
End Function


Function refreshReminderStatus(content, reminderStatus)
  updateBookmarkLocally(content, reminderStatus)
  screen = getCurrentScreen()
  if screen.subtype() = "LinearDetailScreen" AND screen.content <> invalid
    screen.content.update({
      didUserSetReminderForEventContent: reminderStatus
    }, true)
  end if

  handleQueueChange()
End Function


Function onLinearDetailCtaButtonSelected(msg)
  screen = msg.getRoSGNode()
  content = screen.content
  processUserContentSelection(content, screen, screen.playbackSource)
End Function

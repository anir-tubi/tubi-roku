' @eventId: String, id of the program or event.
' @purpleCarpetContainerContent: roSGNode|invalid, purple carpet container content node or invalid incase it is not present in the home screen response.
' @eventContent: roSGNode|invalid, content node or invalid of the individual content node will be used in case of banner click and deeplink.
' @onScreenLoadCompletionCallback: Function, callback triggered once the screen has been completely loaded.
Function showEventDetailScreen(eventId, purpleCarpetContainerContent = invalid, eventContent = invalid, onScreenLoadCompletionCallback = invalid)
  screen = CreateObject("roSGNode", "EventDetailsScreen")
  screen.id = m.constants.ui.screenIds.eventDetailScreen
  screen.trackingLoadStartTime = Uptime(0)
  screen.observeFieldScoped("backgroundUriList", "onEventDetailsBackgroundChange")
  screen.observeFieldScoped("itemSelected", "onEventDetailsItemSelectedChange")
  screen.observeFieldScoped("eventCtaListItemSelected", "onEventCtaListItemSelected")
  screen.observeFieldScoped("backButtonPressed", "onDetailBackPressed")
  screen.observeFieldScoped("componentInteractionInfo", "onComponentInteractionInfoChange")

  bookmark = getBookmark(eventId)
  screen.didUserSetReminderForEventContent = (bookmark <> invalid)
  authInfo = m.tubiAuthUpdate.getAuthInfo()
  screen.signedIn = isLoggedInUser(authInfo)
  screen.eventId = eventId
  screen.trackingPageInfo = {
    pageType: "linear_details_page"
    pageValues: {
      video_id: eventId
    }
  }

  if purpleCarpetContainerContent <> invalid
    screen.content = purpleCarpetContainerContent
    if onScreenLoadCompletionCallback <> invalid
      onScreenLoadCompletionCallback()
    end if
    screen.contentIsReady = true
  else if eventContent <> invalid
    screen.contentIsReady = false
    m.eventDetailsScreenLoadCompletionCallback = onScreenLoadCompletionCallback
    m.singlePurpleCarpetEventContentNode = eventContent
    ' Making a call to fetch container info.
    getPurpleCarpetContainerInfo()
  end if
  
  pushScreen(screen, true, true)
  
  m.wasUserShownPurpleCarpetAvailableAtToast = false
End Function


Function onEventDetailsBackgroundChange(msg)
  detailScreen = msg.getRoSGNode()
  if detailScreen.isInFocusChain() = true
    m.backgroundGroup.backgroundInfo = {
      type: m.constants.ui.backgroundTypes.spotlight
      uriList: detailScreen.backgroundUriList
    }
  end if
End Function


' Callback will be triggered when list content items in event details screen is selected.
Function onEventDetailsItemSelectedChange(msg)
  screen = msg.getRoSGNode()
  content = msg.getData()
  if content <> invalid
    processPlayEvent(content, screen)
  end if
End Function


Function processEventDeeplink(event)
  currentDatetime = CreateObject("roDateTime")
  airDatetime = CreateObject("roDateTime")
  airDatetime.FromISO8601String(event.airDateTime)
  callback = invalid
  ' If current time is greater than the air date time that means the program is live and we will start playback if user is signed in.
  if currentDatetime.asSeconds() >= airDatetime.asSeconds() AND (isLoggedInUser() = true OR event.needsLogin = false)
    callback = startPurpleCarpetDeeplinkedEventPlayback
  end if

  showEventDetailScreen(event.id, invalid, event, callback)
End Function


Function getPurpleCarpetContainerInfo()
  isKidsMode = shouldKidsModeBeSentToServer()
  categoryReqInfo = m.CmsApi.createCategoryReqInfo(m.constants.ui.categoryIds.purpleCarpet, isKidsMode, {})
  m.makeRequest({
    url: categoryReqInfo.url
    requestType: m.constants.reqNames.getCategory
    options: categoryReqInfo.options
    successCallback: onPurpleCarpetContainerRequestComplete
    errorCallback: onPurpleCarpetContainerRequestComplete
    responseType: "node"
    screenId: m.constants.ui.screenIds.eventDetailScreen
    isSignedInUser: isLoggedInUser()
  })
End Function


Function onPurpleCarpetContainerRequestComplete(response)
  screen = getCurrentScreen()
  if screen.id = m.constants.ui.screenIds.eventDetailScreen AND m.singlePurpleCarpetEventContentNode <> invalid
    ' Converting the single content node to a rowlist container content node format.
    if isNode(response) = true
      container = response
    else
      container = CreateObject("roSGNode", "ContentNode")
      container.update({
        children: [m.singlePurpleCarpetEventContentNode]
      }, true)
    end if
    
    context = {
      purpleCarpetContainer: container
      screenId: screen.id
    }
    
    updateContainerWithProgramInfoFromFoxListing(context, updateEventDetailsPurpleCarpetContent)
  end if
  
End Function


Function updateEventDetailsPurpleCarpetContent(purpleCarpetContainer, _screenId)
  screen = getCurrentScreen()

  if screen.id = m.constants.ui.screenIds.eventDetailScreen
    rowListContent = CreateObject("roSGNode", "ContentNode")
    rowListContent.appendChild(purpleCarpetContainer)
    screen.content = rowListContent

    ' Updating the purpleCarpetContainerContentNode to updated value.
    ' Covers use cases where we load event details directly during deeplink.
    m.purpleCarpetContainerContentNode = purpleCarpetContainer.clone(true)

    callback = m.eventDetailsScreenLoadCompletionCallback
    if isFunction(callback) = true
      m.eventDetailsScreenLoadCompletionCallback = invalid
      callback()
    end if

    screen.contentIsReady = true
  end if
End Function


Function startPurpleCarpetDeeplinkedEventPlayback()
  stopLinearVideoContent()
  playbackSource = getPlaybackSourceForDeeplinkType()
  screen = getCurrentScreen()

  if screen.id = m.constants.ui.screenIds.eventDetailScreen
    ' primaryEventContent will contain the processed node which will also have updated values from listing endpoint.
    playLinearVideoContent(screen.primaryEventContent, false, m.constants.ui.screenIds.eventDetailScreen, false, playbackSource)
  end if
End Function

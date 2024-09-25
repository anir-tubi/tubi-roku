Function showEventDetailScreen(eventId, content)
  screen = CreateObject("roSGNode", "EventDetailsScreen")
  screen.id = m.constants.ui.screenIds.eventDetailScreen
  screen.trackingLoadStartTime = Uptime(0)
  screen.observeFieldScoped("backgroundUriList", "onEventDetailsBackgroundChange")
  screen.observeFieldScoped("itemSelected", "onEventDetailsItemSelectedChange")
  screen.observeFieldScoped("eventCtaListItemSelected", "onEventCtaListItemSelected")
  screen.observeFieldScoped("backButtonPressed", "onDetailBackPressed")

  bookmark = getBookmark(eventId)
  screen.didUserSetReminderForEventContent = (bookmark <> invalid)
  authInfo = m.tubiAuthUpdate.getAuthInfo()
  screen.signedIn = isLoggedInUser(authInfo)
  screen.eventId = eventId
  screen.content = content
  
  pushScreen(screen, true, true)
End Function


Function onEventDetailsBackgroundChange(msg)
  detailScreen = msg.getRoSGNode()
  if detailScreen.isInFocusChain() = true
    m.backgroundGroup.backgroundInfo = {
      type: m.constants.ui.backgroundTypes.topright
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

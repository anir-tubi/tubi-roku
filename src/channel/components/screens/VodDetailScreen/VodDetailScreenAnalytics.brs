' VodDetailScreen Analytics Module
' Handles all analytics tracking for the VOD Detail Screen
' Including navigation within page, component interactions, and tracking info propagation


' ============================================================================
' ANALYTICS INITIALIZATION
' ============================================================================

' Initializes analytics configuration mappings
' Sets up button and tab ID to analytics section mapping
Function initAnalytics() as Void
  m.buttonIdToAnalyticsSection = {
    play: "PLAY"
    resume: "CONTINUE_WATCHING"
    startFromBeginning: "START_FROM_BEGINNING"
    watchTrailer: "WATCH_TRAILER"
    addToQueue: "ADD_TO_MY_LIST"
    removeFromQueue: "REMOVE_FROM_MY_LIST"
    like: "LIKE"
    dislike: "DISLIKE"
    signIn: "SIGNUP_TO_SAVE_PROGRESS"
    creator: "COLLECTION"
    gotoChannel: "GO_TO_NETWORK"
    removeFromHistory: "REMOVE_FROM_HISTORY"
    likeRemoveRating: "LIKE_REMOVE_RATING"
    dislikeRemoveRating: "DISLIKE_REMOVE_RATING"
    ratings: "LIKE_DISLIKE"
    ratingsLiked: "LIKE_REMOVE_RATING"
    ratingsDisliked: "DISLIKE_REMOVE_RATING"
    episodes: "EPISODES_LIST"
    moreLikeThis: "YOU_MAY_ALSO_LIKE"
    details: "INFORMATION"
    setReminder: "SET_REMINDER"
    removeReminder: "REMOVE_REMINDER"
  }
End Function


' ============================================================================
' ANALYTICS EVENT PROPAGATION
' ============================================================================

' Handles navigate within page info changes from child components
' Propagates the navigation tracking info to parent
' @param msg - Message object containing navigate within page info
Function onNavigateWithinPageInfoChange(msg) as Void
  m.top.navigateWithinPageInfo = msg.getData()
End Function


' Handles tracking page info changes
' Updates child containers with the new tracking page info
' @param msg - Message object containing tracking page info
Function onTrackingPageInfoChange(msg) as Void
  trackingPageInfo = msg.getData()
  ' Cannot use alias since trackingPageInfo is defined at base screen level
  m.relatedContentContainer.trackingPageInfo = trackingPageInfo
  m.episodesContainer.trackingPageInfo = trackingPageInfo
  m.actionButtonList.trackingPageInfo = trackingPageInfo
  m.sectionTabs.trackingPageInfo = trackingPageInfo
  m.contentContainer.trackingPageInfo = trackingPageInfo
End Function


' Handles navigate within page event info changes from button lists (actionButtonList, sectionTabs)
' Propagates the navigation event info to parent via navigateWithinPageInfo
' @param msg - Message object containing navigate within page event info
Function onButtonListNavigateWithinPageEventInfoChange(msg) as Void
  eventInfo = msg.getData()
  if eventInfo <> invalid
    ' TODO: Remove this once we have a proper way to track vertical location for roku_content_details_v7
    if msg.getRoSGNode().isSameNode(m.actionButtonList)
      eventInfo.vertical_location = 1
    end if
    m.top.navigateWithinPageInfo = eventInfo
  end if
End Function


' ============================================================================
' BUTTON ANALYTICS TRACKING
' ============================================================================

' Sets component interaction event for action buttons and section tabs
' Sends analytics events for user interactions with buttons and tabs
' @param componentInteractionValue - String, user interaction type (TOGGLE_ON, TOGGLE_OFF, CONFIRM)
' @param button - Object, the button or tab content node
Function setComponentInteractionEventForButton(componentInteractionValue as String, button as Dynamic) as Void
  if m.top.trackingPageInfo = invalid OR button = invalid OR button.id = invalid then return

  buttonAnalyticsValue = m.buttonIdToAnalyticsSection[button.id]
  if buttonAnalyticsValue = invalid then return

  componentValues = {
    middle_nav_section: buttonAnalyticsValue
  }

  pageOneof = m.tracking.getAnalyticsPage(m.top.trackingPageInfo.pageType, m.top.trackingPageInfo.pageValues)
  componentOneof = m.tracking.getAnalyticsComponent("middle_nav_component", componentValues)

  m.top.componentInteractionInfo = {
    pageOneof: pageOneof
    componentOneof: componentOneof
    user_interaction: componentInteractionValue
  }

  ' Do not set middle_nav_component for playback buttons, otherwise we overwrite the related content tracking info for YMAL
  if button.id <> "play" AND button.id <> "resume" AND button.id <> "startFromBeginning"
    m.top.trackingComponentInfo = {
      componentType: "middle_nav_component"
      componentValues: componentValues
    }
  end if
End Function


' ============================================================================
' BUTTON COMPONENT ANALYTICS TRACKING
' ============================================================================

' Fires ComponentInteractionEvent for button interactions (e.g., LEFT key to open side nav)
' @param buttonValue - String, button value (e.g., "LEFT", "BACK")
' @param buttonType - String, button type (e.g., "UNKNOWN", "IMAGE", "TEXT")
' @param userInteraction - String, user interaction type (e.g., "CONFIRM", "BACK")
Function fireButtonComponentInteractionEvent(buttonValue as String, buttonType as String, userInteraction as String) as Void
  if m.top.trackingPageInfo = invalid then return

  componentValues = {
    button_type: buttonType
    button_value: buttonValue
  }

  pageOneof = m.tracking.getAnalyticsPage(m.top.trackingPageInfo.pageType, m.top.trackingPageInfo.pageValues)
  componentOneof = m.tracking.getAnalyticsComponent("button_component", componentValues)

  m.top.componentInteractionInfo = {
    pageOneof: pageOneof
    componentOneof: componentOneof
    user_interaction: userInteraction
  }
End Function


' ============================================================================
' SIDE NAV ANALYTICS TRACKING
' ============================================================================

' Fires NavigateWithinPageEvent when user opens side nav from VOD detail screen
' Tracks navigation from middle nav component to left side nav component
Function fireNavigateToSideNavEvent() as Void
  if m.top.trackingPageInfo = invalid OR m.actionButtonList = invalid then return

  ' Get tracking context from the component gaining focus
  componentGainingFocus = m.actionButtonList.componentGainingFocus
  if componentGainingFocus = invalid then return

  trackingContext = invalid
  if componentGainingFocus.itemContent <> invalid
    trackingContext = componentGainingFocus.itemContent.trackingContext
  end if

  if trackingContext = invalid then return

  ' Build navigate within page info
  pageOneof = m.tracking.getAnalyticsPage(m.top.trackingPageInfo.pageType, m.top.trackingPageInfo.pageValues)

  ' Source component (middle nav) - use tracking context from component
  componentOneof = m.tracking.getAnalyticsComponent(trackingContext.type, trackingContext.values)

  ' Destination component (left side nav)
  destComponentValues = {
    left_nav_section: m.tracking.sideNavPageMap[m.top.selectedSideNavId]
  }
  destComponentOneof = m.tracking.getAnalyticsDestinationComponent("dest_left_side_nav_component", destComponentValues)

  ' Build navigate within page event
  navigateWithinPageInfo = {
    pageOneof: pageOneof
    componentOneof: componentOneof
    dest_componentOneof: destComponentOneof
    means_of_navigation: "BUTTON"
    horizontal_location: 1
    vertical_location: m.actionButtonList.focusedIndex + 1
  }

  m.top.navigateWithinPageInfo = navigateWithinPageInfo
End Function

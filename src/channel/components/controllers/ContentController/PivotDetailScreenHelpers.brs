' PivotDetailScreenHelpers - Helper functions for PivotDetailScreen
' Used with roku__pivots_v1 experiment


' Shows the PivotDetailScreen with the provided pivot data
' @param pivot - AssocArray with id (string) and title (string) properties
' @param destTrackingComponentInfo - Optional dest component info for NavigateToPageEvent on back (e.g. pivot collection component)
Function showPivotDetailScreen(pivot as Dynamic, destTrackingComponentInfo = invalid) as Void
  showHideSpinner(true)
  screen = createScreen("PivotDetailScreen")
  screen.shouldTrackViewableImpressionEvent = (isUserInAdultsMode() = true AND isKidsUIOn() = false)
  ' Set up observers
  screen.observeFieldScoped("contentSelectedIndex", "onContentSelected")
  screen.observeFieldScoped("playContentIndex", "onPivotDetailPlayContentIndexChanged")
  screen.observeFieldScoped("backButtonPressed", "onPivotDetailBackButtonPressed")
  ' Set up video tiles observers
  setupVideoTilesObservers(screen)

  ' Set the enableVideoTiles field using the centralized method
  screen.enableVideoTiles = isVideoTileEnabledScreen(m.constants.ui.screenIds.pivotDetailScreen)

  ' Set tracking page info
  screen.trackingPageInfo = {
    pageType: "collection_page"
    pageValues: {
      section: "PIVOT"
      id: pivot.id
    }
  }

  ' Set screen data
  screen.isSignedInUser = isLoggedInUser()
  screen.uiMode = m.uiMode
  screen.serverPersistentData = m.pub_serverPersistentData
  screen.pivotTitle = pivot.title
  screen.pivotId = pivot.id

  ' Set dest component info for NavigateToPageEvent when backing out
  if destTrackingComponentInfo <> invalid
    screen.destTrackingComponentInfo = destTrackingComponentInfo
  end if

  ' Push screen to stack
  pushScreen(screen, true, true)
End Function


' Handles back button press on PivotDetailScreen
' @param msg - Message containing the back button state
Function onPivotDetailBackButtonPressed(msg) as Void
  stopVideoPreview()
  showHideSpinner(false)
  popScreen(true, true)
End Function


' Handles play button press on PivotDetailScreen
' Uses contentFocused to get the content and triggers play action
' @param msg - Message containing the play content index [row, column]
Function onPivotDetailPlayContentIndexChanged(msg) as Void
  screen = msg.getRoSGNode()
  content = screen.contentFocused

  if content = invalid then return

  containerId = getCurrentFocusedContainerId(screen, content)
  playbackSource = {
    "srcForAnalytic": m.constants.player.playbackSource.unknown
    "srcForAds": m.constants.player.playbackOrigin.container
    "playbackContainer": containerId
  }

  processUserPlayAction(content, screen, playbackSource)
End Function

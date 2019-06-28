Function init()
  m._ = rodash()
  '//This var is used to know when to send tracking info. Do not send focus tracking info when the grid is 1st loaded
  m.contentLoadedAndFocused = false
  m.constants = m.global.constants

  m.defaultBackgroundUri = m.constants.ui.uris.defaultBackground
  Request = TubiRequest()
  Auth = TubiAuth(m.constants, Request)
  m.Tracking = TubiTracking(m.constants, Request, Auth)

  m.ChannelCategoryGrid = m.top.findNode("ChannelCategoryGrid")

  m.top.observeField("callingPage", "onSetCallOfAction")
  m.top.observeField("shouldLoadContent", "onLoadContent")
  m.top.observeField("isLoading", "onIsLoading")
  m.top.observeField("focusedChild", "onScreenFocusChange")
  m.ChannelCategoryGrid.observeField("itemFocused", "onItemFocused")
  m.ChannelCategoryGrid.observeField("itemSelected", "onItemSelected")

  ' set initial tracking values
  m.top.trackingPageInfo = createTrackingPageInfo(invalid)

End Function

Function onSetCallOfAction()
  sPreviousPage = m.top.callingPage
  if sPreviousPage <> invalid and Len(sPreviousPage) > 0
    sPreviousPage = "FOR " + UCase(sPreviousPage)
  else 
    sPreviousPage = "TO GO BACK"
  end if 

  callToAction = m.top.findNode("callToAction")
  callToAction.text = sPreviousPage
End Function

Function onScreenFocusChange()
  if m.top.hasFocus() = true
    m.ChannelCategoryGrid.setFocus(true)
    if m.top.content <> invalid and m.top.content.getChildCount() > 0
      if shouldRefresh(m.top.content) = true  'cacheValidationMixin
        m.top.refreshChannel = true
      end if
    end if
  end if
End Function


Function onKeyEvent(key, press)
  if press = true
    if key = "back"
      return false
    end if
  end if
  return true
End Function

Function onLoadContent()
  if m.top.content <> invalid
    items = m.top.content
    m.contentLoadedAndFocused = false
    m.ChannelCategoryGrid.content = items
    if items <> invalid
      m.top.trackingPageInfo = createTrackingPageInfo(items)
    end if
  end if
End Function


Function onIsLoading()
  tubiLog("ChannelDetailScreen.onIsLoading")
  if m.top.isLoading = true
    m.ChannelCategoryGrid.visible = false
  else
    m.ChannelCategoryGrid.visible = true
  end if
End Function


Function onItemFocused()
  tubiLog("ChannelDetailScreen.onItemFocused")
  if m.top.content <> invalid
    item = m.ChannelCategoryGrid.itemFocused
    category = m.top.content
    content = category.getChild(item) 'contentNode
    m.top.backgroundUriList = [m.defaultBackgroundUri]

    if m.contentLoadedAndFocused = true
      '//Do not send out tracking when the grid is initially loaded. When an item 1st gain focus, this indicates that the grid was just loaded.
      ' Update the tracking info.
      trackingPageInfo = createTrackingPageInfo(category)
      m.top.trackingPageInfo = trackingPageInfo
      ' trigger navigate_within_page events in ContentController
      numColumns = m.ChannelCategoryGrid.numColumns
      col = 1 + (item MOD numColumns)
      row = 1 + (item \ numColumns)

      genericComponent = {
        generic_component_type: "UNKNOWN"
      }
     m.top.navigateWithinPageInfo = {
        pageOneof: m.Tracking.getAnalyticsPage(trackingPageInfo.pageType, trackingPageInfo.pageValues)
        componentOneof: m.Tracking.getAnalyticsComponent("generic_component", genericComponent)
        means_of_navigation: "BUTTON"  'MeansOfNavigation enum
        vertical_location: row '1 based index
        vertical_location_mode: "INDEX"  'LocationMode enum
        horizontal_location: col
        horizontal_location_mode: "INDEX"  'LocationMode enum
      }
    else
      m.contentLoadedAndFocused = true
    end if
  end if
End Function


Function onItemSelected()
  item = m.ChannelCategoryGrid.itemSelected
  category = m.top.content
  content = category.getChild(item)
  ' Update the tracking info so that it is ready once the ContentController creates the details page
  m.top.trackingPageInfo = createTrackingPageInfo(category)

  numColumns = m.ChannelCategoryGrid.numColumns
  col = 1 + (item MOD numColumns)
  row = 1 + (item \ numColumns)
  'Set the tracking component of the item that was selected so it can be accessed as part of the navigateToPage event
  m.top.trackingComponentInfo = {
    componentType: "generic_component"
    componentValues: {
      generic_component_type: "UNKNOWN"
    }
  }
  m.contentLoadedAndFocused = false
  ' Pass info to ContentController
  m.top.contentSelected = content
End Function

'@channel: roSGNode, a content node for a single channel
'
'returns an AA with tracking info formatted for use by ScreenStack.screenTrackingLoad()
Function createTrackingPageInfo(channel)
  ' slug = ""
  ' if channel <> invalid
  '   slug = channel.slug
  ' end if

  trackingInfo = {
    pageType: "category_list_page"
    pageValues: {
    }
  }

  return trackingInfo
End Function

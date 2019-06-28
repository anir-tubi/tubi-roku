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
  m.NavSection = m.top.findNode("nav")

  m.top.observeField("callingPage", "onSetCallOfAction")
  m.top.observeField("shouldLoadContent", "onLoadContent")
  m.top.observeField("isLoading", "onIsLoading")
  m.top.observeField("focusedChild", "onScreenFocusChange")
  m.top.observeField("enabled", "onEnableChange")

  m.ChannelCategoryGrid.observeField("itemFocused", "onItemFocused")
  m.ChannelCategoryGrid.observeField("itemSelected", "onItemSelected")

  m.top.screenLevel = m.constants.ui.screenLevels.channelCategoryGridScreen
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

Function onEnableChange()
  if m.top.enabled = true
    fade(m.NavSection, "in", 0.3)
  else
    fade(m.NavSection, "out", 0.3)
  end if
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

Function onLoadContent()
  if m.top.content <> invalid
    items = m.top.content
    m.contentLoadedAndFocused = false
    m.ChannelCategoryGrid.content = items
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
    numColumns = m.ChannelCategoryGrid.numColumns
    category = m.top.content.getChild(item)
    m.top.backgroundUriList = [m.defaultBackgroundUri]

    if m.contentLoadedAndFocused = true
      ' Do not send out tracking when the grid is initially loaded. When an item 1st gain focus, this indicates that the grid was just loaded.
      ' trigger navigate_within_page events in ContentController
      col = 1 + (item MOD numColumns)
      row = 1 + (item \ numColumns)

      m.top.navigateWithinPageInfo = {
        pageOneof: m.Tracking.getAnalyticsPage(m.top.trackingPageInfo.pageType, m.top.trackingPageInfo.pageValues)
        componentOneof: m.Tracking.getAnalyticsComponent("category_component", m.oldCategoryComponent)
        means_of_navigation: "BUTTON"  'MeansOfNavigation enum
        vertical_location: row '1 based index
        vertical_location_mode: "INDEX"  'LocationMode enum
        horizontal_location: col
        horizontal_location_mode: "INDEX"  'LocationMode enum
      }

      ' cateogory component is used even though this is not an actual category, it can be modeled as a category
      ' of categories or a category of channels
      m.oldCategoryComponent = getTrackingCategoryComponent(item, numColumns, category)
    else
      m.oldCategoryComponent = getTrackingCategoryComponent(item, numColumns, category)
    end if

    m.contentLoadedAndFocused = true
  end if
End Function


Function onItemSelected()
  item = m.ChannelCategoryGrid.itemSelected
  categoryItem = m.top.content.getChild(item)

  numColumns = m.ChannelCategoryGrid.numColumns
  'Set the tracking component of the item that was selected so it can be accessed as part of the navigateToPage event
  m.top.trackingComponentInfo = {
    componentType: "category_component"
    componentValues: getTrackingCategoryComponent(item, numColumns, categoryItem)
  }
  m.contentLoadedAndFocused = false
  ' Pass info to ContentController
  m.top.contentSelected = categoryItem
End Function


Function getTrackingCategoryComponent(item, numColumns, category)
  col = 1 + (item MOD numColumns)
  row = 1 + (item \ numColumns)

  slug = ""
  if category <> invalid
    slug = category.slug
  end if

  return {
    category_row: row
    category_col: col
    category_slug: slug
  }
End Function
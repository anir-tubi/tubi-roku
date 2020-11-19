Function init()
  m._ = rodash()
  '//This var is used to know when to send tracking info. Do not send focus tracking info when the grid is 1st loaded
  m.contentLoadedAndFocused = false
  m.constants = m.global.constants

  m.defaultBackgroundUri = m.constants.ui.uris.defaultBackground
  Request = TubiRequest(m.constants.settings.mode)
  Auth = TubiAuth(m.constants, Request)
  m.Tracking = TubiTracking(m.constants, Request, Auth)

  m.ChannelCategoryGrid = m.top.findNode("ChannelCategoryGrid")
  m.NavSection = m.top.findNode("nav")

  m.top.observeField("reloadUserCategoriesResponse", "onReloadUserCategoriesResponse")
  m.top.observeField("callingPage", "onSetCallOfAction")
  m.top.observeField("shouldLoadContent", "onLoadContent")
  m.top.observeField("isLoading", "onIsLoading")
  m.top.observeField("focusedChild", "onScreenFocusChange")
  m.top.observeField("enabled", "onEnableChange")

  m.ChannelCategoryGrid.observeField("itemFocused", "onItemFocused")
  m.ChannelCategoryGrid.observeField("itemSelected", "onItemSelected")

  if getExperimentResource("roku_metadata_align", "roku_metadata_align_experiment", false).is_top_aligned = false 
    m.ScreenNavigationHint = m.top.findNode("ScreenNavigationHint")
    m.ScreenNavigationHint.translation = [168,85]
  end if

  m.contentLoadedAndFocused = false
  m.top.screenLevel = m.constants.ui.screenLevels.channelCategoryGridScreen

  if m.constants.deviceInfo.scaledUi = true then
    m.ChannelCategoryGrid.focusBitmapUri = "pkg:/images/selector-hd.9.png"
  end if
  m.global.observeField("theme", "onThemeChange")

  m.ChannelCategoryGrid.focusBitmapBlendColor = m.global.theme.focused

  BackLabel = m.top.findNode("callToAction")
  if m.constants.deviceInfo.uiResolution <> "FHD"
    '//if the display is not 1080, then adjust the BackLabel to ensure proper vertical alignment 
    BackLabel.translation = [BackLabel.translation[0], BackLabel.translation[1] + 3]
  end if

End Function


Function onThemeChange()
  m.ChannelCategoryGrid.focusBitmapBlendColor = m.global.theme.focused
End Function


Function onReloadUserCategoriesResponse()
  handledRequest = m.top.reloadUserCategoriesResponse
  tubiLog("ChannelGridScreen.onReloadUserCategoriesResponse")
  if handledRequest.response <> invalid then
    bEmpty = true
    response = handledRequest.response
    if response.code >= 200 and response.code < 300 then
      '//this is a successful response
      newCategory = handledRequest.convertedMetadata
      if newCategory <> invalid and newCategory.getChildCount() > 0
        '//this category has content
        bEmpty = false
      end if 
    end if

    '//The ID of the category that was reported to have recently changed
    sChangedCategoryID = handledRequest.id
    checkForContentAndRefresh(bEmpty, sChangedCategoryID)
  end if
End Function


' checkForContentAndRefresh()
' @param bContentEmpty - Does the passed category have NO content?
' @param sCategoryID - The ID of the channel/category that is changing,
' 
' When the content of a channel/category is known to have changed outside of this file, then this function should be called
' to see if the content should be refreshed. If it should, then validUntil will be set to 0 so the next time this screen 
' is on screen, then the content will be reloaded.
Function checkForContentAndRefresh(bContentEmpty, sCategoryID)
  '//Go thru the content and see if category associated with sCategoryID should be hidden or not
  if m.top.content <> invalid
    bRefresh = true
    bCategoryDisplayingOnScreen = false
    for i = 0 to m.top.content.getChildCount() - 1
      category = m.top.content.getChild(i)
      sID = category.id

      if sID = sCategoryID
        bCategoryDisplayingOnScreen = true
        exit for
      end if
    end for

    if bCategoryDisplayingOnScreen = true and bContentEmpty = false
      '//no need to refresh the screen if the category is already displaying AND the category isn't empty
      bRefresh = false
    else if bCategoryDisplayingOnScreen = false and bContentEmpty = true 
      '//no need to refresh the screen if the empty category is already not displaying
      bRefresh = false
    end if

    if bRefresh = true
      m.top.content.validUntil = 0
    end if
  end if 
End Function


Function onSetCallOfAction()
  sPreviousPage = m.top.callingPage
  sCallToAction = ""
  if sPreviousPage <> invalid and Len(sPreviousPage) > 0
    if UCase(sPreviousPage) = UCase(m.constants.ui.terms.categories)
      sCallToAction = getTranslation("goBack_categories")
    else if UCase(sPreviousPage) = UCase(m.constants.ui.terms.channels)
      sCallToAction = getTranslation("goBack_channels")
    else if UCase(sPreviousPage) = UCase(m.constants.ui.terms.menu)
      sCallToAction = getTranslation("goBack_menu")
    end if
  end if
  if sCallToAction = ""
    sCallToAction = getTranslation("goBack_default")
  end if 

  callToAction = m.top.findNode("callToAction")
  callToAction.text = sCallToAction
End Function


Function onEnableChange()
  if m.top.enabled = true
    fade(m.NavSection, "in", 0.3)
  else
    fade(m.NavSection, "out", 0.3)
  end if
End Function


Function onScreenFocusChange()
  tubiLog("ChannelGridScreen.onScreenFocusChange")
  if m.top.hasFocus() = true
    m.ChannelCategoryGrid.setFocus(true)
    if m.top.content <> invalid and m.top.content.getChildCount() > 0
      if shouldRefresh(m.top.content) = true  'cacheValidationMixin
        m.top.refreshChannel = true
      end if
    end if
  else if m.top.isInFocusChain() = false
    m.contentLoadedAndFocused = false
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
  tubiLog("ChannelGridScreen.onItemFocused")
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
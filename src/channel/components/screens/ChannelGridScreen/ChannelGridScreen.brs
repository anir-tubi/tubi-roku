Function init()
  m._ = rodash()
  '//This var is used to know when to send tracking info. Do not send focus tracking info when the grid is 1st loaded
  m.contentLoadedAndFocused = false
  m.constants = getConstantsFromGlobal()

  m.defaultBackgroundUri = m.constants.ui.uris.defaultBackground
  Request = TubiRequest(m.constants.settings)
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

  m.top.screenLevel = m.constants.ui.screenLevels.channelCategoryGridScreen

  BackLabel = m.top.findNode("callToAction")
  if m.constants.deviceInfo.uiResolution <> "FHD"
    '//if the display is not 1080, then adjust the BackLabel to ensure proper vertical alignment
    BackLabel.translation = [BackLabel.translation[0], BackLabel.translation[1] + 3]
  end if

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
  onThemeChange()
End Function


Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.ChannelCategoryGrid.focusBitmapBlendColor = theme.focusedColor
  end if
End Function


Function onReloadUserCategoriesResponse()
  tubiLog("ChannelGridScreen.onReloadUserCategoriesResponse")
  newCategory = m.top.reloadUserCategoriesResponse

  if newCategory <> invalid
    bEmpty = true
    if newCategory.getChildCount() > 0
      '//this category has content
      bEmpty = false
    end if

    checkForContentAndRefresh(bEmpty, newCategory.id)
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
  tubiLog("ChannelGridScreen.checkForContentAndRefresh")
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

    if bCategoryDisplayingOnScreen = true AND bContentEmpty = false
      '//no need to refresh the screen if the category is already displaying AND the category isn't empty
      bRefresh = false
    else if bCategoryDisplayingOnScreen = false AND bContentEmpty = true
      '//no need to refresh the screen if the empty category is already not displaying
      bRefresh = false
    end if

    if bRefresh = true
      m.top.content.validUntil = 0
    end if
  end if
End Function


Function onSetCallOfAction()
  tubiLog("ChannelGridScreen.onSetCallOfAction")
  sPreviousPage = m.top.callingPage
  sCallToAction = ""
  if sPreviousPage <> invalid AND Len(sPreviousPage) > 0
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
  tubiLog("ChannelGridScreen.onEnableChange")
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
    if m.top.content <> invalid AND m.top.content.getChildCount() > 0
      if shouldRefresh(m.top.content) = true  'cacheValidationMixin
        m.top.refreshChannel = true
      end if
    end if
  else if m.top.isInFocusChain() = false
    m.contentLoadedAndFocused = false
  end if
End Function


Function onLoadContent()
  tubiLog("ChannelGridScreen.onLoadContent")
  if m.top.content <> invalid
    items = m.top.content
    m.contentLoadedAndFocused = false
    m.ChannelCategoryGrid.content = items
    jumpToItemById()
  end if
End Function


Function onIsLoading()
  tubiLog("ChannelGridScreen.onIsLoading")
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
    m.top.itemFocused = item

    reportVisibleItems()

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

      ' category component is used even though this is not an actual category, it can be modeled as a category
      ' of categories or a category of channels
      m.oldCategoryComponent = getTrackingCategoryComponent(item, numColumns, category)
    else
      m.oldCategoryComponent = getTrackingCategoryComponent(item, numColumns, category)
    end if

    m.contentLoadedAndFocused = true
  end if
End Function


Function reportVisibleItems()
  '//When a sponsored container is made visible, then call the pixels
  if m.top.content <> invalid AND m.top.content.getChildCount() > 0
    itemFocused = m.ChannelCategoryGrid.itemFocused
    nVisibleNumColumns = m.ChannelCategoryGrid.numColumns
    nVisibleNumRows = m.ChannelCategoryGrid.numRows - 1
    rowFocused = Int(itemFocused \ nVisibleNumColumns) '//zero based
    lowestVisibleItem = rowFocused * nVisibleNumColumns
    highestVisibleItem = (rowFocused + nVisibleNumRows) * nVisibleNumColumns - 1
    if (m.top.content.getChildCount() - 1) < highestVisibleItem
      highestVisibleItem = m.top.content.getChildCount() - 1
    end if

    aVisibleItems = []
    '//Using "visibleItems", indicate what items are visible.
    '//This assumes that the focused item is in the top most visible row
    for i=lowestVisibleItem to highestVisibleItem
      '//for loop to go thru the visible items
      item = m.top.content.getChild(i)
      aVisibleItems.push(item)
    end for
    m.top.visibleItems = aVisibleItems
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


Function jumpToItemById()
  tubilog("ChannelGridScreen.onJumpToItem")
  sCategoryID = m.top.jumpToItemByID
  nodeHelpers = TubiNodeHelpers()
  content = m.top.content

  if content <> invalid AND sCategoryID <> ""
    index = nodeHelpers.getChildIndexById(content, sCategoryID)
    if index <> -1
      m.ChannelCategoryGrid.jumpToItem = index
    end if
    m.top.jumpToItemByID = ""
  end if

End Function

Function init()
  m._ = rodash()
  '//This var is used to know when to send tracking info. Do not send focus tracking info when the grid is 1st loaded
  m.contentLoadedAndFocused = false
  m.constants = m.global.constants
  m.defaultBackgroundUri = m.constants.ui.uris.defaultBackground

  Request = TubiRequest()
  Auth = TubiAuth(m.constants, Request)
  m.Tracking = TubiTracking(m.constants, Request, Auth)

  m.InfoPanel = m.top.findNode("ChannelsInfoPanel")
  m.PageTitle = m.top.findNode("pageTitle")
  m.VideoGrid = m.top.findNode("ChannelsVideoGrid")
  m.NavSection = m.top.findNode("nav")

  m.top.observeField("callingPage", "onSetCallOfAction")
  m.top.observeField("shouldLoadContent", "onLoadContent")
  m.top.observeField("isLoading", "onIsLoading")
  m.top.observeField("focusedChild", "onScreenFocusChange")
  m.top.observeField("enabled", "onEnableChange")
  m.VideoGrid.observeField("itemFocused", "onItemFocused")
  m.VideoGrid.observeField("itemSelected", "onItemSelected")

  ' set initial tracking values
  m.top.trackingPageInfo = createTrackingPageInfo(invalid)
  m.oldCategoryComponent = invalid

  if m.constants.deviceInfo.scaledUi = true then
    m.VideoGrid.focusBitmapUri = "pkg:/images/selector-hd.9.png"
  end if

  m.VideoGrid.focusBitmapBlendColor = m.global.theme.focused
  m.global.observeField("theme", "onThemeChange")

  m.top.screenLevel = m.constants.ui.screenLevels.channelDetailScreen
End Function

Function onThemeChange()
  m.VideoGrid.focusBitmapBlendColor = m.global.theme.focused
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
  if m.top.hasFocus() = true
    m.VideoGrid.setFocus(true)
    if m.top.content <> invalid
      if shouldRefresh(m.top.content.getChild(0)) = true  'cacheValidationMixin
        m.top.refreshChannel = true
      end if
    end if
  end if
End Function

Function onLoadContent()
  if m.top.content <> invalid
    category = m.top.content.getChild(0)
    m.contentLoadedAndFocused = false
    if category.getChildCount() > 0
      m.PageTitle.text = category.title
      m.PageTitle.horizAlign = "left"
      m.PageTitle.wrap = false
      m.VideoGrid.content = category
      m.VideoGrid.visible = true
    end if
    
    if category <> invalid
      m.top.trackingPageInfo = createTrackingPageInfo(category)
    end if
  end if
End Function


Function onIsLoading()
  tubiLog("ChannelDetailScreen.onIsLoading")
  if m.top.isLoading = true
    m.InfoPanel.visible = false
    m.VideoGrid.visible = false
  else
    m.InfoPanel.visible = true
    m.VideoGrid.visible = true
  end if
End Function


Function onItemFocused()
  tubiLog("ChannelDetailScreen.onItemFocused")
  if m.top.content <> invalid
    item = m.VideoGrid.itemFocused
    category = m.top.content.getChild(0) 'contentNode
    content = category.getChild(item) 'contentNode
    numColumns = m.VideoGrid.numColumns

    if content <> invalid
      ' Update the info panel
      populateInfoPanel(m.InfoPanel, content, "item")


      ' Update the background image
      if type(content.backgrounds) = "roArray" and content.backgrounds.count() > 0
        m.top.backgroundUriList = content.backgrounds
      else
        m.top.backgroundUriList = [m.defaultBackgroundUri]
      end if
      if m.contentLoadedAndFocused = true
        '//Do not send out tracking when the grid is initially loaded. When an item 1st gain focus, this indocates that the grid was just loaded.
        ' Update the tracking info.
        trackingPageInfo = createTrackingPageInfo(category)
        m.top.trackingPageInfo = trackingPageInfo

        ' trigger navigate_within_page events in ContentController
        col = 1 + (item MOD numColumns)
        row = 1 + (item \ numColumns)

        m.top.navigateWithinPageInfo = {
          pageOneof: m.Tracking.getAnalyticsPage(trackingPageInfo.pageType, trackingPageInfo.pageValues)
          componentOneof: m.Tracking.getAnalyticsComponent("category_component", m.oldCategoryComponent)
          means_of_navigation: "BUTTON"  'MeansOfNavigation enum
          vertical_location: row '1 based index
          vertical_location_mode: "INDEX"  'LocationMode enum
          horizontal_location: col
          horizontal_location_mode: "INDEX"  'LocationMode enum
        }
        
        m.oldCategoryComponent = getTrackingComponentInfo(item, numColumns, category, m.Tracking)
      else
        m.contentLoadedAndFocused = true
        m.oldCategoryComponent = getTrackingComponentInfo(item, numColumns, category, m.Tracking)
      end if
    else
      '//if content is not valid, then we should refresh the screen. 
      '//Most likely what happened is that the content was modified while the screen is off screen: i.e. ContinuedWatching screen no lomnger has any content so refreshing the page will most likely result in a content error.
      m.top.refreshChannel = true
    end if
  end if
End Function


Function onItemSelected()
  item = m.VideoGrid.itemSelected
  category = m.top.content.getChild(0)
  content = category.getChild(item)

  ' Update the tracking info so that it is ready once the ContentController creates the details page
  m.top.trackingPageInfo = createTrackingPageInfo(category)

  categorySlug = ""
  if category <> invalid
    categorySlug = category.slug
  end if

  numColumns = m.VideoGrid.numColumns
  col = 1 + (item MOD numColumns)
  row = 1 + (item \ numColumns)
  'Set the tracking component of the item that was selected so it can be accessed as part of the navigateToPage event
  m.top.trackingComponentInfo = {
    componentType: "category_component"
    componentValues: {
      category_slug: categorySlug
      category_row: 1
      content_tile: m.Tracking.getAnalyticsTile(content, col, row)
    }
  }
  m.contentLoadedAndFocused = false
  ' Pass info to ContentController
  m.top.contentSelected = content
End Function


'@infoPanel: roSGNode, an InfoPanel component
'@content: roSGNode, a content node
Function populateInfoPanel(infoPanel, content, mode)
  infoPanel.mode = mode
  
  if content.title <> invalid
    infoPanel.title = content.title
  else
    infoPanel.title = ""
  end if

  if content.description <> invalid
    infoPanel.description = content.description
  else
    infoPanel.description = ""
  end if

  line1Data = {}
  if content.releaseDate <> invalid
    line1Data.releaseDate = content.releaseDate
  else
    line1Data.releaseDate = ""
  end if

  if content.length <> invalid
    line1Data.length = content.length
  else
    line1Data.length = 0
  end if

  if (content.hasSubtitles = true or not m._.empty(content.subtitleTracks)) = true
    line1Data.hasCC = true
  else
    line1Data.hasCC = false
  end if

  if content.rating <> invalid
    line1Data.rating = content.rating
  else
    line1Data.rating = 0
  end if

  if content.inlineLogoUri <> invalid
    line1Data.partnerLogoUri = content.inlineLogoUri
  else
    line1Data.partnerLogoUri = ""
  end if
  infoPanel.lineOneData = line1Data

  if content.genres <> invalid
    infoPanel.genres = content.genres
  else
    infoPanel.genres = []
  end if

  if content.totalCount <> invalid and content.totalCount >= 0
    infoPanel.categoryContentCount = content.totalCount
  else
    infoPanel.categoryContentCount = 0
  end if

  if content.logoUri <> invalid
    infoPanel.titleLogoUri = content.logoUri
  else
    infoPanel.titleLogoUri = ""
  end if

  infoPanel.calculateHeight = true

  return infoPanel
End Function


'@channel: roSGNode, a content node for a single channel
'
'returns an AA with tracking info formatted for use by ScreenStack.screenTrackingLoad()
Function createTrackingPageInfo(channel)
  slug = ""
  if channel <> invalid
    slug = channel.slug
  end if

  trackingInfo = {
    pageType: "category_page"
    pageValues: {
      category_slug: slug
    }
  }

  return trackingInfo
End Function


Function getTrackingComponentInfo(itemIndex, numColumns, category, trackingLib)
  if trackingLib <> invalid and category <> invalid
    column = 1 + (itemIndex MOD numColumns)
    row = 1 + (itemIndex \ numColumns)
    content = category.getChild(itemIndex)

    return {
      category_slug: category.slug
      category_row: row
      category_col: column
      content_tile: m.Tracking.getAnalyticsTile(content, column, row)
    }
  end if

  return invalid
End Function
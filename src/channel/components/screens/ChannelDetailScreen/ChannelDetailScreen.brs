Function init()
  m._ = rodash()
  '//This var is used to know when to send tracking info. Do not send focus tracking info when the grid is 1st loaded
  m.contentLoadedAndFocused = false
  m.constants = m.global.constants
  m.defaultBackgroundUri = m.constants.ui.uris.defaultBackground

  Request = TubiRequest(m.constants.settings)
  Auth = TubiAuth(m.constants, Request)
  m.Tracking = TubiTracking(m.constants, Request, Auth)

  m.InfoPanel = m.top.findNode("ChannelsInfoPanel")
  m.PageTitleAndCounter = m.top.findNode("pageTitleAndCounter")
  m.VideoGrid = m.top.findNode("ChannelsVideoGrid")
  m.NavSection = m.top.findNode("nav")
  posterSize = m.constants.ui.imageSizes.poster
  if getExperimentResource("roku_safe_zone", "roku_safe_zone_restart_v2", false).enabled = true
    m.InfoPanel.translation = [192,133]
    m.PageTitleAndCounter.translation = [192,540]
    m.VideoGrid.translation = [192,600]
    m.VideoGrid.itemSpacing = [20,12]
    posterSize = m.constants.ui.safezoneImageSizes.poster
    m.NavSection.findNode("ScreenNavigationHint").translation = [192,55]
    m.top.findNode("leftChevron").translation = [90,528]
  end if

  m.top.observeField("callingPage", "onSetCallOfAction")
  m.top.observeField("shouldLoadContent", "onLoadContent")
  m.top.observeField("isLoading", "onIsLoading")
  m.top.observeField("focusedChild", "onScreenFocusChange")
  m.top.observeField("enabled", "onEnableChange")
  m.top.observeField("transportVoiceRequest", "onTransportVoiceRequest")
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

  BackLabel = m.top.findNode("callToAction")
  if m.constants.deviceInfo.uiResolution <> "FHD"
    '//if the display is not 1080, then adjust the BackLabel to ensure proper vertical alignment 
    BackLabel.translation = [BackLabel.translation[0], BackLabel.translation[1] + 3]
  end if

  m.top.screenLevel = m.constants.ui.screenLevels.channelDetailScreen
  m.top.handlesTransportVoiceRequests = true
  
  m.bLeftButtonActsLikeBackButton = true
  m.VideoGrid.itemSize = posterSize 
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
    else if UCase(sPreviousPage) = UCase(m.constants.ui.terms.home)
      sCallToAction = getTranslation("goBack_home")  
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
    if m.top.content <> invalid
      if m.top.content.getChild(0).getChildCount() > 0
        m.VideoGrid.setFocus(true)
      end if
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
      m.PageTitleAndCounter.content = category
      m.VideoGrid.content = category
      m.VideoGrid.setFocus(true)
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
    m.PageTitleAndCounter.visible = false
  else
    m.InfoPanel.visible = true
    m.VideoGrid.visible = true
    m.PageTitleAndCounter.visible = true
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
      populateInfoPanel(m.InfoPanel, content, m.constants.ui.infoPanelModes.item)

      m.PageTitleAndCounter.currentIndex = item

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


Function onItemSelected(msg)
  itemSelected = msg.getData()
  handleItemSelected(itemSelected)
End Function


' @itemSelected: integer, the position in the grid
Function handleItemSelected(itemSelected)
  category = m.top.content.getChild(0)
  content = category.getChild(itemSelected)

  ' Update the tracking info so that it is ready once the ContentController creates the details page
  updateTrackingInfo(category, content, itemSelected)

  ' Pass info to ContentController
  m.top.contentSelected = content
End Function


' @category: roSGNode, contentNode containing info about the category represented on the page
' @content: roSGNode, contentNode containing info about the content that was selected from the grid
' @itemSelected: integer, the position in the grid
Function updateTrackingInfo(category, content, itemSelected)
  m.top.trackingPageInfo = createTrackingPageInfo(category)

  categorySlug = ""
  if category <> invalid
    categorySlug = category.slug
  end if

  numColumns = m.VideoGrid.numColumns
  col = 1 + (itemSelected MOD numColumns)
  row = 1 + (itemSelected \ numColumns)
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
  if content.type = m.constants.ui.contentTypes.series
    line1Data.type = m.constants.ui.contentTypes.series  
    ' line1Data.seasons =  '//If available, get the number of seasons and set the value here
  end if
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
  if content.availabilityEnds <> invalid
    line1Data.availabilityEnds = content.availabilityEnds
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


Function onKeyEvent(key, press) as Boolean
  handled = false

  if press = true
    if key = "left"
      if m.bLeftButtonActsLikeBackButton = true
        m.top.backButtonPressed = true
        handled = true
      end if
    else if key = "play"
      handlePlayInput()
      handled = true
    end if
  else
    if key = "back"
      authInfo = m.global.authInfo
      ' show SignInRequired modal when guest user presses back from ActivationCode Screen to ChannelDetailScreen
      if authInfo = invalid
        m.top.signInRequired = true
        handled = true
      end if
    end if
  end if
  
  return handled
End Function


Function onTransportVoiceRequest(msg)
  response = "unhandled"
  inputInfo = msg.getData()
  command = ""
  if inputInfo <> invalid and inputInfo.command <> invalid
    command = inputInfo.command
  end if
  tubiLog("ChannelDetailScreen.onTransportVoiceRequest " + command)

  if m.VideoGrid.isInFocusChain() = true
    if command = "play"
      handlePlayInput()
      response = "success"
    else if command = "ok"
      handleItemSelected(m.VideoGrid.itemFocused)
      response = "success"
    end if
  end if

  inputInfo.response = response
  m.top.transportVoiceResponse = inputInfo
End Function


Function handlePlayInput()
  if m.VideoGrid.isInFocusChain() = true
    category = m.top.content.getChild(0)
    selectedContent = category.getChild(m.VideoGrid.itemFocused)
    updateTrackingInfo(category, selectedContent, m.VideoGrid.itemFocused)
    m.top.contentToPlay = selectedContent
  end if
End Function
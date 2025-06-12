Function init()
  '//This var is used to know when to send tracking info. Do not send focus tracking info when the grid is 1st loaded
  m.contentLoadedAndFocused = false
  m.constants = getConstantsFromGlobal()

  m.Tracking = TubiTrackingInfo(m.constants)

  '//if there is a sponsorship, then this will be changed to the number of pixels that some UI assets and the slide animation need to be adjusted vertically.
  m.nSponsorshipYDelta = 0

  '//The number of whole items visible on the screen
  m.itemsInRowCount = 4

  m.upperRowIndex = Int(m.constants.performance.categoryGridList.lazyLoadBatchSize / m.itemsInRowCount) ' items per row = 8 * 6 = 48
  m.lowerRowIndex = 0
  m.numRowsInBatch = Int(m.constants.performance.categoryGridList.lazyLoadBatchSize / m.itemsInRowCount)

  m.PageAnimatedGroup = m.top.findNode("PageAnimatedGroup")
  m.spinner = m.top.findNode("ChannelDetailSpinner")
  m.InfoPanel = m.top.findNode("ChannelsInfoPanel")
  m.PageTitleAndCounter = m.top.findNode("pageTitleAndCounter")
  m.ContentGrid = m.top.findNode("ChannelsContentGrid")
  m.ContentGrid.itemSize = m.constants.ui.imageSizes.largePoster

  m.top.observeFieldScoped("shouldLoadContent", "onLoadContent")
  m.top.observeFieldScoped("isLoading", "onIsLoading")
  m.top.observeFieldScoped("focusedChild", "onScreenFocusChange")
  m.top.observeFieldScoped("width", "onWidthChange")
  m.top.observeFieldScoped("height", "onHeightChange")
  m.top.observeFieldScoped("transportVoiceRequest", "onTransportVoiceRequest")
  m.top.observeFieldScoped("checkOnRefreshed", "onCheckOnRefreshTriggerred")
  m.ContentGrid.observeFieldScoped("itemFocused", "onItemFocused")
  m.ContentGrid.observeFieldScoped("itemSelected", "onItemSelected")

  ' set initial tracking values
  m.top.trackingPageInfo = createTrackingPageInfo(invalid)
  m.oldCategoryComponent = invalid

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
    m.ContentGrid.focusBitmapBlendColor = theme.focusedColor
  end if
End Function


Function onWidthChange(msg)
  m.spinner.width = msg.getData()
End Function


Function onHeightChange(msg)
  m.spinner.height = msg.getData()
End Function


Function checkOnRefresh()
  if m.top.content <> invalid AND m.top.content.getChildCount() > 0
    if shouldRefresh(m.top.content) = true 'cacheValidationMixin
      '//indicate that when the content is refreshed, it should attempt to focus close to where it was previously focused on.
      m.top.jumpToItemFocused = m.ContentGrid.itemFocused
      ' CategoryDetailPage lazy loads more than 200+ titles.  If user revisits categoryDetailPage from title detail page and content needs to be refreshed, then
      ' reset the lazy loading logic along with refreshed conent so that user can use lazy loading feature.
      ' TODO: Implement the logic to focus nJumpToItemFocused exactly.
      m.upperRowIndex = Int(m.constants.performance.categoryGridList.lazyLoadBatchSize / m.itemsInRowCount) ' items per row = 8 * 6 = 48
      m.lowerRowIndex = 0
      m.top.categoryBatchIndex = 0
    end if
  end if
End Function


Function onCheckOnRefreshTriggerred()
  tubiLog("CategoryDetailsPanel.onCheckOnRefreshTriggerred")
  checkOnRefresh()
End Function


Function onScreenFocusChange()
  tubiLog("CategoryDetailsPanel.onScreenFocusChange")
  setUIBasedOnFocus()
End Function


Function setUIBasedOnFocus(bAnimateOn = true)
  tubiLog("CategoryDetailsPanel.setUIBasedOnFocus")
  nAnimateTime = .5
  if m.top.shouldAnimateOnFocus = false OR bAnimateOn = false
    nAnimateTime = 0
  end if

  if m.top.hasFocus() = true
    if m.top.isLoading = true
      '//Since the content is still loading and there is nothing to focus on,
      '//then have the focus return to the left panel
      m.top.backButtonPressed = true
    else if m.top.content <> invalid
      if m.top.content.getChildCount() > 0
        m.ContentGrid.setFocus(true)
        '//Animate panel so infoPanel is visible
        slideTo(m.PageAnimatedGroup, [0, -m.nSponsorshipYDelta], nAnimateTime)
        fade(m.InfoPanel, "in", nAnimateTime)
      end if

      checkOnRefresh()
    end if
  else if m.top.isInFocusChain() = false
    '//Animate panel so infoPanel is no longer visible
    slideTo(m.PageAnimatedGroup, [0, -375], nAnimateTime)
    fade(m.InfoPanel, "out", nAnimateTime)
    m.top.backgroundUriList = []
  end if

  m.top.contentGridHasFocus = (m.ContentGrid.isInFocusChain() = true)
End Function


Function onLoadContent()
  tubiLog("CategoryDetailsPanel.onLoadContent")
  category = m.top.content
  if category <> invalid
    m.contentLoadedAndFocused = false
    if category.getChildCount() > 0
      m.nSponsorshipYDelta = 0
      if category.sponsorImages <> invalid
        m.nSponsorshipYDelta = -45
        m.PageTitleAndCounter.translation = [m.PageTitleAndCounter.translation[0], m.PageTitleAndCounter.translation[1] + m.nSponsorshipYDelta]
        m.InfoPanel.translation = [m.InfoPanel.translation[0], m.InfoPanel.translation[1] + m.nSponsorshipYDelta]
      end if

      m.PageTitleAndCounter.content = category
      m.ContentGrid.content = category

      nPopulateIndex = m.ContentGrid.itemFocused
      nJumpToItemFocused = m.top.jumpToItemFocused
      nContentMaxCount = category.getChildCount() - 1
      if nJumpToItemFocused >= 0
        if nJumpToItemFocused > nContentMaxCount
          nJumpToItemFocused = nContentMaxCount
        end if
        nPopulateIndex = nJumpToItemFocused
        m.ContentGrid.jumpToItem = nJumpToItemFocused
      end if

      populateContent = category.getChild(nPopulateIndex) 'contentNode

      populateInfoPanel(m.InfoPanel, populateContent)
      m.ContentGrid.visible = true

      setUIBasedOnFocus(false)
    end if

    m.top.trackingPageInfo = createTrackingPageInfo(category)
  end if
End Function


Function onIsLoading(msg)
  tubiLog("CategoryDetailsPanel.onIsLoading")
  if msg.getData() = true
    m.top.backgroundUriList = []
    m.InfoPanel.visible = false
    m.ContentGrid.visible = false
    m.PageTitleAndCounter.visible = false
  else
    m.InfoPanel.visible = true
    m.ContentGrid.visible = true
    m.PageTitleAndCounter.visible = true
  end if
End Function


Function onItemFocused(msg)
  tubiLog("CategoryDetailsPanel.onItemFocused")
  if m.top.content <> invalid
    item = msg.getData()
    category = m.top.content 'contentNode
    content = category.getChild(item) 'contentNode

    if content <> invalid
      ' Update the info panel
      populateInfoPanel(m.InfoPanel, content)

      m.PageTitleAndCounter.currentIndex = item

      ' Update the background image
      if type(content.backgrounds) = "roArray" AND content.backgrounds.count() > 0
        m.top.backgroundUriList = content.backgrounds
      else
        m.top.backgroundUriList = []
      end if

      numColumns = m.ContentGrid.numColumns

      if m.contentLoadedAndFocused = true
        '//Do not send out tracking when the grid is initially loaded. When an item 1st gain focus, this indicates that the grid was just loaded.
        ' Update the tracking info.
        trackingPageInfo = createTrackingPageInfo(category)
        m.top.trackingPageInfo = trackingPageInfo

        ' trigger navigate_within_page events in ContentController
        col = 1 + (item MOD numColumns)
        row = 1 + (item \ numColumns)

        m.top.navigateWithinPageInfo = {
          pageOneof: m.Tracking.getAnalyticsPage(trackingPageInfo.pageType, trackingPageInfo.pageValues)
          componentOneof: m.Tracking.getAnalyticsComponent("category_component", m.oldCategoryComponent)
          means_of_navigation: "BUTTON" 'MeansOfNavigation enum
          vertical_location: row '1 based index
          horizontal_location: col
        }

        m.oldCategoryComponent = getTrackingComponentInfo(item, numColumns, category, m.Tracking)
        focusedContent = category.getChild(m.ContentGrid.itemFocused)
        updateTrackingInfo(category, focusedContent, m.ContentGrid.itemFocused)


        'lazy loading logic:
        ' start with fetching contents for row=0 to row= (total number per lazyload) / 8 contents per row (lowerRowIndex to upperRowIndex)
        '
        ' when user scrolls down to midway (say third row out of total 6 rows) , request next batch

        rowForNextCall = Int((m.lowerRowIndex + m.upperRowIndex) / 2)

        if row > rowForNextCall
          m.top.categoryBatchIndex = m.constants.performance.categoryGridList.lazyLoadBatchSize + m.top.categoryBatchIndex
          m.lowerRowIndex = m.upperRowIndex + 1
          m.upperRowIndex = m.upperRowIndex + m.numRowsInBatch
        end if

      else

        m.contentLoadedAndFocused = true
        m.oldCategoryComponent = getTrackingComponentInfo(item, numColumns, category, m.Tracking)
        focusedContent = category.getChild(m.ContentGrid.itemFocused)
        updateTrackingInfo(category, focusedContent, m.ContentGrid.itemFocused)

      end if
      m.top.itemFocused = item
      m.top.contentFocused = focusedContent
    else
      '//if content is not valid, then we should refresh the screen.
      '//Most likely what happened is that the content was modified while the screen is off screen: i.e. ContinuedWatching screen no longer has any content so refreshing the page will most likely result in a content error.
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
  category = m.top.content
  content = category.getChild(itemSelected)

  if content <> invalid
    ' Update the tracking info so that it is ready once the ContentController creates the details page
    updateTrackingInfo(category, content, itemSelected)
    m.contentLoadedAndFocused = false

    ' Pass info to ContentController
    m.top.contentSelected = content
  end if
End Function


'@infoPanel: roSGNode, an InfoPanel component
'@content: roSGNode, a content node
Function populateInfoPanel(infoPanel, content)
  if content <> invalid
    if content.type = m.constants.ui.contentTypes.sportsEvent
      populateInfoPanelWithHomescreenStyleSportsMode(content, infoPanel)
    else if content.type = m.constants.ui.contentTypes.channel
      infoPanel.mode = m.constants.ui.infoPanelModes.channel
      infoPanel.title = content.title
      infoPanel.description = content.description
    else
      populateInfoPanelWithHomescreenStyleItemMode(content, infoPanel)
    end if

    infoPanel.calculateHeight = true
  end if
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
    pageType: "category_list_page"
    pageValues: {
      category_slug: slug
    }
  }

  if channel <> invalid
    trackingInfo.pageValues.personalization_id = channel.personalizationId
  end if

  return trackingInfo
End Function


Function getTrackingComponentInfo(itemIndex, numColumns, category, trackingLib)
  if trackingLib <> invalid AND category <> invalid
    column = 1 + (itemIndex MOD numColumns)
    row = 1 + (itemIndex \ numColumns)
    content = category.getChild(itemIndex)

    componentInfo = {
      category_slug: category.slug
      category_row: row
      category_col: column
    }

    if content.type  = m.constants.ui.contentTypes.channel
      componentInfo.utility_tile = m.Tracking.getUtilityTile(content, column, row)
    else
      componentInfo.content_tile = m.Tracking.getAnalyticsTile(content, column, row)
    end if

    return componentInfo
  end if

  return invalid
End Function


' @category: roSGNode, contentNode containing info about the category represented on the page
' @content: roSGNode, contentNode containing info about the content that was selected from the grid
' @itemSelected: integer, the position in the grid
Function updateTrackingInfo(category, content, itemSelected)
  if content <> invalid
    m.top.trackingPageInfo = createTrackingPageInfo(category)

    categorySlug = ""
    if category <> invalid
      categorySlug = category.slug
    end if

    numColumns = m.ContentGrid.numColumns
    col = 1 + (itemSelected MOD numColumns)
    row = 1 + (itemSelected \ numColumns)

    componentInfo = {
      category_slug: categorySlug
      category_row: row
      category_col: col
    }

    if content.type  = m.constants.ui.contentTypes.channel
      componentInfo.utility_tile = m.Tracking.getUtilityTile(content, col, row)
    else
      componentInfo.content_tile = m.Tracking.getAnalyticsTile(content, col, row)
    end if
    
    'Set the tracking component of the item that was selected so it can be accessed as part of the navigateToPage event
    m.top.trackingComponentInfo = {
      componentType: "category_component"
      componentValues: componentInfo
    }
  end if
End Function


Function onKeyEvent(key, press) as Boolean
  if press = true AND key = "play"
    handlePlayInput()
    return true
  end if

  return false
End Function


Function onTransportVoiceRequest(msg)
  response = "unhandled"
  inputInfo = msg.getData()
  command = ""
  if inputInfo <> invalid AND inputInfo.command <> invalid
    command = inputInfo.command
  end if
  tubiLog("CategoryDetailsPanel.onTransportVoiceRequest " + command)

  if m.ContentGrid.isInFocusChain() = true
    if command = "play"
      handlePlayInput()
      response = "success"
    else if command = "ok"
      handleItemSelected(m.ContentGrid.itemFocused)
      response = "success"
    end if
  end if

  inputInfo.response = response
  m.top.transportVoiceResponse = inputInfo
End Function


Function handlePlayInput()
  if m.ContentGrid.isInFocusChain() = true
    category = m.top.content
    selectedContent = category.getChild(m.ContentGrid.itemFocused)
    updateTrackingInfo(category, selectedContent, m.ContentGrid.itemFocused)
    m.contentLoadedAndFocused = false
    m.top.contentToPlay = selectedContent
  end if
End Function

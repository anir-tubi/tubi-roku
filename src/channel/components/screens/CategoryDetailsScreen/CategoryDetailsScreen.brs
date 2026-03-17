Function init()
  m._ = rodash()
  '//This var is used to know when to send tracking info. Do not send focus tracking info when the grid is 1st loaded
  m.contentLoadedAndFocused = false
  m.constants = getConstantsFromGlobal()

  m.auth = TubiAuth(m.constants)
  m.Tracking = TubiTracking(m.constants, m.auth)
  experimentsInfo = getExperimentsInfoFromGlobal()
  m.experiments = TubiExperiments(experimentsInfo)
  soTStaticConfig = getSoTStaticConfigFromGlobal()
  statSigExperimentsInfo = getStatsigExperimentsInfoFromGlobal()
  m.metadataTranslate = TubiMetadataTranslate(m.constants, m.experiments, soTStaticConfig, StatsigExperimentsInterface(statSigExperimentsInfo))

  m.itemsInRowCount = 8

  m.upperRowIndex = Int(m.constants.performance.categoryGridList.lazyLoadBatchSize / m.itemsInRowCount) ' items per row = 8 * 6 = 48
  m.lowerRowIndex = 0
  m.numRowsInBatch = Int(m.constants.performance.categoryGridList.lazyLoadBatchSize / m.itemsInRowCount)

  m.PageGroup = m.top.findNode("PageGroup")
  m.PageGroup.translation = [m.constants.ui.translations.marginX, 0]
  m.InfoPanel = m.top.findNode("ChannelsInfoPanel")
  m.PageTitleAndCounter = m.top.findNode("pageTitleAndCounter")
  m.VideoGrid = m.top.findNode("ChannelsVideoGrid")
  m.VideoGrid.itemSize = m.constants.ui.imageSizes.largePoster

  m.top.observeField("shouldLoadContent", "onLoadContent")
  m.top.observeField("isLoading", "onIsLoading")
  m.top.observeField("focusedChild", "onScreenFocusChange")
  m.top.observeField("transportVoiceRequest", "onTransportVoiceRequest")
  m.VideoGrid.observeField("itemFocused", "onItemFocused")
  m.VideoGrid.observeField("itemSelected", "onItemSelected")

  ' set initial tracking values
  m.top.trackingPageInfo = createTrackingPageInfo(invalid)
  m.oldCategoryComponent = invalid

  m.top.instantResumeAction = m.constants.instantResumeActions.startChannel

  m.top.screenLevel = m.constants.ui.screenLevels.categoryDetailsScreen
  m.top.handlesTransportVoiceRequests = true

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
    m.VideoGrid.focusBitmapBlendColor = theme.focusedColor
  end if
End Function


Function onScreenFocusChange()

  if m.top.hasFocus() = true
    if m.top.content <> invalid
      if m.top.content.getChildCount() > 0
        m.VideoGrid.setFocus(true)
      end if
      if shouldRefresh(m.top.content) = true 'cacheValidationMixin
        '//indicate that when the content is refreshed, it should attempt to focus close to where it was previously focused on.
        m.top.jumpToItemFocused = m.VideoGrid.itemFocused
        ' CategoryDetailPage lazy loads more than 200+ titles.  If user revisits categoryDetailPage from title detail page and content needs to be refreshed, then
        ' reset the lazy loading logic along with refreshed content so that user can use lazy loading feature.
        ' TODO: Implement the logic to focus nJumpToItemFocused exactly.
        m.upperRowIndex = Int(m.constants.performance.categoryGridList.lazyLoadBatchSize / m.itemsInRowCount) ' items per row = 8 * 6 = 48
        m.lowerRowIndex = 0
        m.top.categoryBatchIndex = 0
      end if
    end if
  end if

End Function


Function onLoadContent()
  tubiLog("CategoryDetailsScreen.onLoadContent")
  if m.top.content <> invalid
    category = m.top.content
    m.contentLoadedAndFocused = false
    if category.getChildCount() > 0
      if category.sponsorImages <> invalid
        m.PageTitleAndCounter.translation = [m.PageTitleAndCounter.translation[0], 518]
        m.VideoGrid.translation = [m.VideoGrid.translation[0], 627]
      end if

      m.PageTitleAndCounter.content = category
      m.VideoGrid.content = category

      m.VideoGrid.setFocus(true)

      nJumpToItemFocused = m.top.jumpToItemFocused
      nContentMaxCount = category.getChildCount() - 1
      if nJumpToItemFocused >= 0
        if nJumpToItemFocused > nContentMaxCount
          nJumpToItemFocused = nContentMaxCount
        end if
        m.VideoGrid.jumpToItem = nJumpToItemFocused
      end if

      m.VideoGrid.visible = true
    end if

    if category <> invalid
      m.top.trackingPageInfo = createTrackingPageInfo(category)
    end if
  end if
End Function


Function onIsLoading()
  tubiLog("CategoryDetailsScreen.onIsLoading")
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


Function onItemFocused(_msg)
  tubiLog("CategoryDetailsScreen.onItemFocused")
  if m.top.content <> invalid
    item = m.VideoGrid.itemFocused
    category = m.top.content 'contentNode
    content = category.getChild(item) 'contentNode

    if content <> invalid
      ' setting the focused content's Id to contentFocusedId field, later it will be used for setting focus on previous screen(home)
      m.top.contentFocusedId = content.id
      m.top.contentFocused = content

      ' Update the info panel
      populateInfoPanel(m.InfoPanel, content)

      ' Update the background image
      if type(content.backgrounds) = "roArray" AND content.backgrounds.count() > 0
        m.top.backgroundUriList = content.backgrounds
      else
        m.top.backgroundUriList = []
      end if

      numColumns = m.VideoGrid.numColumns

      if m.contentLoadedAndFocused = true
        '//Do not send out tracking when the grid is initially loaded. When an item 1st gain focus, this indicates that the grid was just loaded.
        ' Update the tracking info.
        trackingPageInfo = createTrackingPageInfo(category)
        m.top.trackingPageInfo = trackingPageInfo

        ' trigger navigate_within_page events in ContentController
        col = 1 + (item mod numColumns)
        row = 1 + (item \ numColumns)

        m.top.navigateWithinPageInfo = {
          pageOneof: m.Tracking.getAnalyticsPage(trackingPageInfo.pageType, trackingPageInfo.pageValues)
          componentOneof: m.Tracking.getAnalyticsComponent("category_component", m.oldCategoryComponent)
          means_of_navigation: "BUTTON" 'MeansOfNavigation enum
          vertical_location: row '1 based index
          horizontal_location: col
        }

        m.oldCategoryComponent = getTrackingComponentInfo(item, numColumns, category, m.Tracking)


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
      end if
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

    ' Pass info to ContentController
    m.top.contentSelected = content
  end if
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

    numColumns = m.VideoGrid.numColumns
    col = 1 + (itemSelected mod numColumns)
    row = 1 + (itemSelected \ numColumns)
    'Set the tracking component of the item that was selected so it can be accessed as part of the navigateToPage event
    m.top.trackingComponentInfo = {
      componentType: "category_component"
      componentValues: {
        category_slug: categorySlug
        category_row: 1
        category_col: 1
        content_tile: m.Tracking.getAnalyticsTile(content, col, row)
      }
    }
    m.contentLoadedAndFocused = false
  end if
End Function


'@infoPanel: roSGNode, an InfoPanel component
'@content: roSGNode, a content node
Function populateInfoPanel(infoPanel, content)
  if content.type = m.constants.ui.contentTypes.sportsEvent
    populateInfoPanelWithHomescreenStyleSportsMode(content, infoPanel)
  else
    populateInfoPanelWithHomescreenStyleItemMode(content, infoPanel)
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

  if channel <> invalid
    trackingInfo.pageValues.personalization_id = channel.personalizationId
  end if

  return trackingInfo
End Function


Function getTrackingComponentInfo(itemIndex, numColumns, category, trackingLib)
  if trackingLib <> invalid AND category <> invalid
    column = 1 + (itemIndex mod numColumns)
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
    if key = "left" OR key = "back"
      m.top.backButtonPressed = true
      handled = true
    else if key = "play"
      handlePlayInput()
      handled = true
    end if
  end if

  return handled
End Function


Function onTransportVoiceRequest(msg)
  response = "unhandled"
  inputInfo = msg.getData()
  command = ""
  if inputInfo <> invalid AND inputInfo.command <> invalid
    command = inputInfo.command
  end if
  tubiLog("CategoryDetailsScreen.onTransportVoiceRequest " + command)

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
    category = m.top.content
    selectedContent = category.getChild(m.VideoGrid.itemFocused)
    updateTrackingInfo(category, selectedContent, m.VideoGrid.itemFocused)
    m.top.contentToPlay = selectedContent
  end if
End Function

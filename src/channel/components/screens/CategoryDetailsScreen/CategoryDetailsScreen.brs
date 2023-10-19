Function init()
  m._ = rodash()
  '//This var is used to know when to send tracking info. Do not send focus tracking info when the grid is 1st loaded
  m.contentLoadedAndFocused = false
  m.constants = getConstantsFromGlobal()
  m.defaultBackgroundUri = m.constants.ui.uris.defaultBackground

  Request = TubiRequest(m.constants.settings)
  Auth = TubiAuth(m.constants, Request)
  m.Tracking = TubiTracking(m.constants, Request, Auth)
  m.experiments = TubiExperiments(m.constants)
  m.metadataTranslate = TubiMetadataTranslate(m.constants, m.experiments)

  itemsInRowCount = 8

  m.upperRowIndex = m.constants.performance.categoryGridList.lazyLoadBatchSize / itemsInRowCount ' items per row = 8 * 6 = 48
  m.lowerRowIndex = 0
  m.numRowsInBatch = m.constants.performance.categoryGridList.lazyLoadBatchSize / itemsInRowCount

  m.InfoPanel = m.top.findNode("ChannelsInfoPanel")
  m.PageTitleAndCounter = m.top.findNode("pageTitleAndCounter")
  m.VideoGrid = m.top.findNode("ChannelsVideoGrid")
  m.NavSection = m.top.findNode("nav")
  posterSize = m.constants.ui.imageSizes.poster
  if (getExperimentResource("roku_large_poster", "roku_large_poster_categories", false).enabled = true)
    '//::TODO:: roku_large_poster_categories - when graduating, remove the hardcoded properties in the XML associated with the following lines
    posterSize = m.constants.ui.imageSizes.largePoster
    m.VideoGrid.itemSpacing = [16,16]
    m.VideoGrid.numColumns = 6
  end if
  m.top.observeField("callingPage", "onSetCallOfAction")
  m.top.observeField("shouldLoadContent", "onLoadContent")
  m.top.observeField("isLoading", "onIsLoading")
  m.top.observeField("focusedChild", "onScreenFocusChange")
  m.top.observeField("enabled", "onEnableChange")
  m.top.observeField("transportVoiceRequest", "onTransportVoiceRequest")
  m.VideoGrid.observeField("itemFocused", "onItemFocused")
  m.VideoGrid.observeField("itemSelected", "onItemSelected")

  if getExperimentResource("roku_rounded_corners", "roku_rounded_corners_v1", false).enabled = true
    m.VideoGrid.focusBitmapUri="pkg:/images/selectorRoundedCorners-$$RES$$.9.png"
  end if

  ' set initial tracking values
  m.top.trackingPageInfo = createTrackingPageInfo(invalid)
  m.oldCategoryComponent = invalid

  m.top.instantResumeAction = m.constants.instantResumeActions.startChannel

  BackLabel = m.top.findNode("callToAction")
  if m.constants.deviceInfo.uiResolution <> "FHD"
    '//if the display is not 1080, then adjust the BackLabel to ensure proper vertical alignment
    BackLabel.translation = [BackLabel.translation[0], BackLabel.translation[1] + 3]
  end if

  m.top.screenLevel = m.constants.ui.screenLevels.categoryDetailsScreen
  m.top.handlesTransportVoiceRequests = true

  m.VideoGrid.itemSize = posterSize

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(BackLabel, typographyConstants.ids.bodySmall_strong)

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


Function onSetCallOfAction()
  sPreviousPage = m.top.callingPage
  sCallToAction = ""
  if sPreviousPage <> invalid AND Len(sPreviousPage) > 0
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
      if m.top.content.getChildCount() > 0
        m.VideoGrid.setFocus(true)
      end if
      if shouldRefresh(m.top.content) = true 'cacheValidationMixin
        '//indicate that when the content is refreshed, it should attempt to focus close to where it was previously focused on.
        m.top.jumpToItemFocused = m.VideoGrid.itemFocused
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
        '//check in photoshop and re-adjust postions
        m.PageTitleAndCounter.translation = [m.PageTitleAndCounter.translation[0], 518]
        m.VideoGrid.translation = [m.VideoGrid.translation[0], 627]

        '//if a channel is sponsored, then display a background artwork related to the sponsor
        sSponsorBackgroundURL = ""
        if m.constants.deviceInfo.limitedUi = false AND category.sponsorImages.brandBackground <> ""
          sSponsorBackgroundURL = category.sponsorImages.brandBackground
        else if category.sponsorImages.brandColor <> ""
          sSponsorBackgroundURL = category.sponsorImages.brandColor
        end if
        m.top.sponsorshipBackground = sSponsorBackgroundURL
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


Function onItemFocused(msg)
  tubiLog("CategoryDetailsScreen.onItemFocused")
  if m.top.content <> invalid
    item = m.VideoGrid.itemFocused
    category = m.top.content 'contentNode
    content = category.getChild(item) 'contentNode

    if content <> invalid
      ' setting the focused content's Id to contentFocusedId field, later it will be used for setting focus on previous screen(home)
      m.top.contentFocusedId = content.id

      ' Update the info panel
      populateInfoPanel(m.InfoPanel, content)

      m.PageTitleAndCounter.currentIndex = item

      ' Update the background image
      if type(content.backgrounds) = "roArray" AND content.backgrounds.count() > 0
        m.top.backgroundUriList = content.backgrounds
      else
        m.top.backgroundUriList = [m.defaultBackgroundUri]
      end if

      numColumns = m.VideoGrid.numColumns

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


        'lazy loading logic:
        ' start with fetching contents for row=0 to row= (total number per lazyload) / 8 contents per row (lowerRowIndex to upperRowIndex)
        '
        ' when user scrolls down to midway (say third row out of total 6 rows) , request next batch

        rowForNextCall = (m.lowerRowIndex + m.upperRowIndex) / 2

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
  end if
End Function


'@infoPanel: roSGNode, an InfoPanel component
'@content: roSGNode, a content node
Function populateInfoPanel(infoPanel, content)
  if content.type = m.constants.ui.contentTypes.sportsEvent
    populateInfoPanelWithHomescreenStyleSportsMode(content, infoPanel)
  else 'movies, series
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

  return trackingInfo
End Function


Function getTrackingComponentInfo(itemIndex, numColumns, category, trackingLib)
  if trackingLib <> invalid AND category <> invalid
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
    if key = "left" OR key = "back"
      m.top.backButtonPressed = true
      handled = true
    else if key = "play"
      handlePlayInput()
      handled = true
    end if
  else
    if key = "back"
      authInfo = m.global.authInfo
      ' show SignInRequired modal when guest user presses back from ActivationCodeScreen to CategoryDetailsScreen
      if authInfo = invalid OR (authInfo <> invalid AND authInfo.userId = invalid)
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

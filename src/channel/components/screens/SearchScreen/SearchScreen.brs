Function init()
  tubiLog("SearchScreen.init")
  m._ = rodash()
  m.constants = getConstantsFromGlobal()
  Request = TubiRequest(m.constants.settings)
  Auth = TubiAuth(m.constants, Request)
  m.Tracking = TubiTracking(m.constants, Request, Auth)

  m.ResultArea = m.top.findNode("ResultArea")

  ' Since we have 2 different markup grid inside the result area. When the user scroll downs to trending searches grid from results grid,
  ' we move the the container that holds the 2 grid upwards. We are adding clipping rect so that anything that is above the specified x and y everything else is clipped or hidden.
  ' This causes the results grid to be hidden and gives a effects as if the grid scrolled below the container.
  m.ResultArea.clippingRect = {
    height: 1080
    width: 1920
    x: -20
    y: 0
  }
  
  m.searchGroup = m.top.findNode("searchGroup")

  m.spinner = m.top.findNode("spinner")
  m.NavSection = m.top.findNode("nav")
  m.KidsModeMessage = m.top.findNode("KidsModeMessage")
  m.leftSide = m.top.findNode("leftSide")
  m.SearchText = m.top.findNode("SearchText")
  m.trendingSearchHeading = m.top.findNode("trendingSearchHeading")
  m.searchScreenInfoPanel = m.top.findNode("SearchScreenInfoPanel")

  m.voiceHintfont = CreateObject("roSGNode", "Font")

  m.searchMenuText = m.top.findNode("searchMenuText")
  m.searchHintText = m.top.findNode("searchHintText")

  m.keyboard = m.top.findNode("Keyboard")

  m.keyboard.id = "SearchKeyboard"
  m.keyboard.setFocus(true)
  m.keyboard.textEditBox.maxTextLength = 100

  m.keyboard.keyGrid.keyDefinitionUri = "pkg:/components/data/CustomAddressKDF.json"

  ' A value of zero or setting visible to false will cause voiceEnabled to not get updated properly when its state changed
  m.keyboard.textEditBox.opacity = 0.00001

  m.keyboard.textEditBox.observeFieldScoped("voiceEnabled", "onKeyboardTextEditBoxVoiceEnabledChange")
  onKeyboardTextEditBoxVoiceEnabledChange()

  ' searchDebounce timer helps to reduce number of search api requests
  m.searchDebounce = m.top.findNode("searchDebounce")
  m.searchDebounce.observeField("fire", "onSearchDebounce")

  setSearchStrings()

  m.KidsModeMessageSpacer = m.top.findNode("KidsModeMessageSpacer")

  m.ResultGrid = m.top.findNode("ResultGrid")
  m.keyboard.observeField("text", "onKeyboardTextChanged")
  m.keyboard.textEditBox.observeField("focusedChild", "onTextEditBoxFocused")

  m.ResultGrid.observeField("itemSelected", "onResultSelected")
  m.ResultGrid.observeField("itemFocused", "onItemFocused")
  m.ResultGrid.observeFieldScoped("currFocusRow", "onResultGridCurrFocusRowChange")

  m.searchResultsMessageContainer = m.top.findNode("searchResultsMessageContainer")
  m.noMatchingResultsMessage = m.top.findNode("noMatchingResultsMessage")
  m.trendingResultsHint = m.top.findNode("trendingResultsHint")
  m.trendingSearchResultGrid = m.top.findNode("trendingSearchResultGrid")
  m.trendingSearchResultsContainer = m.top.findNode("trendingSearchResultsContainer")
  m.trendingSearchResultGrid.observeFieldScoped("itemSelected", "onResultSelected")
  m.trendingSearchResultGrid.observeFieldScoped("itemFocused", "onItemFocused")

  m.trendingResultsHint.text = getTranslation("trending_search_results_hint")

  m.gridContainer = m.top.findNode("gridContainer")

  m.keyboard.palette = handleKeyboardColors()
  m.NoResultsMessage = m.top.findNode("NoResultsMessage")

  m.top.observeField("focusedChild", "onScreenFocusChange")
  m.top.observeField("signedIn", "onSignedInChange")
  m.top.observeField("visible", "onVisible")
  m.top.observeField("enabled", "onEnableChange")
  m.top.observeField("contentUpdated", "onSearchContentChange")
  m.top.observeField("transportVoiceRequest", "onTransportVoiceRequest")

  m.defaultHeroUri = "pkg:/images/art-blur-background.webp"

  m.top.backgroundUriList = [m.defaultHeroUri]

  'set initial tracking values
  m.top.trackingPageInfo = {
    pageType: "search_page"
    pageValues: {}
  }

  ' Used to determine if navigate_within_page events should be sent. Only send when the content grid already
  ' has focus, not when it gains focus.
  m.gridHasFocus = false
  ' Used to know if the grid was in focus especially when user returns from the detailed screen and we know to set the focus back to the results
  m.bResultsInFocus = false

  ' Holds the boolean true|false value which indicates if the trending search grid was in focus. 
  ' This is used so that we can set focus back to it if the user moved away from it to keyboard or details screen.
  m.isTrendingResultsGridInFocus = false

  ' Boolean flag which indicates if a search api request is in progress this is done to avoid user navigating to results grid to avoid focus issues.
  m.isSearchRequestInProgress = false

  m.top.screenLevel = m.constants.ui.screenLevels.searchScreen
  m.top.handlesTransportVoiceRequests = true
  loadSearchResults(true)'//load the default search results

  BackLabel = m.top.findNode("callToAction")
  if m.constants.deviceInfo.uiResolution <> "FHD"
    '//if the display is not 1080, then adjust the BackLabel to ensure proper vertical alignment
    BackLabel.translation = [BackLabel.translation[0], BackLabel.translation[1] + 3]
  end if

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(BackLabel, typographyConstants.ids.bodySmallStrong)
  setTypographyOfLabel(m.searchMenuText, typographyConstants.ids.headerSmall)
  setTypographyOfLabel(m.searchHintText, typographyConstants.ids.bodyMediumStrong)
  setTypographyOfLabel(m.KidsModeMessage, typographyConstants.ids.bodyMedium)
  setTypographyOfLabel(m.SearchText, typographyConstants.ids.subheaderMedium)
  setTypographyOfLabel(m.trendingSearchHeading, typographyConstants.ids.subheaderMedium)
  setTypographyOfLabel(m.NoResultsMessage, typographyConstants.ids.bodyMedium)

  setTypographyOfLabel(m.trendingResultsHint, typographyConstants.ids.bodyMedium)
  setTypographyOfLabel(m.noMatchingResultsMessage, typographyConstants.ids.bodyMedium)

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
    m.SearchText.color = theme.primaryTextColor
    m.trendingSearchHeading.color = theme.primaryTextColor
    m.KidsModeMessage.color = theme.secondaryTextColor
    m.searchMenuText.color = theme.primaryTextColor
    m.NoResultsMessage.color = theme.primaryTextColor
    m.ResultGrid.focusBitmapBlendColor = theme.focusedColor
    m.trendingSearchResultGrid.focusBitmapBlendColor = theme.focusedColor

    m.trendingResultsHint.color = theme.primaryTextColor
    m.noMatchingResultsMessage.color = theme.cautionColor

    m.keyboard.palette = handleKeyboardColors()
    if theme.id = m.constants.ui.themeIDs.kidsMode
      m.KidsModeMessage.visible = false
      m.KidsModeMessageSpacer.width = 1
    else
      m.KidsModeMessage.visible = true
      m.KidsModeMessageSpacer.width = 0
    end if
  end if
End Function


Function onKeyboardTextEditBoxVoiceEnabledChange()
  if m.keyboard.textEditBox.voiceEnabled = true then
    if m.microphone = invalid then
      setTextForVoiceHint()
    end if
    m.microphone.visible = true
  else if m.microphone <> invalid then
    m.microphone.visible = false
  end if
End Function


Function setTextForVoiceHint()
  m.microphone = m.searchGroup.createChild("Poster")
  m.microphone.uri = "pkg:/images/microphone.png"
  m.microphone.width = "36"
  m.microphone.height = "36"
  m.microphone.translation = [0, 0]
  m.voiceHint = m.microphone.createChild("Label")
  m.voiceHint.text = getTranslation("search_voice_hint")
  m.voiceHint.translation = [m.microphone.translation[0] + 60, m.microphone.translation[1] - 5]
  m.voiceHint.numLines = 2
  m.voiceHint.wrap = true
  m.voiceHint.width = 400
  m.voiceHintfont.size = 21
  m.voiceHint.font = m.voiceHintfont

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.voiceHint, typographyConstants.ids.bodySmall)
End Function


Function setSearchStrings()
  BackLabel = m.top.findNode("callToAction")
  BackLabel.text = getTranslation("goBack_menu")

  m.sDefaultSearchText = getTranslation("screenSearch_trendingSearch")
  m.searchTitleText = getTranslation("menu_search")
  m.searchHintToSearch = getTranslation("screenSearch_defaultLinearSearch")
  setDefaultText()
  m.searchText.text = ""
  m.trendingSearchHeading.text = m.sDefaultSearchText
  m.sDefaultKidsWarning = getTranslation("screenSearch_kidsWarning")
  m.KidsModeMessage.text = m.sDefaultKidsWarning
  m.spinner.text = getTranslation("screenSearch_loading")
End Function


'''''''''''''''''''''''''
' displayLoading
'
' Display the loading spinner and loading message based on search results loaded
Function displayLoading(b = true)
  m.isSearchRequestInProgress = (b = true)
  m.spinner.visible = b
End Function

Function onVisible()
  if m.top.visible = true
    if m.top.backgroundUriList.Count() = 0
      m.top.backgroundUriList = [m.defaultHeroUri]
    end if
  end if
End Function

'''''''''''''''''''''''''
' onScreenFocusChange
'
' On focus set to screen, push focus on keyboard or grid.
' This is used when the search screen regains focus after coming back from the details page.
Function onScreenFocusChange()
  if m.top.hasFocus() then
    if m.bResultsInFocus = true
      if m.isTrendingResultsGridInFocus = false AND m.ResultGrid.content <> invalid AND m.ResultGrid.content.getChildCount() > 0
        m.ResultGrid.setFocus(true)
      else
        m.trendingSearchResultGrid.setFocus(true)
      end if
      handleKeyboardVoiceInput(m.bResultsInFocus)
    else
      m.Keyboard.setFocus(true)
      handleKeyboardVoiceInput(m.bResultsInFocus)
    end if
  else if m.top.isInFocusChain() = false
    m.keyboard.textEditBox.voiceEnabled = false
  end if
End Function

Function onEnableChange()
  if m.top.enabled = true
    fade(m.NavSection, "in", 0.3)
  else
    fade(m.NavSection, "out", 0.3)
  end if
End Function


' This may filter results based on parental controls so send it again on auth change
Function onSignedInChange()
  tubiLog("SearchScreen.onSignedInChange")
  if m.Keyboard.text <> invalid AND m.Keyboard.text.len() > 0 then
    loadSearchResults()
  else
    loadSearchResults(true)
  end if
End Function


Function displayNoResults()
  m.ResultGrid.visible = false
  m.NoResultsMessage.visible = true
  m.NoResultsMessage.text = getTranslation("screenSearch_noResults", {term: m.top.searchText})
End Function


'''''''''''''''''''''''
' onResultSelected
'
' Handle content grid item selected
Function onResultSelected(msg)
  gridNode = msg.getRoSGNode()
  itemSelected = msg.getData()
  content = gridNode.content
  tubiLog("SearchScreen.onResultSelected")
  if content <> invalid
    selectedContent = content.getChild(itemSelected)
    if selectedContent <> invalid
      handleResultSelected(selectedContent, itemSelected)
    end if
  end if
End Function


' @content: roSGNode, ContentNode representing the content that was selected by the user
' @position: integer, the position within the search results grid
Function handleResultSelected(content, position)
  if content <> invalid
    updateTrackingInfo(content, position)
    m.top.contentSelected = content
    m.gridHasFocus = false
  end if
End Function


Function updateTrackingInfo(content, position)
  m.top.trackingComponentInfo = getTrackingComponentInfo(position, m.ResultGrid.numColumns, content, m.Tracking)

  if content <> invalid
    m.top.trackingPageInfo = {
      pageType: "search_page"
      pageValues: {
        query: Left(m.Keyboard.text, 256)
      }
    }
  end if
End Function


'''''''''''''''''''''''
' onSearchContentChange
'
' When the server returns with search content, this function will be called.
Function onSearchContentChange()
  displayLoading(false)
  m.ResultGrid.content = invalid '//reset content everytime so in case the new results = previous results, then the contemt can refresh. Without refreshing content, then the content may appear blank
  content = m.top.content

  if content <> invalid AND content.getChildCount() > 0
    if content.isDefaultSearchResults <> true
      m.ResultGrid.content = content
    else
      ' Setting it only if we received valid data from backend.
      m.trendingSearchResultGrid.content = content
    end if
  end if

  
  if content <> invalid AND content.getChildCount() > 0 then
    ' Resetting the values to default on every new search term to clear out previous navigation/scroll history.
    m.noMatchingResultsMessage.visible = false
    m.trendingResultsHint.visible = false
    m.trendingSearchResultsContainer.translation = [0, 0]
    m.ResultGrid.jumpToItem = 0
    m.trendingSearchResultGrid.jumpToItem = 0
    m.gridContainer.translation = [0, 0]
    m.isTrendingResultsGridInFocus = false

    if content.isDefaultSearchResults = true
      '//display special text when the default search is displaying
      setDefaultText()
      if m.microphone <> invalid
        m.microphone.visible = true
      end if
      m.searchText.text = ""
      m.trendingSearchResultsContainer.visible = true
      m.ResultGrid.visible = false
    else
      matchingText = getTranslation("screenSearch_matchingTitles")
      m.searchHintText.text = m.ResultGrid.content.getChildCount().toStr() + " " + matchingText + " " + Chr(34) + m.searchMenuText.text + Chr(34)
      m.SearchText.text = getTranslation("screenSearch_results")
      m.ResultGrid.visible = true

      trendingSearchContent = m.trendingSearchResultGrid.content
      ' Setting the visibility of trending searches if we have result.
      if trendingSearchContent <> invalid AND trendingSearchContent.getChildCount() > 0
        m.trendingResultsHint.visible = false
        if m.top.isUserEligibleForTrendingSearchBelowExperiment = true AND getExperimentResource("roku_trending_search_below", "roku_trending_search_below_v1", true).enabled = true
          m.trendingSearchResultsContainer.visible = true
          m.trendingResultsHint.visible = true
          if content.getChildCount() > 5
            m.trendingSearchResultsContainer.translation = [0, 672]
          else
            ' If the result count is less than or equal to 5. We will show the trending searches.
            m.trendingSearchResultsContainer.translation = [0, 372]
          end if
        else
          m.trendingSearchResultsContainer.visible = false
        end if
      else
        m.trendingSearchResultsContainer.visible = false
      end if

    end if

    m.NoResultsMessage.visible = false
  else
    ' If it is not kids mode and the user is in experiment display the trending search instead of no content message.
    if m.top.isUserEligibleForTrendingSearchBelowExperiment = true AND getExperimentResource("roku_trending_search_below", "roku_trending_search_below_v1", false).enabled = true
      m.ResultGrid.visible = false
      trendingSearchContent = m.trendingSearchResultGrid.content
      if trendingSearchContent <> invalid AND trendingSearchContent.getChildCount() > 0
        m.trendingSearchResultsContainer.visible = true
        m.trendingSearchResultsContainer.translation = [0, 0]
        m.trendingSearchResultGrid.jumpToItem = 0
        m.trendingResultsHint.visible = true
        m.noMatchingResultsMessage.visible = true
        if isNonEmptyString(m.Keyboard.text) = true
          m.noMatchingResultsMessage.text = getTranslation("search_results_no_matching_results") + " " + m.Keyboard.text
        end if
      end if
      m.searchHintText.text = ""
      m.SearchText.text = ""
    else
      displayNoResults()
    end if
  end if
End Function


Function onSearchDebounce()

  if m.Keyboard.text <> invalid AND m.Keyboard.text.trim().len() > 0 then
    loadSearchResults()
  else
    '//if the search text was empty, clear out any existing results and display the default search results
    loadSearchResults(true)
  end if

  m.top.trackingPageInfo = {
    pageType: "search_page"
    pageValues: {
      query: Left(m.Keyboard.text, 256)
    }
  }

End Function


''''''''''''''''''''''''''
' onKeyboardTextChanged
'
' Launch a search when the keyboard text has changed
Function onKeyboardTextChanged()
  tubiLog("SearchScreen.onKeyboardTextChanged " + m.Keyboard.text)

  '//display spinner
  displayLoading()
  '//hide previous content
  m.ResultGrid.visible = false
  m.NoResultsMessage.visible = false

  m.SearchText.text = ""
  m.searchHintText.text = ""
  m.KidsModeMessage.text = ""
  m.searchMenuText.text = LCase(m.Keyboard.text)

  ' making backend request only after 0.5s
  m.searchDebounce.control = "start"

End Function


'''''''''''''''''''''
' onItemFocused
'
' Update the info panel when a result item is focused
Function onItemFocused(msg)
  tubiLog("SearchScreen.onItemFocused")
  gridNode = msg.getRoSGNode()
  itemFocused = msg.getData()
  gridContent = gridNode.content
  if gridContent <> invalid
    focusedContent = gridContent.getChild(itemFocused)
    m.top.backgroundUriList = determineBackgroundImage(focusedContent)
    m.searchScreenInfoPanel.visible = true

    if m.microphone <> invalid
      m.microphone.visible = false
    end if

    setVisibilityForDefaultText(false)
    m.searchScreenInfoPanel.title = focusedContent.title
    m.searchScreenInfoPanel.description = focusedContent.DESCRIPTION

    if focusedContent.type = "linear"
      m.searchScreenInfoPanel.mode = m.constants.ui.infoPanelModes.linearSearch
      lineOneData = {}
      lineTwoData = {
        badgeText: getTranslation("screenSearch_liveText")
        genres: focusedContent.genres
      }
      m.searchScreenInfoPanel.needsLogin = focusedContent.needsLogin AND (m.top.signedIn <> true)
    else if focusedContent.type = m.constants.ui.contentTypes.sportsEvent
      m.searchScreenInfoPanel.mode = m.constants.ui.infoPanelModes.sportsEvent

      hasVideoresources = focusedContent.hasVideoresources
      airDatetime = focusedContent.airDatetime
      info = getAvailabilityTypeBadgeAndMatchTimeValues(airDatetime, hasVideoresources)
      badgeText = info.badgeText
      matchTime = info.matchTime

      lineOneData = {
        badgeText: badgeText
        hoursOfAiring: matchTime
        hasCC: (focusedContent.hasSubtitles = true OR m._.empty(focusedContent.subtitleTracks) = false)
        length: focusedContent.length
      }

      if focusedContent.highestRendition = m.constants.serverValues.tensorVideoRenditions.fourK
        lineOneData.has4k = true
      end if

      lineTwoData = {
        roundGroupInfo: focusedContent.roundGroupInfo
      }

      m.searchScreenInfoPanel.needsLogin = focusedContent.needsLogin AND (m.top.signedIn <> true)
    else
      m.searchScreenInfoPanel.mode = m.constants.ui.infoPanelModes.item
      lineOneData = {
        releasedate: focusedContent.releaseDate
        descriptorCode: UCase(focusedContent.descriptorCode)
        length: focusedContent.length
        hasCC: (focusedContent.hasSubtitles = true OR m._.empty(focusedContent.subtitleTracks) = false)
        rating: focusedContent.rating
        availabilityEnds: focusedContent.availabilityEnds
      }

      lineTwoData = {
        genres: focusedContent.genres
      }

      rating = UCase(focusedContent.rating)
      if (rating = "R" OR rating = "TV-MA" OR rating = "TV-14" OR rating = "NC-17" OR rating = "NR") AND m.constants.deviceinfo.countrycode = "US"  AND isLoggedInUser() = false
        getExperimentResource("roku_registration_vs_tvt_lock_rated_content", "roku_registration_vs_tvt_lock_rated_content_v1")
      end if

      m.searchScreenInfoPanel.needsLogin = (focusedContent.needsLogin AND m.top.signedIn <> true)
    end if

    ' description = m.searchScreenInfoPanel.findNode("Description")
    ' description.width = 960
    ' m.searchScreenInfoPanel.width = 960

    m.searchScreenInfoPanel.lineOneData = lineOneData
    m.searchScreenInfoPanel.lineTwoData = lineTwoData
    m.searchScreenInfoPanel.descriptionMaxLines = 2
    m.searchScreenInfoPanel.calculateHeight = true

    ' Set up the info that the ContentController uses to send navigate_within_page events.
    ' Don't change m.top.navigateWithinPageInfo if the focused content hasn't changed
    ' (protects against re-setting when the focus is set upon returning to search page from details page)
    if m.gridHasFocus = true AND itemFocused <> invalid

      searchComponent = invalid
      if gridNode.numColumns <> invalid
        searchComponent = getTrackingComponentInfo(itemFocused, gridNode.numColumns, focusedContent, m.Tracking)
      end if

      if searchComponent <> invalid
        navigateWithinPageInfo = {
          pageOneof: m.Tracking.getAnalyticsPage(m.top.trackingPageInfo.pageType, m.top.trackingPageInfo.pageValues)
          componentOneof: m.Tracking.getAnalyticsComponent(m.oldSearchComponent.componentType, m.oldSearchComponent.componentValues)
          means_of_navigation: "BUTTON" 'MeansOfNavigation enum
        }

        if searchComponent.componentValues <> invalid AND searchComponent.componentValues.content_tile <> invalid
          navigateWithinPageInfo.vertical_location = searchComponent.componentValues.content_tile.row
          navigateWithinPageInfo.horizontal_location = searchComponent.componentValues.content_tile.col
        end if

        m.top.navigateWithinPageInfo = navigateWithinPageInfo
        m.oldSearchComponent = searchComponent
      end if
    else if m.gridHasFocus = false AND itemFocused <> invalid
      'the search grid is gaining focus, so we don't send navigate_within_page events at this time. Instead we just cache information
      'for the next time we send a navigate_within_page event (when the user navigates the search grid)
      m.oldSearchComponent = getTrackingComponentInfo(itemFocused, gridNode.numColumns, focusedContent, m.Tracking)
    end if
    m.gridHasFocus = true
  end if
End Function


Function onResultGridCurrFocusRowChange(msg)
  gridNode = msg.getRoSGNode()
  currFocusRow = msg.getData()
  gridContent = gridNode.content

  totalItems = gridContent.getChildCount()
  totalRows = totalItems \ 5
  if totalItems MOD 5 <> 0
    totalRows = totalRows + 1
  end if

  fraction = totalRows - 1 - currFocusRow
  if fraction < 1 AND m.top.isUserEligibleForTrendingSearchBelowExperiment = true AND getExperimentResource("roku_trending_search_below", "roku_trending_search_below_v1", true).enabled = true
    translationY = 672 - ((1 - fraction) * 298)
    m.trendingSearchResultsContainer.translation = [0, translationY]
  end if  
End Function



'''''''''''''''''''''
' loadSearchResults
'
' change the m.top.searchText string so the helper will call the search api and load the search results
Function loadSearchResults(bDefaultResults = false)
  tubiLog("SearchScreen.loadSearchResults")
  if bDefaultResults = false
    m.top.searchText = m.Keyboard.text
  else
    m.top.searchText = ""
  end if
End Function


Function getTrackingComponentInfo(itemIndex, numColumns, contentNode, trackingLib)
  if trackingLib <> invalid
    column = 1 + (itemIndex MOD numColumns)
    row = 1 + (itemIndex \ numColumns)

    return {
      componentType: "search_result_component"
      componentValues: {
        content_tile: trackingLib.getAnalyticsTile(contentNode, column, row)
      }
    }
  end if

  return invalid
End Function

'''''''''''''''''''''''
' onKeyEvent
'
Function onKeyEvent(key As string, press As boolean) As boolean
  tubiLog("SearchScreen.onKeyEvent")
  if press then
    ' Only focus on content grid if animation is not in process, and if there is actually content there
    if key = "right" AND m.Keyboard.isInFocusChain() AND m.isSearchRequestInProgress = false then
      if m.ResultGrid.content <> invalid AND m.ResultGrid.content.getChildCount() > 0 AND m.isTrendingResultsGridInFocus = false
        m.ResultGrid.setFocus(true)
      else if m.trendingSearchResultGrid.content <> invalid AND m.trendingSearchResultGrid.content.getChildCount() > 0
        m.trendingSearchResultGrid.setFocus(true)
      end if
      m.gridHasFocus = true
      m.bResultsInFocus = true
      handleKeyboardVoiceInput(m.bResultsInFocus)
      return true
    else if key = "left" AND (m.ResultGrid.isInFocusChain() = true OR m.trendingSearchResultGrid.isInFocusChain() = true) then
      handleInfoPanelVisibilityForLeftPress()
      m.Keyboard.setFocus(true)
      m.gridHasFocus = false
      m.bResultsInFocus = false
      handleKeyboardVoiceInput(m.bResultsInFocus)
      return true
    else if key = "play"
      handlePlayInput()
      return true
    else if key = "back" AND (m.ResultGrid.isInFocusChain() = true OR m.trendingSearchResultGrid.isInFocusChain() = true) then
      '//when the user hits BACK, then set the keyboard to focus
      '//jump to left most visible thumbnail in the grid
      nFocused = m.ResultGrid.itemFocused
      nColumns = m.ResultGrid.numColumns
      nJumpTo = Int(nFocused / nColumns) * nColumns

      m.ResultGrid.jumpToItem = nJumpTo
      handleInfoPanelVisibilityForLeftPress()
      m.Keyboard.setFocus(true)
      m.gridHasFocus = false
      m.bResultsInFocus = false
      return true
    else if key = "down" AND m.trendingSearchResultsContainer.visible = true AND m.ResultGrid.isInFocusChain() = true AND m.trendingSearchResultGrid.content <> invalid AND m.trendingSearchResultGrid.content.getChildCount() > 0
      m.trendingSearchResultGrid.setFocus(true)
      m.isTrendingResultsGridInFocus = true
      slideTo(m.gridContainer, [0, -375], 0.3)
    else if key = "up" AND m.trendingSearchResultGrid.isInFocusChain() = true AND (m.ResultGrid.content <> invalid AND m.ResultGrid.content.getChildCount() > 0)
      slideTo(m.gridContainer, [0, 0], 0.3)
      m.ResultGrid.setFocus(true)
      m.isTrendingResultsGridInFocus = false
    end if
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
  tubiLog("SearchScreen.onTransportVoiceRequest " + command)

  if m.ResultGrid.isInFocusChain() = true
    if command = "play"
      handlePlayInput()
      response = "success"
    else if command = "ok"
      selectedContent = m.ResultGrid.content.getChild(m.ResultGrid.itemFocused)
      handleResultSelected(selectedContent, m.ResultGrid.itemFocused)
      response = "success"
    end if
  end if

  inputInfo.response = response
  m.top.transportVoiceResponse = inputInfo
End Function


Function handlePlayInput()
  if m.ResultGrid.isInFocusChain() = true
    selectedContent = m.ResultGrid.content.getChild(m.ResultGrid.itemFocused)
    updateTrackingInfo(selectedContent, m.ResultGrid.itemFocused)
    m.top.contentToPlay = selectedContent
  end if
End Function


'@resultFocus : boolean - when the search results is in focus disable the
'keyboard voice functionality and when keyboard is focused enable
'the voice functionality
Function handleKeyboardVoiceInput(resultFocus)
  if resultFocus = true
    m.keyboard.textEditBox.voiceEnabled = false
  else
    m.keyboard.textEditBox.voiceEnabled = true
  end if
End Function


'Handling when app is focusing on an invisible textbox that is built into the keyboard
Function onTextEditBoxFocused()
  m.Keyboard.setFocus(true)
End Function



Function setDefaultText()
  m.searchMenuText.text = m.searchTitleText
  m.searchHintText.text = m.searchHintToSearch
  m.KidsModeMessage.text = m.sDefaultKidsWarning
End Function


Function setVisibilityForDefaultText(b = true)
  m.KidsModeMessage.visible = b
  m.searchMenuText.visible = b
  m.searchHintText.visible = b
  m.searchResultsMessageContainer.visible = b
End Function


Function handleInfoPanelVisibilityForLeftPress()
  m.top.backgroundUriList = [m.defaultHeroUri]
  if m.searchMenuText.text <> "" AND m.searchMenuText.text <> m.searchTitleText
    m.searchScreenInfoPanel.visible = false
  else
    m.searchScreenInfoPanel.visible = false
    setDefaultText()
  end if
  setVisibilityForDefaultText(true)
  if m.microphone <> invalid
    m.microphone.visible = true
  end if
End Function

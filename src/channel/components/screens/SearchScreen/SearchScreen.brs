Function init()
  tubiLog("SearchScreen.init")
  m._ = rodash()
  m.constants = getConstantsFromGlobal()
  m.Tracking = TubiTrackingInfo(m.constants)
  m.nodeHelpers = TubiNodeHelpers()

  m.ResultArea = m.top.findNode("ResultArea")

  ' Since we have 2 different markup grid inside the result area. When the user scroll downs to trending searches grid
  ' from results grid, we move the the container that holds the 2 grid upwards. We are adding clipping rect so that anything
  ' that is above the specified x and y everything else is clipped or hidden. This causes the results grid to be hidden
  ' and gives a effects as if the grid scrolled below the container.
  m.ResultArea.clippingRect = {
    height: 1080
    width: 1920
    x: -20
    y: 0
  }

  m.searchGroup = m.top.findNode("searchGroup")
  m.voiceGroup = m.top.findNode("voiceGroup")

  m.PageGroup = m.top.findNode("PageGroup")
  m.PageGroup.translation = [m.constants.ui.translations.marginX, 0]
  m.spinner = m.top.findNode("spinner")
  m.KidsModeMessage = m.top.findNode("KidsModeMessage")

  m.autocomplete = m.top.findNode("autocomplete")
  m.autocompleteHeading = m.top.findNode("autocompleteHeading")
  m.autocompleteMenu = m.top.findNode("autocompleteMenu")
  m.autocompleteMenu.observeFieldScoped("itemFocused", "onAutocompleteFocused")
  m.autocompleteMenu.observeFieldScoped("itemSelected", "onAutocompleteSelected")
  m.autocompleteMenu.observeFieldScoped("focusedChild", "onAutocompleteFocusChanged")

  m.autocomplete.visible = false
  m.autocompleteHeading.text = getTranslation("search_suggestions")

  m.leftSide = m.top.findNode("leftSide")
  m.rightSide = m.top.findNode("rightSide")
  m.rightSideTextGroup = m.top.findNode("rightSideTextGroup")
  m.SearchText = m.top.findNode("SearchText")
  m.trendingSearchHeading = m.top.findNode("trendingSearchHeading")
  m.searchScreenInfoPanel = m.top.findNode("SearchScreenInfoPanel")
  m.searchDirectionsGroup = m.top.findNode("searchDirectionsGroup")
  m.kidsModeGroup = m.top.findNode("kidsModeGroup")

  m.searchMenuText = m.top.findNode("searchMenuText")
  m.searchHintText = m.top.findNode("searchHintText")

  m.keyboard = m.top.findNode("Keyboard")

  m.keyboard.id = "SearchKeyboard"
  m.keyboard.textEditBox.maxTextLength = 100
  m.keyboard.setFocus(true)
  m.middleColumnFocus = m.keyboard '//Keep track which component in the middle column had the last focus.

  m.keyboard.keyGrid.keyDefinitionUri = "pkg:/components/data/CustomAddressKDF.json"

  ' A value of zero or setting visible to false will cause voiceEnabled to not get updated properly when its state changed
  m.keyboard.textEditBox.opacity = 0.00001

  m.keyboard.textEditBox.observeFieldScoped("voiceEnabled", "onKeyboardTextEditBoxVoiceEnabledChange")
  onKeyboardTextEditBoxVoiceEnabledChange()

  ' searchDebounce timer helps to reduce number of search api requests
  m.searchDebounce = m.top.findNode("searchDebounce")
  m.searchDebounce.observeField("fire", "onSearchDebounce")

  setSearchStrings()

  m.ResultGrid = m.top.findNode("ResultGrid")
  m.keyboard.observeFieldScoped("text", "onKeyboardTextChanged")
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

  m.ResultGrid.itemSize = m.constants.ui.imageSizes.largePoster
  m.ResultGrid.numColumns = 4
  m.trendingSearchResultGrid.itemSize = m.constants.ui.imageSizes.largePoster
  m.trendingSearchResultGrid.numColumns = 4

  m.trendingResultsHint.text = getTranslation("trending_search_results_hint")

  m.gridContainer = m.top.findNode("gridContainer")

  m.keyboard.palette = handleKeyboardColors()
  m.NoResultsMessage = m.top.findNode("NoResultsMessage")

  m.top.observeField("focusedChild", "onScreenFocusChange")
  m.top.observeField("signedIn", "onSignedInChange")
  m.top.observeField("contentUpdated", "onSearchContentChange")
  m.top.observeFieldScoped("autocompleteContent", "onAutocompleteChange")
  m.top.observeField("transportVoiceRequest", "onTransportVoiceRequest")
  m.top.observeFieldScoped("isKidsModeAvailable", "onIsKidsModeAvailableChange")
  m.top.observeFieldScoped("shouldTrackViewableImpressionEvent", "onShouldTrackViewableImpressionEventChange")

  'no change experiment is only to validate exposure logging in statsig console.
  'NOTE: Remove this code once the experiment is complete.
  getStatsigExperimentResource("roku_no_change_statsig_experiment", "roku_no_change_statsig_experiment_v1", true)

  'set initial tracking values
  m.top.trackingPageInfo = {
    pageType: "search_page"
    pageValues: {}
  }

  screenId = m.constants.ui.screenIds.searchScreen

  m.ResultGrid.update({
    parentScreenId: screenId
    parentScreenTrackingPageInfo: m.top.trackingPageInfo
    personalizationId: ""
    shouldTrackViewableImpressionEvent: m.top.shouldTrackViewableImpressionEvent
  }, true)

  m.trendingSearchResultGrid.update({
    parentScreenId: screenId
    parentScreenTrackingPageInfo: m.top.trackingPageInfo
    personalizationId: ""
    shouldTrackViewableImpressionEvent: m.top.shouldTrackViewableImpressionEvent
  }, true)

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

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.searchMenuText, typographyConstants.ids.headerSmall)
  setTypographyOfLabel(m.searchHintText, typographyConstants.ids.bodyMediumStrong)
  setTypographyOfLabel(m.KidsModeMessage, typographyConstants.ids.bodyMedium)
  setTypographyOfLabel(m.SearchText, typographyConstants.ids.subheaderMedium)
  setTypographyOfLabel(m.trendingSearchHeading, typographyConstants.ids.subheaderMedium)
  setTypographyOfLabel(m.NoResultsMessage, typographyConstants.ids.bodyMedium)
  setTypographyOfLabel(m.autocompleteHeading, typographyConstants.ids.bodySmallStrong)
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
    m.autocompleteHeading.color = theme.secondaryTextColor
    m.trendingSearchHeading.color = theme.primaryTextColor
    m.KidsModeMessage.color = theme.secondaryTextColor
    m.searchMenuText.color = theme.primaryTextColor
    m.NoResultsMessage.color = theme.primaryTextColor
    m.ResultGrid.focusBitmapBlendColor = theme.focusedColor
    m.trendingSearchResultGrid.focusBitmapBlendColor = theme.focusedColor

    m.trendingResultsHint.color = theme.primaryTextColor
    m.noMatchingResultsMessage.color = theme.cautionColor

    m.keyboard.palette = handleKeyboardColors()
    '//When NOT in kids mode, then display the kids message
    bNotKidsMode = (theme.id <> m.constants.ui.themeIDs.kidsMode)
    displayKidsMessage(bNotKidsMode)
  end if
End Function


Function onShouldTrackViewableImpressionEventChange(msg)
  shouldTrackViewableImpressionEvent = msg.getData()
  m.ResultGrid.shouldTrackViewableImpressionEvent = shouldTrackViewableImpressionEvent
  m.trendingSearchResultGrid.shouldTrackViewableImpressionEvent = shouldTrackViewableImpressionEvent
End Function


'//@b : boolean, Should the Kids message be displayed? This param will be overriden if m.top.isKidsModeAvailable = false
Function displayKidsMessage(b = true)
  if b = false OR m.top.isKidsModeAvailable = false
    m.searchDirectionsGroup.removeChild(m.kidsModeGroup)
  else
    insertIndex = m.nodeHelpers.getChildIndex(m.searchDirectionsGroup, m.searchHintText) + 1
    m.searchDirectionsGroup.insertChild(m.kidsModeGroup, insertIndex)
  end if
End Function


Function onKeyboardTextEditBoxVoiceEnabledChange()
  if m.keyboard.textEditBox.voiceEnabled = true then
    if m.microphone = invalid then
      setTextForVoiceHint()
    end if
    if m.searchMenuText.text = "" OR m.searchMenuText.text = m.searchTitleText
      m.microphone.visible = true
    end if
  end if
End Function


Function setTextForVoiceHint()
  parentGroup = m.searchGroup '//Note: set it to m.voiceGroup if you ever wish to move this text to be underneath the other text that is above the keyboard. nVoiceHintWidth and nVoiceHintTranslationY would have to be adjusted.
  nVoiceHintWidth = 400
  nVoiceHintTranslationY = -5
  m.microphone = parentGroup.createChild("Poster")
  m.microphone.uri = "pkg:/images/microphone.png"
  m.microphone.width = "36"
  m.microphone.height = "36"
  m.voiceHint = m.microphone.createChild("Label")
  m.voiceHint.text = getTranslation("search_voice_hint")
  m.voiceHint.translation = [60, nVoiceHintTranslationY]
  m.voiceHint.numLines = 2
  m.voiceHint.wrap = true
  m.voiceHint.width = nVoiceHintWidth
  m.voiceHintfont = CreateObject("roSGNode", "Font")
  m.voiceHint.font = m.voiceHintfont

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.voiceHint, typographyConstants.ids.bodySmall)
End Function


Function setSearchStrings()
  m.sDefaultSearchText = getTranslation("screenSearch_trendingSearch")
  m.searchTitleText = getTranslation("menu_search")
  if getExternalConfigValueFromGlobal("livetv", false) = true then
    m.searchHintToSearch = getTranslation("screenSearch_defaultLinearSearch")
  else
    m.searchHintToSearch = getTranslation("screenSearch_defaultSearch")
  end if
  setDefaultText()
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


Function doesAutocompleteSuggestionsHaveFocusInMiddleColumn()
  '//if oldAutocompleteComponent is still valid, then it implies it last had focus in the middle (keyboard/suggestions) column
  return (m.middleColumnFocus.id = m.autocompleteMenu.id)
End Function


'''''''''''''''''''''''''
' onScreenFocusChange
'
' On focus set to screen, push focus on keyboard or grid.
' This is used when the search screen regains focus after coming back from the details page.
Function onScreenFocusChange()
  if m.top.hasFocus() = true then
    m.top.backgroundUriList = []
    if m.bResultsInFocus = true
      if m.isTrendingResultsGridInFocus = false AND m.ResultGrid.content <> invalid AND m.ResultGrid.content.getChildCount() > 0
        m.ResultGrid.setFocus(true)
      else
        m.trendingSearchResultGrid.setFocus(true)
      end if
    else if doesAutocompleteSuggestionsHaveFocusInMiddleColumn() = true
      m.autocompleteMenu.setFocus(true)
      m.middleColumnFocus = m.autocompleteMenu
    else
      m.Keyboard.setFocus(true)
      m.middleColumnFocus = m.keyboard
    end if
    handleKeyboardVoiceInput(m.bResultsInFocus)
  else if m.top.isInFocusChain() = false
    m.Keyboard.keyGrid.jumpToKey = [0, 0, 0] '//focus on the left most letter when focus shifts away from searchScreen (to the sideNav)
    m.keyboard.textEditBox.voiceEnabled = false
  end if

  updatePersonalizationIdInTrackingInfo()

  if shouldRefresh(m.ResultGrid.content) = true
    m.keyboard.text = ""
    loadSearchResults(true)
    ' Due to some bug in Roku it is returning both results grid and trending search grid in focus chain.
    m.ResultGrid.setFocus(false)
    m.trendingSearchResultGrid.setFocus(true)
  end if
End Function


Function updatePersonalizationIdInTrackingInfo()
  trackingPageInfo = m.top.trackingPageInfo

  if isAA(trackingPageInfo) = true AND isAA(trackingPageInfo.pageValues) = true
    personalizationId = m.trendingSearchResultGrid.personalizationId

    if m.ResultGrid.isInFocusChain() = true
      personalizationId = m.ResultGrid.personalizationId
    end if

    trackingPageInfo.pageValues.personalization_id = personalizationId
    m.top.trackingPageInfo = trackingPageInfo
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
  m.gridContainer.visible = false
  m.NoResultsMessage.visible = true
  m.NoResultsMessage.text = getTranslation("screenSearch_noResults", { term: m.top.searchText })
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

  updateTrackingInfoWithSearchQuery()
End Function


'//This function is called after the search results or the autocomplete results come back.
'// It will determine if the autocomplete results should be displated.
Function displayAutocompleteAfterResponse()
  '//make sure autocomplete suggestions are visible if they exist
  autocompleteContent = m.autocompleteMenu.content
  if autocompleteContent <> invalid AND m.isSearchRequestInProgress = false AND m.gridHasFocus = false
    m.autocomplete.visible = true
  end if
End Function


Function onAutocompleteChange()
  content = m.top.autocompleteContent

  suggestions = content.suggestions
  ' If user clicks a suggestion, send suggestion string (as searchText) and m.top.autocompleteContent.id

  if isNonEmptyArray(suggestions) = true
    menuItems = CreateObject("roSGNode", "ContentNode")
    nSuggestions = suggestions.Count()
    for i = nSuggestions - 1 to 0 step -1
      '//Reverse order the suggestions so the top suggestion is at the bottom, closer to the keyboard
      menuItems.appendChild(suggestions[i])
    end for

    m.autocompleteMenu.content = menuItems

    '//because the menu is in reverse order, ensure the top suggestion (now at the menu's bottom most item) is the 1st item to gain focus when the menu gains focus
    jumpToLastAutocompleteSuggestion()
    displayAutocompleteAfterResponse()
  end if

End Function


Function jumpToLastAutocompleteSuggestion()
  suggestions = m.autocompleteMenu.content
  if suggestions <> invalid AND suggestions.getChildCount() > 0
    nSuggestions = suggestions.getChildCount()
    m.autocompleteMenu.jumpToItem = nSuggestions - 1
  end if
End Function


'''''''''''''''''''''''
' onSearchContentChange
'
' When the server returns with search content, this function will be called.
Function onSearchContentChange()
  displayLoading(false)
  ' Resetting result grid once request is complete and not when we start the request.
  ' This is done to provide enough time for Roku to fire render tracking for search results that are getting hidden
  m.ResultGrid.content = invalid
  content = m.top.content
  results = invalid
  if content <> invalid
    results = content.results
  end if

  '//make sure autocomplete suggestions are visible if they exist
  displayAutocompleteAfterResponse()

  if results <> invalid AND results.getChildCount() > 0 then
    if content.isDefaultSearchResults = true
      ' Setting it only if we received valid data from backend.
      m.trendingSearchResultGrid.content = results
      m.trendingSearchResultGrid.personalizationId = results.personalizationId

      m.trendingSearchResultsContainer.visible = true
      resultsContent = m.ResultGrid.content
      ' Checking if the resultsGrid is empty, if yes than hiding the resultsGrid and moving the trendingSearchResultsContainer upwards.
      if resultsContent = invalid OR resultsContent.getChildCount() = 0
        '// display special text when the default search is displaying
        setDefaultText()
        m.ResultGrid.visible = false
        m.trendingSearchResultsContainer.translation = [0, 0]
      else
        if resultsContent.getChildCount() > 4
          m.trendingSearchResultsContainer.translation = [0, 752]
        else
          ' If the result count is less than or equal to 4. We will show the trending searches.
          m.trendingSearchResultsContainer.translation = [0, 430]
        end if
      end if
    else
      m.ResultGrid.content = results
      m.ResultGrid.personalizationId = results.personalizationId
      nMatches = m.ResultGrid.content.getChildCount()
      if nMatches = 1
        matchingText = getTranslation("screenSearch_matchingTitles_singular")
      else
        matchingText = getTranslation("screenSearch_matchingTitles_plural", { matches: nMatches.toStr() })
      end if

      if getExperimentResource("roku_search_autocomplete", "roku_search_autocomplete_v3", false).enabled = true
        m.searchHintText.text = matchingText
      else
        matchingText = getTranslation("screenSearch_matchingTitles")
        m.searchHintText.text = nMatches.toStr() + " " + matchingText + " " + Chr(34) + m.searchMenuText.text + Chr(34)
      end if

      m.SearchText.text = getTranslation("screenSearch_results")
      m.ResultGrid.visible = true

      trendingSearchContent = m.trendingSearchResultGrid.content
      ' Setting the visibility of trending searches if we have result.
      if trendingSearchContent <> invalid AND trendingSearchContent.getChildCount() > 0
        m.trendingResultsHint.visible = false
        if m.top.isUserEligibleForTrendingSearchContents = true
          m.trendingSearchResultsContainer.visible = true

          if results.getChildCount() > 4
            m.trendingSearchResultsContainer.translation = [0, 752]
          else
            m.trendingResultsHint.visible = true
            m.trendingSearchResultsContainer.translation = [0, 430]
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
    if m.top.isUserEligibleForTrendingSearchContents = true
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
      if getExperimentResource("roku_search_autocomplete", "roku_search_autocomplete_v3", false).enabled = false AND m.microphone <> invalid
        m.microphone.visible = false
      end if
    else
      displayNoResults()
    end if
  end if


  '//if the autocompleteMenu is the component that had been last in focus in the middle column, then that means the search results were the result of selecting an autocomplete suggestion.
  '// Move focus to the right most column
  ' if m.autocompleteMenu.isInFocusChain() = true
  if doesAutocompleteSuggestionsHaveFocusInMiddleColumn() = true
    resultsComponent = invalid
    m.middleColumnFocus = m.keyboard '//reset the middle focus to the keyboard after a suggestion selection

    if m.ResultGrid.visible = true
      resultsComponent = m.ResultGrid
      m.gridHasFocus = true
      m.bResultsInFocus = true
      m.autocomplete.visible = false
    else if m.trendingSearchResultsContainer.visible = true
      resultsComponent = m.trendingSearchResultGrid
      m.gridHasFocus = true
      m.bResultsInFocus = true
      m.autocomplete.visible = false
    else
      '//if no results then place focus on keyboard
      resultsComponent = m.Keyboard
    end if
    resultsComponent.setFocus(true)
  end if

End Function


Function onSearchDebounce()
  updateTrackingInfoWithSearchQuery()
  if m.Keyboard.text <> invalid AND m.Keyboard.text.trim().len() > 0 then
    loadSearchResults()
  else
    '//if the search text was empty, clear out any existing results and display the default search results
    loadSearchResults(true)
  end if
End Function


''''''''''''''''''''''''''
' onKeyboardTextChanged
'
' Launch a search when the keyboard text has changed
Function onKeyboardTextChanged()
  tubiLog("SearchScreen.onKeyboardTextChanged " + m.Keyboard.text)

  if m.Keyboard.textEditBox.isDictating = true
    inputDevice = m.constants.inputDevices.voice
  else
    inputDevice = m.constants.inputDevices.remote
  end if

  m.top.inputDeviceLastUsedForSearch = inputDevice
  prepareScreenForSearchChange()
  '//new search so new autocomplete suggestions needed
  m.autocomplete.visible = false
  m.autocompleteMenu.content = invalid

  if getExperimentResource("roku_search_autocomplete", "roku_search_autocomplete_v3", false).enabled = true
    '//Move some text to the right side
    '//if the roku_search_autocomplete_v3 fails, then we need to change the XML so searchDirectionsGroup is on the leftside
    m.rightSideTextGroup.insertChild(m.searchDirectionsGroup, 0)
  end if

  if isNonEmptyString(m.Keyboard.text) = true
    m.searchMenuText.text = LCase(m.Keyboard.text)
  else
    if getExperimentResource("roku_search_autocomplete", "roku_search_autocomplete_v3", false).enabled = true
      '// when searchMenuText is on the right side when the roku_search_autocomplete_v3 experiment is enabled,
      '// then do not display the search title as it looks out of place
      m.searchMenuText.text = ""
    else
      m.searchMenuText.text = m.searchTitleText
    end if
  end if

  ' making backend request only after 0.5s
  m.searchDebounce.control = "start"

End Function


Function prepareScreenForSearchChange()
  '//display spinner
  displayLoading()
  '//hide previous content
  m.noMatchingResultsMessage.visible = false
  m.trendingResultsHint.visible = false
  m.trendingSearchResultsContainer.visible = false
  m.trendingSearchResultsContainer.translation = [0, 0]
  m.ResultGrid.jumpToItem = 0
  m.trendingSearchResultGrid.jumpToItem = 0
  m.gridContainer.translation = [0, 0]
  m.gridContainer.visible = true
  m.isTrendingResultsGridInFocus = false

  m.ResultGrid.visible = false
  m.NoResultsMessage.visible = false

  m.searchMenuText.text = ""
  m.SearchText.text = ""
  m.searchHintText.text = ""
  m.KidsModeMessage.text = ""
  if getExperimentResource("roku_search_autocomplete", "roku_search_autocomplete_v3", false).enabled = true AND m.microphone <> invalid
    m.microphone.visible = false
  end if
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
  if gridContent <> invalid AND itemFocused <> invalid AND gridContent.getChild(itemFocused) <> invalid
    focusedContent = gridContent.getChild(itemFocused)
    m.top.backgroundUriList = determineBackgroundImage(focusedContent)
    m.searchScreenInfoPanel.visible = true

    if m.microphone <> invalid
      m.microphone.visible = false
    end if
    m.autocomplete.visible = false

    setVisibilityForDefaultText(false)
    m.searchScreenInfoPanel.title = focusedContent.title
    m.searchScreenInfoPanel.description = focusedContent.description

    lineOneData = {}
    lineTwoData = {}

    ' Live Events can be of type sportsEvent or video. So basing the info panel mode on presence of scheduleData.
    ' If scheduleData is present, then it is a live event.
    if focusedContent.scheduleData <> invalid
      populateInfoPanelForLiveEvent(focusedContent, m.searchScreenInfoPanel)
    else if focusedContent.type = "linear"
      m.searchScreenInfoPanel.mode = m.constants.ui.infoPanelModes.linearSearch
      lineOneData = {}
      lineTwoData = {
        badgeText: getTranslation("screenSearch_liveText")
        genres: focusedContent.genres
      }
      if focusedContent.needsLogin = true AND m.top.signedIn <> true
        m.searchScreenInfoPanel.loginReason = focusedContent.loginReason 'set loginreason before needslogin
        m.searchScreenInfoPanel.needsLogin = true
      else
        m.searchScreenInfoPanel.needsLogin = false
      end if

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
        hasAudioDescription: focusedContent.hasAudioDescription
      }

      if focusedContent.highestRendition = m.constants.serverValues.tensorVideoRenditions.fourK
        lineOneData.has4k = true
      end if

      lineTwoData = {
        roundGroupInfo: focusedContent.roundGroupInfo
      }
      if focusedContent.needsLogin = true AND m.top.signedIn <> true
        m.searchScreenInfoPanel.loginReason = focusedContent.loginReason 'set loginreason before needslogin
        m.searchScreenInfoPanel.needsLogin = true
      else
        m.searchScreenInfoPanel.needsLogin = false
      end if

    else
      m.searchScreenInfoPanel.mode = m.constants.ui.infoPanelModes.item
      lineOneData = {
        releasedate: focusedContent.releaseDate
        descriptorCode: UCase(focusedContent.descriptorCode)
        length: focusedContent.length
        hasCC: (focusedContent.hasSubtitles = true OR m._.empty(focusedContent.subtitleTracks) = false)
        rating: focusedContent.rating
        availabilityEnds: focusedContent.availabilityEnds
        hasAudioDescription: focusedContent.hasAudioDescription
      }

      lineTwoData = {
        genres: focusedContent.genres
      }

      if focusedContent.needsLogin = true AND m.top.signedIn <> true
        m.searchScreenInfoPanel.loginReason = focusedContent.loginReason 'set loginreason before needslogin
        m.searchScreenInfoPanel.needsLogin = true
      else
        m.searchScreenInfoPanel.needsLogin = false
      end if

      sotInfo = focusedContent.sotInfo
      if isAA(sotInfo) = true
        m.searchScreenInfoPanel.sotTopLabelSignals = sotInfo.sotMetaDataTopLabels
        lineTwoData.sotMetaData = sotInfo.sotMetaData
        m.searchScreenInfoPanel.sotMarkers = sotInfo.sotMarkers
      else
        m.searchScreenInfoPanel.sotTopLabelSignals = []
        lineTwoData.sotMetaData = []
        m.searchScreenInfoPanel.sotMarkers = {}
      end if
    end if

    if focusedContent.scheduleData = invalid
      m.searchScreenInfoPanel.lineOneData = lineOneData
      m.searchScreenInfoPanel.lineTwoData = lineTwoData
    end if

    m.searchScreenInfoPanel.calculateHeight = true

    ' Set up the info that the ContentController uses to send navigate_within_page events.
    ' Don't change m.top.navigateWithinPageInfo if the focused content hasn't changed
    ' (protects against re-setting when the focus is set upon returning to search page from details page)
    if m.gridHasFocus = true AND itemFocused <> invalid

      searchComponent = invalid
      if gridNode.numColumns <> invalid
        searchComponent = getTrackingComponentInfo(itemFocused, gridNode.numColumns, focusedContent, m.Tracking)
      end if

      if searchComponent <> invalid AND m.oldSearchComponent <> invalid then
        navigateWithinPageInfo = {
          pageOneof: m.Tracking.getAnalyticsPage(m.top.trackingPageInfo.pageType, m.top.trackingPageInfo.pageValues)
          componentOneof: m.Tracking.getAnalyticsComponent(m.oldSearchComponent.componentType, m.oldSearchComponent.componentValues)
          means_of_navigation: "BUTTON" 'MeansOfNavigation enum
        }

        if searchComponent.componentValues <> invalid AND searchComponent.componentValues.content_tile <> invalid
          navigateWithinPageInfo.vertical_location = searchComponent.componentValues.content_tile.row
          navigateWithinPageInfo.horizontal_location = searchComponent.componentValues.content_tile.col
        end if

        '//::TODO:: change this code so sendNavigateWithinAnalytics() can handle calling within the search results
        '// and instead of setting navigateWithinPageInfo using the following line, it instead calls sendNavigateWithinAnalytics(?)
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

  if gridContent <> invalid
    totalItems = gridContent.getChildCount()
  else
    totalItems = 0
  end if

  totalRows = totalItems \ 4
  if totalItems mod 4 <> 0
    totalRows = totalRows + 1
  end if

  fraction = totalRows - 1 - currFocusRow
  if fraction < 1 AND m.top.isUserEligibleForTrendingSearchContents = true
    translationY = 752 - ((1 - fraction) * 318)
    m.trendingSearchResultsContainer.translation = [0, translationY]
    m.trendingResultsHint.visible = true
  else
    m.trendingResultsHint.visible = false
  end if
End Function



'''''''''''''''''''''
' loadSearchResults
'
' change the m.top.searchText string so the helper will call the search api and load the search results
Function loadSearchResults(bDefaultResults = false)
  tubiLog("SearchScreen.loadSearchResults")
  m.autocomplete.visible = false
  m.autocompleteMenu.content = invalid

  if bDefaultResults = false
    m.top.searchText = m.Keyboard.text
  else
    m.top.searchText = ""
  end if
End Function


Function getTrackingComponentInfo(itemIndex, numColumns, contentNode, trackingLib)
  if trackingLib <> invalid
    column = 1 + (itemIndex mod numColumns)
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


Function getTrackingAutocompleteComponentInfo(contentNode)
  returnValue = invalid
  if contentNode <> invalid AND contentNode.title <> invalid
    returnValue = {
      componentType: "search_suggestions_component"
      componentValues: {
        search_suggestion: contentNode.title
      }
    }
  end if

  return returnValue
End Function


' Called when navigating from the search results to the middle (keyboard) column
Function navigateLeftFromSearchResults()
  if (m.ResultGrid.isInFocusChain() = true OR m.trendingSearchResultGrid.isInFocusChain() = true)
    handleInfoPanelVisibilityForLeftPress()
    if doesAutocompleteSuggestionsHaveFocusInMiddleColumn() = true
      m.autocompleteMenu.setFocus(true)
      m.middleColumnFocus = m.autocompleteMenu
      if m.ResultGrid.isInFocusChain() = true
        sendNavigateWithinAnalytics(m.ResultGrid.id, m.autocompleteMenu.id)
      else
        sendNavigateWithinAnalytics(m.trendingSearchResultGrid.id, m.autocompleteMenu.id)
      end if
    else
      handleKeyboardVoiceInput(true)
      m.Keyboard.setFocus(true)
      m.middleColumnFocus = m.keyboard
    end if
    m.gridHasFocus = false
    m.bResultsInFocus = false
  end if
End Function



'''''''''''''''''''''''
' onKeyEvent
'
Function onKeyEvent(key as String, press as Boolean) as Boolean
  tubiLog("SearchScreen.onKeyEvent")
  if press then
    ' Only focus on content grid if animation is not in process, and if there is actually content there
    if key = "right" AND (m.Keyboard.isInFocusChain() = true OR m.autocompleteMenu.isInFocusChain() = true) AND m.isSearchRequestInProgress = false then
      if m.ResultGrid.content <> invalid AND m.ResultGrid.content.getChildCount() > 0 AND m.isTrendingResultsGridInFocus = false
        m.ResultGrid.setFocus(true)
        ' Only setting focus to trending search result if the user is eligible.
      else if m.trendingSearchResultGrid.content <> invalid AND m.trendingSearchResultGrid.content.getChildCount() > 0 AND m.trendingSearchResultsContainer.visible = true
        m.trendingSearchResultGrid.setFocus(true)
      end if
      m.gridHasFocus = true
      m.bResultsInFocus = true
      handleKeyboardVoiceInput(m.bResultsInFocus)

      if doesAutocompleteSuggestionsHaveFocusInMiddleColumn() = true
        '//reset focus to the left most letter so when user navigates back to autocomplete suggestions then useer does not find it weird that the keyboard focus is on some "random" letter on the top row which the user may have forgotten that that was the last letter that had focus
        m.Keyboard.keyGrid.jumpToKey = [0, 0, 0]

        if m.ResultGrid.isInFocusChain() = true
          sendNavigateWithinAnalytics(m.autocompleteMenu.id, m.ResultGrid.id)
        else
          sendNavigateWithinAnalytics(m.autocompleteMenu.id, m.trendingSearchResultGrid.id)
        end if
      end if

      return true
    else if key = "left" AND (m.ResultGrid.isInFocusChain() = true OR m.trendingSearchResultGrid.isInFocusChain() = true) then
      navigateLeftFromSearchResults()
      return true
    else if key = "play"
      handlePlayInput()
      return true
    else if key = "back" AND (m.ResultGrid.isInFocusChain() = true OR m.trendingSearchResultGrid.isInFocusChain() = true) then
      '//when the user hits BACK, then set the keyboard to focus
      '//jump to left most visible thumbnail in the grid
      if m.ResultGrid.isInFocusChain() = true
        nFocused = m.ResultGrid.itemFocused
        nColumns = m.ResultGrid.numColumns
        nJumpTo = Int(nFocused / nColumns) * nColumns

        m.ResultGrid.jumpToItem = nJumpTo
      end if

      navigateLeftFromSearchResults()
      return true
    else if key = "down" AND m.trendingSearchResultsContainer.visible = true AND m.ResultGrid.isInFocusChain() = true AND m.ResultGrid.content <> invalid AND m.trendingSearchResultGrid.content <> invalid AND m.trendingSearchResultGrid.content.getChildCount() > 0
      lastItemIndex = m.ResultGrid.content.getChildCount() - 1
      translationY = m.ResultGrid.subBoundingRect("item" + lastItemIndex.toStr()).y
      m.trendingSearchResultGrid.setFocus(true)
      m.isTrendingResultsGridInFocus = true
      translationY = 430 + translationY
      slideTo(m.gridContainer, [0, - (translationY)], 0.3)

    else if key = "up" AND m.trendingSearchResultGrid.isInFocusChain() = true AND (m.ResultGrid.content <> invalid AND m.ResultGrid.content.getChildCount() > 0)
      slideTo(m.gridContainer, [0, 0], 0.3)
      m.ResultGrid.setFocus(true)
      m.isTrendingResultsGridInFocus = false
    else if key = "down" AND m.autocompleteMenu.isInFocusChain() = true
      handleKeyboardVoiceInput(true)
      m.Keyboard.setFocus(true)
      m.middleColumnFocus = m.keyboard
      m.gridHasFocus = false
      m.bResultsInFocus = false
      return true
    end if
  else
    if key = "up" AND m.Keyboard.isInFocusChain() = true AND m.isSearchRequestInProgress = false AND m.autocomplete.visible = true
      m.autocompleteMenu.setFocus(true)
      m.middleColumnFocus = m.autocompleteMenu
      m.gridHasFocus = false
      m.bResultsInFocus = false
      handleKeyboardVoiceInput(false)
      return true
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

  if m.ResultGrid.isInFocusChain() = true OR m.trendingSearchResultGrid.isInFocusChain() = true
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
  selectedContent = invalid
  itemFocused = 0

  if m.ResultGrid.isInFocusChain() = true AND m.ResultGrid.content <> invalid
    itemFocused = m.ResultGrid.itemFocused
    selectedContent = m.ResultGrid.content.getChild(itemFocused)
  else if m.trendingSearchResultGrid.isInFocusChain() = true AND m.trendingSearchResultGrid.content <> invalid
    itemFocused = m.trendingSearchResultGrid.itemFocused
    selectedContent = m.trendingSearchResultGrid.content.getChild(itemFocused)
  end if

  if selectedContent <> invalid
    updateTrackingInfo(selectedContent, itemFocused)
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
  m.middleColumnFocus = m.keyboard
End Function


'// Handling when the user focused on an autocomplete suggestion
Function onAutocompleteFocused(msg)
  itemFocused = msg.getData()
  menu = msg.getRoSGNode()
  autocompleteContent = menu.content

  if autocompleteContent <> invalid AND itemFocused <> invalid AND autocompleteContent.getChild(itemFocused) <> invalid
    focusedContent = autocompleteContent.getChild(itemFocused)

    autocompleteComponent = getTrackingAutocompleteComponentInfo(focusedContent)
    if m.oldAutocompleteComponent <> invalid AND autocompleteComponent <> invalid
      '//Dispatch that the focus has shifted from one autocomplete suggestion to a new suggestion
      sendNavigateWithinAnalytics(m.autocompleteMenu.id)
    else
      '//Since the old oldAutocompleteComponent does not exist or it's identical as the current autocompleteComponent, then that
      '// means the autocompleteComponent menu has just gained focus and report a toggle_on to the automplete suggestion menu
      sendAutocompleteFocusAnalytics(autocompleteComponent)
    end if

    '//if the autocomplete menu is just gaining focus, or a previous autocomplete suggestion is losing focus in favor of another one, then
    '// cache information for the next time we send a navigate_within_page event
    m.oldAutocompleteComponent = autocompleteComponent
  end if
End Function



Function onAutocompleteFocusChanged(msg)
  if m.autocompleteMenu.hasFocus() = false
    '//send analytics if autocomplete suggestions component is just losing focus
    autocompleteComponent = m.oldAutocompleteComponent
    m.oldAutocompleteComponent = invalid 'reset oldAutocompleteComponent when focus is lost
    sendAutocompleteFocusAnalytics(autocompleteComponent, false)
  end if
End Function


' Send the navigateWithinPage event when navigating to/from autocompleteMenu and searchResults grid - OR send the event when navigating within suugestions of the autocompleteMenu
'   TODO:: It currently cannot be called to track a navigateWithinPage event from search result to another search result; however, it should be chamnged so it can.
' @prevComponentID: string - set to be the value either the id of autocompleteMenu or the id of the search results grid
' @destComponentID: string - set to be the value either the id of autocompleteMenu or the id of the search results grid
Function sendNavigateWithinAnalytics(prevComponentID, destComponentID = "")
  '//initialize variables
  prevComponentOneof = invalid
  destComponentOneof = invalid

  if isNonEmptyString(destComponentID) = false
    '//If no destination ID is provided, then assume that the user is navigating within the same component
    destComponentID = prevComponentID
  end if

  autocompleteItemFocused = m.autocompleteMenu.itemFocused
  autocompleteContent = m.autocompleteMenu.content
  if autocompleteContent <> invalid AND autocompleteContent.getChildCount() > 0 AND autocompleteItemFocused <> invalid AND autocompleteContent.getChild(autocompleteItemFocused) <> invalid
    focusedAutocompleteContent = autocompleteContent.getChild(autocompleteItemFocused)
    if prevComponentID = m.autocompleteMenu.id AND destComponentID = m.autocompleteMenu.id
      '//In the case where both destComponent and prevComponent both are the autocompleteMenu, then set to oldAutocompleteComponent
      prevComponentOneof = m.oldAutocompleteComponent
    else if prevComponentID = m.autocompleteMenu.id
      prevComponentOneof = getTrackingAutocompleteComponentInfo(focusedAutocompleteContent)
    else if prevComponentID = m.trendingSearchResultGrid.id OR prevComponentID = m.ResultGrid.id
      prevComponentOneof = m.oldSearchComponent
    end if

    row = -1
    col = -1
    if destComponentID = m.autocompleteMenu.id
      destComponentOneof = getTrackingAutocompleteComponentInfo(focusedAutocompleteContent)
      '//since the UI visually reverses the order of the suggestions: bottomUp instead of topDown,
      '//then we must determine the original row placement of the suggestion that the backend had provided.
      nSuggestions = autocompleteContent.getChildCount()
      row = nSuggestions - m.autocompleteMenu.itemFocused
      col = 1

    else if destComponentID = m.trendingSearchResultGrid.id OR destComponentID = m.ResultGrid.id
      destComponentOneof = m.oldSearchComponent
      if destComponentOneof <> invalid AND destComponentOneof.componentValues <> invalid AND destComponentOneof.componentValues.content_tile <> invalid
        row = destComponentOneof.componentValues.content_tile.row
        col = destComponentOneof.componentValues.content_tile.col
      end if
    end if

    if prevComponentOneof <> invalid AND destComponentOneof <> invalid AND row > 0 AND col > 0 AND prevComponentOneof.componentType <> invalid AND prevComponentOneof.componentValues <> invalid AND destComponentOneof.componentType <> invalid AND destComponentOneof.componentValues <> invalid
      updateTrackingInfoWithSearchQuery()
      navigateWithinPageInfo = {
        pageOneof: m.Tracking.getAnalyticsPage(m.top.trackingPageInfo.pageType, m.top.trackingPageInfo.pageValues)
        componentOneof: m.Tracking.getAnalyticsComponent(prevComponentOneof.componentType, prevComponentOneof.componentValues)
        dest_componentOneof: m.Tracking.getAnalyticsDestinationComponent(destComponentOneof.componentType, destComponentOneof.componentValues)
        means_of_navigation: "SCROLL" 'MeansOfNavigation enum
        vertical_location: row
        horizontal_location: col
      }

      '//Dispatch that the focus has shifted from an autocomplete suggestion to a result item, or visa versa
      m.top.navigateWithinPageInfo = navigateWithinPageInfo
    end if

  end if
End Function


' This is should be called when the autocomplete suggestions just gains or loses focus. The appropriate analytics will be sent.
' @autocompleteComponent, assoocArray - The associated array that is created when calling getTrackingAutocompleteComponentInfo()
' bToggleOn, boolean - Did the Suggestion compontent gain focus? If not, it means it just lost focus.
Function sendAutocompleteFocusAnalytics(autocompleteComponent, bToggleOn = true)
  if autocompleteComponent <> invalid
    sUserInteraction = ""
    if bToggleOn = true
      sUserInteraction = "TOGGLE_ON"
    else
      sUserInteraction = "TOGGLE_OFF"
    end if

    updateTrackingInfoWithSearchQuery()
    pageInfo = m.top.trackingPageInfo
    m.top.componentInteractionInfo = {
      pageOneof: m.Tracking.getAnalyticsPage(pageInfo.pageType, pageInfo.pageValues)
      componentOneof: m.Tracking.getAnalyticsComponent(autocompleteComponent.componentType, autocompleteComponent.componentValues)
      user_interaction: sUserInteraction
    }
  end if
End Function


'// Handling when the user selects an autocomplete suggestion
Function onAutocompleteSelected(msg)
  tubiLog("SearchScreen.onAutocompleteSelected")
  if m.isSearchRequestInProgress = false
    itemSelected = msg.getData()
    menu = msg.getRoSGNode()
    itemData = menu.content.getChild(itemSelected)
    itemTitle = itemData.title
    if m.top.content = invalid OR m.top.content.searchText <> itemTitle
      '//Ensure the current results is not associated with the selected suggestion
      prepareScreenForSearchChange()

      '//Set the query value to the current user-typed query before the keyboard text is changed to the suggestion
      updateTrackingInfoWithSearchQuery()

      m.searchMenuText.text = LCase(itemTitle)

      '//unobserve keyboard.text while dispatching that an autocomplete suggestion was selected.
      '// This is to ensure only one search is performed.
      m.keyboard.unobserveFieldScoped("text")
      m.Keyboard.text = itemTitle
      m.keyboard.observeFieldScoped("text", "onKeyboardTextChanged")

      m.autocomplete.visible = false
      m.autocompleteMenu.content = invalid

      m.top.inputDeviceLastUsedForSearch = m.constants.inputDevices.remote
      m.top.autoCompleteSearchText = itemTitle
    end if
  end if
End Function


Function setDefaultText()
  if m.Keyboard.text = ""
    m.leftSide.insertChild(m.searchDirectionsGroup, 0)

    m.searchMenuText.text = m.searchTitleText
    m.KidsModeMessage.text = m.sDefaultKidsWarning
    m.searchHintText.text = m.searchHintToSearch
    m.searchText.text = ""
    m.autocomplete.visible = false

    if getExperimentResource("roku_search_autocomplete", "roku_search_autocomplete_v3", false).enabled = true AND m.microphone <> invalid
      m.microphone.visible = true
    end if
  end if
End Function


Function setVisibilityForDefaultText(b = true)
  m.KidsModeMessage.visible = b
  m.searchMenuText.visible = b
  m.searchHintText.visible = b
  m.searchResultsMessageContainer.visible = b

End Function


Function handleInfoPanelVisibilityForLeftPress()
  ' Setting background to empty so that we display full screen background.
  m.top.backgroundUriList = []
  m.searchScreenInfoPanel.visible = false
  if m.searchMenuText.text = "" OR m.searchMenuText.text = m.searchTitleText
    m.searchScreenInfoPanel.visible = false
    setDefaultText()
  end if
  setVisibilityForDefaultText(true)

  if getExperimentResource("roku_search_autocomplete", "roku_search_autocomplete_v3", false).enabled = false AND m.microphone <> invalid
    m.microphone.visible = true
  end if

  autocompleteContent = m.autocompleteMenu.content
  if autocompleteContent <> invalid
    m.autocomplete.visible = true
  end if
End Function


Function onIsKidsModeAvailableChange(msg)
  isKidsModeAvailable = msg.getData()
  if isKidsModeAvailable = false
    '//If kids mode is not available, then immediately hide the kids message
    displayKidsMessage(false)
  end if
End Function

Function updateTrackingInfoWithSearchQuery()
  trackingPageInfo = m.top.trackingPageInfo
  if isAA(trackingPageInfo.pageValues) = true
    trackingPageInfo.pageValues.query = Left(m.Keyboard.text, 256)
    m.top.trackingPageInfo = trackingPageInfo
    m.ResultGrid.update({
      parentScreenTrackingPageInfo: trackingPageInfo
    }, true)
  end if
End Function
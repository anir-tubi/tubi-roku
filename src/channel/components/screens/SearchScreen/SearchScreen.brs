Function init()
  tubiLog("SearchScreen.init")
  m._ = rodash()
  m.constants = m.global.constants
  m.theme = m.global.theme
  Request = TubiRequest(m.constants.settings)
  Auth = TubiAuth(m.constants, Request)
  m.Tracking = TubiTracking(m.constants, Request, Auth)

  m.ResultArea = m.top.findNode("ResultArea")
  m.searchGroup = m.top.findNode("searchGroup")

  m.spinner = m.top.findNode("spinner")
  m.NavSection = m.top.findNode("nav")
  m.KidsModeMessage = m.top.findNode("KidsModeMessage")
  m.leftSide = m.top.findNode("leftSide")
  m.SearchText = m.top.findNode("SearchText")
  m.searchScreenInfoPanel = m.top.findNode("SearchSCreenInfoPanel")
  hasVoiceRemoteFeature = m.constants.deviceInfo.hasVoiceRemoteFeature

  m.voiceHintfont = CreateObject("roSGNode", "Font")
  m.voiceHintfont.uri = "pkg:/fonts/Vaud-SemiBold.ttf"

  m.searchMenuText = m.top.findNode("searchMenuText")
  m.searchHintText = m.top.findNode("searchHintText")


  'show voice hint message if user has voice remote
  if hasVoiceRemoteFeature = true
    setTextForVoiceHint()
  end if

  m.keyboard = m.top.findNode("Keyboard")

  m.keyboard.id = "SearchKeyboard"
  m.keyboard.setFocus(true)
  m.Keyboard.textEditBox.maxTextLength = 100

  m.Keyboard.keyGrid.keyDefinitionUri = "pkg:/components/data/CustomAddressKDF.json"
  m.keyboard.textEditBox.visible = false

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

  m.keyboard.palette = handleKeyboardColors()
  m.ResultGrid.focusBitmapBlendColor = m.theme.focused

  m.NoResultsMessage = m.top.findNode("NoResultsMessage")
  m.NoResultsMessage.color = m.constants.ui.colors.primaryText

  m.top.observeField("focusedChild", "onScreenFocusChange")
  m.top.observeField("signedIn", "onSignedInChange")
  m.top.observeField("visible", "onVisible")
  m.top.observeField("enabled", "onEnableChange")
  m.top.observeField("kidsModeEnabled", "onKidsModeEnableChange")
  m.top.observeField("contentUpdated", "onSearchContentChange")
  m.top.observeField("transportVoiceRequest", "onTransportVoiceRequest")

  m.SearchText.color = m.global.constants.ui.colors.titleHeader

  m.defaultHeroUri = "pkg:/images/art-blur-background.png"

  if m.constants.deviceInfo.scaledUi = true then
    m.ResultGrid.focusBitmapUri = "pkg:/images/selector-hd.9.png"
  end if

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

  m.top.screenLevel = m.constants.ui.screenLevels.searchScreen
  m.top.handlesTransportVoiceRequests = true
  loadSearchResults(true)'//load the default search results

  BackLabel = m.top.findNode("callToAction")
  if m.constants.deviceInfo.uiResolution <> "FHD"
    '//if the display is not 1080, then adjust the BackLabel to ensure proper vertical alignment
    BackLabel.translation = [BackLabel.translation[0], BackLabel.translation[1] + 3]
  end if
End Function


Function setTextForVoiceHint()
  m.microphone = m.searchGroup.createChild("Poster")
  m.microphone.uri = "pkg:/images/microphone.png"
  m.microphone.width = "36"
  m.microphone.height = "36"
  m.microphone.translation = [0,0]
  m.voiceHint = m.microphone.createChild("Label")
  m.voiceHint.text = getTranslation("search_voice_hint")
  m.voiceHint.translation = [m.microphone.translation[0]+ 60, m.microphone.translation[1] - 5]
  m.voiceHint.numLines = 2
  m.voiceHint.wrap  = true
  m.voiceHint.width = 400
  m.voiceHintfont.size = 21
  m.voiceHint.font = m.voiceHintfont
End Function


Function setSearchStrings()
  BackLabel = m.top.findNode("callToAction")
  BackLabel.text = getTranslation("goBack_menu")

  m.sDefaultSearchText = getTranslation("screenSearch_trendingSearch")
  m.searchTitleText = getTranslation("menu_search")
  m.searchHintToSearch = getTranslation("screenSearch_defaultLinearSearch")
  setDefaultText()
  m.searchText.text = m.sDefaultSearchText
  m.sDefaultKidsWarning = getTranslation("screenSearch_kidsWarning")
  m.KidsModeMessage.text = m.sDefaultKidsWarning
  m.spinner.text = getTranslation("screenSearch_loading")
End Function


'''''''''''''''''''''''''
' displayLoading
'
' Display the loading spinner and loading message based on search results loaded
Function displayLoading(b = true)
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
      m.ResultGrid.setFocus(true)
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

Function onKidsModeEnableChange()
  m.keyboard.palette = handleKeyboardColors()
  m.ResultGrid.focusBitmapBlendColor = m.theme.focused
  if m.top.kidsModeEnabled = true
    m.KidsModeMessage.visible = false
  else
    m.KidsModeMessage.visible = true
    m.KidsModeMessageSpacer.width = 0
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
Function onResultSelected()
  tubiLog("SearchScreen.onResultSelected")
  if m.ResultGrid.content <> invalid
    selectedContent = m.ResultGrid.content.getChild(m.ResultGrid.itemSelected)
    handleResultSelected(selectedContent, m.ResultGrid.itemSelected)
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
  m.ResultGrid.content = m.top.content

  if m.top.content <> invalid AND m.top.content.getChildCount() > 0 then
    if m.top.content.isDefaultSearchResults = true
      '//display special text when the default search is displaying
      setDefaultText()
      if m.microphone <> invalid
        m.microphone.visible = true
      end if
    else
      matchingText = getTranslation("screenSearch_matchingTitles")
      m.searchHintText.text = m.ResultGrid.content.getChildCount().toStr() + " " + matchingText + " " + Chr(34) + m.searchMenuText.text + Chr(34)
      m.SearchText.text = getTranslation("screenSearch_results")
    end if

    m.ResultGrid.visible = true
    m.NoResultsMessage.visible = false
  else
    displayNoResults()
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

End function


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

  m.SearchText.text =  ""
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
Function onItemFocused()
  tubiLog("SearchScreen.onItemFocused")
  if m.ResultGrid.content <> invalid
    focusedContent = m.ResultGrid.content.getChild(m.ResultGrid.itemFocused)
    m.top.backgroundUriList = focusedContent.backgrounds
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

      m.searchScreenInfoPanel.needsLogin =  focusedContent.needsLogin AND (m.top.signedIn <> true)
    else
      m.searchScreenInfoPanel.mode = m.constants.ui.infoPanelModes.item
      lineOneData = {
        releasedate: focusedContent.releaseDate
        descriptorCode: UCase(focusedContent.descriptorCode)
        length: focusedContent.length
        hasCC: (focusedContent.hasSubtitles = true OR m._.empty(focusedContent.subtitleTracks) = false)
        rating: focusedContent.rating
      }

      lineTwoData = {
        genres: focusedContent.genres
      }

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
    if m.gridHasFocus = true AND m.ResultGrid.itemFocused <> invalid

      searchComponent = invalid
      if m.ResultGrid.numColumns <> invalid
        searchComponent = getTrackingComponentInfo(m.ResultGrid.itemFocused, m.ResultGrid.numColumns, focusedContent, m.Tracking)
      end if

      if searchComponent <> invalid
        navigateWithinPageInfo = {
          pageOneof: m.Tracking.getAnalyticsPage(m.top.trackingPageInfo.pageType, m.top.trackingPageInfo.pageValues)
          componentOneof: m.Tracking.getAnalyticsComponent(m.oldSearchComponent.componentType, m.oldSearchComponent.componentValues)
          means_of_navigation: "BUTTON"  'MeansOfNavigation enum
          vertical_location_mode: "INDEX"  'LocationMode enum
          horizontal_location_mode: "INDEX"  'LocationMode enum
        }

        if searchComponent.componentValues <> invalid AND searchComponent.componentValues.content_tile <> invalid
          navigateWithinPageInfo.vertical_location = searchComponent.componentValues.content_tile.row
          navigateWithinPageInfo.horizontal_location = searchComponent.componentValues.content_tile.col
        end if

        m.top.navigateWithinPageInfo = navigateWithinPageInfo
        m.oldSearchComponent = searchComponent
      end if
    else if m.gridHasFocus = false AND m.ResultGrid.itemFocused <> invalid
      'the search grid is gaining focus, so we don't send navigate_within_page events at this time. Instead we just cache information
      'for the next time we send a navigate_within_page event (when the user navigates the search grid)
      m.oldSearchComponent = getTrackingComponentInfo(m.ResultGrid.itemFocused, m.ResultGrid.numColumns, focusedContent, m.Tracking)
    end if
    m.gridHasFocus = true
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
Function onKeyEvent(key As String, press As Boolean) As Boolean
  tubiLog("SearchScreen.onKeyEvent")
  if press then
    ' Only focus on content grid if animation is not in process, and if there is actually content there
    if key = "right" AND m.Keyboard.isInFocusChain() AND m.ResultGrid.content <> invalid AND m.ResultGrid.content.getChildCount() > 0 then
      m.ResultGrid.setFocus(true)
      m.gridHasFocus = true
      m.bResultsInFocus = true
      handleKeyboardVoiceInput(m.bResultsInFocus)
      return true
    else if key = "left" AND m.ResultGrid.isInFocusChain() then
      handleInfoPanelVisibilityForLeftPress()
      m.Keyboard.setFocus(true)
      m.gridHasFocus = false
      m.bResultsInFocus = false
      handleKeyboardVoiceInput(m.bResultsInFocus)
      return true
    else if key = "play"
      handlePlayInput()
      return true
    else if key = "back" AND m.ResultGrid.isInFocusChain() then
      '//when the user hits BACK, then set the keyboard to focus
      '//jump to left most visible thumbnail in the grid
      nFocused = m.ResultGrid.itemFocused
      nColumns = m.ResultGrid.numColumns
      nJumpTo = Int(nFocused/nColumns) * nColumns

      m.ResultGrid.jumpToItem = nJumpTo
      handleInfoPanelVisibilityForLeftPress()
      m.Keyboard.setFocus(true)
      m.gridHasFocus = false
      m.bResultsInFocus = false
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


'Set the text that tells users that they can use the remote
'control's microphone button on the search screen. Because
'the voice hint text can be different widths based on the language,
'this function will also determine where exactly to place the microphone button,
'which needs to be placed immediately after the text.
Function setVoiceHint()
  hint = getTranslation("search_hint")
  hintArr = hint.split(" ")
  m.voiceHint.wrap = true
  m.voiceHint.text = ""
  'Array of Labels(each item in the array = each label in the layoutgroup)
  labelListArray = []
  'Array to determine the number of words in a line
  sentenceArray = []
  wordCount = hintArr.count()
  'width to determine microphone x translation
  lastLineWidth = 0
  labelWidth = m.keyboard.boundingRect().width
  'Below logic is to handle the custom wrap to add microphone image at the end of the translated text.
  'splitting the sentence into words by space, we are adding the words
  'to the labelListArray until it satisfies the lineWidth. If the width exceeds,
  'will move the words to the next line. Later each line converted to a label.
  for i = 0 to wordCount - 1
    if i = 0
      m.voiceHint.text = hintArr[i]
    else
      m.voiceHint.text = m.voiceHint.text + " " + hintArr[i]
    end if
    width = m.voiceHint.boundingRect().width
    'if the total width of combined words is exceeding the line width move to next line
    'else append to the sentenceArray
    if width > labelWidth or i = wordCount - 1
      labelListArray.push(sentenceArray.join(" "))
      'if it's last word determine the lastline width
      'else initiate the next line
      if i = wordCount - 1
        'if the total width of combined words is exceeding the line width move to next line
        'else consider it as last line and set the last line width
        if width > labelWidth
         labelListArray.push(hintArr[i])
         m.voiceHint.text = hintArr[i]
         lastLineWidth = m.voiceHint.boundingRect().width
        else
          sentenceArray.push(hintArr[i])
          labelListArray[labelListArray.count() -1] = sentenceArray.join(" ")
          lastLineWidth = width
        end if
      else
        sentenceArray = [hintArr[i]]
        m.voiceHint.text = hintArr[i]
      end if
    else
      sentenceArray.push(hintArr[i])
    end if
  end for
  noOfLines = labelListArray.count()
  m.voiceHint.width = labelWidth
  if noOfLines > 0
    m.voiceHint.text = labelListArray[0]
    'createLayoutGroup for eachline in labelListArray and ifit's lastline append microphone icon at the end
    for i = 1 to noOfLines - 1
      voiceHintLine = m.voiceHint.clone(true)
      voiceHintLine.id = "voiceHint" + i.toStr()
      voiceHintLine.text = labelListArray[i]
      m.searchHintGroup.appendChild(voiceHintLine)
      if i = noOfLines - 1
        microphone = voiceHintLine.createChild("Poster")
        microphone.uri = "pkg:/images/microphone.png"
        microphone.width = "36"
        microphone.height = "36"
        microphone.translation = [lastLineWidth + 3, -5]
      end if
    end for
  end if

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
End Function


Function handleInfoPanelVisibilityForLeftPress()
  m.top.backgroundUriList = [m.defaultHeroUri]
  if m.searchMenuText.text <> "" AND m.searchMenuText.text <>  m.searchTitleText
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

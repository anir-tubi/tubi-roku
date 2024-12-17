Function configureBrazeSdk()
  config = {}
  configFields = BrazeConstants().BRAZE_CONFIG_FIELDS
  brazeSettings = m.constants.thirdParty.braze
  config[configFields.API_KEY] = brazeSettings.apiKey
  config[configFields.ENDPOINT] = brazeSettings.endpoint
  config[configFields.HEARTBEAT_FREQ_IN_SECONDS] = brazeSettings.refreshFrequency

  m.global.addFields({ brazeConfig: config })
End Function


Function setBrazeUserData(authInfo)
  ' Adding a check to make sure we only call braze method if the user has given consent.
  ' setBrazeUserData is called when user sign in/out.
  if getConsentOptOutStatusByKey(m.constants.consentKeys.marketing) = false AND m.braze <> invalid
    m.braze.setCustomAttribute("preferred_device_id", m.constants.deviceInfo.deviceId)
    if authInfo <> invalid AND authInfo.userId <> invalid
      m.braze.setUserId(authInfo.userId)
      if m.pub_serverPersistentData.email <> invalid
        ' Email no longer comes from authInfo so must be pulled in
        m.braze.setEmail(m.pub_serverPersistentData.email)
      end if
    else
      ' Setting device id as the unique id.
      m.braze.setUserId(m.constants.deviceInfo.deviceId)
    end if
    ' Doing it as per recommendation from the braze sdk documentation.
    m.brazeTask.BrazeInAppMessage = invalid
  end if
End Function


' @userId: string: user id of the logged in user.
Function brazeMergeUsers(userId)
  restApi = ThirdPartyApi(m.constants)
  requestInfo = restApi.createBrazeMergeUsersReqInfo(m.constants.deviceInfo.deviceId, userId)
  m.makeRequest({
    url: requestInfo.url
    options: requestInfo.options
    requestType: m.constants.reqNames.postBrazeMergeUsers
    responseType: "assocarray"
    silenceCallbackWarnings: true
    errorCallback: onBrazeMergeUsersError
  })
End Function


' @error: assocarray: {code: 401} contains the status code.
Function onBrazeMergeUsersError(error)
  ' Logging braze error so that we can monitor if we are noticing any unexpected errors.
  tubiLog(FormatJSON(error), "error", "apiError", "braze-merge-users-error")
End Function


Function onInAppMessageTriggered(msg)
  if m.constants.settings.mode <> "qa" OR m.constants.settings.hideStartupModals <> true
    m.queuedInAppMessage = msg.getData()
    processQueuedInAppMessage()
  end if
End Function


Function onScreenLoadingChange(msg)
  isLoading = msg.getData()

  if isLoading = false
    currentScreen = msg.getRoSGNode()
    currentScreen.unobserveFieldScoped("isLoading")
    processQueuedInAppMessage()
  end if
End Function


Function processQueuedInAppMessage()
  currentScreen = getCurrentScreen()
  ' Only processing if we are in adult or teen mode.
  ' Restricting the display to only whitelisted screens.
  ' If the screen loading is in progress not displaying the modal.
  ' Delaying it until the screen loading is complete.
  whitelistedScreenIds = {}
  whitelistedScreenIds[m.constants.ui.screenIds.homeScreen] = true
  if m.queuedInAppMessage <> invalid AND isKidsUIOn() = false AND currentScreen <> invalid AND whitelistedScreenIds.DoesExist(currentScreen.id) = true
    if currentScreen.isLoading = true
      currentScreen.observeFieldScoped("isLoading", "onScreenLoadingChange")
    else
      processInAppMessage(m.queuedInAppMessage)
      m.queuedInAppMessage = invalid
    end if
  end if
End Function


Function processInAppMessage(message)
  if message <> invalid
    ' Stopping any preview that is in progress.
    stopVideoPreview()
    stopAndHideLinearVideoPlayer()
    extras = message.extras
    ' Checking to make sure we have a template config key before proceeding.
    if extras <> invalid AND extras.template <> invalid

      data = getBrazeModalData(message)

      if extras.template = "toast"
        showToastStyleModal(data.modalInfo, data.buttonList)
      else
        showMultiStyleModal(data.modalInfo, data.buttonList)
      end if
    end if

    ' Calling the braze method to track the impression.
    LogInAppMessageImpression(message.id, m.brazeTask)
  end if
End Function


Function getBrazeModalData(message)
  modalInfo = {
    header: message.header
    subheader: message.message
    instantResumeAction: m.constants.instantResumeActions.closeDialog
  }

  ' Will contain a comma seperated string of urls.
  imageUrl = message.image_url

  if imageUrl <> invalid
    images = imageUrl.split(",")
    modalInfo.imageUrls = images
  end if

  buttons = message.buttons
  buttonList = []
  for each button in buttons
    buttonType = "accept"
    if button.click_action = "NONE"
      buttonType = "dismiss"
    end if

    buttonInfo = {
      text: button.text
      type: buttonType
      callback: onBrazeInAppMessageButtonSelected
      callbackParams: {
        "uri": button.uri
        "messageId": message.id,
        "buttonId": button.id
      }
      shouldFocusParentBeforeCallback: false
    }
    buttonList.push(buttonInfo)
  end for

  return {
    "modalInfo": modalInfo,
    "buttonList": buttonList
  }
End Function


Function onBrazeInAppMessageButtonSelected(parameters)
  input = parameters

  ' Sample uri value "action=navigate&page=movies"
  if input <> invalid
    ' Tracking button click.
    if input.messageId <> invalid AND input.buttonId <> invalid
      LogInAppMessageButtonClick(input.messageId, input.buttonId, m.brazeTask)
    end if

    ' Processing the uri if it is not empty or else focusing back to the screen.
    if isNonEmptyString(input.uri) = true
      ' Converting the uri string to key value pairs.
      queryKeyValuePairs = input.uri.split("&")
      uriParameters = {}
      for each queryPair in queryKeyValuePairs
        keyValues = queryPair.split("=")

        ' Making sure the we have a validate syntax. ex: "action=navigate".
        if isNonEmptyArray(keyValues) = true AND keyValues.count() = 2
          uriParameters[keyValues[0]] = keyValues[1]
        end if

      end for

      processUriClickAction(uriParameters)
    else
      ' Focusing back to the screen.
      manageChildFocus()
    end if

  end if
End Function


Function processUriClickAction(uriParameters)
  if isAA(uriParameters) = true AND uriParameters.action <> invalid
    action = uriParameters.action
    ' Since the action values are not used else where in the application not moving to constants so that we avoid constants access.
    if action = "navigate"
      ' Sample uri: "action=navigate&page=movies"
      processNavigateAction(uriParameters)
    else if action = "play"
      ' Sample uri: "action=play&contentId=539270&mediaType=movie"
      processPlayAction(uriParameters)
    end if
  end if
End Function


Function processNavigateAction(uriParameters)
  page = uriParameters.page
  ' Since the page values are not used else where in the application not moving to constants so that we avoid constants access.
  if page <> invalid
    if page = "movies"
      showMoviesScreen()
      focusSideNavOption(m.constants.ui.sideNavIds.movies)
    else if page = "myList"
      isUserSigedIn = isLoggedInUser()
      if isUserSigedIn = true
        showMyStuffScreen()
        focusSideNavOption(m.constants.ui.sideNavIds.myList)
      end if
    else if page = "espanol"
      showEspanolScreen()
      focusSideNavOption(m.constants.ui.sideNavIds.espanol)
    else if page = "tvShows"
      showTVScreen()
      focusSideNavOption(m.constants.ui.sideNavIds.tv)
    else if page = "liveTv"
      showDefaultEPGScreen()
      focusSideNavOption(m.constants.ui.sideNavIds.linearEPG)
    else if page = "categories"
      showCategoryPanelListScreen(m.constants)
      focusSideNavOption(m.constants.ui.sideNavIds.categories)
    else if page = "channels"
      showCategoryPanelListScreen(m.constants, false, m.constants.ui.categoryIds.networks)
      focusSideNavOption(m.constants.ui.sideNavIds.categories)
    else if page = "signin" OR page = "signup"
      isUserSigedIn = isLoggedInUser()
      if isUserSigedIn = false
        startSignIn()
      end if
    else if page = "category" AND isNonEmptyString(uriParameters["category"]) = true
      isUserSigedIn = isLoggedInUser()
      categoryId = uriParameters["category"]
      categoryIds = m.constants.ui.categoryIds
      if isUserSigedIn = true OR (categoryId <> categoryIds.history AND categoryId <> categoryIds.queue AND categoryId <> categoryIds.myLikes)
        navigateToCategoryDetailsScreen(categoryId)
        focusSideNavOption(m.constants.ui.sideNavIds.categories)
      else
        showHomeScreen(m.constants)
        focusSideNavOption(m.constants.ui.sideNavIds.home)
      end if
    else if page = "network" AND isNonEmptyString(uriParameters["network"]) = true
      navigateToNetworkDetailsScreen(uriParameters["network"])

      '//::NOTE:: there is no longer a channels side nav option, so target the categories side nav item.
      focusSideNavOption(m.constants.ui.sideNavIds.categories)
    else if page = "detail" AND isNonEmptyString(uriParameters["contentId"]) = true
      processPlayAndDetailsScreenAction(uriParameters)
    else
      ' Focusing back to the screen as a fallback if wrong uri was configured.
      m.top.setFocus(true)
    end if

    ' Setting proper mode based on the page.
    if page = "espanol"
      setUiMode(m.constants.ui.modes.latino)
    else
      setUiMode(m.constants.ui.modes.standard)
    end if
  end if
End Function


Function processPlayAction(uriParameters)
  processPlayAndDetailsScreenAction(uriParameters)
End Function


Function processPlayAndDetailsScreenAction(uriParameters)
  contentId = uriParameters.contentId
  mediaType = uriParameters.mediaType
  action = uriParameters.action
  ' Since the page values are not used else where in the application not moving to constants so that we avoid constants access.
  if contentId <> invalid
    if mediaType = "series"
      contentType = "series"

      ' Appending zero to series id if one is not appended when configured.
      if contentId.startsWith("0") = false
        contentId = "0" + contentId
      end if

    else
      contentType = "video"
    end if
    content = CreateObject("roSGNode", "ContentNode")
    content.update({
      "id": contentId
      "type": contentType
    }, true)

    if mediaType = m.constants.ui.contentTypes.purpleCarpetEvent
      getSingleContentFromServer(content, onDeeplinkSportsContentSuccess, showDeeplinkErrorModal)
    else if action = "play"
      showDetailScreen(content, false, skipDetailScreen, invalid, {})
    else
      showDetailScreen(content, true, invalid, invalid, {})
    end if
  end if
End Function


' Restart braze session.
Function restartBrazeSession()
  if getConsentOptOutStatusByKey(m.constants.consentKeys.marketing) = false AND m.braze <> invalid
    stopBrazeTask()
    configureBrazeAndInitializeTask()
  end if
End Function

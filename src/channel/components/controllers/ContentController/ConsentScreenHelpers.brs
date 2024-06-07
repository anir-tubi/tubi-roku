Function showConsentScreen(callback = startUserExperience)
  m.callbackAfterConsent = callback
  showContentGroupAndHideSpinner()
  bannerScreenTrackingInfo = {
    pageType: "your_privacy_page"
    pageValues: {}
  }
  m.oneTrust.callFunc("showBannerUI", true)
  m.oneTrust.observeFieldScoped("AcceptAll", "onAcceptAll")
  m.oneTrust.observeFieldScoped("RejectAll", "onRejectAll")
  m.oneTrust.observeFieldScoped("onHideBanner", "proceedAfterConsentUpdated")
  m.oneTrust.observeFieldScoped("onHideFailure", "proceedAfterConsentUpdated")
  m.top.observeFieldScoped("focusedChild", "onConsentScreenFocusChange")
  
  ' Since OT handles the displaying of screen. firing a page load after calling show banner ui method.
  screenTrackingLoad(bannerScreenTrackingInfo)
End Function


Function onConsentScreenFocusChange(msg)
  node = msg.getData()
  if node.isSubType("OTBanner") = true
    ' The focused child change event gets triggered every time the focus changes on the show consent screen.
    ' Since we only want to know when OneTrust banner component loads for the first and receives focus.
    ' Once it is loaded and focused for the first time we unobserve the field for which we have attached observer inside showConsentScreen above.
    m.top.unObserveFieldScoped("focusedChild")
    node.observeFieldScoped("onBannerClickedSettings", "onManagePreferencesSelected")
    node.observeFieldScoped("onBannerClickedVendorList", "onManageVendorsSelected")
  end if
End Function


Function onAcceptAll(_msg)
  onConsentActionButtonSelected(m.constants.ui.consentActionButtonIds.accept)
End Function


Function onRejectAll(_msg)
  onConsentActionButtonSelected(m.constants.ui.consentActionButtonIds.reject)
End Function


Function onManagePreferencesSelected()
  oldScreenTrackingInfo = {
    pageType: "your_privacy_page"
    pageValues: {}
  }
  currentScreenTrackingInfo = {
    pageType: "privacy_preferences_page"
    pageValues: {}
  }
  ' Since we do not control the manage preferences screen firing the events when the buttons are clicked.
  screenTrackingNavigate(oldScreenTrackingInfo, currentScreenTrackingInfo)
  screenTrackingLoad(currentScreenTrackingInfo)
End Function


' @buttonSelected: string, contains the id value of the button that was selected, accepted values are in m.constants.ui.consentActionButtonIds.
Function onConsentActionButtonSelected(buttonSelected)
  buttonValue = ""
  if buttonSelected = m.constants.ui.consentActionButtonIds.reject
    buttonValue = "REJECT_ALL_CONSENTS"
  else if buttonSelected = m.constants.ui.consentActionButtonIds.accept
    buttonValue = "ACCEPT_ALL_CONSENTS"
  end if

  if isNonEmptyString(buttonValue) = true
    trackingPageInfo = {
      pageType: "your_privacy_page"
      pageValues: {}
    }

    componentValues = {
      button_type: "TEXT"
      button_value: buttonValue
    }
    pageOneof = m.Tracking.getAnalyticsPage(trackingPageInfo.pagetype, trackingPageInfo.pageValues)
    componentOneof = m.Tracking.getAnalyticsComponent("button_component", componentValues)

    componentInteractionEvent =  {
      pageOneof: pageOneof
      componentOneof: componentOneof
      user_interaction: "CONFIRM"
    }
    m.trackingLoggingTask.trackEvent = {
      type: "component_interaction"
      values: componentInteractionEvent
    }
  end if
End Function


Function getConsent(onGetConsentCompletionCallback)
  m.onGetConsentCompletionCallback = onGetConsentCompletionCallback
  ' We are using One trust sdk only in GDPR countries.
  ' If the user is in gdpr country then we will fetch the partner token and proceed with One trust sdk initialization.
  if isGDPR(m.constants) = true
    initialiazeOneTrustSDK()
  else
    ' If the user is not in GDPR country we will call account service get consent api.
    ' Response from get consent will contain privacy center information and consent status for Roku's continue watching feature.
    requestInfo = m.userDeviceApi.createGetConsentReqInfo()
    m.makeRequest({
      url: requestInfo.url
      options: requestInfo.options
      requestType: m.constants.reqNames.getConsent
      successCallback: onGetConsentSuccess
      responseType: "assocarray"
      silenceCallbackWarnings: true
    })
  end if
End Function


Function initialiazeOneTrustSDK()
  if m.oneTrust = invalid
    m.oneTrust = CreateObject("roSGNode", "OTinitialize") 'bs:disable-line 1128
    m.global.Addfield("OTsdk", "node", false)
    ' Since One trust sdk access m.global.OTsdk within it's codebase we need to update the m.global.OTsdk to have the sdk instance.
    ' The reason why we are also storing it's reference in m scope for better performance since we access the sdk instance a lot of items during the app session.
    m.global.OTsdk = m.oneTrust
  else
    m.global.unobserveFieldScoped("_OT_initialize_data")
  end if

  sdkParams = m.oneTrust.callFunc("OTSdkParams")
  oneTrustConfig = m.constants.thirdParty.oneTrust
  sdkParams.applicationId = oneTrustConfig.applicationId
  sdkParams.version = oneTrustConfig.version
  sdkParams.location = oneTrustConfig.location
  sdkParams.language = m.constants.deviceInfo.language
  sdkParams.countryCode = m.constants.deviceInfo.countryCode

  identifier = "roku:" + m.constants.deviceInfo.deviceId
  sdkParams.shouldCreateProfile = true

  sdkParams.identifier = identifier
  sdkParams.identifierType = "DeviceID"
  m.oneTrust.callFunc("setDataSubjectIdentifier",{"subjectIdentifier": identifier})

  m.oneTrust.callFunc("initOTSDKData", sdkParams)
  m.oneTrust.callFunc("setupUI", { "view": m.top })
  tcfString = getTCFString()
  
  ' For performance reasons so that we can quickly show the homescreen.
  ' Since for guest user consent if we have locally stored consent we do not have to wait until one trust syncs the data from backend
  ' because we need to refresh registry consent with server data only for logged in user because there is a possibility of data been updated from other devices.
  if isNonEmptyString(tcfString)
    onOneTrustSDKInitializeComplete()
  else
    m.global.observeFieldScoped("_OT_initialize_data", "onOneTrustSDKInitializeComplete")
    ' Attaching a error callback so that for any reason OT SDK failed to initialize we still continue with app load with assumption that user did not grant access.
    m.oneTrust.observeFieldScoped("onHideFailure", "onOneTrustSDKInitializeComplete")
  end if
End Function


Function onOneTrustSDKInitializeComplete()
  m.trackingLoggingTask.userConsentsOptOutStatus = getConsentsOptOutStatus()
  if m.onGetConsentCompletionCallback <> invalid
    getConsentCompletionCallback = m.onGetConsentCompletionCallback
    m.onGetConsentCompletionCallback = invalid
    getConsentCompletionCallback()
  end if
  m.global.unobserveFieldScoped("_OT_initialize_data")
  m.oneTrust.unobserveFieldScoped("onHideFailure")
End Function


Function onGetConsentSuccess(response)
  m.consentSettings = response
  m.trackingLoggingTask.userConsentsOptOutStatus = getConsentsOptOutStatus()
  if m.onGetConsentCompletionCallback <> invalid
    getConsentCompletionCallback = m.onGetConsentCompletionCallback
    m.onGetConsentCompletionCallback = invalid
    getConsentCompletionCallback()
  end if
End Function


' @body: assocarray, contains a key value pair for ex: {"behavioral_advertising": opted_in, "essential_functionality": "required"}.
Function setConsent(body, onSetConsentCompletionCallback = invalid)
  m.onSetConsentCompletionCallback = onSetConsentCompletionCallback
  requestInfo = m.userDeviceApi.createPatchConsentReqInfo(body)
  m.makeRequest({
    url: requestInfo.url
    options: requestInfo.options
    requestType: m.constants.reqNames.patchConsent
    responseType: "assocarray"
    successCallback: onSetConsentSuccess
    silenceCallbackWarnings: true
  })

  index = 0
  ' Updating the local state consents variable with user selection.
  ' Below data will be used in the settings privacy center or across the application to determine flow based on user consent.
  consents = m.consentSettings.consents
  for each consent in consents
    if isNonEmptyString(body[consent.key]) = true
      consents[index].value = body[consent.key]
    end if
    index++
  end for

  ' Updating back consents into the m scope variable defined in content controller.
  m.consentSettings.consents = consents

  ' Updating the consent status.
  m.trackingLoggingTask.userConsentsOptOutStatus = getConsentsOptOutStatus()

  ' Checking if the marketing consent preference was changed.
  marketingConsentKey = m.constants.consentKeys.marketing
  if isNonEmptyString(body[marketingConsentKey]) = true
    if getConsentOptOutStatusByKey(marketingConsentKey) = true
      stopBrazeTask()
    end if
  end if

  ' Checking if the continueWatching consent preference was changed.
  continueWatchingConsentKey = m.constants.consentKeys.continueWatching
  if isNonEmptyString(body[continueWatchingConsentKey]) = true
    if getConsentOptOutStatusByKey(continueWatchingConsentKey) = true
      clearRokuContinueWatching()
    end if
  end if
End Function


Function showManagePreferenceScreen(consents)
  screen = CreateObject("roSGNode", "ManagePreferencesScreen")
  screen.consents = consents
  pushScreen(screen, true, true)
  screen.observeFieldScoped("selectedPreferenceInfo", "onSelectedPreferenceInfoChange")
  screen.observeFieldScoped("selectedConsents", "onManagePreferenceSaveAndContinueSelected")
  screen.setFocus(true)
End Function


Function onSelectedPreferenceInfoChange(msg)
  selectedConsent = msg.getData()
  screen = msg.getRoSGNode()

  ' Since this callback is triggered when user toggle a non required preference option it will always have one key/value pair.
  ' ex: {"behavioral_advertising": "opted_in"}
  ' Getting the first key and getting value from it.
  keys = selectedConsent.keys()
  value = selectedConsent[keys[0]]

  if value <> "required"
    userInteractionValue = invalid
    if value = "opted_out"
      userInteractionValue = "TOGGLE_OFF"
    else if value = "opted_in"
      userInteractionValue = "TOGGLE_ON"
    end if

    if userInteractionValue <> invalid
      consentKey = keys[0]
      ' As a safety check if we have a mapping value for the consent key if not falling back to backend key.
      buttonValue = m.Tracking.getConsentAnalyticValue(consentKey)

      componentValues = {
        button_type: "TOGGLE"
        button_value: buttonValue
      }
      pageValues = screen.trackingPageInfo.pageValues
      pageOneof = m.Tracking.getAnalyticsPage(screen.trackingPageInfo.pageType, pageValues)
      componentOneof = m.Tracking.getAnalyticsComponent("button_component", componentValues)

      componentInteractionEvent =  {
        pageOneof: pageOneof
        componentOneof: componentOneof
        user_interaction: userInteractionValue
      }
      m.trackingLoggingTask.trackEvent = {
        type: "component_interaction"
        values: componentInteractionEvent
      }
    end if
  else
    showRequiredPreferenceToast(keys[0])
  end if
End Function


Function onManagePreferenceSaveAndContinueSelected(msg)
  screen = msg.getRoSGNode()
  selectedConsents = screen.selectedConsents

  ' Checking if the selectedConsents is nonempty aa.
  if selectedConsents <> invalid AND selectedConsents.keys().count() > 0
    setConsent(selectedConsents)
  else
    ' This logic will handle the case where user decided not change anything. So we are making a call to backend with default values as it is returned from backend.
    ' So if backend retuned default value opt_in than we pass opt_in if backend pass default opt_out we pass opt_out.
    ' This is needed so that backend is aware that user gave us consent.
    body = {}
    for each consent in m.consentSettings.consents
      if consent.isRequired = false AND consent.key <> invalid
        body[consent.key] = consent.value
      end if
    end for
    setConsent(body)
  end if

  proceedAfterConsentUpdated()
End Function


Function onSetConsentSuccess(_response)
  if m.onSetConsentCompletionCallback <> invalid
    setConsentCompletionCallback = m.onSetConsentCompletionCallback
    m.onSetConsentCompletionCallback = invalid
    setConsentCompletionCallback()
  end if
End Function


Function onInitialGetConsentRequestComplete()
  if isGDPR(m.constants) = true
    consentRequired = isUserConsentRequired()
    ' Calling getConsents api so that we have the data ready whenever we are ready to calling startUserExperience or showConsentScreen method.
    if consentRequired = true AND isUserInAdultsMode() = true AND isKidsUIOn() = false
      showConsentScreen()
    else
      m.isConsentCheckComplete = true
      startUserExperience()
    end if
  else
    m.isConsentCheckComplete = true
    startUserExperience()
  end if
End Function


Function proceedAfterConsentUpdated()
  m.oneTrust.unObserveFieldScoped("AcceptAll")
  m.oneTrust.unObserveFieldScoped("RejectAll")
  m.oneTrust.unObserveFieldScoped("onHideBanner")
  m.oneTrust.unObserveFieldScoped("onHideFailure")
  m.isConsentCheckComplete = true
  if m.callbackAfterConsent <> invalid
    callbackAfterConsent = m.callbackAfterConsent
    m.callbackAfterConsent = invalid
    callbackAfterConsent()
  else
    startUserExperience()
  end if
End Function


' Will return true or false based on if the user opted out of the consent item.
' @key: string, contains a key for the consent item. ex: behavioral_advertising|analytics etc.
Function getConsentOptOutStatusByKey(key)
  didOptOut = false

  ' Proceeding with consent check only if key is not essential. Since if it is essential we are allowed to proceed in kids etc.
  if key <> m.constants.consentKeys.essential
    if isGDPR(m.constants) = true
      didOptOut = (m.oneTrust.callFunc("getConsentStatusForGroupID", key) <> 1)
    else
      ' Irrespective of whether user as opted in or opted out when we are in non adult mode we should treat has if user opted out.
      isUserAllowedToManageConsent = isUserAllowedToManageConsent()
      if m.consentSettings <> invalid AND isUserAllowedToManageConsent = true AND m.consentSettings.consents <> invalid
        for each consent in m.consentSettings.consents
          if consent.key = key
            didOptOut = (consent.value = "opted_out")
            exit for
          end if
        end for
      else
        ' If m.consentSettings is invalid that means the request to get consent failed so we are treating it has opted_out for the session.
        didOptOut = true
      end if
    end if
  end if
  
  return didOptOut
End Function


Function isUserAllowedToManageConsent()
  ' Since we have country specific Kids age. For ex: In GDPR countries less than 18 is kids.
  ' Since outside of GDPR countries it is less than 13 is considered as kids mode. We will not create seperate mapping.
  isUserAllowedToManageConsent = (isUserInAdultsMode() = true OR isParentalControlsTeensLevel() = true)

  if isGDPR(m.constants) = true
    isUserAllowedToManageConsent = (isUserInAdultsMode() = true)
  end if

  ' If the kids mode UI is on than user is not allowed to manage consent.
  if isKidsUIOn() = true
    isUserAllowedToManageConsent = false
  end if

  return isUserAllowedToManageConsent
End Function


' Returns a assocarray with key as the consent key returned from backend and a boolean value which indicates the consent status for the key. ex: {"analytics": true, "marketing": false}
Function getConsentsOptOutStatus()
  consentsStatus = {}

  isUserAllowedToManageConsent = isUserAllowedToManageConsent()
  if isUserAllowedToManageConsent = true
    consentKeys = m.constants.consentKeys
    for each key in consentKeys
      consentsStatus[consentKeys[key]] = getConsentOptOutStatusByKey(consentKeys[key])
    end for
  end if
  
  return consentsStatus
End Function


' Returns true or false based on which we will decide if we need to show the consent screen or not.
' It will return false if user has already provided consent(either accepted or rejected).
Function isUserConsentRequired()
  consentRequired = false
  if isGDPR(m.constants) = true
    consentRequired = m.oneTrust.callFunc("shouldShowBanner")
  else
    if m.consentSettings <> invalid AND m.consentSettings.consentRequired = true
      consentRequired = true
    end if
  end if

  return consentRequired
End Function


' Creating a wrapper so that it is easier to switch to not use global and use some other method easily.
Function getTCFString()
  return m.global.IABTCF_TCString
End Function

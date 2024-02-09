Function showConsentScreen(callback = startUserExperience)
  m.callbackAfterConsent = callback
  showContentGroupAndHideSpinner()
  screen = CreateObject("roSGNode", "ConsentScreen")
  screen.description = m.consentSettings.privacyDescription
  pushScreen(screen, true, true)
  screen.observeFieldScoped("buttonSelected", "onConsentActionButtonSelected")
  screen.setFocus(true)
End Function


Function onConsentActionButtonSelected(msg)
  buttonSelected = msg.getData()

  if buttonSelected <> m.constants.ui.consentActionButtonIds.manage
    consents = m.consentSettings.consents

    optValue = "opted_in"
    buttonValue = "ACCEPT_ALL_CONSENTS"
    if buttonSelected = m.constants.ui.consentActionButtonIds.reject
      optValue = "opted_out"
      buttonValue = "REJECT_ALL_CONSENTS"
    end if

    if isNonEmptyArray(consents)
      body = {}
      ' Looping through the consents array and updating all non required preferences key to the user selected optValue.
      ' Sample data. [{"key": "behavioral_advertising","subtitle": "Tubi may use your information to make inferences and predict your potential areas of interest.","title": "Targeted Advertising","value": "required", "isRequired": true}]
      for each consent in consents
        if consent.isRequired = false AND consent.key <> invalid
          body[consent.key] = optValue
        end if
      end for

      setConsent(body)
    end if

    screen = msg.getRoSGNode()
    componentValues = {
      button_type: "TEXT"
      button_value: buttonValue
    }
    pageOneof = m.Tracking.getAnalyticsPage(screen.trackingPageInfo.pagetype, screen.trackingPageInfo.pageValues)
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

    proceedAfterConsentUpdated()
  else
    showManagePreferenceScreen(m.consentSettings.consents)
  end if
End Function


Function getConsent(onGetConsentCompletionCallback = invalid)
  m.onGetConsentCompletionCallback = onGetConsentCompletionCallback
  requestInfo = m.userDeviceApi.createGetConsentReqInfo()
  m.makeRequest({
    url: requestInfo.url
    options: requestInfo.options
    requestType: m.constants.reqNames.getConsent
    successCallback: onGetConsentSuccess
    responseType: "assocarray"
    silenceCallbackWarnings: true
  })
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


Function onSetConsentSuccess(response)
  if m.onSetConsentCompletionCallback <> invalid
    setConsentCompletionCallback = m.onSetConsentCompletionCallback
    m.onSetConsentCompletionCallback = invalid
    setConsentCompletionCallback()
  end if
End Function


Function onInitialGetConsentRequestComplete()
  ' Calling getConsents api so that we have the data ready whenever we are ready to calling startUserExperience or showConsentScreen method.
  if m.consentSettings <> invalid AND m.consentSettings.consentRequired = true AND isUserInAdultsMode() = true AND isKidsUIOn() = false
    showConsentScreen()
  else
    m.isConsentCheckComplete = true
    startUserExperience()
  end if
End Function


Function proceedAfterConsentUpdated()
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

  ' Please do not remove the isUserInAdultsMode check since we are legally bound to not use parental consent when the user is not in adults mode.
  ' Irrespective of whether user as opted in or opted out when we are in non adult mode we should treat has if user opted out.
  isUserAllowedToManageConsent = isUserAllowedToManageConsent()
  if m.consentSettings <> invalid AND isUserAllowedToManageConsent = true
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
  if m.consentSettings <> invalid AND isUserAllowedToManageConsent = true
    for each consent in m.consentSettings.consents
      consentsStatus[consent.key] = (consent.value = "opted_out")
    end for
  end if

  return consentsStatus
End Function

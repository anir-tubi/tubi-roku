Function init()
  topRef = m.top
  m.constants = getConstantsFromGlobal()
  topRef.observeFieldScoped("focusedChild", "onScreenFocusChange")

  m.heading = topRef.findNode("heading")
  m.heading.text = getTranslation("privacy_preferences_label")

  m.managePreferences = topRef.findNode("managePreferences")
  m.managePreferences.itemSize = [1374, 141]
  m.managePreferences.rowHeights = [141]
  m.managePreferences.subHeaderWidth = 1122
  m.managePreferences.totalWidth = 1374
  m.managePreferences.observeFieldScoped("selectedConsent", "onSelectedConsentChange")

  m.saveAndContinueBtn = topRef.findNode("saveAndContinueBtn")
  m.saveAndContinueBtn.text = getTranslation("privacy_preferences_save_continue_button")
  m.saveAndContinueBtn.observeFieldScoped("selected", "onSaveAndContinueBtnSelected")

  background = topRef.findNode("background")
  background.uri = m.constants.ui.uris.marketingBackground

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
  onThemeChange()

  ' assoc array to be passed to setConsent ex: {"behavioral_advertising": "opted_in", "essential_functionality": "required"}.
  m.selectedConsents = {}
  topRef.id = m.constants.ui.screenIds.managePreferencesScreen
  topRef.screenLevel = m.constants.ui.screenLevels.managePreferencesScreen
  topRef.trackingPageInfo = {
    pageType: "privacy_preferences_page"
    pageValues: {}
  }
End Function


Function onScreenFocusChange()
  setTranslations()
  if m.top.hasFocus() = true
    m.managePreferences.setFocus(true)
  end if
End Function


Function setTranslations()
  heading = m.heading.boundingRect()
  itemSpacing = 32
  m.managePreferences.translation = [0, heading.height + itemSpacing]
  managePreferences = m.managePreferences.boundingRect()
  m.saveAndContinueBtn.translation = [0, managePreferences.height + managePreferences.y + itemSpacing]
End Function


Function onSelectedConsentChange(msg)
  selectedConsent = msg.getData()

  ' Avoiding updating the selectedConsents since we do not have to update backend that user selected required item, but just show the toast.
  key = selectedConsent.keys()[0]
  if selectedConsent[key] <> "required"
    m.selectedConsents.append(selectedConsent)
  end if
  m.top.selectedPreferenceInfo = selectedConsent
End Function


Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.heading.color = theme.primaryTextColor
  end if
End Function


Function onSaveAndContinueBtnSelected(msg)
  m.top.selectedConsents = m.selectedConsents
End Function


Function onKeyEvent(key as String, press as Boolean) as Boolean
  tubiLog("ManagePreferencesScreen.onKeyEvent key = " + key)

  handled = false
  if press then

    if key = "up"

      if m.saveAndContinueBtn.hasFocus() = true
        m.managePreferences.setFocus(true)
        handled = true
      end if

    else if key = "down"

      if m.managePreferences.isInFocusChain() = true
        m.saveAndContinueBtn.setFocus(true)
        handled = true
      end if

    end if
  end if

  return handled
End Function

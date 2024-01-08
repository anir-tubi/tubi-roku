Function init()
  topRef = m.top
  m.constants = getConstantsFromGlobal()
  topRef.observeFieldScoped("focusedChild", "onScreenFocusChange")

  m.heading = topRef.findNode("Heading")
  topRef.observeFieldScoped("consentSettings", "onConsentSettingsChange")

  m.managePreferences = topRef.findNode("ManagePreferences")
  m.managePreferences.itemSize = [1140, 141]
  m.managePreferences.rowHeights = [141]
  m.managePreferences.subHeaderWidth = 882
  m.managePreferences.totalWidth = 1140

  m.qrCodeSections = topRef.findNode("qrCodeSections")
  m.qrCodeSections.observeFieldScoped("focusedIndex", "onFocusedIndexChange")
  m.panelContentSection = topRef.findNode("panelContentSection")
  m.heading = topRef.findNode("heading")

  m.nonEditableModeWarningMessage = topRef.findNode("nonEditableModeWarningMessage")
  m.nonEditableModeWarningMessage.text = getTranslation("privacy_center_not_editable_mode_warning")

  m.saveAndContinueButton = topRef.findNode("saveAndContinueButton")
  m.saveAndContinueButton.text = getTranslation("privacy_center_save_restart")

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
  onThemeChange()
End Function


Function onScreenFocusChange()
  if m.top.hasFocus() = true
    if m.top.isAllowedToManageConsent = true AND isNonEmptyArray(m.top.consentSettings.consents) = true
      m.managePreferences.setFocus(true)
      slideTo(m.panelContentSection, [0, -m.heading.translation[1]], 0.5)
    else
      m.qrCodeSections.setFocus(true)
    end if
  end if
End Function


Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.heading.color = theme.primaryTextColor
    m.nonEditableModeWarningMessage.color = theme.cautionColor
  end if
End Function


Function onConsentSettingsChange(msg)
  consentSettings = msg.getData()
  privacyCenterSettings = consentSettings.privacyCenterSettings

  if privacyCenterSettings.showConsentPreferences = true AND m.top.isAllowedToManageConsent = true
    m.managePreferences.consents = consentSettings.consents
  end if

  if privacyCenterSettings.showPrivacyPolicy = true
    renderQrCodeComponent({
      heading: getTranslation("privacy_preferences_privacy_section_heading")
      subheading: getTranslation("privacy_preferences_privacy_section_subheading") + privacyCenterSettings.privacyPolicyUrl
      qrCodePosterUrl: privacyCenterSettings.privacyPolicyQrCodeUrl
    })
  end if

  if privacyCenterSettings.showDsar = true
    renderQrCodeComponent({
      heading: getTranslation("privacy_preferences_dsar_section_heading")
      subheading: getTranslation("privacy_preferences_dsar_section_subheading") + privacyCenterSettings.dsarUrl
      qrCodePosterUrl: privacyCenterSettings.dsarQrCodeUrl
    })
  end if

  if privacyCenterSettings.showTermsOfUse = true
    renderQrCodeComponent({
      heading: getTranslation("privacy_preferences_tos_section_heading")
      subheading: getTranslation("privacy_preferences_tos_section_subheading") + privacyCenterSettings.termsOfUseUrl
      qrCodePosterUrl: privacyCenterSettings.termsOfUseQrCodeUrl
    })
  end if

  if privacyCenterSettings.showConsentPreferences = true AND m.top.isAllowedToManageConsent = false
    m.qrCodeSections.translation = [0, 177]
    m.nonEditableModeWarningMessage.visible = true
    m.saveAndContinueButton.visible = false
  else
    m.nonEditableModeWarningMessage.visible = false
    ' Since if we place an array grid inside a layout group, it causes a jumping UI glitch when the grid is focused.
    ' To Avoid the UI issue we can manually adjust the position of the items based on the predecessor instead of using the LayoutGroup.
    boundingRect = m.managePreferences.boundingRect()
    translation = m.managePreferences.translation

    buttonRect = m.saveAndContinueButton.boundingRect()
    buttonTranslationY = boundingRect.height + translation[1]

    ' By Default array grid adds some additional padded value when we call bounding rect. To account for that additional padded value we are subtracting 24.
    saveAndContinueButtonTranslationY = buttonTranslationY - 24
    ' Adjusting the position of save and continue button based on manage preferences section height.
    m.saveAndContinueButton.translation = [0, saveAndContinueButtonTranslationY]

    ' Getting the total height of array grid and adding the y translation to place the qr codes.
    qrCodeSectionTranslationY = buttonTranslationY + buttonRect.height + 15
    m.qrCodeSections.translation = [0, qrCodeSectionTranslationY]

    if privacyCenterSettings.showConsentPreferences = true AND m.top.isAllowedToManageConsent = true
      m.saveAndContinueButton.visible = true
    end if
  end if
End Function


' Creates a QR Code Child Component and appends it to the m.qrCodeSections FocusControlLayoutGroup.
Function renderQrCodeComponent(content)
  qrCodeSection = CreateObject("roSGNode", "QRCodeSection")
  qrCodeSection.update({
    heading: content.heading
    subheading: content.subheading
    qrCodePosterUrl: content.qrCodePosterUrl
  })
  qrCodeSection.observeFieldScoped("qrCodeSelected", "onQrCodeSelected")
  m.qrCodeSections.appendChild(qrCodeSection)
End Function


Function onQrCodeSelected(msg)
  section = msg.getRoSGNode()
  m.top.selectedQrCodeSectionInfo = {
    heading: section.heading
  }
End Function


Function onFocusedIndexChange(msg)
  if m.qrCodeSections.componentGainingFocus <> invalid
    ' Getting the translation of the item that gained focus within the layout group.
    translation = m.qrCodeSections.componentGainingFocus.translation
    ' adjusting the position of the panel content section as per below logic.
    ' We are get the parent y position and adding the focused child within the layout groups y position.
    ' And moving up the translation of the content section.
    slideTo(m.panelContentSection, [0, -(m.qrCodeSections.translation[1] + translation[1])], 0.5)
  end if
End Function


Function onKeyEvent(key as String, press as Boolean) as Boolean
  handled = false
  if press then
    if key = "up"
      if m.qrCodeSections.isInFocusChain() = true AND m.top.isAllowedToManageConsent = true AND isNonEmptyArray(m.top.consentSettings.consents) = true
        m.saveAndContinueButton.setFocus(true)
        slideTo(m.panelContentSection, [0, -m.heading.translation[1]], 0.5)
        handled = true
      else if m.saveAndContinueButton.isInFocusChain() = true
        m.managePreferences.setFocus(true)
        handled = true
      end if
    else if key = "down"
      if m.managePreferences.isInFocusChain() = true
        m.saveAndContinueButton.setFocus(true)
        handled = true
      else if m.saveAndContinueButton.isInFocusChain() = true
        m.qrCodeSections.setFocus(true)
        slideTo(m.panelContentSection, [0, -m.qrCodeSections.translation[1]], 0.5)
        handled = true
      end if
    end if
  end if

  return handled
End Function

Function init()
  topRef = m.top
  m.constants = getConstantsFromGlobal()
  topRef.observeFieldScoped("focusedChild", "onScreenFocusChange")

  m.heading = topRef.findNode("Heading")
  topRef.observeFieldScoped("consentSettings", "onConsentSettingsChange")
  topRef.observeFieldScoped("isAllowedToManageConsent", "onIsAllowedToManageConsentChange")

  m.managePrivacySettingsButton = topRef.findNode("managePrivacySettingsButton")
  m.managePrivacySettingsButton.text = getTranslation("privacy_center_view_privacy_settings")
  m.viewPrivacySettingsHint = topRef.findNode("viewPrivacySettingsHint")
  m.viewPrivacySettingsHint.text = getTranslation("privacy_center_view_privacy_settings_hint")

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

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.heading, typographyConstants.ids.headerSmall)
  setTypographyOfLabel(m.nonEditableModeWarningMessage, typographyConstants.ids.bodyMedium)
  setTypographyOfLabel(m.viewPrivacySettingsHint, typographyConstants.ids.bodyMedium)

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if

  renderTOSPrivacyPolicyQrCodeSection()

  onThemeChange()
End Function


Function onScreenFocusChange()
  if m.top.hasFocus() = true
    if m.top.isAllowedToManageConsent = true AND m.top.consentSettings <> invalid AND isNonEmptyArray(m.top.consentSettings.consents) = true
      m.managePreferences.setFocus(true)
      slideTo(m.panelContentSection, [0, -m.heading.translation[1]], 0.5)
    else if isGDPR(m.constants) = true
      m.managePrivacySettingsButton.setFocus(true)
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
    m.viewPrivacySettingsHint.color = theme.secondaryTextColor
  end if
End Function


Function onConsentSettingsChange(msg)
  consentSettings = msg.getData()
  privacyCenterSettings = consentSettings.privacyCenterSettings

  if privacyCenterSettings <> invalid
    if privacyCenterSettings.showConsentPreferences = true AND m.top.isAllowedToManageConsent = true
      m.managePreferences.consents = consentSettings.consents
      m.managePrivacySettingsButton.visible = false
    end if

    if privacyCenterSettings.showConsentPreferences = true AND m.top.isAllowedToManageConsent = false
      m.qrCodeSections.translation = [0, 177]
      m.nonEditableModeWarningMessage.visible = true
      m.saveAndContinueButton.visible = false
    else
      m.nonEditableModeWarningMessage.visible = false
      ' Since if we place an array grid inside a layout group, it causes a jumping UI glitch when the grid is focused.
      ' To Avoid the UI issue we can manually adjust the position of the items based on the predecessor instead of using the LayoutGroup.
      managePrefsRect = m.managePreferences.boundingRect()
      managePrefsTranslation = m.managePreferences.translation

      ' By Default array grid adds some additional padded value when we call bounding rect. To account for that additional padded value we are subtracting 24.
      yTranslationOfItemAfterManagePrefs = managePrefsRect.height + managePrefsTranslation[1] - 24

      buttonRectHeight = 0
      if privacyCenterSettings.showConsentPreferences = true AND m.top.isAllowedToManageConsent = true AND isGdpr(m.constants) = true
        m.saveAndContinueButton.visible = true
        buttonRectHeight = m.saveAndContinueButton.boundingRect().height

        ' Adjusting the position of save and continue button based on manage preferences section height.
        m.saveAndContinueButton.translation = [0, yTranslationOfItemAfterManagePrefs]
      end if

      ' Getting the total height of array grid and adding the y translation to place the qr codes.
      qrCodeSectionTranslationY = yTranslationOfItemAfterManagePrefs + buttonRectHeight + 15
      m.qrCodeSections.translation = [0, qrCodeSectionTranslationY]
    end if

    m.managePreferences.visible = true
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


Function onFocusedIndexChange()
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
      if m.qrCodeSections.isInFocusChain() = true AND m.top.isAllowedToManageConsent = true
        if m.top.consentSettings <> invalid AND isNonEmptyArray(m.top.consentSettings.consents) = true
          if m.saveAndContinueButton.visible = true
            m.saveAndContinueButton.setFocus(true)
          else
            m.managePreferences.setFocus(true)
          end if
        else if isGDPR(m.constants) = true
          m.managePrivacySettingsButton.setFocus(true)
        end if

        slideTo(m.panelContentSection, [0, -m.heading.translation[1]], 0.5)
        handled = true
      else if m.saveAndContinueButton.isInFocusChain() = true
        m.managePreferences.setFocus(true)
        handled = true
      end if
    else if key = "down"
      if m.managePreferences.isInFocusChain() = true
        if m.saveAndContinueButton.visible = true
          m.saveAndContinueButton.setFocus(true)
        else
          m.qrCodeSections.setFocus(true)
          slideTo(m.panelContentSection, [0, -m.qrCodeSections.translation[1]], 0.5)
        end if

        handled = true
      else if m.saveAndContinueButton.isInFocusChain() = true OR m.managePrivacySettingsButton.isInFocusChain() = true
        m.qrCodeSections.setFocus(true)
        slideTo(m.panelContentSection, [0, -m.qrCodeSections.translation[1]], 0.5)
        handled = true
      end if
    end if
  end if

  return handled
End Function


Function onIsAllowedToManageConsentChange(msg)
  if msg.getData() = true AND isGDPR(m.constants) = true
    m.managePrivacySettingsButton.visible = true
    m.nonEditableModeWarningMessage.visible = false
    m.viewPrivacySettingsHint.visible = true
    updateQRCodeSectionsTranslation()
  end if
End Function


' Updates the position of QR Code Section so that it appears below the manage privacy settings button.
Function updateQRCodeSectionsTranslation()
  boundingRect = m.managePrivacySettingsButton.boundingRect()
  translationY = boundingRect.height + boundingRect.y + 24
  m.qrCodeSections.translation = [0, translationY]
End Function


' Renders tos and privacy policy qr codes.
Function renderTOSPrivacyPolicyQrCodeSection()
  externalConfig = getExternalConfigInfoFromGlobal()

  if externalConfig <> invalid
    if isNonEmptyString(externalConfig.privacy_policy_qr_code_url) = true
      renderQrCodeComponent({
        heading: getTranslation("privacy_preferences_privacy_section_heading")
        subheading: getTranslation("privacy_preferences_privacy_section_subheading") + externalConfig.privacy_policy_url
        qrCodePosterUrl: externalConfig.privacy_policy_qr_code_url
      })
    end if

    if isNonEmptyString(externalConfig.terms_of_use_qr_code_url) = true
      renderQrCodeComponent({
        heading: getTranslation("privacy_preferences_tos_section_heading")
        subheading: getTranslation("privacy_preferences_tos_section_subheading") + externalConfig.terms_of_use_url
        qrCodePosterUrl: externalConfig.terms_of_use_qr_code_url
      })
    end if
  end if
End Function

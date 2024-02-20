' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @_reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseGetConsent(fullResponse, _reqInfo)
  consentSettings = {

    ' Boolean flag which indicates whether to show the consent screen or not.
    consentRequired: false

    ' Privacy description text which will be shown in initial consent screen.
    privacyDescription: ""

    ' Below default values are based on current US defaults in case request fails.
    privacyCenterSettings: {

      ' whether we need to show consent preferences component.
      showConsentPreferences: false

      ' whether we need to show privacy policy QR code component.
      showPrivacyPolicy: true

      ' whether we need to show DSAR QR code component.
      showDsar: false

      ' QRCode url for the privacy policy is used for displaying in privacy center.
      privacyPolicyQrCodeUrl: ""

      ' whether we need to show terms of use QR code component.
      showTermsOfUse: false

      ' QRCode url for the terms of use used for displaying in privacy center.
      termsOfUseQrCodeUrl: ""

      ' web link for the terms of use used for displaying in privacy center.
      termsOfUseUrl: ""

      ' privacy policy web link used for displaying in privacy center.
      privacyPolicyUrl: ""

      ' DSAR web link used for displaying in privacy center.
      dsarUrl: ""
    },

    ' Holds the list of preferences which will be used for displaying in manage preferences screen.
    ' Sample: [{"title": "Analytics","subtitle": "","key": "analytics","value": "required"}]
    consents: []
  }

  data = fullResponse.data

  consents = []
  if isAA(data) = true

    if data.consent_required <> invalid
      consentSettings.consentRequired = data.consent_required
    end if

    if data.privacy_description <> invalid
      consentSettings.privacyDescription = data.privacy_description
    end if

    ' Updating privacy center settings.
    privacyCenterSettings = data.privacy_center_settings
    if privacyCenterSettings <> invalid
      consentSettings.privacyCenterSettings = {
        showConsentPreferences: privacyCenterSettings.consent_preferences
        showPrivacyPolicy: privacyCenterSettings.privacy_policy
        showDsar: privacyCenterSettings.dsar
        privacyPolicyQrCodeUrl: privacyCenterSettings.privacy_policy_qr_code_url
        showTermsOfUse: privacyCenterSettings.terms_of_use
        termsOfUseQrCodeUrl: privacyCenterSettings.terms_of_use_qr_code_url
        termsOfUseUrl: privacyCenterSettings.terms_of_use_url
        dsarUrl: privacyCenterSettings.dsar_url
        privacyPolicyUrl: privacyCenterSettings.privacy_policy_url
      }
    end if

    ' Looping through individual consent preferences and creating a list of consents.
    if data.consents <> invalid
      for each item in data.consents

        ' Making sure to ignore any consent that does not have valid data.
        if item.title <> invalid AND item.key <> invalid AND item.subtitle <> invalid
          consent = {
            key: item.key
            subtitle: item.subtitle
            title: item.title

            ' Possible options are opted_in, opted_out, required
            value: item.value
            isRequired: (item.value = "required")
          }
          consents.push(consent)
        end if
      end for
    end if
  end if

  consentSettings.consents = consents

  return consentSettings
End Function

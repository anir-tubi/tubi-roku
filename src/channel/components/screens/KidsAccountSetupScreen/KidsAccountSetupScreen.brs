Function init()
  m.constants = getConstantsFromGlobal()

  ' Find all UI nodes
  m.pageHeading = m.top.findNode("pageHeading")
  m.subHeading = m.top.findNode("subHeading")
  m.digitLabel = m.top.findNode("digitLabel")
  m.startWatchingButton = m.top.findNode("startWatchingButton")
  m.profileMenu = m.top.findNode("ProfileMenu")

  ' Adult Account field
  m.adultAccountField = m.top.findNode("adultAccountField")
  m.adultAccountLabel = m.top.findNode("adultAccountLabel")
  m.adultAccountIcon = m.top.findNode("adultAccountIcon")
  m.adultAccountValue = m.top.findNode("adultAccountValue")
  m.adultAccountDescription = m.top.findNode("adultAccountDescription")

  ' Kid's First Name field
  m.kidFirstNameField = m.top.findNode("kidFirstNameField")
  m.kidFirstNameLabel = m.top.findNode("kidFirstNameLabel")
  m.kidFirstNameValue = m.top.findNode("kidFirstNameValue")

  ' Content Setting field
  m.contentSettingField = m.top.findNode("contentSettingField")
  m.contentSettingLabel = m.top.findNode("contentSettingLabel")
  m.contentSettingValue = m.top.findNode("contentSettingValue")

  ' PIN field
  m.pinField = m.top.findNode("pinField")
  m.pinLabel = m.top.findNode("pinLabel")
  m.pinDescription = m.top.findNode("pinDescription")

  ' Profile preview
  m.profileAvatar = m.top.findNode("profileAvatar")

  ' Terms text
  m.termsText = m.top.findNode("termsText")

  ' Set up terms text with privacy disclaimer
  externalConfig = getExternalConfigInfoFromGlobal()
  ' Format the terms text to match Figma design
  m.termsText.text = getTranslation("kidsAccountSetup_termsText", { "url1": externalConfig.terms_of_use_url, "url2": externalConfig.privacy_policy_url })

  ' Set up text content
  m.pageHeading.text = getTranslation("kidsAccountSetup_pageHeading")
  m.subHeading.text = getTranslation("kidsAccountSetup_subHeading")
  m.startWatchingButton.text = getTranslation("kidsAccountSetup_startWatchingButton")

  m.adultAccountLabel.text = getTranslation("kidsAccountSetup_adultAccountLabel")
  m.adultAccountDescription.text = getTranslation("kidsAccountSetup_adultAccountDescription")
  m.kidFirstNameLabel.text = getTranslation("kidsAccountSetup_kidFirstNameLabel")
  m.contentSettingLabel.text = getTranslation("kidsAccountSetup_contentSettingLabel")
  m.pinLabel.text = getTranslation("screenSettings_parentalControls_pinLabel")
  m.pinDescription.text = getTranslation("kidsAccountSetup_pinDescription")

  ' Set up typography
  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.pageHeading, typographyConstants.ids.headerLarge)
  setTypographyOfLabel(m.subHeading, typographyConstants.ids.bodyMedium)
  setTypographyOfLabel(m.adultAccountLabel, typographyConstants.ids.bodyExtraSmall)
  setTypographyOfLabel(m.adultAccountValue, typographyConstants.ids.bodyMedium)
  setTypographyOfLabel(m.adultAccountDescription, typographyConstants.ids.bodyExtraSmall)
  setTypographyOfLabel(m.kidFirstNameLabel, typographyConstants.ids.bodyExtraSmall)
  setTypographyOfLabel(m.kidFirstNameValue, typographyConstants.ids.bodyMedium)
  setTypographyOfLabel(m.contentSettingLabel, typographyConstants.ids.bodyExtraSmall)
  setTypographyOfLabel(m.contentSettingValue, typographyConstants.ids.bodyMedium)
  setTypographyOfLabel(m.pinLabel, typographyConstants.ids.bodyMedium)
  setTypographyOfLabel(m.pinDescription, typographyConstants.ids.bodyExtraSmall)
  setTypographyOfLabel(m.termsText, typographyConstants.ids.bodySmall)
  setTypographyOfLabel(m.startWatchingButton, typographyConstants.ids.bodyMediumStrong)
  setTypographyOfLabel(m.digitLabel, typographyConstants.ids.bodyLargeStrong)

  ' Set up observers
  m.top.observeFieldScoped("focusedChild", "onScreenFocusChange")
  m.top.observeFieldScoped("signInInfo", "onSignInInfoChange")
  m.top.observeFieldScoped("parentProfile", "onParentProfileChange")
  m.startWatchingButton.observeFieldScoped("selected", "onStartWatchingButtonSelected")

  'set initial tracking values
  m.top.trackingPageInfo = {
    pageType: "register_page"
    pageValues: {
      auth_method: "CLICKED_REGISTER"
    }
  }

  m.top.screenLevel = m.constants.ui.screenLevels.emailInputScreen
  m.top.isStackable = true
  m.top.instantResumeAction = m.constants.instantResumeActions.startChannel

  m.backgroundUriList = []
  m.pinText = ""
  m.currentPinFocus = 0

  ' Set up theme
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
    m.pageHeading.color = theme.primaryTextColor
    m.subHeading.color = theme.secondaryTextColor
    m.adultAccountLabel.color = theme.tertiaryTextColor
    m.adultAccountValue.color = theme.primaryTextColor
    m.adultAccountField.color = theme.neutralColor
    m.adultAccountDescription.color = theme.primaryTextColor
    m.kidFirstNameLabel.color = theme.tertiaryTextColor
    m.kidFirstNameValue.color = theme.primaryTextColor
    m.kidFirstNameField.color = theme.neutralColor
    m.contentSettingLabel.color = theme.tertiaryTextColor
    m.contentSettingValue.color = theme.primaryTextColor
    m.contentSettingField.color = theme.neutralColor
    m.pinLabel.color = theme.tertiaryTextColor
    m.pinDescription.color = theme.primaryTextColor
    m.pinField.color = theme.neutralColor
    m.termsText.color = theme.secondaryTextColor
    m.startWatchingButton.color = theme.backgroundColorLight
    m.digitLabel.color = theme.primaryTextColor
  end if

End Function


Function onScreenFocusChange()
  if m.top.hasFocus() = true
    ' Force a background update
    m.top.backgroundUriList = m.backgroundUriList
    m.startWatchingButton.setFocus(true)

  end if
End Function


Function onSignInInfoChange(msg)
  signInInfo = msg.getData()
  if signInInfo <> invalid
    ' Update kid's first name if available
    if isNonEmptyString(signInInfo.name) = true
      kidName = signInInfo.name
      if isNonEmptyString(kidName) = true
        m.kidFirstNameValue.text = kidName
        ' Update profile avatar with initial
        menuContent = createObject("roSGNode", "ContentNode")
        menuItem = createObject("roSGNode", "ContentNode")
        menuItem.id = signInInfo.tubiId
        avatarUrls = signInInfo.avatar_url
        if avatarUrls <> invalid AND avatarUrls.medium <> invalid
          menuItem.HDPosterUrl = avatarUrls.medium["2x"]
        end if
        ' Unfortunatly kids profiles will have only name and not first name.
        if isNonEmptyString(signInInfo.firstName) = true
          menuItem.title = signInInfo.firstName.left(1)
        else if isNonEmptyString(signInInfo.name) = true
          menuItem.title = signInInfo.name.left(1)
        end if

        menuItem.shortDescriptionLine1 = signInInfo.name
        menuItem.addField("isKidsAccount", "boolean", false)
        menuItem.isKidsAccount = (isNonEmptyString(signInInfo.parent_tubi_id) = true)
        menuContent.appendChild(menuItem)
        m.profileMenu.content = menuContent
      end if
    end if



    updateContentSettingDisplay(signInInfo.parental_rating_v2)

    if signInInfo.parent_has_pin = true
      m.digitLabel.text = "...."
    else
      m.digitLabel.text = ""
    end if

  end if

End Function


Function updateContentSettingDisplay(parentalRating)
  ' Map parental rating to display text
  ' Refer to constants.serverValues.parentalControls for mapping
  if parentalRating = 4
    m.contentSettingValue.text = getTranslation("screenSettings_contentSetting_YOUNGEST_CHILD")
  else if parentalRating = 0
    m.contentSettingValue.text = getTranslation("screenSettings_contentSetting_YOUNGER_CHILD")
  else if parentalRating = 1
    m.contentSettingValue.text = getTranslation("screenSettings_contentSetting_OLDER_CHILD")
  else if parentalRating = 5
    m.contentSettingValue.text = getTranslation("screenSettings_contentSetting_OLDEST_CHILD")
  else
    ' Default to youngest child if invalid
    m.contentSettingValue.text = getTranslation("screenSettings_contentSetting_YOUNGEST_CHILD")
  end if
End Function


Function onParentProfileChange(msg)
  parentProfileInfo = msg.getData()
  if parentProfileInfo <> invalid
    if isNonEmptyString(parentProfileInfo.name) = true
      m.adultAccountValue.text = parentProfileInfo.name
      if parentProfileInfo.name.len() > 0
        m.adultAccountIcon.text = UCase(parentProfileInfo.name.left(1))
      end if
    end if

    if isNonEmptyString(parentProfileInfo.avatarUrl) = true
      m.adultAccountIcon.uri = parentProfileInfo.avatarUrl
    end if
  end if
End Function



Function onStartWatchingButtonSelected(msg)
  if msg.getData() = true
    m.top.startWatchBtnSeleted = true
  end if
End Function


Function onKeyEvent(key as String, press as Boolean) as Boolean
  if press then
    if key = "back"
      m.top.backButtonSelected = true
    end if
  end if

  return true
End Function
Function init()
  m.constants = getConstantsFromGlobal()
  m.pageHeader = m.top.findNode("PageHeader")
  m.subHeader = m.top.findNode("SubHeader")
  m.topHeader = m.top.findNode("TopPageHeader")
  m.pageHeader.text = getTranslation("kidsAgeSelection_header")
  m.topHeader.text = getTranslation("kidsAgeSelection_top_header")
  m.subHeader.text = getTranslation("kidsAgeSelection_sub_header")
  m.ageSelectionList = m.top.findNode("AgeSelectionList")
  m.ageSelectionList.observeFieldScoped("itemSelected", "onAgeSelectionListItemSelected")
  m.top.observeFieldScoped("focusedChild", "onComponentFocusChanged")

  m.top.trackingPageInfo = {
    pageType: "age_gate_page"
    pageValues: {}
  }

  m.top.screenLevel = m.constants.ui.screenLevels.kidsAgeSelectionScreen
  m.top.instantResumeAction = m.constants.instantResumeActions.restartApp

  m.backgroundUriList = []

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.pageHeader, typographyConstants.ids.headerLarge)
  setTypographyOfLabel(m.topHeader, typographyConstants.ids.bodyLargeStrong)
  setTypographyOfLabel(m.subHeader, typographyConstants.ids.bodyMedium)

  setupAgeSelectionList()

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

  m.pageHeader.color = theme.primaryTextColor
  m.topHeader.color = theme.secondaryTextColor
  m.subHeader.color = theme.secondaryTextColor
  m.ageSelectionList.focusBitmapBlendColor = theme.focusedColor

End Function


Function setupAgeSelectionList()

  ageRatingTitle = getTranslation("kidsAgeSelection_ageRatingLabel")
  includedUpToTitle = getTranslation("kidsAgeSelection_includedUpToLabel")

  ageSelectionListContent = createObject("roSGNode", "ContentNode")
  contentY = createObject("roSGNode", "ContentNode")
  contentY.update({
    title: ageRatingTitle
    SecondaryTitle: "1-3"
    Description: includedUpToTitle
    HDposterUrl: "pkg:/images/kids-age-1.png"
    ShortDescriptionLine1: "TV-Y"
  })
  ageSelectionListContent.appendChild(contentY)

  contentG = createObject("roSGNode", "ContentNode")
  contentG.update({
    title: ageRatingTitle
    SecondaryTitle: "4-6"
    Description: includedUpToTitle
    HDposterUrl: "pkg:/images/kids-age-2.png"
    ShortDescriptionLine1: "TV-G"
    ShortDescriptionLine2: "G"
  })
  ageSelectionListContent.appendChild(contentG)

  contentPG = createObject("roSGNode", "ContentNode")
  contentPG.update({
    title: ageRatingTitle
    SecondaryTitle: "7-9"
    Description: includedUpToTitle
    HDposterUrl: "pkg:/images/kids-age-3.png"
    ShortDescriptionLine1: "TV-Y7"
    ShortDescriptionLine2: "TV-Y7-FV"
  })
  ageSelectionListContent.appendChild(contentPG)

  contentPG13 = createObject("roSGNode", "ContentNode")
  contentPG13.update({
    title: ageRatingTitle
    SecondaryTitle: "10-12"
    Description: includedUpToTitle
    HDposterUrl: "pkg:/images/kids-age-4.png"
    ShortDescriptionLine1: "TV-PG"
    ShortDescriptionLine2: "PG"
  })
  ageSelectionListContent.appendChild(contentPG13)

  m.ageSelectionList.content = ageSelectionListContent
End Function


Function onComponentFocusChanged()
  if m.top.hasFocus()
    ' force a background update
    audioGuideText = m.topHeader.text + m.pageHeader.text + m.subHeader.text
    readAudioGuideText(audioGuideText)
    m.top.backgroundUriList = []
    m.ageSelectionList.setFocus(true)
  end if
End Function


Function onAgeSelectionListItemSelected(msg)
  item = msg.getData()
  signInInfo = m.top.signInInfo
  'refer to constants.serverValues.parentalControls for the mapping
  if item = 0
    pcRatingNumeric = 4 'Youngest Child
  else if item = 1
    pcRatingNumeric = 0 'YOUNGER_CHILD
  else if item = 2
    pcRatingNumeric = 1 'OLDER_CHILD
  else
    pcRatingNumeric = 5 'Oldest Child
  end if

  if signInInfo <> invalid
    signInInfo["parental_rating"] = pcRatingNumeric
    m.top.signInInfo = signInInfo
  end if
  m.top.ageSelected = true
  'TODO : send tracking event
End Function
Function init()
  m.constants  = getConstantsFromGlobal()
  theme = getThemeFromGlobal()

  Request = TubiRequest(m.constants.settings)
  Auth = TubiAuth(m.constants, Request)
  m.Tracking = TubiTracking(m.constants, Request, Auth)

  m.top.trackingPageInfo = {
    pageType: "onboarding_page"
    pageValues: {
                  page_sequence: -1
                  name: "ContentTypeSelection"
                }
  }

  m.backgroundUriList = [m.constants.ui.uris.marketingBackground]

  m.top.instantResumeAction = m.constants.instantResumeActions.startChannel

  m.controlGroup = m.top.findNode("controlGroup")
  m.variantGroup = m.top.findNode("variantGroup")
  m.FocusDelayTimer = m.top.findNode("FocusDelayTimer")

  if isICTSExperimentEnabled() = true
    m.controlGroup.visible = false
    m.variantGroup.visible = true

    m.headerPoster = m.top.findNode("headerPoster")
    m.titleLabel = m.top.findNode("titleLabel")
    m.experienceTitleFadeLabel = m.top.findNode("experienceTitleFadeLabel")
    m.experienceDescriptionFadeLabel = m.top.findNode("experienceDescriptionFadeLabel")
    m.InitialContentMenu = m.top.findNode("InitialContentMenu")
    m.SkipButton = m.top.findNode("SkipButton")

    m.rowNode = createInitialContentMenuContent()

    itemCount = m.rowNode.getChildCount()
    m.InitialContentMenu.numColumns = itemCount

    itemSize = m.InitialContentMenu.itemSize
    menuWidth = itemCount * itemSize[0]
    nSpacing = m.InitialContentMenu.columnSpacings[0]
    columnSpacings = []
    for _ = 1 to itemCount - 1
      menuWidth += nSpacing
      columnSpacings.push(nSpacing)
    end for
    m.InitialContentMenu.columnSpacings = columnSpacings

    xTranslation = (1920 - menuWidth) / 2
    m.InitialContentMenu.translation = [xTranslation, m.InitialContentMenu.translation[1]]

    ' items animate in and have a drop shadow. Without this they would get clipped
    m.InitialContentMenu.itemClippingRect = {
      "x": 0
      "y": itemSize[1] * -1
      "width": 1920
      "height": itemSize[1] * 3
    }

    m.InitialContentMenu.content = m.rowNode

    m.titleLabel.text = getTranslation("screenInitialContent_title")
    m.skipButton.text = getTranslation("screenInitialContent_show_everything_title")

    m.InitialContentMenu.focusBitmapUri = "pkg:/images/icts_item_stroke_fhd.9.png"
    if m.constants.deviceInfo.scaledUi = true
      m.InitialContentMenu.focusBitmapUri = "pkg:/images/icts_item_stroke_hd.9.png"
    end if
  else
    m.controlGroup.visible = true
    m.variantGroup.visible = false

    m.Title = m.top.findNode("title")
    m.SubTitle = m.top.findNode("subtitle")
    m.SkipButton = m.top.findNode("controlSkipButton")
    m.InitialContentMenuBground = m.top.findNode("InitialContentMenuBground")
    m.InitialContentMenu = m.top.findNode("controlInitialContentMenu")

    m.Title.text = getTranslation("screenInitialContent_title")
    m.SkipButton.text = getSkipButtonText()

    authInfo = m.global.authInfo
    if (authInfo <> invalid and authInfo.userId <> invalid)
      m.SubTitle.text = getTranslation("screenInitialContent_subtitle_signedIn")
    else
      m.SubTitle.text = getTranslation("screenInitialContent_subtitle_signedOut")
    end if

    m.InitialContentMenu.focusBitmapBlendColor = theme.focused

    m.rowNode = CreateObject("roSGNode", "ContentNode")

    setLiveTvFirst = isICTSSkipExperimentEnabled() AND getICTSSkipExperiment().live_tv_first = true
    if setLiveTvFirst = true then
        setMainContent(m.constants.ui.sideNavIds.linearTV, m.rowNode)
    end if

    setMainContent(m.constants.ui.sideNavIds.movies, m.rowNode)
    setMainContent(m.constants.ui.sideNavIds.tv, m.rowNode)

    if setLiveTvFirst = false then
      setMainContent(m.constants.ui.sideNavIds.linearTV, m.rowNode)
    end if

    setMainContent(m.constants.ui.sideNavIds.espanol, m.rowNode)
    setMainContent(m.constants.ui.sideNavIds.kidsMode, m.rowNode)

    numOfMenuItems = m.rowNode.getChildCount()
    nSpacing = m.InitialContentMenu.columnSpacings[0]
    aColumnSpacings = []
    for i = 1 to numOfMenuItems - 1
      aColumnSpacings.push(nSpacing)
    end for
    nMenuWidth = m.InitialContentMenu.itemSize[0] * numOfMenuItems + (nSpacing * (numOfMenuItems-1))

    nInitialContentMenuBgroundPadding = 96
    m.InitialContentMenu.columnSpacings = aColumnSpacings
    m.InitialContentMenu.numColumns = numOfMenuItems
    nInitialContentMenuX = (1920 - nMenuWidth)/2

    m.InitialContentMenu.translation = [ nInitialContentMenuX, m.InitialContentMenu.translation[1]]

    m.InitialContentMenuBground.width = nMenuWidth + (nInitialContentMenuBgroundPadding*2)
    m.InitialContentMenuBground.translation = [(1920 - m.InitialContentMenuBground.width)/2 , m.InitialContentMenuBground.translation[1]]
  end if

  m.top.observeFieldScoped("animateIntoView", "onAnimateIntoView")
  m.InitialContentMenu.observeField("itemSelected", "onItemSelected")
  m.InitialContentMenu.observeField("itemFocused", "onItemFocused")
  m.SkipButton.observeField("selected", "onSkipBtnSelected")
  m.screenReady = false '//When the screen 1st starts up, the screen is disabled
End Function


' animate the screen when the page 1st loads
Function onAnimateIntoView()
  if isICTSExperimentEnabled() = true
    m.rowNode.animate = true
    if m.constants.deviceInfo.limitedUi = false
      m.headerPoster.opacity = 0
      m.titleLabel.opacity = 0
      m.experienceTitleFadeLabel.opacity = 0
      m.experienceDescriptionFadeLabel.opacity = 0
      m.SkipButton.opacity = 0

      slideFade(m.headerPoster, "above", "in", .5, 0, 50)
      slideFade(m.titleLabel, "above", "in", .5, .2, 50)
      slideFade(m.experienceTitleFadeLabel, "above", "in", .5, .4, 50)
      slideFade(m.experienceDescriptionFadeLabel, "above", "in", .5, .6, 50)
      slideFade(m.SkipButton, "above", "in", .5, .75, 50)

      m.FocusDelayTimer.duration = .75
      m.FocusDelayTimer.observeFieldScoped("fire", "onFocusDelayTimer")
      m.FocusDelayTimer.control = "start"
    else
      m.headerPoster.opacity = 1
      m.titleLabel.opacity = 1
      m.experienceTitleFadeLabel.opacity = 1
      m.experienceDescriptionFadeLabel.opacity = 1
      m.SkipButton.opacity = 1
      onFocusDelayTimer()
    end if
    itemContent = m.rowNode.getChild(0)
    if isLiveTVFirst() = true
      itemContent = getSkipButtonContent()
    end if
    updateExperienceInfo(itemContent)
  else
    ' Have to set here otherwise nodes will animate too early
    m.InitialContentMenu.content = m.rowNode
    if m.constants.deviceInfo.limitedUi = false
      fade(m.InitialContentMenuBground, "in", .5, .5)
      slideFade(m.Title, "above", "in", .5, 0, 50)
      slideFade(m.SubTitle, "above", "in", .5, .2, 50)
      slideFade(m.SkipButton, "above", "in", .5, .75, 50)
      m.FocusDelayTimer.duration = .75
      m.FocusDelayTimer.observeFieldScoped("fire", "onFocusDelayTimer")
      m.FocusDelayTimer.control = "start"
    else
      '//If low spec device, then skip animation
      m.InitialContentMenuBground.opacity = 1
      m.Title.opacity = 1
      m.SubTitle.opacity = 1
      m.SkipButton.opacity = 1
      onFocusDelayTimer()
    end if
  end if
End Function


Function onFocusDelayTimer()
  m.FocusDelayTimer.unobserveFieldScoped("fire")
  if isLiveTVFirst() = true
    m.SkipButton.setFocus(true)
  else if shouldInitiallyFocusSkip() = true
    m.SkipButton.setFocus(true)
  else
    m.InitialContentMenu.setFocus(true)
  end if
  m.screenReady = true
End Function


' Set the ContentNode of one menu button of this screen and add it to the passed parentNode
' @itemID - string, The ID of the propsed menu button
' @parentNode - The node to which the new button info will be added
Function setMainContent(itemID, parentNode)
  contentNode = CreateObject("roSGNode", "ContentNode")
  contentNode.id = itemID
  bSuccess = false

  if itemID = m.constants.ui.sideNavIds.home
    contentNode.title = getTranslation("menu_movies_and_tv")
    contentNode.hdgridposterurl = "pkg:/images/icon-movies-large.png"
    bSuccess = true
  else if itemID = m.constants.ui.sideNavIds.linearTV
    contentNode.title = getTranslation("menu_livetv")
    contentNode.hdgridposterurl = "pkg:/images/icon-linearTV-large.png"
    bSuccess = true
  else if itemID = m.constants.ui.sideNavIds.kidsMode
    contentNode.title = getTranslation("menu_kids")
    contentNode.hdgridposterurl = "pkg:/images/icon-kids-large.png"
    bSuccess = true
  else if itemID = m.constants.ui.sideNavIds.espanol
    contentNode.title = "Español"
    contentNode.hdgridposterurl = "pkg:/images/icon-espanol-large.png"
    bSuccess = true
  else if itemID = m.constants.ui.sideNavIds.profile
    contentNode.title = getTranslation("menu_signIn")
    contentNode.hdgridposterurl = "pkg:/images/icon-profile-large.png"
    bSuccess = true
  else if itemID = m.constants.ui.sideNavIds.Movies
    contentNode.title = getTranslation("menu_movies")
    contentNode.hdgridposterurl = "pkg:/images/sideNavMovies.png"
    bSuccess = true
  else if itemID = m.constants.ui.sideNavIds.tv
    contentNode.title = getTranslation("menu_tv")
    contentNode.hdgridposterurl = "pkg:/images/sideNavTV.png"
    bSuccess = true
  end if

  if bSuccess = true
    parentNode.appendChild(contentNode)
  end if
End Function


Function createInitialContentMenuContent()
  sideNavIds = m.constants.ui.sideNavIds
  experienceModes = m.constants.ui.contentExperienceModes
  bestKnownMenuItem = {
    "id": sideNavIds.bestKnown
    "experienceId": experienceModes.bestKnown
    "title": getTranslation("screenInitialContent_bestKnown_menu_item_title")
    "description": getTranslation("screenInitialContent_bestKnown_menu_item_description")
    "backgroundColor": "#4D013C"
    "headerUri": "https://cdn.adrise.tv/image/roku_support_images/initial_content_screen/best_known_header_{size}.webp"
  }

  nostalgiaMenuItem = {
    "id": sideNavIds.nostalgia
    "experienceId": experienceModes.nostalgia
    "title": getTranslation("screenInitialContent_nostalgia_menu_item_title")
    "description": getTranslation("screenInitialContent_nostalgia_menu_item_description")
    "backgroundColor": "#43200F"
    "headerUri": "https://cdn.adrise.tv/image/roku_support_images/initial_content_screen/nostalgia_header_{size}.webp"
  }

  liveTvMenuItem = {
    "id": sideNavIds.linearTV
    "experienceId": experienceModes.liveTV
    "title": getTranslation("menu_livetv")
    "description": getTranslation("screenInitialContent_live_tv_menu_item_description")
    "backgroundColor": "#480203"
    "headerUri": "https://cdn.adrise.tv/image/roku_support_images/initial_content_screen/live_tv_header_{size}.webp"
  }

  espanolMenuItem = {
    "id": sideNavIds.espanol
    "experienceId": experienceModes.espanol
    "title": "Español"
    "description": getTranslation("screenInitialContent_espanol_menu_item_description")
    "backgroundColor": "#164039"
    "headerUri": "https://cdn.adrise.tv/image/roku_support_images/initial_content_screen/espanol_header_{size}.webp"
  }

  kidsMenuItem = {
    "id": sideNavIds.kidsMode
    "experienceId": experienceModes.kids
    "title": getTranslation("menu_kids")
    "description": getTranslation("screenInitialContent_kids_menu_item_description")
    "backgroundColor": "#5C390D"
    "headerUri": "https://cdn.adrise.tv/image/roku_support_images/initial_content_screen/kids_header_{size}.webp"
  }

  children = [
    bestKnownMenuItem
    nostalgiaMenuItem
    liveTvMenuItem
    espanolMenuItem
    kidsMenuItem
  ]
  if isLiveTVFirst() = true
    children = [
      liveTvMenuItem
      bestKnownMenuItem
      nostalgiaMenuItem
      espanolMenuItem
      kidsMenuItem
    ]
  end if

  contentNode = createObject("roSGNode", "ContentNode")
  contentNode.update({
    "children": children
  }, true)

  ' Using field to trigger animation vs setting content to animate due to boundingRect bug on content getting set again. Improves performance of animation as well :)
  contentNode.addField("animate", "boolean", true)
  return contentNode
End Function


Function getSkipButtonContent()
  return {
    "title": getTranslation("screenInitialContent_show_everything_title")
    "description": getTranslation("screenInitialContent_show_everything_description")
    "headerUri": ""
  }
End Function


Function onItemSelected()
  item = m.InitialContentMenu.itemSelected
  contentItem = m.InitialContentMenu.content.getChild(item)

  setActionableItemSelected(contentItem.id)
End Function


' Helper to update the ui elements for the current focused experience
' @helper - Node or AA with the fields title, description, headerUri
Function updateExperienceInfo(itemContent)
  m.experienceTitleFadeLabel.text = itemContent.title
  m.experienceDescriptionFadeLabel.text = itemContent.description
  if shouldShowBackgroundImages() = true
    m.headerPoster.uri = itemContent.headerUri
  end if
End Function


Function onItemFocused(e)
  itemFocused = e.getData()
  itemContent = m.InitialContentMenu.content.getChild(itemFocused)

  ' force a background update
  m.top.backgroundUriList = m.backgroundUriList

  if isICTSExperimentEnabled() = true
    updateExperienceInfo(itemContent)
  end if

  row = 1
  col = 1
  sButtonID = invalid
  if m.InitialContentMenu.hasFocus() = true
    col = itemFocused + 1
    id = itemContent.id
    sButtonID = m.Tracking.sideNavPageMap[id]

    if m.previousFocusedButton <> invalid and m.previousFocusedButton.top_nav_section <> invalid and m.previousFocusedButton.top_nav_section <> sButtonID and sButtonID <> invalid
      '//::NOTE:: the top_nav_component is used for the navigateWithinPageInfo event of the initial content screen
      ' this triggers a navigate_within_page event in ContentController
      m.top.navigateWithinPageInfo = {
        pageOneof: m.Tracking.getAnalyticsPage(m.top.trackingPageInfo.pageType, m.top.trackingPageInfo.pageValues)
        componentOneof: m.Tracking.getAnalyticsComponent("top_nav_component", m.previousFocusedButton)
        means_of_navigation: "SCROLL"  'MeansOfNavigation enum

        vertical_location: row  '//The row location of the side nav
        vertical_location_mode: "INDEX"  'LocationMode enum
        horizontal_location: col  '//The column location of the side nav
        horizontal_location_mode: "INDEX"  'LocationMode enum
      }
    end if
  else
    '//this else statement does nothing but to inform the developer that
    '//analytics is purposely not being sent for the focus of or from the skip button
  end if

  m.previousFocusedButton = {
    top_nav_section: sButtonID
  }
End Function


Function onSkipBtnSelected()
  setActionableItemSelected("skip")
End Function


Function setActionableItemSelected(sID)
  m.top.actionableItemSelected = sID
End Function


Function isICTSExperimentEnabled()
  ictsExperiment = getExperimentResource("roku_icts_content_modes", "roku_icts_content_modes_v1", false)
  return ictsExperiment.enabled = true and m.constants.deviceInfo.countryCode = "US"
End Function


Function shouldShowBackgroundImages()
  ictsExperiment = getExperimentResource("roku_icts_content_modes", "roku_icts_content_modes_v1", false)
  return ictsExperiment.show_background_images = true and m.constants.deviceInfo.countryCode = "US"
End Function


Function isLiveTVFirst()
  ictsExperiment = getExperimentResource("roku_icts_content_modes", "roku_icts_content_modes_v1", false)
  return ictsExperiment.live_tv_first = true and m.constants.deviceInfo.countryCode = "US"
End Function


Function getICTSSkipExperiment(sendEvent = false)
  return getExperimentResource("roku_icts_skip_new", "roku_icts_skip_new_v1", sendEvent)
End Function


Function isICTSSkipExperimentEnabled()
  if m.constants.deviceInfo.countryCode <> "US" then
    return false
  end if

  return getICTSSkipExperiment(true).enabled = true
End Function


Function shouldInitiallyFocusSkip()
  shouldFocusSkip = false
  if isICTSSkipExperimentEnabled() = true then
    shouldFocusSkip = getICTSSkipExperiment().initially_focus_skip = true
  end if
  return shouldFocusSkip
End Function


Function getSkipButtonText()
  text = getTranslation("dialog_button_skip")
  if isICTSSkipExperimentEnabled() = true AND getICTSSkipExperiment().show_me_everything = true then
    text = getTranslation("screenInitialContent_show_everything_title")
  end if

  return text
End Function


Function onKeyEvent(key, press) as boolean
  if press and m.screenReady = true
    if key = "back"
      setActionableItemSelected(m.constants.ui.keyIds.back)
      return true
    else if key = "down" and m.InitialContentMenu.hasFocus() = true
      if isICTSExperimentEnabled() = true
        updateExperienceInfo(getSkipButtonContent())
      end if
      m.SkipButton.setFocus(true)
      return true
    else if key = "up" and m.SkipButton.hasFocus() = true
      m.InitialContentMenu.setFocus(true)
      return true
    end if
  end if

  return false
End Function

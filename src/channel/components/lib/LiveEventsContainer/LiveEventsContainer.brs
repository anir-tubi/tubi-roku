' Initializes the LiveEventsContainer, caching node references, setting up
' observers, typography, tracking, and the periodic UI refresh timer.
Function init() as Void
  m.constants = getConstantsFromGlobal()
  topRef = m.top

  m.contentSection = topRef.findNode("contentSection")
  m.buttonList = topRef.findNode("buttonList")
  m.metadataSection = topRef.findNode("metadataSection")
  m.metadataRow = topRef.findNode("metadataRow")
  m.description = topRef.findNode("description")
  m.descriptionFocusButton = topRef.findNode("descriptionFocusButton")
  m.titleImage = topRef.findNode("titleImage")
  m.titleImage.loadHeight = 249
  m.titleImage.loadWidth = 594
  m.titleLabel = topRef.findNode("titleLabel")

  m.networkLogo = topRef.findNode("networkLogo")
  networkLogoSize = m.constants.ui.imageSizes.networkLogo
  m.networkLogo.loadHeight = networkLogoSize[1]
  m.networkLogo.loadWidth = networkLogoSize[0]

  m.closedCaptions = topRef.findNode("ClosedCaptionPoster")
  m.ratingGroup = topRef.findNode("ratingGroup")
  m.ratingLabel = topRef.findNode("ratingLabel")
  m.ratingBackground = topRef.findNode("ratingBackground")
  m.genres = topRef.findNode("genres")
  m.availabilityBadge = topRef.findNode("availabilityBadge")

  m.uhdAvailableBadge = topRef.findNode("uhdAvailableBadge")
  m.uhdAvailableBadge.text = getTranslation("info_panel_available_in_4k")

  topRef.observeFieldScoped("itemContent", "onItemContentChange")
  m.buttonList.observeFieldScoped("buttonSelected", "onButtonListSelected")
  topRef.observeFieldScoped("focusedChild", "onComponentFocusChange")
  topRef.observeFieldScoped("signedIn", "onSignedInChange")
  topRef.observeFieldScoped("didUserSetReminderForEventContent", "onDidSetReminderForEventContentChange")
  topRef.observeFieldScoped("rowHasFocus", "onItemHasFocusChange")
  topRef.observeFieldScoped("focusPercent", "onItemHasFocusChange")
  m.titleImage.observeFieldScoped("loadStatus", "adjustMetadataSectionTranslation")
  m.networkLogo.observeFieldScoped("loadStatus", "adjustMetadataSectionTranslation")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.description, typographyConstants.ids.bodyMedium)
  setTypographyOfLabel(m.genres, typographyConstants.ids.bodySmall)
  setTypographyOfLabel(m.ratingLabel, typographyConstants.ids.bodyExtraSmallStrong)
  setTypographyOfLabel(m.titleLabel, typographyConstants.ids.headerMedium)

  m.tracking = TubiTrackingInfo(m.constants)
  m.eventConfig = getExternalConfigValueFromGlobal("event", invalid)
  m.hubConfig = invalid
  if isAA(m.eventConfig) = true AND isAA(m.eventConfig.hub) = true
    m.hubConfig = m.eventConfig.hub
  end if

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
  onThemeChange()

  m.uiRefreshTimer = topRef.findNode("uiRefreshTimer")
  m.uiRefreshTimer.duration = 60
  m.uiRefreshTimer.observeFieldScoped("fire", "onUiRefreshTimerFired")
End Function


' Applies theme colors to labels, badges, and buttons
' @param msg - Optional message containing theme data
Function onThemeChange(msg = invalid) as Void
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.primaryTextColor = theme.primaryTextColor
    m.description.color = theme.primaryTextColor
    m.descriptionFocusButton.blendColor = theme.focusedColor
    m.uhdAvailableBadge.backgroundUri = "pkg:/images/rounded-background-$$RES$$.9.png"
    m.uhdAvailableBadge.borderUri = ""
    m.uhdAvailableBadge.textColor = theme.primaryTextColor
    m.genres.color = theme.primaryTextColor
    m.ratingLabel.color = theme.secondaryTextColor
    m.titleLabel.color = theme.primaryTextColor
    m.focused2Color = theme.focused2Color
    m.backgroundColor = theme.backgroundColor
    m.shadeColor = theme.shadeColor
  end if
End Function


' Delegates focus to the button list when this component receives focus
Function onComponentFocusChange() as Void
  if m.top.hasFocus() = true
    m.buttonList.setFocus(true)
  end if
End Function


' Same focus rule as HubRowLockup: ignore mid-scroll focusPercent; CTA itemHasFocus only when
' focusPercent = 1 and the row has focus.
Function onItemHasFocusChange(_msg = invalid) as Void
  focusPercent = m.top.focusPercent
  if focusPercent <> 0 AND focusPercent <> 1
    return
  end if

  ctaFocused = (focusPercent = 1 AND m.top.rowHasFocus = true)

  ctaButton = getFocusedButton()
  if ctaButton <> invalid
    ctaButton.itemHasFocus = ctaFocused
  end if
End Function


' Handles content changes by updating title, description, network logo,
' badges, genres, and button list.
Function onItemContentChange() as Void
  itemContent = m.top.itemContent
  if isNode(itemContent) = true
    refreshButtonList()
    m.description.text = itemContent.description
    if isNonEmptyString(itemContent.titleImageUrl)
      m.titleImage.uri = itemContent.titleImageUrl
      m.metadataSection.removeChild(m.titleLabel)
    else
      m.titleLabel.text = itemContent.title
      m.metadataSection.removeChild(m.titleImage)
    end if

    ' Resolve network logo URI and observe the parent container for sponsor changes.
    ' Unobserve the previous container first to prevent stale observer accumulation
    ' when the RowList recycles this component for different rows.
    container = itemContent.getParent()
    if isNode(m.prevContainer) = true
      m.prevContainer.unobserveField("sponsor")
    end if
    resolveNetworkLogoUri(container)
    if isNode(container) = true
      container.observeField("sponsor", "onSponsorChange")
      m.prevContainer = container
    end if

    ' Render the 4K badge if the content is 4K.
    isFourK = (itemContent.videoRenditions <> invalid AND arrayIncludes(itemContent.videoRenditions, m.constants.serverValues.tensorVideoRenditions.fourK))
    m.uhdAvailableBadge.visible = isFourK
    if isFourK = false
      m.metadataRow.removeChild(m.uhdAvailableBadge)
    end if

    updateAvailabilityBadge()

    ' Render the genres.
    genres = itemContent.genres
    if isNonEmptyArray(genres) = true
      m.genres.text = genres[0]
    end if

    m.closedCaptions.visible = (itemContent.hasSubtitles = true)

    setRatingBadge(itemContent.rating)

    m.contentSection.opacity = 1.0

    adjustMetadataSectionTranslation()
  end if
End Function


' Rebuilds the CTA button list based on event timing, login state, and hub availability
Function refreshButtonList() as Void
  itemContent = m.top.itemContent
  buttons = []
  if itemContent <> invalid AND itemContent.scheduleData <> invalid AND isNonEmptyString(itemContent.scheduleData.startTime) = true
    currentDatetime = CreateObject("roDateTime")
    airDatetime = CreateObject("roDateTime")
    airDatetime.FromISO8601String(itemContent.scheduleData.startTime)

    isEventLive = currentDatetime.asSeconds() >= airDatetime.asSeconds()
    hasEventEnded = isLessThanOrEqualToCurrentTime(itemContent.scheduleData.endTime)

    updateRefreshTimer(airDatetime, currentDatetime)

    ' Avoid re-triggering onItemContentChange when updating actionId below
    m.top.unObserveFieldScoped("itemContent")
    m.top.observeFieldScoped("itemContent", "onItemContentChange")

    buttonContent = getCtaButtonContent(itemContent, isEventLive, hasEventEnded)
    if buttonContent <> invalid
      itemContent.update({ actionId: buttonContent.id }, true)
      buttons.push(buttonContent)
    end if

    hubButtonContent = getHubButtonContent(itemContent)
    if hubButtonContent <> invalid
      buttons.push(hubButtonContent)
    end if
  end if

  m.buttonList.buttons = buttons
  m.buttonList.visible = isNonEmptyArray(buttons)

  if m.top.parentArrayGrid <> invalid
    onItemHasFocusChange()
  else
    m.buttonList.setFocus(true)
  end if
End Function


' Starts or stops the refresh timer based on seconds until air time
Function updateRefreshTimer(airDatetime, currentDatetime) as Void
  if m.uiRefreshTimer <> invalid
    secondsUntilAirTime = airDatetime.asSeconds() - currentDatetime.asSeconds()
    m.uiRefreshTimer.control = "stop"
    if secondsUntilAirTime > 0
      m.uiRefreshTimer.control = "start"
    end if
  end if
End Function


' Determines which CTA button to show based on event state
' @return assocarray with button content, or invalid if no button needed
Function getCtaButtonContent(itemContent, isEventLive, hasEventEnded) as Dynamic
  if itemContent.needsLogin = true AND getExternalConfigValueFromGlobal("bypass_registration_gate", false) = false AND hasEventEnded = false
    buttonId = "signInWatch"
    if isEventLive = true
      buttonId = "signInWatchLive"
    end if
    return {
      id: buttonId
      title: getTranslation("sign_in_watch_live")
      iconUrl: "pkg:/images/account-icon.webp"
      isPrimaryButton: true
    }
  else if hasEventEnded = true
    return {
      id: "contentUnavailable"
      title: getTranslation("content_unavailable")
      isPrimaryButton: true
      disabled: true
    }
  else if isEventLive = true
    return {
      id: "watchLive"
      title: getTranslation("screenHome_button_spotlight_watch_live")
      iconUrl: "pkg:/images/live-icon.webp"
      isPrimaryButton: true
    }
  end if

  ' Not live, not ended, no login required — show reminder or details
  if isEventLive = false AND itemContent.needsLogin <> true AND hasEventEnded = false
    if m.top.isContentDetailsView = true
      bookmark = getBookmark(itemContent.id)
      didUserSetReminderForEventContent = (bookmark <> invalid)
      if didUserSetReminderForEventContent = false
        reminderTranslationId = "screenDetails_button_set_reminder"
        iconUrl = "pkg:/images/set-reminder.webp"
      else
        reminderTranslationId = "screenDetails_button_remove_reminder"
        iconUrl = "pkg:/images/reminder-set.webp"
      end if
      return {
        id: "reminder"
        title: getTranslation(reminderTranslationId)
        iconUrl: iconUrl
        isPrimaryButton: true
      }
    else
      return {
        id: "details"
        title: getTranslation("screenDetails_button_details")
        isPrimaryButton: true
      }
    end if
  end if

  return invalid
End Function


' Returns hub button content if creatorTensorApp is present or uiCustomization matches the hub
Function getHubButtonContent(itemContent) as Dynamic
  if m.top.isContentDetailsView = false then return invalid

  if isAA(m.hubConfig) = true AND isNonEmptyString(m.hubConfig.id) = true
    if isNowWithinTimePeriod(m.hubConfig.start_time, m.hubConfig.end_time) = false
      return invalid
    end if
  end if

  if isAA(itemContent.creatorTensorApp) = true AND isNonEmptyString(itemContent.creatorTensorApp.id) = true
    hubTitle = itemContent.creatorTensorApp.title
    if isNonEmptyString(hubTitle) = true
      return {
        id: "hub"
        title: hubTitle
        isPrimaryButton: true
      }
    end if
  else if isAA(m.hubConfig) = true AND isAA(itemContent.uiCustomization) = true AND isAA(itemContent.uiCustomization.style) = true AND itemContent.uiCustomization.style.appId = m.hubConfig.id AND isNonEmptyString(m.hubConfig.title) = true
    return {
      id: "hub"
      title: m.hubConfig.title
      isPrimaryButton: true
    }
  end if
  return invalid
End Function


' Handles button selection, firing analytics for reminder toggles
' and passing the selected button ID up via ctaButtonSelectedId
Function onButtonListSelected(msg) as Void
  buttonData = msg.getData()
  if buttonData = invalid then return

  buttonId = buttonData.id
  if buttonId = "reminder"
    trackingPageInfo = m.top.trackingPageInfo
    if trackingPageInfo <> invalid
      itemContent = m.top.itemContent
      componentValues = {
        video_id: itemContent.id
      }
      bookmark = getBookmark(itemContent.id)
      didUserSetReminder = (bookmark <> invalid)
      if didUserSetReminder = false
        userInteractionValue = "TOGGLE_ON"
      else
        userInteractionValue = "TOGGLE_OFF"
      end if

      pageOneof = m.tracking.getAnalyticsPage(trackingPageInfo.pageType, trackingPageInfo.pageValues)
      componentOneof = m.tracking.getAnalyticsComponent("reminder_component", componentValues)

      m.top.componentInteractionInfo = {
        pageOneof: pageOneof
        componentOneof: componentOneof
        user_interaction: userInteractionValue
      }
    end if
  end if
  m.top.ctaButtonSelectedId = buttonId
End Function


' Returns the currently focused button node, defaulting to the first button
Function getFocusedButton() as Dynamic
  focusedIndex = m.buttonList.focusedIndex
  if focusedIndex = -1
    focusedIndex = 0
  end if
  if m.buttonList.getChildCount() > 0
    return m.buttonList.getChild(focusedIndex)
  end if
  return invalid
End Function


' Refreshes the button list when the reminder state changes
Function onDidSetReminderForEventContentChange(_msg) as Void
  refreshButtonList()
End Function


' Periodic refresh triggered by the timer to update buttons (AvailabilityBadge refreshes itself)
Function onUiRefreshTimerFired(_msg) as Void
  refreshButtonList()
End Function


' Refreshes the button list when the user's sign-in state changes
Function onSignedInChange(_msg) as Void
  refreshButtonList()
End Function


' Updates the availability badge (Live, Replay, Upcoming) based on schedule and replay state
Function updateAvailabilityBadge() as Void
  itemContent = m.top.itemContent
  m.availabilityBadge.itemContent = itemContent
  if m.availabilityBadge.isConfigured = false
    m.metadataRow.removeChild(m.availabilityBadge)
  else if m.availabilityBadge.getParent() = invalid
    m.metadataRow.insertChild(m.availabilityBadge, 0)
  end if
End Function


' Adjusts the vertical position of the content section so metadata aligns
' to the bottom of the container, shifting up for detail view
Function adjustMetadataSectionTranslation() as Void
  contentSectionHeight = m.contentSection.boundingRect().height
  isContentDetailsView = m.top.isContentDetailsView
  containerHeight = 690
  ' Since in content details view we have space on top we are moving it up vs home screen we are sticking it zero
  if contentSectionHeight < containerHeight OR isContentDetailsView = true
    translationY = containerHeight - contentSectionHeight
    m.contentSection.translation = [0, translationY]
  else
    m.contentSection.translation = [0, 0]
  end if
End Function


' Resolves and sets the network logo URI based on the following priority:
'   0. Ad sponsored title art (sponsoredLiveEventsHero brand logo from container.sponsor)
'   1. Creator app title art (e.g. studio/network branding)
'   2. Hub config title art (when container style matches the event hub)
'   3. Schedule data channel logo (EPG-provided logo)
'   4. Empty string fallback (no logo)
' @param container - The parent CategoryContentNode of itemContent
Function resolveNetworkLogoUri(container) as Void
  itemContent = m.top.itemContent

  ' Priority 0: Ad sponsored title art
  if isNode(container) = true AND isNode(container.sponsor) = true AND isNonEmptyString(container.sponsor.titleImageUrl) = true
    m.networkLogo.uri = container.sponsor.titleImageUrl
    return
  end if

  scheduleData = itemContent.scheduleData
  creatorApp = itemContent.creatorTensorApp

  containerUiCustomization = invalid
  if isNode(container) = true AND container.hasField("uiCustomization") = true
    containerUiCustomization = container.uiCustomization
  end if

  hasHubLogo = false
  if isAA(containerUiCustomization) = true AND isAA(containerUiCustomization.style) = true
    if isAA(m.hubConfig) = true AND containerUiCustomization.style.appId = m.hubConfig.id AND isNonEmptyString(m.hubConfig.title_art) = true
      hasHubLogo = true
    end if
  end if

  if isAA(creatorApp) = true AND isAA(creatorApp.images) = true AND isNonEmptyArray(creatorApp.images.title_art) = true
    m.networkLogo.uri = creatorApp.images.title_art[0]
  else if hasHubLogo = true
    m.networkLogo.uri = m.hubConfig.title_art
  else if isAA(scheduleData) = true AND isNonEmptyString(scheduleData.channelLogo) = true
    m.networkLogo.uri = scheduleData.channelLogo
  else
    m.networkLogo.uri = ""
  end if
End Function


' Called when the parent container's sponsor field changes (sponsor applied or removed).
' Re-evaluates the network logo priority so priority 0 (brand logo) takes or releases the slot.
Function onSponsorChange() as Void
  itemContent = m.top.itemContent
  if isNode(itemContent) = false
    return
  end if
  resolveNetworkLogoUri(itemContent.getParent())
End Function


' Sets the rating badge visibility and sizing based on content rating
' @param rating - String, the content rating (e.g., "TV-14", "PG-13")
Function setRatingBadge(rating) as Void
  if not isNonEmptyString(rating)
    m.ratingGroup.visible = false
    return
  end if

  ratingLabel = m.ratingLabel
  ratingLabel.width = 0
  ratingLabel.text = UCase(rating)

  badgeWidth = ratingLabel.boundingRect().width + 24
  badgeWidth = ensureDivisibleBy3(badgeWidth)

  ratingLabel.width = badgeWidth
  m.ratingBackground.width = badgeWidth
  m.ratingGroup.visible = true
End Function

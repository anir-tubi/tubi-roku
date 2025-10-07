Function init()
  m.constants = getConstantsFromGlobal()
  m.nodeHelpers = TubiNodeHelpers()
  topRef = m.top

  m.contentSection = topRef.findNode("contentSection")
  m.buttonList = topRef.findNode("buttonList")
  m.metadataRow = topRef.findNode("metadataRow")
  m.description = topRef.findNode("description")
  m.descriptionFocusButton = topRef.findNode("descriptionFocusButton")
  m.descriptionFont = topRef.findNode("descriptionFont")
  m.titleImage = topRef.findNode("titleImage")
  m.titleImage.loadHeight = 249
  m.titleImage.loadWidth = 594

  m.networkLogo = topRef.findNode("networkLogo")
  networkLogoSize = m.constants.ui.imageSizes.networkLogo
  m.networkLogo.loadHeight = networkLogoSize[1]
  m.networkLogo.loadWidth = networkLogoSize[0]

  m.closedCaptions = topRef.findNode("ClosedCaptionPoster")
  m.genres = topRef.findNode("genres")
  m.availabilityBadge = topRef.findNode("availabilityBadge")

  m.uhdAvailableBadge = topRef.findNode("uhdAvailableBadge")
  m.uhdAvailableBadge.text = getTranslation("info_panel_available_in_4k")

  topRef.observeFieldScoped("itemContent", "onItemContentChange")
  topRef.observeField("focusedChild", "onComponentFocusChange")
  topRef.observeFieldScoped("signedIn", "onSignedInChange")
  topRef.observeFieldScoped("didUserSetReminderForEventContent", "onDidSetReminderForEventContentChange")
  topRef.observeFieldScoped("itemHasFocus", "onItemHasFocusChange")
  topRef.observeFieldScoped("rowHasFocus", "onItemHasFocusChange")
  topRef.observeFieldScoped("rowListHasFocus", "onItemHasFocusChange")
  m.titleImage.observeFieldScoped("loadStatus", "adjustMetadataSectionTranslation")
  m.networkLogo.observeFieldScoped("loadStatus", "adjustMetadataSectionTranslation")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.description, typographyConstants.ids.bodyMedium)
  setTypographyOfLabel(m.genres, typographyConstants.ids.bodySmall)

  m.tracking = TubiTrackingInfo(m.constants)


  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
  onThemeChange()

  m.uiRefreshTimer = topRef.findNode("uiRefreshTimer")
  m.uiRefreshTimer.duration = 60
  m.uiRefreshTimer.observeFieldScoped("fire", "onUiRefreshTimerFired")
End Function


Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.primaryTextColor = theme.primaryTextColor
    m.description.color = theme.primaryTextColor
    m.descriptionFocusButton.blendColor = theme.focusedColor
    m.uhdAvailableBadge.backgroundColor = theme.defaultDarkTransparentAccent20
    m.uhdAvailableBadge.textColor = theme.highlightedTextColor
    m.genres.color = theme.primaryTextColor
    m.focused2Color = theme.focused2Color
    m.backgroundColor = theme.backgroundColor
  end if
End Function


Function onComponentFocusChange()
  if m.top.hasFocus() = true
    m.buttonList.setFocus(true)
  end if
End Function


Function onItemHasFocusChange()
  itemHasFocus = m.top.itemHasFocus AND m.top.rowHasFocus = true AND m.top.rowListHasFocus = true
  ctaButton = getFocusedButton()
  if ctaButton <> invalid
    ctaButton.itemHasFocus = itemHasFocus
  end if
End Function


Function onItemContentChange()
  itemContent = m.top.itemContent
  if isNode(itemContent) = true
    refreshButtonList()
    m.description.text = itemContent.description
    if itemContent.titleImageUrl <> invalid
      m.titleImage.uri = itemContent.titleImageUrl
    else
      m.titleImage.uri = ""
    end if
    scheduleData = itemContent.scheduleData
    if isAA(scheduleData) AND isNonEmptyString(scheduleData.channelLogo)
      m.networkLogo.uri = scheduleData.channelLogo
    else
      m.networkLogo.uri = ""
    end if
    isFourK = false
    if itemContent.videoRenditions <> invalid
      isFourK = arrayIncludes(itemContent.videoRenditions, m.constants.serverValues.tensorVideoRenditions.fourK)
    else
      isFourK = false
    end if
    m.uhdAvailableBadge.visible = isFourK
    if isFourK = false
      m.metadataRow.removeChild(m.uhdAvailableBadge)
    end if
    updateAvailabilityBadge()
    genres = itemContent.genres
    if isNonEmptyArray(genres) = true
      m.genres.text = genres[0]
    end if

    m.closedCaptions.visible = (itemContent.hasSubtitles = true)

    m.contentSection.opacity = 1.0

    adjustMetadataSectionTranslation()
  end if
End Function


Function refreshButtonList()
  itemContent = m.top.itemContent
  buttons = []
  m.nodeHelpers.removeAllChildren(m.buttonList)
  if itemContent <> invalid AND itemContent.scheduleData <> invalid AND isNonEmptyString(itemContent.scheduleData.startTime) = true
    buttonContent = invalid
    startTime = itemContent.scheduleData.startTime
    endTime = itemContent.scheduleData.endTime
    currentDatetime = CreateObject("roDateTime")
    airDatetime = CreateObject("roDateTime")
    airDatetime.FromISO8601String(startTime)

    isEventLive = currentDatetime.asSeconds() >= airDatetime.asSeconds()
    hasEventEnded = isLessThanOrEqualToCurrentTime(endTime)
    if m.uiRefreshTimer <> invalid
      secondsUntilAirTime = airDatetime.asSeconds() - currentDatetime.asSeconds()
      m.uiRefreshTimer.control = "stop"
      if secondsUntilAirTime > 0
        m.uiRefreshTimer.control = "start"
      end if
    end if

    if itemContent.needsLogin = true AND getExternalConfigValueFromGlobal("bypass_registration_gate", false) = false AND hasEventEnded = false
      translationId = "sign_in_watch"
      buttonId = "signInWatch"
      if isEventLive = true
        translationId = "sign_in_watch_live"
        buttonId = "signInWatchLive"
      end if
      buttonContent = {
        id: buttonId
        title: getTranslation(translationId)
        iconUrl: "pkg:/images/account-icon.webp"
        badgeText: getTranslation("registration_signup_button_free")
        isPrimaryButton: true
      }
    else if hasEventEnded = true
      buttonContent = {
        id: "contentUnavailable"
        title: getTranslation("content_unavailable")
        isPrimaryButton: true
        disabled: true
      }
    else if isEventLive = true
      ' For now using air datetime in future will use listing api information.
      buttonContent = {
        id: "watchLive"
        title: getTranslation("screenHome_button_spotlight_watch_live")
        iconUrl: "pkg:/images/live-icon.webp"
        isPrimaryButton: true
      }
    end if

    ' Only showing set reminder if the game is not happening on the same day as current day.
    ' Adding a safety check for a use case where start date is older than current day which will never happen real world but added as a safety.
    bookmark = getBookmark(itemContent.id)
    didUserSetReminderForEventContent = (bookmark <> invalid)

    if isEventLive = false AND itemContent.needsLogin <> true AND hasEventEnded = false
      if m.top.isContentDetailsView = true
        if didUserSetReminderForEventContent = false
          reminderTranslationId = "screenDetails_button_set_reminder"
          iconUrl = "pkg:/images/set-reminder.webp"
        else
          reminderTranslationId = "screenDetails_button_remove_reminder"
          iconUrl = "pkg:/images/reminder-set.webp"
        end if

        buttonContent = {
          id: "reminder"
          title: getTranslation(reminderTranslationId)
          iconUrl: iconUrl
          ' Making the button primary only if this button is the only button that is being displayed.
          isPrimaryButton: true
        }
      else
        buttonContent = {
          id: "details"
          title: getTranslation("screenDetails_button_details")
          isPrimaryButton: true
        }
      end if
    end if
    ' Avoiding unnecessary updates to the onItemContentChange been triggered.
    m.top.unObserveFieldScoped("itemContent")
    itemContent.update({
      actionId: buttonContent.id
    }, true)
    m.top.observeFieldScoped("itemContent", "onItemContentChange")
    if buttonContent <> invalid
      content = CreateObject("roSGNode", "ContentNode")
      content.update(buttonContent, true)

      button = CreateObject("roSGNode", "EnhancedButton")
      button.height = 105
      button.itemContent = content
      button.id = buttonContent.id
      button.observeFieldScoped("wasSelected", "onCtaButtonSelected")
      buttons.push(button)
    end if
  end if

  m.buttonList.appendChildren(buttons)
  m.buttonList.visible = isNonEmptyArray(buttons)

  if m.top.parentArrayGrid <> invalid
    onItemHasFocusChange()
  else
    m.buttonList.setFocus(true)
  end if
End Function


Function onCtaButtonSelected(msg)
  ctaButton = msg.getRoSGNode()
  if ctaButton.id = "reminder"
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
  m.top.ctaButtonSelectedId = ctaButton.id
End Function


Function getFocusedButton()
  focusedIndex = m.buttonList.focusedIndex
  if focusedIndex = -1
    focusedIndex = 0
  end if
  if m.buttonList.getChildCount() > 0
    return m.buttonList.getChild(focusedIndex)
  end if
  return invalid
End Function


Function onDidSetReminderForEventContentChange(msg)
  refreshButtonList()
End Function


Function onUiRefreshTimerFired(msg)
  refreshButtonList()
  updateAvailabilityBadge()
End Function


Function onSignedInChange(msg)
  refreshButtonList()
End Function


Function updateAvailabilityBadge()
  itemContent = m.top.itemContent
  if isAA(itemContent.scheduleData)
    badgeInfo = getLinearContentBadgeInfo(itemContent.scheduleData)
    if badgeInfo <> invalid
      m.availabilityBadge.width = 0
      m.availabilityBadge.text = ""
      if badgeInfo.availability = "live"
        setLinearAvailabilityBadge(m.availabilityBadge, badgeInfo.availability, m.primaryTextColor, m.focused2Color)
      else
        setLinearAvailabilityBadge(m.availabilityBadge, badgeInfo.availability, m.backgroundColor, m.primaryTextColor, badgeInfo.badgeText)
      end if
    else
      m.metadataRow.removeChild(m.availabilityBadge)
    end if
  end if
End Function


Function adjustMetadataSectionTranslation()
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
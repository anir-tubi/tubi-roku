Function init()
  m._ = rodash()
  m.constants = getConstantsFromGlobal()
  topRef = m.top

  m.infoPanel = topRef.findNode("InfoPanel")
  m.infoPanelGroup = topRef.findNode("infoPanelGroup")
  m.rowList = topRef.findNode("rowList")
  m.rowList.observeFieldScoped("keyPressed", "onKeyPressedChange")
  m.ctaButtonList = topRef.findNode("ctaButtonList")
  m.ctaButtonList.observeFieldScoped("itemSelected", "onCtaListItemSelected")
  m.ctaButtonList.itemClippingRect = {
    height: 600.0
    width: 1732.0
    x: 0.0
    y: 0.0
  }

  m.rowList.observeFieldScoped("currFocusColumn", "onRowItemFocused")
  topRef.observeFieldScoped("contentUpdated", "onContentChange")
  topRef.observeField("focusedChild", "onComponentFocusChange")
  topRef.observeFieldScoped("signedIn", "populateCtaButtonList")
  topRef.observeFieldScoped("didUserSetReminderForEventContent", "onDidSetReminderForEventContentChange")

  experimentsInfo = getExperimentsInfoFromGlobal()
  experiments = TubiExperiments(experimentsInfo)
  m.metadataTranslate = TubiMetadataTranslate(m.constants, experiments)

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
  onThemeChange()

  ' Contains information about the last focused element, possible values "rowList","ctaButtonList".
  ' Setting default value as ctaButtonList since that is focused by default.
  m.lastFocusedElement = "ctaButtonList"

  ' Creating a timer to refresh the Call to actions button since we have button logic based on whether game is live vs not.
  m.ctaButtonListRefreshTimer = topRef.findNode("ctaButtonListRefreshTimer")
  m.ctaButtonListRefreshTimer.observeFieldScoped("fire", "onCtaButtonListRefreshTimerFired")
End Function


Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.rowList.focusBitmapBlendColor = theme.focusedColor
    m.ctaButtonList.focusBitmapBlendColor = theme.focusedColor
    m.ctaButtonList.focusFootprintBlendColor = theme.neutralColor2
  end if
End Function


Function onComponentFocusChange()
  if m.top.hasFocus() = true
    if m.lastFocusedElement = "ctaButtonList" OR m.rowList.content = invalid
      m.ctaButtonList.setFocus(true)
    else if m.rowList.content <> invalid
      m.rowList.setFocus(true)
    end if
  end if
End Function


Function onContentChange()
  m.top.primaryEventContent = invalid
  m.rowList.content = invalid
  if isNode(m.top.content) = true AND m.top.content.getChild(0) <> invalid
    ' Creating a clone to avoid modifying the original content node.
    rowListContent = m.top.content.clone(true)
    category = rowListContent.getChild(0)
    primaryEventContent = category.getChild(0)

    singleContent = invalid

    if primaryEventContent <> invalid
      ' field with key "json" is a json string that holds the complete response from the container api request.
      ' Even though we are removing primary event from the category container on line number 78, "json" field will hold the complete response from backend.
      singleContent = m.metadataTranslate.getContentFromCategoryJson(category, primaryEventContent.id, m.top.signedIn)

      ' Removing the primary event node from the rowlist content node.
      category.removeChild(primaryEventContent)
    end if

    if singleContent <> invalid
      ' Making sure we add back the airdatetime and foxContentId to the content node since we are fetching updated data from css category json which will not have data added dynamically from listing api.
      originalAirDateTime = primaryEventContent.airDateTime
      foxContentId = primaryEventContent.foxContentId
      primaryEventContent = singleContent
      primaryEventContent.update({
        airDateTime: originalAirDateTime
        foxContentId: foxContentId
      }, true)
    end if
    
    if category.getChildCount() > 0
      size = m.constants.ui.imageSizes.largeLandscape
      posterHeight = size[1]
      m.rowList.update({
        "content": rowListContent
        "itemSize" : [771, posterHeight]
        "rowItemSize": [size]
        "rowHeights": [posterHeight]
      })
    end if

    if primaryEventContent <> invalid
      m.top.primaryEventContent = primaryEventContent

      populateCtaButtonList()
      populateInfoPanelWithPurpleCarpetMode(m.top.primaryEventContent, m.infoPanel)
      m.infoPanel.calculateHeight = true
    end if
  end if
End Function


Function populateCtaButtonList()
  primaryEventContent = m.top.primaryEventContent
  if primaryEventContent <> invalid AND isNonEmptyString(primaryEventContent.airDateTime) = true
    ' Force resetting the content in handle refresh use cases.
    m.ctaButtonList.content = invalid
    menuItems = []
    currentDatetime = CreateObject("roDateTime")
    airDatetime = CreateObject("roDateTime")
    airDatetime.FromISO8601String(primaryEventContent.airDateTime)

    isContentDetailsView = (m.top.isContentDetailsView = true)

    isEventLive = currentDatetime.asSeconds() >= airDatetime.asSeconds()

    if m.ctaButtonListRefreshTimer <> invalid
      secondsUntilAirTime = airDatetime.asSeconds() - currentDatetime.asSeconds()
      if secondsUntilAirTime > 0
        m.ctaButtonListRefreshTimer.duration = secondsUntilAirTime
        m.ctaButtonListRefreshTimer.control = "stop"
        m.ctaButtonListRefreshTimer.control = "start"
      end if
    end if

    currentMonth = currentDatetime.getMonth()
    currentDayOfMonth = currentDatetime.getDayOfMonth()
    airDateMonth = airDatetime.GetMonth()
    airDateDay = airDatetime.getDayOfMonth()

    ' Checking the event is happening on the same day as current day.
    isEventToday = (airDateMonth = currentMonth AND airDateDay = currentDayOfMonth)
    
    if m.top.signedIn = false AND primaryEventContent.needsLogin = true
      menuItems.push({
        id: "signInWatch"
        subType: "DetailMenuItemContentNode"
        title: getTranslation("screenHome_button_sign_in_watch")
        iconUrl: "pkg:/images/lock-closed.webp"
        badgeText: getTranslation("registration_signup_button_free")
        isPrimaryButton: true
      })
    else if isEventLive = true
      ' For now using airdatetime in future will use listing api information.
      menuItems.push({
        id: "watchLive"
        subType: "DetailMenuItemContentNode"
        title: getTranslation("screenHome_button_spotlight_watch_live")
        iconUrl: "pkg:/images/live-icon.webp"
        isPrimaryButton: true
      })
    else if isContentDetailsView = false
      menuItems.push({
        id: "details"
        subType: "DetailMenuItemContentNode"
        title: getTranslation("screenHome_button_spotlight_details")
        isPrimaryButton: true
      })
    else if isEventToday = true
      ' Checking if the current day and air date are same.
      ' Since we only have asTimeStringLoc method to format by passing the time format but that returns in local time so converting the utc time to local format.
      airDatetime.toLocalTime()
      formattedTime = airDatetime.asTimeStringLoc("h:mm a")

      menuItems.push({
        id: "availableAt"
        subType: "DetailMenuItemContentNode"
        title: getTranslation("available_at", {"time": formattedTime})
        isPrimaryButton: true
        disabled: true
      })
    end if

    ' Only showing set reminder if the game is not happening on the same day as current day.
    if isEventToday = false
      if m.top.didUserSetReminderForEventContent <> true
        reminderTranslationId = "screenDetails_button_set_reminder"
        iconUrl = "pkg:/images/set-reminder.webp"
      else
        reminderTranslationId = "screenDetails_button_remove_reminder"
        iconUrl = "pkg:/images/reminder-set.webp"
      end if

      menuItems.push({
        id: "reminder"
        subType: "DetailMenuItemContentNode"
        title: getTranslation(reminderTranslationId)
        iconUrl: iconUrl
        ' Making the button primary only if this button is the only button that is being displayed.
        isPrimaryButton: (menuItems.count() = 0)
      })
    end if

    content = CreateObject("roSGNode", "ContentNode")
    content.update({
      children: menuItems
    }, true)
    m.ctaButtonList.content = content
    updateMenuWidths()

    ' Making sure when we refresh the button list we set the focus back to where it was focused.
    itemFocused = m.ctaButtonList.itemFocused
    if itemFocused <> invalid AND itemFocused >= 0
      m.ctaButtonList.jumpToItem = itemFocused
    end if
  end if
End Function


Function updateMenuWidths()
  defaultMenuWidth = 104
  colWidths = []
  for i = 0 to m.ctaButtonList.content.getChildCount() - 1
    item = m.ctaButtonList.content.getChild(i)
    if item.isPrimaryButton = true
      ' Adjust the width of the menu if text of the button is too long for the default width. Mostly spanish text are generally longer in length.
      tempMenuItem = CreateObject("roSGNode", "DetailHorizMenuItem")
      tempMenuItem.itemContent = item

      potentialWidth = tempMenuItem.calculatedTextWidth + 64 '32 left padding + 32 right padding
      if potentialWidth > defaultMenuWidth
        colWidths[i] = potentialWidth
      end if
    else
      colWidths[i] = defaultMenuWidth
    end if
  end for

  m.ctaButtonList.update({"columnWidths": colWidths})
End Function


Function onCtaListItemSelected(msg)
  itemSelected = msg.getData()
  ctaButtonList = msg.getRoSGNode()
  content = ctaButtonList.content
  if content <> invalid
    item = content.getChild(itemSelected)
    if item <> invalid
      m.top.ctaListItemSelected = item.id
    end if
  end if
End Function


Function onDidSetReminderForEventContentChange(msg)
  reminderIsSet = msg.getData()

  populateCtaButtonList()

  if m.infoPanel <> invalid
    ' Triggering a info panel update to display reminder state.
    m.infoPanel.reminderIsSet = reminderIsSet
  end if
End Function


Function onCtaButtonListRefreshTimerFired(msg)
  populateCtaButtonList()
  ' Refreshing the info panel so that the live badge appears and the countdown timer is removed.
  populateInfoPanelWithPurpleCarpetMode(m.top.primaryEventContent, m.infoPanel)
End Function


' Below method is used to handle navigation between the RowList and the CTA buttons.
' Since we are using wrap focus style for rowlist. We have to create a custom rowlist and handle the key events so that we can capture 
' left press on rowlist and provide a custom navigation or focus flow rather than just wrapping.
Function onKeyPressedChange(msg)
  key = msg.getData()
  if key = "left"
    if m.ctaButtonList.content <> invalid AND m.ctaButtonList.content.getChildCount() > 0
      m.lastFocusedElement = "ctaButtonList"
      m.infoPanelGroup.opacity = 1
      m.ctaButtonList.setFocus(true)
    end if
  end if
End Function


Function onKeyEvent(key as String, press as Boolean) as Boolean
  if press = true AND key = "right" AND m.ctaButtonList.isInFocusChain() = true AND m.rowList.content <> invalid AND m.rowList.content.getChildCount() > 0
    m.lastFocusedElement = "rowList"
    m.infoPanelGroup.opacity = 0.6
    m.rowList.setFocus(true)
    return true
  end if

  return false
End Function

Function init()
  m.constants = getConstantsFromGlobal()
  Request = TubiRequest(m.constants.settings)
  '//This var is used to know when to send tracking info. Do not send tracking info when lastFocused row and currentFocusedRow are equal
  m.lastItemFocused = [0, 0]

  Auth = TubiAuth(m.constants, Request)
  m.Tracking = TubiTracking(m.constants, Request, Auth)
  m.channelsGrid = m.top.findNode("channelsGrid")
  m.headerText = m.top.findNode("headerText")
  m.backToLive = m.top.findNode("backToLive")
  m.backToLiveText = m.top.findNode("backToLiveText")
  m.programGrid = m.top.findNode("programGrid")
  m.leftIcon = m.top.findNode("leftIcon")
  m.playOnFocusMode = true
  ' focusedComponent will keep track of which component (programGrid or channels Grid) had last focus. This will help in handling focus back from sidenav/lienarvideoplayer.
  m.focusedComponent = "programGrid"

  ' canChannelBeFocused will indicate whether linearChannelFocused should get refreshed.
  ' when a channel is added or removed, the rowlist automatically refocuses to a neighboring channel of the previously focused content. We will also be setting a value on the .jumpToItem field to force focus on the channel we want to be focused. We do not want to set m.top.linearChannelToPlay on the default focus update, only the focus update that we force. m.canChannelBeFocused keeps state such that we don't react to the default focus updates.
  '                                   actions and hence linearChannelFocused should not get refreshed.
  m.canChannelBeFocused = true

  m.programGrid.observeFieldScoped("rowScrollFocused", "onProgramGridRowFocused")
  m.top.observeFieldScoped("jumpToLinearChannelID", "onJumpToLinearChannelID")
  m.top.observeFieldScoped("EPGFullMode", "onDisplayModeChange")
  m.programGrid.observeFieldScoped("rowItemSelected", "onProgramGridContentSelected")
  m.programGrid.observeFieldScoped("rowItemFocused", "onProgramGridContentFocused")
  m.top.observeFieldScoped("contentUpdated", "onContentChanged")
  m.top.observeField("focusedChild", "onTimeGridFocusChange")
  m.top.observeField("EPGChannelPlayMode", "onEPGChannelPlayModeChange")
  m.top.observeField("setFocusedToPlay", "onSetFocusedToPlay")
  m.updateMinsLeftTimer = m.top.findNode("updateMinsLeftTimer")
  m.updateMinsLeftTimer.observeField("fire", "onUpdateMinsLeftTimer")
  m.programGrid.observeFieldScoped("okPressed", "onProgramGridOkPressed")

  m.channelsGrid.observeFieldScoped("rowScrollFocused", "onChannelsGridRowFocused")
  m.channelsGrid.observeFieldScoped("itemSelected", "onChannelsGridItemSelected")
  m.channelsGrid.observeFieldScoped("itemFocused", "onChannelsGridContentFocused")
  m.top.observeFieldScoped("jumpToChannelItem", "onJumpToChannelItem")

  m.channelsGrid.observeFieldScoped("scrollingStatus", "onScrollingStatus")
  m.programGrid.observeFieldScoped("scrollingStatus", "onScrollingStatus")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.backToLiveText, typographyConstants.ids.bodySmallStrong)
  setTypographyOfLabel(m.headerText, typographyConstants.ids.subheaderSmall)

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
  onThemeChange()

  m.favoritesExp = (getExperimentResource("roku_linear_favorites", "roku_linear_favorites_v1", false).enabled = true)

End Function


Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.programGrid.focusBitmapBlendColor = theme.focusedColor
    m.channelsGrid.focusFootPrintBlendColor = theme.backgroundColorLight2
    m.headerText.color = theme.primaryTextColor
    m.backToLiveText.color = theme.primaryTextColor
    m.leftIcon.blendColor = theme.primaryTextColor
  end if
End Function


Function onEPGChannelPlayModeChange()
  if m.top.EPGChannelPlayMode = m.constants.EPGChannelPlayMode.playItemOnFocus
    m.playOnFocusMode = true
    m.backToLive.visible = false
  else if m.top.EPGChannelPlayMode = m.constants.EPGChannelPlayMode.playItemOnSelect
    m.playOnFocusMode = false
  end if
End Function


Function onProgramGridContentFocused(msg)
  tubiLog("programGrid.onProgramGridContentFocused")
  channelItem = msg.getRoSGNode()
  itemPosition = msg.getData()
  programGridContentFocused(channelItem, itemPosition)
End Function


Function programGridContentFocused(channelItem, itemPosition)

  if itemPosition <> invalid AND itemPosition.count() = 2
    channel = channelItem.content.getChild(itemPosition[0])

    if m.playOnFocusMode = true OR m.top.linearChannelToPlay = invalid 'anytime linearChannelToPlay is invalid, assign focused channel to play?

      if channel <> invalid AND channel.videoResources <> invalid
        epgTrackingComponentInfo = getEPGTrackingComponentInfo(itemPosition)
        m.top.epgTrackingComponentInfo = {
          componentType : "epg_component"
          componentValues : epgTrackingComponentInfo
        }
        m.top.linearChannelToPlay = channel
        m.top.linearChannelToPlayUpdated = true
      end if

    end if

    if channel <> invalid AND channel.getChildCount() > 0
      program = channel.getChild(itemPosition[1])
      m.top.linearChannelFocused = program
      m.top.linearChannelFocusedUpdated = true

      if m.playOnFocusMode <> true

        if isProgramLive(program) = true OR program.startTime = 0 OR program.endTime = 0
          fade(m.backToLive, "out", 0.1, 0, 0)
        else
          fade(m.backToLive, "in", 0.1, 0, 1)
        end if

      end if

    end if

    ' send NavigationwithinPageEvent when user focuses on tiles on programGrid
    if m.favoritesExp = true
      col = itemPosition[1] + 1 ' channelGrid column always = 0, programGrid column starts with = 1
    else
      col = itemPosition[1]
    end if

    naviPosition = [itemPosition[0], col]
    sendNavigationWithinPageEvent(naviPosition)

  end if
End Function


Function onProgramGridContentSelected(msg)
  tubiLog("ProgramGrid.onProgramGridContentSelected")
  programGrid = msg.getRoSGNode()
  itemPosition = msg.getData()
  if itemPosition <> invalid AND itemPosition.count() = 2
    m.lastProgramGuideComponentFocused = invalid
    channelItem = programGrid.content.getChild(itemPosition[0])
    if channelItem <> invalid AND channelItem.getChildCount() > 0
      programItem = channelItem.getChild(itemPosition[1])

      row = itemPosition[0] + 1
      col = itemPosition[1] + 1
      if programItem <> invalid
        m.top.linearChannelSelected = channelItem
        if isProgramLive(programItem) = true
          if m.playOnFocusMode = false 'playItemOnSelect mode.
            m.top.linearChannelToPlay = channelItem
            setComponentInteractionEventForLiveAndFuturePrograms(programItem, row, col, channelItem.parentId)
            m.top.linearChannelToPlayUpdated = true
          end if
        else ' setting selected field to true, will change display to indicate that the selected program is future program (orange color font and appended with "Starts at")
          programItem.selected = true
          setComponentInteractionEventForLiveAndFuturePrograms(programItem, row, col, channelItem.parentId)
        end if
      end if
    end if
  end if
End Function


Function onContentChanged()
  tubiLog("ProgramGuide.onContentChanged")

  if m.top.content <> invalid
    m.programGrid.content = m.top.content
    m.channelsGrid.content = m.top.content
  end if
End Function


Function onTimeGridFocusChange()
  tubiLog("ProgramGrid.onTimeGridFocusChange")

  if m.top.hasFocus() = true
    getExperimentResource("roku_linear_favorites", "roku_linear_favorites_v1", true)
    if m.focusedComponent = "programGrid"
      m.ProgramGrid.setFocus(true)
    else
      m.channelsGrid.setFocus(true)
    end if

    if m.updateMinsLeftTimer.control <> "start"
      m.updateMinsLeftTimer.control = "start"
      if m.programGrid.content <> invalid
        'UpdateMinsLeftTimer might take a whole min to update after content has been rendered.
        'Call this function to ensure current program shows how much time left on the program on every time timeGrid first gets focus.
        onUpdateMinsLeftTimer()
      end if
    end if

  else if m.top.isInFocusChain() = false
    m.updateMinsLeftTimer.control = "stop"
  end if
End Function


Function onProgramGridRowFocused(_msg)
  newFocus = m.programGrid.rowScrollFocused

  if m.channelsGrid.preItemFocused <> newFocus
    tubiLog("ProgramGrid.onMenuScrollFocused")
    m.channelsGrid.jumpToItem = newFocus
    if m.channelsGrid.content.getchild(newFocus) <> invalid
      m.headerText.text = m.channelsGrid.content.getchild(newFocus).parentTitle
    end if
  end if

End Function


Function onChannelsGridRowFocused(_msg)

  newFocus = m.channelsGrid.rowScrollFocused

  if m.programGrid.preItemFocused <> newFocus
    tubiLog("ProgramGrid.onChannelsGridRowFocused")
    m.programGrid.jumpToItem = newFocus
    if m.channelsGrid.content.getchild(newFocus) <> invalid
      m.headerText.text = m.channelsGrid.content.getchild(newFocus).parentTitle
    end if
  end if

End Function


'based on m.top.jumpToLinearChannelID, this function will jump to channel
Function onJumpToLinearChannelID()
  tubiLog("ProgramGuide.onJumpToLinearChannelID")
  if m.programGrid.content <> invalid AND m.top.jumpToLinearChannelID <> invalid AND m.top.jumpToLinearChannelID.count() = 2
    for i = 0 to m.programGrid.content.getchildCount() - 1
      item = m.programGrid.content.getchild(i)
      containerId = m.top.jumpToLinearChannelID[1]
      if item.id = m.top.jumpToLinearChannelID[0] AND (containerId = "" OR containerId = item.parentId)
        m.programGrid.jumpToRowItem = [i, 0]
        m.programGrid.itemFocused = i
        m.channelsGrid.jumpToItem = i
        if item <> invalid AND item.getChildCount() > 0
          program = item.getChild(0)
          m.top.linearChannelFocused = program
          '//::TODO:: EPG - why doesn't setting of linearChannelFocusedUpdated trigger EPGScreen.onLinearChannelFocused from calling?
          m.top.linearChannelFocusedUpdated = true

          if m.top.shouldSendComponentInteractionEventOnJumpToLinearChannelId = true
            m.top.shouldSendComponentInteractionEventOnJumpToLinearChannelId = false
            rowNum = i + 1
            colNum = 1
            setComponentInteractionEventForLiveAndFuturePrograms(program, rowNum, colNum, item.parentId)
          end if
        end if
        if m.playOnFocusMode = false AND m.top.linearChannelToPlay <> invalid AND m.top.linearChannelToPlay.id <> item.id
          m.top.linearChannelToPlay = item 'after the jump, set the linearchannelToplay to focused content.
          m.top.linearChannelToPlayUpdated = true
        end if
        exit for
      end if
    end for
  end if
End Function


Function onDisplayModeChange()
  if m.top.EPGFullMode = true
    m.headerText.visible = true
    m.channelsGrid.numRows = 4
    m.programGrid.ProgramGrid = 4
  else
    m.headerText.visible = false
    m.channelsGrid.numRows = 3
    m.programGrid.numRows = 3
  end if

End Function


' this function will update the minutesLeft (eg: 50 min left) display every minute.
Function onUpdateMinsLeftTimer()
  tubiLog("ProgramGrid.onUpdateMinsLeftTimer")
  content = m.programGrid.content
  now = getCurrentLocalTime()



  if content <> invalid
    for i = 0 to content.getChildCount() - 1
      channel = content.getChild(i)
      if channel <> invalid
        for j = 0 to channel.getChildCount() - 1
          program = channel.getChild(j)
          if program <> invalid AND program.endTime <> 0
            if program.endTime - now <= 0
              channel.removeChildIndex(j)
            else if isProgramLive(program) = true
              program.ShortDescriptionLine1 = getTranslation("epg_minutes_left", {minutes: toStr(convertSecondsToMins(program.endTime - now))})
              exit for 'found the current program
            end if
          end if
        end for
      end if
    end for
  end if
End Function


Function onProgramGridOkPressed()
  tubiLog("ProgramGrid.onProgramGridOkPressed")
  if m.top.linearChannelFocused <> invalid AND isProgramLive(m.top.linearChannelFocused)
    itemPosition = m.programGrid.rowItemFocused
    m.top.linearChannelToPlay = m.top.linearChannelFocused.getParent()
    m.top.linearChannelToPlayUpdated = true
    m.top.okPressed = true
    channelItem = m.programGrid.content.getChild(itemPosition[0])
    if channelItem <> invalid AND channelItem.getChildCount() > 0
      programItem = channelItem.getChild(itemPosition[1])
      row = itemPosition[0] + 1
      col = itemPosition[1] + 1
      setComponentInteractionEventForLiveAndFuturePrograms(programItem, row, col, channelItem.parentId)
    end if
  end if
End Function


'TODO : We would like to refactor this functionality in future.
'Currently this function is taking the request from outside(EPGScreen) and setting the focused item as  'LinearchannelToPlay'
'this functionality is required to handle situations where EPG is asked to behave differently in 'PlayOnSelect' Mode.
'for example when EPG starts, without user selecting a channel, EPGScreen needs to play first channel in minimized window.
'other example would be, when user lands on EPG from sideNav.
'EPGScreen/ePGScreenHelper can not set 'linearchannelToPlay' directly which will cause refetching the currently focused channel which might be different than linearchannelToPlay

Function onSetFocusedToPlay()
  tubilog("ProgramGrid.onSetFocusedToPlay")
  if m.top.linearChannelFocused <> invalid
    m.top.linearChannelToPlay = m.top.linearChannelFocused.getParent()
    m.top.linearChannelToPlayUpdated = true
  end if
End Function


'Set the componentInteractionInfo value which will pass through to ContentController via epgScreenHelper.brs
'to fire a component_interaction analytics event.
'@content: Node, currently playing/future program
'@rowNum: Integer, horizontal position of the currentProgram with 1 based Index as opposed to 0 based Index
'@colNum, Integer, vertical position of the currentProgram with 1 based Index as opposed to 0 based Index
'@categorySlug, String, id/slug of the category to which the linear channel belongs to.
Function setComponentInteractionEventForLiveAndFuturePrograms(content, rowNum, colNum, categorySlug)
  componentValues = {
    content_tile: m.Tracking.getAnalyticsTile(content, colNum, rowNum)
  }

  if isNonEmptyString(categorySlug) = true
    componentValues.category_slug = categorySlug
  end if

  pageType = ""
  if m.top.trackingPageInfo <> invalid AND m.top.trackingPageInfo.pagetype <> invalid
    pageType = m.top.trackingPageInfo.pagetype
  end if

  pageValues = {}
  if m.top.trackingPageInfo <> invalid AND m.top.trackingPageInfo.pageValues <> invalid
    pageValues = m.top.trackingPageInfo.pageValues
  end if
  componentInteractionInfo = {
    pageOneof: m.Tracking.getAnalyticsPage(pageType, pageValues)
    componentOneof: m.Tracking.getAnalyticsComponent("epg_component", componentValues)
    user_interaction: "CONFIRM"
  }

  m.top.componentInteractionInfo = componentInteractionInfo
End Function


'This function used to check whether user triggered the navigation or not to avoid the duplicate events
'@lastItemFocused: roArray, last focusedItem on the programGrid
'@rowItemFocused: roArray, currentFocusedItem on the programGrid
Function doesSendEvent(lastItemFocused, rowItemFocused)
  isEqual = true
  if lastItemFocused.count() = rowItemFocused.count() AND rowItemFocused.count() = 2
    'to avoid duplicates, when onProgramGridContentFocused() gets invoked twice.
    if rowItemFocused[1] = lastItemFocused[1] AND rowItemFocused[0] = lastItemFocused[0]
      isEqual = false
    'this will avoid the duplicate events when up/down navigation, as the item
    'jumped to [currentRowFocused, 0] and then jump to the correct item.
    else if rowItemFocused[1] = 0 AND rowItemFocused[0] = lastItemFocused[0] AND (m.programGrid.kepPressed = "up" OR m.programGrid.kepPressed = "down")
      isEqual = false
    end if
  end if
  return isEqual
End Function


Function onKeyEvent(key As string, press As boolean) As boolean

  if press
    if m.favoritesExp = true
      if key = "left" AND m.programGrid.isInFocusChain() = true AND m.channelsGrid.content <> invalid
        m.channelsGrid.setFocus(true)
        m.focusedComponent = "channelsGrid"
        return true
      else if key = "right" AND m.channelsGrid.hasFocus() = true AND m.programGrid.content <> invalid
        m.programGrid.setFocus(true)
        m.focusedComponent = "programGrid"
        return true
      end if
    end if

  end if

  return false
End Function


Function onScrollingStatus(msg)
  m.top.scrollingStatus = msg.getData()
End Function


Function onChannelsGridContentFocused(msg)
  tubilog("programGrid.onChannelsGridContentFocused")

  itemPosition = msg.getData()

  if itemPosition <> invalid
    channel = m.programGrid.content.getChild(itemPosition)

    if m.playOnFocusMode = true OR m.top.linearChannelToPlay = invalid  'even when user is on channel logo, play the channel because otherwise whats playing does not match whats on EPG Overlay
      if channel <> invalid AND channel.videoResources <> invalid AND m.canChannelBeFocused = true
        epgTrackingComponentInfo = getEPGTrackingComponentInfo(itemPosition)
        m.top.epgTrackingComponentInfo = {
          componentType : "epg_component"
          componentValues : epgTrackingComponentInfo
        }
        m.top.linearChannelToPlay = channel
        m.top.linearChannelToPlayUpdated = true
      end if

      m.canChannelBeFocused = true
    end if

    if channel <> invalid AND channel.getChildCount() > 0
      program = channel.getChild(0)
      m.top.linearChannelFocused = program
      m.top.linearChannelFocusedUpdated = true
      fade(m.backToLive, "out", 0.1, 0, 0)
    end if

    ' send NavigationwithinPageEvent when user focuses on tiles on ChannelGrid
    navPosition = [itemPosition, 0]
    sendNavigationWithinPageEvent(navPosition)
  end if

End Function


Function onChannelsGridItemSelected(msg)
  tubilog("programGrid.onChannelsGridItemSelected")

  itemSelected = msg.getData()

  channelItem = m.channelsGrid.content.getChild(itemSelected)

  m.canChannelBeFocused = false

  if channelItem.selected = true
    favAction = m.constants.ui.likeDislikeActions.dislike
    channelItem.selected = false
  else
    favAction = m.constants.ui.likeDislikeActions.like
    channelItem.selected = true
  end if

  'channel has been wrapped using AA to avoid channelLikeDislikeInfo interface getting triggered when
  'channel get updated.
  favActionAA = {
    "channelNode": channelItem
    "action": favAction
  }

  m.top.channelLikeDislikeInfo = favActionAA
End Function


' when we jump to a channelItem, the EPG screen does not refresh the metadata and header text.
' This function handles refreshing metadata and header text in case of like/dislike a channel
Function onJumpToChannelItem(msg)
  row = msg.getData()
  m.channelsGrid.jumpToItem = row
  if m.channelsGrid.content.getchild(row) <> invalid
    m.headerText.text = m.channelsGrid.content.getchild(row).parentTitle
  end if
End function


Function sendNavigationWithinPageEvent(rowItemFocused)

  if doesSendEvent(m.lastItemFocused, rowItemFocused) = true

    componentValues = getEPGTrackingComponentInfo(m.lastItemFocused)

    if rowItemFocused[0] >= 0
      row = rowItemFocused[0] + 1
    else
      row = 1 'default row is first row.
    end if

    if rowItemFocused[1] >= 0
      col = rowItemFocused[1] + 1
    else
      col = 1
    end if

    m.lastItemFocused = rowItemFocused

    pageType = ""
    if m.top.trackingPageInfo <> invalid AND m.top.trackingPageInfo.pagetype <> invalid
      pageType = m.top.trackingPageInfo.pagetype
    end if

    pageValues = {}
    if m.top.trackingPageInfo <> invalid AND m.top.trackingPageInfo.pageValues <> invalid
      pageValues = m.top.trackingPageInfo.pageValues
    end if

    navigateWithinPageInfo = {
      pageOneof: m.Tracking.getAnalyticsPage(pageType, pageValues)
      componentOneof: m.Tracking.getAnalyticsComponent("epg_component", componentValues)
      means_of_navigation: "BUTTON"
      vertical_location: row
      horizontal_location: col
    }
    m.top.navigateWithinPageInfo = navigateWithinPageInfo

  end if

End Function


Function getEPGTrackingComponentInfo(itemFocused)
  componentValues = {}

  if m.programGrid.content <> invalid AND itemFocused.count() = 2
    categorySlug = ""
    program = invalid

    channelNode = m.programGrid.content.getChild(itemFocused[0])
    if channelNode <> invalid
      program = channelNode.getchild(itemFocused[1])
      categorySlug = channelNode.parentId
    end if

    itemFocusedCol = itemFocused[1] + 1
    itemFocusedRow = itemFocused[0] + 1

    contentTile = m.Tracking.getAnalyticsTile(program, itemFocusedCol, itemFocusedRow)

    componentValues = {
      content_tile: contentTile
      category_slug: categorySlug
    }
  end if

  return componentValues
End Function

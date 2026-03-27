Function init()
  m.constants = getConstantsFromGlobal()
  '//This var is used to know when to send tracking info. Do not send tracking info when lastFocused row and currentFocusedRow are equal
  m.lastItemFocused = [0, 0]

  m.Tracking = TubiTrackingInfo(m.constants)
  m.channelsGrid = m.top.findNode("channelsGrid")
  m.headerText = m.top.findNode("headerText")
  m.backToLive = m.top.findNode("backToLive")
  m.backToLiveText = m.top.findNode("backToLiveText")
  m.programGrid = m.top.findNode("programGrid")
  m.leftIcon = m.top.findNode("leftIcon")
  m.playOnFocusMode = true

  m.top.observeFieldScoped("jumpToLinearChannelID", "onJumpToLinearChannelID")

  m.top.observeFieldScoped("EPGFullMode", "onDisplayModeChange")
  m.programGrid.observeFieldScoped("rowItemSelected", "onProgramGridContentSelected")
  m.programGrid.observeFieldScoped("rowItemFocused", "onProgramGridContentFocused")
  m.programGrid.observeFieldScoped("rowScrollFocused", "onProgramGridRowFocused")
  m.programGrid.observeFieldScoped("okPressed", "onProgramGridOkPressed")

  m.channelsGrid.observeFieldScoped("itemSelected", "onChannelItemSelected")
  m.channelsGrid.observeFieldScoped("itemFocused", "onChannelGridItemFocused")

  m.top.observeFieldScoped("contentUpdated", "onContentChanged")
  m.top.observeField("focusedChild", "onTimeGridFocusChange")
  m.top.observeField("EPGChannelPlayMode", "onEPGChannelPlayModeChange")
  m.top.observeField("setFocusedToPlay", "onSetFocusedToPlay")
  m.top.observeFieldScoped("channelGridFocusable", "onChannelGridFocusableChange")
  m.top.observeFieldScoped("categoriesMenuVisible", "onCategoriesMenuVisibleChange")
  m.updateMinsLeftTimer = m.top.findNode("updateMinsLeftTimer")
  m.updateMinsLeftTimer.observeField("fire", "onUpdateMinsLeftTimer")

  m.channelGridScrollingTimer = CreateObject("roSGNode", "Timer")
  m.channelGridScrollingTimer.duration = m.constants.timers.epgGridScrollingSettleDuration
  m.channelGridScrollingTimer.repeat = false
  m.channelGridScrollingTimer.observeFieldScoped("fire", "onChannelGridScrollingComplete")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.backToLiveText, typographyConstants.ids.bodySmallStrong)
  setTypographyOfLabel(m.headerText, typographyConstants.ids.subheaderSmall)

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
  onThemeChange()
  onCategoriesMenuVisibleChange()

End Function


Function onChannelGridFocusableChange(msg = invalid)
  if m.top.channelGridFocusable = false
    m.top.isChannelGridFocused = false
  end if
End Function


Function onCategoriesMenuVisibleChange(msg = invalid)
  ' Layout shift: when categories menu is hidden, shift content left by 278px (container width)
  categoriesMenuVisible = true
  if m.top.categoriesMenuVisible <> invalid
    categoriesMenuVisible = m.top.categoriesMenuVisible
  end if

  if categoriesMenuVisible = true
    m.headerText.translation = [300, 51]
    m.channelsGrid.translation = [300, 96]
    m.programGrid.translation = [498, 96]
  else
    m.headerText.translation = [22, 51]
    m.channelsGrid.translation = [22, 96]
    m.programGrid.translation = [220, 96]
  end if
End Function


Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.programGrid.focusBitmapBlendColor = theme.focusedColor
    m.channelsGrid.focusBitmapBlendColor = theme.focusedColor
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


Function onChannelItemSelected(msg)
  itemSelected = msg.getData()
  m.top.channelIdSelected = m.channelsGrid.Content.getChild(itemSelected).id
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

    if channel.needsLogin = true AND isNonEmptyArray(channel.backgrounds) = true
      m.top.isBackgroundImagesChanges = true
    end if

    if m.playOnFocusMode = true OR m.top.linearChannelToPlay = invalid 'anytime linearChannelToPlay is invalid, assign focused channel to play?

      if channel <> invalid AND channel.videoResources <> invalid
        ' Only trigger observer when channel actually changes to avoid unwanted firing on every focus change
        channelChanged = (m.top.linearChannelToPlay = invalid) OR (m.top.linearChannelToPlay.id <> channel.id)
        if channelChanged = true
          epgTrackingComponentInfo = getEPGTrackingComponentInfo(itemPosition)
          m.top.epgTrackingComponentInfo = {
            componentType: "epg_component"
            componentValues: epgTrackingComponentInfo
          }
          m.top.linearChannelToPlay = channel
          m.top.linearChannelToPlayUpdated = true
        end if
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
    if m.top.channelGridFocusable = true AND m.top.isChannelGridFocused = true
      m.channelsGrid.setFocus(true)
    else
      m.ProgramGrid.setFocus(true)
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


Function onChannelGridItemFocused(msg)
  channelFocusedIndex = msg.getData()

  if channelFocusedIndex <> invalid AND channelFocusedIndex >= 0
    m.top.channelGridScrollingStatus = true

    ' Debounce: stop cancels any pending fire; start begins a new delay so "scrolling complete"
    ' runs only after focus stays on one item for the full settle duration.
    m.channelGridScrollingTimer.control = "stop"
    m.channelGridScrollingTimer.control = "start"

    tubiLog("ProgramGuide.onChannelGridItemFocused - syncing program grid to row: " + channelFocusedIndex.toStr())
    m.programGrid.jumpToRowItem = [channelFocusedIndex, 0]
    if m.channelsGrid.content.getchild(channelFocusedIndex) <> invalid
      m.headerText.text = m.channelsGrid.content.getchild(channelFocusedIndex).parentTitle
    end if
  end if
End Function


Function onChannelGridScrollingComplete(msg)
  ' Reset scrolling status when channel grid scrolling stops (similar to program grid)
  m.top.channelGridScrollingStatus = false
  m.channelGridScrollingTimer.control = "stop"
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
              program.ShortDescriptionLine1 = getTranslation("epg_minutes_left", { minutes: toStr(convertSecondsToMins(program.endTime - now)) })
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


Function onKeyEvent(key as String, press as Boolean) as Boolean
  tubiLog("ProgramGuide.onKeyEvent")
  handled = false

  if press = true AND m.top.channelGridFocusable = true
    if key = "left" AND m.programGrid.hasFocus() = true
      m.channelsGrid.setFocus(true)
      handled = true
    else if key = "right" AND m.channelsGrid.hasFocus() = true
      m.programGrid.setFocus(true)
      handled = true
    end if
  end if

  return handled
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

Function init()
  m.constants = getConstantsFromGlobal()
  Request = TubiRequest(m.constants.settings)
  '//This var is used to know when to send tracking info. Do not send tracking info when lastFocused row and currentFocusedRow are equal
  m.lastItemFocused = [0,0]

  Auth = TubiAuth(m.constants, Request)
  m.Tracking = TubiTracking(m.constants, Request, Auth)
  m.channelsGrid = m.top.findNode("channelsGrid")
  m.headerText = m.top.findNode("headerText")
  m.backToLive = m.top.findNode("backToLive")
  m.programGrid = m.top.findNode("programGrid")
  theme = getThemeFromGlobal()
  if theme <> invalid
    m.programGrid.focusBitmapBlendColor = theme.focused
  end if
  m.playOnFocusMode = true
  m.lastFocused = -1

  m.programGrid.observeFieldScoped("currFocusRow", "onRowFocused")
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
  m.programGrid.observeFieldScoped("okPressed", "onOkPressed")
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

  rowItemFocused = m.programGrid.rowItemFocused
  if Type(rowItemFocused) = "roArray" AND doesSendEvent(m.lastItemFocused, rowItemFocused) = true
    previousItemFocused = invalid
    if m.programGrid.content.getChild(m.lastItemFocused[0]) <> invalid
      previousItemFocused = m.programGrid.content.getChild(m.lastItemFocused[0]).getchild(m.lastItemFocused[1])
    end if

    lastItemFocusedCol = m.lastItemFocused[1] + 1
    lastItemFocusedRow = m.lastItemFocused[0] + 1
    contentTile = m.Tracking.getAnalyticsTile(previousItemFocused, lastItemFocusedCol, lastItemFocusedRow)

    row = rowItemFocused[0] + 1
    col = rowItemFocused[1] + 1
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
      componentOneof: m.Tracking.getAnalyticsComponent("epg_component",  {content_tile: contentTile})
      means_of_navigation: "BUTTON"
      vertical_location: row
      horizontal_location: col
    }
    m.top.navigateWithinPageInfo = navigateWithinPageInfo

  end if

  if itemPosition <> invalid AND itemPosition.count() = 2
    channel = channelItem.content.getChild(itemPosition[0])
    if m.playOnFocusMode = true or m.top.linearChannelToPlay = invalid 'anytime linearChannelToPlay is invalid, assign focused channel to play?
      if channel <> invalid AND channel.videoResources <> invalid
        m.top.linearChannelToPlay = channel
        m.top.linearChannelToPlayUpdated = true
      end if
    end if
    if channel <> invalid AND channel.getChildCount() > 0
      program = channel.getChild(itemPosition[1])
      m.top.linearChannelFocused = program
      m.top.linearChannelFocusedUpdated = true
      if m.playOnFocusMode <> true
        if isProgramLive(program) = true or program.startTime = 0 or program.endTime = 0
          fade(m.backToLive, "out", 0.1, 0, 0)
        else
          fade(m.backToLive, "in", 0.1, 0, 1)
        end if
      end if
    end if
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
            setComponentInteractionEventForLiveAndFuturePrograms(programItem, row, col)
            m.top.linearChannelToPlayUpdated = true
          end if
        else ' setting selected field to true, will change display to indicate that the selected program is future program (orange color font and appended with "Starts at")
          programItem.selected = true
          setComponentInteractionEventForLiveAndFuturePrograms(programItem, row, col)
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
  if m.top.isInFocusChain() = true
    m.ProgramGrid.setFocus(true)
    if m.updateMinsLeftTimer.control <> "start"
      m.updateMinsLeftTimer.control = "start"
      if m.programGrid.content <> invalid
        'UpdateMinsLeftTimer might take a whole min to update after content has been rendered.
        'Call this function to ensure current program shows how much time left on the program on every time timeGrid first gets focus.
        onUpdateMinsLeftTimer()
      end if
    end if
  else
    m.updateMinsLeftTimer.control = "stop"
  end if
End Function


Function onRowFocused(msg)
  tubiLog("ProgramGrid.onRowFocused")
  focusPos = msg.getData()
  newFocus = Int(focusPos)
  if focusPos > m.programGrid.itemUnfocused
    if newFocus < focusPos
      newFocus += 1
    end if
  end if
  if newFocus <> m.lastFocused
    m.channelsGrid.jumpToItem = newFocus
    m.lastFocused = newFocus
    m.headerText.text = m.channelsGrid.content.getchild(newFocus).parentTitle
  end if
End Function


'based on m.top.jumpToLinearChannelID, this function will jump to channel
Function onJumpToLinearChannelID()
  tubiLog("ProgramGuide.onJumpToLinearChannelID")
  if m.programGrid.content <> invalid AND m.top.jumpToLinearChannelID <> invalid AND m.top.jumpToLinearChannelID.count() = 2
    for i = 0 to m.programGrid.content.getchildCount() - 1
      item = m.programGrid.content.getchild(i)
      if item.id = m.top.jumpToLinearChannelID[0]
        m.programGrid.jumpToRowItem = [i , 0]
        if item <> invalid AND item.getChildCount() > 0
          program = item.getChild(0)
          m.top.linearChannelFocused = program
          '//::TODO:: EPG - why doesn't setting of linearChannelFocusedUpdated trigger EPGScreen.onLinearChannelFocused from calling?
          m.top.linearChannelFocusedUpdated = true

          if m.top.shouldSendComponentInteractionEventOnJumpToLinearChannelId = true
            m.top.shouldSendComponentInteractionEventOnJumpToLinearChannelId = false
            rowNum = i + 1
            colNum = 1
            setComponentInteractionEventForLiveAndFuturePrograms(program, rowNum, colNum)
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
  now = getCurrentLocalTime(m.constants)



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


Function onOkPressed()
  tubiLog("ProgramGrid.onOkPressed")
  if m.top.linearChannelFocused <> invalid AND isProgramLive(m.top.linearChannelFocused)
   itemPosition =  m.programGrid.rowItemFocused
    m.top.linearChannelToPlay = m.top.linearChannelFocused.getParent()
    m.top.linearChannelToPlayUpdated = true
    m.top.okPressed = true
    channelItem = m.programGrid.content.getChild(itemPosition[0])
    if channelItem <> invalid AND channelItem.getChildCount() > 0
      programItem = channelItem.getChild(itemPosition[1])
      row = itemPosition[0] + 1
      col = itemPosition[1] + 1
      setComponentInteractionEventForLiveAndFuturePrograms(programItem, row, col)
    end if
  end if
End Function


'TODO : We would like to refactor this functionality in future.
'Currently this function is taking the request from outside(EPGScreen) and setting the focused item as  'LinearchannelToPlay'
'this functionality is required to handle situations where EPG is asked to behave differently in 'PlayOnSelect' Mode.
'for example when EPG starts, without user selecting a channel, EPGScreen needs to play first channel in minimized window.
'other example would be, when user lands on EPG from sideNav/topNav.
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
Function setComponentInteractionEventForLiveAndFuturePrograms(content, rowNum, colNum)
  componentValues = {
    content_tile: m.Tracking.getAnalyticsTile(content, colNum, rowNum)
  }
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
    componentOneof: m.Tracking.getAnalyticsComponent("epg_component",  componentValues)
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
    else if rowItemFocused[1] = 0 AND rowItemFocused[0] = lastItemFocused[0] AND (m.programGrid.kepPressed = "up" or m.programGrid.kepPressed = "down")
      isEqual = false
    end if
  end if
  return isEqual
End Function

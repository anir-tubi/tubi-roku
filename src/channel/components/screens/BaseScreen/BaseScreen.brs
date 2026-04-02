Function init()
  m.audioGuide = CreateObject("roAudioGuide")
  m.defaultBackgroundUri = ""

  m.top.trackingLoadStartTime = UpTime(0)
End Function


Function determineBackgroundImage(content)
  if isNode(content) = true AND isNonEmptyArray(content.backgrounds) = true then
    return content.backgrounds
  else
    if isNonEmptyString(m.defaultBackgroundUri) = true
      return [m.defaultBackgroundUri]
    else
      return []
    end if
  end if
End Function


'This function will tell you whether audioGuide enabled or not.
'AudioGuide supported devices:  Roku Streaming Stick (3600X), Roku Express (3700X) and Express+ (3710X),
'Roku Premiere (4620X) and Premiere+ (4630X), Roku Ultra (4640X), and any Roku TV running Roku OS version 7.5 and late
Function isRokuAudioGuideEnabled()
  deviceInfo = CreateObject("roDeviceInfo")

  return deviceInfo.isAudioGuideEnabled()
End Function


'This function will read the passing text to be spoken.
'@textToRead: String, The string to be spoken.
'@isFlush: boolean, set to true to make the screen reader immediately stop speaking any other speech before speaking, otherwise set to false
'@isRepeat: boolean, set to true will ignore reading the same text, otherwise set to false.
Function readAudioGuideText(textToRead as String, isFlush = true as Boolean, isRepeat = true as Boolean)
  if isRokuAudioGuideEnabled() = true AND m.audioGuide <> invalid
    m.audioGuide.say(textToRead, isFlush, isRepeat)
  end if
End Function


' Processes bulk listing refresh data for this screen.
' Position data is bundled with the response by VideoTileHelpers (snapshotted at fetch time),
' so this function does not read from the global pendingListingRefreshData.
' For each schedule ID, it either updates the child's scheduleData if the event is still active,
' or marks it for removal if the event has ended. Expired children are batch-removed using
' removeChildren() to avoid triggering multiple RowList refreshes. If all children in a container
' have ended, the entire container is removed instead of removing individual children.
'
' Can be called from any screen that extends BaseScreen (e.g. VideoTilesScreen, HomeScreen).
' @param data - AA with { listings: AA keyed by scheduleId, positions: AA keyed by scheduleId with arrays of { rowIndex, columnIndex, contentId } }
Function processListingRefreshData(data) as Void
  if data = invalid OR m.top.content = invalid then return

  response = data.listings
  screenData = data.positions
  if response = invalid OR screenData = invalid then return

  ' First pass: iterate through each registered schedule ID for this screen.
  ' For active events, update scheduleData in place at all positions.
  ' For ended events, group them by container for batch removal.
  expiredByContainer = {}
  for each scheduleId in screenData.keys()
    listing = response[scheduleId]
    if isAA(listing) = false OR isNonEmptyString(listing.startTime) = false then continue for

    positions = screenData[scheduleId]
    if isNonEmptyArray(positions) = false then continue for

    for each posInfo in positions
      ' Use stored position info to directly locate the content node
      container = m.top.content.getChild(posInfo.rowIndex)
      if container = invalid then continue for

      ' Verify contentId still matches to guard against stale position data after content refresh
      child = container.getChild(posInfo.columnIndex)
      if child = invalid OR child.id <> posInfo.contentId then continue for

      if isGreaterThanCurrentTime(listing.endTime) = false
        ' Event has ended — collect for batch removal
        containerId = container.id
        if expiredByContainer[containerId] = invalid
          expiredByContainer[containerId] = { container: container, children: [] }
        end if
        expiredByContainer[containerId].children.push(child)
      else
        ' Event still active — update with fresh schedule data
        child.scheduleData = listing
      end if
    end for
  end for

  ' Second pass: batch remove expired content.
  ' If all children in a container have ended, remove the container itself to avoid
  ' removing children first and then the empty container (which would cause two refreshes).
  containersToRemove = []
  for each containerId in expiredByContainer.keys()
    info = expiredByContainer[containerId]
    if info.container.getChildCount() <= info.children.count()
      containersToRemove.push(info.container)
    else
      info.container.removeChildren(info.children)
    end if
  end for

  if containersToRemove.count() > 0
    m.top.content.removeChildren(containersToRemove)
  end if
End Function

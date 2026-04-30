Function showCollectionScreen(appId, sourceContentId = "", sotBadgeType = "")
  screen = createScreen("CollectionScreen")

  screen.observeFieldScoped("selectedContentIndex", "onCollectionScreenSelectedContentIndexChanged")
  screen.observeFieldScoped("playContentIndex", "onCollectionScreenPlayContentIndexChanged")

  pageValues = {
    id: appId
    section: UCase(m.constants.ui.appTypes.creator)
  }

  if isNonEmptyString(sourceContentId) = true
    pageValues.sourceContentId = sourceContentId
    screen.sourceContentId = sourceContentId
  else
    screen.sourceContentId = ""
  end if

  screen.trackingPageInfo = {
    pageType: "collection_page"
    pageValues: pageValues
  }

  screen.sotBadgeType = sotBadgeType

  screen.appId = appId

  screen.isStackable = true

  showHideSpinner(true)
  pushScreen(screen, true, false)
End Function


Function onCollectionScreenPlayContentIndexChanged(msg)
  ' For the time being we can use the same handler as item selection always plays currently
  onCollectionScreenSelectedContentIndexChanged(msg)
End Function


Function onCollectionScreenSelectedContentIndexChanged(msg) as Void
  selectedIndex = msg.getData()
  screen = msg.getRoSGNode()

  rowListContent = screen.content
  if isNonEmptyArray(selectedIndex) = false OR rowListContent = invalid then
    return
  end if

  rowContent = rowListContent.getChild(selectedIndex[0])
  if rowContent = invalid then
    logWarn("Warning: No rowContent found for rowListContent id: " + rowListContent.id + " at index: " + selectedIndex[0].toStr())
    return
  end if

  playbackSource = {
    "srcForAnalytic": m.constants.player.playbackSource.unknown
    "srcForAds": m.constants.player.playbackOrigin.container
    "playbackContainer": rowContent.id
  }

  if selectedIndex.count() > 1 then
    itemContent = rowContent.getChild(selectedIndex[1])
    if itemContent = invalid then
      logWarn("Warning: No itemContent found for rowContent id: " + rowContent.id + " at index: " + selectedIndex[1].toStr())
      return
    end if

    processUserPlayAction(itemContent, screen, playbackSource)
  else
    relatedTo = rowContent.relatedTo
    if relatedTo <> invalid then
      processUserContentSelection(relatedTo, screen, playbackSource)
    else
      logWarn("Warning: No relatedTo content found for rowContent id: " + rowContent.id)
    end if
  end if
End Function


' @content - screen.content for VOD/detail (series or movie)
Function getSotBadgeType(content)
  if content = invalid
    return ""
  end if

  return getTubiExclusiveSotSignalsFromSotInfo(content.sotInfo).badgeType
End Function

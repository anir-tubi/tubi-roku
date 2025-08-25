Function init()
  tubiLog("CategoryGridList.init")
  m.constants = getConstantsFromGlobal()

  m.top.observeFieldScoped("categoryResponseInBatch", "onCategoryResponseInBatch")
  m.top.observeFieldScoped("adResponseInBatch", "onAdResponseInBatch")
  m.top.observeFieldScoped("focusedChild", "onComponentFocusChange")
  m.top.observeFieldScoped("jumpToRowItemByID", "onJumpToRowItemByIDChange")
  m.top.observeFieldScoped("contentUpdated", "onContentChange")
  m.top.observeFieldScoped("repopulateContent", "onRepopulateContent")
  m.top.observeFieldScoped("removeFocusFromRowList", "onRemoveFocusFromRowList")
  m.top.observeFieldScoped("signedIn", "onSignedInChange")
  m.top.observeFieldScoped("parentScreenTrackingPageInfo", "onParentScreenTrackingPageInfoChange")
  m.top.observeFieldScoped("kidsMode", "onKidsModeChange")
  m.top.observeFieldScoped("containerAppendMoreTilesStatus", "onContainerAppendMoreTilesStatusChange")
  m.top.observeFieldScoped("animateToItem", "onAnimateToItemChange")

  m.RowList = m.top.findNode("RowList")
  m.RowList.observeFieldScoped("rowItemFocused", "onRowItemFocused")
  m.RowList.observeFieldScoped("rowItemSelected", "onRowItemSelected")

  m.featuredRowList = m.top.findNode("featuredRowList")
  m.featuredRowList.observeFieldScoped("rowItemFocused", "onFeaturedRowItemFocused")
  m.featuredRowList.observeFieldScoped("rowItemSelected", "onFeaturedRowItemSelected")
  m.featuredRowList.observeFieldScoped("currFocusColumn", "onFeaturedRowCurrFocusColumnChange")
  m.featuredRowList.observeFieldScoped("currFocusRow", "onFeaturedListCurrFocusRowChange")
  m.featuredRowList.observeFieldScoped("vertFocusDirection", "onVertFocusDirectionChange")
  m.top.observeFieldScoped("featuredRowContent", "onFeaturedRowContentChange")

  experimentsInfo = getExperimentsInfoFromGlobal()
  experiments = TubiExperiments(experimentsInfo)
  soTStaticConfig = getSoTStaticConfigFromGlobal()
  m.metadataTranslate = TubiMetadataTranslate(m.constants, experiments, soTStaticConfig)

  m.RowList.drawFocusFeedbackOnTop = true

  ' stores an array of the form [y, x], which can be set on RowList.jumpToItem
  m.itemToJumpTo = invalid

  m.LinearProgramRefreshTimer = m.top.findNode("LinearProgramRefreshTimer")
  m.LinearProgramRefreshTimer.observeFieldScoped("fire", "onLinearProgramRefreshTimer")

  m.skinAdRow = m.top.findNode("skinAdRow")
  m.skinAdRow.observeFieldScoped("rowItemSelected", "onSkinAdRowItemSelected")
  m.skinAdRow.observeFieldScoped("rowItemFocused", "onSkinAdRowItemFocused")

  m.originalTranslationSkinAdRow = m.skinAdRow.translation

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
  onThemeChange()

  ' Holds the value of last focused list, possible values are "", "skinAdRow" "rowlist".
  ' These IDs match with the IDs of the components in the XML.
  m.top.lastFocusedList = ""

  m.lastCurrentFocusColumn = 0
  m.lastFocusColumnIndex = 0

  experiment = getExperimentResource("roku_home_screen_redesign", "roku_home_screen_redesign_v_1_4_restart", false)
  if isNonEmptyArray(experiment.featuredRowPosterSize) = true
    m.featuredRowPoster = experiment.featuredRowPosterSize
  else
    m.featuredRowPoster = m.constants.ui.imageSizes.featuredRowPoster
  end if

  if isNonEmptyArray(experiment.gridItemSize) = true
    m.gridItemSize = experiment.gridItemSize
  else
    m.gridItemSize = m.constants.ui.imageSizes.featuredPortraitSmall
  end if

  m.expandedTileFocusXOffset = m.featuredRowPoster[0] - m.gridItemSize[0] + 4

  ' 263 is the height of the metadata section displayed beneath the featured focused tile.
  ' 263 also includes the space between the last line of the description and container below it.
  m.rowListPosition = [0, 263 + m.featuredRowPoster[1]]
  m.homeScreenDesignType = experiment.design_type
  m.isWithDescPortraitSmallExpEnabled = (m.homeScreenDesignType = "withDescriptionPortraitSmall")

  m.ignoreCurrColumnChange = false
End Function


Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.RowList.focusBitmapBlendColor = theme.focusedColor
    m.FeaturedRowList.focusBitmapBlendColor = theme.focusedColor
  end if
End Function


Function onFeaturedRowContentChange(msg)
  m.featuredRowList.update({
    parentScreenId: m.top.parentScreenId
    parentScreenTrackingPageInfo: m.top.parentScreenTrackingPageInfo
    personalizationId: m.top.personalizationId
    shouldTrackViewableImpressionEvent: m.top.shouldTrackViewableImpressionEvent
    rowIndexBoost: 0
  }, true)

  m.featuredRowList.content = msg.getData()
End Function


Function onFeaturedRowItemSelected(msg)
  tubiLog("CategoryGridList.onFeaturedRowItemSelected")
  featuredItemSelected = msg.getData()
  m.top.selectedPosition = featuredItemSelected

  itemSelected = resolveAbbreviatedContent(m.top.featuredRowContent, featuredItemSelected)
  if itemSelected <> invalid
    m.top.featuredItemSelected = itemSelected
  end if
End Function


Function onRemoveFocusFromRowList()
  m.RowList.setFocus(false)
End Function


' This function is used to handle the case where the row list is focused and we are appending more tiles to the row list.
' @param msg - The message object containing the status of the container append more tiles operation.
Function onContainerAppendMoreTilesStatusChange(msg)
  status = msg.getData()

  ' NOTE: This is to handle a edge case bug only happens when we fast scroll by press and hold.
  ' NOTE: Theory is that when we fast scroll and when roku is trying to scroll through items rapidly and we are also appending items at the same time it messes up internal logic of row list.
  ' The idea around below logic is to handle the case where when we append more tiles to the row list, we need to reset the focus to the correct item.
  ' This is required because whenever we append more children to the row list, the focus position is reset to zero.
  ' So in the below logic before we start appending we check if there is a difference between currFocusColumn and rowItemFocused[1], this indicates to us that user is fast scrolling because when user press and hold only currFocusColumn changes and rowItemFocused[1] is updated only when user releases the press.
  ' So we store the value of where the user position is when we start appending and then we jump to that position when we are done appending.
  ' This way user press and hold is seem less.
  ' TODO: Revisit the logic below and remove either if or else based on whether we graduated roku_home_screen_redesign_v_1_4_restart experiment.
  ' TODO: Revisit logic inside onComponentFocusChange since that gets triggered a lot of times during navigation we might not need that logic. Not changing now to avoid scope creep for this PR.
  if m.isWithDescPortraitSmallExpEnabled = true
    if status = "start" AND isNonEmptyArray(m.featuredRowList.rowItemFocused) = true AND (m.featuredRowList.rowItemFocused[0] = m.featuredRowList.currFocusRow AND m.featuredRowList.rowItemFocused[1] <> m.top.featuredRowCurrFocusColumn)
      m.resetListPositionOnRepopulateToIndex = [m.featuredRowList.currFocusRow, m.top.featuredRowCurrFocusColumn]
    else if isNonEmptyArray(m.resetListPositionOnRepopulateToIndex) = true
      m.FeaturedRowList.jumpToRowItem = m.resetListPositionOnRepopulateToIndex
      m.resetListPositionOnRepopulateToIndex = invalid
    end if
  else
    if status = "start" AND isNonEmptyArray(m.RowList.rowItemFocused) = true AND (m.RowList.rowItemFocused[0] = m.RowList.currFocusRow AND m.rowList.rowItemFocused[1] <> m.rowList.currFocusColumn)
      m.resetListPositionOnRepopulateToIndex = [m.RowList.currFocusRow, CInt(m.RowList.currFocusColumn)]
    else if isNonEmptyArray(m.resetListPositionOnRepopulateToIndex) = true
      m.RowList.jumpToRowItem = m.resetListPositionOnRepopulateToIndex
      m.resetListPositionOnRepopulateToIndex = invalid
    end if
  end if
End Function


Function onJumpToRowItemByIDChange()
  tubiLog("CategoryGridList.onJumpToRowItemByIDChange")
  sDesiredContainerID = ""
  sContentID = ""
  if m.top.jumpToRowItemByID <> invalid
    sContentID = m.top.jumpToRowItemByID[0]
    sDesiredContainerID = m.top.jumpToRowItemByID[1]
  end if

  if m.isWithDescPortraitSmallExpEnabled = true AND m.featuredRowList.content <> invalid
    content = m.featuredRowList.content
  else
    content = m.RowList.content
  end if

  '//Loop thru the containers to find the content item with an ID that matches sContentID and focus on that content item
  for i = 0 to content.getChildCount() - 1
    container = content.getChild(i)
    sTempContainerID = container.id
    if sDesiredContainerID = sTempContainerID OR sDesiredContainerID = ""
      for j = 0 to container.getChildCount() - 1
        item = container.getChild(j)
        if item.id = sContentID
          'focus on the item
          if m.isWithDescPortraitSmallExpEnabled = true
            m.featuredRowList.jumpToRowItem = [i, j]
          else
            m.RowList.jumpToRowItem = [i, j]
          end if
          return true
        end if
      end for
    end if
  end for
  return false
End Function


'''''''''''''''''''''''''
' onComponentFocusChange
'
Function onComponentFocusChange(msg)
  tubiLog("CategoryGridList.onComponentFocusChange " + focusState(m.top))
  if m.top.lastFocusedList = "featuredRowlist"
    content = m.top.featuredRowContent
  else
    content = m.top.content
  end if

  itemToJumpTo = invalid
  if m.itemToJumpTo <> invalid AND resolveAbbreviatedContent(content, m.itemToJumpTo) <> invalid then
    itemToJumpTo = m.itemToJumpTo
  end if
  m.itemToJumpTo = invalid

  ' If top has focus then we need to focus the RowList itself
  if m.top.hasFocus() = true then
    if (isSkinAdsAvailable() = true) AND (m.top.lastFocusedList = "skinAdRow" OR m.top.lastFocusedList = "")
      m.top.lastFocusedList = "skinAdRow"
      m.skinAdRow.opacity = 1
      m.skinAdRow.setFocus(true)
    else if m.isWithDescPortraitSmallExpEnabled = true AND m.FeaturedRowList.content <> invalid AND (m.top.lastFocusedList = "featuredRowList" OR m.top.lastFocusedList = "")
      m.top.lastFocusedList = "featuredRowList"
      m.FeaturedRowList.setFocus(true)
    else
      ' Don't want to do any of this logic if we are already have an item we are going to jump to
      if itemToJumpTo = invalid then

        rowItemFocused = m.RowList.rowItemFocused

        if rowItemFocused.count() = 2
          '// If count does not equal 2 then the rowList has not gained focus yet so use the default first item in the else block
          itemToJumpTo = rowItemFocused
        else
          itemToJumpTo = [0, 0]
        end if
      end if

      if resolveAbbreviatedContent(content, itemToJumpTo) <> invalid
        m.top.lastFocusedList = "rowList"
        m.RowList.setFocus(true)

        ' Adding to check to make sure if reset grid position was requested.
        ' Making sure we are resetting after focus is set to rowlist.
        if m.top.resetGridPosition = true
          itemToJumpTo = [0, 0]
          m.top.resetGridPosition = false
        end if
      end if

      m.LinearProgramRefreshTimer.control = "start"
      ' When Grid get focus refresh all visible channels
      onLinearProgramRefreshTimer()
    end if
  else if m.top.isInFocusChain() = false
    m.LinearProgramRefreshTimer.control = "stop"
  end if

  ' We used to only jump to if m.top had focus. In some cases we would not jump back to the correct item after we modified the RowList content which triggers a jump to the first position usually. Now if we have a m.itemToJumpTo we will always jump to it when we receive a focus change event
  if itemToJumpTo <> invalid then
    m.RowList.jumpToRowItem = itemToJumpTo
  end if

  if m.isWithDescPortraitSmallExpEnabled = true
    m.top.featuredListHasFocus = m.top.isInFocusChain() = true AND m.top.lastFocusedList = "featuredRowList" AND m.top.featuredRowContent <> invalid
  end if
End Function


Function onContentChange()
  tubiLog("CategoryGridList.onContentChange")

  ' Resetting the state of the UI. Below condition safe guards against any rowList background refresh.
  ' Like item getting added to CW row or queue row.

  ' Below condition is needed to handle a case where skinAdRow was visible.
  ' But during refresh it has been removed.
  if m.top.lastFocusedList = "skinAdRow" AND isSkinAdsAvailable() = false
    m.skinAdRow.opacity = 0
    m.top.lastFocusedList = ""
  end if

  ' When the rowlist is in focus, we need to hide the featuredRowList.
  ' In place of featuredRowList, we will show the info panel.
  if m.top.lastFocusedList <> "rowList" AND m.top.featuredRowContent <> invalid
    m.FeaturedRowList.opacity = 1
  end if

  bSetRowListFocus = false
  '//RESET position of 1st-row elements
  m.skinAdRow.translation = m.originalTranslationSkinAdRow


  ' set the translation position of the page based on presense or absence of any 1st rows.
  ' DO this BEFORE setting the content of the rowList (later in this function) or else the translation will not be properly set.
  ' This is need mainly for the initial load and if skinAdRow is focused.
  ' When any other list is focused, we will not show the skin ads.
  if isSkinAdsAvailable() = true AND (m.top.lastFocusedList = "skinAdRow" OR m.top.lastFocusedList = "")
    if m.top.featuredRowContent <> invalid
      m.FeaturedRowList.translation = [0, 384]
    else
      m.rowList.translation = [0, 384]
    end if

    m.skinAdRow.opacity = 1
    m.top.lastFocusedList = "skinAdRow"
    category = m.top.skinAdContent.getChild(0)
    if category <> invalid
      content = category.getChild(0)
      m.top.reloadedItemToBeFocused = content
    end if
  else
    ' Resetting the state of the UI.
    if m.top.featuredRowContent <> invalid
      ' This is needed only for initial load and not needed for subsequent loads.
      ' This is required for initial slide down animation.
      if m.top.lastFocusedList = ""
        m.FeaturedRowList.translation = [0, 0]
        if m.isWithDescPortraitSmallExpEnabled = true
          ' 92 is the amount of px we need to animate down to create a required initial animation.
          ' This allows to create a slide down animation.
          m.rowList.translation = [0, m.featuredRowPoster[1] + 92]
        else
          m.RowList.translation = [0, 0]
        end if
      end if
    else
      m.RowList.translation = [0, 0]
    end if

    m.skinAdRow.opacity = 0
    bSetRowListFocus = true
  end if

  if m.top.content = invalid
    m.RowList.content = invalid
    '//reset some values. According to the Roku documentation, these fields should be read only but they seem to be writable.
    if m.RowList.currFocusColumn <> invalid
      m.RowList.currFocusColumn = 0
    end if
    m.RowList.rowItemFocused = [0, 0]
    m.RowList.currFocusRow = 0
    if m.top.featuredRowContent <> invalid
      setFeaturedRowHeights()
      if bSetRowListFocus = true
        setRowListFocus()
      end if
    end if
  else
    ' Setting RowList invalid here will empty the grid.  It will be set after the first batch of
    ' metadata is received.  Setting RowList.content with a few full categories will cause it to prefetch
    ' posters and do a nice fade-in.
    m.RowList.content = invalid
    if m.top.content <> invalid then
      setRowHeights()

      if bSetRowListFocus = true
        setRowListFocus()
      end if
    end if
  end if

  ' Since we are splitting grid content into two RowLists, we need to take into account rows that are in above rows.
  m.RowList.update({
    parentScreenId: m.top.parentScreenId
    parentScreenTrackingPageInfo: m.top.parentScreenTrackingPageInfo
    personalizationId: m.top.personalizationId
    shouldTrackViewableImpressionEvent: m.top.shouldTrackViewableImpressionEvent
    rowIndexBoost: 0
  }, true)

  ' Below is to add animation of slide down of the row list for the first time when screen is loaded.
  if m.top.featuredRowContent <> invalid AND isSkinAdsAvailable() = false AND m.isWithDescPortraitSmallExpEnabled = true AND m.top.lastFocusedList <> "rowList"
    slideTo(m.RowList, [m.rowListPosition[0], m.rowListPosition[1]], 0.3, 0.3)
  end if

  updateCurrentFocusedItemBoundingRect()

  m.top.gridContentIsReady = true
End Function


Function onParentScreenTrackingPageInfoChange(msg)
  ' Since we are splitting grid content into two RowLists, we need to take into account rows that are in above rows.
  m.RowList.update({
    parentScreenTrackingPageInfo: m.top.parentScreenTrackingPageInfo
    personalizationId: m.top.personalizationId
  }, true)

  m.FeaturedRowList.update({
    parentScreenTrackingPageInfo: m.top.parentScreenTrackingPageInfo
    personalizationId: m.top.personalizationId
  }, true)
End Function


' onRepopulateContent callback gets triggered when adding/removing any row
' it sets RowHeight and jumps the focus to a specified content.
Function onRepopulateContent()
  if m.top.content <> invalid
    setRowHeights()
  end if

  rowItemFocused = m.RowList.rowItemFocused
  if m.itemToJumpTo <> invalid
    rowItemFocused = m.itemToJumpTo
  end if

  if rowItemFocused = invalid
    rowItemFocused = [0, 0]
  end if

  rowAdded = m.top.rowAdded
  rowRemoved = m.top.rowRemoved

  ' Resetting rowAdded & rowRemoved
  m.top.rowAdded = ""
  m.top.rowRemoved = ""

  if m.top.lastFocusedList = "featuredRowlist"
    content = m.top.featuredRowContent
  else
    content = m.top.content
  end if

  ' setting the rowItemSize and/or rowHeights moves the focus indicator back to the origin so
  ' we need to move the focus back to it's appropriate place. But we need to check that there is content
  ' at the location or else the RowList loses focus and can't get it back.
  if resolveAbbreviatedContent(content, rowItemFocused) <> invalid
    ' re-focus the most recently focused content
    m.itemToJumpTo = rowItemFocused
  else if resolveAbbreviatedContent(content, [rowItemFocused[0], 0]) <> invalid
    ' if there is no content at the most recently focused coordinates, then
    ' check if there is at least one content in the most recently focused row and focus the last content in the row
    rowIndex = 0
    if rowItemFocused[0] <> invalid
      rowIndex = rowItemFocused[0]
    end if

    lastContentIndex = m.top.content.getChild(rowIndex).getChildCount() - 1
    m.itemToJumpTo = [rowIndex, lastContentIndex]
  else
    ' if there is no content at the most recently focused coordinates, and
    ' there is no content in the most recently focused row, then
    ' check if there is any content in each row prior to the most recently focused row
    ' and focus the first content in that row
    rowIndex = 0
    if rowItemFocused[0] <> invalid
      rowIndex = rowItemFocused[0]
    end if

    while resolveAbbreviatedContent(content, [rowIndex, 0]) = invalid AND rowIndex >= 0
      rowIndex -= 1
    end while

    m.itemToJumpTo = [rowIndex, 0] ' m.itemToJumpTo might equal [-1, 0] in worst case scenario
  end if

  ' there are 4 options here
  ' 1) new continue_watching row got inserted, so increment the focus index by 1
  ' 2) new queue row got inserted, so increment the focus index by 1
  ' 3) continue_watching row got removed, so decrement the focus index by 1
  ' 4) queue row got removed, so decrement the focus index by 1
  if m.Rowlist <> invalid AND m.Rowlist.content <> invalid AND rowItemFocused[0] <> invalid
    if rowAdded = m.constants.ui.categoryIds.history
      if rowItemFocused[0] >= m.RowList.content.continueWatchingIndex
        m.itemToJumpTo = [m.itemToJumpTo[0] + 1, m.itemToJumpTo[1]]
      end if
    else if rowAdded = m.constants.ui.categoryIds.queue
      if rowItemFocused[0] >= m.RowList.content.queueIndex
        m.itemToJumpTo = [m.itemToJumpTo[0] + 1, m.itemToJumpTo[1]]
      end if
    else if rowRemoved = m.constants.ui.categoryIds.history
      if rowItemFocused[0] >= m.RowList.content.continueWatchingIndex
        m.itemToJumpTo = [m.itemToJumpTo[0] - 1, m.itemToJumpTo[1]]
      end if
    else if rowRemoved = m.constants.ui.categoryIds.queue
      if rowItemFocused[0] >= m.RowList.content.queueIndex
        m.itemToJumpTo = [m.itemToJumpTo[0] - 1, m.itemToJumpTo[1]]
      end if
    end if
  end if

  ' We need to make sure the focused item is updated to account for cases where container content is updated.
  if m.isWithDescPortraitSmallExpEnabled = true
    updateFeaturedRowItemFocused()
  end if
End Function


Function setRowHeights()
  'determine the height of each row in the RowList so we can set it on RowList.rowItemSize
  rowItemSize = []
  rowHeights = []
  rowItemSpacings = []
  focusXOffsets = []
  numRows = 2
  imageSizes = m.constants.ui.imageSizes
  posterSize = imageSizes.largePoster
  landscapeSize = imageSizes.largeLandscape
  featuredRowPoster = imageSizes.featuredRowPoster
  liveEventsContainerSize = imageSizes.liveEventsContainer
  bannerSize = imageSizes.banner
  showRowLabel = []

  for i = 0 to m.top.content.getChildCount() - 1
    category = m.top.content.getChild(i)
    rowHeight = 0
    rowHeightAdjustment = 57 '//The height of the row container heading and its vertical spacing
    gridItemType = category.gridItemType
    gridItemTypes = m.constants.ui.gridItemTypes

    if gridItemType = gridItemTypes.liveEventSpotlight
      rowItemSize.push(liveEventsContainerSize)
      rowHeight = liveEventsContainerSize[1]
    else if gridItemType = gridItemTypes.liveEventBanner
      rowItemSize.push(bannerSize)
      rowHeight = bannerSize[1]
    else if gridItemType = gridItemTypes.historySignedOutUser
      posterHeight = posterSize[1]
      rowItemSize.push([1693, posterHeight])
      rowHeight = posterHeight
      rowItemSpacings.push([15, 0])
      focusXOffsets.push(0)
    else if gridItemType = gridItemTypes.banner
      bannerSize = m.constants.ui.imageSizes.banner
      rowItemSize.push(bannerSize)
      rowHeight = bannerSize[1]
      rowItemSpacings.push([10, 0])
      focusXOffsets.push(0)
    else if gridItemType = gridItemTypes.adRowlistSpotlight OR gridItemType = gridItemTypes.adRowlistCarousel
      adSize = m.constants.ui.imageSizes.adRowlistThumbnail
      rowItemSize.push(adSize)
      rowHeight = adSize[1]
      rowItemSpacings.push([15, 0])
      focusXOffsets.push(0)
      numRows = 3
    else if gridItemType = gridItemTypes.portrait OR gridItemType = gridItemTypes.certifiedFresh
      posterWidth = posterSize[0]
      posterHeight = posterSize[1]
      rowItemSize.push([posterWidth, posterHeight])
      rowHeight = posterHeight
      rowItemSpacings.push([15, 0])
      focusXOffsets.push(0)
    else if gridItemType = gridItemTypes.portraitTopTen
      posterWidth = posterSize[0]
      posterHeight = posterSize[1]
      rowItemSize.push([posterWidth, posterHeight])
      rowHeight = posterHeight
      rowItemSpacings.push([243, 0])
      'push the focus indicator to the right so it doesn't cover the top ten label
      focusXOffsets.push(243)
    else if gridItemType = gridItemTypes.landscape OR gridItemType = gridItemTypes.landscapeNoTitle OR gridItemType = gridItemTypes.linear
      if gridItemType = gridItemTypes.landscapeWithMetadata
        posterWidth = featuredRowPoster[0]
        posterHeight = featuredRowPoster[1]
      else
        posterWidth = landscapeSize[0]
        posterHeight = landscapeSize[1]
      end if

      if gridItemType = gridItemTypes.landscape then
        rowHeightAdjustment = rowHeightAdjustment + 21
      end if
      rowItemSize.push([posterWidth, posterHeight])
      rowHeight = posterHeight
      rowItemSpacings.push([15, 0])
      focusXOffsets.push(0)
    end if
    shouldDisplayHeader = arrayIncludes(m.constants.ui.noHeaderGridTypes, category.gridItemType) = false
    showRowLabel.push(shouldDisplayHeader)

    if category.sponsorImages <> invalid
      '//if this is a sponsored row, then adjust the spacing so row includes the header size of the sponsored row
      rowHeightAdjustment = rowHeightAdjustment + 32
    end if
    rowHeights.push(rowHeight + rowHeightAdjustment)
  end for

  '//setting the height of the m.RowList.itemSize is superceded by the rowHeight of each row
  '//However, just in case the height of a row is not defined, then it will default to the height defined by itemSize
  itemSize = [1752, posterSize[1]]
  m.Rowlist.update({
    "itemSize": itemSize
    "rowItemSize": rowItemSize
    "rowHeights": rowHeights
    "showRowLabel": showRowLabel
    "numRows": numRows
    "rowItemSpacing": rowItemSpacings
    "focusXOffset": focusXOffsets
  })
  m.RowList.content = m.top.content
  setFeaturedRowHeights()
End Function


Function setFeaturedRowHeights()
  imageSizes = m.constants.ui.imageSizes
  guestCWPosterSize = imageSizes.guestContinueWatchingTile
  liveEventsContainerSize = imageSizes.liveEventsContainer
  bannerSize = imageSizes.banner

  gridItemTypes = m.constants.ui.gridItemTypes
  featuredRowContent = m.top.featuredRowContent

  if isNode(featuredRowContent) = true
    heights = []
    rowItemSize = []
    showRowLabel = []
    for i = 0 to featuredRowContent.getChildCount() - 1
      category = featuredRowContent.getChild(i)
      gridItemType = category.gridItemType

      ' 246 is the height of the metadata section displayed beneath the featured focused tile.
      featuredRowHeight = m.featuredRowPoster[1] + 246
      if category.sponsorImages <> invalid
        '// if this is a sponsored row, then adjust the spacing so row includes the header size of the sponsored row
        featuredRowHeight = featuredRowHeight + 32
      end if

      shouldDisplayHeader = arrayIncludes(m.constants.ui.noHeaderGridTypes, category.gridItemType) = false
      showRowLabel.push(shouldDisplayHeader)

      if gridItemType = gridItemTypes.liveEventSpotlight
        rowItemSize.push(liveEventsContainerSize)
        heights.push(liveEventsContainerSize[1])
      else if gridItemType = gridItemTypes.liveEventBanner
        rowItemSize.push(bannerSize)
        heights.push(bannerSize[1])
      else if gridItemType = gridItemTypes.historySignedOutUser
        rowItemSize.push(guestCWPosterSize)
        ' 80 is the padding below the poster.
        heights.push(guestCWPosterSize[1] + 80)
      else if gridItemType = gridItemTypes.adRowlistSpotlight OR gridItemType = gridItemTypes.adRowlistCarousel
        adSize = m.constants.ui.imageSizes.adRowlistThumbnail
        rowItemSize.push(adSize)
        heights.push(adSize[1] + 186)
      else
        rowItemSize.push(m.gridItemSize)
        heights.push(featuredRowHeight)
      end if
    end for

    m.FeaturedRowList.update({
      "showRowLabel": showRowLabel
      "rowItemSize": rowItemSize
      "rowHeights": heights
      "focusXOffset": [0]
    })

    if m.top.featuredRowFocusedItem = invalid AND m.skinAdRow.content = invalid
      if arrayIncludes(m.constants.ui.nonVideoTileGridItemTypes, featuredRowContent.getChild(0).gridItemType) = true
        m.featuredRowList.focusXOffset = [0, 0]
      else
        m.featuredRowList.focusXOffset = [m.expandedTileFocusXOffset, 0]
      end if
      m.FeaturedRowList.rowItemFocused = [0, 0]
      if m.isWithDescPortraitSmallExpEnabled = true
        m.top.lastFocusedList = "featuredRowList"
      end if
    end if
  end if
End Function


' Resolve and internal ContentNode that's been abbreviated for the CategoryGridList
' into a fully parsed TubiContentNode
'
' @content rowlist content node.
' @rowItemIndex is 2D array of [rowindex, itemindex] from RowList.rowItemSelected or m.RowList.rowItemFocused
Function resolveAbbreviatedContent(content, rowItemIndex)
  itemContent = invalid
  if content <> invalid AND rowItemIndex[0] <> invalid AND rowItemIndex[1] <> invalid
    contentId = invalid
    category = content.getChild(rowItemIndex[0])
    if category <> invalid
      itemContent = category.getChild(rowItemIndex[1])
      if itemContent <> invalid
        if itemContent.type = m.constants.ui.contentTypes.adRowlistSpotlight OR itemContent.type = m.constants.ui.contentTypes.adRowlistCarousel
          ' adRowlistSpotlight and adRowlistCarousel are not regular video content items so they were never abbreviated
          return itemContent
        end if
        contentId = itemContent.id
      end if
    end if

    if isNonEmptyString(contentId) = true
      singleContent = m.metadataTranslate.getContentFromCategoryJson(category, contentId, m.top.signedIn) ' can return invalid
      ' Adding additional temporary field to the content to handle the actionId for the live events.
      if isNonEmptyString(itemContent.actionId) = true
        singleContent.update({
          actionId: itemContent.actionId
        }, true)
      end if
      ' Since we are refreshing the tensor data from schedule endpoint we need to use node info rather than from category json
      if isAA(itemContent.scheduleData)
        singleContent.update({
          scheduleData: itemContent.scheduleData
        }, true)
      end if
      return singleContent
    end if
  end if

  return invalid
End Function


''''''''''''''''
' onRowItemSelected - RowList.rowItemSelected event handler, triggered when user presses "OK"
Function onRowItemSelected(msg)
  tubiLog("CategoryGridList.onRowItemSelected")
  if m.top.content <> invalid 'should not be necessary but crash reports show that it is.
    rowItemSelected = msg.getData()
    m.top.selectedPosition = rowItemSelected

    category = m.top.content.getChild(rowItemSelected[0])
    if category <> invalid
      m.top.oldCategoryId = m.top.currCategoryId
      m.top.currCategoryId = category.id
    end if
    itemSelected = resolveAbbreviatedContent(m.top.content, rowItemSelected)
    if itemSelected <> invalid
      m.top.itemSelected = itemSelected
    end if
  end if
End Function


'''''''''''''''
' onRowItemFocused - RowList.rowItemFocused event handler.
Function onRowItemFocused(msg)
  tubiLog("CategoryGridList.onRowItemFocused")
  rowItemFocused = msg.getData()
  m.top.focusedPosition = rowItemFocused

  if m.top.content <> invalid AND rowItemFocused <> invalid
    category = m.top.content.getChild(rowItemFocused[0])
    if category <> invalid then
      category.focusIndex = rowItemFocused[1]
      m.top.oldCategoryId = m.top.currCategoryId
      m.top.currCategoryId = category.id

      itemFocused = resolveAbbreviatedContent(m.top.content, rowItemFocused)
      if itemFocused <> invalid
        m.top.oldCursorPosition = m.top.cursorPosition
        m.top.cursorPosition = m.top.focusedPosition
        m.top.oldItemFocused = m.top.itemFocused
        m.top.rowFocused = m.top.content.getChild(rowItemFocused[0])
        m.top.itemFocused = itemFocused
      end if
    end if
  end if
End Function


Function onAdResponseInBatch(msg) as Void
  tubiLog("CategoryGridList.onAdResponseInBatch")

  aResponse = msg.getData()
  if isNonEmptyArray(aResponse) = true
    content = m.top.content

    '//Process the batch into categories for update
    processResult = processAdBatchResponse(aResponse, content)
    aAdsToAdd = processResult.aAdsToAdd
    aAdsToReplace = processResult.aAdsToReplace
    removableCategories = processResult.removableCategories

    if content <> invalid
      '//Capture last focus before mutations
      lastFocusedRowID = ""
      lastRowItemFocused = invalid
      if m.top.featuredRowContent <> invalid
        rowItemFocused = m.FeaturedRowList.rowItemFocused
      else
        rowItemFocused = m.RowList.rowItemFocused
      end if

      if isNonEmptyArray(rowItemFocused) AND rowItemFocused[0] > 0
        lastFocusedRow = content.getChild(rowItemFocused[0])
        lastFocusedRowID = lastFocusedRow.id
      end if

      '//Update content with ads (remove, replace, add)
      shouldInformHomeScreen = updateContentWithAdBatches(content, aAdsToReplace, removableCategories, aAdsToAdd)

      m.top.content = content ' Set m.top.content before handling UI side effects

      '//Restore focus and set row heights if changes occurred
      if shouldInformHomeScreen = true
        restoreFocusAndRowHeightsAfterAdBatchUpdate(content, lastFocusedRowID, lastRowItemFocused)
      end if
    end if

    '//Free references to the batch so that it can be garbage collected
    m.top.adResponseInBatch = invalid
  end if
End Function


' Helper to onAdResponseInBatch(): Processes the ad response batch into adds, replaces, and removals
Function processAdBatchResponse(aResponse, content) as Object
  removableCategories = {}
  aAdsToAdd = []
  aAdsToReplace = []

  for i = 0 to aResponse.count() - 1
    adContent = aResponse[i]
    if adContent <> invalid
      bValid = (adContent.getChildCount() > 0) ' If the container has children, then it is valid. If it does not, it is being passed to remove from the rowList
      containerID = adContent.id

      '//If this is valid content, then we need to add it to the rowlist content later.
      if bValid = true
        rowPlacement = adContent.rowPlacement
        if content <> invalid AND content.getChild(rowPlacement).id = containerID
          aAdsToReplace.push(adContent)
        else
          '//If the row placement has changed, then mark content for removal from the current rowList, so it can be re-added back in at the new rowPlacement.
          removableCategories[containerID] = true
          aAdsToAdd.push(adContent)
        end if
      else
        '//Place all content in removableCategories associative array. We want to get rid of all the content before adding it back in.
        removableCategories[containerID] = true
      end if
    end if
  end for

  return {
    aAdsToAdd: aAdsToAdd
    aAdsToReplace: aAdsToReplace
    removableCategories: removableCategories
  }
End Function


' Helper to onAdResponseInBatch(): Updates the content by replacing, removing, and adding ad batches; returns if significant changes occurred
Function updateContentWithAdBatches(content, aAdsToReplace, removableCategories, aAdsToAdd) as Boolean
  shouldInformHomeScreen = false

  '//Replace existing ads
  if aAdsToReplace.count() > 0
    for i = 0 to aAdsToReplace.count() - 1
      adContent = aAdsToReplace[i]
      content.replaceChild(adContent, adContent.rowPlacement)
    end for
  end if

  '//First remove all ad campaigns. They may no longer be valid or they may have been requested to be moved to a new row. Do this before we add the new, valid adContent
  if removableCategories.count() > 0
    shouldInformHomeScreen = true
    for i = content.getChildCount() - 1 to 0 step -1
      child = content.getChild(i)
      if removableCategories[child.id] = true
        content.removeChildIndex(i)
      end if
    end for
  end if

  '//Add new ads
  if aAdsToAdd.count() > 0
    shouldInformHomeScreen = true
    for i = 0 to aAdsToAdd.count() - 1
      adContent = aAdsToAdd[i]
      content.insertChild(adContent, adContent.rowPlacement)
    end for
  end if

  return shouldInformHomeScreen
End Function


' Helper to onAdResponseInBatch(): Restores focus to the last row item and sets row heights after ad batch updates
Function restoreFocusAndRowHeightsAfterAdBatchUpdate(content, lastFocusedRowID, lastRowItemFocused)
  '//If the content had been removed or inserted, then we need to jump back to the last focused rowItem we reset the rowlist.content which happens when we reset the row heights.
  if m.top.featuredRowContent <> invalid
    rowList = m.FeaturedRowList
  else
    rowList = m.RowList
  end if

  if lastFocusedRowID <> ""
    for i = 0 to content.getChildCount() - 1
      row = content.getChild(i)
      if row.id = lastFocusedRowID AND isNonEmptyArray(rowList.rowItemFocused) = true
        lastRowItemFocused = [i, rowList.rowItemFocused[1]]
        exit for
      end if
    end for
  end if

  setRowHeights()
  if lastRowItemFocused <> invalid
    '//::NOTE:: if the rowlist does not have focus (i.e. an ad component has focus), then the rowItemFocused will not be set even after jumpToRowItem is set.
    rowList.jumpToRowItem = lastRowItemFocused
  end if
End Function


Function onCategoryResponseInBatch(msg) as Void
  tubiLog("CategoryGridList.categoryResponseInBatch")

  response = msg.getData()
  shouldInformHomeScreen = false
  removableCategories = {}

  if response <> invalid
    batchMaxIndex = 0

    ' the function mergeMetadata (which is called in the subsequent for loop) calls
    ' node.replaceChild() which will reparent the node being looped over, thereby reducing
    ' the number of children nodes in the parent node as the looping is happening.
    ' In order to work around this, we need to iterate backwards over a set of child node containers/categories.
    ' But we also want to iterate in the order in which the containers are displayed on the screen,
    ' so we need to reverse the order of the nodes before iterating over them,
    ' such that when iterating from end to beginning, the order is the same as
    ' iterating from beginning to end without pre-reversing the nodes.
    subtype = response.subtype()
    reverseOrder = CreateObject("roSGNode", subtype)

    for i = response.getChildCount() - 1 to 0 step -1
      ' note: reparenting is quicker than appending
      response.getChild(i).reparent(reverseOrder, false)
    end for


    for i = reverseOrder.getChildCount() - 1 to 0 step -1
      content = reverseOrder.getChild(i)

      if content <> invalid
        categoryId = content.ID
        index = mergeMetadata(content)

        if index = -1
          'categories with index = -1 means they have no content and should be removed
          removableCategories[categoryId] = true
        else if index = 0
          ' index is 0 for the top most category in the homescreen grid. LimitedUI models do not start out with any
          ' content in their categories, and we must inform the homescreen that content has arrived so that it may
          ' populate the info panel
          shouldInformHomeScreen = true
        end if

        if index > batchMaxIndex
          batchMaxIndex = index
        end if

      end if
    end for

    if m.top.content <> invalid
      if removableCategories.count() > 0
        for i = m.top.content.getChildCount() - 1 to 0 step -1
          child = m.top.content.getChild(i)
          if removableCategories[child.id] = true
            m.top.content.removeChildIndex(i)
          end if
        end for
        setRowHeights()
      end if
    end if

    ' Delayed setting of Rowlist content until first batch arrives
    if m.RowList.content = invalid then
      m.RowList.content = m.top.content
    else if m.RowList.currFocusColumn > -1
      ' This mainly happens because of reloading of the content in the category.
      category = m.RowList.content.getChild(m.RowList.currFocusRow)
      if category <> invalid AND category.focusIndex <> m.RowList.currFocusColumn
        m.RowList.jumpToRowItem = m.RowList.rowItemFocused
      end if
    end if

    ' inform home screen of first content after content has been set on RowList
    if shouldInformHomeScreen = true AND m.skinAdRow.content = invalid
      ' set focus once we have content to focus on.
      ' will only affect limitedUI models as high spec models will set focus on m.RowList when m.top gains focus
      ' because their homescreen response contains content in it, but limitedUI models homescreen responses don't.
      setRowListFocus() 'only happens if m.top has focus, ie. when the app is launched or signin/signout
    end if

    ' free references to the batch so that it can be garbage collected
    m.top.categoryResponseInBatch = invalid
  end if
End Function


Function mergeMetadata(fetchedContent)
  tubiLog("Merging metadata for categoryId: " + fetchedContent.id)
  index = -1

  categories = invalid
  if m.top.content <> invalid
    categories = m.top.content.getChildren(m.top.content.getChildCount(), 0)
  end if

  if categories <> invalid AND fetchedContent <> invalid AND fetchedContent.id <> invalid
    for i = 0 to categories.count() - 1
      if categories[i].id = fetchedContent.id then
        index = i
        exit for
      end if
    end for

    parentCategory = invalid
    if m.top.content <> invalid
      parentCategory = m.top.content.getChild(index)
    end if

    ' Check if a response arrives but the cache has been flushed and categories moved, such as adding or removing user categories
    if parentCategory = invalid then
      if index = -1 AND fetchedContent.id = "featured"
        fetchedContent.state = "loaded"
        m.top.featuredRowContent.replaceChild(fetchedContent, 0)
        return -2
      else
        tubiLog("Ignoring response due to changed index " + fetchedContent.id)
        return -1
      end if
    end if

    fetchedContent.state = "loaded"

    'Add the existing preliminarily loaded contents to the newly received contents
    m.top.content.replaceChild(fetchedContent, index)
    return index
  else
    return -1
  end if
End Function


' Sets focus on the rowlist, but only if the m.top has focus.
' This function is called when content has been loaded on the RowList and the RowList is ready to accept focus.
' In some cases where side nav or other components have focus, we don't want to set focus on the RowList however.
' Setting focus on RowList triggers an update to itemFocused which Homescreen.brs listens to in order to update
' the info panel. In the case that we do not want set focus on the RowList, we still need to let Homescreen.brs that
' that content has loaded so it can update the infoPanel.
Function setRowListFocus()
  tubiLog("CategoryGridList.setRowListFocus")
  if m.top.hasFocus() = true
    if m.top.featuredRowContent <> invalid
      m.top.lastFocusedList = "featuredRowList"
      m.FeaturedRowList.setFocus(true)
    else
      m.top.lastFocusedList = "rowList"
      m.RowList.setFocus(true)
    end if
  else
    ' If the rowlist is in focus chain or we do not have a featured row.
    ' Then we need to show the default info panel.
    ' Below logic handles the use case where home screen is refreshed but the focus after refresh is on the screen but modal or side nav.
    ' Since featured row does not have info panel we need to check for presence of featured row content.
    ' Featured row landscape poster logic is handled in homescreen helpers.
    if m.RowList.isInFocusChain() = true OR m.isWithDescPortraitSmallExpEnabled = false
      if m.RowList.currFocusRow <> invalid AND m.RowList.currFocusRow >= 0 AND m.RowList.currFocusColumn <> invalid AND m.RowList.currFocusColumn >= 0
        '//If rowList is not in focus and new content is set, then one would think that rowItemFocused should be [0,0] but it isn't,
        '//so that is why we use currFocusRow and currFocusColumn - to ensure the proper item is announced
        row = Int(m.RowList.currFocusRow)
        col = Int(m.RowList.currFocusColumn)
        reloadedItemIndex = [row, col]
      else if isNonEmptyArray(m.RowList.rowItemFocused) = true AND m.RowList.rowItemFocused[0] >= 0 AND m.RowList.rowItemFocused[1] >= 0
        '//currFocusColumn is not available in firmware lower than Roku OS 10.5, so use rowItemFocused. It's imperfect, as it
        '// may think a different item is focused instead of the 1st colum/1st row,
        '// but it will not display a wrong metadata when the user quickly navigates away from 1st rowItem [0,0] as the content is loading
        reloadedItemIndex = m.RowList.rowItemFocused
      else
        reloadedItemIndex = [0, 0]
      end if
      if m.RowList.content <> invalid
        m.top.rowFocused = m.RowList.content.getChild(reloadedItemIndex[0])
        m.top.reloadedItemToBeFocused = resolveAbbreviatedContent(m.top.content, reloadedItemIndex)
      end if
    else if m.FeaturedRowList.isInFocusChain() = true
      m.FeaturedRowList.setFocus(true)
    end if
  end if
End Function


Function onLinearProgramRefreshTimer()

  if m.global <> invalid AND m.global.refreshLinearChannels <> invalid
    ' force trigger linear channel refresh by changing the global field.
    m.global.refreshLinearChannels = not m.global.refreshLinearChannels
  end if

End Function


Function onSkinAdRowItemSelected(msg)
  content = m.top.skinAdContent
  rowItemSelected = msg.getData()

  if content <> invalid
    m.top.oldCategoryId = m.top.currCategoryId
    m.top.currCategoryId = "skinAdRow"
    m.top.selectedPosition = rowItemSelected
    m.top.itemSelected = content.clone(true)
  end if
End Function


Function onSkinAdRowItemFocused(msg)
  tubiLog("CategoryGridList.onSkinAdRowItemFocused")
  rowItemFocused = msg.getData()
  content = m.top.skinAdContent

  if content <> invalid
    category = content.getChild(rowItemFocused[0])

    if category <> invalid then
      category.focusIndex = rowItemFocused[1]
      m.top.oldCategoryId = m.top.currCategoryId
      m.top.currCategoryId = category.id
      content = category.getChild(rowItemFocused[1])

      if content <> invalid then
        m.top.oldCursorPosition = m.top.cursorPosition
        m.top.cursorPosition = rowItemFocused
        m.top.oldItemFocused = m.top.itemFocused
        m.top.rowFocused = category
        m.top.itemFocused = content.clone(true)
        m.top.focusedPosition = rowItemFocused
      end if
    end if
  end if
End Function


Function onReloadedItemToBeFocused(msg)
  tubiLog("CategoryGridList.onReloadedItemToBeFocused")
  ' Not creating an alias to avoid it becoming bi-directional field into the skinAd.
  ' Below logic should only get triggered for initial load and when backing out to home screen if the user navigated from skinAd row.
  itemToBeFocused = msg.getData()
  triggeredRowId = msg.getNode()

  if itemToBeFocused <> invalid AND m.top.lastFocusedList = triggeredRowId
    m.top.reloadedItemToBeFocused = itemToBeFocused
  end if
End Function


Function onFeaturedRowItemFocused(_msg)
  updateFeaturedRowItemFocused()
End Function


Function updateFeaturedRowItemFocused()
  rowItemFocused = m.featuredRowList.rowItemFocused
  if rowItemFocused <> invalid
    itemFocused = resolveAbbreviatedContent(m.top.featuredRowContent, rowItemFocused)
    if itemFocused <> invalid
      topRef = m.top
      topRef.oldCategoryId = topRef.currCategoryId
      category = topRef.featuredRowContent.getChild(rowItemFocused[0])
      category.focusIndex = rowItemFocused[1]
      topRef.oldCategoryId = topRef.currCategoryId
      topRef.currCategoryId = category.id
      topRef.oldCursorPosition = topRef.cursorPosition
      topRef.cursorPosition = rowItemFocused
      topRef.oldItemFocused = itemFocused
      topRef.featuredRowFocusedItem = itemFocused
      updateCurrentFocusedItemBoundingRect()
      updateFocusXOffset(rowItemFocused[0])
    end if
  end if
End Function


' Observer that gets fired when the rowlist vertical focus direction field changes.
Function onVertFocusDirectionChange(msg)
  direction = msg.getData()
  ' Since the direction gets reset during the flow.
  ' The value of m.scrollDirection gets reset to none after the value changes to up or down during scrolling.
  ' This is the reason we are maintaining our own directional scope variable.
  if direction <> "none"
    m.top.featuredListScrollDirection = direction
  end if
End Function


Function updateFocusXOffset(currFocusRow, isInTransit = false)
  featuredRowContent = m.top.featuredRowContent
  focusXOffsets = m.featuredRowList.focusXOffset
  if isNode(featuredRowContent) = true AND isNonEmptyArray(focusXOffsets) = true
    focusXOffset = []
    nonVideoTileGridItemTypes = m.constants.ui.nonVideoTileGridItemTypes

    for i = 0 to featuredRowContent.getChildCount() - 1
      category = featuredRowContent.getChild(i)
      gridItemType = category.gridItemType
      if (i = currFocusRow OR (isInTransit = true AND i = currFocusRow + 1)) AND arrayIncludes(nonVideoTileGridItemTypes, gridItemType) = false
        focusXOffset.push(m.expandedTileFocusXOffset)
      else
        focusXOffset.push(0)
      end if
    end for
    ' To Avoid unnecessary updates to the focusXOffset field, doing a simple array comparison.
    if FormatJson(focusXOffset) <> FormatJson(m.featuredRowList.focusXOffset)
      m.ignoreCurrColumnChange = true
      m.featuredRowList.focusXOffset = focusXOffset
      m.ignoreCurrColumnChange = false
    end if
  end if
End Function


Function onFeaturedListCurrFocusRowChange(msg)
  currFocusRow = 0
  featuredRowContent = m.top.featuredRowContent
  if isNode(featuredRowContent) = true AND m.top.lastFocusedList = "featuredRowList"
    rowItemFocused = m.featuredRowList.rowItemFocused
    if isNonEmptyArray(rowItemFocused) = true
      currFocusRow = rowItemFocused[0]
    end if

    nextFocusRow = 0
    if m.top.featuredListScrollDirection = "down"
      nextFocusRow = currFocusRow + 1
    else if currFocusRow > 0
      nextFocusRow = currFocusRow - 1
    end if

    updateFocusXOffset(nextFocusRow, m.top.featuredListScrollDirection = "up")

    updateCurrentFocusedItemBoundingRect()
  end if
End Function


Function updateCurrentFocusedItemBoundingRect()
  rowItemFocused = m.featuredRowList.rowItemFocused

  featuredRowContent = m.top.featuredRowContent
  if isNonEmptyArray(rowItemFocused) = true AND isNode(featuredRowContent) = true
    currFocusRow = rowItemFocused[0]
    ' Since we are trying to update the bounding rect as the user scrolls we cannot use any of the row list fields to figure out the next row.
    ' Based on the scroll direction we are updating the next focus row.
    nextFocusRow = 1
    if m.top.featuredListScrollDirection = "down"
      nextFocusRow = currFocusRow + 1
    else if currFocusRow > 0
      nextFocusRow = currFocusRow - 1
    end if

    ' Updating the bounding rect for the next focus row.
    category = featuredRowContent.getChild(nextFocusRow)
    if category <> invalid AND category.focusIndex <> invalid
      columnFocused = category.focusIndex
      nextBoundingRect = m.FeaturedRowList.subBoundingRect("item" + nextFocusRow.toStr() + "_" + columnFocused.toStr())
      m.top.inTransitCurrentFocusedItemBoundingRect = nextBoundingRect
    end if

    ' Updating the bounding rect for the current focus row.
    columnFocused = rowItemFocused[1]
    boundingRect = m.FeaturedRowList.subBoundingRect("item" + currFocusRow.toStr() + "_" + columnFocused.toStr())
    m.top.currentFocusedItemBoundingRect = boundingRect
  end if
End Function


' Observer that gets fired when the featured row column focus changes.
' @msg: object, the message object containing the new focus column.
Function onFeaturedRowCurrFocusColumnChange(msg)
  ' ignoreCurrColumnChange is set to true when the user is scrolling through the columns of the row.
  ' Updating the focusXOffset field triggers currFocusColumnChange twice one for the row which we are removing the offset and one for which we are adding the offset.
  ' This optimizes the performance when unnecessary updates been triggered.
  if m.ignoreCurrColumnChange = false
    currentFocusColumn = msg.getData()
    absCurCol = Int(currentFocusColumn)
    ' To account for fast scrolling.
    diff = Abs(absCurCol - m.lastFocusColumnIndex)

    ' Ignoring all updates when user is fast scrolling through the columns of the row.
    ' When the user stops the scrolling we will process the column change.
    if currentFocusColumn <> absCurCol AND diff <= 1
      ' If the current focus column is greater than the last current focus column, then we are scrolling right.
      ' If the current focus column is less than the last current focus column, then we are scrolling left.
      if currentFocusColumn > m.lastCurrentFocusColumn
        featuredRowCurrFocusColumn = m.lastFocusColumnIndex + 1
        m.top.featuredListScrollDirection = "right"
      else
        featuredRowCurrFocusColumn = m.lastFocusColumnIndex - 1
        m.top.featuredListScrollDirection = "left"
      end if
      m.top.featuredRowCurrFocusColumn = featuredRowCurrFocusColumn
    else
      m.lastFocusColumnIndex = absCurCol
      if m.lastFocusColumnIndex <> m.top.featuredRowCurrFocusColumn
        m.top.featuredRowCurrFocusColumn = m.lastFocusColumnIndex
      end if
    end if

    m.lastCurrentFocusColumn = currentFocusColumn
  end if
End Function


Function isSkinAdsAvailable()
  return (m.top.skinAdContent <> invalid AND m.top.skinAdContent.getChildCount() > 0)
End Function


Function translateFeaturedListAndSetFocus(delayFeaturedFocus = false)
  callback = sub()
    m.top.lastFocusedList = "featuredRowList"
    m.FeaturedRowList.setFocus(true)
  end sub

  ' Below logic handles logic to smoothen navigation around skin ads.
  if delayFeaturedFocus = false
    callback()
    callback = invalid
  end if

  slideFadeGeneral(m.FeaturedRowList, [0, 0], "in", 0.3, 0, 1, true, callback)
  if m.isWithDescPortraitSmallExpEnabled = true
    slideTo(m.RowList, [m.rowListPosition[0], m.rowListPosition[1]], 0.3)
  end if

  m.top.hideInfoPanel = false
  updateFeaturedRowItemFocused()
End Function


' Kids mode is a special case where we want to disable the small portrait description experiment.
Function onKidsModeChange(msg)
  kidsMode = msg.getData()
  m.isWithDescPortraitSmallExpEnabled = (m.homeScreenDesignType = "withDescriptionPortraitSmall" AND kidsMode = false)
End Function


Function onAnimateToItemChange(msg)
  tubiLog("CategoryGridList.onAnimateToItemChange")
  '//::TODO::roku_home_screen_redesign, change this observer to an alias once the roku_home_screen_redesign experiment is fully rolled out.
  itemToAnimate = msg.getData()
  if m.isWithDescPortraitSmallExpEnabled = true AND m.featuredRowList.content <> invalid
    m.featuredRowList.animateToItem = itemToAnimate
  else
    m.RowList.animateToItem = itemToAnimate
  end if
End Function


Function onKeyEvent(key as String, press as Boolean) as Boolean
  if press = true
    bSkinAdAvailable = (isSkinAdsAvailable() = true)

    if key = "down" AND m.skinAdRow.isInFocusChain() = true
      if m.FeaturedRowList.content <> invalid
        fade(m.skinAdRow, "out", 0.3)
        translateFeaturedListAndSetFocus(true)
      else
        m.top.lastFocusedList = "rowList"
        slideFade(m.skinAdRow, "above", "out", 0.3)
        m.RowList.setFocus(true)
        slideTo(m.RowList, [0, 0], 0.3)
      end if
      return true
    else if key = "down" AND m.FeaturedRowList.isInFocusChain() = true AND isNode(m.rowList.content) = true
      m.top.lastFocusedList = "rowList"
      slideFadeGeneral(m.featuredRowList, [0, -760], "out", 0.3, 0, -1, true)
      if m.isWithDescPortraitSmallExpEnabled = true
        slideTo(m.RowList, [0, 420], 0.3, 0.1)
      end if
      m.RowList.setFocus(true)
      return true
    else if key = "up" AND m.FeaturedRowList.isInFocusChain() = true AND bSkinAdAvailable = true
      m.top.lastFocusedList = "skinAdRow"
      m.skinAdRow.setFocus(true)
      slideTo(m.RowList, [0, 565], 0.3)
      slideTo(m.FeaturedRowList, [0, 384], 0.3)
      fade(m.skinAdRow, "in", 0.3)
      updateCurrentFocusedItemBoundingRect()
      updateFocusXOffset(-1)

      return true
    else if key = "up" AND m.RowList.isInFocusChain() = true
      if m.FeaturedRowList.content <> invalid
        translateFeaturedListAndSetFocus()
        return true
      else if bSkinAdAvailable = true
        slideFade(m.skinAdRow, "below", "in", 0.3)
        m.top.lastFocusedList = "skinAdRow"
        m.skinAdRow.setFocus(true)
        slideTo(m.RowList, [0, 384], 0.3)
        return true
      end if
    end if
  end if
  return false
End Function

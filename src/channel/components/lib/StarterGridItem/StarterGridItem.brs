Function init()
  m.poster = m.top.findNode("poster")

  m.top.observeFieldScoped("itemContent", "onItemContentChange")
  m.top.observeFieldScoped("itemHasFocus", "onItemFocusChange")

  ' Used for dwell time tracking
  m.itemFocusTimespan = invalid

  ' List of fields that will only be observed if we have a child grid item component with that field
  m.conditionallyObservedFields = [
    "itemHasFocus"
    "rowListHasFocus"
    "rowHasFocus"
    "focusPercent"
    "width"
    "height"
    "index"
    "rowIndex"
  ]

  ' Below field will hold the object of roTimeSpan that will be used to calculate how long the item was fully visible for use with viewableImpressionEvents.
  m.itemVisibleTimespan = invalid

  ' During navigation between screens for ex homescreen to movies the renderTracking change to none happens async with the new screen been loaded.
  ' Due to which when it fires rendertracking for rowlist item with none value the currentScreen value would have already changed to new screen.
  ' To avoid any timing issues choosing a safer side of adding a field to individual row node which will hold the id of the screen to which it belongs too.
  ' Adding a for loop with max as 10 to avoid infinite incase we place the starter grid item outside of categoryGridList
  ' Doing it in init due to roku orphaning the itemcomponent when it deletes the item from the screen during navigation which causes getparent to be invalid.
  ' Performance tested the below code it was not adding a additional process time.
  m.parentArrayGrid = invalid
  m.rowIndexBoost = 0
  m.clientTrackingInfo = {}
  parent = m.top.getParent()
  for x = 1 to 10
    ' If at any point of view due to any reason parent is invalid and then exiting the for loop.
    ' parent can be invalid if the starterGridItem is used outside of rowlist.
    if parent = invalid
      exit for
    end if

    if parent.hasField("shouldTrackViewableImpressionEvent") = true AND parent.shouldTrackViewableImpressionEvent = true
      m.parentArrayGrid = parent
      ' Only enabling it if we find the parent values.
      ' Enabling only if we have parentScreenId. Below logic disables the renderTracking when CategoryGridList is placed in non home screen for now.
      ' If in future if we want to enable in other screens due to the fact that screenId is required when we set the value in the screen it will
      ' automatically start tracking. This will disable the tracking in videoPlayerScreen in Browse while watching tray.
      parentScreenId = parent.parentScreenId
      if parentScreenId <> invalid AND parentScreenId <> ""
        m.top.enableRenderTracking = true
        m.top.observeFieldScoped("renderTracking", "onRenderTrackingChange")
      end if
      exit for
    end if
    parent = parent.getParent()
  end for

  typographyConstants = getTypographyConstants()
  m.subheaderSmallFont = typographyConstants.ids.subheaderSmall
  m.bodySmall = typographyConstants.ids.bodySmall

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "setThemeColors")
  end if

  setThemeColors()
End Function


Function setThemeColors(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    if m.adIndicator <> invalid
      m.adIndicator.fontColor = theme.backgroundColor
    end if
    m.focusedTextColor = theme.focusedTextColor
    m.focused2Color = theme.focused2Color
    m.backgroundColor = theme.backgroundColor
    m.primaryTextColor = theme.primaryTextColor
    m.shadeColor = theme.shadeColor
  end if
End Function


Function onItemFocusChange(msg)
  itemHasFocus = msg.getData()
  itemContent = m.top.itemContent
  MIN_VISIBLE_THRESHOLD = 1000

  ' Track focus state and store focus-specific labels when focused
  if m.clientTrackingInfo <> invalid AND m.clientTrackingInfo.itemInfo <> invalid
    itemInfo = m.clientTrackingInfo.itemInfo
    if itemHasFocus = true
      ' Start dwell time tracking when rowItem gains focus
      m.itemFocusTimespan = CreateObject("roTimespan")

      contentLabels = itemInfo.content_labels

      ' Initialize contentLabels if it doesn't exist
      if contentLabels = invalid
        contentLabels = {}
      end if

      ' Store focus-specific labels when item gets focus
      if isAA(itemContent.sotInfo) = true
        sotInfo = itemContent.sotInfo

        ' Process metadata labels (sotMetaDataLabels) - only add if data exists
        if isNonEmptyArray(sotInfo.sotMetaDataTopLabels) = true
          metadataLabels = []
          for each metaDataLabel in sotInfo.sotMetaDataTopLabels
            if isNonEmptyString(metaDataLabel.sotLabelText)
              metaDataLabelArray = { type: metaDataLabel.sotLabelText }
              metadataLabels.push(metaDataLabelArray)
            end if
          end for
          if isNonEmptyArray(metadataLabels) = true
            contentLabels.metadata_labels = metadataLabels
          end if
        end if

        ' Process metadata (sotMetaData) - only add if data exists
        if isNonEmptyArray(sotInfo.sotMetaData) = true
          metadata = []
          for each mData in sotInfo.sotMetaData
            if isNonEmptyString(mData.sotLabelText)
              metaDataArray = { type: mData.sotLabelText }
              metadata.push(metaDataArray)
            end if
          end for
          if isNonEmptyArray(metadata) = true
            contentLabels.metadata = metadata
          end if
        end if

        ' Process markers (sotMarkers) - only add if data exists
        if isAA(sotInfo.sotMarkers) = true AND isNonEmptyString(sotInfo.sotMarkers.sotLabelText)
          markerLabel = { type: sotInfo.sotMarkers.sotLabelText }
          contentLabels.markers = [markerLabel]
        end if

        ' Store focus-specific labels for later use during impression only if there are changes
        if isAA(contentLabels) = true AND contentLabels.count() > 0
          itemInfo.content_labels = contentLabels
        end if

      end if
    else if m.itemFocusTimespan <> invalid
      ' Calculate dwell time when rowItem lost focus(Includes selected, screen change and focus move to another item in a row)
      currentFocusTime = m.itemFocusTimespan.totalMilliSeconds()

      itemInfo.totalSessionDwellTime = itemInfo.totalSessionDwellTime + currentFocusTime

      ' Only set dwell_time if total accumulated time meets the minimum threshold
      if itemInfo.totalSessionDwellTime >= MIN_VISIBLE_THRESHOLD
        itemInfo.dwell_time = itemInfo.totalSessionDwellTime
      end if

      ' Clear the timer
      m.itemFocusTimespan = invalid
    end if
  end if

End Function


Function onItemContentChange(msg)
  itemContent = msg.getData()

  ' Clear any active focus timer since this is new content
  m.itemFocusTimespan = invalid

  if itemContent <> invalid
    gridItemType = itemContent.gridItemType

    childGridItemComponent = invalid
    row = itemContent.getParent()

    if gridItemType = "emptyContainer" then
      childGridItemComponent = "CategoryGridPoster"
    else if gridItemType = "videoTile"
      childGridItemComponent = "PortraitVideoGridTile"
    else if gridItemType = "landscapeInnerMetadata" then
      childGridItemComponent = "CategoryGridPoster"
    else if gridItemType = "continue_watching_signed_out_user" then
      if row.useVideoTilesFormat = true
        childGridItemComponent = "GuestUserContinueWatchingTile"
      else
        childGridItemComponent = "CategoryGridPoster"
      end if
    else if gridItemType = "linear" then 'For any linear content use CategoryGridPoster to add badges/progress bar etc
      childGridItemComponent = "CategoryGridLinearPoster"
    else if gridItemType = "portraitTopTen"
      childGridItemComponent = "CategoryGridTopTen" 'make sure this check before itemContent.needsLogin check
    else if itemContent.type = "linear" then
      if row <> invalid AND row.gridItemType = "landscapeNoTitle" OR row.gridItemType = "landscape" then
        childGridItemComponent = "CategoryGridLinearPoster"
      end if
    else if gridItemType = "certifiedFresh"
      childGridItemComponent = "CertifiedFreshPoster"
    else if gridItemType = "liveEventSpotlight"
      childGridItemComponent = "LiveEventsContainer"
    else if gridItemType = "liveEventBanner"
      childGridItemComponent = "Banner"
    else if itemContent.needsLogin = true
      childGridItemComponent = "CategoryGridPoster"
    else
      if row <> invalid AND row.id = "continue_watching"
        childGridItemComponent = "CategoryGridPoster"
      end if
    end if


    requiresParenting = false

    if m.availabilityBadge <> invalid
      m.top.removeChild(m.availabilityBadge)
      m.availabilityBadge = invalid
    end if

    if m.titleLabelGroup <> invalid
      m.top.removeChild(m.titleLabelGroup)
      m.titleLabelGroup = invalid
    end if

    if childGridItemComponent = invalid then
      ' If we're only using the starter component then we want to unobserve all of the conditionally observed fields
      if m.childGridItem <> invalid then
        removeConditionalFieldObservers()
        m.top.removeChild(m.childGridItem)
        m.delete("childGridItem")
      end if

      if row <> invalid AND row.isControlLandscape = true
        sPosterURL = itemContent.controlLandscape
      else
        sPosterURL = itemContent.HDGRIDPOSTERURL
      end if
      m.poster.uri = sPosterURL
      m.poster.visible = true

      if row <> invalid AND row.isControlLandscape = true
        createTitleLabel()
      end if
    else
      m.poster.visible = false
      if m.childGridItem = invalid then
        ' Create the child grid item component and setup observers to pass along data to it
        m.childGridItem = createObject("roSgNode", childGridItemComponent)
        requiresParenting = true
        removeConditionalFieldObservers()
        addConditionalFieldObservers(m.childGridItem)
      else if m.childGridItem.subtype() <> childGridItemComponent then
        ' If our childGridItemComponent doesn't match then we need to throw it out and build the new component
        m.top.removeChild(m.childGridItem)
        requiresParenting = true
        m.childGridItem = createObject("roSgNode", childGridItemComponent)
        removeConditionalFieldObservers()
        addConditionalFieldObservers(m.childGridItem)
      end if

      if m.childGridItem <> invalid then
        if m.childGridItem.hasField("parentArrayGrid") = true
          m.childGridItem.parentArrayGrid = m.parentArrayGrid
        end if
        if m.childGridItem.hasField("videoTilesVariant") = true
          m.childGridItem.videoTilesVariant = row.videoTilesVariant
        end if
        ' Pass along the itemContent to the child
        m.childGridItem.itemContent = itemContent

        ' Don't parent until after itemContent is set to improve performance as discussed in Roku talk from 2023
        if requiresParenting = true then
          m.top.appendChild(m.childGridItem)
        end if

      end if
    end if

    if itemContent.scheduleData <> invalid AND gridItemType <> "liveEventSpotlight" AND gridItemType <> "liveEventBanner"
      badgeInfo = getLinearContentBadgeInfo(itemContent.scheduleData)
      if badgeInfo <> invalid
        m.availabilityBadge = createObject("roSGNode", "Badge")
        if badgeInfo.availability = "live"
          setLinearAvailabilityBadge(m.availabilityBadge, badgeInfo.availability, m.primaryTextColor, m.focused2Color)
        else
          setLinearAvailabilityBadge(m.availabilityBadge, badgeInfo.availability, m.backgroundColor, m.primaryTextColor, badgeInfo.badgeText)
        end if
        m.availabilityBadge.translation = [6, 6]
        m.top.appendChild(m.availabilityBadge)
      end if
    end if

    'Adding the Badge info on the poster. Currently we are not adding the badge for linear content. It might be added in future.
    sotPosterLabels = itemContent.sotPosterLabels
    ' this is to avoid rowlist reusing the same badge without adjusting to the new text.
    if m.sotBadge <> invalid
      m.top.removeChild(m.sotBadge)
      m.sotBadge = invalid
    end if

    if itemContent.type <> "linear" AND m.availabilityBadge = invalid AND isAA(sotPosterLabels) = true AND sotPosterLabels.count() > 0 AND childGridItemComponent <> "PortraitVideoGridTile" AND itemContent.gridItemType <> "liveEventSpotlight"
      config = {
        primaryTextColor: m.primaryTextColor
        maxWidth: m.poster.width - 12
        badgeTextFont: m.bodySmall
      }
      m.sotBadge = createSotPosterLabels(sotPosterLabels, config)
      showPosterLabesls(m.sotBadge, m.top)
    end if
  end if

  m.parentScreenId = ""
  m.shouldTrackViewableImpressionEvent = false
  ' If the parent array grid is invalid then resetting the values.
  ' Getting the values in onItemContentChange due to the fact that Rowlist re-uses itemComponent when it does it does not call the init.
  if m.parentArrayGrid <> invalid AND itemContent <> invalid
    m.parentScreenId = m.parentArrayGrid.parentScreenId
    parentScreenTrackingPageInfo = m.parentArrayGrid.parentScreenTrackingPageInfo
    personalizationId = m.parentArrayGrid.personalizationId
    m.shouldTrackViewableImpressionEvent = m.parentArrayGrid.shouldTrackViewableImpressionEvent
    numColumns = m.parentArrayGrid.numColumns
    rowIndexBoost = 0
    if m.parentArrayGrid.rowIndexBoost <> invalid
      rowIndexBoost = m.parentArrayGrid.rowIndexBoost
    end if

    row = itemContent.getParent()

    rowIndex = m.top.rowIndex
    col = m.top.index

    if isInteger(numColumns) = true AND numColumns > 0 AND m.parentArrayGrid.subType() <> "RowList"
      rowIndex = Int(col / numColumns)
      col = col mod numColumns
    end if

    ' dwell_time: tracks focus time for the current focus session
    ' totalSessionDwellTime: accumulates focus time across multiple focus events within the same session
    itemInfo = {
      row: rowIndex + 1 + rowIndexBoost
      col: col + 1
      dwell_time: 0
      totalSessionDwellTime: 0
    }

    ' Build ContentLabels structure - only add arrays when data exists
    contentLabels = {}

    ' Process poster labels - only add if data exists
    if isAA(itemContent.sotPosterLabels) = true AND isNonEmptyString(itemContent.sotPosterLabels.sotLabelText)
      posterLabel = [{ type: itemContent.sotPosterLabels.sotLabelText }]
      contentLabels.poster_labels = posterLabel
    end if

    ' Always set content_labels (even if empty) so it can be populated later on focus
    itemInfo.content_labels = contentLabels

    if itemContent.type = "series"
      seriesId = itemContent.id
      if seriesId.startsWith("0") = true
        seriesId = mid(seriesId, 2)
      end if
      itemInfo.series_id = seriesId
    else if itemContent.type = "adRowlistSpotlight" OR itemContent.type = "adRowlistCarousel"
      if isNonEmptyString(itemContent.slug) = true
        itemInfo.ad_id = itemContent.slug.toInt()
      else if isNumber(itemContent.slug) = true
        itemInfo.ad_id = itemContent.slug
      end if
    else
      itemInfo.video_id = itemContent.id
    end if

    if row <> invalid
      m.clientTrackingInfo = {
        containerId: row.id
        itemInfo: itemInfo
        screenId: m.parentScreenId
        screenTrackingInfo: parentScreenTrackingPageInfo
        personalizationId: personalizationId
      }
    end if
  end if
End Function


Function addConditionalFieldObservers(childGridItem)
  if childGridItem <> invalid then
    for each field in m.conditionallyObservedFields
      ' We only observe the field if the child grid item has that field
      if childGridItem.hasField(field) = true then
        m.top.observeFieldScoped(field, "conditionallyObservedFieldCallback")

        ' Set the initial value for each field
        childGridItem[field] = m.top[field]

        ' For focus tracking, we also need to observe the child's focus changes
        ' to ensure dwell_time calculation works for child components like CategoryGridPoster
        if field = "itemHasFocus" then
          childGridItem.observeFieldScoped("itemHasFocus", "onItemFocusChange")
        end if
      end if
    end for
  end if
End Function


Function removeConditionalFieldObservers()
  for each field in m.conditionallyObservedFields
    m.top.unobserveFieldScoped(field)
  end for

  ' Also unobserve child focus changes if we have a child grid item
  if m.childGridItem <> invalid AND m.childGridItem.hasField("itemHasFocus") then
    m.childGridItem.unobserveFieldScoped("itemHasFocus")
  end if
End Function


' set as the function callback for each field in m.conditionallyObservedFields
Function conditionallyObservedFieldCallback(msg)
  childGridItem = m.childGridItem
  if childGridItem = invalid then
    tubiLog("m.childGridItem was invalid. Cannot pass along field to child", "warn")
  else
    childGridItem[msg.getField()] = msg.getData()
  end if
End Function


Function onRenderTrackingChange(msg)
  state = msg.getData()
  topRef = m.top
  content = topRef.itemContent

  MIN_VISIBLE_THRESHOLD = 1000

  ' Checking the item is of a certain type that we want to track viewable impression event for.
  aAllowedTypes = ["series", "video", "linear", "adRowlistSpotlight", "adRowlistCarousel"]

  if m.shouldTrackViewableImpressionEvent = true AND arrayIncludes(aAllowedTypes, content.type) = true then
    ' Minimum visible time in milli seconds.

    if state = "full"
      ' Not doing it init of the method to avoid having to create this for items that are not visible yet.
      ' Since Rowlist creates additional nodes for items that are not visible plus partially visible.
      m.itemVisibleTimespan = CreateObject("roTimespan")
    else if state <> "full" AND m.itemVisibleTimespan <> invalid
      duration = m.itemVisibleTimespan.totalMilliSeconds()
      row = content.getParent()

      if duration >= MIN_VISIBLE_THRESHOLD AND row <> invalid AND m.parentScreenId <> invalid
        if m.clientTrackingInfo <> invalid AND m.clientTrackingInfo.itemInfo <> invalid
          m.clientTrackingInfo.itemInfo.duration = duration
        end if

        m.global.viewableImpressionEventInfo = m.clientTrackingInfo

        ' Reset dwell_time tracking after firing viewable impression event
        ' This ensures clean state for future events
        if m.clientTrackingInfo <> invalid AND m.clientTrackingInfo.itemInfo <> invalid
          m.clientTrackingInfo.itemInfo.dwell_time = 0
          m.clientTrackingInfo.itemInfo.totalSessionDwellTime = 0
        end if
      end if

      m.itemVisibleTimespan = invalid
    end if
  end if
End Function


Function createTitleLabel()
  titleLabelGroup = createObject("roSGNode", "Group")
  titleLabelGroup.id = "titleLabelGroup"

  gradient = createObject("roSGNode", "Poster")
  gradient.update({
    id: "titleLabelGradient"
    uri: "pkg:/images/video_in_grid_gradient_$$RES$$.9.png"
    translation: [0, m.poster.height - 120]
    width: m.poster.width
    height: 120
    loadDisplayMode: "scaleToFill"
    loadSync: true
  })
  titleLabelGroup.appendChild(gradient)

  titleLabel = createObject("roSGNode", "Label")
  setTypographyOfLabel(titleLabel, m.subheaderSmallFont)
  titleLabel.update({
    id: "titleLabel"
    color: m.primaryTextColor
    maxLines: 2
    numLines: 2
    height: 80
    lineSpacing: 6
    width: m.poster.width - 35
    wrap: true
    vertAlign: "bottom"
    text: m.top.itemContent.title
    translation: [15, m.poster.height - 86]
  })

  titleLabelGroup.appendChild(titleLabel)
  m.top.appendChild(titleLabelGroup)
  m.titleLabelGroup = titleLabelGroup
End Function


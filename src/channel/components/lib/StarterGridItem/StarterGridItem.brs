Function init()
  m.poster = m.top.findNode("poster")

  m.top.observeFieldScoped("itemContent", "onItemContentChange")

  ' List of fields that will only be observed if we have a child grid item component with that field
  m.conditionallyObservedFields = [
    "itemHasFocus"
    "rowListHasFocus"
    "rowHasFocus"
    "focusPercent"
    "width"
    "height"
    "index"
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
End Function


Function onItemContentChange(msg)
  itemContent = msg.getData()

  if itemContent <> invalid
    gridItemType = itemContent.gridItemType
    
    childGridItemComponent = invalid
    row = itemContent.getParent()
    if gridItemType = "emptyContainer" then
      childGridItemComponent = "CategoryGridPoster"
    else if gridItemType = "landscapeInnerMetadata" then
      childGridItemComponent = "CategoryGridPoster"
    else if gridItemType = "continue_watching_signed_out_user" then
      childGridItemComponent = "CategoryGridPoster"
    else if gridItemType = "linear" then 'For any linear content use CategoryGridPoster to add badges/progress bar etc
      childGridItemComponent = "CategoryGridLinearPoster"
    else if gridItemType = "portraitTopTen"
      childGridItemComponent = "CategoryGridTopTen" 'make sure this check before itemContent.needsLogin check
    else if itemContent.type = "linear" then
      if row <> invalid AND row.gridItemType = "landscapeNoTitle" OR row.gridItemType = "landscape" then
        childGridItemComponent = "CategoryGridLinearPoster"
      end if
    else if itemContent.needsLogin = true AND isLoggedInUser() = false '//TBD : isLoggedInUser accesses m.global for every item. Try to remove this
      childGridItemComponent = "CategoryGridPoster"
    else
      if row <> invalid AND row.id = "continue_watching"
        childGridItemComponent = "CategoryGridPoster"
      end if
    end if

    if childGridItemComponent = invalid then
      ' If we're only using the starter component then we want to unobserve all of the conditionally observed fields
      if m.childGridItem <> invalid then
        removeConditionalFieldObservers()
        m.top.removeChild(m.childGridItem)
        m.delete("childGridItem")
      end if

      sPosterURL = itemContent.HDGRIDPOSTERURL
      m.poster.uri = sPosterURL
      m.poster.visible = true
    else
      m.poster.visible = false
      if m.childGridItem = invalid then
        ' Create the child grid item component and setup observers to pass along data to it
        m.childGridItem = m.top.createChild(childGridItemComponent)
        removeConditionalFieldObservers()
        addConditionalFieldObservers(m.childGridItem)
      else if m.childGridItem.subtype() <> childGridItemComponent then
        ' If our childGridItemComponent doesn't match then we need to throw it out and build the new component
        m.top.removeChild(m.childGridItem)
        m.childGridItem = m.top.createChild(childGridItemComponent)
        removeConditionalFieldObservers()
        addConditionalFieldObservers(m.childGridItem)
      end if

      if m.childGridItem <> invalid then
        ' Pass along the itemContent to the child
        m.childGridItem.itemContent = itemContent
      end if
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

    row = itemContent.getParent()
  
    rowIndex = m.top.rowIndex
    col = m.top.index

    if isInteger(numColumns) = true AND numColumns > 0
      rowIndex = Int(col / numColumns)
      col = col MOD numColumns
    end if
    
    itemInfo = {
      row: rowIndex + 1
      col: col + 1
    }

    if itemContent.type = "series"
      seriesId = itemContent.id
      if seriesId.startsWith("0") = true
        seriesId = mid(seriesId, 2)
      end if
      itemInfo.series_id = seriesId
    else
      itemInfo.video_id = itemContent.id
    end if

    m.clientTrackingInfo = {
      containerId: row.id
      itemInfo: itemInfo
      screenId: m.parentScreenId
      screenTrackingInfo: parentScreenTrackingPageInfo
      personalizationId: personalizationId
    }
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
      end if
    end for
  end if
End Function


Function removeConditionalFieldObservers()
  for each field in m.conditionallyObservedFields
    m.top.unobserveFieldScoped(field)
  end for
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

  ' Checking the item is of type video or series or linear only then we proceed.
  contentType = content.type
  if m.shouldTrackViewableImpressionEvent = true AND (contentType = "series" OR contentType = "video" OR contentType = "linear")
    ' Minimum visible time in milli seconds.
    MIN_VISIBLE_THRESHOLD = 1000

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
      end if

      m.itemVisibleTimespan = invalid
    end if
  end if
End Function

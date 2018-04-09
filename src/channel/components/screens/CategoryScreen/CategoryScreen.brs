Function init()
  tubiLog("CategoryScreen.init")
  m._ = rodash()
  m.constants = m.global.constants
  m.ContentArea = m.top.findNode("ContentArea")
  m.CategoryList = m.top.findNode("CategoryList") 'aka category menu
  m.InfoPanel = m.top.findNode("InfoPanel")
  m.FeatureInfo = m.top.findNode("FeatureInfo")
  m.HintGroup = m.top.findNode("UpHintGroup")
  m.FeatureDots = m.top.findNode("FeatureDots")
  fades = m.top.findNode("Fades")
  m.InfoPanelFade = fades.findNode("InfoPanelFade")
  m.FeatureInfoFade = fades.findNode("FeatureInfoFade")
  m.HintGroupFade = fades.findNode("HintGroupFade")
  m.top.observeField("focusedChild", "onScreenFocusChange")
  m.top.observeField("signedIn", "onSignedInChange")
  m.top.observeField("dirtyUserCategories", "onDirtyUserCategories")
  m.top.observeField("homescreenResponse", "onHomescreenResponse")
  m.top.observeField("trackingUri", "onTrackingUriChange")
  m.top.observeField("categoryMenuVisible", "onCategoryMenuVisible")
  m.top.trackingCount = 0
  
  m.CategoryList.observeField("itemFocused","onCategoryMenuItemFocused")
  m.CategoryList.observeField("rowScrollFocused","onCategoryListScrollFocused")
  m.CategoryList.observeField("itemSelected", "onCategoryMenuSelected")
  m.categoryListIsFocused = false

  m.CategoryRefreshTimer = m.top.findNode("CategoryRefreshTimer")
  m.CategoryRefreshTimer.duration = m.constants.timers.categoryContentRefreshTimeout
  m.CategoryRefreshTimer.observeField("fire", "onCategoryRefreshTimer")
  m.CategoryRefreshTimer.control = "start"

  'Content area
  m.CategoryGridList = m.top.findNode("CategoryGridList")
  m.CategoryGridList.observeField("itemFocused", "onGridFocusChange")
  m.CategoryGridList.observeField("itemSelected", "onGridItemSelected")
  m.CategoryGridList.observeField("cursorPosition", "onGridCursorChange")
  m.CategoryGridList.observeField("categoryTotalCounts", "onTotalCountsChange")
  m.CategoryGridList.observeField("currFocusRow", "onCurrFocusRow")

  'Special categories - used to update the user categories as necessary
  m.ContinueWatchingCategory = invalid
  m.MyQueueCategory = invalid

  m.defaultBackgroundUri = m.constants.ui.uris.defaultBackground

  m.metadataFetchTaskDTO = MetadataFetchTaskDTO()

  ' Category list loaded by loadAllCategories
  ' Content should be structured as:
  ' <CategoryContentNode json={...all contents info...}>
  '   <CategoryContentNode id="featured">
  '     <ContentNode id="37108" />
  '     <ContentNode id="337825" />
  '      ...
  '   </CategoryContentNode>
  '   <CategoryContentNode id="most_popular" />
  '     <ContentNode id="346629" />
  '     <ContentNode id="407698" />
  '      ...
  '   </CategoryContentNode>
  ' </CategoryContentNode>
  m.categoryContent = invalid

  if m.constants.deviceInfo.scaledUi = true then
    frame = m.top.findNode("DockedVideoFrame")
    frameMargin = 4 ' FHD is margin 6
    frame.uri = "pkg:/images/selector-white-hd.9.png"
    frame.width = 455 + frameMargin * 2
    frame.height = 256 + frameMargin * 2
    frame.translation = [1390 - frameMargin, 151 - frameMargin]
  end if

  m.singleFeaturePoster = false
  if m.constants.ui.categoryScreen.singleFeaturePoster <> invalid
     m.singleFeaturePoster = m.constants.ui.categoryScreen.singleFeaturePoster
  else
    m.singleFeaturePoster = (getExperimentValue("UserNamespace", "roku_single_feature_poster") = 1)
  end if

  ' Corrections for the XML values in case of not showing single feature poster
  if not m.singleFeaturePoster
    m.FeatureInfo.opacity = 0.0
    m.InfoPanel.opacity = 1.0
  end if

  loadAllCategories()
End Function


''''''''''''''''''''''''''''''
' onHomescreenResponse
'
Function onHomescreenResponse()
  tubiLog("CategoryScreen.onHomescreenResponse")
  if m.top.homescreenResponse.response <> invalid then
    response = m.top.homescreenResponse.response
    if response.code >= 200 and response.code < 300 then
      m.categoryContent = m.top.homescreenResponse.convertedMetadata
      spinner = m.top.findNode("CategorySpinner")
      spinner.visible = false

      for i=0 to m.categoryContent.getChildCount()-1
        category = m.categoryContent.getChild(i)

        'since we're already looping through the content, take advantage to set the user categories (queue, history)
        if category.id = m.constants.ui.categoryIds.history
          m.ContinueWatchingCategory = category
        else if category.id = m.constants.ui.categoryIds.queue
          m.MyQueueCategory = category
        end if

        if m.ContinueWatchingCategory <> invalid and m.MyQueueCategory <> invalid
          exit for
        end if
      end for

      m.InfoPanel.mode = "category"
      m.CategoryList.content = m.categoryContent    ' should be all cateogories but with no content in them
      m.CategoryGridList.content = m.categoryContent  ' should be all categories with initial amounts of content in them
      if m.top.isInFocusChain() then m.CategoryGridList.setFocus(true)
    else
      testLog("Category list returned " + stri(response.code))
      ' if we were loading in the background, don't show an error modal
      if m.top.isInFocusChain() then showErrorModal(response.code, response.failReason, retryCategoryList, retryCategoryList)
    end if
  end if
End Function

' We retry in the cancel or retry cases, since there is nowhere else to go
Function retryCategoryList()
  loadAllCategories()
  m.top.setFocus(true)
End Function

''''''''''''''''''''''''''''
' onDirtyUserCategories
'
' if one of the user categories is showing, reload it
Function onDirtyUserCategories()
  tubiLog("CategoryScreen.onDirtyUserCategories")
  adjustCategories()
  m.CategoryGridList.dirtyUserCategories = true
End Function

''''''''''''''''''''
' onScreenFocusChange
'
' Set focus back to category list or component group if the
' screen has lost focus, usually due to another screen or dialog
' being shown.
Function onScreenFocusChange()
  tubiLog("CategoryScreen.onScreenFocusChange " + focusState(m.top))
  if m.top.hasFocus()
    if m.categoryListIsFocused = false
    ' defaulted to screen, move to a subcomponent
      m.CategoryGridList.setFocus(true)
    else
      m.CategoryList.setFocus(true)
      m.categoryListIsFocused = true
    end if
  end if
End Function


Function onCategoryMenuSelected()
  m.top.categoryMenuVisible = false
End Function


''''''''''''''''''''
' onKeyEvent
'
Function onKeyEvent(key As String, press As Boolean) As Boolean
  tubiLog("CategoryScreen.onKeyEvent")
  ' ignore keypresses until the screen content has shown up
  if press and m.top.homescreenResponse <> invalid then
    if (key = "right" or key = "ok") then
      m.top.categoryMenuVisible = false
      return true
    else if key = "left" then
      m.top.categoryMenuVisible = true
      return true
    end if
  end if
  return false
End Function


' onCategoryMenuVisible
Function onCategoryMenuVisible()
  if m.top.categoryMenuVisible
    showCategoryMenu()
  else
    hideCategoryMenu()
  end if
End Function


Function showCategoryMenu()
  if not m.CategoryList.isInFocusChain()
    fade(m.InfoPanel, "in", 0.4)  ' if feature row is focused on the grid, the info panel would be hidden
    m.CategoryList.jumpToItem = Int(m.CategoryGridList.currFocusRow)
    m.CategoryList.setFocus(true)
    m.categoryListIsFocused = true
    if m.global.constants.deviceInfo.limitedUi
      m.ContentArea.translation = [517,m.ContentArea.translation[1]]
      m.CategoryList.translation = [60,m.CategoryList.translation[1]]
    else
      slideTo(m.ContentArea, [517,m.ContentArea.translation[1]], 0.5)
      slideTo(m.CategoryList, [60,m.CategoryList.translation[1]], 0.5)
    end if
    m.trackingCount = 0
    m.CategoryGridList.isFullWidth = false
    m.top.backgroundUriList = [m.defaultBackgroundUri]
  end if
End Function


Function hideCategoryMenu()
  if m.CategoryList.isInFocusChain()
    m.CategoryGridList.setFocus(true)
    m.categoryListIsFocused = false
    if m.CategoryGridList.currFocusRow = 0 and m.singleFeaturePoster = true
      m.InfoPanel.opacity = 0.0   ' hide info panel if category grid will show the feature row
    end if
    if m.global.constants.deviceInfo.limitedUi
      m.ContentArea.translation = [85,m.ContentArea.translation[1]]
      m.CategoryList.translation = [-380,m.CategoryList.translation[1]]
    else
      slideTo(m.ContentArea, [85,m.ContentArea.translation[1]], 0.5)
      slideTo(m.CategoryList, [-380,m.CategoryList.translation[1]], 0.5)
    end if
    m.trackingCount = 0
    m.CategoryGridList.isFullWidth = true
  end if
End Function


' Change categories based on current app state
Function adjustCategories() As Void
  if m.categoryContent = invalid then return

  insert = 1
  ' Add or remove user categories, taking care to only change them when necessary
  if m.top.signedIn and m.global.historyIds.getChildCount() > 0
    if m.ContinueWatchingCategory = invalid
      m.ContinueWatchingCategory = CreateObject("roSGNode", "CategoryContentNode")
      m.ContinueWatchingCategory.id = m.constants.ui.categoryIds.history
      m.ContinueWatchingCategory.title = m.constants.ui.categoryNames.history
      m.ContinueWatchingCategory.state = "none"
      m.categoryContent.insertChild(m.ContinueWatchingCategory, insert)
    end if
  else if m.global.historyIds.getChildCount() = 0 and m.ContinueWatchingCategory <> invalid
    historyIndex = getChildIndexById(m.categoryContent, m.constants.ui.categoryIds.history)
    m.categoryContent.removeChildIndex(historyIndex)
    m.ContinueWatchingCategory = invalid
  end if

  if m.top.signedIn and m.global.bookmarkIds.getChildCount() > 0
    if m.MyQueueCategory = invalid
      m.MyQueueCategory = CreateObject("roSGNode", "CategoryContentNode")
      m.MyQueueCategory.id = m.constants.ui.categoryIds.queue
      m.MyQueueCategory.title = m.constants.ui.categoryNames.queue
      m.MyQueueCategory.state = "none"
      historyIndex = getChildIndexById(m.categoryContent, m.constants.ui.categoryIds.history)
      if historyIndex >= 0
        insert = historyIndex + 1
      end if
      m.categoryContent.insertChild(m.MyQueueCategory, insert)
    end if
  else if m.global.bookmarkIds.getChildCount() = 0 and m.MyQueueCategory <> invalid
    queueIndex = getChildIndexById(m.categoryContent, m.constants.ui.categoryIds.queue)
    m.categoryContent.removeChildIndex(queueIndex)
    m.MyQueueCategory = invalid
  end if
End Function


' Use this trigger to synchronize menu and grid
Function onCategoryListScrollFocused()
  ' Don't sync if CategoryList has focus and most likely triggered the grid category change
  if m.CategoryList.isInFocusChain() and m.CategoryList.content <> invalid then
    m.CategoryGridList.animateToCategory = m.CategoryList.rowScrollFocused
  end if
End Function


'''''''''''''''''''''
' onCategoryMenuItemFocused
'
' On category menu, item focus change, update the info panel
Function onCategoryMenuItemFocused() As Void
  tubiLog("CategoryScreen.onCategoryMenuItemFocused")
  if not m.CategoryList.isInFocusChain() or m.CategoryList.content = invalid then return

  infoMetadata = CreateObject("roSGNode", "CategoryContentNode")

  newCategory = m.CategoryList.content.getChild(m.CategoryList.itemFocused)
  if newCategory <> invalid
    infoMetadata.title = newCategory.title
    infoMetadata.description = newCategory.description
    infoMetadata.totalCount = newCategory.totalCount
  end if

  populateInfoPanel(m.InfoPanel, "category", infoMetadata)

  'update the tracking URI for user tracking purposes
  catPos = (m.CategoryList.itemFocused + m.top.rowPlaceholder + 1).toStr()
  if newCategory <> invalid
    catSlug = newCategory.id
  else
    catSlug = ""
  end if
  m.top.trackingUri = "/home/" + catPos + "/cat/" + catSlug
End Function


'''''''''''''''''''''''''''
' onSignedInChange
'
Function onSignedInChange()
  tubiLog("CategoryScreen.onSignedInChange")
  onDirtyUserCategories()
End Function

Function onCurrFocusRow()
  if m.CategoryGridList.currFocusRow >= 1
    animationFraction = 1.0
  else
    animationFraction = m.CategoryGridList.currFocusRow
  end if

  m.HintGroupFade.fraction = animationFraction
  if m.singleFeaturePoster = true
    if m.CategoryGridList.isInFocusChain()
      ' If category menu is focused, info panel shows category description so don't hide it
      m.InfoPanelFade.fraction = animationFraction
    end if
    m.FeatureInfoFade.fraction = animationFraction
  end if
End Function


'''''''''''''''''''''
' onGridFocusChange
'
' On grid focus change, update the info panel
Function onGridFocusChange() As Void
  tubiLog("CategoryScreen.onGridFocusChange")

  if not m.CategoryGridList.isInFocusChain() then return
  focusedContent = m.CategoryGridList.itemFocused
  if focusedContent <> invalid
    if m.CategoryGridList.currFocusRow = 0 and m.singleFeaturePoster = true
      populateInfoPanel(m.FeatureInfo, "item", focusedContent)

      ' Show the position dots
      totalCount = 0
      if m.categoryContent <> invalid
        referenceCategory = m.categoryContent.findNode(m.constants.ui.categoryIds.featured)
        if referenceCategory <> invalid
          totalCount = referenceCategory.totalCount
        end if
      end if
      m.FeatureDots.removeChildrenIndex(m.FeatureDots.getChildCount(), 0)
      dots = m.FeatureDots.createChildren(totalCount, "Poster")
      for i=0 to dots.count()-1
        dots[i].width = 8
        dots[i].height = 8
        dots[i].uri = "pkg:/images/dot.png"
        dots[i].blendColor = "0xffffff50"
        if m.CategoryGridList.cursorPosition[1] = i
          dots[i].blendColor = "0xff501a"
        end if
      end for

    else
      populateInfoPanel(m.InfoPanel, "item", focusedContent)
    end if
  end if

  ' If focus is on an empty category, leave the background as is.  This helps avoid
  ' background jank and keeps CPU usage down while categories are being fetched.
  if focusedContent <> invalid
    if focusedContent.backgrounds <> invalid and focusedContent.backgrounds.count() > 0 then
      m.top.backgroundUriList = focusedContent.backgrounds
    else
      m.top.backgroundUriList = [m.defaultBackgroundUri]
    end if
  end if

  'update the tracking URI
  catSlug = ""
  if m.CategoryList.content.getChild(m.CategoryGridList.cursorPosition[0]) <> invalid
    if m.CategoryList.content.getChild(m.CategoryGridList.cursorPosition[0]).id <> invalid
      catSlug = m.CategoryList.content.getChild(m.CategoryGridList.cursorPosition[0]).id + "/"
    end if
  end if
  
  row = 1  'row is fixed at 1 for this design, it indicates the row within the category
  col = 0  'column is the column within the category, expect this to change
  catPos = 0  'catPos is the order of the category (Featured should be 1)
  if m.CategoryGridList.cursorPosition[0] >= 0
    catPos = m.CategoryGridList.cursorPosition[0] + 1
    col = m.CategoryGridList.cursorPosition[1] + 1
  end if

  'set the user event tracking info
  row = row.toStr() + "/"
  col = col.toStr()
  catPos = catPos.toStr()
  m.top.trackingUri = "/home/" + catPos + "/cat/" + catSlug + row + col
End Function

Function onGridItemSelected() As Void
  tubiLog("CategoryScreen.onGridItemSelected")
  m.top.trackingCount = 0
  selectedItem = m.CategoryGridList.itemSelected
  if selectedItem <> invalid then 
    m.top.contentSelected = selectedItem
  end if
End Function


Function onTotalCountsChange(msg)
  tubiLog("CategoryScreen.onTotalCountsChange")
  totalCountInfo = msg.getData()

  for i=0 to totalCountInfo.count()-1
    categoryInList = m.categoryContent.getChild(i)
    categoryInList.totalCount = totalCountInfo[i]
  end for

  itemFocused = m.CategoryList.itemFocused
  m.CategoryList.content = m.categoryContent
  ' NOTE: Setting the content for the CategoryList forces a refresh of the
  ' CategorySeasonListItems but the side effect is the MarkupGrid focuses
  ' to the first item.  We counteract that here by explicitly setting
  ' the focus.
  m.CategoryList.jumpToItem = itemFocused
End Function


'''''''''''''''''''''
' loadAllCategories
'
' Load all category content, including . Series do not have season or episode information though.
Function loadAllCategories()
  tubiLog("CategoryScreen.loadAllCategories")

  ' TODO(Chris): This should move to a shim layer which hides specifics of the Tubi v4 API
  settings = m.global.constants.settings
  platform = m.global.constants.platform
  deviceInfo = m.global.constants.deviceInfo
  url = m.global.constants.urls.matrix.homescreen
  options = {
    params: {
      "app_id": settings.shortAppName
      platform: platform
      "device_id": deviceInfo.deviceId
      expand: 2
      includeEmpty: true
      limit: m.constants.performance.categoryGridList.initialBlockSize
    }
  }
  reqName = m.constants.reqNames.getHomescreen
  m.global.metadataFetchTask.request = m.metadataFetchTaskDTO.createRequest("homescreen", m.top, "homescreenResponse", url, reqName, options)
End Function


'''''''''''
' onTrackingUriChange
'
' send the navigateInPage (navigate_within_page) tracking event
Function onTrackingUriChange()
  if m.top.trackingUri <> ""
    m.top.trackingCount = m.top.trackingCount + 1
    m.global.trackingLoggingTask.trackEvent = {
      trackType: "navigateInPage"
      value: m.top.trackingCount
      ctx: m.top.trackingUri
    }
  end if
End Function


'@target: either the m.InfoPanel or m.FeatureInfo, depending on which panel is showing
'@mode: string, one of the valid info panel modes (see InfoPanel.brs for details)
'@contentNode: content node
Function populateInfoPanel(target, mode, contentNode)
  if contentNode <> invalid and target <> invalid
    if mode = "category"
      target.mode = "category"
      target.categoryContentCount = contentNode.totalCount
      target.title = contentNode.title
      target.description = contentNode.description
    else if mode = "item"
      target.mode = "item"
      target.title = contentNode.title
      target.description = contentNode.description
      target.releaseDate = contentNode.releaseDate
      target.length = contentNode.length
      target.rating = contentNode.rating
      target.genres = contentNode.genres
      target.hasCC = (contentNode.hasSubtitles or not m._.empty(contentNode.subtitleTracks))
    end if

    target.calculateHeight = true
  end if
End Function


Function onCategoryRefreshTimer()
  tubiLog("CategoryScreen.onCategoryRefreshTimer")
  loadAllCategories()
End Function